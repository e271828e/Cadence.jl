# Unit A rulings: the chapter heading, §10.1, §10.2 and §10.3

Line numbers are `spec.md` lines at `08f5dff` unless marked `log`
(`decisions.md`). Claim ids are `inventory.json`'s.

## Corrections proposed

None new. The ruled corrections applied here are R1, R2, R3 (4704–4706), R6
and F13 (R8); see the inventory's `R` tags.

## Citations added or replaced

| claim | entry | words that rule it |
|---|---|---|
| A-005, all six activities are framework code | D-017 Position, log 601 | "Framework-owned simulation loop" |
| A-014, the framework delegates the operation across the stepper seam | D-017 Position, log 601–603 | "stepper seam (advance by arbitrary `h` + on-demand dense output over the last step; one-step methods only)" |
| A-041, RK4 and Heun as the first cut | D-017 Position, log 603 | "in-house fixed-step RK4/Heun as the sole first-cut backends" |
| A-051, an `OrdinaryDiffEq` stepper later as an extension | D-017 Position, log 604 | "`OrdinaryDiffEq` dropped from dependency to possible future extension adapter" |
| A-027, a model with no continuous state is legal | D-156 Position, log 5321–5325 | "The three degenerate shapes are decided, all in favor of legality." … "Empty continuous block: integrate degenerates to advancing `t` to the next boundary" |
| A-030, the seam is never entered empty | D-156 Position, log 5325–5328 | "the stepper seam is never invoked with a zero-length buffer, no backend faces N = 0" |
| A-046, `RK4` is the default | D-227 Position, log 8246–8248 | "its value is a stepper type, `RK4` by default" (the same sentence as the `algorithm` keyword, already cited on A-048) |
| A-089, `t*` is a boundary but not a frame top | D-081 Position, log 2331–2333 | "`t*` is a boundary, not a frame: frames = grid steps, the scheduling unit (input drain, pacer deadlines, tick eligibility); boundaries = published consistency points (grid, `t*`, boundary zero)." It also rules A-081 to A-088, the definitions R1 moved here, which cited no entry |
| A-074, RK stages run the interior sweep | D-147 Position, log 4932–4934 | "The interior sweep walks continuous entries only and is what RK stage evaluations and localization guard probes run" |
| A-077, external readers observe the table only at boundaries | D-023 Rejected, log 779 | "*Mid-step publication:* see [§10.3][s10-3]." Listed below |
| added, the checkpoint hook (R6) | D-274 Position bullet 1, log 11107–11108 | "The stepper seam gets a checkpoint hook, empty for a single-step method." "What a backend needs across a frame top" is R6's wording; a `Checkpoint{T}` "is the executor's state at a frame top" (log 11097) |

Section pointers added, no entry involved: §10.6 at "the step-boundary
contract" (A-008; the glossary's `contract` note, spec 11965, places that
contract in §10.6); §5.6 at the feedthrough tracer (A-045, F13); §12.6 at the
checkpoint hook (where `checkpoint`/`restore!` are specified, spec 8242);
§10.6 replacing the self-citation "§10.3 extends naturally" (A-090); the
intro's §5.3, §9.7 and §10.1–§10.7.

## Rationale-only rulings

| claim | entry | field | log line |
|---|---|---|---|
| A-077, external readers observe the signal table only at step boundaries, and (A-091) only after the boundary sequence completes | D-023 | Rejected ("*Mid-step publication:* see §10.3") | 779 |
| A-035, the dummy-`[0.0]` tax under a foreign loop (citation unchanged) | D-017 | Rejected | 618 |
| A-010, the `CallbackSet` rejection, deleted under R3 and mapped there | D-017 | Rejected | 611–621 |

D-023 owes a Position stating the reader rule; D-017's Rationale is "Recorded
only through the rejections below" (log 608).

## Inbound citations affected

- R1 moves the frame and boundary definitions to §10.1. Retarget §10.4 →
  §10.1 at spec 5827 (§11.1, "the grid step §10.4 names"), 7598 (§12.3,
  published boundaries are grid, `t*` and boundary zero) and 12212 (glossary,
  `boundary`: `t*` and boundary zero are boundaries that are not frame tops).
  D-081's Spec field (log 2331's entry) gains §10.1 and §10.4.
- M2 puts the full reader rule in §10.3. Spec 5945 (§11.2, "§10.3 as
  extended by §10.6") stays true; "§10.3" alone now suffices.
- R6 gives §10.2 the checkpoint hook, so `implementation.md` 497–506 (the hook
  pair under "Spec: §10.2–§10.7") now relies on content §10.2 holds. D-274's
  Spec field lacks §10.2.
- R2 adds section 5 to `companions/flight_case_studies.md`. Its opening
  paragraph names sections 1 to 4 and needs one sentence for section 5 at
  landing. The new section cites §10.2, so `linkify.jl` must add the `s10-2`
  link definition there.
- Unchanged and still wrong outside the chapter: log 5324 (D-156 Position,
  "§10.1's removal of the dummy-`[0.0]` tax", which is §10.2); log 2125 and
  2500 (the "§10.1 `task_local_storage` lesson", which is D-017's dossier).

## Open questions

1. **Where D-081 is bold.** A bolds its headline at §10.1 (A-089), where R1
   puts the definitions. Unit B1's kept `t*` sentence in §10.4 and unit B2's
   "The `t*` boundary" block must then cite D-081 unbolded, or the ruling is
   bold twice. If the orchestrator prefers the bold in §10.4, A-089 drops its
   `**` and keeps the citation.
2. **How literally R2's "one plain sentence each" applies.** Each claim's
   old bold lead-in became a plain topic sentence ("Closed-loop ticks cap the
   step.", "A piecewise-smooth RHS … starves high order.", "Stiffness has a
   remedy ladder."). The supporting sentences that are not Flight.jl evidence
   stay after it: stale commands, the smoothness list and the ladder. Only the
   evidence R2 lists moved. Compressing each claim to one sentence would lose
   those sentences unless they too had a home.
3. **Two borderline evidence sentences (ruled by the coordinator).** "The
   RHS costs microseconds and 500 Hz real-time is unremarkable" moved to the
   companion's stiffness item under R2; the spec keeps "First shrink `h`."
   "Every application beyond bare propagation runs periodic avionics" stays,
   with one introducing clause for periodic avionics.
4. **`h` required has no entry.** The old text bolded "required" with no
   citation (survey row 17, "Rulings with no entry at all"). The bold is gone
   because nothing can cite it; track 2 owes an entry (Appendix B 11162
   repeats the rule).
5. **The checkpoint hook is unbolded.** It is one sentence inside D-274's
   first bullet, whose ruling (the checkpoint's contents) is stated in §12.6.
   It cites D-274 plainly as the fourth clause of the seam contract, whose
   bold (A-014) is D-017's.
6. **`N = 0` is not glossed.** Neither the old text nor §10.2's context says
   what `N` is, and the spec defines it nowhere (`rg` finds only spec 4740).
   D-156 (log 5328, "zero-length buffer, no backend faces N = 0") and D-227's
   Rationale (log 8250ff, "`N` comes out of compilation") imply the
   continuous-state buffer length. Left as written.

## Verifier fixes applied (coordinator, 2026-10-02)

- A-068: "RK4's stability region at the deployed `h`" keeps the old scope.
- A-069 split: "First shrink `h`." stays; the cost clause moved to the
  companion (R2).
- Companion: "Flight.jl's codebase"; title "Fixed-step RK4 on Flight.jl's
  aircraft model"; the crosswind-landing demo introduced as
  "a Flight.jl demo of a landing in a crosswind", naming no file or aircraft.
- Glossary links with glosses at first use: `#g-checkpoint` (a new sentence
  after the hook clause, carrying §12.6 and D-274) and `#g-feedthrough-tracer`.
- The periodic-avionics clause: "(onboard flight systems)".

