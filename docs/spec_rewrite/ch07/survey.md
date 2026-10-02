# Survey of spec chapter 7 before its readability rewrite — 2026-10-02

Scope: `docs/design/spec.md` lines 1499–1884, "## 7. State and data
representation", at commit `8032ff2` (the working tree's `spec.md` equals it),
3,433 words. `chapter_old.md` line 1 is spec line 1499. The convention is
`docs/design/tools/spec_style.md`; the method is `docs/spec_rewrite/recipe.md`
step 1; the model is chapter 8's survey (`git show
d268d39:docs/spec_rewrite/ch08/survey.md`).

Line numbers are `spec.md` lines unless marked `log` (`decisions.md`) or given
with a file name. Entry claims rest on the entry's Position as read, with its
log line where the point sits outside the Position's first sentence. Every
entry a rule is classified under was read in full: the 14 the chapter cites
(D-006, D-011, D-013, D-015, D-016, D-035, D-077, D-094, D-183, D-190, D-220,
D-231, D-252, D-263) and the 28 more whose Spec field names §7 or a §7.x
(among them D-079, D-086, D-116, D-121, D-135, D-137, D-302; the renames
D-267 and D-279 and superseded D-166 at their Position and their §7 lines).
Eleven more
rule the chapter's content without either and were read whole or at their
Position and the cited lines: D-010, D-014, D-033, D-053, D-070, D-074,
D-115, D-238, D-280, D-288, D-295. Copies are in
`scratch_survey/entries/`. `src/` was read, and run, where a claim about code
was in doubt (`scratch_survey/noise_check.jl`).

Classification codes used in part A:

- **C** cited, and ruled by the cited entry's Position (at the spot or in the
  same paragraph, marked "adjacent").
- **U** ruled by an entry's Position that the section does not cite at that
  spot.
- **S** cited to a superseded entry.
- **R** ruled only in an entry's Rationale, Rejected list or annotation.
- **N** no entry found. Where the sentence reads as a description of an
  inherited status quo (FlightCore's, or Flight.jl's code) rather than a
  ruling, the row says so.
- **B** borderline; both readings are given.

"Marking" is how the spec marks the rule now: **Rule.**/**Why.** label, bold
sentence, bold lead-in (a bold phrase opening a paragraph or bullet, used as a
heading), bold words, or plain. The chapter carries 6 **Rule.** labels and 2
**Why.** labels, all in §7.2 and §7.3.

Section sizes (words, `wc -w` over the line ranges): heading 1499–1500 (6, no
intro); 7.1 1501–1589 (813); 7.2 1590–1652 (484); 7.3 1653–1794 (1,125); 7.4
1795–1836 (380); 7.5 1837–1884 (444, the closing `---` included).

Rows that are reasons, mechanisms, examples, pointers, context or code are kept
in the tables for the rewriters but left out of the tally (part A, "Tally").

## A. Per section

### Chapter heading (1499–1500, no intro)

The chapter opens straight into `### 7.1`. Every other chapter rewritten so
far opens with a context paragraph and a roadmap: chapter 8 (1904–1919: what
the chapter covers, its two halves, pointers to §9 and §14), chapter 9 and
chapter 10. Part G q1 proposes one.

Sources a new opening may draw on, so that it claims nothing new:

- spec 133 (the Part I roadmap): "[§7][s7] fixes where data lives, on both
  tiers and outside them."
- spec 1900 (chapter 8's opening): "[§7][s7] fixes the homes the declared state
  occupies."
- The section titles themselves, and §7.5's own "a scoped invariant".

Content for the paragraph, in that spirit: continuous state is an immutable
value over a flat buffer the framework owns (§7.1); the continuous path is
generic over the scalar type (§7.2); discrete state and modes live in stores,
and scratch in a workspace (§7.3); §7.4 records how the §5.2 interfaces were
reached and the prior art; §7.5 states the allocation policy those choices
make possible. Every word of it is a declared addition.

No rules. No display-block candidates.

### §7.1 Continuous state: structured immutable, flat backing (1501–1589, 813 words)

Purpose: how a continuous component's state is declared, laid out, read and
written: the closed leaf vocabulary, the flat buffer, the immutable views, the
shape of `Ẋ`, why the vocabulary is closed, and what the design buys against
FlightCore's mutable-view pattern.

No subheadings. Bold lead-ins act as headings: "What `Ẋ` is." (1525). No
labels.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 1 | 1503 | "Each continuous component declares its state by value (`x_init`, §8.2)." | plain | D-033 Position ("`init_*` by value") | U; §8.2 2217 bolds D-033, so this stays a pointer |
| 2 | 1503–1506 | "The declaration is a NamedTuple whose leaves are drawn from a **deliberately closed vocabulary, plain real scalars and `SArray`s (static vectors and matrices) of a common eltype `T`**, and nothing else." | bold words | D-094 Position ("`init_x` leaves are plain real scalars and `SArray`s at the common eltype"); the `NamedTuple` form is D-247 Position | C (adjacent, 1512); U for the form |
| 3 | 1506–1507 | "`Int`s, enums and `Bool`s belong in modes." | plain | none in a Position; §8.2's message 2611 says the same | B: a consequence of D-094 (C) for "not here"; N for "belong in modes" |
| 4 | 1507 | "Domain wrapper types (`RQuat`, `Ranged`) are not state leaves." | plain | D-094 Position ("no domain wrapper types") | C (adjacent); both names reader-cold (F9, part G q2) |
| 5 | 1507–1509 | "An attitude state is an `SVector{4,T}`, cast where rotation semantics are wanted, as described below." | plain | D-094 Rationale log 2775–2776 | R; example |
| 6 | 1509–1512 | "The declaration is flat. Each field is one leaf, never a `NamedTuple` of leaves. The condition algebra and the readers address a field as one leaf (§14.3, §14.4), and structure comes from the component tree, not from the value (D-094)." | plain | D-094 annotation 2026-09-14 (log 2780–2784) | R (cited, annotation only) |
| 7 | 1512–1515 | "The framework does three things with the declaration." + "It computes a **flat layout** at build time, with compile-time offsets over one contiguous `Vector{T}` buffer it owns." | bold word | D-010 Position ("Structured immutable state over a framework-owned flat `Vector{T}`"); D-302 Position ("The buffer is the concrete layout of continuous state, the flat `x` vector") | U; D-010 is cited nowhere in the spec and has no Spec field |
| 8 | 1516–1519 | "It **reconstructs** the typed immutable state value … and passes it to every function receiving state views, under the argument rule of §5.2. The reconstruction is field loads at known offsets, register-level, at zero cost." | bold word | D-010 Position; D-035 Position (zero-copy views) | U; "at zero cost" is description |
| 9 | 1520–1523 | "It receives immutable results back. Derivative functions return an `Ẋ`-typed value, which is scatter-stored into the flat `ẋ` buffer. Event handlers and projection return a new `X`, which is written back, with projection at the two positions in the execution order of §5.3." | plain | D-235 Position bullet 1 (state writes); D-111 Position (projection written back at both positions) | U; "handlers … return a new `X`" is loose (F16) |
| 10 | 1525–1527 | "**What `Ẋ` is.** … `Ẋ` has exactly `X`'s shape at the activation scalar. A scalar leaf's derivative is a `T`, and an `SArray` leaf's is the same `SArray` at `T`." | bold lead-in | D-190 Position | C (adjacent, 1534); spec 4562 (§9.5) quotes the second sentence |
| 11 | 1527–1530 | "This is the vocabulary rule paying rent. An invariant-carrying leaf like a unit quaternion has a derivative off its own type … Here the attitude leaf is an `SVector{4,T}` and so is its rate." | plain | D-190 Rejected log 6843–6846 | reason |
| 12 | 1530–1533 | "The conformance predicate is structural. *Each field of `x_deriv`'s return scatters into its field's block at `T`* (§9.5 states the check). That makes derivative completeness a property of the layout rather than of author discipline." | italic | D-190 Rationale log 6837–6840 | R; §9.5 4560–4566 states and bolds the check |
| 13 | 1533–1534 | "There is deliberately **no `derivative_type` hook** (D-190)." | bold words | D-190 Position | C; §9.5 4560 already bolds D-190 (part G q4) |
| 14 | 1536–1537 | "**The buffer is authoritative, and typed values are ephemeral reconstructions.** Nobody outside the framework ever holds a mutable reference to state." | bold sentence | D-010 Position and Rejected ("Mutable views: aliasing") | B: U by D-010 for ownership and immutability; N for "authoritative" as worded. Glossary 12482 repeats it, citing §7.1 |
| 15 | 1538–1542 | "'Ephemeral' is literal. An isbits view materializes in the caller's frame for exactly the duration of the call … value-identical because the value is immutable and the buffer is unchanged within a sweep." | plain | D-086 Rationale log 2559–2560 and D-288 Rationale log 11994–11995 ("the staleness rule") | R for the buffer-unchanged rule; the rest is mechanism. §9.7 4764 cites it by name as "§7.1's buffer-unchanged-within-a-sweep rule" |
| 16 | 1544–1549 | "Whether repeated reads within a sweep re-materialize or reuse the loads is codegen freedom … The executor … is spelled rebuild-per-call, and hoisting a repeated read is the code generator's CSE. The legality condition of that CSE is exactly the buffer-unchanged-within-a-sweep rule (§9.7)." | plain | D-288 Position bullet 2 ("Views are rebuilt per call. Hoisting is the code generator's common-subexpression elimination") | U; §9.7 4759 bolds D-288 here (part B, M1) |
| 17 | 1551–1555 | "The complementary rule is **one home per datum** (§5.2). The buffer holds `x`, the stores hold `s` and `m`, and the table holds produced signals. No store ever mirrors another. In particular there are no state cells in the table beyond the declared ports a component returns from `y_state` (§5.3), which are interface, not transport." | bold term | D-035 Position ("the table holds produced signals only, never transported ones (one home per datum)"); D-035 Rejected log 1118–1119 (state cells mirroring the buffer); D-252 Position sentence 2 | U; §5.2 821–825 states the same with D-035 (M2); "the stores hold `s` and `m`" is stale since D-302 (F4) |
| 18 | 1557–1563 | "**The vocabulary is closed because views must materialize without running anyone's invariants.** Scalars and `SArray`s have invariant-free constructors. … `reconstruct(flatten(x)) == x` holds identically, with no constructor bypass, no `reinterpret`, and no reliance on a custom struct's memory layout mirroring the buffer's." | bold sentence | D-094 Rationale log 2771–2773; D-094 Rejected log 2787–2796 | R; the "no … no … no" tail names two rejected alternatives (part G q10) |
| 19 | 1564 | "Invariant-carrying leaves are closed (D-094)." | plain | D-094 Position | C; "closed" here means excluded, a second sense beside "closed vocabulary" |
| 20 | 1564–1566 | "Domain semantics are instead an **explicit, invariant-free cast at the point of use**, the conversion today's `f_ode!` code performs on its raw views." | bold words | D-094 Rationale log 2775–2776 | R; "today's `f_ode!`" is FlightCore's (F9); spec 3279 cites "§7.1's explicit cast" |
| 21 | 1566–1569 | "Invariants live where the design already put them, in `x_projection` at boundaries and in writers. Handlers build their returned values through ordinary constructors, and the condition apply converts authored values through ordinary `convert` methods (§14.3)." | plain | D-094 Rationale log 2776–2778 | R |
| 22 | 1570 | "Constructors run on the write paths, never on views." | plain | D-094 Rationale log 2776–2778 | R; spec 10184 cites it ("They never run on state views (§7.1)") |
| 23 | 1572–1588 | "Against today's flat-`Vector` + `ComponentArrays`-views pattern, this buys five things." + five bullets | plain list, bold word "structural" | bullets 1, 2, 4: D-010 Rejected log 487–489 (aliasing; silent missing-ẋ; loses the integrator interface); bullet 3: D-094 Rationale; bullet 5: D-072 Position bullet 1 ("The `get_*_ss`/`assign_*_ss!` shuttle layer is deleted, discharging §7.1") and D-011 Rejected | bullets 1–4: reason; bullet 5: U. "today's" is FlightCore's (F9); spec 4653, 11127 and D-072 rely on bullet 5 |

Descriptions that read like rules: row 3 (a redirect with no entry); row 14's
"authoritative", which no entry words. Row 15's buffer-unchanged rule has no
Position anywhere; it is the rule §9.7 leans on by name.

The section names no Appendix C kind. Appendix C 12001 cites §7.1 for
`IllegalStateLeaf`, whose condition rows 2, 4 and 6 state: the section should
name the kind there (part G q8). Appendix C 12067 also cites §7.1 for
`IllegalPortType`, whose conditions (a port type with no leaves, a mutable
type, an opaque leaf at a root input, a misplaced `Pinned`) §7.1 never states;
§4.3 547–549 does. That row is already wrong (part D).

Display-block candidates: none needed. The three "things" may stay a list.
`reconstruct(flatten(x)) == x` stays inline.

Flight.jl names (spec_style "Introduce every reader-cold name"): `RQuat` and
`Ranged` (1507), `f_ode!` (1566), `ComponentArrays` (1572), the
`get_x_ss`/`assign_x_ss!`/`get_u_ss` layer (1587). Part G q2 proposes a
disposition for each.

### §7.2 Numeric genericity (eltype) (1590–1652, 484 words)

Purpose: the continuous path is generic over `T <: Real`; the four consumers
that genericity serves; how the declaration layer scopes it per leaf; the three
tiers (walked, pinned, exempt); lookup tables; three author-facing rules.

No subheadings. Labels: **Rule.** 1646. Bold terms act as list labels
(**Walked**, **Pinned**, **Exempt**, **linearization**, **trim**, **feedthrough
tracer**, **CI invariant**).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 24 | 1592–1594 | "The state buffer, the pack/unpack machinery, and the entire **continuous evaluation path** are generic over `T <: Real`. This one design property serves four consumers." | bold words | D-011 Position ("Eltype genericity on the continuous path, three-tier scoping") | U (D-011 cited at 1621) |
| 25a | 1596–1600 | consumers 1–3: exact Jacobians for **linearization** with ForwardDiff duals replacing finite differences; derivatives for **trim**; the **feedthrough tracer** (§5.6) | numbered list, bold words | D-011 Rejected log 502–503 ("FD noise, keeps hand-written state-space layer, no tracer") | R |
| 25b | 1601–1603 | "4. A trivially checkable **CI invariant**. One evaluation sweep with `T = Dual` fails loudly (`MethodError`/`InexactError` at the offending line) on any Float64-pinning." | bold words | D-280 Position ("The repository's test suite builds a `Dual` activation of every component … Linearizability is an invariant held by this policy") | U; §9.4 4347 bolds D-280; spec 2540 cites "the CI invariant of §7.2". "any Float64-pinning" is broad (F11) |
| 26 | 1605–1608 | "For consumer 1, the *discrete* side's exemption is not a limitation but the exact answer. A frozen discrete cell is a constant with zero partials … `frozen_discrete_walkthrough.md` works the chain through in detail." | plain | D-072 Position bullet 2 ("the discrete tier frozen-exact"); D-079 Rationale log 2346–2348 | U |
| 27 | 1610–1612 | "The declaration layer keeps this scoping legible without putting it in the author's way. Every declaration is written at nominal `Float64`, and one walk retypes it per activation (§8.2)." | plain | D-263 Position sentence 1 ("Every contract declaration … is written at nominal `Float64`, and is retyped") | U; "Every declaration" overreaches past the allocator (F6) |
| 28 | 1612–1615 | "On the continuous tier a `Float64` leaf follows the activation scalar, in a contract and in the `x_init`-derived state type alike, and a contract leaf wrapped as `Pinned{P}` is deliberately pinned." | plain | D-263 Position bullet 1; D-295 Position bullet 4 (the stores' walk) | U; "pinned" is used before the tier list defines it (1632) |
| 29 | 1615–1616 | "Participation is therefore authored per leaf, by the absence or presence of the marker." | plain | D-263 Rationale log 10309–10312 ("the pin is on the page, per leaf"); glossary 12866–12868 | R |
| 30 | 1616 | "The discrete side stays plain and pins wholesale." | plain | D-263 Position bullet 1; D-295 Position bullet 4 | U |
| 31 | 1617 | "Nothing anywhere comes from inference through user code." | plain | D-079 Rejected log 2364–2365 (probe-inferred participation); D-032 Position (declarations define) | B: U by D-032; R by D-079 |
| 32 | 1617–1618 | "Safety of the substitution rests on the embedding guarantee stated in §9.5." | plain | D-238 Position | U; pointer |
| 33 | 1620–1621 | "Scoping, meaning what actually needs genericity, covers roughly half the type inventory and has three tiers (D-011)." | plain | D-011 Position | C; "roughly half the type inventory" is Flight.jl's inventory, a status-quo description |
| 34 | 1623–1631 | "**Walked**, the payload and value types constructed during evaluation (about 25 structs). These are the quaternion/attitude family, `Wrench`, `FrameTransform`, `MassProperties`, `KinData`, `AirData`, geodesy value types, `TerrainData` and continuous output structs. `Quaternion` becomes `Quaternion{N,T} <: AbstractVector{T}`. By invariance, `Float64` instances still match every existing `AbstractVector{Float64}` method … The parametrization is mechanical. Constructors infer `T`, so call sites don't change, and `@kwdef` defaults pin the no-argument case to `Float64`." | bold term (list label) | D-011 Position (the tier); no entry for the list | B: C (adjacent) for the tier; N for the inventory, a Flight.jl status-quo description (part G q2). spec 3258 (§8.6) cites the list for `FrameTransform`; `extensions.md` 294 and 334 cite the `@kwdef` pattern and "the walked payload list" |
| 35 | 1632–1633 | "**Pinned**, the parameters and definitions. They stay `Float64`, since promotion handles mixing, and need no migration." | bold term | D-011 Position | C (adjacent); "need no migration" is Flight.jl's migration. `extensions.md` 220 and 278 quote "stay `Float64`; promotion handles mixing" |
| 36 | 1634–1635 | "**Exempt**, the discrete side (compensators, avionics). Linearization and trim differentiate continuous dynamics only." | bold term | D-011 Position; D-072 Position bullet 2 | C (adjacent); spec 2467 cites "the discrete exemption (§7.2)" |
| 37 | 1637–1639 | "For lookups, **table data is a pinned parameter and the query coordinate is walked traffic.** Interpolations.jl evaluates generically over the coordinate. `itp(x::Dual)` works through the `BSpline`/`scale`/`extrapolate` compositions in use." | bold sentence | none; D-011 Position's tiers applied | B: U by D-011 for the classification; N for the Interpolations.jl claims. "in use" means in Flight.jl's tables |
| 38 | 1639–1644 | "Two caveats apply. `Linear()` interpolants have kinked derivatives at knots. … upgrade to `Cubic` where Jacobian quality near a lookup matters. A manual chain rule via `Interpolations.gradient` is the escape hatch for anything exotic, and the pattern for wrapping non-Julia black boxes." | plain | D-070 Position bullet ("The C172 audit is Interpolations tables (prefer cubic knots)"); D-266 Position (an AD-opaque implementation supplies a local rule) | B: U by D-070 for `Cubic`; U by D-266 for the black-box pattern; N for the rest |
| 39 | 1646–1648 | "**Rule.** Three rules are author-facing. First, no `::Float64` argument annotations in math. Use `<:Real` or nothing, which the codebase already mostly does." | **Rule.** label | D-011 Position (genericity); D-235 Rejected log 8751 ("Type stability under `Dual` is an authoring rule (§7.2)") | B: U by D-011 for the obligation; R by D-235; N for the three rules as worded. "the codebase" is Flight.jl's (F9) |
| 40 | 1648 | "Second, no `Float64`-pinned intermediates. Write `zero(SVector{3,T})`." | plain | as row 39 | B |
| 41 | 1649–1651 | "Third, **no `::SomeType{Float64}` return-type annotations** on the continuous path, because they force converts and hence `InexactError`. The `*` method in `attitude.jl` is the live example pattern." | bold words | as row 39 | B; `attitude.jl` is a Flight.jl file the reader cannot open (part G q2). `extensions.md` 283 quotes the rule |

Define-before-use: rows 27–30 use *pinned* (1615, 1616) before the tier list
defines the tiers (1623–1635). The glossary link at 1615 (`#g-walked`) covers
it today, but the reorder in part C puts the tiers first.

Two senses of *pinned* meet here: the tier (parameters and definitions that
stay `Float64`, row 35) and the leaf marker `Pinned{P}` (row 28). The glossary
entry `#g-walked` (12926–12932) carries both. The rewrite keeps them
distinguishable; the tier's list label is capitalized only because it opens a
bullet.

Appendix C cites no kind to §7.2. The section states no condition a kind
reports; the CI invariant's failures are Julia's `MethodError` and
`InexactError`, not kinds.

Display-block candidates: the three author rules could become a short list
with `zero(SVector{3,T})` kept inline. No new code.

### §7.3 Discrete state, modes, and workspace (1653–1794, 1,125 words)

Purpose: the two homes outside the buffer. The `s` and `m` stores (immutable
values, isbits or `Symbol` field by field, checked); the workspace (mutable
scratch, declared by allocation, governed by contract); the blessed idioms
that join them (the Kalman snapshot, the PRNG); the snapshot discipline; the
deferred double-buffering door.

Subheadings (`####`): "Stores: discrete state and modes" (1661, 270 words),
"Workspace" (1689, 790), "Double-buffered mutable state (deferred)" (1790,
16). The opening (1655–1659, 60 words) is a context paragraph. Labels:
**Rule.** 1663, 1672, 1693, 1699, 1718; **Why.** 1682, 1724. Bold lead-ins
act as headings: 1711, 1742, 1752, 1757.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 42 | 1655–1659 | "Two homes sit outside the continuous buffer, and the rules they obey are opposites. Discrete state and modes are state in the full sense. They are isbits values that the framework owns and that a checkpoint copies wholesale. A workspace is mutable scratch, deliberately not state at all, governed by contract rather than by checks." | plain | D-231 Rationale log 8575–8577 ("stores governed by checks, the workspace by contract"); D-183 Position ("its rules stated as contract only") | B: R by D-231; U by D-183. "isbits values" is loose since D-231 admits `Symbol` fields (F5). D-231 Rationale 8576 quotes this opening |
| 43 | 1663–1665 | "**Rule.** Discrete state, a discrete leaf's `s`, and the modes `m` live in **typed stores**, apart from the buffer that holds `x` (§7.1). The framework overwrites an `s` or `m` store when an update or a handler returns a new value." | **Rule.** label, bold words | D-013 Position ("Immutable `z` in cells + workspace + snapshot idiom"); D-121 Position ("`z`/`m` live in *stores*"); D-302 Position | U; D-013's Position is in retired vocabulary, unannotated (part E) |
| 44 | 1667–1669 | "An `s` or `m` store keeps the same immutable-value discipline as the table's cells, in a separate home. The vocabulary of §4.1 never counts a store as a cell." | plain | D-121 Position; D-302 Position ("Stores are not cells") | U |
| 45 | 1669–1670 | "The `s` and `m` stores never touch the integrator buffer, and no arithmetic is ever done on them." | plain | D-302 Rationale log 12560–12562 ("isbits fields, no arithmetic and copy by bits"); D-195 Rationale log 7044–7047 | R |
| 46 | 1672–1680 | "**Rule.** Every field of an `s` or `m` store value is **isbits or a `Symbol`**. Isbits is an immutable value that holds no references, transitively. … A `Symbol` is admitted as the idiomatic label. It is interned, immutable and never freed … The table admits it on the same grounds, as an opaque leaf (§4.3). A `String`, an array, or a struct holding either does not qualify, and neither does a struct nesting a `Symbol`. The structure step checks every `s_init` and `m_init` field and reports a violation as `IllegalStoreField` (§9.1, Appendix C, D-231)." | **Rule.** label, bold words | D-231 Position sentence 1; the `Symbol` grounds and the nesting rejection are D-231 Rationale log 8589–8596; the table's admission is D-243 Position | C; §9.1 3728 bolds D-231 for the check (part G q4). spec 545 and D-243 Rationale 9080, 9091 rely on the `Symbol` grounds and the nesting sentence |
| 47 | 1682–1687 | "**Why.** State is what changes between ticks. Bulk data and labels do not, and their home is the component instance. The frozen-reference latitude signals enjoy (§4.1) exists for field handles (§4.4), and no store needs it. Isbits is what makes the rest of this section literal. Copying an `s` or `m` store copies bits, so checkpoint and replay of the entire discrete side is 'copy the store values', and a stored value has one fixed layout per component." | **Why.** label | D-231 Position sentence 2 ("The frozen-reference latitude of §4.1 stays with signals"); the rest D-231 Rationale log 8578–8582 | U for the latitude sentence, a Position ruling inside a **Why.** paragraph; reason for the rest |
| 48 | 1691 | "A workspace serves heavy algorithms, such as an n≈20 Kalman filter." | plain | — | context |
| 49 | 1693–1697 | "**Rule.** A workspace is component-declared mutable scratch, instantiated by the framework. It arrives as the `ws` field of the bundle … in every bundle-receiving function of the declaring component (§5.2). `x_projection` is positional and receives none." | **Rule.** label | D-013 Position (workspace); D-077 Position (the method is the allocator); D-194 Position bullet log 6972–6973 ("`ws` is the mutable-scratch channel (§7.3)"); D-074 Position log 2173 ("`project(comp, x)` alone stays positional") | U |
| 50 | 1699–1701 | "**Rule.** A workspace is **excluded from state semantics**. It is not snapshotted, not replayed and never a condition target (§14.1). It must carry no information between calls." | **Rule.** label, bold words | D-183 Position ("no information carried between calls"); D-077 Rejected log 2288–2291 ("a store conditions exclude") | B: U by D-183 for the last sentence; R by D-077 for the condition exclusion; N for "not snapshotted, not replayed" |
| 51 | 1703–1709 | "The framework **never inspects or mutates a workspace**. The workspace is an opaque, opt-in escape hatch from value semantics, used at the author's own risk, and its rules are contract, not checks. At call entry, contents are unspecified beyond the structure the allocator itself established. A plan or factorization configured at allocation is valid from then on. Scratch is garbage until written this call … No poisoning of scratch is attempted (D-183)." | bold words | D-183 Position; "valid from allocation" D-183 Rejected log 6574–6576 | C |
| 52 | 1711–1716 | "**Declared by allocation.** The well-known method *is* the allocator." + the `KF` block | bold lead-in, code | D-077 Position ("the method *is* the allocator") | U (D-077 cited at 1728); spec 2007 (§8.1) cites the `KF` block ("reads `c.n`, §7.3") |
| 53 | 1718–1722 | "**Rule.** `ws_init(::C, ::Type{T})` takes the activation scalar on both tiers, and it is the one declaration that does. A discrete allocator receives `Float64` at every activation, because the discrete tier never runs at another scalar (§9.4). `x_init`, `s_init`, `m_init` and the contracts take the component alone on every tier." | **Rule.** label | D-263 Position bullet 4; the last sentence D-263 Position sentence 1 and D-033 Position | C (adjacent, 1728) for the allocator; U for the last sentence, which §8.2 2189 bolds |
| 54 | 1724–1728 | "**Why.** State and cells re-scalar through the walk (§7.2), so those declarations never need `T`. Scratch is allocated, not retyped. A factorization, a plan or a buffer sized by the scalar has no rebuild the framework could perform … (D-077, D-263)." | **Why.** label | D-077 Rejected log 2284–2287; D-263 Rationale log 10348–10357 | reason |
| 55 | 1730–1733 | "The allocator is called once per activation … and once per scratch-store set (§14.8). Sizes come from the instance, and eltypes from the activation. Nothing downstream derives from a workspace's type, and mistyped scratch detonates loudly at the `Dual` probe." | plain | D-077 Position (per activation and per scratch-store set); D-077 Rationale log 2271 (sizes, eltypes); D-115 Position log 3455–3457 ("deriving nothing from layouts") | B: U by D-077 for the calls; R for sizes and eltypes; N for the detonation clause |
| 56 | 1735–1737 | "The `undef` spelling is the recommended idiom and the sole visible marker that contents are meaningless. It puts that fact in the declaration, which is the by-allocation convention this store actually lives in." | plain | D-183 Rationale log 6567–6568; D-077 Rationale log 2271–2272 | R; "this store" names the workspace a store (F3) |
| 57 | 1737–1738 | "Declaration is by allocation, never by initial value (D-077)." | plain | D-077 Position; Rejected log 2288 (`init_workspace` by value) | C |
| 58 | 1738–1740 | "The `init_` prefix means *establish*, as the device contract's `init!` does (§11.6), and carries no claim that the allocated contents are a value (D-220)." | plain | D-220 Rationale log 8111–8113 | R; no declaration has an `init_` prefix since D-267 (F2) |
| 59 | 1742–1746 | "**Available on both tiers.** Nothing in the workspace contract is tier-specific, and a continuous workspace simply joins the `T`-generic surface. Under a `Dual` activation the allocator is called at `Dual`, and the in-place math runs through Julia's generic fallbacks. No BLAS is involved. Activations probe and linearize, they don't run marathons." | bold lead-in | D-077 Rationale log 2272–2274; D-263 Position bullet 4 | R; repeats row 53's tier fact (M7) |
| 60 | 1748–1750 | "The continuous side runs many calls per boundary, for RK stages, localization trial evaluations and event re-sweeps. That multiplicity makes the no-information-between-calls contract *more* essential there, not less." | plain | D-077 Rejected log 2296–2298 | reason |
| 61 | 1752–1755 | "**The blessed idiom for zero-allocation ticks with immutable `s`.** Do the in-place math (`mul!`, `cholesky!`, BLAS) on the workspace. At the end, snapshot into an isbits container and return it, as in `s = KFState(SVector{20}(ws.x̂), SMatrix{20,20}(ws.P))`." | bold lead-in | D-013 Position ("workspace + snapshot idiom") | U; glossary 13367 (*blessed*) cites §7.3 for it |
| 62 | 1757–1762 | "**The blessed idiom for a PRNG in a discrete leaf.** A generator object such as `Xoshiro` is mutable, so it is scratch and lives in the workspace, allocated once. The values that determine its next draw are immutable, so they are state and live in `s`, which is what makes replay deterministic (§2.2). The tick loads them … at entry and snapshots them back at exit" | bold lead-in | D-231 Position sentence 3 ("A PRNG object is workspace; the values that determine its next draw are the state") | C (adjacent, 1777) |
| 63 | 1764–1774 | the `Noise` block | code | — | code; it fails its own conformance check (F1) |
| 64 | 1776–1777 | "Rematerializing the generator from its values each tick reads naturally and allocates. A sampler with an out-of-line tail lets the object escape (D-231)." | plain | D-231 Rationale log 8584–8588; Rejected log 8605–8606 | R |
| 65 | 1779–1781 | "Construction and storage of large `SArray`s are cheap and compile fine. The StaticArrays 'codegen catastrophe' lives in its *operations*, the unrolled matmuls, which are never called on snapshots." | plain | D-077 Rejected log 2292–2295 names the "`MMatrix` codegen catastrophe" | B: R for the catastrophe's existence; N for the claim about snapshots |
| 66 | 1783–1788 | "The discipline is that snapshot values are for storage, logging and element access only, never arithmetic. It is optionally enforceable by an op-forbidding `ValueSnapshot{N,T}` wrapper … The practical ceiling is a few KB comfortable and tens of KB defensible. Beyond that, value semantics stop making sense." | plain | none | N; `ValueSnapshot` exists nowhere in `src/`, the log or the rest of the spec (F13) |
| 67 | 1790–1793 | "#### Double-buffered mutable state (deferred)" + "Double-buffered mutable state is a possible future extension only, deferred (D-013)." | heading, plain | D-013 Rejected log 545 ("*Double-buffering:* deferred; publication races") | R (cited) |

Appendix C cites one kind to §7.3, `IllegalStoreField` (12073), and the
section names it where it states the condition (1679–1680). Good as is.

Outside citations that attribute to §7.3 a rule it does not state: the
`ConformanceFailure` message in `src/diagnostics.jl` 1043, `src/executor.jl`
383, `src/build.jl` 1619 and `test/test_store.jl` 176, `test/test_failures.jl`
722 all say "a discrete successor is the store's own type exactly (§7.3)".
§9.5 4565 states it ("`s_update` checks against its leaf's `s` shape"); §7.3
does not. Part D lists them.

Display-block candidates: the two existing blocks stay (the `KF` allocator is
cited from §8.1 2007). The `KFState` snapshot (1754–1755) is a one-line call
and could become a display line beside the allocator; optional.

### §7.4 The fused-evaluation lineage (prior art and how we got here) (1795–1836, 380 words)

Purpose: history. How the §5.2 interfaces were reached in four steps, each
cited to its entry; the prior art for the shared-computation problem; the
computer/integrator split as an idiom the design admits without support.

No subheadings. The four steps are a numbered list with bold step names. Bold
terms: **Simulink diagrams**, **S-functions and FMUs**, **Modelica/MTK**,
**computer/integrator split**.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 68 | 1797–1798 | "The §5.2 interfaces are the end point of a four-step simplification arc. The arc is recorded here because each step replaced a mechanism with something smaller." | plain | — | context (history) |
| 69 | 1800–1801 | "1. **N output groups → exactly two** (D-006), at the price of an occasional component split (§5.4)." | bold lead-in | D-006 Position ("component split as the refinement") | C (history) |
| 70 | 1802–1804 | "2. **Derivative binding → own-output access** (D-015). Passing the fresh signal table to `x_deriv`/`s_update` subsumes the declaration feature, and the 'binding' becomes a one-line function body." | bold lead-in | D-015 Position; Rejected log 577 ("*Derivative binding:* a declaration feature subsumed by `y`-access") | C (history); spec 10578 and D-125 Rationale 3784 cite "§7.4 step 2's one-line binding" |
| 71 | 1805–1806 | "3. **Separate state arguments → the state decoder** (D-016, D-035). Step 4 later reversed the second half of this step." | bold lead-in | D-016 Position ("Uniform component interfaces via the no-feedthrough state decoder"), annotated superseded in part (log 595–597) | C (history) |
| 72 | 1807–1815 | "4. **Decoder-exclusive state access → stores-and-views arguments.** Step 3's second half was reversed (D-035). Once §8.3 made publication a deliberate interface act, the identity decode stood revealed as *transport*. … The fixed point is the argument rule (§5.2), zero-copy views of the stores a function genuinely reads. What survives of step 3 is the uniform shapes, the fused economics, and the stage-1 decoder itself (today's `y_state`). That decoder is no longer the sole state gate. It is the no-feedthrough stage." | bold lead-in | D-035 Position and Rejected log 1109–1113 (the "published anyway" camouflage fell with contract visibility); D-034 Position (contract visibility) | C (history); U by D-034 for the §8.3 clause (F10). "today's `y_state`" means the current name (F9). D-169 Position 6002 (superseded) cites "§7.4 step 4's rejected identity transport" |
| 73 | 1817–1823 | "For orientation, here is the prior art. Every causal framework meets the shared-computation problem and resolves it per its architecture. **Simulink diagrams** make integrators explicit blocks … **S-functions and FMUs** use sanctioned *mutable caches*, DWork vectors and FMI's lazy-evaluation caching … **Modelica/MTK** write `der(x) = expr` natively with symbolic CSE." | bold terms | D-015 Rejected log 573–574 ("*Mutable caches between `f` and outputs:* S-function/FMI style — hidden state, purity violation") | R; orientation, not litigation (part G q10) |
| 74 | 1824–1826 | "The fused sweep plus signal-consuming `x_deriv`/`s_update` is the cache-free formulation that fits this design's purity rules. It is also what FlightCore's fused `f_ode!` did economically, minus the checked ordering." | plain | D-015 Position | U; §5.3 1027–1029 says the same of FlightCore's `f_ode!`, citing D-015 |
| 75 | 1828–1832 | "The **computer/integrator split** remains fully expressible without any framework support. A stateless component computes derivatives as outputs, wired into a trivial state-holding component. It is the idiom of choice when the factoring earns reuse, for example one Newton–Euler solver shared across vehicle variants, or swappable kinematic descriptors against a common integrator shape." | bold term | D-015 Position ("the *rewarded* idiom, not an impossibility claim") | U; §5.3 1033–1035 points here for "the full statement, including when the factoring earns its keep" |
| 76 | 1833–1835 | "Against a split-form spelling of the same model (four components, thirteen connections), the merged form has half the components and wiring. Everything derivable from pose alone migrates to stage 1, shortening the stage-2 chain." | plain | D-015 Rejected log 578–579 ("2× components/wiring for the domain-normal overlap case") | R; a worked-example measurement, exempt under spec_style but owing its citation; "the same model" has no antecedent (F7) |

The lineage steps are history: each records a past ruling and cites it. They
stay cited, and none takes bold (part G q4). The section names no Appendix C
kind, and none is cited to it.

Reader-cold names: `f_ode!` (FlightCore, the predecessor; spec_style needs
nothing for FlightCore named as predecessor, but `f_ode!` is its machinery and
takes a short gloss); DWork vectors and `mdlDerivatives`/`mdlOutputs` (Simulink
S-function machinery, external precedent cited in support, which
`decisions_style.md` 66–68 keeps where it is). Newton–Euler and kinematic
descriptors are aerospace examples and read without an introduction.

### §7.5 Allocation policy: a scoped invariant (1837–1884, 444 words)

Purpose: why the framework keeps a zero-allocation invariant, and how it is
scoped: exactly zero on the continuous hot path, zero by idiom for ticks and
handlers, amortized-zero for logging; what the log does not record; the levers
where garbage is unavoidable.

No subheadings. Five bullets, each opening with a bold lead-in. Bold term:
**the canary**.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 77 | 1839–1840 | "The allocation policy is not dogma. Three reasons support it, and only one is about speed." | plain | D-014 Position ("Scoped allocation invariant, CI-enforced on the hot path"); Rejected log 556 ("*Blanket dogma:* fights logging reality") | U; D-014 is cited nowhere in the spec and has no Spec field |
| 78 | 1840–1841 | "First, GC-pause jitter control for real-time. Second, throughput for unattended runs (runs with empty staging and no snapshot readers)." | plain | none | reason |
| 79 | 1841–1845 | "Third, **the canary**. An unexpected allocation is Julia's most reliable symptom of type instability. A zero baseline therefore makes `@allocated == 0` a CI-testable invariant, one that catches inference regressions at the offending commit." | bold term | D-014 Rejected log 557 ("*No policy:* loses the type-instability canary"); D-116 Rejected log 3505–3507 | R; spec 4484 and D-151 Position cite "the canary" |
| 80 | 1847–1852 | "**Continuous hot path.** This is per-stage evaluation, plus everything else that runs unconditionally per frame or boundary. Those unconditional items are guards … and `x_projection` at both of its §5.3 positions in the execution order. The budget is exactly zero, CI-enforced at the §9.7 phase-body seam (`phase_bodies`)." | bold lead-in | D-014 Position; D-116 Position (the seam, CI warm-then-assert); D-116 Rationale log 3491–3492 (guards and projection join the exactly-zero tier) | U; §9.7 4871 bolds D-116. The projection after a handler runs only on firing (F12) |
| 81 | 1853–1858 | "**Periodic ticks and event handlers.** These execute episodically … Allocation here is zero by idiom. The idiom is the workspace … and snapshot pattern, plus immutable-value returns. The rare exception has a documented tolerance, scoped per body by the seam's granularity so it never loosens the continuous assertions." | bold lead-in | D-116 Rationale log 3492–3493 (handlers join the tick tier); D-116 Position ("a documented tolerance loosens exactly one assertion") | U; spec 4914 cites "a documented §7.5 tolerance" |
| 82 | 1859–1862 | "**Logging** is amortized-zero. The log retains the published snapshot objects themselves, by reference, one slot per retained boundary and no copy (§11.2). `sizehint!` to the retention bound makes regrowth a non-event." | bold word | D-137 Position (retained references under `log_max`); D-137 Rationale log 4379–4381 (`sizehint!` capped by `log_max`); D-014 Rejected ("fights logging reality") | B: U by D-137 for retention; R for `sizehint!`; N for "amortized-zero" as the tier's name |
| 83 | 1862–1870 | "The allocation claim is about the snapshot's *fields*, not about everything reachable from them. A model carrying §4.4 field handles … has a snapshot type with reference fields. Those fields ride as references to build-time-frozen data, with no copy and no per-boundary garbage … The per-boundary allocation cost is zero either way, and the summarize-or-skip rule (§4.4) governs what such a field contributes on export." | plain | D-137 Rationale log 4339–4341 ("field handles riding as references to build-time-frozen data, §7.5") | R |
| 84 | 1871–1877 | "**Event firings are not recorded.** The log holds boundary snapshots and the trace holds staged inputs (§11.2, §11.5). … The honest remedy (§11.2) is to declare the mode field public and return it from `y_state` (D-252); a mode field so exposed is in every snapshot. An event-firing stream is a guarded addition (a capability the design admits but does not build)." | bold lead-in sentence | D-252 Position sentence 2 (the remedy); no entry for the headline or the guarded addition | B: C for the remedy; N for "not recorded" and for the guarded addition. D-243 Rationale 9086 and `test/fixtures.jl` 1413, 1444 cite "§7.5's remedy" |
| 85 | 1878–1881 | "**Tools where garbage is unavoidable.** Arena allocation (Bumper.jl-style) serves scoped temporaries. A scheduled `GC.gc(false)` at frame boundaries moves collection out of the critical path. Julia has no per-object freeing, so these are the honest levers." | bold lead-in | none | N; `pending.md` 109–110: "§7.5 names `GC.gc(false)` at frame boundaries, and nothing in `src/` builds it" (F14) |

What the section does not say, and the corpus cites it for (part D, the "scope
family"): that the invariant is scoped to the stepping loop or model sweep,
that the stopped-sim services and one-shot setup allocate freely, and that
publication's per-boundary snapshot sits "on the framework side" of the scope.
Seventeen rows rely on one of these (spec 4406, 4917, 6420, 6493, 7061, 7819,
10220, 10778; log D-066, D-107 (superseded), D-116, D-135, D-136, D-137,
D-176, D-241, D-288). §7.5 holds only the logging bullet. Part G q5.

The section names no Appendix C kind, and none is cited to it.

The two `[log](#g-log)` links (1859, 1871) are the only body links to that
anchor in the spec. `check_glossary.jl --strict` fails if the rewrite drops
both.

### Tally

| section | rules | C | U | S | R | N | B |
|---|---|---|---|---|---|---|---|
| §7.1 | 22 | 5 | 7 | 0 | 8 | 0 | 2 |
| §7.2 | 19 | 3 | 7 | 0 | 2 | 0 | 7 |
| §7.3 | 22 | 5 | 6 | 0 | 6 | 1 | 4 |
| §7.4 | 8 | 4 | 2 | 0 | 2 | 0 | 0 |
| §7.5 | 8 | 0 | 3 | 0 | 2 | 1 | 2 |
| total | 79 | 17 | 25 | 0 | 20 | 2 | 15 |

The count leaves out the 10 rows that are reasons, context or code (11, 23
bullets 1–4, 48, 54, 60, 63, 68, 78), counts row 23's fifth bullet as one rule
(U), splits row 25 into 25a and 25b, and classes each row by its first code.

Against chapter 8 (C 57, U 83, S 2, R 43, N 7, B 21 of 213): chapter 7 is
cited at fewer of its spots (17 of 79), and one rule in four lives only in a
Rationale, Rejected list or annotation (20). Two have no entry at all (66,
`ValueSnapshot` and the snapshot ceiling; 85, the garbage levers). Two entries that rule whole
sections are cited nowhere in the spec and have no Spec field: D-010 (§7.1)
and D-014 (§7.5). No superseded entry is cited. Fifteen rows are borderline,
most of them §7.2's author-facing rules and lookup advice, which apply D-011
without an entry stating them.

Bold weight now: 50 bold spans outside code blocks. Eight are labels (6
**Rule.**, 2 **Why.**); the other 42 carry 185 words. Half are list labels
and lead-ins acting as headings (21, among them the four lineage steps and the
five §7.5 bullets), eight are bold terms (*flat layout*, *reconstructs*,
*structural*, *typed stores*, *the canary*, *one home per datum*, the three
prior-art names counted once), and the rest mark rulings or reasons.
Part C proposes 12 bolds, one per ruling.

## B. Overlaps

### Inside the chapter

1. **The explicit cast.** §7.1 says it three times: 1507–1509 ("cast where
   rotation semantics are wanted, as described below"), 1564–1570 (the rule
   and where invariants live) and the third "thing bought" 1580–1583 (the
   `RQuat(x.q, normalization = false)` spelling). Home: 1564–1570. The bullet
   keeps its one clause of contrast with FlightCore and the code spelling,
   which no other line shows; 1507–1509 keeps "as described below".
2. **Derivative completeness.** 1532–1533 ("a property of the layout rather
   than of author discipline") and the second "thing bought" 1577–1579 ("a
   forgotten `ẋ` entry is impossible rather than silently stale"). Both stay:
   the bullet is the contrast with FlightCore. The rewriter may shorten the
   bullet to its contrast clause.
3. **The workspace's scalar on both tiers.** §7.3 1718–1722 (the rule), 1724–
   1728 (why), 1730–1733 ("eltypes from the activation") and 1742–1746
   ("Available on both tiers", the same fact from the contract side). Home:
   1718–1728. 1742–1746 merges into it (M7); its `Dual` and BLAS sentences
   are the only new content and survive.
4. **No information between calls.** 1701, 1707–1708 and 1748–1750. Distinct
   jobs: the rule, the contract's wording (D-183), the reason it matters more
   on the continuous side. No change.
5. **What a checkpoint copies.** 1656–1657 ("a checkpoint copies wholesale")
   and 1685–1687 ("checkpoint and replay … is 'copy the store values'"). The
   first is context, the second the reason. No change beyond F5.
6. **The workspace-plus-snapshot idiom.** §7.3 1752–1755 states it; §7.5
   1855–1856 names it again as the tick tier's idiom, with a fresh gloss of
   *workspace*. §7.5 keeps one clause and a pointer to §7.3.
7. **Projection's two positions.** §7.1 1522–1523 and §7.5 1850, both
   pointing to §5.3. Each keeps its pointer.
8. **The discrete exemption.** §7.2 1605–1608 (consumer 1), 1616 ("pins
   wholesale") and 1634–1635 (the Exempt tier). After the reorder (part C) the
   tier comes first and the other two read as its consequences.

### Other chapters

| content | chapter 7 | elsewhere | home |
|---|---|---|---|
| one home per datum: buffer, stores, table; no store mirrors another | §7.1 1551–1555 | §5.2 821–825, with D-035, near-verbatim; glossary 12532–12534 cites §5.2 and §7.1 | §5.2. §7.1 keeps a pointer and its own clause (no state cells beyond the ports returned from `y_state`), M2 |
| views rebuilt per call; hoisting is the code generator's CSE | §7.1 1544–1549 | §9.7 4759–4766, bold, D-288 | §9.7. §7.1 keeps the buffer-unchanged rule, which §9.7 4764 cites by name, and points (M1) |
| `x_deriv` against `X`'s own shape; completeness structural | §7.1 1525–1534 | §9.5 4560–4566, bold, D-190 | §7.1 for what `Ẋ` is; §9.5 for the check and the bold (part G q4) |
| the closed leaf vocabulary, the flat declaration, their check and messages | §7.1 1503–1512 | §8.2 2604–2617 (points to §7.1); §9.1 3726–3731 (the check's place) | §7.1 for the vocabulary; §8.2 for the messages; §9.1 for when |
| `x_init` by value; the stores' walk; no marker in a store | §7.1 1503; §7.2 1612–1616 | §8.2 2215–2240 (bold, D-033), 2595–2602 (D-263, D-295) | §8.2. §7.1 and §7.2 point |
| the leaf walk and per-leaf participation (`Pinned{P}`) | §7.2 1610–1618 | §8.2 2189–2210, 2279–2300; glossary 12860–12868 | §8.2. §7.2 keeps its summary sentence and the pointer |
| the CI `Dual` activation | §7.2 1601–1603 | §9.4 4347 (bold, D-280); §8.2 2587–2590 (D-280) | §9.4 for the policy; §7.2 for "the CI invariant" as a consumer, which §8.2 2540 cites by name |
| frozen discrete outputs are exact | §7.2 1605–1608 | §8.2 2465–2467 ("the discrete exemption (§7.2)"); §14.10; `frozen_discrete_walkthrough.md` | §7.2 for the exemption; §14.10 for linearization |
| the embedding guarantee | §7.2 1617–1618 (pointer) | §9.5 4490–4515 (bold, D-053, D-238) | §9.5 |
| the store vocabulary: a store is the home of a state letter, stores are not cells | §7.1 1551–1552; §7.3 1663–1670 | §4.1 452–454 (D-302); glossary 12565–12571 | §4.1 for the word; §7.3 for the `s` and `m` rules |
| `Symbol` as a store field and as an opaque port leaf | §7.3 1674–1677 | §4.3 543–546 ("the same grounds §7.3 admits it in a store on", D-243) | §7.3 for the store; §4.3 for the port |
| the isbits check, its kind and its place | §7.3 1678–1680 | §9.1 3728 (bold, D-231); §8.2 2605–2606, 2620 | §7.3 for the rule; §9.1 for when (part G q4) |
| the workspace by allocation; `ws_init`'s scalar on both tiers | §7.3 1693–1746 | §8.2 2189–2210 (the criterion), 2250–2261; §8.1 2006–2008; §8.5 2874; §9.4 4300–4305; §5.2 table 732 | §7.3 for the workspace; §8.2 for its place in the inventory |
| the workspace is never a condition target | §7.3 1700 | §14.1 (tests cite "the 'never workspace' half of §14.1's rule") | §14.1 for conditions; §7.3 for the exclusion |
| fused evaluation, FlightCore's `f_ode!`, the computer/integrator split, mutable caches | §7.4 1817–1835 | §5.3 1011–1037 ("Why derivatives may read outputs"; "FlightCore's fused `f_ode!` already embodied the same economics"; "§7.4 carries the full statement") | §5.3 for the departure and its reason; §7.4 for the lineage, the prior art and the split, as §5.3 says |
| the phase bodies as the measurement seam; CI warm-then-assert; the documented tolerance; publication is not a phase body | §7.5 1850–1858 | §9.7 4871–4917 (bold, D-116, D-288); Appendix B 11833–11841 | §9.7 for the seam; §7.5 for the tiers |
| the log retains snapshots by reference; one snapshot per boundary; `sizehint!` | §7.5 1859–1862 | §11.2 6416–6421, 6440–6515 (D-137) | §11.2 for the log; §7.5 for the tier |
| a state field wanted in logs: declare it public, return it from `y_state` | §7.5 1873–1876 | §11.2 6404–6407; §5.3 | §11.2 and §5.3; §7.5 keeps the event-firing case |
| the zero-allocation invariant's scope (stepping loop, model sweep, framework side) | absent from §7.5 | §9.4 4406; §11.2 6420; §11.8 7819; §14.4 10220; §14.8 10778 | §7.5 should hold it (part G q5) |
| publication's garbage; a scheduled young collection | §7.5 1878–1881 | `pending.md` 93–125 | `pending.md` until ruled |
| zero-allocation stepping as a capability | §7.5 | §1 170 ("the test suite asserts it (§7.5, §9.7)") | §7.5 |

Bold already given elsewhere to a ruling chapter 7 states (the one-bold test,
`docs/design/tools/check_bold.jl`'s `REWRITTEN = [8, 9, 10]`; the full list
of bold spans in chapters 8–10 citing an entry chapter 7 touches is
`scratch_survey/bold_rewritten.txt`):

| entry | ruling | bold in | chapter 7 |
|---|---|---|---|
| D-033 | state declared by value | §8.2 2217 | §7.1 1503 points; no bold |
| D-190 | `Ẋ` has `X`'s shape; no `derivative_type` | §9.5 4560 | §7.1 1534 is bold now; part G q4 |
| D-288 | views rebuilt per call | §9.7 4759 | §7.1 1546; no bold |
| D-288 | publication is not a phase body | §9.7 4916 | §7.5 (if q5 adds it); no bold |
| D-280 | a `Dual` activation of every component in CI | §9.4 4347 | §7.2 1601; no bold |
| D-231 | the isbits check, field by field | §9.1 3728 | §7.3 1672 is bold now; part G q4 |
| D-263 sentence 1 | every contract declaration takes the component alone | §8.2 2189 | §7.3 1722; no bold |
| D-263 bullet 1 | contracts walked, `Pinned{P}` pinned | not bold anywhere (§8.2 2286 plain) | §7.2 1612; no bold, the home is §8.2 |
| D-295 bullet 4 | the stores take no marker | not bold anywhere (§8.2 2595 plain) | §7.2 1612–1616; no bold, the home is §8.2 |
| D-252 sentence 1 | one producing stage per port | §8.3 2746 | not stated |
| D-252 sentence 2 | expose state by returning it from `y_state` | not bold in 8–10; §5.3 states it under a **Rule.** label | §7.5 1875; no bold, the home is §5.3 |
| D-116 | the measurement seam | §9.7 4871, 4898, 4905 | §7.5 1851; no bold |
| D-111, D-235 | projection and state writes checked | §9.5 4569, 4429 | §7.1 1520–1523; no bold |
| D-247 | the `NamedTuple` form | §8.2 2217, §9.1 3728 | §7.1 1504; no bold |
| D-238 | embed-accept decided on the type | §9.5 4515 | §7.2 1618; no bold |

## C. Proposed structure

No section is renumbered and no `###` title changes. `inbound.tsv` holds 205
rows outside the frozen briefs and the tools' tables, every one of them by
section number: §7.1 58, §7.5 63, §7.3 40, §7.2 21, §7.4 13, §7 10. No file
links a `####` anchor of chapter 7 (checked with `rg` over `docs/design`), so
the three `####` labels of §7.3 can change freely. §7.4's parenthetical title
is a retitle candidate the rewrite does not need: §7.4 is cited by step number
("§7.4 step 2", spec 10578, D-125 Rationale; "§7.4 step 4", D-169), so the
numbered steps must survive too.

### Moves

| move | content | from | to | needs a ruling |
|---|---|---|---|---|
| M0 | a context paragraph and roadmap for the chapter | — | after `## 7.` (1499) | yes, q1 |
| M1 | codegen freedom and the executor's spelling | §7.1 1544–1549 (75 words) | one sentence that keeps the buffer-unchanged rule as the CSE's legality condition, with a pointer to §9.7 for rebuild-per-call and hoisting (D-288) | yes, q6 |
| M2 | one home per datum restated | §7.1 1551–1553 (to "mirrors another.") | a pointer to §5.2, keeping 1553–1555 (no state cells beyond the ports returned from `y_state`, interface not transport), with D-035 and D-252 | yes, q6 |
| M3 | Flight.jl's walked-type inventory | §7.2 1623–1628 (from "(about 25 structs)" to "behavior is untouched", about 60 words) | `companions/migration_outline.md`, "The parametrization pass" (30–35), which today holds `Ranged` at ports and parameters only; §7.2 keeps the tier's definition, `FrameTransform` as one example (spec 3258 needs it), and the generic pattern sentence ("Constructors infer `T` … `@kwdef` defaults pin the no-argument case to `Float64`", which `extensions.md` 294 cites) | yes, q2 |
| M4 | `attitude.jl` and "which the codebase already mostly does" | §7.2 1647–1648 (clause), 1650–1651 (sentence) | `migration_outline.md`, the same paragraph | yes, q2 |
| M5 | the tier list before the walk paragraph | §7.2 1620–1635 | after 1608, before 1610 | yes, q7 |
| M6 | "Available on both tiers" | §7.3 1742–1746 | merged into the scalar rule (1718–1728); its `Dual`/BLAS sentences kept | yes, q6 |
| M7 | the "Double-buffered mutable state (deferred)" heading | §7.3 1790–1793 (16 words) | one sentence at the end of the stores block, citing D-013; the heading goes | yes, q7 |
| M8 | the scope of the invariant | — | §7.5, after the three reasons: two sentences stating the scope and the framework side, cited | yes, q5 |
| M9 | "Event firings are not recorded" | §7.5 1871–1877 (a bullet among allocation tiers) | a paragraph after the tier list: it says what the log holds, not what allocates | yes, q7 |

Every move stays inside its section, so no inbound row retargets for a move
inside the chapter. M3 and M4 send text out of the chapter; part D lists the
rows they touch.

### Order within each section

Define-before-use was checked for each order below against the terms each
block uses.

- **Chapter opening (new, M0).** A context paragraph: what the chapter fixes
  (where each datum lives on both tiers and outside them, how it is
  represented, what scalar it is generic over, what allocation the choices
  permit). One roadmap sentence naming §7.1 to §7.5 by subject. Model: the
  openings of chapters 8, 9 and 10. Checked: it may name *buffer*, *store* and
  *workspace* without glossary links, since §7.1 and §7.3 link them at first
  use in their sections.
- **§7.1.** (1) Context and rule: the declaration by value (row 1, pointer to
  §8.2), the closed vocabulary (rows 2–5), the flat declaration (row 6), and
  the kind that refuses a field outside it (`IllegalStateLeaf`, q8). (2) What
  the framework does with it: layout, reconstruction, write-back (rows 7–9).
  (3) The buffer and its views: authority, ephemerality, the buffer-unchanged
  rule, and M1's sentence (rows 14–16). (4) M2's pointer to §5.2 and its
  clause (row 17), "the complementary rule" to (3). (5) Why the vocabulary is
  closed, with the explicit cast (rows 18–22). (6) What `Ẋ` is (rows 10–13).
  (7) What the design buys against FlightCore (row 23). The one change from
  today's order is (6): the `Ẋ` paragraph sits between (2) and (3) now, but it
  calls itself "the vocabulary rule paying rent" and leans on the cast ("Here
  the attitude leaf is an `SVector{4,T}`"), so it reads after (5). Checked:
  (3) introduces *view* and *materialize* before (5) uses them ("views must
  materialize without running anyone's invariants"), as today; (6) needs only
  the vocabulary and the cast. No subheadings: at about 800 words the section
  takes a context paragraph ending in one sentence naming its parts (q7).
- **§7.2.** (1) Context: the generic path and its four consumers (rows 24–
  25b). (2) The ruling: scoping in three tiers (rows 33–36, M5), with the
  discrete exemption as the Exempt tier's consequence (row 26). (3) How the
  declaration layer spells it per leaf (rows 27–32), now after *pinned* is
  defined. (4) Lookups (rows 37–38). (5) The three author rules (rows 39–41).
  Checked: the tier list uses *activation scalar* (glossed in §7.1, glossed
  again here per section), and nothing from (3).
- **§7.3.** Context paragraph (row 42), ending in one sentence naming the
  parts. `#### Stores: discrete state and modes` (rows 43–47, then M7's
  sentence). `#### Workspace` (rows 48–60, with M6). A new `#### Idioms` for
  rows 61–66 (the Kalman snapshot, the PRNG and its code, the `SArray` cost,
  the snapshot discipline): they join the two homes, so they follow both.
  Checked: the idioms use *blessed* (glossary), *snapshot* (the isbits
  container, defined at 1754 in place) and the workspace's rules, all before
  them.
- **§7.4.** Unchanged order. One context sentence first, naming the problem
  every step addresses (the shared computation between derivatives and
  outputs, §5.3), then the four numbered steps, the prior art, the split.
  The steps keep their numbers.
- **§7.5.** (1) Context: not dogma, three reasons (rows 77–79). (2) The
  ruling and its scope (D-014; M8). (3) The tiers as a list: the continuous
  hot path, ticks and handlers, logging (rows 80–83). (4) What the log does
  not record (M9, row 84). (5) The levers (row 85). Checked: M8's sentences
  need *publication* and *stopped-sim services*, both pointed (§11.2, §14).

### Bold, one per ruling

The section states what each entry below decides, and no rewritten chapter
bolds it (part B's last table). Twelve bolds, against 42 bold spans and 8
labels today.

| section | entry | ruling | where |
|---|---|---|---|
| §7.1 | D-010 Position | structured immutable state over a framework-owned flat `Vector{T}` | the headline of row 14 ("The buffer is authoritative, and typed values are ephemeral reconstructions"), or of the context sentence that states the layout and the reconstruction; the rewriter picks one and cites D-010 there |
| §7.1 | D-094 Position | the closed leaf vocabulary | row 2's headline |
| §7.1 | D-094 annotation | the declaration is flat | row 6's "The declaration is flat"; R, so the log owes a Position (part E) |
| §7.2 | D-011 Position | genericity on the continuous path, three-tier scoping (one sentence, one ruling) | row 24's headline; rows 33–36 cite D-011 plain |
| §7.3 | D-013 Position | immutable discrete state in stores, workspace and snapshot idiom ("+" joins one ruling) | row 43's headline; rows 49 and 61 cite D-013 plain |
| §7.3 | D-231 Position sentence 1 | every `s` and `m` field is isbits or a `Symbol` | row 46's headline, if q4 rules (a) |
| §7.3 | D-231 Position sentence 2 | the frozen-reference latitude stays with signals | row 47's latitude sentence |
| §7.3 | D-231 Position sentence 3 | a PRNG object is workspace, its draw-determining values are state | row 62's headline |
| §7.3 | D-183 Position | the framework never inspects or mutates a workspace | row 51's headline |
| §7.3 | D-077 Position | declaration by allocation; the method is the allocator, called per activation and per scratch-store set | row 52's headline |
| §7.3 | D-263 Position bullet 4 | `ws_init` takes the scalar on both tiers, `Float64` on the discrete one | row 53's headline |
| §7.5 | D-014 Position | the scoped allocation invariant, CI-enforced on the hot path | row 80's budget sentence ("The budget is exactly zero, CI-enforced …"), or M8's scope sentence if q5 adds one |

Not bold, each for the reason given: D-190 (§9.5 holds the bold, q4); the
lineage entries D-006, D-015, D-016, D-035 (history, and D-015's ruling is
§5.3's); D-302 and D-121 (vocabulary, home §4.1); D-035 (home §5.2); D-288,
D-116, D-280, D-247, D-111, D-235, D-238, D-033, D-263 sentence 1 (bold in
chapters 8 and 9); D-263 bullet 1 and D-295 bullet 4 (home §8.2, unbolded
there); D-252 sentence 2 (home §5.3); D-072 (home §14.10); D-074 (home §5.2).
§7.2's three author rules and its lookup rule have no entry stating them, so
they cannot be bold (`check_bold.jl` refuses a bold with no D-citation); they
are stated plain, citing D-011 and, for "an authoring rule", D-235.

### Rewrite units

| unit | lines (original) | moves in | moves out | words |
|---|---|---|---|---|
| A | 1499–1589: heading, new opening, §7.1 | M0, M1, M2 (in place) | — | 819 plus the opening |
| B | 1590–1652: §7.2 | M5 (in place) | M3, M4 to `migration_outline.md` | 484, about 410 after M3 and M4 |
| C | 1653–1794: §7.3 | M6, M7 (in place) | — | 1,125 |
| D | 1795–1884: §7.4, §7.5 | M8, M9 (in place) | — | 824 |

Total 3,433 words. Four units, cut by content: A is continuous state, B the
scalar type, C the other homes, D the history and the policy that rest on the
three. B is small, but its Flight.jl decisions (q2) and its reorder are its
own; joining it to A would make A carry both the opening and two sets of
reader-cold names. D joins two short sections whose only shared hazard is
`f_ode!`; splitting it gives two units of 380 and 444 words, which part G q9
offers.

Each move stays inside one unit. M3 and M4 produce a
`units/B/companion_addition.md` for `migration_outline.md`, which `EXTRA` in
`chapter.sh` names for the PDF.

### Code blocks

Two `julia` blocks: `KF`'s allocator (1713–1716) and `Noise` (1764–1774). No
tables, no display math.

- Carry both verbatim, each as one claim (`checks/norm.py` folds a fenced
  block into one span).
- `Noise` fails its own conformance check as written (F1). Its fix is a ruled
  code edit (q8); until ruled, carry it verbatim and flag it.
- `KF` is cited from §8.1 2007 ("`ws_init(c::KF, ::Type{T})` reads `c.n`");
  it stays as is.
- No new display blocks are needed. Optional: the `KFState` snapshot call
  (1754–1755) as a display line beside `KF`'s allocator, the two ends of one
  idiom.

## D. Inbound citations

The full list is `inbound.tsv` (beside this file): 269 rows, one per "§7" or
"§7.N" occurrence outside chapter 7 (1499–1884) and outside the Contents
block, plus every `#7N-…` anchor; for `decisions.md` rows the `entry` and
`field` columns are filled. The script is `scratch_survey/inbound.py`,
chapter 8's with the targets changed and the briefs and tool tables added.
Link definitions are excluded.

By file: `spec.md` 77, `decisions.md` 106 (Spec 55, Rationale 24, Rejected 13,
Position 12, Annotation 2), `extensions.md` 9, `implementation.md` 7,
`migration_outline.md` 2, `pending.md` 2, `event_visibility_walkthrough.md` 1,
`frozen_discrete_walkthrough.md` 1. That is 205 live rows. The other 64 are
frozen or tabular: `briefs/` 56 (historical records, never edited; many are a
brief's own "§7", not the spec's) and `tools/gloss_table.md` 8 (a record of
where glosses were applied, in an older numbering). The inbound check can mark
those 64 HISTORY in one pass. By target, live rows: §7 10, §7.1 58, §7.2 21,
§7.3 40, §7.4 13, §7.5 63.

`src/` and `test/` cite §7 or a §7.x on 97 lines of comments, docstrings and messages
(`rg -n '§7' src test`). They are not in `inbound.tsv`, as in chapter 8; the
ones that matter are listed below.

### Citations relying on moved or trimmed content

M3 and M4, Flight.jl's walked-type inventory and `attitude.jl` to
`migration_outline.md`:

| file:line | fact relied on | after |
|---|---|---|
| spec 3258 (§8.6, the IMU leaves) | "`FrameTransform` is one of the payload types §7.2 lists as walked" | holds if §7.2 keeps `FrameTransform` as its example, as M3 proposes |
| `extensions.md` 294 | "`@kwdef` defaults pin the no-argument case — the pattern §7.2 already prescribes for the walked payload types" | holds: M3 keeps the pattern sentence in §7.2 |
| `extensions.md` 334 | "§7.2's mechanical parametrization of the walked payload list" | COMPANION: the list moves; retarget to `migration_outline.md` or reword to "§7.2's walked tier" |
| `extensions.md` 220, 278 | "stay `Float64`; promotion handles mixing" | holds: the Pinned tier stays |
| `extensions.md` 283 | "§7.2's 'no `::SomeType{Float64}` annotations' rule" | holds: the author rules stay |
| `migration_outline.md` 25, 109 | the state-declaration conversion to §7.1's closed vocabulary (`RQuat`, `Ranged`) | holds: §7.1 keeps both names (q2) |

M1 and M2, the trims to pointers:

| file:line | fact relied on | after |
|---|---|---|
| spec 4764 (§9.7) | "That is precisely §7.1's buffer-unchanged-within-a-sweep rule." | holds only if §7.1 keeps the rule stated in its own words. M1 must not reduce it to "see §9.7", or §9.7 and §7.1 point at each other (lesson 16) |
| spec 4766 (§9.7) | "per-call by topological necessity either way (§7.1)" | already not in §7.1 (below) |
| spec 12534 (glossary, *one home per datum*); spec 818–825 (§5.2) | "No store mirrors another, and the table never holds transported data (§5.2, §7.1)" | holds if M2 keeps "no state cells in the table beyond the declared ports … interface, not transport"; that is §7.1's share |
| spec 12482, 12587 (glossary, *buffer*, *view*) | authoritative, ephemeral reconstructions; value-identical on re-materialization within a sweep | hold: rows 14–15 stay |

No row relies on §7.3's `####` labels, on the double-buffering heading (M7),
on the position of "Available on both tiers" (M6) or on the event-firings
bullet's form (M9). D-243 Rationale 9086 and 9097 and `test/fixtures.jl`
1413, 1444 rely on "§7.5's remedy" for the absent event stream, which M9
keeps.

### Citations that already rely on content chapter 7 does not hold

The inbound check will flag these whatever the rewrite does; they belong to
track 2, to q5, or to another chapter's rewrite.

| file:line | claim | what chapter 7 says |
|---|---|---|
| spec 4406 (§9.4), 10220 (§14.4), 10778 (§14.8); log 1892 (D-066 Position), 4228 (D-135 Rationale) | the invariant "covers only the stepping loop"; "the stopped-sim path was never under the zero-alloc regime (§7.5)"; "allocation fine per §7.5" | §7.5 never says it. q5 |
| spec 4917 (§9.7), 6420 and 6493 (§11.2), 7061 (§11.5), 7819 (§11.8); log 3194 (D-107, superseded), 3491–3493 (D-116 Rationale), 4298 (D-136), 4369 (D-137), 6297 (D-176), 9001 (D-241), 12008 (D-288 Rationale); `src/dataplane.jl` 670, `src/sim.jl` 2227 | "the §7.5 carve-out", "the retention carve-out", "the framework side of the §7.5 scope, which already carved out logging", "scoped to the model sweep" | §7.5 holds the logging bullet (amortized-zero) and nothing named a carve-out or a framework side; publication's per-boundary snapshot is not mentioned. q5 |
| spec 12067 (Appendix C, `IllegalPortType`) | cites §7.1 for a port type the walk cannot lay out | §7.1 states no port-type condition; §4.3 547–549 does. Track 2: cite §4.3 |
| spec 12548 (glossary, *scratch*) | "the integrator's buffers and the mid-step table (§7.5, §10.3, §10.4)" | §7.5 mentions neither. Track 2 |
| spec 4766 (§9.7) | "The sweep-varying bundle fields (`u`, `y_x`/`y_s`) are per-call by topological necessity either way (§7.1)" | §7.1 never says it, nor did its July text (`git show f9e2cac:docs/framework_spec.md`, 660–700). Chapter 9's sentence; track 2 |
| log 7349 (D-203 Rejected) | "the clock is seeded `zero(T)` (§7.2)" | §7.2 says nothing about the clock |
| spec 304, 331 (§3.1, §3.2) | continuous state "an isbits struct of real scalars (§7)"; discrete state "any isbits value (§7)" | §7.1: a flat `NamedTuple` of real scalars and `SArray`s; §7.3: fields isbits or `Symbol` (D-231). Chapter 3's rewrite |
| `src/diagnostics.jl` 1043, `src/executor.jl` 383, `src/build.jl` 1619; `test/test_store.jl` 176, `test/test_failures.jl` 722 | "a discrete successor is the store's own type exactly (§7.3)" | §7.3 does not state it; §9.5 4565 does. Track 2 (implementation side) |
| spec 2599 (§8.2); log 12324 (D-295 Position), 5860 (D-166 Rejected) | "§7.1 admits no pinned state leaf" | §7.1 implies it ("of a common eltype `T`"), never says it. D-295 points back to §7.1 for the reason, so §7.1 must not cite D-295 for it (lesson 16); "of a common eltype `T`" must survive word for word |
| spec 11539 (Appendix B) | "`x_deriv` returns the layout image of `X` (§7.1)" | §7.1 says "an `Ẋ`-typed value, which is scatter-stored into the flat `ẋ` buffer"; "layout image" is Appendix B's phrase. VAGUE, holds in substance |
| spec 2258 (§8.2) | "A workspace earns the exception because it is not memory … (§7.3)" | §7.3 says "mutable scratch, deliberately not state at all"; "not memory" is D-077 Rejected's phrase. VAGUE, holds in substance |
| log 5575 (D-162 Position) | "cells flattened by §7.1's leaf walk" | §7.1 says "flat layout"; the glossary's *leaf walk* cites §8.2. VAGUE |
| log 3644 (D-121 Rationale) | "§7.3's term is author-facing, poison-covered scratch" | the poison was retired by D-183; history, stays true as history |

Rows that record history and stay true as history: log 8572, 8576, 8599
(D-231 on "the prior §7.3 text"), 12553 and 12565 (D-302 on "store" as §4.1
and §7.3 used it), 3964–3997 (D-131's consistency sweep).

Quoted phrases the rewrite must keep word for word, because a row outside the
chapter quotes them: "buffer-unchanged-within-a-sweep" (spec 4764); "the
explicit cast" (spec 3279 `# §7.1's explicit cast`); "domain wrapper type"
(spec 2303, 2480, 3255); "of a common eltype `T`" (above); "the CI invariant"
(spec 2540, 5047); "the discrete exemption" (spec 2467); "stay `Float64`" and
"promotion handles mixing" (`extensions.md` 220, 278); "the canary" (spec
4484; D-151); "a documented tolerance" (spec 4914); "interned, immutable and
never freed" (spec 545; D-243 9081); "governed by contract rather than by
checks" (D-231 8576 paraphrases it); the step numbers of §7.4 (spec 10578;
D-125; D-169).

### Log entries whose Spec field would change

- Under M3 and M4: none.
- Under q5, if M8 cites D-288: D-288 gains §7.5. D-135 already lists §7.5.
- New citations the rewrite adds (part E, "Entries to cite at the rule") give
  these entries a §7 section their Spec field lacks: D-010 and D-014 (no Spec
  field at all), D-302 (§7.1), D-288 (§7.1), D-035 (§7.1), D-280 (§7.2),
  D-295 (§7.2), D-238 (§7.2), D-070 (§7.2, if cited), D-074 (§7.3), D-194
  (§7.3, though its Position cites §7.3), D-034 (§7.4), D-137 (already §7.5),
  D-116 (already §7.5).

The recipe updates the Spec fields at landing (step 7.3). The missing Spec
fields of D-010 and D-014 are track 2 either way.

## E. Log repairs and factual problems

Log repairs go to the second track, after landing (recipe step 8). The rewrite
only adds citations; it states no repair. Factual problems stay as written and
go to the units' `rulings.md`, unless part G pre-rules them.

### Entries to cite at the rule

From part A's U rows, by entry: D-010 (7, 8, 14), D-014 (77, 80), D-032 (31),
D-033 (1, 53), D-034 (72), D-035 (8, 17), D-070 (38, optional), D-072 (23
bullet 5, 26, 36), D-074 (49), D-077 (52, 55), D-111 (9), D-116 (80, 81),
D-121 (43, 44), D-137 (82), D-183 (50), D-194 (49), D-235 (9), D-238 (32),
D-247 (2), D-252 (17), D-263 (27, 28, 30, 53), D-266 (38, optional), D-280
(25b), D-288 (16), D-295 (28, 30), D-302 (7, 43, 44), D-011 (24), D-013 (43,
49, 61), D-015 (74, 75), D-231 (47).

Cited nowhere in the spec, though each rules a whole section: **D-010**
(§7.1's subject: structured immutable state over a framework-owned flat
vector; its Rejected list holds three of the five "things bought") and
**D-014** (§7.5's subject: the scoped allocation invariant, CI-enforced; its
Rejected list holds "not dogma" and the canary). Neither has a Spec field
(`decisions.md` 477–490, 547–558; seven other entries also lack one:
D-002, D-003, D-009, D-030, D-062, D-076, D-161). Cited nowhere in the
chapter, though each rules a block of it: D-121 and D-302 (the store
vocabulary), D-288 (views), D-116 (the tiers), D-280 (the CI invariant).

### Superseded and half-superseded citations

No superseded entry is cited. Half-superseded or stale entries the chapter
cites, by whether they are annotated:

- D-016 (cited 1805): annotated "superseded in part" (log 595–597). Cited for
  history; stands.
- D-035 (cited 1805, 1808): its Position keeps "selective auto-publication of
  declared state/mode fields" (log 1101), which D-252 retired. D-252's
  Position names D-016's publication rule, D-152 and D-169 as superseded, not
  D-035's clause, and D-035 carries no annotation. The chapter cites D-035
  for step 4 (stores and views), which stands.
- D-013 (cited 1793): Position "Immutable `z` in cells + workspace +
  snapshot idiom" (log 537). `z` is `s` since D-195, and discrete state lives
  in stores, not cells, since D-121, whose Rejected list (log 3658–3659) says
  the historical D-013 is annotated, never rewritten. D-013 carries no
  annotation.
- D-077 (cited 1728, 1738): Rationale (log 2274–2276) keeps "scoped debug
  poison"; D-183 Rationale (log 6569–6570) "supersedes D-077's poison
  clause". D-077's one annotation (log 2278–2281) concerns D-263 only.
- D-220 (cited 1740): its Rationale's "`init` … means *establish*" stands,
  annotated for the renames (log 8129–8133).

### Rulings that need an entry stating them in a Position

1. **The flat declaration** (row 6): D-094's annotation of 2026-09-14 only.
   It is cited and would take bold.
2. **Why the vocabulary is closed, the explicit cast, and where invariants
   live** (rows 5, 18, 20–22): D-094 Rationale log 2771–2778.
3. **Derivative completeness is structural** (row 12): D-190 Rationale log
   6837–6840.
4. **The buffer is unchanged within a sweep, the CSE's legality condition**
   (row 15): D-086 Rationale log 2559–2560 and D-288 Rationale log
   11994–11995, as "the staleness rule". §9.7 4764 cites it by name as a
   §7.1 rule.
5. **The four consumers of genericity** (row 25a): D-011 Rejected log
   502–503.
6. **Participation is authored per leaf** (row 29): D-263 Rationale log
   10309–10312.
7. **Store fields: the `Symbol` grounds, the nesting rejection, no arithmetic
   on `s` and `m`** (rows 45, 46): D-231 Rationale log 8589–8596; D-302
   Rationale log 12560–12562.
8. **The workspace's sizes and eltypes, the `undef` marker, both tiers under
   `Dual`, `init` as *establish*** (rows 55, 56, 58, 59): D-077 Rationale log
   2271–2274; D-183 Rationale log 6567–6568; D-220 Rationale log 8111–8113.
9. **A plan or factorization configured at allocation is valid from then on**
   (row 51): D-183 Rejected log 6574–6576.
10. **The workspace is never a condition target** (row 50): D-077 Rejected
    log 2288–2291 only.
11. **Rematerializing the generator allocates** (row 64): D-231 Rationale log
    8584–8588 and Rejected 8605–8606.
12. **Double-buffering deferred** (row 67): D-013 Rejected log 545.
13. **Not dogma; the canary** (rows 77, 79): D-014 Rejected log 556–557;
    D-116 Rejected log 3505–3507.
14. **The tiers' membership: guards and projection exactly zero, handlers
    zero by idiom** (rows 80, 81): D-116 Rationale log 3491–3493.
15. **`sizehint!` to the bound; field handles as references** (rows 82, 83):
    D-137 Rationale log 4339–4341, 4379–4381.
16. **The invariant's scope: the stepping loop, the services
    allocation-tolerant** (q5): D-135 Rationale log 4228–4230.
17. **Prior-art caches; the split's measured cost** (rows 73, 76): D-015
    Rejected log 573–574, 578–579.

### Rulings with no entry at all

- §7.1: "`Int`s, enums and `Bool`s belong in modes" (row 3), a redirect the
  structure step's message repeats (§8.2 2611); "the buffer is authoritative"
  as worded (row 14).
- §7.2: the three author-facing rules (rows 39–41), stated under **Rule.**,
  with only D-235's Rejected list calling type stability "an authoring rule";
  the lookup rule and its caveats (rows 37–38).
- §7.3: "not snapshotted, not replayed" (row 50); the `SArray` codegen claim
  (row 65); the snapshot discipline, `ValueSnapshot` and the ceiling (row 66).
- §7.5: the three reasons as reasons (row 78); "event firings are not
  recorded" and the event-firing stream as a guarded addition (row 84); the
  garbage levers (row 85).

Some are descriptions of an inherited status quo: the walked-type inventory
and "roughly half the type inventory" (rows 33–34), "need no migration" (row
35), "which the codebase already mostly does" and `attitude.jl` (rows 39,
41), "the compositions in use" (row 37), "HDF5 logging" and "OrdinaryDiffEq"
(row 23, bullet 4). These are Flight.jl's, from the July 2026 source text
(`git show f9e2cac:docs/framework_spec.md`, 660–700), and they record what
FlightCore and FlightPhysics did rather than rulings. The author rules, the
lookup rule and the allocation reasons read as rulings the July text made and
the log never recorded; they go to the owner (recipe step 8, lesson 17).

### Stale entry text and Spec fields

- D-010 and D-014: no Spec field. Add §7.1 and §7.5.
- D-013 Position: `z` and "cells" (above). No annotation.
- D-035 Position: "selective auto-publication" (above). No annotation.
- D-077 Rationale: the poison clause (above). No annotation pointing at
  D-183.
- D-295 Position cites §7.1 (log 12324) and its Spec field (log 12326) lacks
  §7.1. Same for D-194 (its Position cites §7.3 at log 6973, its Spec field
  lacks it).
- D-288 Position bullet 2 rules §7.1's views; its Spec field lists §9.7 and
  §10.5 only.
- D-066 Spec field lists §7.5 for "allocation fine per §7.5", which §7.5 does
  not say until q5 is ruled.
- D-121 Rationale (log 3644) "poison-covered scratch": history since D-183;
  an annotation would serve.

### Factual problems in chapter 7

None meets the recipe's test for **serious**: no two authoritative sources
contradict each other on the design, and no fix changes what the framework
does. F1 is a defect in an example, proven by running it. The rest are prose,
vocabulary or pointer problems, and the status-quo descriptions part G q2
handles.

- **F1. The PRNG example fails its own conformance check** (1764–1774).
  `s_init` writes the four words as 8-digit hex literals, which Julia types
  `UInt32`, so the store type is `NTuple{4, UInt32}`. `s_update` returns the
  words read back from `Xoshiro`'s fields, which are `UInt64` (Julia 1.13.1:
  `fieldtypes(Xoshiro) == (UInt64, UInt64, UInt64, UInt64, UInt64)`). Running
  the block verbatim against the framework (`scratch_survey/noise_check.jl`)
  gives: "ConformanceFailure: `n`: s_update returns
  @NamedTuple{rng::NTuple{4, UInt64}}, state store is
  @NamedTuple{rng::NTuple{4, UInt32}} — a discrete successor is the store's
  own type exactly (§7.3)". With `s_init(::Noise) = (rng =
  UInt64.((0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667)),)` the same model
  runs three ticks and the state stays `NTuple{4, UInt64}`. Correction: that
  `s_init` line, the rest of the block unchanged. Clear (q8). Two notes for
  the record, neither ruled: `Xoshiro` has a fifth field, `s4`, in Julia
  1.13, which the example leaves untouched; and D-231 Rationale (log
  8588–8589) says "the spec … stays silent on the generator's internals",
  while the example names `s0` to `s3`. Both were in the same commit
  (`d80f6dd`), so the owner chose the illustration; the fix keeps it.
- **F2. "The `init_` prefix"** (1738). No declaration has an `init_` prefix
  since D-267 renamed `init_workspace` to `ws_init` (log 10609–10610); D-220's
  annotation of 2026-09-25 (log 8133) records the move "from prefix to
  qualifier". Correction: "The `init` in `ws_init` means *establish* …". One
  instance in the chapter (grep `init_`: 1738 only; `x_init`, `s_init`,
  `m_init`, `ws_init` elsewhere are names). Clear.
- **F3. The workspace called a store** (1737, "the by-allocation convention
  this store actually lives in"). D-302 Position: a store is the home of a
  state letter, `x`, `s` or `m`; the suite names the workspace "the register
  that is not a store" (`test/test_store.jl` 113). Correction: "this
  declaration" (it is the declaration the `undef` sits in). One instance
  (grep `store` in §7.3: 1737 is the only one naming the workspace). Clear.
- **F4. "The buffer holds `x`, the stores hold `s` and `m`"** (1551–1552).
  Since D-302 (log 12545–12548) a store is the home of any state letter and
  an `x` store is a range of the buffer; §4.1 452–454 and the glossary's
  *store* (12565) were updated, §7.1 was not. Correction: "the `s` and `m`
  stores hold `s` and `m`". One instance in the chapter (1663–1664 already
  reads "typed stores, apart from the buffer that holds `x`"). The same
  sentence stands in §5.2 822 and the glossary's *one home per datum* (12532),
  outside the chapter: carry note for chapter 5 and track 2. Clear.
- **F5. "They are isbits values"** (1657). D-231 admits `Symbol` fields, and
  a store value with one is not isbits (`isbitstype(NamedTuple{(:a,),
  Tuple{Symbol}}) == false`). Correction: "values whose fields are isbits or
  `Symbol`s (below)". One instance; 1672's rule already says it, and 1685's
  "copies bits" holds for a `Symbol`, which copies as a pointer (D-231
  Rationale log 8591). Clear.
- **F6. "Every declaration is written at nominal `Float64`"** (1610–1611).
  `ws_init` takes the scalar and is not written at nominal `Float64` (§7.3
  1718; D-263 Position bullet 4). D-263's sentence says "Every contract
  declaration". Chapter 8 ruled the same overreach (its F22, "Every
  declaration of a structural fact but the allocator", spec 2189).
  Correction: "Every declaration but the allocator (§7.3) is written at
  nominal `Float64`". One instance (grep "Every declaration": 1611 only).
  Clear.
- **F7. "A split-form spelling of the same model"** (1833) has no
  antecedent. The July text read "See `sketch_decoder.jl` for the worked
  example; against a split-form spelling of the same model …"
  (`git show f9e2cac:docs/framework_spec.md` 865–867); commit `7a0d8d9`
  ("Remove the companion sketch references from the spec") dropped the first
  clause. `prototypes/sketch_decoder.jl` 1 calls its model "the rigid-body
  kinematics/dynamics core". Correction: "Against a split-form spelling of a
  rigid-body kinematics and dynamics core (four components, thirteen
  connections), the merged form has half the components and wiring (D-015)",
  without the file name, which `7a0d8d9` removed on purpose. Clear; the cited
  entry is D-015 Rejected (log 578–579).
- **F8. §7.5 lacks the scope the corpus cites it for.** Part D's first two
  rows: seventeen citations rely on §7.5 stating that the invariant covers the
  stepping loop, that the stopped-sim services allocate freely, and that
  publication and logging sit on the framework side of the scope. §7.5 states
  the logging tier only. Not a factual error in §7.5's sentences, a gap. Part
  G q5.
- **F9. "today's", "the codebase", "in use"** — Flight.jl's status quo stated
  as the reader's present. Grep of the chapter for today|current|existing|
  codebase|in use|live example: 1565 ("today's `f_ode!` code" = FlightCore's),
  1572 ("today's flat-`Vector` + `ComponentArrays`-views pattern" =
  FlightCore's), 1813 ("today's `y_state`" = the current name), 1628
  ("every existing `AbstractVector{Float64}` method, so existing behavior" =
  Flight.jl's), 1640 ("compositions in use" = Flight.jl's tables), 1647
  ("which the codebase already mostly does" = Flight.jl's), 1651 ("the live
  example" = Flight.jl's `attitude.jl`). Corrections: 1565 and 1572 →
  "FlightCore's"; 1813 → "(now `y_state`)"; 1640 → "in Flight.jl's tables";
  1628, 1647, 1651 follow q2 (M3, M4). Clear.
- **F10. "Once §8.3 made publication a deliberate interface act"** (1808).
  §8.3 (2715–2780) decides visibility by declaration (D-034) and says
  "Publicity is never implicit (D-297)"; in substance it holds. But
  "publication" now means the per-boundary snapshot (§11.2 "Outbound: snapshot
  publication"; glossary *snapshot*, "the immutable per-boundary
  publication"), and the step's sense is the retired publication of state as
  ports. D-035 Rejected (log 1110–1113) words the history: the camouflage
  "fell with contract visibility". Correction: "Once contract visibility
  (§8.3, D-034) made a port's publicity a declaration". One instance. Clear,
  wording only.
- **F11. "fails loudly … on any Float64-pinning"** (1602–1603). Read as the
  three author anti-patterns of 1646–1651, it holds: each fails at the `Dual`
  sweep. Deliberate stripping with `ForwardDiff.value` passes silently (§9.5
  4536–4553), and the Pinned tier and `Pinned{P}` pin on purpose. Leave as
  written; flag for the rewriter not to sharpen it.
- **F12. The hot path's "unconditional" projection** (1847–1851). §5.3 runs
  `x_projection` after integration (every boundary) and after a handler's `x`
  reset (only on firing, §5.3 928–936). D-116 Rationale calls projection
  unconditional and keeps it in the zero tier per body. Leave as written; the
  tier is per body, not per call site.
- **F13. `ValueSnapshot{N,T}`** (1785). No such type exists in `src/`, in the
  log, or elsewhere in the spec. "It is optionally enforceable by" reads as an
  available option. Who would build it is a design question with no entry.
  Leave as written; the owner's list (track 2, lesson 17).
- **F14. `GC.gc(false)` at frame boundaries** (1879–1880). `pending.md`
  109–110 already records that nothing in `src/` builds it and frames it as a
  design question under "Publication's garbage". Leave as written; no new
  escalation, since `pending.md` holds it.
- **F15. "Integrator compatibility (OrdinaryDiffEq or custom), trim solvers,
  HDF5 logging"** (1584–1585). §10.2 4992 drops OrdinaryDiffEq as a
  dependency (an extension stays possible, 5061), and HDF5 export is
  unsettled (`pending.md` 127–131). FlightCore-era status quo; the sentence
  claims compatibility, not a feature. Leave as written; flag.
- **F16. "Event handlers and projection return a new `X`"** (1521–1522). A
  handler returns a `NamedTuple` whose optional `x` key is the new `X` (§5.2
  "The handler return law"; §9.5 4576–4590; D-287). Correction: "A handler's
  `x` key and the projection carry a new `X`". One instance. Clear, low
  stakes.
- **F17. `IllegalStateLeaf` unnamed** (1503–1512). Appendix C 12001 cites
  §7.1 for it; §7.1 states its condition and never names it. Correction: one
  clause naming the kind where the vocabulary is stated, pointing to §8.2 for
  the messages and §9.1 for the step. Clear (q8).

Not problems, checked: `phase_bodies` exists (`src/sim.jl` 427); `Pinned`
exists (`src/leaves.jl`, `src/declare.jl`); `ws_init(::C, ::Type{T})` matches
`src/declare.jl` 45–50 and the suite's fixtures; `IllegalStoreField` exists
(`src/diagnostics.jl` 859–870); the two positions of `x_projection` (1523,
1850) match §5.3 928–936; `sizehint!` to the bound matches D-137 and
`src/dataplane.jl` 725; the device contract's `init!` is in §11.6.

## F. Difficulty per section

| unit | difficulty | reason |
|---|---|---|
| A (opening, §7.1) | medium | a new opening, all of it declared additions; five reader-cold Flight.jl names (q2); the `Ẋ` paragraph moves after the vocabulary's reason; M1 and M2 trim two duplicates without losing the two clauses §9.7 and the glossary cite; three bolds, one of them on an annotation; F4, F9, F16, F17; seven entries to cite that the section never cites (D-010, D-035, D-072, D-111, D-235, D-288, D-302) |
| B (§7.2) | medium | the reorder for define-before-use; M3 and M4 send text to a companion, and the residue must keep `FrameTransform`, the `@kwdef` pattern and "stay `Float64`; promotion handles mixing"; a **Rule.** label over three rules with no entry, which therefore cannot be bold; two senses of *pinned*; F6, F9; Interpolations.jl takes an introducing clause |
| C (§7.3) | high | the largest unit; five **Rule.** and two **Why.** labels to fold; seven bolds across four entries (D-013, D-231 three times, D-183, D-077, D-263 bullet 4); a Position ruling inside a **Why.** (row 47); M6 and M7; a new `#### Idioms` label; a ruled code edit (F1); F2, F3, F5; phrases quoted from outside |
| D (§7.4, §7.5) | medium | the lineage's numbering is cited from outside and stays; F7's antecedent and F10's wording; M8's scope sentences are declared additions resting on Rationale (q5); M9; the only two links to `#g-log` in the spec; F12–F15 stay as written and flagged |

Warnings for the rewriters:

- **Terms of art stay verbatim**: closed vocabulary; common eltype; flat
  layout; reconstruct, reconstruction; view, materialize, ephemeral;
  authoritative; buffer-unchanged-within-a-sweep; codegen freedom; one home
  per datum; interface, not transport; invariant-carrying; domain wrapper
  type; explicit, invariant-free cast; write paths; activation scalar;
  walked, pinned, exempt; discrete exemption; frozen-exact; CI invariant;
  feedthrough tracer; embedding guarantee; participation; typed stores;
  isbits or a `Symbol`; opaque leaf; frozen-reference latitude; excluded from
  state semantics; escape hatch; contract, not checks; by allocation;
  scratch-store set; blessed idiom; snapshot; codegen catastrophe;
  no-feedthrough stage; identity decode; transport; fused economics;
  computer/integrator split; the canary; continuous hot path; zero by idiom;
  documented tolerance; amortized-zero; summarize-or-skip; guarded addition;
  honest levers.
- **Distinctions the log fought for.** "authoritative … ephemeral"; "on the
  write paths, never on views"; "contract rather than … checks"; "allocated,
  not retyped"; "by allocation, never by initial value"; "interface, not
  transport"; "not a limitation but the exact answer"; "table data is a
  pinned parameter and the query coordinate is walked traffic". A paraphrase
  that drops one half changes the rule.
- **Phrases quoted from outside** (part D, last list): keep each word for
  word. The one most at risk is "the buffer is unchanged within a sweep":
  M1 trims the paragraph around it, and §9.7 4764 cites §7.1 for it by name.
  Do not reduce it to a pointer to §9.7, which points back (lesson 16).
- **Lesson 16, twice.** D-295 Position cites §7.1 for "no pinned state leaf",
  so §7.1 must not cite D-295 for it. §9.7 cites §7.1 for the
  buffer-unchanged rule, so §7.1 must state it, not point to §9.7.
- **Antecedent hazards.** Row 14's "Nobody outside the framework" follows the
  bold sentence directly; an inserted D-010 gloss between them moves no
  antecedent, but one inserted after "'Ephemeral' is literal" would orphan
  "It". In §7.3, "That multiplicity" (1749) points at the continuous calls of
  1748; M6 must not land between them. In §7.4 step 4, "That decoder" (1814)
  points at "the stage-1 decoder itself (today's `y_state`)"; F9's "(now
  `y_state`)" sits inside the parenthesis and moves nothing. In §7.5, "these
  are the honest levers" (1881) needs both tools before it.
- **Citations covering several clauses.** 1512's D-094 covers the flat
  declaration, which is the annotation, not the Position; the vocabulary's
  Position citation sits at 1564. Splitting 1503–1512 needs D-094 at both
  rulings. 1680's citation list covers the check and the kind only; the
  `Symbol` grounds are D-231's Rationale. 1728's D-077 and D-263 cover the
  **Why.** only; row 53's rule needs D-263 at its own sentence.
- **Bold that duplicates another chapter's bold.** §7.1 1534 (D-190, bold at
  §9.5 4560) and §7.3 1672 (D-231, bold at §9.1 3728) are bold today; q4 rules
  both. `check_bold.jl` sees chapter 7 only once it joins `REWRITTEN` at
  landing; grep chapters 8–10 for `**` beside the entry before bolding
  (`scratch_survey/bold_rewritten.txt` lists them).
- **The log's vocabulary is old.** D-013 says `z` and "cells", D-077 says
  `workspace` and poison, D-094 `init_x` and `project`, D-016 and D-006
  `h_x`/`h_xu`, D-015 `f`/`h`, D-231 "Stratum A" and `init_s`/`init_m`, D-220
  `init_workspace`. Never import them when citing an entry.
- **Glossary links reset per section.** The chapter links 30 distinct anchors.
  One link per term per section, at first use. Keep at least one
  `[log](#g-log)`: no other body line links it. `#g-one-home-per-datum` and
  `#g-feedthrough-tracer` each have one other body link only.
- **Flight.jl names** take one introducing clause that claims nothing beyond
  its source (lesson 14). For `RQuat`: a rotation quaternion type with a
  `normalization` keyword (spec 1582; `migration_outline.md` 108–111). For
  `Ranged`: a clamped scalar (D-094 Rejected log 2789; `migration_outline.md`
  111–113). For `f_ode!`: FlightCore's in-place derivative function (log
  2018, "mutating `f_ode!`"; `flight_case_studies.md` 22–28). For
  `ComponentArrays`: mutable views into the flat vector (the section's own
  bullet 1). For `get_x_ss`: FlightCore's per-aircraft state-space mapping
  functions (the section's own words). For Interpolations.jl: the package
  Flight.jl's lookup tables use (`migration_outline.md` 28).
- **"today's"** means FlightCore's at 1565 and 1572, and the current name at
  1813 (F9).
- **Code**: two blocks, carried verbatim; `Noise` waits on q8 (F1).

## G. Decisions at checkpoint 1

Settled for every chapter and not asked again: log repair rides track 2, and
bold marks one headline clause per ruling (recipe step 1, checkpoint 1).

**q1. The chapter opening (M0).** Chapter 7 has no context paragraph after
`## 7.`. Options: (a) add one, sourced from the Part I roadmap (spec 133) and
chapter 8's opening (spec 1900), plus a roadmap sentence naming §7.1 to §7.5;
(b) a roadmap sentence only; (c) nothing. Recommendation: (a). Every
rewritten chapter opens that way, spec_style's template puts context first,
and the sources exist, so the paragraph claims nothing new. Its words are
declared additions in unit A's inventory.

**q2. The Flight.jl material.** spec_style: "Flight.jl machinery used as if
known moves to a companion, or the spec says what it is." Per item:

| item | lines | proposal | why | destination holds it? |
|---|---|---|---|---|
| `RQuat`, `Ranged` | 1507, 1582 | keep, one introducing clause at first use | spec 2303, 2480, 2614, 3255 and `migration_outline.md` 25, 109 cite §7.1 for them as domain wrapper types | — |
| `f_ode!` | 1566 | keep as "FlightCore's `f_ode!`", with a short gloss | FlightCore as predecessor needs nothing; its function needs a clause | — |
| `ComponentArrays` and the five things bought | 1572–1588 | keep in §7.1 as the contrast with FlightCore, "today's" → "FlightCore's", `ComponentArrays` glossed | constructive: each bullet says what the design gains; spec 4653, 11127 and D-072 rely on bullet 5 | `flight_case_studies.md` section 1 is the `Vehicle` case study and holds none of it |
| `get_x_ss`/`assign_x_ss!`/`get_u_ss` | 1587 | keep, introduced as FlightCore's | spec 4653 and 11127 discharge "the promised `get_x_ss` deletion (§7.1)"; D-072 Position too | — |
| the walked-type inventory, `Quaternion{N,T}`, the invariance sentence | 1623–1628 | move to `migration_outline.md`'s "parametrization pass" (M3); §7.2 keeps the tier, `FrameTransform` as its example, and the pattern sentence | it is FlightPhysics' migration list, used as if known; the outline's row "The walked-leaf parametrization pass" is its natural home | no: the outline's paragraph (30–35) covers `Ranged` at ports and parameters only |
| `@kwdef` | 1630 | keep, glossed as Julia's keyword-constructor macro | Julia, not Flight.jl; `extensions.md` 294 cites the pattern | — |
| `attitude.jl` and "which the codebase already mostly does" | 1647, 1650–1651 | move to the same outline paragraph (M4) | a file the reader cannot open; a claim about Flight.jl's code | no |
| Interpolations.jl, "in use" | 1637–1644 | keep with an introducing clause; "in use" → "in Flight.jl's tables" | general guidance for any lookup table; D-070 rules `Cubic` | — |
| FlightCore's `f_ode!` in §7.4 | 1826 | keep | predecessor named; §5.3 says the same | — |

Options: (a) as the table; (b) keep everything in place with introducing
clauses, moving nothing out; (c) move the five things bought to
`flight_case_studies.md` as well. Recommendation: (a). (c) would send three
inbound rows to a companion for a list that states what the design gains.
Under (a), `extensions.md` 334 needs a retarget, an outside edit at landing.

**q3. §7.4, the history section.** Options: (a) keep it in place and whole,
rewritten for prose, the step numbers kept; (b) reduce the four steps to one
paragraph pointing at D-006, D-015, D-016, D-035 and D-252, keeping the prior
art and the split; (c) move the lineage to a companion. Recommendation: (a).
Each step is cited (C), the entries hold every step, but spec 10578, D-125
and D-169 cite steps 2 and 4 by number, §5.3 1035 sends the reader here for
the split "including when the factoring earns its keep", and the arc is
constructive: it explains why §5.2's interfaces have their shape.
`decisions_style.md` 68–71 puts FlightCore contrast in the log's Rationale,
but this section's history is the log's own sequence, cited, not FlightCore's.

**q4. One bold per ruling where another chapter already bolds.** (i) D-190
is bold at §9.5 4560 ("`x_deriv` checks against `X`'s own shape"). Its
Position is one sentence, one ruling. Options: (a) no bold in §7.1, D-190
cited plain; (b) bold in §7.1 too. Recommendation: (a), by the mechanical
test. (ii) D-231 sentence 1 joins the field rule and the check with "and".
§9.1 3728 bolds the check ("checked on `s_init` and `m_init` field by
field"). Options: (a) read the "and" as joining two rulings, the rule (home
§7.3, bold there) and the check's timing (home §9.1, bold there), as
spec_style's "a ruling about when a check runs is bold where the run is
described" implies; (b) one ruling, already bold at §9.1, so §7.3 cites plain.
Recommendation: (a). The isbits rule is §7.3's subject, and chapter 9's bold
names the run, not the rule. Record the reading in `brief.md` so the bold
check across chapters does not flag it.

**q5. The invariant's scope (M8, F8).** Seventeen citations rely on §7.5
stating the scope: the stepping loop or model sweep, the stopped-sim
services allocation-tolerant, publication and logging on the framework side.
§7.5 states the logging tier only. Options: (a) add two sentences after the
three reasons, one stating the scope and the services' tolerance (D-135
Rationale; §9.4 4406; §14.8), one placing publication's per-boundary snapshot
on the framework side with logging (D-288 Position "Publication is not a
phase body", bold at §9.7; §11.2 6420), both plain, D-014's bold staying on
the budget sentence; (b) leave §7.5 as is and let the inbound check mark the
seventeen rows VAGUE for track 2. Recommendation: (a). The facts are recorded
(a Position for publication, a Rationale for the services), they are what the
section's title "a scoped invariant" promises, and seventeen rows already
read them there. Track 2 then owes D-135's scope a Position.

**q6. Duplicates trimmed to pointers.** M1 (codegen freedom → §9.7, keeping
the buffer-unchanged rule), M2 (one home per datum → §5.2, keeping §7.1's
clause), M6 (both tiers merged into the scalar rule). Options: (a) all three;
(b) none, the duplicates recorded for chapter 5's and the final pass.
Recommendation: (a). Each keeps the clause an outside row cites (part D).

**q7. Orders and labels.** §7.1's `Ẋ` paragraph after the vocabulary's
reason; §7.2's tier list before the walk paragraph (M5, a define-before-use
fix); §7.3's labels (a new `#### Idioms`, the double-buffering heading folded
into the stores, M7); §7.5's event-firing bullet as a paragraph after the
tiers (M9); no subheadings in §7.1, §7.2, §7.4, §7.5. Options: (a) all; (b)
M5 only, as the one define-before-use fix; (c) none. Recommendation: (a). No
row names a `####` label, and each order was checked in part C.

**q8. Clear factual corrections, ruled before writing** (lesson 13; each
grepped for every instance, lesson 19):

1. F1 (1765): `s_init(::Noise) = (rng = UInt64.((0x9e3779b9, 0x243f6a88,
   0xb7e15162, 0x6a09e667)),)`, the rest of the block unchanged. Evidence:
   the block fails `ConformanceFailure` as written and runs with this line
   (`scratch_survey/noise_check.jl`).
2. F2 (1738): "The `init` in `ws_init` means *establish*". Evidence: D-267
   log 10609–10610; D-220 annotation log 8133.
3. F3 (1737): "this declaration" for "this store". Evidence: D-302 Position.
4. F4 (1551–1552): "the `s` and `m` stores hold `s` and `m`". Evidence: D-302
   Position; §4.1 452–454.
5. F5 (1657): "values whose fields are isbits or `Symbol`s". Evidence: D-231
   Position; `isbitstype` of a `NamedTuple` with a `Symbol` field is false.
6. F6 (1611): "Every declaration but the allocator (§7.3) is written at
   nominal `Float64`". Evidence: D-263 Position bullet 4; chapter 8's F22.
7. F7 (1833): "a split-form spelling of a rigid-body kinematics and dynamics
   core", cited to D-015. Evidence: the July text; `7a0d8d9`;
   `prototypes/sketch_decoder.jl` 1.
8. F9 (1565, 1572, 1640, 1813): "FlightCore's" twice, "in Flight.jl's
   tables", "(now `y_state`)". Evidence: the grep in F9.
9. F10 (1808): "Once contract visibility (§8.3, D-034) made a port's
   publicity a declaration". Evidence: §8.3 2721, 2742; D-035 Rejected
   log 1110–1113.
10. F16 (1521–1522): "A handler's `x` key and the projection carry a new
    `X`". Evidence: §5.2's handler return law; §9.5 4576–4590.
11. F17 (§7.1): name `IllegalStateLeaf` where the vocabulary is stated, with
    pointers to §8.2 and §9.1. Evidence: Appendix C 12001.

Leave as written, flagged: F11 (CI invariant's "any Float64-pinning"), F12
(projection "unconditional"), F13 (`ValueSnapshot`, owner's list), F14
(`GC.gc(false)`, already in `pending.md`), F15 (OrdinaryDiffEq, HDF5).

**q9. The units.** Four units as in part C: A 819 plus the opening, B 484, C
1,125, D 824. Options: (a) as proposed; (b) split D into §7.4 (380) and §7.5
(444), five units; (c) join A and B (1,303), three units. Recommendation: (a).
B's Flight.jl moves and reorder are its own work, and D's two sections are
short enough for one rewriter and one verifier.

**q10. Adversarial passages.** spec_style sends "why alternative X loses" to
the log. Candidates: 1561–1563's "no constructor bypass, no `reinterpret`,
and no reliance on a custom struct's memory layout" (D-094 Rejected holds
both alternatives); §7.4's prior art (1817–1823; D-015 Rejected holds the
caches' verdict); 1776–1777, rematerializing the generator (D-231 Rejected).
Options: (a) cut each to a pointer at its entry; (b) keep all. Recommendation:
(b). The first states a property the design has (the round trip holds with no
special machinery), the second is orientation in support, introduced "for
orientation", and the third steers the author to the blessed idiom. None
argues a design down.
