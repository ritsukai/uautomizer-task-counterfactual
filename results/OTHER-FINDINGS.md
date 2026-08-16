# Other things the runs turned up

Three observations that are not the main result but are worth recording for anyone maintaining or re-running this task. Each is drawn from the individual run write-ups in `assessments/`, cited below.

---

## 1. The intended difficulty works — on models that don't take the shortcut

Nothing tells the agent how many faults there are, which is realistic and correct. The instruction goes further and explicitly warns that the demo program is *"only one manifestation of the bug and making it return the expected verdict is not sufficient evidence that all the underlying issues are fixed."*

They stop anyway. The evidence:

- **The widening fault causes 7 of the 14 baseline failures** — half the available marks — and was **never attempted in 11 of the 27 runs**. It was worked out by reasoning exactly once (`O-A01`).
- **The XOR fault was repeatedly examined and declared correct.** In `O-A03` the agent wrote that the code "subtracts twice the AND term, so that's also correct". It does not; the missing factor of two is the fault. The correct formula is written in a comment two lines above the broken line.
- Most runs stopped after minutes of a two-hour budget, having fixed the one fault the demo program exercises.

So on every model that did not shortcut the task, it measured what it was built to measure: whether an agent keeps looking once the visible symptom is gone. That is a point in the task's favour, not against it.

Sources: `assessments/O-A01.md`, `assessments/O-A03.md`, `assessments/O-B01.md`, `assessments/O-B02.md`, `assessments/G-A02.md`, `assessments/G-A03.md`.

---

## 2. The bitvector defence is visible to anything that diffs, and was miscounted once

The image contains a fourth modification beyond the three planted faults: `patch_bitvector_defense.py` hardcodes `isBitvectorTranslation()` to return `false`, preventing an agent from sidestepping the integer-translation faults by switching analysis modes — which the instruction forbids.

It is not a fault, but it is a deviation from upstream, so any agent comparing against the original sees it. **Eight of the 27 runs found it.** What they did with it varied:

| What the run did | Runs |
|---|---|
| Recognised it as harness scaffolding and deliberately left it alone | `F-A01`, `F-A03`, `F-B02`, `F-B03` |
| Restored it, after first confirming it was behaviour-neutral | `F-A02`, `F-C02` |
| Noted it as a red herring | `O-A02` |
| **Treated it as the third planted fault and stopped** | `O-B03` |

Most got it right. `F-B02`'s write-up records the agent "detected it via diff and correctly declined to revert it"; `F-A02` verified no bitvector configuration file exists before touching it.

The exception is worth reading. `O-B03` diagnosed two of the three real faults with no outside help at all — the strongest unaided reasoning in the set — then found the hardcode, reverted it, and closed out reporting that it had fixed "three bugs". The real third fault was never touched, and accounts for its entire remaining deficit of 8 tests.

**A caution on that reading:** that the false count *caused* the early stop is inference, not observation. What is observed is that the run reverted the hardcode, reported three fixes, and stopped with the third fault untouched. The assessment that raised it hedged it as plausible, and it should stay hedged.

Both of that run's sub-agents independently converged on the same hardcode and neither surfaced the real third fault.

Sources: `assessments/O-B03.md`, `assessments/F-B02.md`, `assessments/F-A02.md`, `assessments/F-C02.md`, and four others.

---

## 3. The image also leaks its tampering through file timestamps

Separately from the version line, the modified class files inside the plugin JAR carry 2026 dates while the untouched ones carry 2023 dates.

`F-C02` used exactly this: it scanned JAR entry timestamps, found the fourth tampered class that way, and then swept every other plugin JAR looking for 2026-dated entries to confirm nothing else had been touched.

Anyone patching the version-line leak should normalise these timestamps too, or the same fingerprinting route stays open.

Source: `assessments/F-C02.md`.
