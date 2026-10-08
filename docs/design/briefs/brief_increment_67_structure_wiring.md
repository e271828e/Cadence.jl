# Brief: increment 67, the `Structure` holds its declared wiring and resolves it by function

Three code stages, one cold review and a fixer if the review needs one. The
docs arc is landed in d442223: D-315 and its
annotations on D-207, D-257, D-261 and D-270 in `decisions.md`, the §9.1,
§9.2, §13.7, Appendix B and glossary amendments in `spec.md`, and
`pending.md`'s increment 67 bullet. Written at 90bf71d and rebased at e98faf3
once increments 65 and 66 had landed: neither touched a source file, the
spec or the log this brief cites, `test/fixtures.jl` only renamed its
`DiscreteIntegrator` to `DiscreteAccumulator` on the same lines, and
`test/imports.jl`'s `Redstone.Blocks` list grew. The tip at launch is the
commit rebasing this brief; line numbers below are that tree's. Find
passages in `docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **The artifact holds declared facts and no resolved table** (D-315).
  `Structure` keeps its primitives' rows, its anchors, its scopes and its
  root inputs with their types, and gains one row per assembly. It loses
  `root`, `child_lists`, `in_faces`, `out_faces`, `in_routes` and
  `out_routes`, and `ComponentEntry` loses `conns`. Every resolution over
  the wiring becomes a function over the rows, computed where it is read.
- **The level row.** Two structs in `src/assembly.jl`, beside
  `ComponentEntry`:

  ```julia
  struct Child
      segment::String             # "trim", "loops/l1", or "l1" under a transparent container
      field::Symbol               # the field that contributed it, the rate sugar's key (§8.7)
      instance::AbstractComponent
  end

  struct LevelEntry
      path::String                # "" for the root
      instance::AbstractComponent
      children::Vector{Child}     # field order, then element order: `_children`'s order
      wires::Vector{Pair{Tuple{String,Symbol},Tuple{String,Symbol}}}   # producer => consumer
  end
  ```

  `Structure.levels::Vector{LevelEntry}` holds one row per assembly in the
  walk's pre-order, the root first, so `levels[1].instance` is what `root`
  was. A level's `wires` are its three declarations as one-level pairs in
  declaration order: `local_wires` entries first, then `input_wires`, then
  `output_wires`, each in its list's order. An input or output wire carries
  the level's own face on the boundary side, `("", :ref) => ("trim", :e)`
  and `("loop", :y) => ("", :y)`. An `input_wires` entry fanning out to
  several children is one pair per target. Nothing else is stored: no
  terminal, no route, no type.
- **Where the pairs come from.** The walk already holds each pair's
  one-level endpoints at the moment it claims the consumer
  (`src/assembly.jl` lines 1084 to 1124). `resolve_source` and `_fanout`
  return routes whose first hop is the immediate child's face, so a local
  wire records `first(route) => first(first(routes))`, an input entry
  records `(path, face) => first(route)` for each distinct first hop of its
  routes, and an output entry records `first(route) => (path, face)`. A
  pair whose endpoint failed to resolve records nothing; the barrier throws
  before any `Structure` exists. The draft records the pairs in a
  `Dict{String,Vector{Pair}}` keyed by level path and the level paths in
  pre-order in a vector, pushed where `_children` is called (line 1055);
  the constructor assembles the rows. The draft's own scratch, `feeds`,
  `routes`, `out_faces`, `claims` and `faces`, stays as it is: `_check_wires`
  reads `feeds`, `_last_level` reads `routes`, `resolve_source` reads
  `out_faces`. The draft is disposable and holds what the checks need.
- **Container membership** is read off a child's segment against its field,
  in one accessor on `Child`: the segment equals the field name for a plain
  component field; it starts with the field name and a slash for a
  container element; otherwise the element came from a name-transparent
  container. Name it under "Naming" (`membership(child)` returning `:field`,
  `:container` or `:transparent` is the suggestion; grep first).
- **Two functions resolve, in the resolvers' section of `src/assembly.jl`.**
  `terminal_producer(structure::Structure, face::Tuple{String,Symbol})`
  returns the producer `(path, port)` of any face at any level, a
  primitive's port or `("", root_input)`. The walk: find the wire whose
  consumer is the face; if the producer is a primitive's port, stop; if it
  is a sibling assembly's output face, continue from that level's wire into
  that face; if it is the level's own input face, continue from the parent
  level's wire into it. An output face starts from its own level's output
  wire. `face_routes(structure, face)` returns the hops the same walks
  visit, `Vector{Vector{Tuple{String,Symbol}}}`: one route for an output
  face, down to the producer, and one per consumer for an input face, down
  to each terminal consumer, in the shape `in_routes` and `out_routes` hold
  today (`test/test_assembly.jl` lines 596 to 603 show both). A primitive's
  own input face has one route, itself. Both functions take plain data and
  nothing else, so they compile once at package load (D-289). A level is
  found by `findfirst` over `levels`; the tables are hundreds of rows and
  the walk is a quarter of a millisecond over every face of a sixty-primitive
  model, so no index is built.
- **The layout is the one address home** (D-261). `cell_layout`'s alias
  pass (`src/build.jl` lines 587 to 589) enters every assembly output face
  from `terminal_producer` in place of `structure.out_faces`, and gains the
  input side: for every primitive and every face in `decls[ci].ins`,
  `addr[(path, face)] = addr[terminal_producer(structure, (path, face))]`.
  `in_group` in `compile` (line 1420) then reads `layout.addr[(path, face)]`
  and `input_addr` (line 619) goes.
- **Every other reader calls the functions**, each in place of one field
  read, the declared faces coming from `decls[ci].ins` where the row's
  `conns` gave them: `_outputs` (line 370), `_root_input_cell` (607),
  `_probe_input` (1576), `_seed_face` in `src/tracer.jl` (243), the pinning
  check in `src/linearize.jl` (340 to 352), `_feedthrough` in `src/show.jl`
  (220), `_input_faces_at` and `_face_producer` in `src/conditions.jl` (462,
  469), the mounting producer and `_exported_faces` in `src/readers.jl` (548
  to 563), and `port_views` in `src/devices.jl` (306 to 330). The faces of a
  level are the wire endpoints carrying its own path: its input faces are
  the producers equal to `(path, f)`, its output faces the consumers equal
  to `(path, f)`, in wire order, deduplicated for a fanned input. The root's
  input faces stay `structure.root_inputs`. `_mount` (`src/readers.jl` 466)
  and `_resolve_entries` (`src/conditions.jl` 355) start from
  `structure.levels[1].instance`; `resolve_authored` (`src/assembly.jl`
  1205) finds the level row at `here_path` and reads its children, a
  primitive having no row.
- **`show` derives the routes.** `_route_lines` (`src/show.jl` 73) walks
  `face_routes` over the root's faces instead of the two tables; the printed
  form is unchanged, one line per route, `→`-joined, ending at the terminal.
- **The specialization test** (`test/test_build.jl` lines 1675 to 1740)
  gains `terminal_producer`, `face_routes`, the membership accessor and the
  `LevelEntry` and `Child` constructors on `DECLARATION_LAYER`, and a fourth
  case over the sublist that takes no scalar: `build_opaque` of a model at
  nominal, the count, `build_opaque` of the same model with `activations =
  (Float64, FreshDual)` where `FreshDual = ForwardDiff.Dual{FreshTag,
  Float64, 1}` and `FreshTag` is a type the test file alone defines, so the
  activation has never compiled in the process, and the count again. The
  sublist excludes `declarations`, which takes the scalar and legitimately
  specializes per activation, and anything else on the list whose
  signature carries `::Type{T}`; state the sublist as a second constant
  beside `DECLARATION_LAYER`.
- **Measured at 90bf71d's parent**, warm, on `FannedLoops(20)`: sixty
  primitives, twenty-one levels, 101 input faces; the structure step 7.3
  ms, one resolution of every input face by linear search 0.25 ms. Nothing
  here is on a hot path; the cold review re-measures only if a stage's
  report claims a cost.

## Out of scope

- `descriptor`, the inspector, any JSON. The inspector's first session
  follows at this increment's tip (`pending.md`).
- The `Build`, `Outputs`, `Events`, `Schedule` and `Deployment` artifacts.
- Correcting the compile-cost harness under `docs/reports/`. The drift is
  noted in `pending.md` by stage 3 and nothing there is edited.
- Any spec or log edit beyond what the docs arc landed. A shape that
  contradicts D-315 is a stop-and-report.

## Reading, in order

- `docs/design/pending.md`, the increment 67 bullet, lines 16 to 26.
- `docs/design/decisions.md` D-315 (line 13181), then D-261 (10121), D-207
  (7530), D-257 (9896), D-270 (11020) and D-289 (12125), each with its
  2026-10-07 annotation where one was added.
- `docs/design/spec.md` §9.1, lines 3739 to 3882, the structure step and
  its product list; §9.2, lines 3935 to 4027 and 4135 to 4160, the `Build`
  and the rendering; §13.7, lines 9735 to 9772, the face routes; §6.1,
  lines 1223 to 1353, the one-level rule; §13.3, lines 9260 to 9333, the
  build primitives. Never read the spec whole.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/assembly.jl`, `### src/build.jl`,
  `### src/show.jl`, `### src/conditions.jl`, `### src/readers.jl`,
  `### src/devices.jl`, `### src/linearize.jl`, `### src/tracer.jl` and
  `### test/fixtures.jl`; "Authoring caveats" whole; "Naming"; "Running the
  suite". Never restate either in a commit or a comment.
- `src/assembly.jl`: the spelling helper `_terminal` (line 72), the
  resolvers (540 to 620), the structs (644 to 741), `index_of` (743), the
  walk's caches (764 to 790), `flatten_tree!` (902), `wire!` and the
  constructor (955 to 991), `_walk!` (999 to 1130, the wiring loops at 1075
  to 1124), `_claim!` (1135), `resolve_authored` (1205 to 1246).
- `src/build.jl`: `_outputs` (370 to 420), `Layout` and `cell_layout` (519
  to 599), `_root_input_cell` and `input_addr` (607 to 621), `_check_wires`
  (833 to 880), `compile`'s `in_group` (1415 to 1425), `_probe_input` (1576
  to 1590).
- `src/show.jl` lines 64 to 110 and 220 to 234; `src/conditions.jl` 350 to
  360 and 455 to 475; `src/readers.jl` 460 to 476 and 548 to 563;
  `src/devices.jl` 300 to 335; `src/linearize.jl` 340 to 352;
  `src/tracer.jl` 243 to 252.
- `test/test_assembly.jl`: the generic-holding comparison (405 to 420), the
  routes testset (592 to 617), the passthrough comparison (980 to 992), the
  mixed-tier wiring (1140 to 1150), the child-list testsets (1189 to 1240).
  `test/test_build.jl` 1675 to 1740. `test/fixtures.jl`: `Vehicle` and
  `SampledLoop` (1000 to 1040), `routed_pair` (1044 to 1050), `FannedLoops`
  (1052 to 1080), and `TransparentRoster`, the fixture the testset at
  `test/test_assembly.jl` line 266 builds.

## Stage 1: the rows and the functions, beside the tables

### The shape

`Child`, `LevelEntry`, `Structure.levels` and the per-level `wires`, recorded
in the walk and assembled by the constructor as "What is settled" says;
`terminal_producer`, `face_routes` and the membership accessor. Every
existing field stays, every existing reader is untouched, and the
constructor's signature grows by what the draft now carries. The `Structure`
docstring gains the level row and the two functions and keeps the rest for
stage 3 to strike. The `_children` call site (line 1055) is the one place a
level is entered; nothing else pushes a level path.

Probe before asserting, and report the numbers: build `routed_pair()`,
`Vehicle()`, `FannedLoops(2)`, the `twins` group of `test/test_assembly.jl`
line 1207 and `MultiRate()`, print `levels` and, for every row of
`in_faces`, `out_faces`, `in_routes` and `out_routes`, the functions'
answers beside it. Then probe the aliasing case, a `Group` exporting one
source under two faces with a sibling fed from the second:

```julia
aliased = Group((; pair = Group((; a = Gain(2.0));
                                input_wires = "u" => "a/e",
                                output_wires = ("a/out" => "y", "a/out" => "y_copy")),
                   b = Gain(3.0));
                local_wires = "pair/y_copy" => "b/e",
                input_wires = "u" => "pair/u", output_wires = "b/out" => "out")
```

Confirm it builds. Its root level's wires must hold
`("pair", :y_copy) => ("b", :e)`, the fact no existing table carries (both
`("pair", :y)` and `("pair", :y_copy)` resolve to `("pair/a", :out)`). If
two output faces from one source are refused at build, stop and report:
D-315's rationale rests on their being legal.

### Tests

New testsets in `test/test_assembly.jl`, after the routes testset, models at
top level or in the fixtures file (grep every new name across `test/`):

- "the structure holds one row per level, its children in order and its
  wires as declared (§9.1, §9.2, D-315)": on `routed_pair()`, `[l.path for
  l in levels] == ["", "pair"]`; the root's children `[("pair", :pair)]` by
  segment and field, `pair`'s `[("a", :a), ("b", :b)]`; the root's wires
  exactly `[("", :u) => ("pair", :u), ("pair", :y) => ("", :y)]` and `pair`'s
  exactly `[("pair", :u) => ("pair/a", :e), ("pair", :u) => ("pair/b", :e),
  ("pair/a", :out) => ("pair", :y)]`. On `Vehicle()`, the root's wires in
  declaration order, the local wire `("trim", :out) => ("loop", :ref)`
  first. On `aliased`, `("pair", :y_copy) => ("b", :e)` in the root's wires.
  `levels[1].instance === root` for each.
- "container membership is read off the segment and the field (§8.5,
  D-211, D-315)": `Vehicle`'s `trim` is `:field`; `FannedLoops(2)`'s
  `loops/l1` is `:container` with field `:loops`; `TransparentRoster((a =
  Gain(2.0), b = Gain(3.0)))`'s `a` is `:transparent` with the bare segment
  `"a"`.
- "the functions resolve every face at every level as the tables do (§9.2,
  §13.7, D-315)": for each of the five models, `terminal_producer` equals
  the `in_faces` and `out_faces` entry for every row, `face_routes` of each
  input face equals the `in_routes` rows for that face in order, and
  `face_routes` of each output face is the one `out_routes` row. This is the
  equivalence sweep; stage 3 removes its table side and keeps direct
  assertions in its place.
- "the resolution compiles once (§9.7, D-289)": deferred to stage 3's
  specialization test; stage 1 adds the new functions to
  `DECLARATION_LAYER` so the three existing cases already count them.

### Routing

`src/assembly.jl` and `test/test_assembly.jl` are the first row: run
`declare assembly build diagnostics leaves show` under the flags of
"Running the suite", in the foreground, 600 s per invocation.

### Bookkeeping, in the same commit

- `docs/design/implementation.md` `### src/assembly.jl`: one bullet after
  the flatten pass's, "`LevelEntry` and `Child`, one row per assembly in
  walk order with its children and its declared wires, and
  `terminal_producer`/`face_routes` over them (D-315)". Constructs, not
  behaviour. Stage 3 strikes the old bullets.
- `test/imports.jl`: whatever the new tests import, on the existing
  `import Redstone:` lines.

## Stage 2: every reader calls the functions

### The shape

Each site in "What is settled"'s reader list switches from the field to the
function, and the layout's alias pass gains the input side. The fields stay
until stage 3, so a site switched wrong fails its own tests, not a
`FieldError`. Order of work: `cell_layout` and `in_group` first, then
`_outputs`, `_root_input_cell` and `_probe_input`, then the tracer, the
linearizer and `show`, then `conditions.jl`, `readers.jl` and `devices.jl`.
`_mount`, `_resolve_entries` and `resolve_authored` read `levels` in place
of `root` and `child_lists`.

Two rules for every site. The declared faces of a primitive come from
`decls[ci].ins`, in its order, where `conns` gave them; `_outputs` and
`_root_input_cell` already hold `decls`, `_probe_input` holds `layout` and
takes `decls` if it needs them, `_seed_face` and the linearizer hold the
activation. And a function specialized on the scalar (`cell_layout`,
`_root_input_cell`, `_probe_input`, `_seed_face`, the linearizer's) calls
`terminal_producer` and never inlines the walk: the resolution is one call
on plain data, so the per-scalar compile grows by a call and nothing else
(D-289, D-315). The reviewer's fourth specialization case is written
against exactly this.

`port_views` builds its input views over every level's input faces (the
wire endpoints carrying the level's path, the primitives' faces from
`decls`, and the root inputs), each with `terminal_producer` as its source,
so the view set is unchanged: D-270's annotation of 2026-10-07 says so.

### Tests

Every switched site is covered by the files its row names, and stage 1's
equivalence sweep is the oracle. One new testset in `test/test_build.jl`,
"the layout aliases every input face onto its producer's cell (§9.2,
D-261, D-315)": with `addr = activation(build(Vehicle()), Float64).layout.addr`,
`addr[("loop/sum", :a)] === addr[("trim", :out)]`, `addr[("trim", :e)] ===
addr[("", :ref)]` and `addr[("loop", :y)] === addr[("loop/plant", :y)]`, the
input side and the output side of the alias pass. `activation` is the
accessor `src/conditions.jl` line 352 uses.

### Routing

The change reaches `build.jl`'s compile half, `conditions`, `readers`,
`linearize`, `tracer`, `devices` and `show`, so the routed set is the union
of the table's rows, which is the whole suite: run it all, under the flags,
in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`: `### src/build.jl`, the layout bullet
  says the alias pass enters assembly output faces and primitive input
  faces from `terminal_producer` and that `input_addr` is gone;
  `### src/devices.jl` line 398 reads "off `terminal_producer` over every
  input face at every level" in place of "off `Structure.in_faces`";
  `### src/show.jl`, the routes bullet says the lines are derived through
  `face_routes`; `### src/conditions.jl` and `### src/readers.jl`, one
  clause each where they name the face tables or the retained root.

## Stage 3: the tables go

### The shape

Remove `root`, `child_lists`, `in_faces`, `out_faces`, `in_routes` and
`out_routes` from `Structure` and `conns` from `ComponentEntry`. `wire!`
shrinks to what `_check_wires` consumes: it still derives the per-primitive
terminal list from `draft.feeds`, as a local the check reads and the
constructor never sees; rename it if "wire" no longer says what it does.
The constructor becomes `Structure(draft, root_types)`. Rewrite the
`Structure` and `ComponentEntry` docstrings to D-315's content: declared
facts as rows, the two functions, the layout as the address home, and the
sentence that no resolved table lives here. `index_of` stays.

The suite is the proof: a reader stage 2 missed fails to compile or throws
at its first call, and the full run finds it.

### Tests

- The equivalence sweep of stage 1 loses its table side. In its place, the
  routes testset at line 592 asserts `face_routes` against the literal
  routes it asserts today, and `terminal_producer` against the literal
  producers its loop derived.
- Line 414's comparison of two builds' `conns` becomes a comparison of
  their `levels`' wires; line 988's `out_faces` equality becomes equality
  of `terminal_producer` over the root's output faces; line 1145's `conns`
  helper becomes `terminal_producer` over the named faces, same literals;
  lines 1212 to 1214 read `face_routes`; the child-list testset at 1218
  reads `levels` and asserts the same segments and fields.
- `test/test_build.jl`: the fourth specialization case of "What is settled",
  with `FreshTag` and `FreshDual` defined at the file's top level and
  grepped across `test/` first. Its testset name: "nor does a new activation
  scalar, for the functions that take none (§9.7, D-289, D-315)".
- `test/test_show.jl`'s `Structure` testset: unchanged assertions, since the
  printed routes are unchanged; re-run it and say so.

### Routing

A field removal reaches every file that ever read it, so run the whole
suite, under the flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md` `### src/assembly.jl`: strike the flatten
  pass's bullets on `wire!` deriving the input side, on the routes and face
  tables, and the service-walk bullet's `Structure.child_lists` sentence;
  say the walk searches `levels`. `### test/fixtures.jl` gains a line if a
  fixture was added.
- `docs/design/pending.md`: the increment 67 bullet is removed. The bullet
  "An example model, large enough to measure on" gains one sentence: "The
  compile-cost report's harness (`docs/reports/20261001_compile_cost_reeval/probes`)
  drifted at D-313 and D-314: `Group` lives in `Redstone.Blocks` and its
  keywords are the declaration names; correct a copy before measuring, and
  leave the report as it is." `check_refs.jl` and `check_rows.jl` read this
  file; run the battery.

## The cold review

One fresh Opus reviewer over the three code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **D-315 against the tree.** No resolved table on `Structure`, no `conns`,
  `levels` in pre-order with the root first, wires per level in declaration
  order with the boundary face on the level's side, the layout the only
  place an address is stored, every reader a call. Grep `in_faces`,
  `out_faces`, `in_routes`, `out_routes`, `child_lists`, `\.conns\b`,
  `structure\.root\b` and `input_addr` across `src/`, `test/` and
  `docs/design/implementation.md`: zero hits outside the log's history.
- **Equivalence.** At stage 1's commit both forms exist: on a scratch copy at
  that tip, run the sweep over every zero-argument fixture of
  `test/fixtures.jl` that builds at nominal, not only the five models, and
  report any face where the function and the table disagree.
- **The aliasing fact.** The `aliased` model's root wires name `y_copy`;
  confirm a probe at the tip's parent shows the old tables could not.
- **Mutants on a scratch copy**, each named test going red: `face_routes`
  dropping the first hop; `terminal_producer` stopping at an assembly's
  output face instead of descending; the walk recording `last(route)` in
  place of `first(route)` for a local wire's producer; the alias pass
  skipping the input side (`in_group` must fail); the membership accessor
  reading `:container` for a transparent element; `levels` built in
  dictionary order instead of pre-order; a per-level `wires` vector in
  resolver order instead of declaration order; the fourth specialization
  case with `terminal_producer` given a `::Type{T}` argument it ignores. A
  surviving mutant is a missing test.
- **Specialization.** Run the extended test, then confirm by
  `Base.specializations` on a fresh process that `terminal_producer` and
  `face_routes` hold exactly one method instance each after building two
  models at two scalars.
- **The register and the docstrings.** `implementation.md`'s rows name
  constructs; the `Structure` docstring says what D-315 says and no more;
  the `pending.md` sentence on the harness is one sentence.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the routed subset's result with the
assertion count, the probe's numbers for every asserted value, and every
deviation from this brief with its reason.
