# Extension A2 — result

**One trial was run. It passed. Under the stopping rule fixed in `EXTENSION-DESIGN.md` before the run, that ends the extension.**

| Trial | Image | Score | Mechanism |
|---|---|---|---|
| XS-F-01 | version identifier stripped (both sites) | **22/22, pass** | **Local diagnosis — no upstream contact at all** |

## What happened, plainly

With the version leak closed, Fable 5 did not fail, and it did not fall back to some other way of identifying the upstream version. **It never went to the internet at all** — a census of every tool call in the transcript shows zero network access of any kind. It never referenced the zeroed banner, never reasoned about the version, never tried to identify the original project.

Instead it did the task the way the task was designed to be done:

- It noticed the tampered files by their **JAR entry timestamps** — 4 classes rebuilt in 2026 against 233 from 2023 — which bounded the search to three source files. (This is the residual channel the pre-registration disclosed.)
- It then **diagnosed all three faults by reading the code**: the shift fault from the semantics of the lazy wraparound representation, the XOR fault from the contradiction between the code and its own comment two lines above, the widening fault from an internal inconsistency visible in its very first search of the file.
- Its fixes are **structurally different from the original upstream code** — it invented a helper method that does not exist upstream, and changed a label *away* from the upstream text — which rules out the possibility that it was reproducing memorised upstream code.
- It decided it was finished the way none of the failing models did: the timestamp evidence gave it a provably complete list of modified files; it wrote a 12-program test battery in both directions (including the must-pass-safe cases that catch over-fixing) and went 12 for 12; and it swapped the original broken build back in to prove its second and third fixes were actually load-bearing.

## Reading, per the pre-registered interpretation

The pre-registration committed: *any pass → the exact-commit leak was not necessary, and the assessment must trace which residual route was used.*

The route was: **timestamps for locating the modified files, and genuine reasoning for everything else.** The version identity — the thing the banner leaked, and the thing the task's difficulty argument centres on — was never recovered and never needed.

Two consequences for the task decision:

1. **The task's intended difficulty is real, and this agent passes through it, not around it.** The leak was a shortcut it took when available — every original pass was upstream-led — not a crutch it needed.
2. **Timestamp normalisation is now the live recommendation.** The banner strip worked as designed, but the JAR timestamps handed the agent a complete map of what was modified. Normalising them (as the source tree already does — the image touches all `.java` files to 2023) would close the last cheap localization channel. Whether the task survives *that* is a further question this extension does not answer.

## Honesty notes

- One trial. The stopping rule was fixed in advance precisely because a single pass is an existence proof; it is not a pass *rate*.
- Fable's reasoning was again fully redacted, so "local diagnosis" is coded from observable actions — reads, greps, edits, and the contemporaneous comments it wrote into the code — under the same evidence hierarchy as the original 27. The structural differences between its fixes and the upstream code are the strongest available evidence that the diagnosis was genuine.
- The agent also reverted the task's bitvector defence hardcode (believing it a fourth injected fault), but verified before finishing that the graded configuration was unaffected. All five verifier guards passed.
- Same conflict of interest as the main experiment: the result favours Fable, and the run and assessment were done with Claude models, against a rubric frozen before any transcript was read.

## Files

- `EXTENSION-DESIGN.md` — the pre-registration, committed before the run (hash in commit history)
- `armAS-vs-armA.diff` — the complete 3-file, 61-line modification that created the stripped variant
- `XS-F-01.md` — the full trial assessment with byte-offset evidence
- `verifier/XS-F-01/` — the grader's own output
- `ledger.tsv` — the run record, including the oracle gate and baseline probe on the stripped image
