# Design lineage

Two design revisions were publicly hashed on issue #1541 before any trials ran. This file records both, so the pre-registration claim can be checked against the right one.

| Revision | SHA-256 | Posted | Content |
|---|---|---|---|
| v1 | `0a7f30ac8276c1fb72ed264a627537b7b2fdcaa37ee3c984c54c5cf3fbca1bcd` | 2026-08-12 17:31 UTC | Three arms, Claude Code + Fable 5 only |
| **v1+A1** | **`788ca364f417317e6b56bb172e4e89920926048a3e5bd147aeb76486a11adc43`** | **2026-08-13 15:16 UTC** | **Four setups, after a maintainer asked for the original agent configurations** |

**`DESIGN.md` in this repository is v1+A1** — the revision the runs executed under. `runner/run-trials.sh` names that hash in its header comment.

## Why there are two

The first design proposed three arms on a single agent configuration. In the thread, Anjiang-Wei asked that the counterfactual use the same three agent setups as the original evaluation, since the task's difficulty was established with those. The design was amended to four setups: the three acceptance-era configurations plus the Fable pair, so the results speak to both "does the task hold up as accepted" and "does it hold up against today's agents". The amended design was re-hashed and the new hash posted before trials began.

A pre-hash amendment is also recorded inside `DESIGN.md` itself: the confirmatory sample was reduced from five to three valid trials per arm, and a pre-declared maintainer-extension rule was added, both by operator decision after cost review and both disclosed before the hash.

## Verify

```sh
shasum -a 256 DESIGN.md
# 788ca364f417317e6b56bb172e4e89920926048a3e5bd147aeb76486a11adc43
```

Cross-check that value against the comment posted to [#1541](https://github.com/harbor-framework/terminal-bench/issues/1541) on 13 August 2026, which predates the first valid trial in `ledgers/`.

## What pre-registration does and does not establish here

It establishes that the arms, the trial count, the ordering, the coding rubric and the interpretation table were fixed before results existed — so the analysis could not be shaped to fit them.

It does **not** establish independence from the run owner. The hash was posted by the same party that ran the trials; a local pre-registration is discipline, not proof against the person keeping it. The raw artifacts are available so that the discipline can be audited rather than trusted.
