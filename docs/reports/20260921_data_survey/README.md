# Data survey, 2026-09-21

A read-only survey of every struct field in `src/` for three smells: dead,
duplicate, misplaced. Five Opus agents, one slice each, at tip `aa9162a`.
The brief is `docs/design/briefs/brief_data_survey.md`.

- `merge.md`: the register of the 22 findings, the grouping into plain fixes
  and rulings, a recommendation per ruling, the questions, the sequencing.
- `a_authoring.md`, `b_build_executor.md`, `c_dataplane.md`, `d_loop.md`,
  `e_services.md`: the slice reports, each with its findings, its clean
  list with field counts, its questions and its coverage.

The reports are frozen evidence at that tip; the rulings and their
consequences land in `docs/design/`.
