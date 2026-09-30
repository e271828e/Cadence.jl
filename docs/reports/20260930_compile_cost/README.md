# Compile cost of the build and the executor — 2026-09-30

Start with the **[report](report.md)**: where time-to-first-simulation
goes at tip `82c23d5`, the three mechanisms behind the per-topology cost,
the per-type term, the `Dual` re-measurement, the alternatives measured,
and the ordered roadmap.

`probes/` holds every script the numbers come from. Run each from a scratch
export of `82c23d5` with the workspace `Manifest.toml` copied beside it,
`julia --project=<export> probes/<script>.jl`, or `--project=<export>/test`
for the ones that use BenchmarkTools (`dyn.jl`, `oc.jl`, `heavy.jl`).
`nospecialize_patch.sh` applies §3's patch to an export;
`trace_diff.py` attributes a `--trace-compile-timing` diff between two runs.

The report answers the compile-cost entry of `docs/design/pending.md`. It is
frozen evidence at that tip; the rulings and their consequences land in
`docs/design/`.
