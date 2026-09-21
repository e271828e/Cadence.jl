# Increment 48 — The row shape of `Structure` and the renderings (§9.1, §9.2, §13.7, D-257, D-261)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `4ac061c` plus the commit that adds this brief. Line numbers below
are those of `4ac061c`. Never `cd` elsewhere (`cd` is aliased to zoxide in
the user's shell; use absolute paths).

**Standing.** D-257 (`decisions.md:9560`) says every build-side and
deployment artifact renders itself through `show`, with no accessors, and
fixes the hyperperiod chart's binary guard. Its first bullet was amended on
2026-09-21 to add `Events`. D-261's artifact rule (`decisions.md:9785`) was
amended the same day: an artifact holds its facts as rows, so `Structure`
carries one `ComponentEntry` per component and one `Anchor` per anchor, as
the `Schedule` carries `ScheduleEntry` and `ScopeEntry` rows, and the
walk's accumulator is a `StructureDraft`. The spec has said the tables
since D-253 (§9.2, 3290–3340). `pending.md:41–44` is the sentence this
increment retires, and with it the redesign's umbrella bullet. Roadmap
step 7 of `roadmap_pipeline_redesign.md`.

**The pre-flight probe** (2026-09-21, greps at `4ac061c` and one REPL
script over `MultiRate`, the `Absolute(Hz(500))`/`Absolute(Hz(10),
1//150)` group of `test_discrete.jl:458` and `Pendulum`).

- `Structure`'s per-component columns (`paths`, `comps`, `tiers`,
  `triples`, `provenance`, `conns`) are read through a structure receiver
  at 74 sites in `src/build.jl`, 9 in `src/deployment.jl`, 9 in
  `src/sim.jl`, 8 in `src/conditions.jl`, 7 in `src/tracer.jl`, 3 each in
  `src/readers.jl` and `src/trim.jl`, 1 each in `src/assembly.jl` and
  `src/trace.jl`; in `test/`, 25 in `test_assembly.jl`, 3 in
  `test_discrete.jl`, 1 in `test_conditions.jl`. Two idioms cover nearly
  all: `for ci in eachindex(s.comps)` with `s.paths[ci], s.comps[ci],
  s.tiers[ci]` inside, and `zip(w.paths, w.comps)`. Through the walk
  receiver (`w.`), 31 sites in `assembly.jl` and 15 in `build.jl`; those
  stay column reads on the draft.
- `Structure.anchors`/`aprov` are read at `deployment.jl:186` alone;
  `aprov` is written at `assembly.jl:897–900`. `Structure.scopes` at
  `deployment.jl:262` and `test_discrete.jl:278`.
- `Walk` has 10 mentions in `assembly.jl`, 3 in `build.jl` (`703`, `743`,
  `794`), none in `test/` (`WalkingFaceAtFrozenEntry` and `WALK_FACES` are
  other names and stay).
- `ScheduleRow`: `deployment.jl:101, 113, 116, 138, 253, 259`,
  `test/imports.jl`. `ScopeRow`: `deployment.jl:123, 139, 262`,
  `test/imports.jl`, `test_discrete.jl:280`. `.rows` readers stay
  (`deployment.jl` 4, `trace.jl` 3, `test_discrete.jl` 15); the field
  keeps its name.
- `ScheduleRow.provenance` is read at `deployment.jl:115, 117`,
  `trace.jl:303` (the column walk's list), `test_discrete.jl:262, 266,
  267`.
- `GridEntry.provenance` (`diagnostics.jl:1219`) is read by `_grid_label`
  (`1280`, a regex parsing the key off the string) and `_grid_block`
  (`1286`), constructed at `deployment.jl:86` and `test_diagnostics.jl:252,
  254`, asserted at `test_discrete.jl:469–471`.
  `DeploymentInvalid.provenance` (`1244`) is set at `deployment.jl:238,
  243`, read in `message` at `1332, 1335`, constructed at
  `test_diagnostics.jl:425, 428`, asserted at `test_discrete.jl:398`.
- `root_types` is `nothing` only on `_check_wires`' two refusal arms
  (`build.jl:846, 852`), each recording a diagnostic; the barrier at
  `build.jl:715` throws before `Structure` is built at `716`.
- `Structure.comps` holds only what `_walk!`'s primitive branch pushes
  (`assembly.jl:1015`), a value from `_children` (fields and container
  elements `<: AbstractComponent`, `140–157`) or the root, which
  `build(root::AbstractComponent)` (`build.jl:695`) types.
- No `Base.show` exists on any artifact; the one in the tree is `Marker`'s
  (`build.jl:774`). The default `show` of a `MultiRate` `Structure` is
  1507 characters, of its `Deployment` 4208.
- `MultiRate` at `h = 1//500`: rows `fcs/inner (1, 0)`, `fcs/outer (5,
  2)`, `gnss (10, 0)`, `lcm = 10`; one anchor `(1//50, 0)` declared at the
  root under key `gnss`; one scope row `("fcs", :fcs, (0, 1, 0))`; `src`
  is continuous. The `Hz(500)`/`Hz(10), 1//150` group derived at `h =
  1//1500`: rows `a (3, 0)`, `b (150, 10)`, `lcm = 150`, a
  `GridUtilization` warning on the deployment. `Pendulum`: one component
  at path `""`, no rows, no anchors, root input `u`. `Events` on
  `MultiRate` is four empty `NamedTuple`s; `Motor` (`fixtures.jl:61`),
  `Trigger` (`317`) and `Sawtooth` (`356`) declare events.
  `SelectedNothing(Gain(2.0), Gain(3.0))` builds with one
  `EmptyFaceSelection` warning (`test_assembly.jl:1019`).
- `test/imports.jl` lists `Structure`, `Schedule`, `ScheduleRow`,
  `ScopeRow`, `GridEntry`, `GridReport`, `Dataflow`, `Events`, `Build`,
  `Deployment`. It will need `ScheduleEntry`, `ScopeEntry`,
  `ComponentEntry`, `Anchor` and lose the two old names.

**Two stages, two commits, in this order.** Both touch a file in the
routing table's last row (`deployment.jl`, `diagnostics.jl` beyond a new
kind, `Cadence.jl`), so each routed subset is all of it, under the sandbox
flags. `implementation.md`'s "Running the suite" (124–175) is the one home
of test policy; this brief does not restate it. The gate is the reviewer's.

- **Stage 1, the shapes.** The records, the draft, the renames, the
  narrowings, the reader sweep.
- **Stage 2, the renderings.** Six artifacts, two `show` methods each, the
  chart and its guard, `test_show.jl`.

**Read, in `docs/design/spec.md`:** §9.1's opening table and the structure
step, 2991–3033; the fold table and the `Structure` paragraph, 3080–3105;
§9.2 from the timing tables to the grid diagnostics, 3290–3343, and the
worked example, 3344–3362; §13.7's first four paragraphs, 8205–8232;
§10.5's assemblies subsection heading for the scope vocabulary, 4533. In
`docs/design/decisions.md`: **D-257 (9560–9600)**, D-261's first three
bullets and the amendment (9773–9795), D-254 (9380), D-187's position
(6512–6522).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (124–175)**: the routed subset, the flags.
- The file-table rows for the files a stage touches: `src/diagnostics.jl`
  (20), `src/assembly.jl` (22), `src/build.jl` (25), `src/deployment.jl`
  (30), `src/trace.jl` (33), `test/imports.jl` (40).
- **"Authoring caveats" in full (62–122)** — always.

In `docs/design/pending.md`: the umbrella bullet (21–44) and the two
sweep bullets after "Smaller" (67–89), which state the naming rule this
increment writes to.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the decision and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute. No behaviour beyond
the shapes and the renderings: no accessor returning a table (D-257), no
new validation, no change to what any diagnostic carries beyond the two
fields named below.

---

## Stage 1 — the shapes

Opus. Files: `src/assembly.jl`, `src/build.jl`, `src/deployment.jl`,
`src/diagnostics.jl`, `src/trace.jl`, the readers listed in the probe,
`test/imports.jl`, `test/test_assembly.jl`, `test/test_discrete.jl`,
`test/test_diagnostics.jl`, `test/test_conditions.jl`.

### The two records

In `assembly.jl`, beside `RateLink` and `RateScope` (`718–721`). First
the fold's value gets named positions:

```julia
"The sample-time fold's value for one scope or component (§9.1): the anchor it hangs from (0 the base grid), and its period multiple and phase in that anchor's ticks."
const Timing = @NamedTuple{anchor::Int, m::Int, c::Int}
```

`RateScope.triple` becomes `timing::Timing`; the `scope::NTuple{3,Int}`
arguments of `_child_scope` (`879`) and `_walk!` (`996`) and the fold's
arithmetic (`891–904`) take and build a `Timing`; `bind_schedule`'s
destructurings (`deployment.jl:256, 262–264`) become field reads. 34
sites name `triple` (14 in `assembly.jl`, 7 in `deployment.jl`, 1 in
`build.jl`, 9 in `test_assembly.jl`, 3 in `test_discrete.jl`). The spec
keeps "triple" as its word for the value.

```julia
"""
One anchor (§9.1, §9.2): the exact `(T, τ)` an `Absolute` entry seeds, with
the `sample_times` entry that declared it, by scope path and key. Anchor 0,
the base grid, has no record here; it is symbolic until `Δt_base` binds.
"""
struct Anchor
    T::Rational{Int}
    τ::Rational{Int}
    scope::String
    key::Symbol
end

"""
One component of the structure (§9.1): its path, the instance, the tier the
walk read, the `sample_times` links met on the way down and the timing the
fold made of them, and each declared input face resolved to its producer.
"""
struct ComponentEntry
    path::String
    instance::AbstractComponent
    tier::Tier
    rates::Vector{RateLink}
    timing::Timing
    conns::Vector{Pair{Symbol,Tuple{String,Symbol}}}   # face => (producer path, port)
end
```

The chain field is `rates`, not `provenance` (the word is a pending sweep,
`pending.md:75`; new code does not add to it). `instance`, not `comp`.

### `Structure`

```julia
struct Structure
    root::AbstractComponent
    components::Vector{ComponentEntry}     # in walk order; the index is `ci` everywhere
    anchors::Vector{Anchor}                # anchors 1…K
    scopes::Vector{RateScope}
    root_inputs::Vector{Symbol}
    root_types::Vector{Type}
    in_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}
    out_faces::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}
end
```

Rewrite the docstring (`724–736`) for the shape; keep its citations. The
narrowings hold by the probe: `root` is typed by `build`'s signature,
`instance` by the walk's push site, `root_types` by the barrier.

### `StructureDraft`

`Walk` (`761–784`) becomes `StructureDraft`, docstring rewritten to say
what it is: the structure step's accumulator, disposable, holding the
per-component columns with the slack the dirty pass needs and the walk's
scratch, and handed to the `Structure` constructor at the barrier. Fields:
`root::AbstractComponent`, `paths`, `instances::Vector{AbstractComponent}`,
`tiers::Vector{Union{Nothing,Tier}}`, `rates::Vector{Vector{RateLink}}`, `timings::Vector{Timing}`,
`anchors::Vector{Anchor}`, `scopes`, `root_inputs`, `out_faces`, and the
four scratch fields unchanged. `aprov` goes. `_child_scope` (`878–905`)
finds an anchor by `scope == path && key == k` and pushes
`Anchor(v.T, v.τ, path, k)`; the comment on one anchor per `Absolute`
entry stays.

The constructor at `987–992` builds the rows at the barrier:

```julia
Structure(draft::StructureDraft, conns, in_faces, root_types) =
    Structure(draft.root,
              [ComponentEntry(path, instance, tier, rates, timing, cs)
               for (path, instance, tier, rates, timing, cs) in
                   zip(draft.paths, draft.instances, Vector{Tier}(draft.tiers),
                       draft.rates, draft.timings, conns)],
              draft.anchors, draft.scopes, draft.root_inputs, Vector{Type}(root_types),
              in_faces, draft.out_faces)
```

The invariant is unchanged: no code pushes into a `Structure`'s vector
after this call. The parameter is `draft`, never `w` or `d`, in every
signature that takes one (`_child_scope`, `flatten!`, `_last_level`,
`wire!`, `_walk!`, `_claim!`, `_check_event_declarations`, `_check_wires`).

### The readers

`s.paths[ci]`, `s.comps[ci]`, `s.tiers[ci]`, `s.triples[ci]`,
`s.provenance[ci]`, `s.conns[ci]` become `s.components[ci].path`,
`.instance`, `.tier`, `.timing`, `.rates`, `.conns`; `for ci in eachindex(s.comps)` becomes `for (ci, entry) in
enumerate(s.components)` where the body reads more than one column, and
`length(s.components)` where it reads none. `index_of` (`803`) searches
`components` by path. `_gates` (`deployment.jl:145`) iterates the entries.
`bind_schedule` (`186–262`) reads `structure.anchors` and the entries.
`sim.jl:1282`, `readers.jl:309, 324`, `tracer.jl`, `conditions.jl`,
`trim.jl`, `trace.jl` likewise. Rename the receiver where it is a single
letter in a signature the sweep touches (`s::Structure` → `structure`,
`b::Build` → `build` is fine where no `build` call is in scope; use
`built` where one is); leave a receiver alone inside a function the sweep
does not otherwise touch, the naming sweep of `pending.md:67` covers it.

The tests: `test_assembly.jl`'s 25 reads of `s.paths` and the like become
reads over `components`; a one-line helper in `test/utils.jl`,
`paths(structure) = [entry.path for entry in structure.components]`, is
acceptable if it keeps the assertions readable.

### `ScheduleEntry`, `ScopeEntry`

`ScheduleRow` → `ScheduleEntry`, its `provenance` field → `rates`;
`ScopeRow` → `ScopeEntry`. `Schedule.rows` and `Schedule.scopes` keep their
names. `==`/`hash` (`113–117`) follow. `trace.jl:303`'s column list names
`:rates`; check `_walk_deployment!`'s rendering of that column and
`ReplayHeaderMismatch`'s test in `test_trace.jl` for the old word.

### The grid's two payloads

`GridEntry.provenance::String` → `scope::String, key::Symbol`.
`_grid_report(anchors)` (`deployment.jl:53`) takes the `Vector{Anchor}`
alone, its `prov` argument gone. `_grid_label` (`1279–1282`) becomes
`"$(entry.key) $(entry.kind)"`, no regex. `_grid_block`'s first column
formats the entry through one helper in `diagnostics.jl`:

```julia
# The anchor's declaring entry, as every grid consumer names it.
_anchor_label(scope::String, key::Symbol) =
    "`sample_times` at $(_at_path(scope)), key `$key`"
```

`DeploymentInvalid.provenance::String = ""` → `scope::String = ""` and
`key::Union{Nothing,Symbol} = nothing`; `message`'s two anchor arms
(`1332, 1335`) open with `_anchor_label(d.scope, d.key)`. The rendered text
is byte-identical to today's, so no message assertion moves. The two
constructions at `deployment.jl:238, 243` pass `scope = anchor.scope, key
= anchor.key`. `assembly.jl:72`'s `_at` and `diagnostics.jl:69`'s
`_at_path` are the same function twice; leave that, the naming sweep
(`pending.md:67`) folds them.

Tests: `test_diagnostics.jl:252–255` construct `GridEntry(:period, 1//30,
"a", :b, 10, Rational{Int}[])`; `425–429` pass `scope = "a", key = :b`;
`test_discrete.jl:398` asserts `d.scope == "" && d.key === :gnss`;
`469–471` assert `[(e.scope, e.key) for e in g.pool] == [("", :a), ("",
:b), ("", :b)]`.

### Bookkeeping

- `implementation.md`: the `assembly.jl` row (22) says `StructureDraft`
  accumulating the columns and the `Structure` built as rows,
  `ComponentEntry` and `Anchor`, at the barrier; the `deployment.jl` row
  (30) says `ScheduleEntry` and `ScopeEntry`; the `diagnostics.jl` row
  (20) says `GridEntry` carries the anchor's scope and key and
  `_anchor_label` renders them. `test/imports.jl`.
- `pending.md`: nothing; the umbrella bullet retires in stage 2.
- Docstrings and comments on every touched struct and function say the
  new shape; a comment that names `Walk`, `aprov`, `comps` or
  `ScheduleRow` is stale.
- Commit subject, one sentence: what changed.

---

## Stage 2 — the renderings

Opus. A new file `src/show.jl`, included last in `src/Cadence.jl` (after
`localization.jl`; every type it renders exists by then). A new
`test/test_show.jl`, included and registered in `test/CadenceTests.jl`
like its siblings. `_grid_block` stays in `diagnostics.jl`, since the
messages use it; `show.jl` calls it.

### The two methods

Every artifact gets `Base.show(io::IO, x)` (the compact form, one line, no
newline, what a container or `repr` prints) and
`Base.show(io::IO, ::MIME"text/plain", x)` (the REPL form, the tables). The
REPL form ends without a trailing newline and no line carries trailing
whitespace. Tables align their columns with `rpad` over `textwidth`, as
`_grid_block` does, two spaces between columns, the block indented two
spaces under its heading. A nested artifact's REPL form is rendered into a
buffer and indented two further spaces, through one `_indented(io, x)`
helper. Anchor labels are `A₀`, `A₁`, … (`_SUPERSCRIPTS` has the digits;
a subscript table of the same shape is needed). Tiers print through
`tier_word` (`declare.jl:270`). A `RateLink` chain prints as
`key = entry` joined by ` → `, the entry by its default `show`
(`Relative(5, 2)`, `Absolute(1//50, 0)`); an empty chain is `—`. A
component label is `#ci` where only a `Dataflow` or `Events` is in hand and
the path where the `Build` renders them: the two files' table builders take
a `label(ci)` function.

### `Structure`

Compact: `Structure(4 components, 1 anchor, 1 rate scope)`; singular forms
where the count is 1; `no anchors`, `no rate scopes` at zero.

REPL form, in this order:

```
Structure: 4 components, 1 anchor, 1 rate scope; root inputs: none
  components:
    path       tier        anchor  m  c  rates
    src        continuous  A₀      1  0  —
    fcs/inner  discrete    A₀      1  0  fcs = Relative(1, 0) → inner = Relative(1, 0)
    fcs/outer  discrete    A₀      5  2  fcs = Relative(1, 0) → outer = Relative(5, 2)
    gnss       discrete    A₁      1  0  gnss = Absolute(1//50, 0)
  rate scopes:
    path  key  anchor  m  c
    fcs   fcs  A₀      1  0
  anchors:
    anchor  T        τ  scope  key
    A₀      Δt_base  0  —      —
    A₁      1//50    0  root   gnss
```

The root inputs line lists the faces comma-separated, `none` when empty.
The root path prints as `root` in the scope column (and as the component
path where a primitive is the root, `Pendulum`'s case). The `A₀` row is
always present, with `Δt_base` in the `T` column and dashes in the scope
and key columns (§9.2). The rate-scope block is omitted when there are
none. Faces and wires are not printed (§9.2: fields, "printed by any REPL
without a method of their own"; the face-provenance printer is
`pending.md`'s "Smaller" bullet, unchanged by D-257).

### `Dataflow`

Compact: `Dataflow(4 components)`.

```
Dataflow: execution order over 4 components
  position  component  stage 1  stage 2  feedthrough
  1         #1         out      —        —
  2         #2         —        out      —
  3         #4         —        out      —
  4         #3         —        out      in ← #4.out
```

One row per position in `order`, the component label at that position,
its stage-1 names and stage-2 names comma-separated (`—` when empty), and
its incoming feedthrough edges from `edges[ci]` as `face ← producer.port`,
comma-separated. These are the stage-2 dependencies the order was
computed over, not the wires: `fcs/inner` and `gnss` read `src.out`, a
stage-1 port, so their column is empty, and only `fcs/outer`, fed by
`gnss`'s stage-2 `out`, carries one (the probe's `edges`). Standalone the
label is `#ci`; the `Build` passes paths.

### `Events`

Compact: `Events(2 events over 4 components)`; `Events(no events over 4
components)` at zero.

```
Events: 2 events over 4 components
  component  events                                  bundle
  #2         start => boundary                       (x, s)
  #3         up => localized, down => localized      (x, s, ws)
```

One row per component that declares an event; the events column lists
`name => policy` in declaration order; the bundle column the field names
from `bundles[ci]`, `—` when empty. A `Events` with no events prints the
heading line alone.

### `Schedule`

Compact: `Schedule(3 rows, hyperperiod 10 base ticks)`; `Schedule(no
rows)` when empty.

```
Schedule: 3 rows, 1 rate scope, hyperperiod 10 base ticks
  path       anchor  D   Φ  Δt     rates
  fcs/inner  A₀      1   0  0.002  fcs = Relative(1, 0) → inner = Relative(1, 0)
  fcs/outer  A₀      5   2  0.01   fcs = Relative(1, 0) → outer = Relative(5, 2)
  gnss       A₁      10  0  0.02   gnss = Absolute(1//50, 0)
  rate scopes:
    path  key  anchor  D  Φ
    fcs   fcs  A₀      1  0
  hyperperiod chart, 10 base ticks:
               0
    fcs/inner  ●●●●●●●●●●
    fcs/outer  ··●····●··
    gnss       ●·········
```

`Δt` prints through `repr`, never rounded. The hyperperiod is
`lcm(D for the rows)`, `L`. The chart is one row per schedule row in row
order, one character per base tick `k = 0 … L−1`, `●` where
`(k − Φ) % D == 0` and `·` elsewhere, under a ruler line that carries the
tick index at every column divisible by 10 (`0`, `10`, `20`, …, left-aligned
at its column, the ruler's path column blank). `fcs/outer` above is the
check: `Φ = 2, D = 5` fires at 2 and 7.

**The guard (D-257).** `L ≤ 100` prints the chart. `L > 100` prints in its
place the single line `hyperperiod: 150 base ticks, chart omitted`, the
number being `L`. No rows: the heading says `no rows`, no scope block
unless scopes exist, no chart line at all.

### `Build`

Compact: `Build(4 components, activations: Float64)`, the activation keys
in insertion order; `no warnings` is not on the compact form.

```
Build: 4 components (1 continuous, 3 discrete); activations: Float64; no warnings
  <the Structure's REPL form, indented>
  <the Dataflow's REPL form with paths as labels, indented>
  <the Events' REPL form with paths as labels, indented>
  warnings: none
```

With warnings, the last block is one line per warning, `logline(w)`,
indented, and the heading says `1 warning`. Read `activations` under the
build's `lock`.

### `Deployment`

Compact: `Deployment(h = 0.002, N_base = 1, Δt_base = 0.002, RK4)`.

```
Deployment: h = 0.002, N_base = 1, Δt_base = 0.002, RK4; firing_budget = 4, localization_tol = 1.0e-6, localization_budget = 8
  build: Build(4 components, activations: Float64)
  <the Schedule's REPL form, indented>
  grid:
    <_grid_block's lines, re-indented>
  warnings: none
```

The build is its compact form, one line (D-257's "parts" for the
deployment are the parameters, the schedule, the grid and the warnings; a
reader wanting the build evaluates `d.build`). `grid:` is followed by
`_grid_block(d.grid)`'s rows; when the block is empty (no anchor declares a
constraint) the line reads `grid: no constraint`. `algorithm` prints its
type name.

### Tests, `test/test_show.jl`

Cut by property, one function `test_show()`, testsets citing §9.2 and
D-257. Every assertion is on `sprint(show, x)` or
`sprint(show, MIME("text/plain"), x)`; message text stays
`test_diagnostics.jl`'s. Fixtures: `MultiRate` at `h = 1//500`, the
`Hz(500)`/`Hz(10), 1//150` group derived at `h = 1//1500` (wrap the
constructor in `@test_logs` as `test_discrete.jl:461` does), `Pendulum` at
`h = 1//100`, `Motor` or `Sawtooth` for events,
`SelectedNothing(Gain(2.0), Gain(3.0))` for a build with a warning.

- Compact forms: one line, no `'\n'`, the counts named, for all six.
- `Structure`: the exact block above for `MultiRate` (the `m` and `c`
  columns are `timing.m` and `timing.c`); the `A₀` row's dashes; `Pendulum`'s single `root` component row and the absence of the
  rate-scope block; the root inputs line on both.
- `Dataflow`: the exact block for `MultiRate` with `#ci` labels; the one
  feedthrough edge `in ← #4.out` on `fcs/outer`'s row and none elsewhere;
  the same table inside the `Build` carrying paths.
- `Events`: `MultiRate`'s heading alone; an event-declaring fixture's row
  with its policy word and bundle.
- `Schedule`: the exact block for `MultiRate`, the three chart rows
  asserted as strings; the group's `chart omitted` line with `150`;
  `Pendulum`'s `no rows` heading and no chart line. One more:
  `(k − Φ) % D == 0` against the chart's `●` positions for every row of
  `MultiRate`, computed independently in the test.
- `Build`: the heading's tier counts and activation list; `activations:
  Float64, ForwardDiff.Dual…` after `activation(b, Dual)` is not required;
  the warning line for `SelectedNothing`.
- `Deployment`: the parameter line; the `grid:` block present for the
  anchored group and `no constraint` for `Pendulum`; the
  `GridUtilization` warning line for the group.
- Every REPL form: no trailing newline, no line with trailing whitespace.

### Bookkeeping

- `test/CadenceTests.jl`: the include and the registration, as the other
  files.
- `implementation.md`: a `src/show.jl` row after `src/trim.jl`'s, one
  line, naming the twelve methods, the label function, the chart and its
  guard, citing §9.2, §13.7, D-257. The routing table (146–152): add
  `show` to the first row's list, and a new row before the last, `| `show`
  | `show` |`. `test/` is not rostered beyond its three rows; nothing
  else.
- `pending.md`: delete the umbrella bullet (21–44) whole; the "Smaller"
  bullet's face-table clause stays. Run `check_refs.jl` and
  `check_rows.jl` after.
- Commit subject, one sentence.

---

## Rules for every stage

- **Names.** Function parameters and any binding that outlives a few
  lines take a descriptive name (`draft`, `structure`, `entry`, `anchor`,
  `schedule`, `deployment`, `diagnostic`). Single letters stay for the
  spec's symbols (`D`, `Φ`, `Δt`, `T`, `τ`, `m`, `c`, `h`, `L`), for a
  binding visible in one glance (`for (k, v)`, a comprehension variable)
  and for the component index `ci`. This is `pending.md:67`'s rule; the
  increment applies it to what it touches and to everything it creates.
- Run the suite in the foreground with a 600 s timeout, under the sandbox
  flags of "Running the suite"; never in the background. Never stash,
  reset or check out the working tree. Baselines come from `git show
  4ac061c:<file>`.
- Check every runtime claim above in a REPL before relying on it
  (`julia --project=test -L test/repl.jl` opens one with the fixtures;
  `include` it by absolute path from a script). The probe's chart rows
  and `lcm` values are what stage 2's exact-string tests assert; re-derive
  them.
- `test/imports.jl` lists every framework name a test calls; stage 1
  edits it, stage 2 needs nothing new unless a helper is tested directly.
- A stage that finds the suite red on a file it did not touch stops and
  reports, with the failing testset's name.
- Docstrings and comments are prose the next reader trusts: write them
  for the shape that exists after the stage.

## Report format

For each stage: the commit hash and subject; every site the brief cited
that did not hold as described, with what was there instead; every
deviation from the shapes above, with the reason; the suite's result line
(the pass/fail/error counts) and its wall time; and handoff notes for the
next stage or the reviewer, one line each, on anything the reviewer should
probe.
