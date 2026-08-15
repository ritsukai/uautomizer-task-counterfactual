# tb-1541 evidence

Evidence for a pre-registered counterfactual run on the Terminal-Bench task `fix-uautomizer-soundness`, in response to [harbor-framework/terminal-bench#1541](https://github.com/harbor-framework/terminal-bench/issues/1541).

Everything here is small and readable. Every number in the accompanying issue comment can be checked against a file in this repository.

## The question

Issue #1541 asks whether the task is compromised because the bug it asks you to fix was created by reverting public open-source code — so an agent might diff against upstream and copy the answer without doing the diagnosis. A maintainer argued the opposite: finding the right upstream version is itself hard, and nine earlier trials scored 0/9.

The design ran the same task under three information conditions, changing **only** the instruction text:

| Arm | Instruction |
|---|---|
| **A** | exactly as shipped — no mention of upstream or open source |
| **B** | plus one generic sentence: *"consider locating a plausible upstream baseline and comparing it with the local source"* |
| **C** | plus the exact repository, the `v0.2.4` tag, and the two file paths |

Three models × three arms × three trials = 27 trials.

## How scoring works

Grading runs **22 hidden C programs**; all 22 must be correct to score. There are **three** independent injected defects, and nothing tells the agent how many exist.

**The shipped, untouched image already scores 8/22** — fourteen programs fail before any agent touches anything. Every number below is stated relative to that baseline, which is why a "12/22" is a repair of four tests, not a breakage of ten.

## Results

| Arm | GPT-5.4 | Opus 4.6 | Fable 5 |
|---|---|---|---|
| **A** — as shipped | 0/3 · +7 +5 +5 | 0/3 · +12 +4 +4 | **3/3 · +14 ×3** |
| **B** — nudge | 0/3 · +4 +4 +4 | 0/3 · +4 +4 +6 | **3/3 · +14 ×3** |
| **C** — coordinates | 2/3 · +14 +14 +7 | 2/3 · +14 +14 +12 | **3/3 · +14 ×3** |

`+N` = improvement over the 8/22 baseline; `+14` = a perfect 22/22.

**Every trial improved on the baseline. None regressed below it.** Exactly one program (`safe_condition_false`) ever fails where the baseline passes, and four independent codings attribute that to *unmasking* — repairing defect 1 while defect 3 remains broken — not to damage.

## The mechanism

The task leaks its own version. When the verifier runs, it prints its build commit: `Version 0e0057cc`. That identifies the exact upstream commit, which makes a diff surgical — three files, three defects, no noise.

Across all 27 trials:

- **6 trials** read that banner and used it — all Fable 5, in arms A and B where no coordinates were given
- **9 trials** used the tag supplied by arm C
- **12 trials** never noticed it existed

GPT-5.4 and Opus printed the banner in their own output — sometimes eight or nine times — and never referenced it once. One trial (`G-B01`) found the correct upstream repository a different way, from copyright headers, then stopped at search-engine queries without ever fetching anything. Its coder's conclusion: *identifying the upstream was never the bottleneck; retrieving and diffing it was.*

The three defects are also very unequal. Defect 3 (unsigned widening) causes 7 of the 14 baseline failures and was **never attempted in 11 of 27 trials**, diagnosed locally exactly once. Defect 2 (XOR) was repeatedly *inspected and declared correct* — in one trial the agent wrote that the code "subtracts twice the AND term, so that's also correct", when the missing factor of two is the bug, and the correct identity is stated in a comment two lines above.

## What is here

```
DESIGN.md                  frozen pre-registration; sha256 788ca364…, posted to #1541 before the runs
DESIGN-LINEAGE.md          the two publicly-hashed design revisions and why there are two
CORRECTIONS.md             three mid-analysis corrections that each changed a conclusion
LIMITATIONS.md             what this does not prove — read before citing anything
results/
  MASTER-SUMMARY.tsv       all 27 trials, one row each, baseline-relative
  verifier/<TRIAL>/        test-stdout.txt, reward.txt, ctrf.json  (+ BASELINE-PROBE-O)
codings/
  CODING-INSTRUCTIONS.md   the rubric, frozen before coding
  <TRIAL>.md               27 per-trial codings: provenance, chronology, byte offsets
ledgers/                   per-leg run records, plus the superseded arm64 ledger
arms/                      the three instruction.md files that differ, and their hashes
runner/                    the script that executed the sequence, and the frozen trial order
gemini-substitution/       evidence for the Gemini model-substitution finding
MANIFEST.sha256            digest of every file here
```

## How to check a claim

```sh
# any trial's score: reward, then count the failing programs
cat results/verifier/F-A01/reward.txt                                    # → 1
grep -cE 'expected (TRUE|FALSE), got' results/verifier/F-A01/test-stdout.txt   # → 0 failures = 22/22

# the baseline: 14 failures on the untouched image = 8/22
grep -cE 'expected (TRUE|FALSE), got' results/verifier/BASELINE-PROBE-O/test-stdout.txt

# note: match the full failure line. A bare `grep -c expected` also matches pytest's own
# "PASSED ...::test_expected_verdicts" line and will over-count by one.

# the pre-registration hash posted to #1541 before any trial ran
shasum -a 256 DESIGN.md          # → 788ca364f417317e6b56bb172e4e89920926048a3e5bd147aeb76486a11adc43

# the three arm instructions are the ones that ran
shasum -a 256 -c arms/ARM-HASHES.sha256

# this repository is intact
shasum -a 256 -c MANIFEST.sha256
```

For *why* a trial is coded as it is, read `codings/<TRIAL>.md`. Each cites byte offsets into that trial's agent transcript.

## What is deliberately absent

**Full agent transcripts (~14 MB).** The codings cite byte offsets into them. They are available on request — open an issue here or ask on #1541 and they will be sent. They are excluded because publishing detailed behavioural traces of three labs' frontier agents is a separate act from answering a task-triage question.

**The task's `solution/` and `tests/` directories.** These are the answer key and the 22 hidden programs. They are already public [upstream](https://github.com/harbor-framework/terminal-bench/tree/main/tasks/fix-uautomizer-soundness); re-hosting them here would only make them more findable.

**The arm64 trials.** Environment-invalid — see below.

## Related issues filed from this work

- [terminal-bench#1601](https://github.com/harbor-framework/terminal-bench/issues/1601) — this task is silently unsolvable on arm64: all 22 programs return `UNKNOWN`, so any Apple Silicon run scores 0 with no error. Our first two days of trials were lost to this before an oracle check caught it.
- [harbor#2758](https://github.com/harbor-framework/harbor/issues/2758) — harbor resolves the host platform and then discards it; recording it would have made the above diagnosable immediately.
- [gemini-cli#28825](https://github.com/google-gemini/gemini-cli/issues/28825) — requesting `gemini-3.1-pro-preview` on personal OAuth credentials silently returns a 2.5-series model. This is why there is no Gemini leg here.

## Provenance

Run by [@ritsukai](https://github.com/ritsukai) on rented x86 DigitalOcean droplets, 14–15 August 2026. harbor 0.21.0; terminal-bench pinned at `14e2ef927e3bf83bcedb24ad11494fc446f306d8`. Trial orchestration, transcript coding and this write-up were performed with AI assistance; see `LIMITATIONS.md` for what that implies about the results.
