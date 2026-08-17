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

## How runs are named

Every run has a three-part name like **`F-A01`**:

| Part | Meaning |
|---|---|
| first letter | which model — **F** = Fable 5, **O** = Opus 4.6, **G** = GPT-5.4 |
| second letter | which instruction — **A**, **B** or **C**, as in the table above |
| number | which of the three attempts |

So `F-A01` is Fable 5's first attempt under the plainest instruction. Every file about that run uses that name.

## What is in this repository

**Start here**

| File | What it is |
|---|---|
| `LIMITATIONS.md` | What this evidence does **not** establish. Read before quoting anything. |
| `CORRECTIONS.md` | Three conclusions we reached, published, and then found to be wrong. |
| `results/BASELINE.md` | Why the starting score is 8 out of 22, and which programs already fail. |

**The results**

| Path | What it is |
|---|---|
| `results/MASTER-SUMMARY.tsv` | One row per run: score, improvement, and a summary of how it worked. |
| `results/OTHER-FINDINGS.md` | Three side observations for anyone maintaining the task: that its intended difficulty does work, that the anti-bypass defence is visible to any agent that compares against the original, and that file timestamps leak the tampering too. |
| `results/verifier/<run>/` | The grading program's own output for that run — which test programs passed, which failed, and the final score. |
| `results/verifier/BASELINE-PROBE-O/` | The same, for the untouched tool. This is where the 8-out-of-22 figure comes from. |

**How each run was judged**

| Path | What it is |
|---|---|
| `assessments/<run>.md` | A written account of how that run reached its result: whether it worked the faults out or copied them from the original project, and what evidence supports that. |
| `assessments/HOW-WE-JUDGED.md` | The standards used, written down before anyone read a single run. |

**The rules, fixed in advance**

| Path | What it is |
|---|---|
| `DESIGN.md` | The full experiment design, published before any run happened. |
| `DESIGN-LINEAGE.md` | There are two published versions of the design; this explains why, and which one governs. |
| `procedure/` | The script that carried out the runs, and the order they were fixed to run in. |
| `instructions/` | The three instruction texts that were varied, and fingerprints proving these are the ones used. |

**Supporting records**

| Path | What it is |
|---|---|
| `run-log/` | A running log of every run, written as it happened, including the ones that were thrown out. |
| `gemini-finding/` | Evidence that a fourth model could not be tested, because its tool silently substituted a different model than the one requested. |
| `MANIFEST.sha256` | A fingerprint of every file here, so you can confirm nothing has been altered. |

## Checking any of this yourself

You need nothing but a terminal. Replace `F-A01` with any run name.

```sh
# What did this run score? "1" means it solved the task; "0" means it did not.
cat results/verifier/F-A01/reward.txt

# How many of the 22 test programs did it get wrong?
grep -cE 'expected (TRUE|FALSE), got' results/verifier/F-A01/test-stdout.txt
```

Careful with that second command: match the whole phrase as written. Searching for the word
"expected" alone also matches a line the grading tool prints about itself, and you will count one
too many.

```sh
# The starting point: 14 wrong on the untouched tool, so 8 of 22 correct.
grep -cE 'expected (TRUE|FALSE), got' results/verifier/BASELINE-PROBE-O/test-stdout.txt

# Confirm the design really was published before the runs. This prints a fingerprint;
# compare it against the one posted publicly on 13 August, before the first run.
shasum -a 256 DESIGN.md

# Confirm the three instruction texts are the ones actually used.
shasum -a 256 -c instructions/FINGERPRINTS.sha256

# Confirm nothing in this repository has been altered since publication.
shasum -a 256 -c MANIFEST.sha256
```

To understand *why* a run was judged the way it was, open `assessments/<run>.md`. Each one points
at specific positions in that run's own record, so the judgement can be argued with.

## What is deliberately not here

**The full moment-by-moment records of what each model did** — roughly 14 MB. The assessments quote
from them and cite positions within them. They are available to anyone who asks: open an issue here,
or ask in the discussion thread, and they will be sent. They are held back because publishing
detailed accounts of how three companies' AI systems behave is a significant act in itself, separate
from answering a maintainer's question about one task.

**The task's official solution and its hidden test programs.** These are the answer key. They are
already published in the benchmark's own repository; copying them here would only make them easier
to stumble across.

**The first two days of runs.** They were carried out on an Apple Silicon Mac, where this task
cannot be solved by anyone — see below. They are void, and the log that records them is marked as
such.

## The follow-up: what happens when the leak is closed

After the main results were posted, the version identifier was stripped from the task image and the strongest setup re-run on the unmodified instruction — pre-registered in `extension/EXTENSION-DESIGN.md` before the run. **It passed anyway, and not by finding another route to the version: it never touched the network at all.** It located the modified files by their timestamps and worked out all three faults by reading the code — the way the task intended. The leak was a shortcut, not a crutch. See `extension/RESULTS.md`.

## Problems found along the way, and reported

Three separate faults were discovered while running this experiment. All three were reported to the
projects responsible.

**The task cannot be solved on Apple Silicon computers.** On those machines the tool answers "I
cannot tell" for all 22 test programs, so any run scores zero — with no error message and nothing to
suggest the machine is at fault. It simply looks as though the AI failed. We lost two days to this
before checking, and the check that caught it was running the task's own official solution and
seeing it score zero too. Reported as
[terminal-bench#1601](https://github.com/harbor-framework/terminal-bench/issues/1601).

**The benchmark software does not record which kind of computer a run happened on.** It works this
out in order to build the run, then discards it. Recording it would have made the problem above
obvious in seconds instead of days. Reported as
[harbor#2758](https://github.com/harbor-framework/harbor/issues/2758).

**Google's command-line tool silently ran a different model than the one requested.** We asked for
Gemini 3.1 Pro; the tool returned answers from an older 2.5-series model, with no error and no
warning. This is why there is no Gemini in the results — we cut it rather than publish numbers under
the wrong model's name. Reported as
[gemini-cli#28825](https://github.com/google-gemini/gemini-cli/issues/28825).

## Who ran this, and how

Run by [@ritsukai](https://github.com/ritsukai) on rented Intel/AMD servers, 14–15 August 2026.

The benchmark software was harbor version 0.21.0; the task collection was pinned to a fixed version
so it could not change mid-experiment.

The runs were orchestrated, the records assessed, and this write-up drafted with substantial help
from AI. The experiment's design, the decision of what to publish, and every judgement call about
framing were made by the human author. `LIMITATIONS.md` explains why that matters for how much
weight to give the results.
