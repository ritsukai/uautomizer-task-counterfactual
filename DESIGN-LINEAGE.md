# Why there are two published versions of the design

The point of writing the design down and publishing a fingerprint of it *before* running anything is that nobody can later reshape the plan to fit whatever the results turned out to be. That only works if it is clear which version governs.

There are two. Both were published openly, in the discussion thread, before any run they applied to.

| Version | Published | What it said |
|---|---|---|
| First | 12 August 2026, 17:31 UTC | Three instruction conditions, tested on one AI model. |
| **Second — the one that governs** | **13 August 2026, 15:16 UTC** | **Three instruction conditions, tested on four model setups.** |

**`DESIGN.md` in this repository is the second version** — the one the runs were actually carried out under. The script that ran the experiment names its fingerprint in its opening comment.

## Why it was revised

The first version proposed testing a single AI configuration. In the discussion, a maintainer asked that the test use the same three model setups that were used when the task's difficulty was originally established — reasonably, since a result on a different model says little about whether the original judgement still holds.

The design was widened to four setups: the three original ones, plus the current leaderboard-leading pair. That way the results speak to two different questions at once — whether the task still holds up as it was accepted, and whether it holds up against today's strongest agents.

The revised design was published, with a new fingerprint, before any run began.

The design document also records one earlier change made before its own fingerprint was fixed: the number of attempts per condition was reduced from five to three after a cost review, and a rule was added in advance covering what would happen if a maintainer asked for more. Both were disclosed at the time rather than discovered later.

## Checking this yourself

```sh
shasum -a 256 DESIGN.md
```

Compare the result against the fingerprint posted in the discussion thread on 13 August 2026. That message is timestamped earlier than the first valid run recorded in `run-log/`.

## What this does and does not establish

**It does establish** that the conditions, the number of attempts, the order they ran in, the standards for judging them, and the way results would be interpreted were all fixed before any result existed. The analysis could not have been bent to fit the findings, because the findings did not exist yet.

**It does not establish independence.** The fingerprint was published by the same person who then ran the experiment. Writing your plan down in advance is a discipline you impose on yourself; it is not proof to someone who does not trust you. That is why the underlying records are published too — so the discipline can be audited rather than simply believed.
