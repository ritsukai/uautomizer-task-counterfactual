#!/bin/bash
# tb-1541 confirmatory runner — implements DESIGN.md v1+A1 (hash 788ca364…adc43)
# Modes:
#   ./run-trials.sh preflight   checks only
#   ./run-trials.sh run         preflight, then execute the 36-trial sequence
#   ./run-trials.sh status      show ledger summary
# Replacements for invalid trials run AFTER the 36-slot sequence completes (§8);
# invoke run again after clearing blocks — the runner is idempotent over the ledger.
# NEVER add set -x. The Claude token is read inline and never echoed or logged.

set -u
ROOT="$HOME/tb-1541/run"
TB="$ROOT/terminal-bench"
PIN_SHA="14e2ef927e3bf83bcedb24ad11494fc446f306d8"
ARMS="$ROOT/arms"
JOBS="$ROOT/jobs"
LOGS="$ROOT/logs"
LEDGER="$ROOT/ledger.tsv"
SEQ="$ROOT/sequence.tsv"
BLOCKED="$ROOT/blocked-legs.txt"
TOKEN_FILE="$HOME/.config/tb-smoke/oauth-token"
DISK_FLOOR_GB=8
# caffeinate is macOS-only; on Linux run harbor bare
if command -v caffeinate >/dev/null 2>&1; then CAFF="caffeinate -dims"; else CAFF=""; fi
# portable disk/stat helpers (macOS + Linux)
if df -BG / >/dev/null 2>&1; then
  DISK_PATH="/"
  free_gb() { df -BG "$DISK_PATH" | tail -1 | awk '{gsub(/G/,"",$4); print $4+0}'; }
  file_mode() { stat -c %a "$1" 2>/dev/null; }
else
  DISK_PATH="/System/Volumes/Data"
  free_gb() { df -g "$DISK_PATH" | tail -1 | awk '{print $4+0}'; }
  file_mode() { stat -f %Lp "$1" 2>/dev/null; }
fi
mkdir -p "$JOBS" "$LOGS"
touch "$LEDGER" "$BLOCKED"

say() { printf '%s\n' "$*"; }
utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ---------- sequence (frozen order, A1 §20.2): blocks B-A-C / C-B-A / A-C-B, legs interleaved
init_seq() {
  [ -s "$SEQ" ] && return 0
  local n=0 block leg a
  for block in 1 2 3; do
    case $block in 1) arms_order="B A C";; 2) arms_order="C B A";; 3) arms_order="A C B";; esac
    for leg in F O G M; do
      for a in $arms_order; do
        n=$((n+1))
        printf '%d\t%s-%s0%d\t%s\t%s\n' "$n" "$leg" "$a" "$block" "$leg" "$a" >> "$SEQ"
      done
    done
  done
}

# Precise rate-limit detection. Harbor's classifier pattern-matches the literal
# string "rate_limit_event" (benign telemetry Claude Code emits every run), so
# grepping harbor's log for /rate.?limit/ produces false positives that block a
# whole leg. Require real evidence: a rate_limit_event whose status is NOT
# "allowed", or explicit human-readable limit language.
rate_limited_dir() { # $1 = trial dir
  local d="${1:-}"
  [ -n "$d" ] && [ -d "$d" ] || return 1
  grep -rhoE '"rate_limit_event"[^}]*' "$d"/agent 2>/dev/null \
    | grep -qE '"status":"(rejected|blocked|exhausted|limited|denied)"' && return 0
  grep -rqiE "usage limit reached|weekly limit reached|rate limit exceeded|too many requests|HTTP 429" \
    "$d"/agent "$d"/trial.log 2>/dev/null && return 0
  return 1
}

ledger_has() { grep -q "^$1	" "$LEDGER" 2>/dev/null; }
leg_blocked() { grep -qx "$1" "$BLOCKED" 2>/dev/null; }

# ---------- preflight
preflight() {
  local ok=1
  docker info >/dev/null 2>&1 && say "PASS docker daemon" || { say "FAIL docker daemon not running"; ok=0; }
  local free; free=$(free_gb)
  [ "$free" -ge 20 ] && say "PASS disk ${free}GB free" || { say "FAIL disk ${free}GB free (<20GB to start)"; ok=0; }
  [ "$(cd "$TB" 2>/dev/null && git rev-parse HEAD)" = "$PIN_SHA" ] && say "PASS repo pinned $PIN_SHA" || { say "FAIL repo not at pinned SHA"; ok=0; }
  command -v harbor >/dev/null && say "PASS harbor $(harbor --version 2>/dev/null)" || { say "FAIL harbor missing"; ok=0; }
  [ -f "$TOKEN_FILE" ] && [ "$(file_mode "$TOKEN_FILE")" = "600" ] && say "PASS claude token file (0600)" || { say "FAIL claude token file missing/perms"; ok=0; }
  [ -f "$HOME/.codex/auth.json" ] && say "PASS codex auth.json" || { say "FAIL codex auth.json missing"; ok=0; }
  [ -f "$HOME/.gemini/oauth_creds.json" ] && say "PASS gemini oauth creds" || { say "FAIL gemini oauth_creds.json missing"; ok=0; }
  local h
  for a in A B C; do
    [ -f "$ARMS/arm$a/fix-uautomizer-soundness/instruction.md" ] && say "PASS arm$a task dir" || { say "FAIL arm$a task dir missing"; ok=0; }
  done
  if [ -f "$ROOT/ARM-HASHES.sha256" ]; then
    (cd / && shasum -a 256 -c "$ROOT/ARM-HASHES.sha256" >/dev/null 2>&1) && say "PASS arm instruction hashes" || { say "FAIL arm instruction hash mismatch"; ok=0; }
  else say "FAIL ARM-HASHES.sha256 missing"; ok=0; fi
  [ $ok -eq 1 ] && say "PREFLIGHT: ALL PASS" || say "PREFLIGHT: FAILURES ABOVE"
  return $((1-ok))
}

# ---------- per-leg invocation
leg_args() { # -> echoes harbor agent/model args for leg $1
  case "$1" in
    F) echo "--agent claude-code --model anthropic/claude-fable-5 --ak reasoning_effort=xhigh --ak version=2.1.228";;
    O) echo "--agent claude-code --model anthropic/claude-opus-4-6 --ak version=2.1.228";;
    G) echo "--agent codex --model openai/gpt-5.4";;
    M) echo "--agent gemini-cli --model google/gemini-3.1-pro-preview";;
    H) echo "--agent claude-code --model anthropic/claude-haiku-4-5-20251001 --ak version=2.1.228";;
  esac
}

run_harbor() { # $1 leg, $2 arm, $3 trial_id, $4 extra args (e.g. --install-only)
  local leg=$1 arm=$2 id=$3 extra=${4:-}
  local task="$ARMS/arm$arm/fix-uautomizer-soundness"
  local jdir="$JOBS/$id" log="$LOGS/$id.log"
  mkdir -p "$jdir"
  (
    unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL
    case "$leg" in
      F|O|H) export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$TOKEN_FILE")"; export CLAUDE_FORCE_OAUTH=1;;
      G)   export CODEX_FORCE_AUTH_JSON=1;;
      M)   export GEMINI_FORCE_OAUTH=1; export GOOGLE_CLOUD_PROJECT=colophon-505410;;
    esac
    # shellcheck disable=SC2046
    $CAFF harbor run -p "$task" $(leg_args "$leg") \
      -n 1 -k 1 --jobs-dir "$jdir" $extra >> "$log" 2>&1
  )
  return $?
}

extract_and_ledger() { # $1 trial_id, $2 leg, $3 arm, $4 start_utc, $5 harbor_exit
  local id=$1 leg=$2 arm=$3 start=$4 hexit=$5 end; end=$(utc)
  local jdir="$JOBS/$id" log="$LOGS/$id.log"
  local trial reward="?" models="?" cost="?" status note=""
  # the TRIAL dir is the one containing verifier/reward.txt (the job dir also has a result.json)
  trial=$(find "$jdir" -path "*/verifier/reward.txt" -maxdepth 5 2>/dev/null | head -1 | sed 's|/verifier/reward.txt$||')
  [ -z "$trial" ] && trial=$(find "$jdir" -maxdepth 3 -mindepth 2 -type d -name "fix-uautomizer-soundness__*" 2>/dev/null | head -1)
  if [ -n "$trial" ]; then
    [ -f "$trial/verifier/reward.txt" ] && reward=$(tr -d '[:space:]' < "$trial/verifier/reward.txt")
    models=$(python3 - "$trial/agent/trajectory.json" 2>/dev/null <<'PY'
import json,sys
try:
  d=json.load(open(sys.argv[1]))
  ms=sorted({s.get("model_name") for s in d.get("steps",[]) if isinstance(s,dict) and s.get("model_name")})
  print(",".join(ms) or "none")
except Exception: print("unreadable")
PY
)
    cost=$(python3 - "$trial/agent/trajectory.json" 2>/dev/null <<'PY'
import json,sys
try:
  d=json.load(open(sys.argv[1])); print(d.get("final_metrics"))
except Exception: print("?")
PY
)
  fi
  # rate-limit / window detection
  if rate_limited_dir "$trial"; then
    status="invalid"; note="genuine rate limit (rate_limit_event status != allowed)"; echo "$leg" >> "$BLOCKED"
  elif [ "$hexit" != "0" ] || [ "$reward" = "?" ]; then
    status="invalid"; note="harbor exit $hexit / missing reward"
  else
    status="valid"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$status" "$leg" "$arm" "$reward" "$models" "$start" "$end" "$hexit" "$note" >> "$LEDGER"
  say "[$id] $status reward=$reward models=$models"
}

probe_needed() { # $1 leg -> 0 if probe row missing
  case "$1" in F) return 1;; esac
  ledger_has "PROBE-$1" && return 1 || return 0
}

run_probe() { # $1 leg — O gets max_turns=1 real probe; G/M get --install-only (minimal per §20.6)
  local leg=$1 start; start=$(utc)
  say "running probe for leg $leg..."
  local extra="--install-only"
  [ "$leg" = "O" ] && extra="--ak max_turns=1"
  run_harbor "$leg" A "PROBE-$leg" "$extra"
  local hexit=$?
  local note="install-only"; [ "$leg" = "O" ] && note="max_turns=1"
  if rate_limited_dir "$(find "$JOBS/PROBE-$leg" -maxdepth 2 -type d -name "fix-*" 2>/dev/null | head -1)"; then
    printf 'PROBE-%s\tblocked\t%s\tA\t-\t-\t%s\t%s\t%s\trate-limit\n' "$leg" "$leg" "$start" "$(utc)" "$hexit" >> "$LEDGER"
    echo "$leg" >> "$BLOCKED"; return 1
  fi
  if [ "$hexit" = "0" ]; then
    printf 'PROBE-%s\tok\t%s\tA\t-\t-\t%s\t%s\t0\t%s\n' "$leg" "$leg" "$start" "$(utc)" "$note" >> "$LEDGER"
    return 0
  fi
  printf 'PROBE-%s\tfailed\t%s\tA\t-\t-\t%s\t%s\t%s\t%s\n' "$leg" "$leg" "$start" "$(utc)" "$hexit" "$note" >> "$LEDGER"
  echo "$leg" >> "$BLOCKED"; return 1
}

run_all() {
  local only_leg="${1:-}"
  init_seq
  preflight || { say "aborting: preflight failed"; exit 1; }
  [ -n "$only_leg" ] && say "LEG FILTER: running only leg $only_leg"
  while IFS=$'\t' read -r ord id leg arm; do
    [ -n "$only_leg" ] && [ "$leg" != "$only_leg" ] && continue
    ledger_has "$id" && continue
    if leg_blocked "$leg"; then
      ledger_has "SKIP-$id" || printf 'SKIP-%s\tskip\t%s\t%s\t-\t-\t%s\t-\t-\tleg blocked\n' "$id" "$leg" "$arm" "$(utc)" >> "$LEDGER"
      continue
    fi
    # reclaim per-trial container layers + dangling build artifacts (NOT images: rebuilds cost ~10min)
    docker container prune -f >/dev/null 2>&1
    docker image prune -f >/dev/null 2>&1
    docker builder prune -f >/dev/null 2>&1
    local free; free=$(free_gb)
    say "  [disk ${free}GB free after reclaim]"
    [ "$free" -lt "$DISK_FLOOR_GB" ] && { say "ABORT: disk ${free}GB below floor"; exit 2; }
    if probe_needed "$leg"; then run_probe "$leg" || continue; fi
    leg_blocked "$leg" && continue
    say "[$id] starting $(utc)"
    local start; start=$(utc)
    run_harbor "$leg" "$arm" "$id"
    extract_and_ledger "$id" "$leg" "$arm" "$start" "$?"
  done < "$SEQ"
  say "sequence pass complete $(utc). Blocked legs: $(sort -u "$BLOCKED" | tr '\n' ' ')"
  say "Skipped slots re-run on next invocation after clearing $BLOCKED"
}

status() {
  init_seq
  local total done_v done_i
  total=$(wc -l < "$SEQ" | tr -d ' ')
  done_v=$(awk -F'\t' '$2=="valid" && $1 !~ /^SHAKE/ && $1 !~ /-RE$/' "$LEDGER" | wc -l | tr -d ' ')
  done_i=$(awk -F'\t' '$2=="invalid"' "$LEDGER" | wc -l | tr -d ' ')
  say "valid: $done_v  invalid: $done_i  of $total slots. Blocked: $(sort -u "$BLOCKED" 2>/dev/null | tr '\n' ' ')"
  say "--- last 6 ledger rows ---"; tail -6 "$LEDGER"
}

case "${1:-}" in
  preflight) init_seq; preflight;;
  run) run_all "${2:-}";;
  status) status;;
  shakedown)
    preflight || exit 1
    for a in A B C; do
      say "[SHAKE-$a] full haiku trial, arm $a, $(utc)"
      start=$(utc); run_harbor H "$a" "SHAKE-$a"; extract_and_ledger "SHAKE-$a" H "$a" "$start" "$?"
    done;;
  probe) [ -n "${2:-}" ] || { say "usage: $0 probe F|O|G|M"; exit 1; }; run_probe "$2";;
  *) say "usage: $0 preflight|run [leg]|status|probe <leg>"; exit 1;;
esac
