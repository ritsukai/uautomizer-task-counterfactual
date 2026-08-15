# Baseline: the untouched image

Before any agent touches the task, the shipped image already fails **14 of 22** hidden programs.
It scores **8/22**.

This is measured from `PROBE-O`, a `max_turns=1` probe in which the agent could take no
meaningful action. Its verifier output is preserved at `results/verifier/BASELINE-PROBE-O/`.

Every score in `results/MASTER-SUMMARY.tsv` is reported both absolutely (`score`) and relative to
this baseline (`delta`). A trial at 12/22 has **repaired four** programs, not broken ten.

## The 14 programs that fail before any agent runs

- `safe_bounded_mult.c`: expected TRUE, got FALSE
- `safe_no_overflow.c`: expected TRUE, got FALSE
- `safe_small_sum.c`: expected TRUE, got FALSE
- `safe_two_ushorts.c`: expected TRUE, got FALSE
- `safe_widen_ushort_max_neq.c`: expected TRUE, got FALSE
- `safe_xor_mask_ff_eq.c`: expected TRUE, got FALSE
- `safe_zero_const_shift.c`: expected TRUE, got FALSE
- `unsafe_multi_shift.c`: expected FALSE, got TRUE
- `unsafe_rshift1.c`: expected FALSE, got TRUE
- `unsafe_rshift2.c`: expected FALSE, got TRUE
- `unsafe_rshift3.c`: expected FALSE, got TRUE
- `unsafe_two_shorts.c`: expected FALSE, got TRUE
- `unsafe_widen_ushort_max_eq.c`: expected FALSE, got TRUE
- `unsafe_xor_mask_ff.c`: expected FALSE, got TRUE

## Which defect governs which

- **D1** (constant-shift wraparound) governs the five `unsafe_rshift*` / `unsafe_multi_shift` /
  `unsafe_two_shorts` programs. Every trial in the dataset repaired these.
- **D2** (XOR identity) governs `unsafe_xor_mask_ff` and `safe_xor_mask_ff_eq`.
- **D3** (unsigned widening) governs the remaining seven, all of which involve
  `(unsigned int)<narrow>` widening. **D3 is the single largest scoring lever and was never
  attempted in 11 of 27 trials.**

## One program behaves specially

`safe_condition_false.c` **passes** at baseline and fails in every trial that repaired D1 while
leaving D3 broken; it passes again in trials that repaired both. It is a masking artifact, not a
regression introduced by any agent. See `CORRECTIONS.md` §1.
