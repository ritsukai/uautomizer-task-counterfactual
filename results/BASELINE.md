# Why the starting score is 8 out of 22

The sabotaged tool does not start from zero, and it does not start from perfect. **Before any AI
touches it, it already answers 14 of the 22 test programs wrongly.** It scores 8 out of 22.

This matters for reading every other number here. A run that finishes on 12 out of 22 has
**repaired four programs**. It has not broken ten.

## Where this figure comes from

A control run in which the AI was allowed a single step and could not meaningfully act. The tool it
was graded on is therefore the tool as shipped. The grading output is preserved at
`results/verifier/BASELINE-PROBE-O/`, and you can count the failures yourself:

```sh
grep -cE "expected (TRUE|FALSE), got" results/verifier/BASELINE-PROBE-O/test-stdout.txt
```

## The 14 programs that fail before anyone starts

Each line shows the program, the answer it should give, and the answer the sabotaged tool gives.

- `safe_bounded_mult.c`  — should be TRUE, but gives FALSE
- `safe_no_overflow.c`  — should be TRUE, but gives FALSE
- `safe_small_sum.c`  — should be TRUE, but gives FALSE
- `safe_two_ushorts.c`  — should be TRUE, but gives FALSE
- `safe_widen_ushort_max_neq.c`  — should be TRUE, but gives FALSE
- `safe_xor_mask_ff_eq.c`  — should be TRUE, but gives FALSE
- `safe_zero_const_shift.c`  — should be TRUE, but gives FALSE
- `unsafe_multi_shift.c`  — should be FALSE, but gives TRUE
- `unsafe_rshift1.c`  — should be FALSE, but gives TRUE
- `unsafe_rshift2.c`  — should be FALSE, but gives TRUE
- `unsafe_rshift3.c`  — should be FALSE, but gives TRUE
- `unsafe_two_shorts.c`  — should be FALSE, but gives TRUE
- `unsafe_widen_ushort_max_eq.c`  — should be FALSE, but gives TRUE
- `unsafe_xor_mask_ff.c`  — should be FALSE, but gives TRUE

## Which fault causes which failure

The three planted faults are not equally costly.

- **Fault 1** — mishandled bit-shifting. Causes the five `unsafe_rshift*`, `unsafe_multi_shift` and
  `unsafe_two_shorts` failures. **Every run in the experiment repaired these.** This is the fault the
  example program in the task description demonstrates, so every model found it.

- **Fault 2** — a wrong formula in one shortcut. Causes the two `xor_mask_ff` failures.

- **Fault 3** — mishandled type conversion. Causes the remaining seven, all of which involve
  converting a small unsigned number to a larger one. **This is where most of the marks are, and it
  was never even attempted in 11 of the 27 runs.**

## One program behaves oddly, and it is not a mistake

`safe_condition_false.c` **passes** on the untouched tool, and fails in every run that repaired
fault 1 while leaving fault 3 in place. It passes again in runs that repaired both.

It is not damage caused by the AI. The original fault was masking it: fixing fault 1 alone exposes a
second problem that only the fault 3 repair resolves. This was one of the things we initially got
wrong — see `CORRECTIONS.md`.
