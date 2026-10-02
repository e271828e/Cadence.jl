# Chapter 10: ruled edits applied before step 6b

Rulings from `rulings_batch.md` (items and its "Status" section).

| ruling | unit (claim) | old wording | new wording |
|---|---|---|---|
| K7 | C1 (C1-016) | "… at a localized event time `t*` ([§10.4][s10-4], [D-185][d-185])." | "… at a localized event time `t*` ([§10.4][s10-4], [D-185][d-185], [D-288][d-288])." |
| K10 | A (A-033) | "No backend ever faces `N = 0`, and no backend contract …" | "No backend ever faces a state count of `N = 0`, and no backend contract …" |
| K11 | B1 (B1-089) | "ITP or Brent are the intended methods, …" | "ITP (the interpolate-truncate-project method) or Brent's method are the intended methods, …" |
| K11 | B1 (B1-091) | "Newton and AD localization are rejected …" | "Newton and AD (automatic differentiation) localization are rejected …" |
| K12 | A (A-077), §10.3 | "The [boundary sweep](#g-sweep) in the [§5.3][s5-3] sequence …" | "The boundary sweep in the [§5.3][s5-3] sequence …" |
| K12 | B1 (B1-084), §10.4 | "… and running the [interior sweep](#g-sweep)." | "… and running the interior sweep." |
| K12 | B1 (B1-040), §10.4 | "… before the due-gated [boundary sweep](#g-sweep) refreshes …" | "… before the due-gated boundary sweep refreshes …" |
| K12 | E (E-010), §10.7 | "Its [sweep](#g-sweep) cost is absorbed as [debt](#g-pacing) (wall time …" | "Its [sweep](#g-sweep) cost is absorbed as debt (wall time …" |

K12 sweep of the other sections: a script counted glossary links per `###`
section of `chapter_new.md`. Before the edits only §10.3 (`#g-sweep` ×2),
§10.4 (`#g-sweep` ×3, B1 and B2 together) and §10.7 (`#g-pacing` ×2) had
repeats. §10.1, §10.2, §10.5 and §10.6 had none. After the edits no section
links one anchor twice.

Not done here, outside this step's files: K7's follow-ups (drop the case from
C1's Rationale-only list; add §10.5 to D-288's Spec field in K26) and K12's
`spec_style.md` sentence.
