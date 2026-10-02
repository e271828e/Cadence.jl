# Unit F (§8.7, §8.8): rulings and findings

Rulings applied: R1 (the `Group` sentence verbatim), R3 (§8.7's forms to a
pointer), R6 (part C's order and the three §8.8 labels), R7 (F7, F21). M3's
sugar paragraph is merged into §8.7's container paragraph. F15's names take
introducing clauses drawn from the code blocks and from
`companions/flight_case_studies.md` ("the full C172X demo").

R3's cut claims, mapped in `inventory.json` to `docs/design/spec.md`:
"The wrappers are the whole value vocabulary, so a bare integer or bare
quantity is a declaration error" → §10.5 "The wrappers are the whole
vocabulary (D-185). A bare integer or bare quantity is a declaration error";
"An unlisted discrete child defaults to `Relative(1)`" → §10.5, same words.
"The declaration is optional, and so is any given key" and "only multiplied,
phased or anchored children need appear" are not in §10.5, so they stay.

## Corrections proposed

None beyond R7's. One observation for the owner, left as written:

- 3191–3192 and the moved 2769–2773 say the bare-field-name sugar survives a
  name-transparent container, with `(children = Relative(2),)` for a `Group`.
  D-211 Position (log 7535–7536) spells a `Group`'s rate entry by bare key,
  `(ctl = Relative(2),)`. The two spellings do not conflict, but no entry
  states that the field-name sugar survives transparency. It sits with R1's
  escalation.

## Citations added or replaced

- D-185 at "These are the two forms that §10.5 defines". Position: "a
  `sample_times` entry … declares one (period, phase) pair as an explicit
  wrapper type naming the unit system — `Relative(K, Φ = 0)` … `Absolute(q, τ
  = 0)`".
- D-042 at "The declaration is optional, and so is any given key", at "Keys
  are immediate child names only" and at "A `sample_times` key on a
  continuous child is a build error". Position: "`rates(::A)` optional
  declaration, immediate children only, `K` on a continuous child = error".
- D-042 at "The declaration belongs to the assembly type, not to the child
  instance". Rejected: "makes the type-intrinsic ratio a per-instance value"
  (Rationale-only, below).
- D-085 at "`sample_times` needs no rule change for them". Rationale:
  "`rates` keys = element names with bare-field-name uniform-`K` sugar"
  (Rationale-only, below).
- D-254 at "They are deployment decisions fixed at deployment". Position
  bullet 1: "`Deployment` is the build plus `h`, `N_base`, `Δt_base`".
- D-039 replaces "§8.1; D-039" at "structure kept in two artifacts" (R7 F7).
  Rejected: "dispatch type and structure recipe drift apart".
- D-043 at "What computation does *not* do is auto-bubble". Rejected:
  "Auto-bubbling: forgotten wire silently promoted to a live root slot"
  (Rationale-only, below).
- D-043 at "Generic holding is an imposed derived contract". Position:
  "generic holding = imposed contract checked per instantiation".
- D-046 at the dotted face name. Position: "Face names = arbitrary strings;
  build invariants only no-`/` + per-assembly uniqueness; slash = structure".
- D-046 at "There is no `rename` hook". Rejected: "`rename` hooks in `faces`:
  `exports` is ordinary code — map over the pairs" (Rationale-only, below).
- D-145 at the two-producers error. Position: "re-exporting a fed face is a
  two-producers error".
- D-145 at "Removing the duplication needs no vocabulary". Position: "No new
  vocabulary and no framework change".
- D-145 at "Adding an actuator channel is then one edit". Rationale: "adding
  a channel is one edit" (Rationale-only, below).
- D-145 at "The single source must be authored data, never inferred
  structure". Rejected: "the single source must be authored data, never
  inferred structure" (Rationale-only, below).
- D-171 at "The helpers come in pairs, because the name carries the
  direction" and at "two helpers rather than one keyword". Rationale: "after
  D-170's split a single call cannot emit into two declarations, so the
  guarded addition's landing shape is a sibling `output_passthrough` … the
  name now carrying the direction" (Rationale-only, below).
- D-209 at "Its consumer is one-level routing". Rationale: "every level
  re-exports the outputs it surfaces, and the output side needs the computed
  spelling the input side already has" (Rationale-only, below).
- D-207 at "naming an immediate child, container key segments included" and
  at "A deeper path meets `resolve`'s one-level rejection". Position: "every
  endpoint in the three wiring declarations addresses an immediate child
  (container elements included)".
- D-207 at "Scalar faces make partial scripting compose". Rejected: bundled
  faces at a root input collide with "§4.3's write-side granularity and
  forfeit partial scripting" (Rationale-only, below).
- D-251 at "A formal required-faces declaration … remains possible sugar".
  Position bullet 3: "Required-faces declarations are not owed. Recorded as
  possible sugar."

## Rationale-only rulings

- D-039, Rejected, log 1197–1198: structure kept in two artifacts ("dispatch
  type and structure recipe drift apart"); the Position does not carry it.

- D-042, Rejected, log 1255–1256: the declaration belongs to the type, not
  the instance.
- D-085, Rationale, log 2490–2491: element names as rate keys and the
  bare-field-name sugar.
- D-043, Rejected, log 1272–1273: no auto-bubbling.
- D-046, Rejected, log 1377: no `rename` hook.
- D-145, Rationale, log 4879–4890: one edit per channel, no drift, every
  misspelling loud, the omission asymmetry.
- D-145, Rejected, log 4896–4904: the line not to cross; authored data,
  never inferred structure (bold kept).
- D-171, Rationale, log 6024–6030: the name carries the direction; two
  helpers, not a keyword.
- D-209, Rationale, log 7475–7478: one-level routing as
  `output_passthrough`'s consumer.
- D-207, Rejected, log 7430–7432: scalar faces and partial scripting.

## Bold on the same entry elsewhere

- D-251's selector ruling is bold here ("The selectors are exclusive") and
  in §13.7, spec 9469 ("The passthrough helpers take a predicate"), both on
  the Position's first sentence. §13.7 is outside chapter 8; flagged for the
  owner. Mine is kept; the §13.7 edit (unbolding or recasting spec 9469) is
  outside the chapter and goes to the rulings batch.
- D-207's immediate-child rule is bold in §6.1 (spec 1233). The old bold on
  "**immediate**" (3311) is therefore dropped here; the sentence cites D-207
  plainly.
- No other unit's `new.md` bolds D-042, D-043, D-145, D-209 or D-251.

## Inbound citations affected

None loses its target. Checked:

- spec 12188 and log 6981 (`(D, Φ)` per discrete component, §8.7): the
  compile sentence is kept verbatim.
- spec 11791 (`RatesViolation`, §8.7) and log 6119 (D-173): the
  continuous-child error stays.
- spec 11993 (`ArgumentInvalid`, §8.7): already unsupported before the
  rewrite (survey F27); unchanged.
- `src/assembly.jl` 113–116: the bare field name applying one entry to every
  element is now stated once, in §8.7 (M3).
- D-085 Spec field (log 2482) and D-211 Spec field (log 7541) should gain
  §8.7 at landing (survey part D).
- spec 1265 and D-207 Rationale log 7414 ("every level of a realistic tree
  is a generic seam"), spec 1268 (the single authored feed list), spec 3647
  ("inspectable derived contract"), D-144 Rationale log 4833 (the quoted
  "helper exists for the pass-through case …" sentence), D-276 (dots in face
  names), spec 11716, 11780, 11784, 11787, 12143, 12158: all kept.
- log 4877 (D-145 Rationale, "§8.1's and D-039's 'structure kept in two
  artifacts'"): the spec no longer attributes the phrase to §8.1; the log
  still does (track 2).

## Open questions

- Two claims are uncited after the verifier's check: "`u_connections` and
  `y_connections` are ordinary functions evaluated at build against the
  concrete instance" and "Computed entries mix freely with hand-written ones
  in either declaration". D-043's Position says only "Computed exports as
  ordinary code + `faces(…)`", its Rationale is "Recorded only through the
  rejections below", and no Rejected item states either claim. The citations
  are dropped; an entry may be owed.

- The glossary gloss for *seam* ("a narrow, named interface kept
  deliberately thin") is attached to "generic seam". The glossary entry lists
  the stepper, backend, measurement and phase-body seams, not a generic one.
  The old text linked the term the same way; a glossary entry or a whitelist
  decision may be owed.
- "At the scale of Flight.jl's C172X demo" introduces C172X from
  `companions/flight_case_studies.md` ("the full C172X demo"). D-145 cites
  `c172.jl:697-713` for the count.
