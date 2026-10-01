# A readability rewrite of spec §9.4 — 2026-10-01

Start with the **[report](report.md)**: five rewrites of §9.4, what each
round's verifiers found, the writing convention agreed for a full rewrite of
the spec, the no-loss method, and how to delegate it.

- `versions/` holds the section as of `d9b2711` (`v0_spec.md`), the five
  rewrites, and the three log entries Versions 3 to 5 cite.
- `checks/` holds the mechanical check, the claim inventory for Versions 1 to
  4, and the PDF build.
- `experiment/` holds Version 5's inputs: the claim list, with and without its
  source spans, the glossary excerpt, and the writer's notes.
- `verification/` holds the blind verifiers' claim lists and reports for
  Versions 1 and 5. Later rounds are summarized in the report.

From this directory, `python3 checks/check.py versions/v4_flat.md 4 --bold`
checks Version 4 against the original, and `checks/build_pdf.sh` renders
every version with `design.pdf`'s settings into `samples.pdf` (untracked).

The report is frozen evidence. The convention lands in
`docs/design/tools/spec_style.md` when a rewrite is adopted.
