# Increment 43 — the auto-publishing removal (§5.3, §8.3, §9.1, Appendix C, D-252)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `2a909ed` plus the commit that adds this brief. Never `cd` elsewhere
(`cd` is aliased to zoxide in the user's shell; use absolute paths).

**Standing.** D-252 removed the framework's third port class. A declared
output is produced by stage 1 or by stage 2 and by nothing else; a component
exposes a state or mode field by returning it from `output_state`; a declared
output no stage produces is `DeclaredNotProduced` at every tier. The spec says
this since `5502e1a`. The code still auto-publishes: `auto_published` in
`build.jl`, the `published` vector on `Activation`, `PublishEntry` in
`executor.jl`, the `published` argument threaded through Stratum B and C and
the tracer, and `compile`'s key slicing. This increment is step 2 of
`roadmap_pipeline_redesign.md`, item 11 of `notes_pipeline_redesign.md`.

**The pre-flight probe** (2026-09-18, the roadmap's table): nine fixture
types rely on publication, all in `test/fixtures.jl`, 18 use sites outside
it. Six were written for publication, three carry an unrelated property.
The stage-1 return wins over publication in the current classifier
(`build.jl:384`, "stage 1 returned it: the stage wins"), which is what lets
the sweep land first, green, under the machinery it retires.

**Two stages, two commits, in this order.**

- **Stage 1, the sweep**, `test/` only. Every fixture that keeps a test gains
  its `output_state` return; the ones the refusal test needs unreturned are
  renamed to say so; the testsets are rewritten to assertions that hold both
  under the current framework and after stage 2. Green at commit.
- **Stage 2, the framework.** The machinery goes, `DeclaredNotProduced`'s
  message changes, the refusal testset lands, and the registers conform.

Both stages sit in the routing table's last row (the fixtures change in
stage 1; `diagnostics.jl` beyond a new kind in stage 2), so each runs the gate
itself.

**Read, in `docs/design/spec.md`:** §5.3's stage roles, 727–797, the rule at
771–775. §8.3, 2351–2405, its conformance bullet 2376–2391. §9.1's
Stratum B, 3091–3125. Appendix C's rows for `ProducedByTwoStages` (11181),
`DeclaredNotProduced` (11184–11189) and `ConformanceFailure` (11197). In
`docs/design/decisions.md`: **D-252 (9264–9307)**, the ruling and its
rationale.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (113–164)**: the routed subset, the flags, the
  gate. It is the one home of test policy; this brief does not restate it.
- The file-table rows for `src/diagnostics.jl` (20), `src/executor.jl`
  (24), `src/build.jl` (25), `src/tracer.jl` (26), `test/fixtures.jl` (38),
  `test/imports.jl` (39).
- **"Authoring caveats" in full (61–111)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–41), the
umbrella for increments 43–48. Its port-model sentence is what stage 2
amends.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, D-252 and this brief disagree, stop and say so in the report
rather than improvising. Where a site does not hold what the brief claims,
report it rather than inventing a substitute.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Never run the suite in the background. The build
tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset.

## Stage 1 — the sweep

Files: `test/fixtures.jl`, `test/test_build.jl`, `test/test_continuous.jl`,
`test/test_discrete.jl`, `test/test_events.jl`, `test/test_executor.jl`.
Nothing under `src/` changes. `test/imports.jl` keeps `PublishEntry` until
stage 2 deletes the type.

Every new fixture name below was grepped across `test/` and `src/` on
2026-09-18 and is free: `VectorPlant`, `vector_feedback_model`,
`UnreturnedCounter`, `UnreturnedMode`. Grep them again before defining
them: a same-named type silently rebinds a fixture module on 1.13.

### The fixtures

The section `# --- §5.3's auto-published ports` (`fixtures.jl:35–38`)
becomes `# --- §5.3's stage-1 return of exposed state` with a header
comment saying what the group now is: components exposing a state or mode
field by returning it from `output_state`, and the refusal fixtures that
declare one and return nothing (D-252). Each docstring is rewritten to the
new fact; none may say "published" of a port.

| fixture | change | why |
| --- | --- | --- |
| `Motor` (47) | gains `output_state(::Motor, (; x, m)) = (ω = x.ω, running = m.running)` | §8.2's worked engine; the runtime closed form in `test_continuous.jl` reads it |
| `AutoPlant` (68) | renamed `VectorPlant`; gains `output_state(::VectorPlant, (; x)) = (q = x.q,)` | a plant exposing its whole state vector as one `SVector` stage-1 port; the loop through it stays legal by the same rule as `Plant`'s `y` |
| `StateFeedback` (88) | docstring only: "on the plant's state-vector port" | consumer of the above |
| `auto_feedback_model` (863) | renamed `vector_feedback_model`; docstring rewritten: the loop closes through a stage-1 port, an `SVector` one | its two tests keep the comparison with `feedback_model` |
| `AutoCounter` (98) | renamed `UnreturnedCounter`; body unchanged | stage 2's refusal fixture on the `s` home |
| `PinnedState` (109) | gains `output_state(::PinnedState, (; x)) = (q = x.q,)` | the D-166 refusal now comes from the stage-1 port check |
| `WrongTyped` (116) | unchanged in this stage | stage 2 retires it |
| `Twice` (123) | gains `output_state(::Twice, (; x)) = (q = x.q,)` | two stage writers of one port, §8.3 |
| `TwiceState` (131) | retired | it existed to show "nothing is published" |
| `ModeNamedProduct` (144) | body unchanged; docstring: a stage-2 product named after a mode field, beside a declared state field no stage returns | stage 2's refusal fixture on the `x` home, with a non-empty product list |
| `AutoOverload` (575) | renamed `UnreturnedMode`, its guard and handler `unreturned_mode_guard`/`unreturned_mode_handler`; body otherwise unchanged | stage 2's refusal fixture on the `m` home |
| `auto_overloaded` (588) | retired | its one test moves to `Overload` |
| `GearMode` (1225) | `output_state(::GearMode, (; m)) = (gear = m.gear, y = m.gear === up ? 0.0 : 1.0)` | the enum port is returned |
| `PhaseMode` (1250) | `output_state(::PhaseMode, (; m)) = (phase = m.phase, y = m.phase === :idle ? 0.0 : 1.0)` | the `Symbol` port is returned |

`GearMode`'s docstring (1221–1224) says publication is §7.5's remedy; §7.5
now says the remedy is declaring the mode field public, which the return
delivers. Say that.

### The tests

Verified on 2026-09-18 against the current tree with the returns added
(`probe43.jl`, session scratchpad): `Motor`'s nominal `stage1` is
`(ω = 0.0, running = false)`, its `published` is empty, its products are
`(:ω, :running, :M_shaft)` and its stage-2 hand-down is
`(:x, :m, :u, :y_x, :t)`; `Twice` throws
`ProducedByTwoStages("c", [:q], [:output_state])`; `PinnedState` at `D8` is
one collected `ConformanceFailure` with `what = "output_state"`,
`reason = :field_type`, `shape = :ports`, `field = :q`, `observed = D8`,
`declared = Float64`; `GearMode`'s nominal `stage1` is `(gear = up, y = 0.0)`
and its `D8` keys `(:gear, :y)`.

**`test_build.jl`, `build_auto_publication` (313–390).** Renamed
`build_port_classes`, section header `# --- the two port classes (§5.3,
§8.3, §9.1, D-252)`, the call at 1542 following. Its testsets become:

- *"a state or mode field is exposed by returning it from stage 1 (§5.3,
  D-252)"*: over `fed(Motor(1.0), "M_load")`, `stage1[i]` keys
  `(:ω, :running)`, `published[i] === NamedTuple()`, products keys
  `(:ω, :running, :M_shaft)`, and the hand-down `(:x, :m, :u, :y_x, :t)`.
  The `published` assertion is the one line stage 2 deletes.
- *"a loop closes through a stage-1 port carrying the state vector (§5.3,
  §5.5)"*: `vector_feedback_model()` builds; the same loop through `power`
  is still the cycle, assertions unchanged, `VectorPlant` in the `Group`.
- The `AutoCounter` testset (347–350) retires.
- *"publication is by name and type"* (352–358) stays verbatim this stage;
  stage 2 retires it with `WrongTyped`.
- *"a port is produced by one stage (§8.3)"*: `Twice` throws
  `ProducedByTwoStages`, `d.ports == [:q] && d.producers == [:output_state]`.
  The `TwiceState` half goes.
- The `ModeNamedProduct` testset (369–378) retires.
- *"a pinned declaration of a walking field is refused at the stage-1 port
  check (§9.5, D-166)"*: `build(single(PinnedState()))`, then
  `only(diagnostics(failure(() -> activation(b, D8))))` is a
  `ConformanceFailure` with `what == "output_state"`, `reason === :field_type`,
  `field === :q`, `observed === D8`, `declared === Float64`.

**`test_build.jl`, 1161–1166 and 1179–1181.** *"an enum mode is returned
from stage 1 (§7.5)"*: `b.nominal.stage1[i] === (gear = up, y = 0.0)`,
`keys(activation(b, D8).stage1[i]) === (:gear, :y)`, and the `port` read
unchanged. `PhaseMode`: `b.nominal.stage1[index_of(b.flat, "c")] ===
(phase = :idle, y = 0.0)`, the comment "the mode label is returned (§7.5's
remedy on the idiomatic label)".

**`test_continuous.jl`, `continuous_auto_publication` (60–118).** Renamed
`continuous_state_return`, header `# --- stage-1 returns of store fields at
runtime (§5.3, D-163)`, the call at 122 following. Both testsets keep every
assertion; only the prose changes: the first is *"a stage-1 port returning a
store field carries the store, not an integration (§5.3, D-163)"* and its
comments say boundary zero's `ESTABLISH` round ran `output_state` over the
authored stores; the second is *"a loop closed through a state-vector port
integrates like the scalar one (§5.3)"* over `vector_feedback_model`.

**`test_discrete.jl`, 70–98.** The testset retires whole: its first half
tested publication from `init_s`, its second the absence of a
`PublishEntry` under freezing, which `discrete_frozen_activation` (101–112)
covers by the walked length.

**`test_events.jl`, 292–307.** *"a handler's mode flip reaches its cell
through the next sweep (§5.3, D-154)"* over
`Group((; src = Sawtooth(1.0), mon = Overload(0.315)); wires = ("src/q" =>
"mon/sig",), outputs = ("mon/tripped" => "tripped",))` built inline (it is
`overloaded()` of `test_lifecycle.jl`, which is not a fixture). Assertions
unchanged. The comment says `Overload` returns `tripped` from stage 1, the
table is written by sweeps and nothing else, so the handler's round is
followed by a sweep before anything is read.

**`test_executor.jl`, 24–39.** The `Motor` block's claim becomes: a stage-1
return over both homes, `x` and `m`, compiles one `StageEntry` and the
canary holds over it. `count(e -> e isa StageEntry, walk) == 1`; the
`PublishEntry` line goes; the `BLOCKS` loop stays.

### The routed run

The fixtures change, so the table's last row: the gate, under its flags, in
the foreground.

## Stage 2 — the framework

Files: `src/build.jl`, `src/executor.jl`, `src/tracer.jl`,
`src/diagnostics.jl`, `test/imports.jl`, `test/fixtures.jl`,
`test/test_build.jl`, `test/test_diagnostics.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`,
`docs/design/companions/event_visibility_walkthrough.md`.

### `src/build.jl`

- Section `2b. auto-publication` (333–410): `auto_published` and its
  docstring go. `_homes` (340) and `_state_fields` (352) stay, being
  `DeclaredNotProduced`'s helpers at 1010–1011; `_home_of` (344) has no
  caller left and goes. The section header becomes what remains, the store
  homes for `DeclaredNotProduced`'s list (§7.1, §8.3), cited D-252, not
  D-016 or D-169.
- `schedule_stage2` (420–458): the `published` parameter and the
  `haskey(published[pi], pport)` disjunct go; the docstring's "or
  auto-published" clause goes, the payoff sentence now naming stage-1 ports
  alone. `_cycle_diagnostics` (469–500) loses the parameter and its
  forwarding to `_classify`.
- `Activation` (659–665): the `published` field goes.
- `_stratum_c` (901–933): the `pubdiags`/`published` block (913–925) goes;
  `schedule_stage2`, `probe_stage2` and the constructor lose the argument.
- `probe_stage2` (963–1015): the parameter goes; the ordering invariant
  reads `keys(products[ci]) == (keys(stage1[ci])…, keys(y2)…)` and
  `products` starts as `copy(stage1)` in the same `NamedTuple` vector shape;
  the `y2keys` comment follows.
- `_probe_direct!` (1063–1100): the parameter goes; `twice` is
  `intersect(keys(s1), keys(y2))`; `producers` is `fill(:output_state,
  length(twice))`; the comment says stage-1 position is the stage's;
  `products[ci] = merge(s1, _embed_ports(y2, d.outs, T))`.
- `compile` (1482–1500): `y2keys` slices from
  `length(keys(act.stage1[ci]))+1`; the `PublishEntry` loop (1486–1500) and
  its comment go.
- Grep `published` across `src/build.jl` after; every hit left must be
  `publish!`, `Published` or a snapshot sentence, none of them this
  construct.

### `src/executor.jl`

`PublishEntry` (86–98), its outer constructor (119–121) and its `run!`
(192–201) go. The header comment (33–41) counts three kinds. The
`:auto_publish` site label leaves with the `run!`; grep it across `src/`
after, expecting nothing.

### `src/tracer.jl`

`_classify` (271–283) loses the `published` parameter; `products` starts
as `copy(stage1)`; `_probe_direct!` is called without it.

### `src/diagnostics.jl`

- `DeclaredNotProduced` (871–884): the payload is unchanged, path, `ports`,
  `products`, `state_fields`. The message loses the "a store field of that
  name and type carries them" remedy and gains D-252's: declared port(s)
  produced by no stage; `output_state` returns them, or `output_types`
  drops them; the stages return `…`; the state fields are `…` (§5.3,
  §8.3). The docstring at 871 stays.
- `ProducedByTwoStages`'s message (861–868): the `:auto_publication` arm
  goes; the producer renders as `` `$q` `` always. The `producers` field
  stays: Appendix C names both stage names.
- `ConformanceFailure`'s message (972–981): the comment and the
  `d.what == "auto-publication"` branch go; the `:ports` arm reads
  "returns". The `activation` field stays, three other sites set it
  (`build.jl:310`, `1129`, `1649`).

### `test/`

- `imports.jl:24`: drop `PublishEntry`.
- `fixtures.jl`: `WrongTyped` (115–120) retires; the group's header comment
  drops any mention of a type test.
- `test_build.jl`, `build_port_classes`: delete the
  `published[i] === NamedTuple()` line; retire the *"publication is by name
  and type"* testset; add *"a declared port no stage returns is refused at
  every home (§8.3, D-252)"*, one `only(diagnostics(failure(() ->
  build(single(…)))))` per fixture, asserting kind and the three payload
  fields:

  | fixture | `ports` | `products` | `state_fields` |
  | --- | --- | --- | --- |
  | `UnreturnedCounter()` | `[:n]` | `Symbol[]` | `[:n]` |
  | `UnreturnedMode(0.315)` | `[:tripped]` | `Symbol[]` | `[:tripped]` |
  | `ModeNamedProduct()` | `[:q]` | `[:flag]` | `[:q, :flag]` |

  The `x`-before-`m` order of the last row is `_state_fields`' merge order,
  verified 2026-09-18. `Unproduced` (test_build.jl:16, no store) keeps its
  assertion in `build_probe_refusals` at 59–61.
- `test_diagnostics.jl`, the rendering testset: the `DeclaredNotProduced`
  construction at 358 gets the new message; the `ConformanceFailure`
  construction at 371 becomes `what = "output_state"` unless an identical
  `:ports` construction already exists there, in which case it is dropped;
  the `ProducedByTwoStages` construction at 356 asserts the one-arm
  rendering.

### The registers

- `implementation.md` row 24 (`src/executor.jl`): drop the `PublishEntry`
  clause. Row 25 (`src/build.jl`): drop "`auto_published` and the published
  set on the `Activation` (§5.3, D-169)", and D-016 and D-169 from its
  decision column; add D-252. Row 26 (`src/tracer.jl`) is unchanged.
- `pending.md`, the umbrella bullet: the port-model sentence gains
  "delivered by increment 43", so the bullet stays true. Run
  `docs/design/tools/check_refs.jl` and `check_rows.jl` after.
- `companions/event_visibility_walkthrough.md:71`: "auto-publication is a
  stage-1 sweep act like any other" becomes "the next sweep's
  `output_state` reads those stores like any other stage-1 act". A
  companion explains; the spec wins over it.

### The routed run

`diagnostics.jl` beyond a new kind: the gate, under its flags, in the
foreground.

## Report

For each stage, in the handoff: the commit hash; per file, what changed;
the fixtures renamed, retired or extended, by name; the gate, pass or fail,
with the output on failure; every place the brief's claim about a site was
wrong (a line number off, a value not in hand, a test the brief did not
foresee), and what you did instead; and any deviation from the spec you
chose or noticed, stated as such.
