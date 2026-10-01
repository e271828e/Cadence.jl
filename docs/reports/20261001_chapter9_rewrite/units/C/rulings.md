# Unit C (§9.5): rulings for the user

Log line numbers are `decisions.md` lines at the working tree of 2026-10-01.
Old-text line numbers are `units/C/old.md` lines.

## Corrections proposed

None of substance. Survey part F lists no item inside §9.5. Two notes:

1. F15, assembly only. `spec.md` lacks a blank line between §9.5's last line
   (4140) and `### 9.6`. `new.md` ends with a newline. The blank line must be
   restored when the units are joined.
2. Two antecedents were resolved, not changed. Please confirm the readings.
   - Old line 43, "Its one baked type test is resolved by dispatch rather than
     executed ([D-235][d-235])". "Its" follows "the economics ([D-053][d-053])".
     New text: "The economics' one baked type test". D-235 Rationale (log
     8540–8541) reads it the same way: "This is D-053's one baked type test
     resolved by dispatch".
   - Old line 47, "which is equally why that diff never has to express one".
     New text: "the payload's diff", after "reported by the payload below".

## Citations added or replaced

| claim | entry | the words that rule it |
|---|---|---|
| C-007, the generated-write headline, "The write is generated over that type and the return's type" | D-235 Position (log 8514–8517), moved from the end of the old sentence at old line 15 to this headline. C-004 stays plain: it describes what the executor holds, while D-235 rules what the write does. | "At the write it holds the return to the type of the cells the stage writes, as the probe fixed them at this activation, and it is decided when the write's method is generated over the cell type and the return type." |
| C-018, names are the pairing | D-151 Position (log 5111–5112), new | "At every author↔framework `NamedTuple` seam the names are the pairing and field order carries no semantics" |
| C-039/C-040, exact match at nominal | D-053 Position (log 1479, 1484–1485) on the match; D-235 stays on "decided at generation and absent from the conformant path". Old line 51 cited both on one sentence. | "no convert-on-write"; "Exact match is scoped to the nominal activation" |
| C-046, walking leaf | D-053 Position (log 1485–1486), new | "parametrized leaves under non-nominal activations accept `{T, Float64}` with zero-partial embedding" |
| C-050/C-051, opaque leaf | D-237 Position (log 8631), moved from the subject to the end of the headline | "An opaque leaf is accepted by identity alone" |
| C-054, decided on the type | D-238 Position (log 8686–8688), moved from the end of the following sentence to the headline | "A type `V` is accepted at a declaration `P` at activation `T` when lifting `V`'s `Float64` positions to `T` exactly where `P` has `T` yields `P` itself, compared by identity." |
| C-057, pinned leaf (plain, not bold) | D-238 and D-263, new. See "Rationale-only rulings". | D-238 Position as above, which lifts nothing where `P` has no `T`, and Rationale log 8693–8694, "every other leaf is exact"; D-263 bullet 1 (log 10068–10070), "A leaf wrapped as `Pinned{P}` is pinned at every activation" |
| C-075, schema-visible freeze | D-263, new. See "Rationale-only rulings". | Rationale log 10112–10115 |
| C-079, uniform | D-053 Position (log 1480–1483), new | "uniform across `f` (state-field completeness), guards (…), output stages, handlers (partial-`m` subset predicate)" |
| C-080, `x_deriv` | D-190 Position (log 6644–6645), new | "No `derivative_type` declaration: `Ẋ` has `X`'s shape at the activation scalar." |
| C-087, `x_projection` | D-111 Position (log 3228–3232), new | "`project` joins the always-on uniform check — complete against `X`'s own shape at the activation's `T`, the same predicate as a handler's `x` key, because its return is written back to the buffer wholesale at both §7.1 schedule positions and a mode-dependent projection first executes its second branch at run time" |
| C-092, handler key set first | D-090, new. See "Rationale-only rulings". | Position log 2564–2565, "a key present iff the store exists AND the handler updates it" (this covers the absent key, C-099) |
| C-095/C-097, `x` complete, `m` partial | D-053 Position (log 1483) and D-090, new | D-053: "handlers (partial-`m` subset predicate)", the `m` half. D-090 Rationale (log 2569–2570): "`x` present ⇒ complete against the state field set", the `x` half; see "Rationale-only rulings". |
| C-105, guard check form-aware | D-053 Position (log 1480–1483), new | "guards (form-aware against the two §2.1 forms: `Bool` for predicates, the nominal scalar for continuous guards; anything else … a build error naming both forms)" |
| C-112, payload | D-249 Position bullet 2 (log 9175–9178), new. The old text cites nothing on this sentence. | "A runtime `ConformanceFailure` carries no simulation time of its own … A handler's occurrence names its event". D-249 does not list the path, function and diff. D-053 Position (log 1484) does, as "failure = path + stage + field diff + `t`", but its `t` conflicts with D-249, so D-053 is not cited here. D-111 Rationale (log 3237) renames `stage` to `function`. |
| C-114, `StepError` species | D-059 Position bullet 2 (log 1643), new | "§9.5's conformance failure is a species of it." |
| C-117, source branch absent | D-053, new. See "Rationale-only rulings". | Rejected log 1500–1501 |
| C-119, reproducible by replay | D-053 Position (log 1484), new | "reproducible by trace replay" |
| C-121, nonfinite-state check | D-157 Position (log 5316–5317), new | "The nonfinite-`x` check is the boundary's first act — immediately after integrate". D-059 Position bullet 3 (log 1644) also states it: "A loop-level nonfinite-`x` check runs at the boundary." Either fits; D-157 is the more specific. |
| C-008 | D-235 removed from "So the test is decided … conformant path". The headline just before it (C-007) cites it. | |

## Rationale-only rulings

| claim | entry | field | log line |
|---|---|---|---|
| C-057, a pinned leaf takes the exact check at every activation | D-238 and D-263 (both cited, sentence left plain); D-263 bullet 1 states only that a `Pinned` leaf "is pinned at every activation"; D-079 Rationale | D-238 Rationale; the Position entails it | 8693–8694 ("every other leaf is exact"); D-263 10068–10070; D-079 2262–2264 |
| C-061/C-062, the misplaced-pin error and its hint "remove its `Pinned`" | none current. The superseded D-166 Rationale had the hint as "declare it `T`" | (none) | D-166 5654–5655 |
| C-075, the pinned leaf is the schema-visible freeze | D-263 (cited); D-079 | Rationale | 10112–10115 ("the pin is on the page, per leaf, schema-visible and conformance-checked, so §14.10's freeze door and the FFI door survive as declared doors"); D-079 2267–2268 |
| C-078, stripping mid-expression at an unpinned leaf remains legal (left plain, not cited) | D-266; D-079 | Rationale | 10371–10373 ("which §9.5 leaves legal at an unpinned leaf"); D-079 2267 |
| C-092/C-093, key set checked first; unknown key a build error with did-you-mean | D-090 (cited) | Rationale | 2569–2572 ("Checks per key … unknown key ⇒ did-you-mean against `{x, m}` narrowed to the declared stores") |
| C-095, handler `x` complete against the state field set | D-090 (cited); D-111 Position presupposes it ("the same predicate as a handler's `x` key") | Rationale | 2569–2570 |
| C-117, the payload omits the source branch | D-053 (cited) | Rejected | 1500–1501 ("a value does not say which branch produced it — the diff + replay suffice") |

Survey part E items 9 to 11 propose entries that state these in a Position.

## Inbound citations affected

Nothing moved out of §9.5 and nothing moved in. Every fact that the 114
inbound "§9.5" rows rely on stays in the section. Spot-checked:

- spec 9788 (§14.7), "the names are the pairing, order carries no semantics":
  the bold headline under "Pairing by name".
- spec 10520, "Declare the leaf `Pinned{Float64}`, and strip with
  `ForwardDiff.value`": under "Deliberate stripping".
- spec 10556, D-266 Rationale 10372, `handle_walk_walkthrough.md` 223,
  "stripping … legal at an unpinned leaf": the last sentence under
  "Deliberate stripping".
- D-266 Rejected 10397, "the silent zero in the Jacobian": under "Deliberate
  stripping".
- D-166 5649, D-194 6776, D-235 8530, D-238 8703, "§9.5's embed-accept" and
  "§9.5's exact match at nominal": the label "Exact match and embed-accept"
  keeps the term, which appeared only in the old bold lead-in.
- D-249 9177, the carrier's frame satisfies §9.5: under "The failure
  payload".
- `handle_walk_walkthrough.md` 5, "§9.5 (the embedding guarantee)": "The
  embedding is exact, not lenient" paragraph.

The six bold lead-ins became `####` labels or bold rulings. No inbound row
quotes a lead-in by its words.

## Open questions

1. Bold count. The new text has 16 bold rulings, against 17 bold spans in the
   old (six lead-ins, three bold sentences, eight bold terms). D-053 is bolded
   six times. Three of those ("uniform", the guard form, the handler `m`) are
   clauses of one Position sentence. §9.5 states
   many distinct rulings. Three of the bold headlines sit in bullets
   (`x_deriv`, `x_projection`) or under labels that could carry them. Should
   the D-190 and D-111 rulings stay bold here, or only in §7.1?
2. The pinned-leaf sentence (C-057) is plain and cites D-238 and D-263.
   Neither Position states the exact check at a pinned leaf in
   words. A new entry (survey E9) would settle it, together with the
   misplaced-pin error and its hint, which have no current entry.
3. Struct-valued ports "use the standard cross-eltype constructor, and a
   missing one fails loudly with both types named" (old line 60). No entry
   states it (survey E11). D-238 Rationale (log 8706–8709) says the store
   "rebuilds the declaration from" the leaves. Is the constructor what does
   the rebuilding? Left as written.
4. D-235's Position (log 8513–8514) names D-166's embed-accept, and D-166 is
   superseded by D-263. The spec text cites D-235 only, so the convention is
   met, but the log entry points at a superseded one.
5. Order. Survey part C suggests moving "Pairing by name" after the
   per-function predicates. The brief lists no move for this unit, so the old
   order stands. Proposed for the user.
6. The didactic message at old line 53 contains an em dash inside the quoted
   message text. It stays verbatim, as message text.
7. Spec link definitions. `spec.md` has no `[d-151]` or `[d-111]` definition
   today. `linkify.jl` must regenerate them when this text lands.
8. Outside the unit. D-152 Rationale (log 5163) says "Auto-published cells
   belong to no stage (§9.5)". §9.5 does not state that, old or new.
9. D-053's Position lists `t` in the failure payload (log 1484). D-249
   bullet 2 says a runtime `ConformanceFailure` carries no simulation time.
   D-053 has no annotation that says so. The spec follows D-249.
10. The gloss on "activation" moved from old line 54, the non-nominal
    activation sentence, to its first use under "The generated write". The
    meaning holds, but the brief lists no such move. The cold verifier flagged
    it. Revert if the user prefers.
