# Rewriting spec chapter 9 for readability — 2026-10-01

Start with the **[report](report.md)**. It is a recipe for rewriting the
remaining chapters of `docs/design/spec.md`: the steps, the agents and their
prompts, the convention, the checks, the cost, and the lessons of this run,
each attached to the step it changed. The chapter itself landed in `9a7d84f`.

The rest of this directory is the run's evidence, listed in the report's
section 7. From this directory:

- `python3 checks/check9.py check <U>` checks a unit's rewrite against its
  original (`show-old` and `show-new` print the normalized texts).
- `python3 checks/boldcheck.py <U>` checks a bold-only edit against
  `units/<U>/new_pretrim.md`, a copy of `new.md` taken just before the edit.
- `checks/assemble.sh` rebuilds `chapter_new.md` from the units.
- `checks/build_pdf.sh` renders the old and new chapters with `design.pdf`'s
  settings into `chapter9.pdf` (untracked).

The report is frozen evidence of this run. The convention lands in
`docs/design/tools/spec_style.md`.
