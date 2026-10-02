# Tuple walks past 32 elements, 2026-10-02

Start with the **[report](report.md)**. It traces three findings of
increment 58's cold review. Two condition-plan walks and the reader gather
allocate past 32 elements, and `run!` allocates about 800 B per frame. It
sweeps `src/` for the same cliff, prototypes a fix and measures it at HEAD
`6be1f17`.

- `patches/walks.patch` is the prototype. It is a `git diff` against the
  `6be1f17` export and passes `git apply --check` at `08f5dff`.
- `probes/` holds one Julia script per measurement. `plan_width.jl` comes
  from the increment 58 review.
- `results/` holds the raw output of each probe, named after it, with `base`
  or `fix` and the widths or the Julia version. `tests_fix_part1.txt` and
  `tests_fix_part2.txt` are the routed test rows on the fixed copy.

## Measuring again

Make two copies of the measured tree, then patch one.

    git archive 6be1f17 | tar -x -C <scratch>/base && cp Manifest.toml <scratch>/base/
    cp -R <scratch>/base <scratch>/fix && (cd <scratch>/fix && patch -p1 < <dir>/patches/walks.patch)

Run a probe from inside a copy, with that copy's root as the argument.

    cd <scratch>/base && julia --project=test <dir>/probes/plan_width.jl <scratch>/base

Every probe takes the root as `ARGS[1]` except three. `a_tail_minimal.jl`
needs no project and no argument. `c_seeds.jl` and `c_seeded_infer.jl` need
`--project=test` and no argument.

Several probes read their widths from `WIDTHS`, a comma-separated list.
These are `a_mechanism.jl`, `c_siblings.jl`, `c_seeds.jl`, `d_compile.jl` and
`d_first_trim.jl`. For example:

    WIDTHS=4,8,16,32,64,128 julia --startup-file=no -O2 --project=test <dir>/probes/d_compile.jl <scratch>/fix

Run `d_compile.jl` in a fresh process per list. Its first width carries the
process's one-time compilation. On the base copy, width 256 takes more than
three minutes. For Julia 1.12, use `julia +release`. Run probes in the
foreground, one at a time.
