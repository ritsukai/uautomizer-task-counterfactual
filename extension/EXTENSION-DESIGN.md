# Extension A2: the task with its version line stripped

**Status: registered before any run. This file is committed and pushed before the first trial starts; the commit history is the timestamp.**

## What this tests

The main experiment found that Fable 5 solved the task 3 out of 3 on the unmodified instruction by reading the tool's own output. Every run of the sabotaged verifier prints a version banner naming the exact upstream commit it was built from. Fable read that banner, downloaded exactly that version, compared, and restored the tampered code.

This extension re-runs the same task with that identifier removed, to answer: **was the leak load-bearing?** If the agent still passes, the leak was not necessary and the task is saturated for this agent regardless. If it now fails, the banner was the mechanism, and stripping it restores the difficulty the task was designed around.

## Why this is an amendment, not an extension under the original rule

The original design's extension rule (§7) permits extra trials only "under the identical frozen configuration". A modified task image is not the identical configuration — it is a new information condition. The original design also requires that changes be applied "only as dated, public amendments" (§14). This file is that amendment, designated **A2**. Its results are reported separately and are never merged into the original 27 trials.

## Setup

One model setup: **Fable 5** via Claude Code 2.1.228 at `xhigh` reasoning effort — identical to the original leg F in every respect except the task image. Only Fable ever used the banner, so only its behaviour can change; the other setups went 0/3 on this instruction without ever noticing the line, and re-running them would measure nothing new. (The results comment offered "same four setups"; this narrowing is disclosed here and in the report. The Gemini setup also remains infeasible for the unrelated reason documented in the main LIMITATIONS.)

The instruction text is **byte-identical to the original condition A** (the task exactly as shipped, no hints). Verified by hash before running.

Runs execute on a fresh x86 cloud machine restored from the same snapshot used for the original trials, with the standing gates: an oracle run (the task's own reference solution) must score full marks on the modified image, and a no-action probe must still score the baseline 8 of 22, before any trial spends.

## The modification, exactly

The version identifier appears in two places, both inside the task image, neither created by the task's own build scripts — both arrive in the downloaded release:

1. **The Python wrapper** (`Ultimate.py`) hardcodes `version = '0e0057cc'` and prints `Version 0e0057cc` on every run. The variant replaces the hash with `00000000` (same length).
2. **The Java distribution** prints `This is Ultimate 0.2.4-dev-0e0057c` into its output and its log file. The variant patches that string inside the jar that carries it, replacing the 7-hex-char commit fragment with zeros, using the same extract-patch-rejar technique the task's own build already uses.

Both changes are applied identically in the task's two image builds (the agent's environment and the verifier). Because one guard test pins the byte-hash of `Ultimate.py`, the variant updates that expected-hash constant; if the jar patch touches the one other whole-jar-hashed artifact, its constant is updated the same way. **The full diff between the original condition-A directory and this variant is published alongside the results**, so the modification itself is auditable.

## What is deliberately not stripped — the residual surface

Honesty requires stating what still identifies the version after the strip:

- The release version `0.2.4` remains in jar filenames, directory names, and the log line (`…0.2.4-dev-0000000`). It cannot be removed: the verifier addresses artifacts by those literal paths. A version number is a weaker pointer than an exact commit — `v0.2.4` is a public tag — but it is a pointer.
- The tampered files carry 2026 timestamps against the distribution's 2023 ones. One original run fingerprinted the tampering this way.
- The source tree's package headers name the upstream organisation. One original run found the repository through them.

This extension therefore tests the removal of the **exact-commit leak specifically**, not of every route to the upstream. If the agent passes anyway, the assessment must trace which residual route it used — that is the actionable output for the maintainers either way.

## Trials and stopping rule — fixed in advance

Trial IDs `XS-F-01`, `XS-F-02`, `XS-F-03`. At most three.

1. Run one trial.
2. **If it passes, stop.** Passing requires all 22 hidden programs correct, which cannot happen by luck; a single pass is an existence proof that the capability survives the strip.
3. **If it fails, run up to two more.** The original data contains two failures caused by silent download-tool faults, so a single failure cannot distinguish "the strip worked" from noise.
4. Every trial run is reported, whatever the count. No trial is excluded after the fact for any reason other than the environment-validity rules of the original design (which are unchanged).

## Interpretation — committed before the result exists

| Outcome | Reading |
|---|---|
| Any pass | The exact-commit leak was **not** necessary. Residual identifiers suffice for this agent, and the task is effectively saturated for it regardless of the banner. The transcript assessment identifies which residual route was used, which tells the maintainers what else would need closing. |
| 0 of 3 | The banner **was** load-bearing. Stripping it restores the intended version-selection difficulty against the strongest setup tested. Recommend the equivalent patch upstream (plus timestamp normalisation, per the main findings). |
| Mixed (fail then pass) | The capability survives but is less reliable without the leak. Both readings above apply in part; the per-trial assessments carry the detail. |

## Prediction, recorded for honesty

Genuinely uncertain — which is why the run is worth doing. The residual `0.2.4` identifiers give a capable agent a plausible route to the right tag without the banner. If forced to one guess: the agent still finds the upstream, more slowly, via the version number in artifact names. The point of pre-registering this is that we cannot quietly claim afterwards to have expected whatever happens.

## Assessment

Same frozen rubric, same evidence hierarchy, same return format as the original 27 (see `../assessments/`). Published in this directory with verifier output and ledger rows, and the repository manifest updated.
