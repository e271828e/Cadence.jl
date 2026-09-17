# Increment 42 — the Appendix C payload fills and the contract-arity move (§6.1, §8.5, §8.6, §9.5, §11.3, §12.6, §13.2, §13.5, Appendix C, D-216, D-249)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `cff996f` (the docs-first commit) plus the register commit that adds
this brief. Never `cd` elsewhere (`cd` is aliased to zoxide in the user's
shell; use absolute paths).

**Standing.** D-216 kept every Appendix C payload column as the design and
left the prototype's shortfalls enumerated in `pending.md`'s first "Not yet
built" bullet. Every item there is a field a site can fill from data it
already holds, once D-249's three rulings landed at `cff996f`:
`TierSignatureMismatch` owns the contract-arity arms, a runtime
`ConformanceFailure` carries no time of its own, and `FaceNameCollision`
carries no provenance. This increment fills the enumeration and retires the
bullet.

**Two stages, two commits.** Stage 1 fills the Stratum A kinds in
`assembly.jl`, `build.jl` and `diagnostics.jl`, and moves the contract-arity
arms. Stage 2 fills the service and runtime kinds, which touches `sim.jl`,
and retires the bullet. Each stage runs the subset the routing table gives
it; stage 2 sits in the table's last row and runs the gate itself.

**Read, all in `docs/design/spec.md`:** §13.2's two rendering rules
(7403–7418: strings never instances, port types the one exception, the
didactic style). Appendix C's preamble (10731–10800: what a column is, the
policies). The columns of the kinds this brief names, at the lines given
per kind below. §8.5's tier paragraph (2308–2330) and its signature-shape
passage (2611–2632), the home of the arity move. §9.5's failure payload
(3576–3587). §6.1's obligation rule (1184–1190). §11.3's frozen roster
(5345–5353). §12.6's legality table (8110–8120). §13.5's two binding sites
(7772–7780). In `docs/design/decisions.md`: **D-249 (9085, the ruling)**,
D-216 (the column-is-the-design rule; grep `### D-216`), D-215
(`InternalInvariant`; grep `### D-215`).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (113–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/leaves.jl` (19), `src/diagnostics.jl` (20),
  `src/declare.jl` (21), `src/assembly.jl` (22), `src/executor.jl` (24),
  `src/build.jl` (25), `src/sim.jl` (28), `src/roster.jl` (33),
  `src/bindings.jl` (34), `src/devices.jl` (35), `src/conditions.jl` (36),
  `src/trim.jl` (37), `test/fixtures.jl` (38), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–111)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module; `_typename` for a user type in a payload.

In `docs/design/pending.md`: the first "Not yet built" bullet, "Kinds
carrying less than their Appendix C payload" (21–41), is the one stage 2
retires. Read it now: it is the enumeration this brief fills, item by item.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, D-249 and this brief disagree, stop and say so in the report
rather than improvising. A column asks for a datum; this brief says which
value fills it and from where. Where a site does not hold the value the
brief claims, report it rather than fabricating a lookup.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

**Shape rules for every fill.** A new payload field is typed as narrowly as
its value allows (`Vector{Symbol}` for a name list, `String` for a spelled
type). A field naming a *user* type is a `String` through `_typename`. A
port type stays a type (§13.2's one exception) and renders as the
neighbouring kinds render theirs. A new field with no natural default has no
default, so no site can omit it. The message renders every new field in
the didactic style, through the existing helpers (`_at_path`, `_faceset`,
`_namelist`, `_plainlist`). The build tests assert kind and payload,
including the field this increment adds; message text is asserted only in
`test_diagnostics.jl`'s rendering testset, where every kind this brief
touches already has a construction to update.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Grep every new fixture name across `test/` and
`src/` before defining it: a same-named type silently rebinds a fixture
module on 1.13.

---

## Stage 1 — the Stratum A kinds and the arity move

Routed subset: `declare assembly build diagnostics leaves events`
(row one plus `events`, whose tests read the tier classifier and the event
declarations).

Construction sites, one per kind unless stated (line numbers at `cff996f`):

| kind | column | site |
|---|---|---|
| `ContainerMixed` | spec 10864 | `assembly.jl:133` |
| `UnconnectedInput` | 10814 | `assembly.jl:802` |
| `ClassUnreadable` | 10859 | `assembly.jl:48` |
| `TierUnreadable` | 10909 | `build.jl:204` |
| `TransparentContainerUnknown` | 10906 | `assembly.jl:182` |
| `TwoProducers` | 10817 | `assembly.jl:950` |
| `EventHalfMissing` | 10851 | `build.jl:728, 734` |
| `AbstractAtRoot` | 10834 | `build.jl:824` |
| `ProducedByTwoStages` | 10930 | `build.jl:1076` |
| `DeclarationOnWrongTier` / `TierSignatureMismatch` | 10869, 10876 | `build.jl:217` (the vote loop) |

### The fills

- **`ContainerMixed`** gains `keys::Vector{Any}`, the keys or indices of the
  non-component elements in element order, beside the existing `types`
  (which stays the unique non-component types). `ContainerNested` one
  screen down has the same pair; match its comment and its message shape
  ("at {k1, k2} (Int, Float64)").
- **`UnconnectedInput`** gains `declared::Any`, the entry type at nominal
  `Float64` as `_contract(input_types, c)` reads it, and `level::String`,
  the obligation chain's last level: the shortest `path` among `w.routes`
  rows whose `consumers` contain `(path, face)`, or the leaf's own path when
  no route names it (`w.routes` records only routes with consumers, so an
  entry nobody handed up has no row). The message names the declared type
  as `WireTypeMismatch`'s does, and when `level != path` adds that the input
  was handed up to `level` and fed by nothing there. Tests: one fixture
  where an `input_connections` chain stops at an intermediate assembly
  asserts `level` as that assembly's path; one primitive with no route
  asserts `level == path`; both assert `declared`. Build such a fixture only
  if `test_assembly.jl`'s existing `UnconnectedInput` fixtures give you
  neither.
- **`ClassUnreadable`** replaces `families::String` (a pre-rendered list)
  with `type::String` (`_typename(c)`), `found::Vector{Symbol}` (the
  `DECLARATION_FAMILY` names `c` declares, in family order; extend
  `leaf_declarations`'s per-name reading with `_declares` for the five
  non-leaf names, in a helper beside it) and the two family lists
  `assembly_family::Vector{Symbol}` (`[:child_connections]`) and
  `leaf_family::Vector{Symbol}`. Turn the `LEAF_FAMILY` string constant into
  a `Symbol` tuple and render the message's list from it with `_namelist`.
  `holds_components` stays. The message names the type, both lists and,
  when `found` is non-empty, what the component does declare.
- **`TierUnreadable`** gains `type::String` (`_typename(c)`) and
  `family::Vector{Symbol}`, the tier-announcing family: the names
  `classify_tier`'s vote loop reads, as a constant `TIER_FAMILY` beside it,
  in vote order. The message lists the family.
- **`TransparentContainerUnknown`** gains `candidates::Vector{Symbol}`, the
  type's container fields (`fieldnames(typeof(c))` filtered by
  `_is_container` on the value). The message lists them, "none" when empty.
- **`TwoProducers`** gains `incumbent_producer::String` and
  `producer::String`, the two producer terminals spelled: `` "`path`.port" ``
  for a component terminal, `` "root input `face`" `` for `("", face)`. Fill
  from `w.feeds[consumer]` and the `producer` argument. The provenance
  strings stay; the message adds the two terminals.
- **`EventHalfMissing.found`** becomes a `String` through `_typename`, at
  both sites (the component type, or the entry's type). Every test
  asserting `found` against a type asserts the string.
- **`AbstractAtRoot`** keeps its payload (abstract *port* entries, §13.2's
  exception). Its message renders each entry through `_typename` so a user
  abstract type prints unqualified. Nothing else moves.
- **`ProducedByTwoStages`** gains `producers::Vector{Symbol}`, parallel to
  `ports`: each port's stage-1 producer, `:output_state` when the port is in
  `s1`, `:auto_publication` when it is in `published[ci]`. The second
  producer is `output_direct` at this site, always; the message says so per
  port. Keep `ports`.

### The arity move (D-249)

In `classify_tier`'s disagreement loop (`build.jl:214–220`), a vote named
`:output_types` or `:input_types` that disagrees with the announced tier
reports

```julia
TierSignatureMismatch(path = path, declaration = name, tier = Symbol(tier_word(t)),
                      reason = :arity, found = _form(vt), mandated = _form(t))
```

with `_form(CONTINUOUS) = :two_argument` and `_form(DISCRETE) = :plain`.
Every other name (`init_workspace` included) keeps
`DeclarationOnWrongTier(reason = :tier_form)`. On a stateless leaf
`output_types` is the decider and casts no disagreeing vote, so only
`input_types` reaches the new arm there, which is §6.1's "either
violation"; a leaf declaring `output_types` in both arities reports the
second form against the first.

`TierSignatureMismatch` changes accordingly: `tier` is `:continuous |
:discrete`; `reason` is `:bound | :arity`; `found` and `mandated` hold a
bound on the `:bound` arm and a form symbol on the `:arity` arm; drop the
comment saying the arity arms ride elsewhere, and reword the docstring
("here the bound arm" is no longer true). The message gains an `:arity`
arm in the didactic style, naming the form found, the tier the leaf's
store and update law announce, and the form that tier mandates, spelled as
§8.5 spells them (`(::C, ::Type{T}) where {T <: Real}` / `(::C)`).
`DeclarationOnWrongTier`'s `:tier_form` arm stays as it is.

Tests: split the loop at `test_build.jl:1203–1211`. `WrongArity` and
`BothArities` (offender `output_types`) now assert `TierSignatureMismatch`
with `reason === :arity`, `declaration`, `found` and `mandated`;
`BothUpdates` and `ModesOnDiscrete` stay `DeclarationOnWrongTier`. Check
`test_events.jl:94` and every other `DeclarationOnWrongTier` assertion for
a contract-arity fixture. Add an `:arity` construction to the rendering
testset.

### Register

`implementation.md`'s `build.jl` row says "the contract-bound check
(`TierSignatureMismatch`'s bound arm)"; make it the contract-form check,
the arity arm in the vote loop and the bound arm in the wire pass. No
other row changes in this stage.

---

## Stage 2 — the service and runtime kinds, and the bullet

The gate (`sim.jl` is in the routing table's last row). Baseline: stage 1's
commit.

| kind | column | sites |
|---|---|---|
| `StopFaceInvalid` | spec 10973 | `sim.jl:217–241` (the pass), `160`, `247–252`, `791`, `916` |
| `AttachUnknownFace` | 10984 | `roster.jl:201–212`, called at `sim.jl:1322` |
| `ReadBindingUnresolved` | 11010 | `bindings.jl:138–199`, called at `sim.jl:1330` |
| `ServiceLifecycle` | 10969 | `conditions.jl:832`, `devices.jl:136–141`, `sim.jl:326–328, 645–646, 760–761`, `trim.jl:387–388` |
| `ConformanceFailure` | 10944 | `build.jl:1158–1196` (the handler probe), `executor.jl:355–360` (the latch), `leaves.jl:329–358`, `executor.jl:373–393` |

### The fills

- **`StopFaceInvalid`** gains `site::Symbol`, `:constructor | :run! |
  :replay!`, with no default. `_stop_faces(layout, stop_on, diags; site)`
  takes it and the two-argument wrapper forwards it; the constructor passes
  `:constructor`, `run!` `:run!`, `replay!` `:replay!`. The message opens
  with the site ("the constructor's `stop_on`", "`run!`'s `stop_on`").
  Tests: `test_lifecycle.jl`'s stop-face testset asserts `site` at the
  constructor and at `run!`; assert `replay!` too if a trace is in hand
  there, and say in the report if it is not.
- **`AttachUnknownFace`** gains `device::String`, `_typename(dev)`, beside
  the existing `binding`; `_claim` takes the spelling as an argument.
  **`ReadBindingUnresolved`** gains `device::String` the same way, through
  `_compile_gather` and every `_resolve_read` method, and its `binding`
  moves from `string(T)` to `_typename(T)` (the printed-form caveat). Leave
  `BindingContractMismatch`'s `string(T)` alone and name it in the report.
  Messages name the device and the binding. Tests: `test_roster.jl` and
  `test_bindings.jl` assert `device` on their existing refusals.
- **`ServiceLifecycle.legal`** loses its default and every site fills it:
  `_assert_advanceable` `[:initialized]`; `assert_stopped`
  `[:built, :initialized, :stopped, :errored]`; `assert_configurable`
  `[:built, :initialized, :stopped]`; `init!`, `replay!` and `trim!`
  `[:built, :initialized, :stopped]`; `capture` as today. These are §12.6's
  table and §11.3's sentence; if a site's own admission test disagrees with
  the list above, the site is right and the report says so. Every `message`
  arm keeps its sentence. Tests: each gate function's existing refusal
  testset asserts `legal` once.
- **`ConformanceFailure`** gains `event::Union{Nothing,Symbol} = nothing`,
  the event name on a handler's occurrence, at both stages. At the probe,
  `_check_handler` sets `what = "handler"` and `event = name` on every
  `ConformanceFailure` it constructs, and `_check_state_write` gains a
  keyword `event = nothing` it forwards into each of its own; the renderer
  composes "event `snap`'s handler" from the two whenever `event` is set,
  so the rendered text is unchanged. At run time, `EventEntry` gains
  `event::Symbol` (filled at `build.jl:1541` from the event's name), and
  `flatten_state!` and `_merge_modes!` gain a trailing
  `event::Union{Nothing,Symbol}` argument that every caller passes as
  `nothing` except `_latch!`, which passes `e.event`; their throws fill it.
  `scatter_group!` is untouched (no handler reaches it). Tests:
  `test_events.jl` asserts `event` on a handler probe failure;
  `test_failures.jl` asserts it on a `StepError{ConformanceFailure}` raised
  from a handler, adding the fixture if none of its nine sites is one.

### Register

Retire `pending.md`'s bullet whole: every item of its enumeration is now
filled or ruled (D-249). The `executor.jl` row of `implementation.md`
says entries carry the component's path for the write's diagnostic; add
that an event entry carries its event name too. No other row changes.

---

## Report

For each stage, in the handoff: the commit hash; per kind, the fields
added and the site filled; the fixtures added, if any, with their names;
the routed run (stage 1) or the gate (stage 2), pass or fail, with the
output on failure; every place the brief's claim about a site was wrong
(a value not in hand, a line number off, a test the brief did not
foresee), and what you did instead; and any deviation from the spec you
chose or noticed, stated as such.
