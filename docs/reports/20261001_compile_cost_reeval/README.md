# Compile cost re-evaluation, 2026-10-01

Start with the **[report](report.md)**. It re-evaluates the roadmap of the
[2026-09-30 compile-cost report](../20260930_compile_cost/report.md) at tip
`2556df4`: each mechanism as a source patch, alone and combined, on three
model scenarios, at `-O2` and `-O0`, with the mechanism behind every number.
It corrects several of that report's conclusions and supersedes its roadmap.

- `probes/`: the harness. `fixtures.jl` defines the components and the three
  scenarios. `measure.jl` is one measurement in one process. `run_matrix.jl`
  runs a job list and resumes from its output file. `tabulate.py` aggregates.
  `mechanism.jl` records the code size of the loop methods. `anchor.jl`
  reproduces the earlier report's headline at this tip.
- `patches/`: every variant, each a `diff -ru` against the `2556df4` export.
  `recommended.patch` is the stack the report recommends. The four
  `stage2` to `stage5` patches split it for landing, numbered by the brief's
  stages; they apply in order and sum to it exactly; `docs/design/briefs/brief_increment_58_compile_cost.md` is the
  brief that lands them.
- `results/`: one line per run, the mechanism table, the gate log.
- `agent_reports/`: the long tables of the four agents that wrote the larger
  patches.

## Measuring again

The numbers hold at `2556df4` only. To reproduce a cell:

    git archive 2556df4 | tar -x -C <scratch>/base && cp Manifest.toml <scratch>/base/
    cp -R <scratch>/base <scratch>/<name> && (cd <scratch>/<name> && patch -p1 < patches/<name>.patch)
    julia -O2 --project=<scratch>/<name>/test probes/measure.jl <scenario> <mode> <chunk_size>

`measure.jl`'s header defines the scenarios and modes. For a whole matrix:

    julia probes/run_matrix.jl <scratch> probes/jobs_final.txt <out_file> 2
    python3 probes/tabulate.py <out_file> 2

Time at top level, one process per measurement. Implement a mechanism as a
source patch, never as a wrapper in a probe script: the earlier report's two
largest errors came from wrappers that measured something else.
