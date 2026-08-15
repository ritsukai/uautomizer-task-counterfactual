# What this evidence does not prove

Read this before quoting anything from this repository.

## 1. The three models were not observed equally, so comparing *how* they worked is unsafe

This is the most serious problem here, and it cuts against the headline result.

When these AI systems work, some of them write down their reasoning as they go and some do not. In this experiment:

- **Fable 5** recorded *nothing* of its reasoning. The slots where its thinking would appear are present but empty in all nine of its records.
- **Opus 4.6** recorded a condensed version of its reasoning.
- **GPT-5.4** recorded none either.

Our method for judging *how* a run reached its answer deliberately relies only on what can be seen: actions taken, files read, things downloaded, edits made, and any reasoning actually written down. It refuses to credit explanations a model gives *afterwards*, because a model that copied an answer can still describe it fluently once it has seen it.

That rule is sound on its own, but it has an unfair consequence here. **A model whose thinking is invisible can never be credited with having worked something out**, no matter how much thinking it actually did. A model whose thinking is visible can.

So the statement "Fable copied, Opus partly reasoned" is **not a clean comparison of ability**. Part of that difference is a difference in what got written down.

What survives this objection: Fable's *actions* are not in doubt. In one run it downloaded the original source about thirty seconds in — before its own attempt to reproduce the bug had even finished. That is visible regardless of what it was thinking.

## 2. The two failures in the best-informed condition were tool failures, not thinking failures

Two runs were given the exact address of the original code and still failed. Neither failed because the model reasoned badly.

In one, the single attempt to download the file **returned nothing at all**, and the model never tried again by any other means. In the other, the download tool **returned an English summary of the code instead of the code**, so the relevant section was never actually seen; when the model retried, it narrowed its request to a part it had already understood.

So that condition is better described as **four successes out of four when the download worked, and zero out of two when it silently failed**. The same summarising behaviour also affected two runs that did succeed — they recovered by trying a different download method.

This reading comes from two independent assessments of those records. It has not been separately checked by anyone else.

## 3. Three attempts per box is a small number

Each model attempted each instruction three times. One run landing differently would change a headline.

This is not hypothetical. One run in the best-informed condition failed, and had it happened earlier in the sequence rather than later, our conclusions at that moment would have looked materially different.

## 4. One task, one day, and the models can change

This is a single task. All runs happened on 14–15 August 2026. The AI models are online services that their makers update; these exact results cannot be reproduced in the strict sense, only attempted again.

## 5. The software versions do not exactly match the published leaderboard

The design fixed a specific version of the AI command-line tool so the experiment would be repeatable. The version used in the public leaderboard entry we are comparing against was never established. The comparison is exact for *which model* and *what effort setting*, but not for the tool build around it.

## 6. There is no Gemini here, and that was not planned

The design called for four model setups. Google's tool silently returned an older model than the one requested, so that setup could not be run as specified. We cut it rather than publish results under a model name that was not what actually ran. The evidence is in `gemini-finding/`.

## 7. The assessments point into records that are not published here

Each assessment cites positions in that run's full record. Those records are held back (see the front page) and available on request. Until you request them, those particular citations cannot be checked. That is a real cost of publishing a smaller, readable set, and requests will be answered.

## 8. Some cause-and-effect claims are reasoned, not measured

Where an assessment says a particular failing test program was caused by a particular unfixed fault, that is usually worked out from the program's name, the nature of the fault, and comparison across runs — not from a controlled re-run isolating it.

One assessment raises a further caution: the models rebuild part of the tool and swap the rebuilt piece into place **without ever confirming that the source they compiled matches the version that was shipped**. If those differ, some results could have a cause nobody has accounted for.

## 9. We have a stake in the outcome

The result favours Fable 5. This experiment was orchestrated, and these records assessed, using AI systems from the same family. The standards for judging were written before any record was read, and the raw records are available so any judgement can be disputed — but the conflict of interest is real and those safeguards do not erase it.

More broadly: the runs, the assessments, and this write-up were produced with substantial AI assistance. The design, the decision to publish, and the framing choices were made by the human author. The work in between was not.

## 10. We got three things wrong before getting them right

See `CORRECTIONS.md`. All three mistakes ran the same way — treating an unfinished repair as a broken one — and each was caught only by going back to a specific file rather than trusting our own summary of it. That pattern is itself a reason to check the rest rather than take it on trust.
