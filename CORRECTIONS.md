# Corrections made during analysis

Three conclusions were reached, stated, and then found wrong. Each changed an answer. They are recorded here because a pre-registered study that hides its corrections is worth less than one that shows them.

All three erred in the same direction: **reading incompleteness as damage.**

## 1. The baseline is 8/22, not 22/22

**What was claimed:** that trials scoring 12/22 or 13/22 showed models "overcorrecting" and "breaking safe programs" — turning a soundness bug into a false-alarm bug.

**What is true:** the shipped, untouched image already fails **14 of 22** programs, including seven of the eleven `safe_*` ones. A trial at 12/22 *repaired four tests*. It broke nothing.

**How it was caught:** the coder for `O-A02` went and read the `max_turns=1` probe (`PROBE-O`) as an unmodified-build baseline — something no instruction asked it to do — and reported that six of the eight safe programs that trial "failed" were already failing before the agent started.

**Consequence:** every score in this repository is now stated relative to the 8/22 baseline. The "overcorrection" narrative was largely fictional. Genuine over-repair does exist in two trials (`G-A01`, `G-A03`), but it is the exception, not the pattern.

## 2. Arm A contains no upstream hint

**What was claimed:** that arm A's instruction invited an upstream comparison — "this codebase may be derived from a public open-source project" — and that Fable's upstream lookups were therefore the behaviour the instruction asked for.

**What is true:** that sentence is **arm B's**. Arm A contains no reference to upstream, open source, or comparison of any kind. Its only related line is the closing "Do not cheat by using online solutions or hints specific to this task."

**How it was caught:** the coder for `O-A01` checked the instruction text in `trajectory.json` rather than trusting the framing it had been given, and reported the discrepancy.

**Consequence:** the coding instructions carried the wrong premise for part of the run, and were corrected in place with a dated note. Provenance codes rest on tool chronology and are unaffected, but any narrative about what arm A "invited" is void. The correction makes Fable's arm A result *stronger*: it located the upstream project with no prompting at all.

## 3. Fable's passes were upstream-led, not diagnosis-first

**What was claimed:** early in the analysis, from a shallow grep of event ordering, that Fable's arm A trials showed "reproduce → long local work → then upstream", i.e. diagnosis followed by upstream verification.

**What is true:** the full codings show the opposite. In all nine trials the upstream diff both *located* and *corrected* every defect. In `F-B01` upstream contact began before the agent had read the defective file at all; in `F-C01` it fetched upstream ~30 seconds in, while its own reproduction was still running. The fluent per-defect explanations in the final summaries are retrospective.

**How it was caught:** running the actual rubric instead of a keyword scan.

**Consequence:** the finding reported to the maintainers is that the public baseline **does** collapse the task for the model that finds it — which is closer to the original concern in #1541 than the first reading suggested.

---

A fourth, smaller error was caught before publication rather than after: during transcription, `G-B02`'s coding file was briefly written with `G-B03`'s chronology. They are different runs — G-B02 made seven web searches and codes D1 as `MIXED`; G-B03 explicitly refused the arm-B suggestion and codes D1 as `LOCAL`. The file was rewritten from the correct source, and a check now confirms all 27 codings match their filenames.
