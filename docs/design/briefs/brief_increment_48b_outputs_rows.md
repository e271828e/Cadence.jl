# Increment 48b — `Outputs` and `Events` as rows (§9.1, §9.2, D-253, D-257, D-261)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `6cbbaea` plus the commit that adds this brief. Line numbers below
are those of `6cbbaea`. Never `cd` elsewhere (`cd` is aliased to zoxide in
the user's shell; use absolute paths).

**Standing.** D-261's artifact rule (`decisions.md:9783–9807`) was extended
on 2026-09-21, in `6cbbaea`: the nominal evaluation's first product is
`Outputs`, one `ComponentOutputs` per component in walk order with the
execution order beside the rows as component indices; the old `ports` and
`edges` columns were derived facts and went; `Events` is one
`ComponentEvents` per component; `Activation{T}` keeps its columns as
compiled state. The same commit renamed `Dataflow` to `Outputs` throughout
the spec (§9.1's paragraph at 3107–3116, the glossary entry at 12020–12024,
the artifact rosters) and recorded in D-261's supersession paragraph
(`9836–9842`) why the log's D-253 and D-258 keep the old name: the log keeps
the vocabulary of its day (`tools/decisions_style.md`, rule 2). The code
still says `Dataflow`; this increment makes it conform. `pending.md:21–25`
is the bullet it retires. Roadmap step 7b of
`roadmap_pipeline_redesign.md` is written after landing.

**The pre-flight probe** (2026-09-21, greps at `6cbbaea` and one REPL
script over `MultiRate`, `feedback_model`, `fed(Motor(1.0), "M_load")`,
`Sawtooth(1.0)` and `Pendulum()`).

- `Dataflow` (`build.jl:628–634`) holds `ports`, `stage1`, `stage2`,
  `edges` per component and `order`. `Events` (`644–647`) holds
  `policies` and `bundles` per component. Nothing compares either by `==`;
  nothing outside `src/` constructs them.
- Readers of the columns after construction, every one indexed by `ci`:
  `build.jl:1415, 1425, 1429, 1441` (`stage1`), `1429` (`stage2`), `1442,
  1477` (`ports`), `1467` (`policies`, `bundles`); `readers.jl:343`
  (`ports`); `sim.jl:1286` (`stage1`); `trim.jl:519` (`ports`);
  `show.jl:102–106, 115–125` (all of them). `order` is read at
  `build.jl:938, 963` (handed to `probe_stage2`, which walks it at `1024`),
  `1421` and `show.jl:95, 106–107`. `edges` has one reader, `show.jl:105`.
- In `test/`: `test_build.jl:115–141` (the two `Dataflow` testsets), `370,
  375, 1195, 1214` (`stage1[i]`); `test_events.jl:112–114, 121–122`;
  `test_localization.jl:158`; `test_show.jl:38–44, 71–72, 83, 109–131, 163,
  191`. `test/imports.jl:13, 18` list `Dataflow` and `Events`.
- Comments that name the old shape: `build.jl:353–361, 620–626, 636–642,
  650, 691, 920, 951, 1006, 1457–1461`; `readers.jl:296–297`; `show.jl:92,
  97–100, 120–121, 198–199`; `localization.jl:4`; `executor.jl:251`;
  `test_build.jl:92, 111–113`.
- `_cycle_diagnostics` (`build.jl:413`) and the tracer's `_classify`
  (`tracer.jl:272–354`) read the builder's local `edges` column before any
  artifact exists. They are outside this increment.
- `ports == stage1 ∪ stage2` as sets on every fixture; the orders differ:
  `Motor` declares `[:M_shaft, :ω, :running]` and returns `[:ω, :running]`
  from stage 1, so `vcat(stage1, stage2)` is `[:ω, :running, :M_shaft]`,
  which is `keys(act.products[ci])`'s order (`test_build.jl:371`). `Plant`
  gives `[:y, :power]` either way, so `test_readers.jl:92`'s candidates
  assertion holds unchanged.
- The feedthrough derived from `conns` and the producers' `stage2` equals
  the old `edges` column on every fixture. `MultiRate`: walk order `src,
  fcs/inner, fcs/outer, gnss`, `order = [1, 2, 4, 3]`, one edge
  `gnss.out → fcs/outer.in`. `feedback_model`: walk order `plant, ctl, sum`,
  `order = [3, 2, 1]`, edges `sum.e → ctl.e` and `ctl.out → plant.u`
  (`plant.y` is stage 1, so `sum.b` carries none). `Motor`, `Sawtooth`,
  `Pendulum`: one component, no edge.
- `Events`: `Motor` `(start = :boundary,)` with bundle `(:x, :m, :u, :y,
  :t)`; `Sawtooth` `(wrap = :localized,)` with `(:x, :y, :t)`; every
  `MultiRate` and `Pendulum` row empty.
- `EventEntry` (`build.jl:1473`, `executor.jl`) is the executor's compiled
  event record and stays; `ComponentEvents` is the artifact's row.
- `Group` has an `outputs` field and keyword (`assembly.jl:254–273`), an
  assembly's exported faces. Unrelated, and no other `Outputs`,
  `ComponentOutputs` or `ComponentEvents` exists in `src/` or `test/`.

**One stage, one commit.** It touches `build.jl`'s `compile` half, so the
routed subset is all of it, under the sandbox flags. `implementation.md`'s
"Running the suite" (125–178) is the one home of test policy; this brief
does not restate it. The gate is the reviewer's.

**Read, in `docs/design/spec.md`:** §9.1's opening table and the nominal
evaluation, 3004–3010 and 3105–3140; §9.2's rendering paragraph,
3320–3332; the glossary entries for `Outputs`, `Events` and `Build`,
12020–12024, 11977–11980, 11960–11964. In `docs/design/decisions.md`:
**D-261 in full (9773–9842)**, D-257's first bullet (9560–9575), D-253's
position (9315–9345, in its own vocabulary).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (125–178)**: the routed subset, the flags.
- The file-table rows for the files touched: `src/build.jl` (25),
  `src/readers.jl` (27), `src/sim.jl` (28), `src/trim.jl` (38),
  `src/show.jl` (39), `test/imports.jl` (41).
- **"Authoring caveats" in full (63–124)** — always.

In `docs/design/pending.md`: the bullet this increment retires (21–25) and
the naming rule (48–56).

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decision and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute. No behaviour beyond
the shapes and the renderings: no accessor returning a table (D-257), no
new validation, no change to any diagnostic's payload.

---

## The shapes

Opus. Files: `src/build.jl`, `src/readers.jl`, `src/sim.jl`, `src/trim.jl`,
`src/show.jl`, the two comments in `src/localization.jl` and
`src/executor.jl`, `test/imports.jl`, `test/test_build.jl`,
`test/test_events.jl`, `test/test_localization.jl`, `test/test_show.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

### The records

In `build.jl`, replacing `Dataflow` (`620–634`) and `Events` (`636–647`):

```julia
"""
One component's outputs (§9.1): the port names each stage produces, `stage1`
in the return's order, `stage2` the declared remainder in `output_types`
order. Their concatenation is the products' order, stage 1 then stage 2.
"""
struct ComponentOutputs
    path::String
    stage1::Vector{Symbol}
    stage2::Vector{Symbol}
end

"The output port names in the products' order (§8.3): stage 1, then stage 2."
_ports(entry::ComponentOutputs) = vcat(entry.stage1, entry.stage2)

"""
The nominal evaluation's product (§9.1, D-253, D-261): per component, in walk
order, the output ports each stage produces, and the execution order over the
component indices. Structural and `T`-independent, names only, which is why a
reader wanting a name list takes it from here rather than from a scalar-typed
activation. The feedthrough graph the order was computed over is not carried;
where it is shown it is derived from the structure's connections and the
producers' `stage2`.
"""
struct Outputs
    components::Vector{ComponentOutputs}   # in walk order; the index is `ci`
    order::Vector{Int}                     # the execution order over `ci`
end

"""
One component's events (§9.1, §10.4): the detection policy each guard's return
form fixes, by event name in declaration order, and the event bundle's field
names, `()` where the component declares no events.
"""
struct ComponentEvents
    path::String
    policies::NamedTuple   # event name => :boundary | :localized
    bundle::Tuple
end

"""
The nominal evaluation's other product (§9.1, D-253), built last, after the
stage probes: one row per component in walk order, the index being `ci`. It is
structural and `T`-independent like the `Outputs`, and separate from it because
a different input fixes it, the event declarations, read after the probes, so
a consumer of the execution order never carries the event tables.
"""
struct Events
    components::Vector{ComponentEvents}
end
```

`Build.dataflow` (`666`) becomes `outputs::Outputs`; its docstring
(`649–663`) says "structure, outputs, events". `_ports` is the only
concatenation; nothing spells `vcat(stage1, stage2)` elsewhere.

### The builders

`_dataflow` (`363–401`) becomes `_outputs`. Its body is unchanged through
Kahn and the stall; the local columns `ports`, `names1`, `names2`, `edges`
stay as the builder's scratch, since `_cycle_diagnostics` takes `edges`
and the cycle classifier reads it. The last line builds the rows:

```julia
    Outputs([ComponentOutputs(entry.path, names1[ci], names2[ci])
             for (ci, entry) in enumerate(structure.components)], order)
```

The docstring (`352–361`) keeps its sentences about the edges and the
stall, since the builder still computes them; it says the artifact carries
the two name lists and the order. `probe_events` (`1174–1206`) pushes
`ComponentEvents(path, policy, bn)` into one vector and returns
`Events(rows)`. `_nominal` (`926–940`) and `_activate` (`955–966`) rename
their `df` binding to `outputs` and pass `outputs.order` to `probe_stage2`,
whose `order::Vector{Int}` parameter is unchanged.

### The readers

Every column read becomes a row read at the same `ci`; no loop changes its
shape, since `Outputs.components` and `Events.components` are both in walk
order and `order` is still the list of `ci`s.

| site | today | after |
|---|---|---|
| `build.jl:1415`, `1425`, `1441` | `build.dataflow.stage1[ci]` | `build.outputs.components[ci].stage1` |
| `build.jl:1429` | `build.dataflow.stage2[ci]` | `build.outputs.components[ci].stage2` |
| `build.jl:1421` | `for ci in build.dataflow.order` | `for ci in build.outputs.order` |
| `build.jl:1442`, `1477` | `build.dataflow.ports[ci]` | `_ports(build.outputs.components[ci])` |
| `build.jl:1467` | `build.events.policies[ci], build.events.bundles[ci]` | `row = build.events.components[ci]`, then `row.policies`, `row.bundle` |
| `readers.jl:343` | `b.dataflow.ports[ci]` | `_ports(b.outputs.components[ci])` |
| `sim.jl:1286` | `sim.deployment.build.dataflow.stage1[ci]` | `sim.deployment.build.outputs.components[ci].stage1` |
| `trim.jl:519` | `build.dataflow.ports[ci]` | `_ports(build.outputs.components[ci])` |

`readers.jl:296–300`: `_ports` returns a fresh vector, so the `copy` and
the comment about copying the artifact's vector go; `candidates =
declared`. Inside `compile` a local `outputs = build.outputs` at the top
is fine if it shortens the eight reads; a single-letter binding is not.

### The renderings, `show.jl`

The `Dataflow` section (`92–110`) becomes the `Outputs` section. Compact
form `Outputs(4 components)`. The table has three columns and one row per
position in `order`, the component's path as its label, so the `label`
function and the second `_lines` method go, for `Events` too:

```
Outputs: execution order over 4 components
  component  stage 1  stage 2
  src        out      —
  fcs/inner  —        out
  gnss       —        out
  fcs/outer  —        out
```

`_lines(outputs::Outputs)` walks `for ci in outputs.order` and prints
`_path_label(outputs.components[ci].path)`; `_lines(events::Events)`
walks `enumerate(events.components)` and prints the path of each row whose
`policies` is non-empty. `Events`' block is otherwise as it is today:

```
Events: 1 event over 1 component
  component  events             bundle
  root       wrap => localized  (x, y, t)
```

The `Build` (`198–212`) renders the structure, the outputs table, then a
line of its own, then the events table and the warnings:

```
Build: 4 components (1 continuous, 3 discrete); activations: Float64; no warnings
  <the Structure's REPL form, indented>
  <the Outputs' REPL form, indented>
  feedthrough: gnss.out → fcs/outer.in
  <the Events' REPL form, indented>
  warnings: none
```

The line lists every feedthrough edge as `producer.port → consumer.face`,
comma-separated, consumers in execution order and each consumer's faces in
its `conns` order; `feedthrough: none` when there is none. The edges are
derived in one helper in `show.jl`, the `Build` being the one artifact
that holds both inputs:

```julia
# The feedthrough edges the execution order was computed over (§5.3, D-261),
# derived rather than carried: a face of a component with a stage 2, fed by
# another component's stage-2 port. A root input and a stage-1 port add none.
function _feedthrough(structure::Structure, outputs::Outputs)
    edges = String[]
    for ci in outputs.order
        isempty(outputs.components[ci].stage2) && continue
        consumer = structure.components[ci]
        for (face, (producer, port)) in consumer.conns
            isempty(producer) && continue
            port in outputs.components[index_of(structure, producer)].stage2 || continue
            push!(edges, "$producer.$port → $(_path_label(consumer.path)).$face")
        end
    end
    edges
end
```

`feedback_model` renders `feedthrough: sum.e → ctl.e, ctl.out → plant.u`.
Paths print through `_path_label`, so a root primitive is `root`. The
`for T in (...)` loop at `241` names `Outputs`.

### Tests

`test_build.jl`, the "names and edges" testset (`110–144`): rename it "the
nominal evaluation's products are names and an order"; `df` becomes
`outputs`; the six `ports` assertions and the three `edges` assertions go;
`stage1`/`stage2` reads become `outputs.components[plant].stage1` and so
on; `outputs.order == [sm, ctl, plant]` stays. Add, on `feedback_model`,
`[outputs.components[ci].path for ci in outputs.order] == ["sum", "ctl",
"plant"]` and `_ports(outputs.components[plant]) == [:y, :power]`. The
`SwappedPorts` case keeps `stage1 == [:q, :p]` and `isempty(stage2)`, and
gains `_ports(...) == [:q, :p]`, the products' order. The comment at
`92` says `Outputs`. `370, 375, 1195, 1214`: `b.outputs.components[i].stage1`.

`test_events.jl:112–114, 121–122`: `.events.components[1].policies`,
`.events.components[1].bundle`; the comment at `118–120` says the rows.
`test_localization.jl:158` likewise.

`test_show.jl`: `MULTIRATE_DATAFLOW` (`38–44`) becomes `MULTIRATE_OUTPUTS`
with the block above; `71` asserts `Outputs(4 components)`; the `Dataflow`
testset (`109–122`) asserts the block, that the same block appears inside
`plain(multirate)` indented two spaces (the labels are paths in both
places now, so one constant serves), and the `Build`'s line
`"\n  feedthrough: gnss.out → fcs/outer.in\n"`. Add, in the `Build` testset
(`159–171`): `plain(build(feedback_model()))` carries
`"\n  feedthrough: sum.e → ctl.e, ctl.out → plant.u\n"`, and
`plain(pendulum)` carries `"\n  feedthrough: none\n"`. The `Events`
testset (`124–131`) drops the `#1` form: `plain(build(Motor(1.0)).events)`
prints `c` in the component column (the path `fed` gives it; check in the
REPL) and the `Sawtooth` block prints `root` as today. `83` and `191` name
`multirate.outputs`. Every expected string is re-derived in a REPL before
it is pasted; the probe's blocks above are the brief's reading, not the
test's evidence.

`test/imports.jl`: `Dataflow` → `Outputs`, add `ComponentOutputs`,
`ComponentEvents`, and `_ports` if a test calls it.

### Bookkeeping

- `implementation.md`: row 25 says the `Outputs` as `ComponentOutputs` rows
  with the order beside them and `_ports`, the `Events` as
  `ComponentEvents` rows, "structure, outputs, events" for the `Build`; rows
  27, 28, 38 say `Outputs`; row 39 says the `Outputs` and `Events` tables
  print paths, no label function, and the `Build`'s `feedthrough:` line
  derived by `_feedthrough`. Nothing else in the file names the old type;
  check with a grep.
- `pending.md`: delete the bullet at 21–25 whole. Run `check_refs.jl` and
  `check_rows.jl` after.
- After the change, `grep -rn -i "dataflow" src/ test/` returns nothing;
  `grep -rn "policies\[\|bundles\[" src/ test/` returns nothing. The
  comments the probe lists are rewritten for the shape that exists, not
  patched by substitution: a comment that says "column" or "per component
  vector" of the artifact is stale.
- Commit subject, one sentence: what changed.

---

## Rules for the stage

- **Names.** Function parameters and any binding that outlives a few lines
  take a descriptive name (`outputs`, `row`, `entry`, `consumer`,
  `producer`). Single letters stay for the spec's symbols, for a binding
  visible in one glance and for the component index `ci`. This is
  `pending.md:48`'s rule; the increment applies it to what it touches and
  to everything it creates. A loop-body local the increment does not
  otherwise touch is left alone, the naming sweep covers it.
- Run the suite in the foreground with a 600 s timeout, under the sandbox
  flags of "Running the suite"; never in the background. Never stash,
  reset or check out the working tree. Baselines come from `git show
  6cbbaea:<file>`.
- Check every runtime claim above in a REPL before relying on it
  (`julia --project=test -L test/repl.jl` opens one with the fixtures; from
  a script, `include` `test/repl.jl` by absolute path, then `using Test`
  and `test/utils.jl` for `single`/`fed`, and reproduce `SwappedPorts` from
  `test_build.jl:93–97` if it is needed).
- A stage that finds the suite red on a file it did not touch stops and
  reports, with the failing testset's name.
- Docstrings and comments are prose the next reader trusts: write them
  for the shape that exists after the stage.

## Report format

The commit hash and subject; every site the brief cited that did not hold
as described, with what was there instead; every deviation from the shapes
above, with the reason; the suite's result line (the pass/fail/error
counts) and its wall time; and handoff notes for the reviewer, one line
each, on anything worth probing.

## For the reviewer

Beyond the gate: the two greps above; every row of the readers table
checked against the diff; the `Outputs` and `Events` docstrings' index
conventions read against every loop that touches `components` and `order`;
and one probe script in the scratchpad that builds `feedback_model` and
`MultiRate`, renders each `Build`, and confirms the `feedthrough:` line
against the edge lists the pre-flight probe records above.
