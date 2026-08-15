# What this evidence does not prove

Read this before citing anything here.

## 1. The mechanism codings are not comparable across models

This is the most serious limitation, and it cuts against the headline.

All nine **Fable 5** transcripts have **fully redacted reasoning** — thinking blocks are present but contain zero characters, only signatures. The **Opus 4.6** transcripts contain condensed but contemporaneous reasoning. The **GPT-5.4** (codex) transcripts contain no reasoning items at all.

The frozen rubric codes provenance from *observable* evidence and explicitly refuses to credit retrospective claims. A model whose reasoning is invisible therefore **cannot earn a `LOCAL` code**, however much local diagnosis it actually performed; a model whose reasoning is visible can.

So "Fable was upstream-led, Opus was hybrid" is **not a clean capability comparison** — part of that difference is a logging difference. Fable's *actions* are unambiguous (in `F-C01` it fetched upstream ~30 seconds in, before its own reproduction had finished), but its reasoning is unavailable and may have contained diagnosis we cannot see.

## 2. Both arm C failures were tooling failures, not reasoning failures

`G-C03`'s single upstream fetch returned an **empty result**; it never retried by any other method. `O-C03`'s WebFetch returned a **1,575-character English summary instead of source code**, so the XOR hunk was never exposed; its retry narrowed the request to a method it had already diagnosed.

Arm C is therefore better described as **4 of 4 when the fetch worked, 0 of 2 when it silently degraded**. The same WebFetch summarisation also hit `O-C01` and `O-C02`, which recovered by falling back to `curl`. Four of six arm C trials were affected by one tool's behaviour.

This claim rests on two coders' independent reads of those transcripts. It has not been separately verified.

## 3. Three trials per cell

n=3 per model per arm. One flipped trial changes a headline. `G-C03` demonstrates this directly: had it landed in block 1 instead of block 3, arm C would have looked meaningfully weaker at the point we were forming conclusions.

## 4. Single task, single day, live endpoints

One task. All trials 14–15 August 2026. The models are live API endpoints that may change; these results are not reproducible in the strong sense, only re-runnable.

## 5. The CLI build is not the leaderboard build

The design pins Claude Code 2.1.228 for reproducibility. The exact build used in the June leaderboard submission was never established. Comparability is exact for agent/model/effort, **not** for CLI build.

## 6. There is no Gemini leg

The design specified four setups. Gemini could not run as specified — the CLI silently substituted a 2.5-series model for the requested 3.1 Pro ([gemini-cli#28825](https://github.com/google-gemini/gemini-cli/issues/28825)). The leg was cut rather than run under a different model than declared. Its evidence is preserved in `gemini-substitution/`.

## 7. Byte offsets point into transcripts that are not published here

The codings cite offsets into agent transcripts held back from this repository (see README). Those citations are checkable only once you request the transcripts. This is an honest cost of publishing a curated set; requests will be honoured.

## 8. Some per-program attributions are inferred, not measured

Where a coding attributes a specific failing program to a specific unfixed defect, that is usually inferred from program names, the defect's semantics, and cross-trial comparison — not from a controlled re-run. `O-A03`'s coder additionally notes that agents hot-swap a recompiled `.class` into the shipped JAR **without verifying the source tree reproduces that JAR**, so source/binary drift cannot be excluded as a contributor to some flips.

## 9. Conflict of interest

The headline result favours Fable 5. The experiment was orchestrated, and these transcripts were coded, using Claude models — the same family. The coding rubric was frozen before any coding began, and the raw transcripts are available so any coding can be disputed, but the conflict is real and is not neutralised by those safeguards.

Relatedly: this repository, its analysis, and the accompanying issue comment were produced with substantial AI assistance. The pre-registration, the arm design, and every publication decision were made by the human author; the execution and coding were not.

## 10. Three conclusions were reached and then corrected

See `CORRECTIONS.md`. Each was wrong in the same direction — reading incompleteness as damage — and each was caught only by checking a specific artifact. That pattern is itself a caution about the rest.
