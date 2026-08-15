# Things we got wrong

Three conclusions were reached, stated as fact, and later found to be wrong. Each one changed an answer. They are recorded here because a study that hides its corrections is worth less than one that shows them.

All three failed the same way: **we read an unfinished repair as a broken one.**

## 1. We were measuring from the wrong starting point

**What we said:** that runs scoring 12 or 13 out of 22 showed the models "overcorrecting" — that they had fixed the original fault but broken other things in the process, turning a missed-bug problem into a false-alarm problem.

**What is actually true:** the sabotaged tool **already fails 14 of the 22 test programs before any AI touches it**, including seven of the eleven programs that are supposed to come out safe. A run scoring 12 out of 22 had *repaired four programs*. It broke nothing.

We had been silently measuring against a perfect score, as though the tool arrived working and the models damaged it. It arrives broken. That is the entire premise of the task.

**How it was caught:** while assessing one run, the assessment went and read the output of a control run in which the AI was allowed only a single step and could not meaningfully act. That control is effectively the untouched tool. It reported that six of the eight "safe" programs that run supposedly broke were already failing before the run started. Nothing had asked it to check this.

**What changed:** every score in this repository is now given both as a raw score and as an improvement over the true 8-out-of-22 starting point. The "models break things" story was mostly an artifact of our arithmetic. Genuine over-repair does happen — in two runs out of 27 — but it is the exception, not the pattern.

## 2. We attributed a sentence to the wrong instruction

**What we said:** that the plainest instruction already nudged the AI toward the original open-source project, by telling it the code "may be derived from a public open-source project" — and therefore that Fable's habit of going to find that project was simply following instructions.

**What is actually true:** that sentence belongs to the *middle* instruction. The plainest one says nothing whatsoever about open source, upstream code, or comparison. Its only related line is a closing warning not to look up solutions specific to the task.

**How it was caught:** one assessment checked the instruction text in the run's own record rather than trusting the description it had been given, and reported the discrepancy.

**What changed:** our judging standards carried the wrong premise for part of the work and were corrected in place, with a dated note. The judgements themselves rest on observable actions and are unaffected, but any commentary about what the plainest instruction "invited" is void.

Note that this correction makes the finding **stronger**, not weaker. With no hint of any kind — and a warning against looking things up — Fable located the original project by itself, three times out of three.

## 3. We had the direction of Fable's method backwards

**What we said:** early on, based on a quick scan of when things happened, that Fable diagnosed the faults itself and then used the original source to check its work.

**What is actually true:** the opposite. In all nine of its runs, the comparison against the original both *found* the faults and *supplied* the corrections. In one run it began downloading before it had even read the broken file; in another, before its own reproduction of the bug had finished running. The confident explanations in its closing summaries were written afterwards.

**How it was caught:** by applying the actual judging standards to the full records, instead of searching for keywords and inferring an order from where they appeared.

**What changed:** the finding reported to the maintainers is that a publicly available original **does** let a capable model shortcut this task — which is closer to the original concern raised in the issue than our first reading suggested.

---

A fourth mistake was caught before publication rather than after. While writing up the assessments, one run's account was briefly written using a different run's timeline. The two are genuinely different — one made seven web searches and partly worked the fault out itself; the other explicitly declined to look for the original at all. The file was rewritten from the correct source, and a check now confirms all 27 accounts match the runs they describe.
