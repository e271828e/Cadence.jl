# Unit C1 rulings: §10.5 from its opening to "Assemblies"

Old lines are spec lines at `08f5dff`; log lines are `decisions.md` as of
this rewrite.

## Ruled edits applied

- **R10.** "All due `s_update` calls run after the sweep" became "after
  quiescence" (old 5257).

- **R7.** Deleted "The 'tick at `t₀⁻`' story they once told held only in the
  build's own world, because the probe runs before any condition exists"
  (old 5248–5250). Mapped to D-205 Rationale, log 7261–7263 ("§10.5's
  content defense … held only in the build's own world, the probe running
  before any condition exists"). The rule before it and the phase-free remark
  after it stay.
- **R8, F7.** "`t = k·h`" became "`t = t₀ + k·h`" (old 5166).
- **R8, F14.** "The FCS cascade" gained one introducing clause: "a flight
  control system's outer loops feeding its inner loop". Source:
  `companions/flight_case_studies.md` section 2, "`PID` and the C172X FCS",
  where outer compensators feed the inner LQR (`outer.output → inner.input`).

## Corrections proposed

- **Ruled as R10 and applied.** "All due `s_update` calls run after the
  sweep, in any order" (old 5257) now reads "after quiescence". D-020 Position (log 698) says due updates "run
  after quiescence, outside the iteration", and the glossary's *due* entry
  says the same. A boundary runs one sweep per round, so "after the sweep"
  can read as after each round's sweep.

## Citations added or replaced

- **D-185**, at "neither does a boundary at a localized event time `t*`".
  Rationale only (below). D-147 was cited here first and dropped on the
  verifier's finding: its Position covers only the `t*` half, for a different
  reason. The off-tick half and the `k ÷ N_base` form have no entry (survey
  row 81).
- **§10.4**, beside the same sentence, as the pointer for `t*` at its first
  use in the section.
- **D-185**, at "the build compiles it to two integers per discrete
  component". Rationale only (below).
- **D-185**, at the gate. Rationale only (below).
- **D-019**, moved from the end of the grid paragraph to its first sentence,
  and from the old **Why.** sentence to the ZOH rule. Same paragraphs, so the
  later sentences still cite by adjacency. Position, log 657–658: "Harmonic
  tick grid on step boundaries; discrete stages gated to own tick instants".
- **D-147**, moved from "static rather than a runtime test" to the
  two-variant sentence before it, and added at the interior sweep, the
  boundary sweep and "the split applies to both sweep blocks". Position, log
  4930–4943: "two statically distinct variants compiled from one entry list",
  "The interior sweep walks continuous entries only", "The boundary sweep
  walks the full list, with discrete entries gated by counter modulo against
  the boundary's tick index", "Both blocks split identically".
- **D-147**, at "The due set is computed once for the boundary and reused by
  every re-sweep of its quiescence iteration". Position, log 4950–4952: "The
  due set is a property of the boundary, computed once and reused by every
  re-sweep of its quiescence iteration".
- **D-185 and D-205**, at "the due set is everything with `Φ = 0`" at
  boundary zero. D-185 Rationale only (below). D-205:
  Position, log 7247–7248: "`g` updates remain gated by `Φ` — an offset
  component's first consumed sample stays its `Φ·Δt_base` tick's", amending
  D-185's boundary-zero consequence "whose gate composition and residue
  invariant stand". D-147 Position (log 4956) still says "everything at
  boundary zero", stale since D-185 and D-205, so it is not cited here. The
  log owes D-147 an annotation (survey part E, "Stale entry text").
- **D-019**, added at "An assembly is virtual for execution". Position, log
  658–659: "assemblies virtual for execution, rate scopes for declaration".

## Rationale-only rulings

- **D-185, Rationale**, log 6498–6500: "all scoping still compiling to one
  `(D, Φ)` pair per discrete component". Cited and bold at "the build
  compiles it to two integers per discrete component". The log owes a
  Position.
- **D-185, Rationale**, log 6500: "the boundary gate is `(idx − Φ) % D ==
  0`". Cited and bold at the gate. The log owes a Position.
- **D-185, Rationale**, log 6502: "`t*` emptiness remaining arity selection
  (no sentinel index fails every gate)". Cited at "neither does a boundary at
  a localized event time `t*`". The log owes a Position.
- **D-185, Rationale**, log 6503–6505: "everything with `Φ = 0`, implemented
  by nothing — the ordinary gate at index 0 under the residue invariant".
  Cited beside D-205 at boundary zero's due set. It also carries "Nothing
  implements this rule. It falls out of the ordinary gate." The log owes a
  Position.

## Inbound citations affected

- None that rely on moved or deleted content. No file links a `####` anchor
  of chapter 10 (survey part C), so the retitled labels are free.
- D-205 Rationale (log 7261) quotes "§10.5's content defense" as history. R7
  deletes the sentence that echoed it; the log's account stays true as
  history.
- Pre-existing, unchanged by this unit: `extensions.md` 47 says §10.5
  "records why atomic subsystems are an artificial-loop factory". §10.5
  states only that no coarsening is needed; the artificial-loop argument is
  D-019 Rejected (log 673–674).

## Open questions

- Resolved: the interior-sweep sentence is plain, keeping its D-147
  citation. Unit B1's "Trial evaluations run the interior sweep" bolds the
  same D-147 Position sentence and comes first in reading order, so it keeps
  the bold.

- Bold weight. D-147's Position has five sentences that §10.5 states. Four
  are bold here: the two variants, the boundary sweep, both blocks, and the
  due set. The interior sweep's sentence is bold in unit B1, and the arity
  sentence in §9.7. If four bolds from one entry read heavy, the boundary
  bullet could share the two-variant bold as an elaboration of one ruling.
- No glosses were added for *component*, *tick*, *guard* and *tier* beyond
  their links, where a gloss would break a short sentence. *Sweep*
  got a defining sentence instead of a parenthesis, and so did *probe*,
  linked at its first use with its glossary entry's wording.
