# Does the agent work the bug out, or look the answer up?

There is a benchmark task in which an AI agent is asked to fix a bug in **UltimateAutomizer**, a tool that reads a C program and decides whether it can go wrong. The tool has been sabotaged: three separate faults were introduced into its source, and the agent's job is to find and repair them. It is graded by running 22 small C programs through the repaired tool. Every one must come out right.

The task was built by taking a real open-source project and **reverting some of its code**. That is the problem. The correct code still exists publicly, on the internet the agent is allowed to use. So an agent might never diagnose anything — it might simply find the original project, compare it against the sabotaged copy, and copy the differences back.

A maintainer of the benchmark raised exactly this worry in [issue #1541](https://github.com/harbor-framework/terminal-bench/issues/1541). Another maintainer disagreed, arguing that finding the *right version* of a large, fast-moving project is itself most of the difficulty, and pointing out that nine earlier attempts had all failed.

This repository is the evidence from an experiment run to settle it.

## How the experiment worked

The same task was given to three AI models, three times each, under three different instructions. **Only the instruction text changed** — everything else was identical.

| Condition | What the instruction said |
|---|---|
| **A** | The task exactly as it ships. No mention of open source, upstream code, or comparison. |
| **B** | The same, plus one vague nudge: *"consider locating a plausible upstream baseline and comparing it with the local source."* |
| **C** | The same, plus the exact address: which project, which version, and which two files to compare. |

Three models × three conditions × three attempts = **27 runs**.

The design, the number of runs, the order they would run in, and the standards for judging them were all written down and published **before any run happened** — so the analysis could not be quietly shaped to fit whatever turned up. See `DESIGN.md` and `DESIGN-LINEAGE.md`.

## Reading the scores

Two things make the raw scores misleading unless you know them.

**Scoring is all-or-nothing.** All 22 programs must be correct. Getting 21 right scores exactly the same as getting none right: zero.

**The starting point is not zero — it is 8 out of 22.** The sabotaged tool already fails fourteen of the test programs before any agent touches it. So a run that ends at 12 out of 22 has *repaired four programs*, not broken ten. Every number below is given both ways: the raw score, and the improvement over that starting point.

Neither of these is obvious from the benchmark's own output, and both changed our conclusions once we checked. See `CORRECTIONS.md`.

## Results

Each cell shows **how many of the three runs fully solved the task**, then how much each run improved on the starting point.

| Instruction given | GPT-5.4 | Opus 4.6 | Fable 5 |
|---|---|---|---|
| **A** — nothing added | solved 0 of 3 · +7 +5 +5 | solved 0 of 3 · +12 +4 +4 | **solved 3 of 3** · +14 +14 +14 |
| **B** — vague nudge | solved 0 of 3 · +4 +4 +4 | solved 0 of 3 · +4 +4 +6 | **solved 3 of 3** · +14 +14 +14 |
| **C** — exact address | solved 2 of 3 · +14 +14 +7 | solved 2 of 3 · +14 +14 +12 | **solved 3 of 3** · +14 +14 +14 |

`+N` is the improvement over the 8-out-of-22 starting point. `+14` means a perfect 22 out of 22.

Read the middle column of each cell, not just the pass count. **Every single run improved on the starting point, and none made things worse.** Exactly one test program ever fails where the untouched tool passes, and the reason is explained below — it is a side effect of a partial repair, not damage.

Fable 5 solved the task every time, including when given no help at all. The other two models never solved it unaided, and solved it roughly two times in three when handed the answer's location.

## Why: the task gives itself away

The sabotaged tool **prints its own version number**. Every time it runs, its output includes a line naming the exact version of the original project it was built from.

That single line is the whole game. With it, an agent can download precisely the right original version and compare — and the differences light up immediately: three files changed, three faults, nothing else. Without it, an agent faces a project of thousands of files whose current version has moved far from the one in front of it.

Across all 27 runs:

- **6 runs** read that version line and used it — all of them Fable 5, in the two conditions where no address was given
- **9 runs** used the address that condition C handed them
- **12 runs** never noticed the version line at all

The other two models printed that line in their own output — in one case nine times — and never once referred to it. One run found the right project by a different route, reading the copyright headers in the source, then ran a few web searches and gave up without ever downloading anything. As that run's assessment puts it: identifying the original was never the hard part. **Fetching it and comparing was.**

## The three faults are not equally hard

They look similar and behave nothing alike.

**Fault 1** is the one the example program demonstrates. Every model found it by reasoning. It is not the problem.

**Fault 3** causes half of all the failures — 7 of the 14 — so it is where most of the marks are. It was **never even attempted in 11 of the 27 runs**, and worked out by reasoning exactly once. Almost every run that downloaded the original fixed it; almost every run that did not never considered it.

**Fault 2** is the strange one. Models did not overlook it — they examined it and **pronounced it correct**. One wrote that the code "subtracts twice the AND term, so that's also correct." It does not subtract twice the AND term; that omission is the bug. The correct formula is written in a comment two lines above the broken line. The model read the comment, read the code, and did not notice they disagreed.

That is the real difficulty of this task. Not that any one fault is subtle, but that **nothing tells the agent there are three of them** — so it stops as soon as the visible symptom goes away.

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
