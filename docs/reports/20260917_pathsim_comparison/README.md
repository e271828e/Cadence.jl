# Cadence.jl versus PathSim — 2026-09-17

Start with the **[report](report.md)**: features, performance, usability,
mathematical rigor and code quality, against PathSim 0.25.1.

`probes/` holds every script the report's numbers and claims come from: the
two benchmarks, the two PathSim probes (missed event cascade, numerical
feedthrough misclassification) and the fan-out check on Cadence's side.

Cadence is assessed as if every `pending.md` item were built. The report
changed one line of source: the fan-out hint on `FaceNameCollision`'s
assembly arm.
