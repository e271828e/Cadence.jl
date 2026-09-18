# Increment 44 — the build-side types (§9.1, §9.2, §9.4, §13.2, Appendix C, D-250, D-253, D-259)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `3815392` plus the commit that adds this brief.
Never `cd` elsewhere (`cd` is aliased to zoxide in the user's shell; use
absolute paths).

**Standing.** D-253 named the build's products and D-259 named its steps.
The structure step returns a `Structure`; the nominal evaluation is a
function of it returning a `Dataflow`, an `Events` and the nominal
`Activation`; activation at another scalar takes those and completes an
`Activation{T}`; the `Build` is the three products plus one activation
dictionary keyed by scalar type. Structural
consumers read the products, not an activation. D-250 put the build's
warnings on the `Build`, reached through a scoped channel the build binds.
The spec says all of this since `5502e1a`. The code still has `Flat` with
`tiers` alongside it on the `Build`, no product of the nominal evaluation beyond an
`order` vector and a `policies` vector, a `nominal` field beside a `cache`,
consumers reading name lists off the `Float64` activation, and no warnings
anywhere on the build side. This increment is step 3 of
`roadmap_pipeline_redesign.md`, items 12–17 of `notes_pipeline_redesign.md`
and the build side of items 2–5.

**The pre-flight probe** (2026-09-18, `probe44.jl` in the session
scratchpad, against `2938a02`): a stage-2 return in the reverse of the
declared port order still writes each cell by name (`a = 3.0, b = 2.0` for a
return of `(b = 2u, a = 3u)` over `(a, b)` declared), and a stage-1 return's
product keys follow the *return* order, `(:q, :p)` against `(:p, :q)`
declared. `_check_ports` (`build.jl`) checks a return as a subset of the
declaration, in any order. Those two facts fix the `Dataflow` name lists
below. `Base.ScopedValues` binds and unbinds as expected on 1.13.

**Four stages, four commits, in this order.** The roadmap lists five; its
stages 2 and 3 are merged here because a `Dataflow` computed and then
flattened back into an `order` field would be an interim state with no
reader, and the two together are the size of stage 1.

- **Stage 1, `Structure` replaces `Flat`.** The tiers move in, the two new
  fields land, and the rename runs through every reader.
- **Stage 2, the nominal evaluation and the `Build` recomposition.**
  `Dataflow`, `Events`, `_nominal`, `_activate`, the one activation
  dictionary.
- **Stage 3, the consumers.** `compile`, the catch site's species, the
  readers and trim take their name lists from the products.
- **Stage 4, the channel.** The scoped binding, the append helper,
  `warnings(::Build)`, the once-per-warning log, the carrier's rendering.

Every stage touches `sim.jl` or `diagnostics.jl` beyond a new kind, so every
stage sits in the routing table's last row and runs the gate itself, under
its flags, in the foreground. `implementation.md`'s "Running the suite"
(113–164) is the one home of test policy; this brief does not restate it.

**Read, in `docs/design/spec.md`:** §9.1 whole, 2991–3240, its step table at
the head, then the structure step's return, the nominal evaluation,
activation and "Where a build warning lives". §9.2, 3241–3272, and
`warnings(x)` at 3382–3386. §9.4's caching paragraphs, 3546–3574. §13.2's
rule and the build paragraph, 7616–7628. §13.4's cursor sentence naming the
`Dataflow`, 7788. Appendix C's `logged` policy, 11040–11046, and the
collected-warning slot, 11059–11062. The glossary entries `activation`
(11868), `Build` (11886), `Dataflow` (11897), `Events` (11909), `Structure`
(11976), `artifact` (12394). In `docs/design/decisions.md`: **D-250
(9157–9217)**, **D-253 (9311–9375)** with its amended fourth bullet, and **D-259
(9621–9676)**, the step names.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (113–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/assembly.jl` (22),
  `src/executor.jl` (24), `src/build.jl` (25), `src/tracer.jl` (26),
  `src/readers.jl` (27), `src/sim.jl` (28), `src/trace.jl` (32),
  `src/conditions.jl` (36), `src/trim.jl` (37), `test/fixtures.jl` (38),
  `test/imports.jl` (39).
- **"Authoring caveats" in full (61–111)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–39), the
umbrella for increments 43–48. Its build-side-types sentence and its
warning-homes sentence are what stage 4 amends.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the two decisions and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Never run the suite in the background. The build
tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset. A REPL check of a fixture defined
in a `test_*.jl` file loads `test/repl.jl`, `using Test` and `test/utils.jl`
(`single`, `fed`, `failure`), then reproduces the fixture.

**The nominal evaluation's return.** D-253 as first written had the
nominal evaluation return the `Float64` stage-1 products and a later step
complete the nominal activation from them. `Events` is the evaluation's
last product and its probe needs every component's complete nominal product
and the layout (`probe_events`, `build.jl:1062`), so the evaluation runs the
whole nominal probe chain regardless, and a second run at `Float64` would be
the separate pass §9.1 forbids. D-259 and D-253's amended fourth bullet say
what stage 2 builds: the nominal evaluation returns the dataflow, the events
and the nominal activation, assembled from its own probe chain; activation
at every other scalar takes the structure, the dataflow and the nominal
activation as the carry for frozen components. The code's names are
`_nominal` and `_activate`; `_stratum_c` goes with stage 2 and
`build_stratum_a` with stage 1, the two identifiers the vocabulary sweep
(D-259) left for this increment.

## Stage 1 — `Structure` replaces `Flat`

Files: `src/assembly.jl`, `src/build.jl`, `src/tracer.jl`, `src/readers.jl`,
`src/conditions.jl`, `src/trim.jl`, `src/sim.jl`, `src/trace.jl`,
`test/test_assembly.jl`, `test/test_build.jl`, `test/test_conditions.jl`,
`test/test_discrete.jl`, `test/test_failures.jl`, `test/test_localization.jl`,
`test/test_readers.jl`, `test/imports.jl`, `docs/design/implementation.md`.

### The type

`Flat` (`assembly.jl:679–691`) becomes `Structure`, immutable, with these
fields in this order:

| field | today | change |
| --- | --- | --- |
| `root::Any` | on `Flat` | unchanged |
| `paths::Vector{String}` | on `Flat` | unchanged |
| `comps::Vector{Any}` | on `Flat` | unchanged |
| `tiers::Vector{Tier}` | `Build.tiers` | moves in: per component, beside `paths` |
| `conns`, `root_inputs`, `root_types`, `in_faces`, `out_faces` | on `Flat` | unchanged |
| `triples`, `anchors`, `aprov` | on `Flat` | unchanged |
| `provenance::Vector{Vector{@NamedTuple{scope::String, key::Symbol, entry::Union{Relative,Absolute}}}}` | — | new: per component, the `sample_times` links met on the way down, outermost first |
| `scopes::Vector{@NamedTuple{path::String, key::Symbol, triple::NTuple{3,Int}}}` | — | new: one row per assembly an explicit `sample_times` key names, in walk order |

The docstring (670–678) is rewritten for the artifact: the structure step's product,
everything the instance alone fixes, nothing in it depending on a scalar
type (§9.1, D-253); keep its sentences on the two-sided face table and the
retained root. `root_types` keeps today's practice: the wire pass
(`_check_wires`, `build.jl:723`) fills the vector before the step's
second barrier, and the artifact is complete at the barrier.

A link is `(scope = the declaring assembly's path, key = the key as
`_rate_entry` returned it, entry = the `Relative` or `Absolute` value)`. A
component under no explicit key anywhere has an empty chain. The `Group`
sugar `(children = Relative(2),)` links with `key = :children`. Over the
`MultiRate` fixture (`fixtures.jl:1042`, the §9.2 example), the expected
values are:

| component | `triples` | `provenance` |
| --- | --- | --- |
| `fcs/inner` | `(0, 1, 0)` | `[("", :fcs, Relative(1)), ("fcs", :inner, Relative(1))]` |
| `fcs/outer` | `(0, 5, 2)` | `[("", :fcs, Relative(1)), ("fcs", :outer, Relative(5, 2))]` |
| `gnss` | `(1, 1, 0)` | `[("", :gnss, Absolute(Hz(50)))]` |

and `scopes == [(path = "fcs", key = :fcs, triple = (0, 1, 0))]`. Verify the
triples against a REPL before asserting them; the chain values follow from
the fold's rules (`assembly.jl:722–730`).

### The walk

`Walk` (703–720) stops owning a `Flat`. It owns the accumulators as its own
fields: `paths`, `comps`, `tiers::Vector{Union{Nothing,Tier}}` (as today,
`nothing` for a recorded failure), `root_inputs`, `root_types`,
`out_faces`, `triples`, `anchors`, `aprov`, `provenance`, `scopes`, beside
`feeds`, `claims` and `routes`. Every `w.flat.X` in `assembly.jl` becomes
`w.X` (21 hits, `out_faces` among them at 607–608 and 979). `wire!` (859–871)
derives `conns` and `in_faces` as today and returns the `Structure`, with
`tiers` narrowed by `Vector{Tier}(w.tiers)` there rather than in `build`
(`build.jl:664`); the walk is clean at that point, so no `nothing` remains.
`index_of` (693) takes a `Structure`.

Recording the two new fields: `_child_scope` (786–800) returns the link
beside the triple, `nothing` for an unlisted child. `_walk!` (873) takes the
chain of the links above it and its own link; the primitive branch pushes
the chain extended by its own link into `provenance`; the assembly branch
pushes `(path, link.key, scope)` into `scopes` when its own link is not
`nothing`, and recurses with the extended chain. The loop at 925–933 passes
what `_child_scope` returned. The predicate for a scope row is the link, not
`_walk!`'s return value: that value is `nothing` for an assembly and for a
primitive whose store form failed (903).

### The readers

Mechanical, and the whole list:

- `build.jl`: the 15 `::Flat` annotations, `_check_event_declarations` (675),
  `_check_wires` (723; the `tiers` argument goes, read off the structure),
  `build` (646–670: `s = wire!(w)`, the `tiers` local goes, `Build(s, …)`),
  `schedule_stage2` (360), `_cycle_diagnostics` (407), `cell_layout` (504),
  `_stratum_c` (838), `_mstores` (860), `_workspaces` (867), `probe_stage1`
  (256), `probe_stage2` (893), `_probe_direct!` (992), `probe_events` (1062),
  `bind_schedule` (1177: `b.flat.*` and `b.tiers` become `b.structure.*`),
  `compile` (1347–1349). `_frozen(tiers, ci, T)` keeps its signature and is
  passed `s.tiers`. Every function that took `flat` and `tiers` as two
  arguments takes the structure alone.
- `Build` (615–623): the `tiers` field goes; `flat` becomes `structure`.
  The docstring says "structure" where it says "flat"; the rest of its
  rewrite is stage 2's.
- `tracer.jl`: the 4 `::Flat` annotations and the `tiers` parameter of
  `_trace_direct` (183), `_trace_sampled` (211), `_seed` (238) and
  `_classify` (271).
- `readers.jl:258` (`_read_component`), 243, 302–304, 317–319, 335, 347–349,
  358–360; `conditions.jl` 168–203 (the `flat::Flat` annotations of the
  flattening helpers), 332, 373–374, 420, 434, 506, 834; `trim.jl:407`,
  514–516; `sim.jl` 555, 655–657, 1123, 1145, 1650–1653, 1662;
  `trace.jl:269`. `b.flat` and `sim.build.flat` become `.structure`;
  `b.tiers` and `sim.build.tiers` become `.structure.tiers`.
- `test/`: the `.flat` hits, `.structure` in every one — `test_assembly.jl`
  (21), `test_build.jl` (325, 1150, 1168, 1423 and the `index_of` calls),
  `test_conditions.jl` (273, 442, 485), `test_discrete.jl` (157),
  `test_failures.jl` (124), `test_localization.jl` (158), `test_readers.jl`
  (37, 204). Grep `\.flat\b` across `src/` and `test/` after, expecting
  nothing; grep `Flat\b` likewise, expecting nothing.
- `test/imports.jl`: add `Structure`. `Relative`, `Absolute`, `Hz` are on the
  list already.
- `test_build.jl`: `build_stratum_a` (1389, called at 1539) becomes
  `build_barrier`, the identifier the vocabulary sweep left for this
  increment; its section header and testset name already say "the
  structure step".

### The tests

In `test_assembly.jl`, beside the sample-time fold's testsets (grep
`Absolute(` there and in `test_discrete.jl:202–220` for the models in use),
one new testset, *"the structure records each component's rate provenance
and each keyed scope's triple (§9.1, §9.2, D-253)"*, over
`build(MultiRate())` as `test_discrete.jl:229` builds it: the three
`provenance` chains and the one `scopes` row of the table above, `triples`
beside them, `tiers` of length `length(paths)` with `gnss` and the two `fcs`
children `DISCRETE`, and the fourth component, `src` (a `Ramp`, continuous,
under no key), carrying an empty chain and no scope row: an unlisted child
continues at the enclosing scope and records nothing.

### The registers

`implementation.md` row 22 (`src/assembly.jl`): `Flat` becomes `Structure`
throughout; the parenthesis "`Walk` owning the `Flat` it builds" becomes
"`Walk` accumulating what `wire!` returns as the `Structure`, the tiers and
the two rate-provenance tables among them"; cite D-253. Rows 25–27, 28, 32,
36, 37: `Flat` becomes `Structure` where named. Run
`docs/design/tools/check_refs.jl` and `check_rows.jl` after.

### The routed run

`sim.jl` is touched: the gate, under its flags, in the foreground.

## Stage 2 — the nominal evaluation and the `Build` recomposition

Files: `src/build.jl`, `src/sim.jl`, `src/executor.jl`, `src/localization.jl`,
`test/test_build.jl`, `test/test_events.jl`, `test/test_localization.jl`,
`test/imports.jl`, `docs/design/implementation.md`.

### The two products

Beside `Activation` (598–603), two immutable types:

```julia
struct Dataflow
    ports::Vector{Vector{Symbol}}    # per component: every declared output port, in `output_types` order
    stage1::Vector{Vector{Symbol}}   # per component: the stage-1 names, in the product's order
    stage2::Vector{Vector{Symbol}}   # per component: the remainder, in `output_types` order
    edges::Vector{Vector{Tuple{Int,Symbol,Symbol}}}   # per consumer: (producer, port, face)
    order::Vector{Int}               # the execution order over component indices
end

struct Events
    policies::Vector{NamedTuple}     # per component: event name => :boundary | :localized
    bundles::Vector{Tuple}           # per component: the event bundle names, `()` where none
end
```

`stage1[ci]` is `collect(keys(stage1_products[ci]))`: the product's order,
because the hand-down bundle `y_x` and `bundle_names`' `stage1_ports` tuple
are built from it (`compile`, 1409 and 1418). `stage2[ci]` is
`filter(∉(stage1[ci]), ports[ci])`, the declared order, which the pre-flight
probe shows is a legal order to address the cells by. `ports[ci]` is
`collect(keys(decls[ci].outs))`. `edges` is `schedule_stage2`'s `edges`
unchanged. `Events.policies` keeps `probe_events`' per-component shape
exactly, so its keys are the event names in declaration order, and
`bundles[ci]` is `event_bundle_names(c)` for a component with events, `()`
otherwise. Docstrings cite §9.1 and D-253: the two are structural,
`T`-independent, and `Events` is separate because it is fixed by a different
input, read after the stage probes.

### The nominal evaluation

`_stratum_c` (838–858) splits in two and goes. `_nominal(s::Structure)` returns
`(Dataflow, Events, Activation{Float64})` and is today's `_stratum_c` at
`Float64` with `carry = nothing`, in this order: declarations at `Float64`,
`_mstores`, `_workspaces`, `probe_stage1`, the dataflow, `cell_layout`,
`probe_stage2` over `dataflow.order`, the nominal `Activation{Float64}`,
then `probe_events` over it, returning `Events`. `schedule_stage2` (360–401)
becomes `_dataflow(s, decls, stage1, mstores) → Dataflow`, its stall path
(`_cycle_diagnostics`, the tracer) unchanged; the section header
`3. the feedthrough graph and the stage-2 schedule` (350) becomes
`3. the nominal evaluation's products` and the docstring says what the artifact carries.
`probe_events` (1062–1090) returns `Events` and takes the structure and the
nominal activation.

`_activate(s::Structure, df::Dataflow, nominal::Activation{Float64}, ::Type{T})`
returns `Activation{T}` for `T !== Float64`: declarations at `T`, `_mstores`,
`_workspaces`, `probe_stage1` with `nominal` as the carry, `cell_layout`,
`probe_stage2` over `df.order` with `nominal` as the carry. The comment at
830–837 is rewritten: the nominal evaluation's run is the nominal
activation, and `_activate` re-runs the typed half at another scalar with
the frozen components' products carried from it.

### The `Build`

```julia
struct Build
    structure::Structure
    dataflow::Dataflow
    events::Events
    activations::Dict{DataType,Any}   # keyed by scalar type, the nominal Float64 entry included
    lock::ReentrantLock               # guards `activations` (§9.4's torn-state guarantee)
    warnings::Vector{Diagnostic}      # D-250's list; empty until stage 4 binds the channel
end
```

`build` (646–670): `df, ev, nominal = _nominal(s)`, then
`Build(s, df, ev, Dict{DataType,Any}(Float64 => nominal), ReentrantLock(),
Diagnostic[])`. `activation` (822–828): the lookup under the lock serves
`Float64` like any other key; on a miss, `_activate(b.structure,
b.dataflow, b.activations[Float64], T)` with that read under the lock too,
then `get!` under the lock as today. The docstring of `Build` (605–614) is
rewritten to §9.2's sentence: structure, dataflow, events, the activations
and `warnings`; the `Build` immutable and backing many deployments; the one
mutable thing the dictionary, whose insertion the lock makes torn-state-free.
`build`'s docstring (637–645) says the structure step and the nominal
evaluation, the nominal activation being the evaluation's.

Readers of the retired fields, the whole list: `compile` 1409 (`b.order` →
`b.dataflow.order`), 1470 (`b.policies[ci][name]` →
`b.events.policies[ci][name]`); `sim.jl:1146` (`sim.build.nominal` →
`activation(sim.build, Float64)`; stage 3 rewrites it again); the comments
at `executor.jl:250` and `localization.jl:4` naming `Build.policies` say
`Events.policies`. Grep `\.nominal\b`, `\.policies\b`, `\.cache\b`,
`\.order\b` across `src/` after; the survivors must be `Events.policies`
reads through `b.events` and `df.order`.

### The tests

- `test_build.jl` 326–331: `b.nominal` becomes `activation(b, Float64)`;
  763, 1139, 1151, 1168 likewise; 1475 becomes
  `activation(b, Float64) === b.activations[Float64]`; 1497 reads
  `haskey(….activations, ProbeDual)`; 1521 asserts
  `length(b.activations) == 2` with a comment that the nominal entry is one
  of them.
- `test_events.jl:112–114` and `test_localization.jl:158`: `.policies` →
  `.events.policies`.
- New, in `build_schedule` (91–116), *"the nominal evaluation's products are names and
  edges (§9.1, D-253)"*: over the model the first testset there already
  builds (read it; it has a stage-1 producer, a stage-2 consumer and one
  wire), assert `ports`, `stage1`, `stage2` per component as the table the
  fixtures' declarations give (compute them in a REPL first), the one edge
  as `(producer index, port, face)` on the consumer's row and empty rows
  elsewhere, and `order` equal to what the testset asserts today. Add a
  component whose `output_state` returns its ports in the reverse of the
  declared order if none is in the file (the pre-flight's `Swap1` sketch:
  `init_x = (p, q)`, `output_state` returning `(q, p)`, declared `(p, q)`),
  asserting `stage1 == [:q, :p]` and `ports == [:p, :q]`: the two orders
  are different on purpose.
- New, in `test_events.jl` beside 112–114, *"the events product carries the
  policies and the bundle names (§9.1, D-253)"*: `b.events.bundles[1]` for
  `fed(Trigger(0.5), "sig")` equals the tuple `Cadence.event_bundle_names`
  returns for it (read the literal in a REPL and assert the literal), and
  `()` for `single(Rotor())`.
- `imports.jl`: add `Dataflow`, `Events`.

### The registers

Row 25 (`src/build.jl`): "the `Build` and its activations" becomes the
nominal evaluation `_nominal` returning `Dataflow`, `Events` and the nominal
activation, `_activate` for every other scalar, the `Build` as
structure, dataflow, events, one activation dictionary and `warnings`, and
`activation` over the dictionary; "Kahn's schedule" becomes "Kahn's
execution order into the `Dataflow`"; cite D-253. Row 24 and row 30 lose
nothing. Run the two tools.

### The routed run

`sim.jl` is touched: the gate, under its flags, in the foreground.

## Stage 3 — the consumers

Files: `src/build.jl`, `src/sim.jl`, `src/readers.jl`, `src/trim.jl`,
`test/test_build.jl`, `docs/design/implementation.md`.

Item 17: readers, trim, the tracer, `compile`'s key slicing and the runtime
field-error species take their name lists from `Structure` and `Dataflow`.
Port and face name lists are the products'; a store field's names stay the
declaration's (`init_x`/`init_s` through `Decls`), since neither product
carries them and the register puts only port and face lists on the
products. Say that in the report if a reader disagrees.

- `compile` (1347–1483): `keys(s1)` and `keys(act.stage1[ci])` (1409, 1418,
  1436) become `b.dataflow.stage1[ci]` (as a tuple where `bundle_names`
  wants one); `y2keys(ci)` (1402, 1424) becomes `b.dataflow.stage2[ci]`;
  `keys(d.outs)` (1437, 1466) becomes `b.dataflow.ports[ci]`;
  `keys(act.products[ci])` in the seed scatter (1390–1394) stays, that loop
  scattering values. The event loop keeps `invoke_declaration(state_events,
  c)` for the guard and handler functions, iterates
  `keys(b.events.policies[ci])`, and takes `bn` from `b.events.bundles[ci]`.
  The ordering-invariant comment in `probe_stage2` (896–899) is rewritten:
  the product is a value table read by name, and no reader slices it.
- `sim.jl` `_species` (1141–1166): `s1` becomes
  `tuple(sim.build.dataflow.stage1[ci]...)`; the `activation(sim.build,
  Float64)` read from stage 2 goes.
- `readers.jl` `_resolve_selector(::GetOutput)` (335–342): the membership
  test and the `:undeclared` candidates read `b.dataflow.ports[ci]`; the
  type for `_check_index` stays `d.outs[s.name]`, a type being C's.
  `test_readers.jl:92` pins the candidates as `[:y, :power]`, the declared
  order, which `ports` keeps.
- `trim.jl` `_establish_frozen!` (512–522): `keys(act.decls[ci].outs)`
  becomes `b.dataflow.ports[ci]`.
- The tracer runs inside the stall path of `_dataflow`, before any
  `Dataflow` exists, and reads the stage-1 products' keys for their values'
  sake (`tracer.jl:198`); nothing changes beyond stage 1's signatures. Say
  so in the report.
- `test_build.jl:331`: the hand-down assertion reads
  `tuple(b.dataflow.stage1[i]...)`.

Row 25: "`compile` → `Executor{T}`" gains "its name lists off the
products"; row 27 (`src/readers.jl`): the port candidates off the
`Dataflow`; row 28 (`src/sim.jl`): the species rule's stage-1 names off the
`Dataflow`; row 37 (`src/trim.jl`): the frozen copy over the `Dataflow`'s
port list. Cite D-253 on each. Run the two tools.

### The routed run

`sim.jl` is touched: the gate, under its flags, in the foreground.

## Stage 4 — the channel

Files: `src/Cadence.jl`, `src/diagnostics.jl`, `src/build.jl`,
`test/test_build.jl`, `test/test_diagnostics.jl`, `test/imports.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

No build-side producer of a warning exists until increment 45
(`EmptyFaceSelection`), so the tests below are synthetic: a test-local kind
and a fixture whose declaration body calls the helper.

### `src/diagnostics.jl`

- The carrier (84–90) gains a second field, `warnings::Vector{Diagnostic}`,
  the outer constructors defaulting it to `Diagnostic[]`. `diagnostics`,
  `diagnostic` and `kinds` are unchanged: a warning joins no throw
  (Appendix C, 11001). The docstring says a barrier's throw carries the
  build's warnings so far beside the collection (§9.1, D-250).
- `showerror` (112–120): both forms append, after their own lines, one line
  per warning, `  KindName: message`, in first-appearance order; the
  collected form's count line becomes `DiagnosticError: N diagnostics, M
  warnings` when `M > 0` (`1 warning` singular), unchanged otherwise.
- Beside `logline` (132): the channel and the helper.

```julia
const BUILD_WARNINGS = ScopedValue{Union{Nothing,Vector{Diagnostic}}}(nothing)

function _warn!(d::Diagnostic)
    severity(d) === :warning || throw(InternalInvariant(…))
    ws = BUILD_WARNINGS[]
    ws === nothing ? (@warn logline(d)) : push!(ws, d)
    nothing
end
```

  The docstring is D-250's third bullet: bound by the build around its
  steps, a helper inside a declaration body appends without knowing the
  build, and the same helper outside any build logs directly. The
  `InternalInvariant` names the kind and says an error-severity kind is
  collected or thrown, never warned.
- `warnings(b::Build) = b.warnings`, with §9.2's sentence, lives in
  `build.jl` beside `activation`. `Simulation`'s method is increment 46's
  (it concatenates two artifacts' lists); do not add it.

`src/Cadence.jl`: `using Base.ScopedValues: ScopedValue, with`.

### `src/build.jl`

`build` binds once around its three steps, the eager activations included:

```julia
ws = Diagnostic[]
b = try
    with(BUILD_WARNINGS => ws) do
        …                       # the steps as today, Build(…, ws) at the end
    end
catch e
    (e isa DiagnosticError && !isempty(ws)) && throw(DiagnosticError(e.carried, ws))
    rethrow()
end
for d in ws
    @warn logline(d)
end
b
```

with an inner constructor call spelled so both carrier policies keep their
parameter (`DiagnosticError{typeof(e.carried)}(e.carried, ws)` or an outer
constructor over `(carried, warnings)`, whichever `diagnostics.jl` defines).
One binding, one list, every step's warnings; a throw of either policy
leaving the build carries the list; a completed build logs each once at
return through the standard backend (§9.1, Appendix C's `logged`). The
comment says why the rewrap is at `build`'s top rather than at each
barrier: the barriers stay ignorant of the channel.

### The tests

At the top level of `test_build.jl`, beside `PinnedGetsDual` (1407), a
test-local warning kind and a fixture:

```julia
struct SyntheticWarning <: Diagnostic
    note::String
end
severity(::SyntheticWarning) = :warning
message(d::SyntheticWarning) = d.note

# An assembly whose declaration body warns through the channel (§9.1, D-250).
struct WarningWires <: AbstractComponent
    c::Gain
end
input_connections(w::WarningWires) = (_warn!(SyntheticWarning("synthetic")); ("in" => "c/in",))
```

Read a `Gain`-wrapping assembly in `fixtures.jl` for the exact declaration
forms (`children`, `input_connections`, `output_connections`) and copy
them; grep `SyntheticWarning` and `WarningWires` across `test/` first.
`severity`, `message`, `Diagnostic`, `input_connections`, `Gain` are on
`imports.jl`'s list; add `_warn!`, `BUILD_WARNINGS`, `warnings`.

New section `# --- the build's warnings (§9.1, §13.2, D-250)`, function
`build_warnings()` called from `test_build()`:

- *"a warning raised inside a declaration body lands on the Build and is
  logged once at return (§9.1, D-250)"*: `b = @test_logs (:warn,
  r"^SyntheticWarning: synthetic") build(WarningWires(Gain(1.0)))`;
  `only(warnings(b)) isa SyntheticWarning`; `only(warnings(b)).note ==
  "synthetic"`; `BUILD_WARNINGS[] === nothing` after.
- *"a step that throws carries its warnings beside the collection
  (§9.1, D-250)"*: a `WarningWires` whose `Gain` input the assembly leaves
  unfed (drop the `input_connections` wire under a second fixture, or wire
  to a face that does not exist); `e = failure(() -> build(…))`;
  `kinds(e) == [UnconnectedInput]` (or the kind the fixture trips; verify
  in a REPL); `length(e.warnings) == 1`; and nothing was logged, asserted
  as `e = @test_logs failure(() -> build(…))` with no records expected,
  which holds because `failure` returns the throw rather than propagating
  it (`utils.jl:37`).
- *"outside a build the helper logs directly (D-250)"*:
  `@test_logs (:warn, r"^SyntheticWarning") _warn!(SyntheticWarning("x"))`.
- *"the helper refuses an error-severity kind"*: `@test_throws
  InternalInvariant _warn!(UnconnectedInput(path = "a", face = :v,
  declared = Float64, level = "a"))`.

`test_diagnostics.jl`'s rendering testset (587): the collected carrier of
596–601 rebuilt with `warnings = [TrimCommitResiduals(residuals = [(:a,
1.0, 0.1)])]`, asserting the count line `"DiagnosticError: 4 diagnostics, 1
warning"` and the last line `startswith("  TrimCommitResiduals: ")`; the
fail-fast carrier with one warning renders its one line and then the
warning's. `diagnostics(e)` and `kinds(e)` unchanged by the warnings.

### The registers

- Row 20 (`src/diagnostics.jl`): the carrier's `warnings` beside `carried`,
  the channel `BUILD_WARNINGS` and `_warn!`; cite D-250. Row 25: `build`
  binding the channel and logging at return, `warnings(::Build)`; cite
  D-250.
- `pending.md`, the umbrella bullet: the build-side-types sentence gains
  "delivered by increment 44"; the warning-homes sentence splits into what
  44 delivered (`warnings` on `Build` and the scoped channel) and what
  stays (`Deployment`'s list, increment 46; `EmptyGreedyClaim` into the
  roster entry's cell, increment 47). Run the two tools.

### The routed run

`diagnostics.jl` beyond a new kind: the gate, under its flags, in the
foreground.

## Report

For each stage, in the handoff: the commit hash; per file, what changed;
the fixtures and kinds added, by name; the gate, pass or fail, with the
output on failure; every place the brief's claim about a site was wrong (a
line number off, a value not in hand, a test the brief did not foresee), and
what you did instead; and any deviation from the spec you chose or noticed,
stated as such.
