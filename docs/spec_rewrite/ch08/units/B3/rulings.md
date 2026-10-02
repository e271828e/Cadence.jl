# Unit B3: rulings and findings

Unit B3 is §8.2's `y_types` block (old spec 2360–2500), with M2, "Custom
structs as port types" (old 2527–2540), moved in after the handle rule and
before constructibility at `T`.

Rulings applied: R6 (the label "Output contracts: `y_types`"; M2's place),
R7 F4 (D-238 in place of D-033 at 2443) and R7 F5 (dropped "and no pinned
fields on the continuous path" at 2531–2532). The survey's part F warning
on "as they always did" is applied at 2392–2393: the bullet now says the
leaves pin, and the history clause goes.

Subheading order: one `####` label, "Output contracts: `y_types`". The old
"Custom structs as port types" heading dissolves into the block, as part C
lists no label for it.

Glossary links: none. Every term the old text linked (port, contract, tier,
walked/pinned, cell, probe, sweep, component) is used earlier in §8.2, in
units B1 or B2 (their `old.md`), so the brief's rule leaves B3 without a
first use.

Bold: three headline clauses, each with its citation in the sentence.

- "A handle keeps its bulk at `Float64` and its activation-dependent part in
  the parameter" (D-263 Position bullet 3).
- "A declared type must be buildable at the activation scalar" (D-079
  Position).
- "The first bug lurks, but is never silent" (D-286 Position bullet 2).

Every other old bold goes plain: "by type", "literally", "continuous
producer", "discrete producer", "literal", "per leaf", the four bullet
lead-ins, "participates", "deliberately pinned", "constructibility at `T`",
"embedding guarantee", "walking leaves", "The misplaced-pin account, stated
openly." (now a plain topic sentence), "The test suite builds a `Dual`
activation of every component", "one convention", and "The stores are walked
by the same rule, with no marker." (now a plain topic sentence with D-263).
The **Why.** label at 2445 folds into "The reason is that …".

## Corrections proposed

None beyond the rulings. Survey findings in this unit left as written:

- F18. The second quoted message (old 2492–2493) says "cast where rotation
  semantics are wanted"; `src/diagnostics.jl` says "cast where the domain
  semantics are wanted", and `src/` appends section pointers to all four
  messages. The text introduces them as the didactic style, so they stay
  verbatim.
- F19. "read literally" (2365–2366) and "Semantics are literal" (2376) keep
  the spec's sense. D-166's annotation (log 5791–5792) uses "literal" for the
  retired semantics. Track 2 may annotate.

## Citations added or replaced

- D-238 replaces D-033 at "keyed on walking leaves" (R7, F4). D-238
  Position: "A type `V` is accepted at a declaration `P` at activation `T`
  when lifting `V`'s `Float64` positions to `T` exactly where `P` has `T`
  yields `P` itself, compared by identity." D-033 says nothing on embedding.
- D-263 at "means the leaf participates". Position bullet 1: "every `Float64`
  position follows the activation scalar"; bullet 3: "The type walk
  substitutes `Float64` in type-parameter positions".
- D-079 at "Value parameters … never take it". Position: "non-type (value)
  parameters pin".
- D-286 at "Declare `Pinned{Float64}` and strip with `ForwardDiff.value`
  inside the stage". Position bullet 3: "An author who means to strip
  partials declares the leaf `Pinned{Float64}` and strips inside the stage."
- D-079 at "`Int`/`Bool`/enum leaves and reference-typed fields pin".
  Position: "`Int`/`Bool`/enum leaves, reference-typed fields and non-type
  (value) parameters pin".
- D-263 beside D-237 at "one built from build-time data is declared
  `Pinned`". Position bullet 3: "a handle with a scalar parameter walks like
  any type, and `Pinned` freezes one built from build-time data". D-237
  states it only in its 2026-09-24 annotation.
- D-263 at "A mutable type's parameters pin by rule". Position bullet 3:
  "does not enter a mutable type's parameters".
- D-263 at the handle rule (bold). Position bullet 3: "A handle's data
  references are fields and never walk; a handle with a scalar parameter
  walks like any type".
- D-265 repeated at "every `Float64` position follows the scalar" reads the
  declaration as written. Rationale (log 10425–10428), quoted verbatim there.
  The old sentence 2422–2425 was split; its D-265 stays with its second half.
- D-263 at the custom struct's walk, "The walk retypes it there, recursively
  for nested parameters". Position bullet 3: "substitutes `Float64` in
  type-parameter positions".
- D-079 at constructibility (bold). Position: "with the companion obligation
  that a Tier-1 type be constructible at the walked type — enforced by
  construction at the `Dual` probe".
- D-079 at "That is semantically exact" (frozen discrete outputs). Rationale
  only, below.
- D-194 at the piecewise-constant branches. Position bullet 4:
  "embed-accept keeps the constant-branch idiom legal".
- D-079 at "never by typing". Rationale only, below.
- D-263 at the habitual spelling walks. Rationale only, below.
- D-286 at "The first bug lurks, but is never silent" (bold). Position
  bullet 2: "An observed `Dual` at a pinned leaf is the misplaced-pin error,
  with the didactic hint …". The "lurks until the first `Dual` activation"
  half is D-280's Rationale (log 11576–11578).
- D-280 at "The test suite builds a `Dual` activation of every component".
  Position: "The repository's test suite builds a `Dual` activation of every
  component".
- D-263 at "one convention". Rationale only, below.
- D-263 at "The stores are walked by the same rule". Position bullet 1: "the
  leaf walk that types `init_x` and the root inputs".
- D-079 at the zero-partial embedding of declared `Float64` initial values.
  Rationale only, below.
- D-094 at the closed leaf vocabulary. Position: "`init_x` leaves are plain
  real scalars and `SArray`s at the common eltype".
- D-231 at the stores' isbits rule. Position: "Every field of a store value
  … is isbits or a `Symbol`, and Stratum A checks every `init_s`/`init_m`
  field".

## Rationale-only rulings

- Frozen discrete outputs are semantically exact: D-079 Rationale, log
  2311 ("discrete producers pin wholesale (frozen-exact by typing rule …)")
  and 2313–2316.
- Seeding, never typing, picks the invocation that carries partials: D-079
  Rationale, log 2316 ("differentiation participation = per-invocation
  seeding, never typing").
- Declared `Float64` initial values embed as zero-partial constants: D-079
  Rationale, log 2309–2310.
- A participating leaf cannot be pinned by habit, because the bare `Float64`
  walks: D-263 Rationale, log 10229–10231.
- One convention, one walk rule for every declaration: D-263 Rationale, log
  10219–10227.
- "every `Float64` position follows the scalar" reads the declaration as
  written: D-265 Rationale, log 10425–10428.

Each owes a live Position (survey part E, items 6, 7 and 8).

## Bold on the same entry elsewhere

- D-280 is bold in §9.4 (spec 4092, "Every component gets a `Dual`
  activation built in CI"). B3 states the same ruling plain, with the
  citation, so it is bold once.
- D-238 is bold in §9.5 (spec 4259, "The check is decided on the type").
  B3's "keyed on walking leaves" stays plain.
- D-286: §9.5 bolds its Position's first sentence (spec 4292, "The pinned
  leaf is the schema-visible freeze") and states bullet 2 plain (4265–4270).
  B3 bolds bullet 2, the misplaced-pin error, once.
- No other unit's `new.md` bolds D-079, D-263 bullet 3 or D-286 at the time
  of writing (checked by grep over `units/*/new.md`).

## Inbound citations affected

None lose their target. The facts other files cite §8.2 for all stay in
this block: the handle shape rule (`handle_walk_walkthrough.md` 4, 19), the
`Pinned{Float64}` strip idiom (spec 11019; `handle_walk_walkthrough.md`
151), the misplaced pin and "lurks … never silently" (spec 1325, 4087), an
enum pinned (spec 539), `y_types` retyped per activation (spec 1383), the
walk resting on the closed vocabulary (spec 3475), the embedding of frozen
values (spec 9570), the frozen-exact typing rule
(`frozen_discrete_walkthrough.md` 5).

## Open questions

- The stores' walk and the vocabulary check (old 2478–2499) sit under the
  label "Output contracts: `y_types`", as in the old text. A second label,
  such as "The stores' walk", would serve a returning reader. Part C lists
  none, so none is added.
- "It is the same species as `u_types`" became "Like `u_types`, …", because
  *species* is a glossary term (`#g-species`, a `StepError` subtype) the
  sentence does not mean.
- "detonates" (old 2433–2434 and 2537) became "fails", unwinding the
  metaphor.
- "`Pinned` has no place in a store" has no live entry. Its only statement
  is D-166 Rejected (log 5807–5808), superseded, so it stays uncited.
