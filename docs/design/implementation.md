# Implementation status

The implementation of the framework in `spec.md`, grown one increment at a
time (increment 1, the cell-store bench, is frozen in
`prototypes/cellstore_bench`; D-162 cites its numbers). Spec and code are
peers: neither is subservient, and both are kept in agreement. This file is
the map, the traps and the naming rules; `pending.md` is what the code still owes the spec. Why
a given test asserts what it does is carried by the suite itself: every
testset name states its property and cites the section it answers to.

## What is real here

One entry per file: which constructs live where, and the sections they answer
to. For more, read the file itself and the sections it cites.

### `src/Cadence.jl`

The package module: the dependencies and the include order the other files load
in.

### `src/leaves.jl`

- The leaf walk includes the enum leaf, D-237's opaque leaf and
  `mutable_position`. `Symbol` counts among the opaque leaves by D-243. The
  walk covers flatten `flatten!` and `_mflatten_expr`, reconstruct
  `reconstruct` and `_mreconstruct_expr`, and the activation retype.
  - `Pinned` is the contract marker. It is defined here because the walk
    dispatches on it.
  - `retype_entry` strips the marker at the top of an entry alone (D-265). It
    sits over `retype`, which replaces each `Float64` position by the scalar
    and pins a mutable type's parameters (D-263).
  - `_holds_marker` finds a marker below the top.
- `leaf_names`' dotted spelling of a flat position, a matrix leaf by its
  indices.
- Embed-accept's relation `_accepts` (D-166). The relation is decided on the
  type (D-238). At a store it accepts an opaque leaf by identity (D-237). At a
  wire it admits an opaque leaf as the producer's cell (D-264).
- The wire relation `_accepts_wire`, with its abstract arm (D-236).
- The checked state write `flatten_state!` (D-235).

Spec: §4.1, §4.3, §4.4, §6.1, §7.1, §7.2, §8.2, §9.5, §13.4, D-166, D-235,
D-236, D-237, D-238, D-243, D-263, D-264, D-265, D-276.

### `src/diagnostics.jl`

- The diagnostic kinds. Each kind has `severity`, `path` and `message`.
- `_typename`, a user type's name for a payload field or a label.
- The `DiagnosticError` carrier, parametric on policy, with `diagnostic`,
  `diagnostics` and `kinds`, and the carrier's two renderings.
- The carrier holds the build's `warnings` beside the `carried` collection. A
  warning joins no collection, and both renderings end with one line per
  warning (D-250).
- `logline`.
- The build's warning channel `BUILD_WARNINGS`, with `_warn!` appending to the
  bound list or logging outside any build (D-250).
- The grid records `GridEntry` and `GridReport`. They are deployment
  substrate, defined here because the payloads naming them are. `GridEntry`
  carries the anchor's declaring scope and key, and `_anchor_label` renders
  the scope and key as every grid consumer names the entry.
- `DeploymentInvalid`'s `grid` payload and `GridUtilization`'s. `_grid_block`
  renders both as the structured block every grid consumer appends to its
  first line (D-187):
  - the pool table, with each entry's refinement factor and a driving
    offset's repair;
  - then the prime attribution, with its suppliers.
- `ArgumentInvalid` has arms off the deployment surface (D-256):
  - the materialization's `join_timeout`, the doors' `trace`, `log`,
    `log_every` and `log_max` (D-261) and `t_end` carry their constraint
    text and section;
  - `DeploymentInvalid`'s parameter set is Appendix C's row.
- The `Trim*` kinds `TrimProblemInvalid`, `TrimCommitEvents`,
  `TrimCommitResiduals` and `TrimCommitChecks` (D-262).
- `TapResolution`'s tap-set reasons `:tap_kind`, `:discrete_state`,
  `:vector_tap`, `:unseedable` and `:duplicate_site`, with the `list`,
  `pinning` and `duplicate_of` fields; `ReadSetMisuse`'s `:not_a_tap_list`;
  `ArgumentInvalid`'s `:not_a_tap_set`, `:t0_without_about` and
  `:nonpositive_width`, and its `:non_nominal` arm naming the service
  (D-272). A pinning consumer carries its tier, and a discrete one renders
  as unseedable by tier. Each `TapResolution` reason renders one citation
  group, its own.
- `TapResolution`'s and `ReadBindingUnresolved`'s leaf reasons
  `:leaf_syntax`, `:no_such_field`, `:opaque_leaf`, `:not_indexable`,
  `:index_arity` and `:index_bounds`, with the `leaf` and `step` fields.
  `_leaf_clause` renders the six for either kind (D-276).
- `TapResolution`'s `mount` field, which a mounted read's message names
  after the selector, and its `producer` field. The mount step's reasons
  `:no_input_face` and `:internally_wired`, the second naming the producer,
  and `:input_face_not_output` at every level (D-277).
- `TierUnreadable`, for a primitive declaring no store, sits beside
  `StatelessWithoutOutputs` (D-263).
- `InternalInvariant`.
- §13.4's runtime trio is `CursorFrame`, `StepError` and `NonfiniteState`.
  `StepError` is parametric on its cause, and `diagnostic` is defined on the
  species.
- §12.7's replay trio is `CheckpointMismatch`, `ReplaySchemaMismatch` and
  `ReplayUnknownFace`. `ReplayUnknownFace`'s `face` carries a bare position
  where no schema resolves it, and the name where one does.
  `CheckpointMismatch` is one kind for replay's entry pass and `restore!`.
  It keeps the root-input arm, for the fingerprint's face list and for a
  recorded value that does not convert (D-274). Its deployment arm has five renderings. The
  one for a schedule row names the component path and the column (D-255).
- `CheckpointMidFrame`, `checkpoint`'s refusal after a `t*` stop and after
  an abandoned frame, carrying the clock's `t`, the frame top `t_frame` and
  the frame index `frame` (D-274). Its message branches on whether the two
  times are equal.
- `StepError`'s `host` records which catch took the throw, `:boundary_zero`
  or `:loop`, since boundary zero and frame one share pointer 0. Its
  rendered recipe reads the host alone: `init!` under the same condition for
  a boundary-zero throw, and replay to the pointer then `step!` for a frame's
  throw at every pointer, 0 included (§13.4, D-274).
- `CheckpointMismatch`'s store arm also names a component's `x` type
  (`:x`), a cell (`port.<name>`) and the event list (`:events`). Its clock
  arm is `restore = false`'s own: the recording's `t₀` (`:t₀`) and the frame
  range the feed covers (`:frame`). `ArgumentInvalid` covers
  `replay!`'s `restore` and a halt before the feed's first frame, and its
  `:t0_without_about` names the checkpoint as the default operating point.

Spec: §9.1, §9.2, §12.6, §12.7, §13.1, §13.2, §13.4, §14.8, §14.9, §14.10, Appendix C,
D-058, D-059, D-157, D-187, D-214, D-215, D-222, D-225, D-250, D-255, D-256,
D-261, D-262, D-263, D-272, D-274, D-276, D-277.

### `src/declare.jl`

The declaration layer:

- Both tiers' name families.
- `Pinned`'s docstring and the one-arity `declared_at`. `declared_at` walks a
  continuous contract at its scalar and reads a discrete one as written
  (D-263).
- The bundle law, with the legal bundle sets `LEGAL_BUNDLE` and
  `classify_bundle_field` (§5.2, Appendix B).
- `probe_value`, with its enum arm (D-051).
- The connection declarations `inner_connections`, `u_connections` and
  `y_connections`, beside `transparent_container`.
- The rate forms `Period`, `Relative` and `Absolute`, with `sample_times`.
- The event surface `StateEvent`, `state_events` and `x_projection`.
- The declaration family `DECLARATION_FAMILY` and `foreign_declarations`.
- The readers of a component, `has_stage`, `_declares`, `declared_at`, the two
  bundle-name functions and `foreign_declarations`, take it unspecialized, so a
  new component type compiles none of them again (§9.7, D-289).

Spec: §2.1, §5.2, §8.1, §8.2, §8.5–§8.7, §9.3, §9.7, Appendix B, D-051, D-179,
D-185, D-195, D-211, D-246, D-248, D-263, D-289.

### `src/assembly.jl`

- Class by declaration shape `classify`, and `_contract`, which reads a
  contract at nominal with its pins stripped (D-263).
- Children and containers, with their collision family.
- The anonymous assembly `Group`, kernel material by decision.
- Paths and §6.1's one-level rule.
- Endpoint and face resolution, with the root's face invariants. The
  resolvers return routes, the hops `(path, face)` from an endpoint down to
  its terminal: one for a producer, one per consumer (§13.7).
- The flatten pass runs under one structure-step barrier (D-261):
  - `StructureDraft` accumulates the per-component columns the `Structure` is
    built from, among them the tiers, the rate chains and the fold's `Timing`s;
  - resolvers record into the step's list;
  - `wire!` derives the face graph's input side after the barrier, and the
    walk records the output side;
  - the `Structure` carries `in_routes` and `out_routes` beside the two face
    tables, one row per route at every level, and `out_faces` is their last
    hops;
  - `Structure.root_types` holds the root-input types the wire pass fixes
    ahead of construction;
  - as the step's last act, the artifact is built complete as rows at the
    barrier, with one `ComponentEntry` per primitive in walk order and one
    `Anchor` per `Absolute` entry.
- The sample-time fold.
- The shadowing check ahead of `classify` in the walk (D-246).
- The store-form gate ahead of the classifier in the walk (D-247).
- The component frame around the walk's two branches (D-248).
- §13.3's `resolve`/`resolve_terminal`/face-list primitives `input_faces` and
  `output_faces`. The walk records each assembly's evaluated face lists in
  `StructureDraft.faces`, and `flatten_tree!` binds them as `WALK_FACES` around the
  walk, so the primitives read them once per call (Appendix C) and evaluate a
  body only outside a walk. Beside it `flatten_tree!` binds `WALK_CHILDREN`, a
  fresh cache of each assembly's child list, so endpoint resolution derives a
  list once per walk rather than once per endpoint (§9.7).
- The service walk `resolve_authored` runs over the `Structure`'s retained
  root and reads declared holdings off the type definition (D-061, D-130).
- §8.8's `input_passthrough`/`output_passthrough`, with the three exclusive
  selectors `except`, `only` and `select`, and `EmptyFaceSelection` through the
  channel (D-251).
- The walk, the class and child readers, the resolvers and the build
  primitives take components, assemblies and the root unspecialized, and
  `_children` reads a container through `_elements` and `_element_keys`, so a
  new component or root type compiles none of them again (§9.7, D-289). A
  function that takes a connection or its endpoint tuple, as `_fanout` does,
  still compiles once per connection type.

Spec: §6.1, §8.1, §8.5–§8.8, §9.1, §9.2, §9.7, §13.3, §13.7, §14.2, Appendix C, D-061, D-130,
D-171, D-207–D-212, D-229, D-236, D-246, D-247, D-248, D-251, D-253, D-261,
D-263, D-289.

### `src/store.jl`

- Per-eltype cell stores `CellStore` and `CellAddr`. A handle type is its own
  eltype, as `leaf_types` in leaves.jl decides (D-237).
- The `StoreBundle`.
- Gather `gather_cell`/`gather_group` and the checked scatter
  `scatter_cell!`/`scatter_group!`. The scatter's check is §9.5's always-on
  check, decided at generation (D-235).
- `_cell_key`.
- The `Clock` (D-260):
  - its `t` is in the deployment's scalar;
  - its origin `t₀` is a `Float64`;
  - the constructor takes `t₀` and converts it into `t`.

Spec: §9.5, §9.7, D-162, D-235, D-237, D-260.

### `src/executor.jl`

- Entries `StageEntry`, `RHSEntry`, `UpdateEntry`, `EventEntry` and
  `ProjectEntry`. Each carries its component's path, for the write's
  diagnostic, and an event entry carries its event name beside the path
  (D-249).
- The chunked walk `Chunk` and `chunked_body`. `Chunk` is mutable, so a
  phase body holds one pointer per chunk and a barrier call loads one
  pointer. Every tuple walk, over a chunk's entries, a body's chunks, or the
  event set's chunks and their entries, unrolls through one generated body,
  `_unrolled`. Its twin `_unrolled_tuple` returns the elements as one tuple
  and serves the value-building walks of readers.jl, bindings.jl and
  conditions.jl.
- The interior/boundary split `PhaseBody`. A body with no gated entry has two
  tuples of one type and walks its interior at a boundary.
- The `(tick − Φ) % D` gate `Gated`, with boundary zero's `ESTABLISH` beside
  it.
- The event set, with its registers. It is mutable, so the executor holds it
  by reference. Its `entries` and `projects` hold `EventChunk`s, each a
  mutable chunk of entries, so their `length` counts chunks.
- The guard/fire/project walks `_guards!`, `_fire!` and `_projects!`, each one
  non-inlined call per `EventChunk`, over the executor's buffers the caller
  hands them (D-261).
- The execution cursor, which every entry stores into. The cursor holds its
  dispatch fields alone, and the loop's stop hit is `frame!`'s return value
  (§13.5, D-261).

Spec: §5.3, §9.5, §9.7, §10.4–§10.6, §13.4, §13.5, §14.5, D-059, D-205, D-235,
D-249, D-255, D-261, D-289.

### `src/build.jl`

- The user-code frame is `invoke_declaration`, `invoke_probed` and
  `at_component` (§13.2, D-248).
- Tier classification records what it finds instead of throwing. The walk
  reads the tier beside the class, and the store decides the tier.
  Classification records `StatelessWithoutOutputs` and runs the pinned-entry
  check, both from D-263. It also holds `IllegalPortType`'s nested-marker arm,
  on both tiers (D-265).
- `build` owns the structure step's one throw.
- `build` binds the warning channel once around its three steps (D-250):
  - a `DiagnosticError` leaving the build is rewrapped with the warning list,
    and any other throw passes unchanged;
  - a completed build logs each warning once at return.
- `build`, the user-code frame, the declaration checks and the probes take
  components and the root unspecialized, and each per-component frame reads
  the instance inside rather than capture it, so a new component or root type
  compiles none of them again (§9.7, D-289).
- The wire pass (D-236) checks both type clauses, at `Float64` and at the
  marker scalar. It retypes the contracts at each. It also fixes the
  root-input type, which has two refusals, `AbstractAtRoot` and
  `RootInputTypeConflict`.
- The store-form check `check_store_form` (§8.2, D-247), the store isbits
  check (§7.3, D-231) and the state-leaf vocabulary check (§7.1, D-094).
- The probe and the event probe. The dead-stage rule applies at both stage
  probes, and `cell_layout` raises `MissingProbeValue` (§9.3).
- `ProbeTag`/`ProbeDual`, the canonical probe scalar (§9.4).
- The probe's embedding of products, `_embed`.
- `_probe_direct!`, shared with the classifier's prefix probe.
- The feedthrough graph, the builder's scratch. Each edge keeps its port and
  face.
- Kahn's execution order, written into the `Outputs` (D-261):
  - one `ComponentOutputs` row per component, in walk order, holding its path
    and the two stage name lists;
  - the order beside the rows, as `ci`s;
  - `_ports`, which concatenates a row into the products' order.
- At a stall, the SCC decomposition into one `AlgebraicCycle` per cluster
  (§5.6, D-012).
- The layout, with the root-input meet (D-168, D-236), `IllegalPortType`'s
  three layout arms (D-237) and the flat `x` ranges every offset is read from
  (D-261).
- The nominal evaluation `_nominal`. It returns the `Outputs`, the `Events` and
  the nominal activation. The `Events` hold one `ComponentEvents` row per
  component, with its path, policies and bundle.
- `_activate`, for every other scalar.
- The `Build`, holding the structure, the outputs, the events, one activation
  dictionary and `warnings`. `activation` reads that dictionary, and
  `warnings(::Build)` sits beside it.
- `compile`, which turns the deployment's `Schedule` into an `Executor{T}`.
  It derives the per-component gates from the schedule's rows (D-261). The
  executor takes its name lists from the products.
  - An executor is one activation's buffer set, with the bodies closed over
    it. Each set has one owner. `evaluate!`, `_round!` and `apply!` run on it.
  - The executor owns its stepper, its arrival buffers, the `chunk_size` it
    was compiled at and the localized-event key (D-256). `compile` builds the
    stepper from the `algorithm` keyword.
  - The event set takes the phase bodies' chunk size (D-289).

Spec: §5.3, §5.5, §5.6, §6.1, §7.1, §7.3, §8.2, §9.1–§9.4, §9.7, §10.4, §13.2,
D-012, D-051, D-094, D-166, D-179, D-208, D-210, D-229, D-231, D-235, D-236,
D-237, D-247, D-248, D-250, D-252, D-253, D-256, D-261, D-263, D-265, D-289.

### `src/tracer.jl`

- `Tracer{S}`, §5.6's set-propagation scalar. It is global on `true` and local
  on `false`, and `Undecidable` is the marker between them.
- The leaf-wise lift and tag walks `_lift`, `_tag` and `_sample`.
- `_classify`, the schedule-free per-member trace at the probe point, with its
  prefix probe, D-245's port-graph verdict and the sampled fallback at a fixed
  seed.

Spec: §5.4, §5.6, §9.3, D-012, D-140, D-245.

### `src/readers.jl`

- The closed read-selector family `get_state`, `get_deriv`, `get_output`,
  `get_input` and `get_face`, each taking a leaf address as its `leaf`, a
  `Symbol` the short form of a plain name (D-276).
- The mount step (§14.9, D-277). `Reads` carries its mount chain as
  `prefixes`, and `_mount` walks it from the root, each prefix from the
  level the previous one reached (§13.3), to the mount path and the level
  there, reporting a failed chain once. `_rebase` then turns each selector
  into a `MountedRead`: the selector as authored, the mount, the
  root-authored selector and the head and steps of its leaf. A path
  selector's path is walked from the mount level and joined to the mount.
  `get_input` matches an input face of the mount level and follows the
  export chain to its root input. `get_face` matches an output face of the
  mount level and becomes `get_output` of the port behind it. The callers
  rebase and resolve one selector at a time, so the collected list keeps the
  authored order, and the resolvers read the rebased selector.
- The leaf address (D-276). `parse_leaf` splits it at resolution. On a face
  selector `match_leaf` matches the head against the face list instead, since
  a face name may hold a dot. `resolve_leaf` checks each step against the declared type and returns the
  chain or a `LeafRefusal`, the six leaf reasons any kind wraps. `walk_steps`
  runs the chain as `getfield` and `getindex` calls unrolled at generation.
  A step is an `AccessStep`, and a condition's tree position is a tuple of
  the same steps, so the specialized `apply!` runs on the same walk.
- `reads` and `Reads`.
- The internal `_compile_reads`, which yields a `Reader{T}`. Each entry carries
  its chain as a type parameter, and the `CellRead` core reads a store bundle,
  so every gather over a table shares it.
- `gather_reads`, `apply!`'s twin over an executor. It reads its entries
  through the generated `_read_entries`, which `gather_snapshot` shares.
- The output-port candidates, read off the `Outputs`.
- Activation identity on readers, checked as an internal invariant. The same
  check on plans sits in conditions.jl's `apply!`.

Spec: §13.1, §13.3, §14.1, §14.4, §14.7, §14.9, §14.10, D-125, D-130, D-253,
D-276, D-277.

### `src/sim.jl`

- §13.5's block (D-203, D-255):
  - the four termination sources `EndTimeReached`, `ModelRequestedStop`,
    `ControlRequestedStop` and `LoopError`;
  - `StopPolicy`, the immutable value each advance declares, holding `t_end`
    and the stop faces alone;
  - the termination record, which carries the terminating advance's policy
    beside its source and the tail's residue.
- `Run{T}` holds §12.6's run state in four fields (D-255, D-260):
  - the log and the trace, fixed by the door that built the run;
  - the trace is `nothing` under §11.5's switch, which rides on the run;
  - the two fields the run evolves, the attached recording and the termination
    record the tail writes;
  - `closed(run)` sits beside the termination record;
  - the origin, the stop policy and the mode are not fields of the run;
  - the clock holds `t₀` as a `Float64`, each advance carries its own policy,
    and `mode(sim)` reads the feed.
- The mutable `Simulation` holds five fields, the deployment, the executor, the
  run, the plane and the control, and every other value belongs to one of them
  (D-256, §12.1).
- The materialization `Simulation(deployment, T)` takes `join_timeout` and
  `chunk_size` alone, and checks `join_timeout` under `ArgumentInvalid`. Its
  placeholder run is an empty log and no trace. The placeholder run carries no
  configuration.
- The four recording keywords belong to `init!`, `restore!` and `replay!`,
  for the run each builds. There `_check_recording` validates them under
  `ArgumentInvalid` at the door's `call`. The door hands them to
  `_open_run!`, which reads nothing off the run the last door left.
- `trace(sim)` refuses on the lifecycle before it reads the switch.
- The materialization builds the plane without the run, and no drain thunk is
  compiled before a door or a roster change (D-261).
- The two sugar forms `Simulation(::Build)` and
  `Simulation(::AbstractComponent)`, defined as the composition (D-254).
- `warnings(::Simulation)`, as the concatenation (D-250).
- The boundary macro-sequence.
- The §10.6 event phase, with its `FiringBudget` degradation.
- `init!`, `restore!`, `run!`/`step!` and `replay!`. `run!` and `replay!`
  share the one run body, and `init!`, `restore!` and `replay!` are the three
  doors that build a run (D-274):
  - `init!` takes the trace header after boundary zero's first publication;
  - `restore!` checks the fingerprint, restores the state and publishes one
    snapshot, with no boundary zero;
  - `replay!` is a restore of the trace's header plus the feed, the loop's
    one substitution; its `restore = false` form attaches the feed to the
    simulation as it stands, and its entry pass also checks the simulation's
    clock against the recording's.
- `checkpoint(sim)`, the stopped-sim service. It is refused unless the clock
  sits on a grid time and the latest snapshot is of that boundary, which
  excludes a `t*` stop and an abandoned frame.
- `_open_trajectory!` and `_open_run!`. `init!` opens the trajectory whole;
  `restore!` and `replay!` take the parts that are neither the clock nor the
  priors.
- `attach!`/`detach!`. `attach!` builds the handle with the build's
  `Structure` and the nominal `Layout` (D-270).
- The pause verbs `pause!`/`resume!`/`paused`, beside `stop!(sim)` (§12.1,
  D-268).
- The pacing verbs and the `Pacer` (§10.7, §12.1, D-269):
  - the pacing verbs `pace!`/`margin!` and the readers `pace`/`margin`, beside
    the pause verbs;
  - `run!` and `replay!` take `pace` and `margin` as keywords, validated per
    call under `ArgumentInvalid` and written at entry;
  - the run body creates the `Pacer` per `run!` call, and the `Pacer` is
    threaded the way the policy is;
  - the pacer is anchored as the loop starts, re-anchored at un-pause, waits at
    the frame top after the yield, and is carried to every publication;
  - `step!` passes no pacer and never waits.
- §12.2's thread-budget check `report_thread_budget!` runs at the run body's
  top after the freeze, so either door checks once against the frozen roster
  and `step!` never does (D-027).
- Staging/drain/publication, with the drain's replay substitution, and the
  run's roster (§11.3):
  - the run body and `step!` copy the roster after the freeze, and thread the
    copy the way the policy and the pacer are threaded;
  - the drain, the status, the account reset, the thread-budget check, the
    init bracket and the tail's sweep read the copy, never the plane's;
  - the doors pass the plane's roster to their publication, and every
    stopped-sim reader reads the plane's.
- Publication reads each device's `task_state` off `run_tasks` (§12.2,
  D-270). A device with no registered task reads `:done` inside a run and
  `:none` outside one, by the sticky status. `_run_body!`'s `finally`
  removes the inline entry when its body returns, under `wake`'s lock, and
  `_await_loop` removes it again inside its `try` on the arm's call, since an
  interrupt can cut the first removal short.
- §12.6's input mode (D-260):
  - `mode(sim)`, `to_time` and `live!`;
  - the mode is read off the run's `feed`, so a change of mode is a write to
    the run, never a change of run.
- The `StopPolicy`, which each advance builds and validates per call and then
  carries as an argument, from the call through the frame loop to `_record`'s
  assembly. The faces' compiled addresses sit beside it as the loop's own. The
  `t*` hit comes back as `frame!`'s return value.
- `t_end` and `stop_on` are keywords of `run!`/`replay!`/`step!`, never of the
  constructor, and `run!` raises the unbounded run's advisory (D-255, D-260,
  D-261).
- The lifecycle and the termination record.
- The frame loop's one catch site, with the species rule. The species rule
  holds the runtime bundle-field match (§13.2, §13.4, D-248). The match reads
  its stage-1 names off the `Outputs`. The catch site also holds the interrupt
  carve-out. The catch site's second host `_host_boundary_zero!` sits around
  boundary zero. Both hosts reach the one constructor `_wrap_step` and set
  the carrier's `host`, the frame loop to `:loop` and `_host_boundary_zero!`
  to `:boundary_zero`.
- §12.4's mask and the handling around it (D-268):
  - the mask spans each frame's boundary sequence, with the frame's `try`
    inside it;
  - the unmask points sit at the mask's end and at the frame top, the pause
    block among them;
  - a deferred interrupt yields to a holding face;
  - a frame that throws with an interrupt pending ends `errored`;
  - the masked bookkeeping sits in `run!`'s and `step!`'s outermost `finally`;
  - the `running` store is the first statement of the `try` that `finally`
    closes, so no interrupt leaves the lifecycle `running`;
  - the loop's throw is stored before anything can cut the failure arm, and
    the masked bookkeeping builds the `LoopError` from it, in `run!` and
    `step!` alike;
  - the spawns and their registrations are masked, in the calling-task
    topology through the loop's spawn, so a deferred interrupt raises with
    every task bound and registered;
  - `run!`'s outer catch takes a stray interrupt as the stop. Its head runs
    masked: the fallback source, and with no loop to await the stop request.
    An interrupt arriving within the head raises at its unmask and the head
    reruns. Where the loop was spawned and has not returned, the arm
    awaits it through `_await_loop`, so `run!` returns only after the loop
    ends, and a loop failure found there takes the failure arm's one
    handling. `_await_loop` issues its stop request inside its `try` and
    retries it when an interrupt cuts it short, so a later interrupt never
    reads as the loop's failure. On the arm's call it first removes the
    inline body's record the same way, then requests the stop without
    waiting for an interrupt, and it returns a loop failure as a value
    built inside the `try`. Where the tail had not run, the arm runs it
    unmasked and retries it from where an interrupt cut it, so none leaves
    the tail: the direct release advances a cursor per entry, `_tail!`
    retries its collapse's reports past the entries settled and lets no
    interrupt out, and a flag keeps a later step's retry from running
    `_tail!` again. The arm shuts the inline entry down when its wrapper
    never ran `shutdown!`;
  - `run!` reads §13.4's disposition off the roster, and `step!` always
    rethrows.
- The seam's `isfinite` sweep over `x`, the boundary's first act.
- The accessors `lifecycle`, `mode`, `termination`, `latest`, `logged`,
  `trace`, `port`, `state`, `modes` and `phase_bodies`. `logged` returns a
  vector typed by the run's concrete snapshot type,
  `Snapshot{T,typeof(sim.exec.store)}`, empty or not.

Spec: §10.2–§10.7, §11.1–§11.5, §11.8, §12.1–§12.7, §13.2, §13.4–§13.6,
§14, §14.5, §14.6, D-027, D-059, D-101, D-157, D-203, D-218, D-219, D-221,
D-223, D-232, D-233, D-248, D-250, D-253, D-254, D-255, D-256, D-260, D-261,
D-268, D-269, D-270, D-274.

### `src/stepper.jl`

The seam's backend side: RK4 and Heun, the retained `startpoint`, dense output.
`checkpoint_stepper` and `restore_stepper!` are the checkpoint's hook pair,
empty for both methods, which hold nothing across a frame top (D-274).

Spec: §10.2, D-017.

### `src/deployment.jl`

- Deployment binding and its two artifacts (D-254), the `Schedule` and the
  `Deployment`. The binding is `bind_schedule`, with `_exact`/`_as_int`.
- The typed `Schedule`, over `ScheduleEntry` and `ScopeEntry` (D-261):
  - the anchor and rates columns beside `(D, Φ, Δt)`, in `ScheduleEntry`;
  - the rate-scope rows, in `ScopeEntry`;
  - `_gates`, which derives the per-component triple the executor compiles
    over from the rows at `compile`.
- The `Deployment` holds the build plus the grid parameters `h`, `N_base` and
  `Δt_base`, the algorithm and the three event parameters `firing_budget`,
  `localization_tol` and `localization_budget`. It is scalar-free. The
  `Deployment` constructor has one throw per call (§9.2, D-229).
- `==`/`hash` on a `Deployment` compare by value over everything but the
  build, the grid attribution and the warnings (§12.7).
- `warnings(::Deployment)`.
- The grid attribution `_grid_report` (D-187):
  - the constraint pool, with each entry's leave-one-out refinement factor;
  - the prime attribution of `gcd(pool)`'s denominator;
  - a driving offset's nearest non-refining neighbours.
- `_grid_report` runs once per call, ahead of the `Δt_base` branch. The
  `Deployment` carries its result. The call also hands that result to the
  three refusals whose remedy is a `Δt_base` the pool admits, and to the
  derivation path's info line.
- The derivation path's info line shows the derived value over the same block,
  with both attribution forms. The derivation path also raises the
  `GridUtilization` advisory at `min_i Dᵢ > 1`.

Spec: §9.2, §10.5, §12.7, Appendix B, Appendix C, D-187, D-227, D-229,
D-250, D-254, D-256, D-261.

### `src/localization.jl`

- The frame loop, with the arrival sweep, the θ = 0 validation, ITP
  bracketing `_crossing`, `t*` boundaries, the localization budget and the
  `ChatteringBudget` degradation.
- The cursor's arrival/validation/trial phases.
- §13.5's stop-face read at every `t*` publication (D-261):
  - the read is off the policy and the addresses `frame!` carries;
  - when a face holds, the frame's remainder is abandoned and the face is
    returned.
- The run's pacer, carried beside the policy and the addresses to the `t*`
  publication for its record (§10.7, D-269).

Spec: §10.2, §10.4, §10.7, §13.4, §13.5, D-018, D-059, D-133, D-255, D-260,
D-261, D-269.

### `src/dataplane.jl`

- The compiled writer `Writer` and `Batch`, and the staging cells.
- The per-writer drain `_drain!`, which sim.jl's `drain!` reaches through the
  roster's thunks.
- The typed diagnostic kinds and the diagnostic cells.
- `KINDS`, the closed set's one home. The union `DiagValue` and `KindCounts`'
  field order are built from it.
- The diagnostic kinds include:
  - `UnboundedRun`, the loop's own advisory (§13.5, D-255);
  - `EmptyGreedyClaim`, declared with the service kinds and reported by
    `attach!` into the roster entry's own cell (§11.3, D-250);
  - `DebtReanchor`, the pacer's forgiveness on the loop's own cell (§10.7);
  - `ThreadBudget`, the run-top tightness warning on the loop's own cell
    (§12.2, D-027).
- Snapshots, and the log with re-decimation. The log stores the box
  publication made, which `log!` takes `@nospecialize`d beside its concrete
  type, so the two `boundary` reads stay static (§7.5).
- The published `FrameworkStatus`, which every snapshot carries. It holds the
  per-writer records `WriterStatus` and, beside them, the pacer's frozen
  `PacerStatus` (D-269):
  - the `PacerStatus` reads `Inf` and zeros where no pacer runs;
  - the copy off a live `Pacer` is control.jl's.

Spec: §10.7, §11.1–§11.4, §11.8, §12.2, §12.4, §12.6, §13.2, §13.5, D-023,
D-027, D-038, D-137, D-250, D-255, D-269.

### `src/checkpoint.jl`

- `Checkpoint{T}`, the executor's state at a frame top (D-274): the flat
  buffer, the `s` and `m` stores, the signal table with every cell buffer
  copied, the guard priors, the clock in full (`t`, the frame index, the
  boundary ordinal and `t₀`, a `Float64` like `h`), and the fingerprint, the
  run's `Deployment` and the structural layout `Fingerprint`.
- `Fingerprint` holds the cell sizes, the root-input faces, the component
  paths and the store types, and what a copy by position relies on: each
  component's `x` type, every cell's address with its type and offsets, and
  the event list, taken from the list that sizes the priors.
- What stays out: the derivative buffer, the arrival pair and the
  localization samples, which every frame rewrites before reading them, the
  cursor and the periphery.
- `_take_checkpoint`, the one read, behind `checkpoint(sim)` and the trace
  header `init!` takes. `_restore_state!`, its inverse, behind `restore!`,
  `replay!` and `linearize`'s default operating point. It is strict about
  the scalar. `_restore_stores!` is the part of it that writes the `s` and
  `m` stores, shared with `linearize`'s seeded half.
- `_check_checkpoint!`, the fingerprint check `restore!` and replay's entry
  pass share, collecting `CheckpointMismatch`.

Spec: §11.5, §12.6, §12.7, §14.10, D-038, D-254, D-273, D-274.

### `src/trace.jl`

- The input trace:
  - the mutable `Trace{T}`, holding its header, two lists that grow in
    place, namely the writers' schemas and one sparse record per drained
    batch, and the length a replay reads its bound off, which is also the
    ordinal each record carries and which the drain advances at its top
    (D-255, D-260);
  - the header is a `Checkpoint{T}` written once. `init!` writes it after
    boundary zero's first publication, and `restore!` and `replay!` open
    their run with the checkpoint they restore. It is `nothing` only between
    `init!`'s opening of the run and that publication (D-274).
- `_install_writers!` (D-261):
  - the growth rule;
  - the one site a drain thunk is compiled at, against the executor's store
    and the run's trace that `_install_writers!` takes as arguments, with the
    appended range as a local (D-260).
- `trace(sim)`, defined in sim.jl, which hands back a detached value, the
  checkpoint copied.
- Replay's up-front entry pass, run by `_compile_feed` in sim.jl. It validates
  the header, the schemas and the records. Both stages, `_check_checkpoint!`
  with `_check_schemas!` and then `_compile_records!`, collect (D-217). The
  pass builds the `ReplayFeed` the drain reads.
- The entry pass checks the checkpoint's deployment with one `==`, and
  `_walk_deployment!` names what the `==` refused, the schedule's rows and
  scopes by path and column (§12.7).

Spec: §11.5, §12.6, §12.7, §14.5, D-029, D-038, D-101, D-176, D-217, D-218,
D-254, D-255, D-260, D-261, D-274.

### `src/roster.jl`

- Device/binding traits and conformance `check_binding` and `check_device`.
- The roster, whose entries work as follows (D-261):
  - each entry keeps the device, its stable id, its thunk, its abort policy
    `should_abort`, its account and its handle;
  - each entry reads its binding, writer and diagnostic cell through the
    handle by `_handle`'s typeassert.
- Both claim sources and the harness writer.
- §11.5's drain thunks, beside the claim sources and the harness
  writer (D-260, D-261):
  - `DataPlane(layout)` compiles none;
  - the plane's harness thunk is the `_no_drain` sentinel until a door or a
    roster change compiles it;
  - `reclaim!` takes the store and the run's trace from `attach!` and
    `detach!` rather than reading either off the plane.
- The loop is a writer too, so the plane holds the loop's diagnostic cell
  and account, and §11.2's published holder with them (D-256).

Spec: §11.2, §11.3, §11.4, §11.5, §11.6, §11.8, §12.4, D-255, D-256, D-260,
D-261.

### `src/bindings.jl`

- `TableBinding`.
- `map_input`, generated over the datum's keys with one `_map_channel` call
  each, and the conditioning helper `_condition`.
- Binding reads `ReadGather`, resolved at attach by `_compile_gather`.
  Resolution raises `ReadBindingUnresolved` and enforces the source rule.
- The three table members take a leaf address, parsed and resolved by the
  family's `parse_leaf` and `resolve_leaf`, a face selector's head matched
  by `match_leaf`. `ReadGather` holds the family's
  `CellRead` entries, and `gather_snapshot` runs `_read` over the
  snapshot's store (D-276).
- The candidates on the two name-shaped read misses (§14.4).

Spec: §11.2, §11.4, §11.6, §14.4, D-276.

### `src/control.jl`

- The control plane (§12.1) and the pacer riding on the control plane (§10.7).
- `Control` keeps:
  - the stop word, with the pause flag beside it;
  - the two pacing knobs `pace` and `margin`, which the loop reads only at
    frame top (D-269);
  - the lifecycle;
  - §12.3's `counter` and condition `wake`, which devices.jl's
    `wait_next_snapshot` waits on;
  - the shutdown cap `join_timeout` (D-256).
- `_request_stop!` is the stop word's one write path (D-203):
  - the first CAS from empty wins;
  - the notify wakes a paused loop.
- `wait_resume!` is the pause block (§12.1, D-268):
  - `resume!` and every stop request wake the block;
  - the tail's `_finish!`, defined in devices.jl, clears the pause flag;
  - the block returns whether it parked.
- The two lifecycle gates `assert_stopped` and `assert_configurable`, one for
  the readers and one for the roster (§11.3, D-232).
- The `Pacer` holds one `run!` call's schedule and counters. It is never a
  field of anything. `anchor!`, `reanchor!` and the monotonic wall clock
  `_wall_now` sit beside it.
- `wait_deadline!` is §10.7's pacer wait. It runs the hybrid sleep-then-spin
  toward the deadline off the anchor, and `margin` is the one knob of the
  sleep-then-spin. The coarse phase is a task-yielding `sleep` (§12.2, D-027)
  and an unmask point (§12.4), and the spin never yields but takes a safepoint.
- `wait_deadline!` leaves an overrun as debt, counted where the debt grew,
  and re-anchors the pacer in two cases (D-021, D-269):
  - once the debt passes `5·h/p`, a re-anchor forgives the debt and reports
    `DebtReanchor` into the loop's cell;
  - a live pace change re-anchors forward, `Inf` included.
- The copy `PacerStatus(::Pacer)`. The `PacerStatus` record is dataplane.jl's.

Spec: §10.7, §11.3, §12.1–§12.4, §12.6, D-021, D-027, D-203, D-232, D-255,
D-256, D-268, D-269.

### `src/devices.jl`

- The device contract `init!`, `shutdown!`, `unblock!` and `loop`.
- The handle (D-261):
  - it holds the binding, the writer, the diagnostic cell and the compiled
    gather;
  - it holds the plane's exclusivity index by reference, never the plane;
  - it holds the build's `Structure` and the nominal `Layout` by reference,
    for the panel kit's bake alone (D-270);
  - the handle's stable id is the roster entry's.
- The handle primitives read the control plane that control.jl defines.
  `running` reads the sticky status, and `wait_next_snapshot` reads the
  counter and the condition.
- The primitive `pending` reads the handle's own staging cell, dataplane.jl's,
  with one acquire load and never takes it (§11.7).
- The panel kit, §11.7's framework half (D-270):
  - `PortView`, one port's baked verdict, its address field abstract;
  - `port_views(handle)`, the `Dict` of views keyed by `(path, port)`, one
    per input face at every level, off `Structure.in_faces`, and one per
    produced cell;
  - `peek_port`, the peek rule over `pending` and the snapshot;
  - `incumbent_status`, the incumbent's `WriterStatus` by `who`, and
    `orphaned` on it, exactly `task_state === :done` (§12.2). A crashed
    loop's task ends `:done`, since the wrapper catches the crash.
- The task wrapper.
- The init bracket, with its interrupt arm. An `InterruptException` in `init!`
  sets the `:interrupt` stop in place of `DeviceCrash`. The bracket lists each
  entry in the run's own list before its `init!`, so an interrupt escaping the
  bracket leaves no initialized device unreleased.
- `report!(entry, DeviceCrash(…))`, the crash report addressed by the roster
  entry (§12.4). The wrapper and the init bracket both file through it. It
  writes the entry's cell with no attachment check and no heartbeat.
- The tail under `join_timeout`, which `Control` carries (D-256). An interrupt
  reaching the tail collapses the remaining joins into `DeviceJoinTimeout` by
  name (D-268).
- `ResidueRecord` sits beside the sweep that builds it after the tail (§13.5,
  D-203).

Spec: §11.1, §11.3, §11.6, §11.7, §12.1–§12.4, §13.5, §13.6, D-198, D-203,
D-233, D-244, D-256, D-261, D-268, D-270.

### `src/conditions.jl`

- `condition`, the fragment function's generic (§14.2, Appendix B).
- The condition algebra `fragment`, `at`, `combine` and `override`. `at`
  also lifts read sets, joining the prefix to their mount chain; trim.jl
  and linearize.jl add its methods for problems and tap sets (D-277).
- The export chain's lookup, `_input_faces_at` and `_face_producer`, shared
  by a condition's `u` entry and the read side's `get_input` (D-277).
- One collecting pass behind both ways of applying a plan. Each `at` prefix is
  walked from its authoring level (§13.3). The two ways are:
  - `resolve_condition`, for values;
  - `compile_plan`, with lenses run by `walk_steps` (readers.jl),
    `SpecializedPlan`, whose writes and prefixes `apply!` walks as generated
    unrolls, and `ConditionShapeDrift`.
- Root-input totality `assert_total`.

Spec: §9.5, §13.1, §13.3, §14.1–§14.6, §14.9, Appendix B, D-063–D-068, D-117,
D-130, D-204, D-205, D-207, D-226, D-277.

### `src/trim.jl`

- `TrimProblem`, with its `checks` and `check_tolerances` defaulting to
  empty (D-262).
- `at` on a `TrimProblem`, field by field: the condition post-composed, the
  read set mounted, the path-free fields and a `reads` that is no read set
  passed through (§14.9, D-277).
- The `solve` seam, with `LevenbergMarquardt`.
- `trim!`, over D-213's two-half scratch world.
- The frozen copy, over the `Outputs`' port list.
- `TrimReport`, with its `committed_checks` (D-262).

Spec: §9.6, §13.1, §14.5–§14.9, D-070, D-158, D-213, D-224, D-253, D-262,
D-277.

### `src/linearize.jl`

- `Taps` and `taps`, three labeled selector lists with closed membership.
  `at` on a `Taps` mounts the three lists (D-277).
- `LinearizeTag`, `LINEARIZE_WIDTH` and `LinearizeDual`, the default width's
  pre-materializable scalar.
- `Linearization`, the operating point and the four matrices under the tap
  labels.
- `linearize`, over D-213's two-half scratch world in passes of `width`
  directions, the seeds written at the resolved taps' own sites.
- The default operating point is `checkpoint(sim)`, restored into the
  nominal half with no resolve, no `apply!` and no establishment round, so
  the frozen cells are the checkpoint's held cells. The `about` form keeps
  the resolve, the `apply!` and D-213's round (D-274).
- The collecting tap resolution, with the discrete store, the vector leaf,
  the member in the wrong list, the unseedable root input and a second seed
  at one site refused. The unseedable root input names its pinning consumers
  with their tiers, the duplicate the earlier label.
- At a mount the collecting tap resolution mounts each list. The kind check
  reads the selector as authored, and a chain that fails is reported once
  across the three lists. The pinning meet sees the root input the chain
  landed on, and `:no_input_face` and `:internally_wired` join the refusals
  (D-277).
- A seeded tap reaches its scalar through one index step at most, and a
  `.name` step is unseedable (D-036). The seed site is the leaf's linear
  place on the `x` and `u` lists alike, so `[k,l]` seeds the entry its
  linear `[k]` names and the two spellings are one site (D-276).

Spec: §9.7, §14.4, §14.10, D-036, D-167, D-168, D-197, D-213, D-272, D-274,
D-276, D-277.

### `src/show.jl`

- Each artifact renders through `show`, with no accessor beside the
  rendering.
- `Structure`, `Outputs`, `Events`, `Schedule`, `Build` and `Deployment` each
  have the compact one-line form and the `MIME"text/plain"` tables. That makes
  twelve methods over one `_lines` per artifact.
- The `Outputs` and `Events` tables, with the `Build`'s `feedthrough:` line
  between them (D-261):
  - each table prints each row's path, with no label function, and the
    `Events` table holds only the components that declare an event;
  - `_feedthrough` derives the line's edges from the structure's connections
    and the producers' stage-2 names.
- The `Structure`'s `input routes:` and `output routes:` blocks after the
  anchors, one line per route of a root face, its hops joined with ` → `
  (§13.7). A side with no root face prints no block.
- The `Schedule`'s hyperperiod chart, over `lcm(Dᵢ)` base ticks, with its
  binary guard at 100.
- The `Deployment` sets `_grid_block`'s lines under `grid:`.
- The published `FrameworkStatus`'s two forms. The `MIME"text/plain"` form
  prints one block per writer and the pacer's line last. It prints each
  writer × kind in full up to `STATUS_MAXLOG` cumulative occurrences, and
  count-only past it.

Spec: §9.2, §11.8, §13.7, D-136, D-257, D-261.

### `test/fixtures.jl`

The suite's fixtures:

- The coverage component set.
- The named assemblies.
- The devices and bindings.
- The `condition` methods, the fragment-function idiom over the framework's
  generic. The generic lives in `src/conditions.jl`.
- `Pendulum`.
- The `ForgottenImport` module and the forgotten-import fixtures `Inventory`,
  `Update`, `Events` and `Rates`, which import nothing, and
  `PassthroughOverForgotten`.

All of them are user material, and no name here is known to `src/`.
`test_build.jl`'s `Dual` sweep builds every fixture with a zero-argument
constructor at `ProbeDual` (§9.4, D-280), and `DUAL_PINNED` lists the four
pinned on purpose, which it must refuse.

### `test/imports.jl`

The suite's `import Cadence:` list, shared with `repl.jl` — the one place a
framework name the tests call or extend is admitted.

### `test/repl.jl`

The REPL bootstrap: `julia --project=test -L test/repl.jl` loads the list and
the fixtures into `Main`.

Correctness is checked against analytically integrated references with a
tolerance, never `==` (D-163) — except the frame-top stamps, asserted bitwise
against the indexed grid time because that is the claim.

**Rule: nothing deviates silently.** Every construct a reader could mistake
for the design's is in exactly one of three places: the entries above, or
`pending.md`'s two release lists or its deviation list, the latter naming
the spec shape it replaces. The rule itself is unenforceable — no tool can see a
deviation nobody wrote down — and `src/` and `test/` sit outside every
roster, so the diff review is what holds it.

`test/` does not mirror `src/`, and the remainder is not to be "finished":
`src/` is cut by layering, `test/` by property. `sim.jl` gets no
`test_sim.jl`; `log`, `lifecycle`, `failures`, `localization` and the loop
halves of `discrete` and `events` assert emergent properties of
the layers cooperating, which no source file owns. `test_leaves.jl` is the one
file kept for a source file rather than a property: the leaf walk has no
single consumer to own it.

## Authoring caveats

Traps the code does not warn about, each hit more than once while building:

- **declarations in a local scope never reach the framework.** Inside a
  `let`, a function body or a `@testset`, `y_state(::MyComp, (; x)) = …`
  binds a new local function, not a method of the global one, and the build
  sees a component that declares nothing. The periphery's traits, the device
  contract's four functions and the mapping conventions hit it identically; a
  local `loop` leaves the global fallback in place and crashes the device by
  name. Fixtures live at top level for this reason. Nothing names the trap:
  the build refuses the component as having no class to read (§8.5), and
  `DeadStage` does not reach it — a method the framework never sees is not a
  method returning `(;)` (§5.2, §9.3);
- **extending a declaration without importing it is silent on 1.12.** After
  `using Cadence`, a bare `y_state(::MyComp, …)` creates a local generic
  with no error or warning, exported or not (Julia ≤1.11 raised; only `using
  Cadence: y_state` still errors). The build sees the same
  declares-nothing component, and an optional declaration (`state_events`,
  `x_projection`, `m_init`, `ws_init`, `sample_times`, the
  connection declarations) silently drops its feature. The diagnostic that
  catches it is D-246's fail-fast `DeclarationShadowed`, raised by the walk
  before the class is read, off a foreign binding of a D-220 name in
  `parentmodule(typeof(c))`; the local-scope case above is the one it cannot
  reach;
- the suite reaches the framework through `test/imports.jl`'s `import Cadence:`
  list, so a test that calls or extends a name not on it fails with an
  `UndefVarError` — add the name there. A fixture reusing a framework name
  collides loudly, where the old `Main` arrangement let it clobber silently;
- a function `Core.eval`'d into the module inside a running call cannot be
  called from that same world age — reach it through `Base.invokelatest`, or
  build it at top level. `test_leaves.jl` compiles the mixed-cell expression
  builders that way;
- `===` has no curried form (`all(===(x), v)` fails — use a lambda); a
  `where`-clause method's `.sig` is a `UnionAll` (`Base.unwrap_unionall`
  before `.parameters`);
- a local named `state_events` inside `compile` shadows the `state_events(c)`
  accessor;
- assert a store's type on the `Ref` — `(v[ci]::Base.RefValue{S})[]` — never
  after `[]`, which boxes 16 bytes;
- **a type's printed form depends on the printing module**, so never
  interpolate one into a name a test or a trace compares (`string(typeof(x))`
  reads `Pad` from `Main` and `Main.CadenceTests.Pad` from the test module).
  Every payload field and writer label naming a *user* type goes through
  `_typename` (`diagnostics.jl`), which is `nameof` and so module-independent;
  the two `string(typeof(...))` left in `trim.jl` name a *framework* type on
  purpose, parameters and all. `Symbol(::Type)` has the same dependence — key
  buffers with `_cell_key`;
- the init-service keyword is `t0` (the spec's signatures, D-110) while the
  *concept* and `Clock`'s field stay `t₀` — `clock.t₀ = t0` inside `init!`
  is that split, not a typo; don't unify them;
- **a walk over a tuple whose width a model sets is a generated unroll**
  where it runs in the loop or in a service, through `_unrolled` or
  `_unrolled_tuple` in `executor.jl`. A walk that runs once per build or per
  attach is exempt. Two Julia thresholds make any other walk allocate. A
  `Base.tail` recursion allocates at every call once the tuple passes 32
  elements. `map` over a tuple of 32 or more falls back to a `Vector{Any}`,
  dispatches per element and returns a type that is not concrete. §9.7 rules
  this for the executor's walks alone, and D-289 records why the rule stops
  there. Two service walks still break it, the splats of partials in
  `trim.jl`'s `_seeded` and `linearize.jl`'s `_seed`;
- **code that runs once per build takes a component, an assembly or the root
  unspecialized**: `@nospecialize` on the argument, and
  `Base.@nospecializeinfer` on the walk's entry points `build`, `flatten_tree!` and
  `_walk!`. A closure created per component never captures the instance. It
  reads it from an unspecialized binding, an entry's or the draft's field or a
  `Ref{AbstractComponent}`, because a closure is a type per type of what it
  captures: a typed local always, and an unspecialized argument on Julia 1.12.
  Code the executor runs stays specialized (§9.7, D-289);
- **a callee that needs one more value takes it as an argument.** Never add
  a field to a container the callee already holds so the value can be
  reached without one: that is how the plane came to hold the executor's
  store and the cursor the loop's stop hit (§12.6, D-261). A struct holds
  what it owns or must retain across calls;
- **an artifact holds declared facts; compile at the consumer, once.** A
  compiled form stored beside its declared one (the schedule's vectors
  beside its rows, a policy's addresses beside its faces) is a second home
  with no enforcer but the constructor. `Layout` is the one home for
  address facts (§9.2, D-261);
- **`checkpoint` is refused after a `t*` stop and after an abandoned
  frame.** A test that checkpoints a stopped run stops it at a frame top:
  `t_end`, a stop face read at a grid boundary, or `stop!` (§12.6, D-274).

## Naming

Rules for locals, parameters, fields and package functions, applied to new
and touched code and cited by every stage brief and the cold review. The
rulings behind them are `docs/reports/20260923_naming_inventory/README.md`.

- **a local names what it holds**, with the noun the spec uses for the
  concept (`entry`, `structure`, `deployment`, `tier`, `policy`). Two values
  of one type coexisting are named by role, not type: `producer`/`consumer`,
  `child_path`/`parent_path`;
- **single letters are reserved** for five uses: loop and comprehension
  indices (`i`, `j`, `k`, and `ci` for the component index); type parameters,
  and a binding that plays one's part (`T = Tracer{true}`, a `Dual` width
  `N`); the spec's symbols and their derivatives — a symbol followed by a
  digit, a plural `s`, or a suffix or word (`x_offs`, `xbuf`, `mstores`,
  `y1`, `σs`, `h_r`, `Δtb`, `n_x`, `t_seg`, `h′`), never a bare letter that
  spells no symbol (`n_ok`); a binding whose whole life fits in one glance
  (a lambda parameter, a comprehension variable, a destructuring consumed on
  the next line, any local or parameter of a method under about five lines,
  unless the letter breaks one-meaning in its file); and a family letter: a
  parameter holding a per-kind method family's dispatch value, fixed once
  per family across every file extending it (`d` for a diagnostic kind, `b`
  for a binding);
- **abbreviations are a roster**: `sim`, `exec`, `comp`, `decl`/`decls`,
  `diags`, `conns`, `addr`/`addrs`, `ci`, `act` (activation), `fn` (a
  declaration, stage, guard or handler passed by value), `io`, `err` (a
  caught exception, always `catch err`), `dev` (a device; `device` is its
  id string), `trc` (a trace; `trace` is the API's keyword flag), `cp` (a checkpoint;
  `checkpoint` is the API's function), `op` (a
  lifecycle payload's operation), `rng`, `kw`, `scc`/`sccs`, `deriv`
  (a derivative, as in `x_deriv` and `get_deriv`), and
  `ins`/`outs` for a `Decls` row's declared faces and ports only. A frequent
  name earns a place by being added here, never by being coined in place.
  `diag` in the singular never joins: it shadows `LinearAlgebra.diag`, live
  in `trim.jl`;
- **one name, one meaning per file**: `t` is time, never a tier; `T` is the
  numeric type, and a `Type`-valued parameter that is not it takes a noun
  (`binding_type`); `d` is a diagnostic in the diagnostic families and the
  decision vector in `trim.jl`, nothing else;
- **every method of a function names alike the positions that hold the same
  thing**; a method dispatching on a different type names its parameter by
  what it holds (`warnings(build)`, `warnings(deployment)`, `warnings(sim)`),
  and a deliberate contrast (`other` in a misuse method) stands. Operator
  operands stay `a`, `b`; a Base overload takes Base's `x`, `y`, `z`; a hash
  seed is `seed`;
- **fields follow the same rules**: a field names what it holds, in full or
  by the roster, one meaning per file; a field the spec names or the API
  reads keeps the spec's spelling; a constructor parameter mirrors its
  field;
- **a package function spells its words in full**, joined by underscores,
  the roster's abbreviations admitted (`_condition_violation`, never
  `_cviol`); a generic has one meaning across its methods; a private helper
  never shares an API function's name, and where the spec's verb is the
  right verb the helper appends its target (`gather_cell`, `gather_reads`,
  `capture_stores`, `run_entry!`); an underscore does not lift the rule: a
  prefixed twin appends its target like any helper (`report_cell!`, never
  `_report!` beside `report!`), the one exception being a keyword-to-positional
  shim (`reads`/`_reads`), one function in two calling conventions;
- **no local shares a name with a function** defined in the package, or with
  a Base function the package calls anywhere in `src/` (`pairs`, `count`,
  `max`, `values`, `only`, `bind`; a Base name the package never calls, such
  as `run` or `schedule`, is free). Where the natural noun is taken, the
  local takes a qualifier or a role name. Two exceptions, `path` and
  `build`: a spec noun whose function produces the thing the local holds,
  where no scope holding one calls the function;
- **out of the rules' reach**: a parameter of a public signature keeps the
  spec's spelling (`trace`, `log`, `condition`, `reads`, `sep`, `maxiter`,
  the selectors' `leaf`); a name the code generators emit and read back
  (`buffer`, `offset`, `offsets`, `statements`, `_bundle_expr`'s `entry`)
  changes only with its builder; a parameter mirroring a struct field keeps
  the field's spelling;
- **words join with underscores** (`port_name`, `claimed_by`, `child_path`);
  two words never fuse in a local. A spec symbol fuses with the word for
  what holds it and takes an underscore for a subscript, counts included:
  `xbuf`, `mstores`, `xnext`; `t_seg`, `h_r`, `y_x`, `n_leaves`, `n_x`,
  `N_base`. Locals never take camelCase;
- the suite follows the same rules; the API's keyword names inside calls are
  not locals.

## Running the suite

From the repository root:

    julia --project=test test/runtests.jl                        # all of it
    julia --project=test test/runtests.jl roster devices trace   # named files

The suite is the one `CadenceTests` module in `test/CadenceTests.jl`: the
includes, the `import Cadence:` list (`imports.jl`), `runall()` and
`runonly(names...)`. Each file's tests are one function
(`CadenceTests.test_trace()`), the tightest loop in a live session;
`julia --project=test -L test/repl.jl` opens one with the list and the
fixtures in `Main`. The tests are a workspace member (`[workspace]` in
`Project.toml`), so one root `Manifest.toml`, never committed, resolves both.

Run the suite in the foreground with a 600 s timeout, never in the
background. The full run costs about 7 min; a cold process spends about 30 s
before the first file and little per file after, and an `src/` edit adds
about 15 s of precompile, so name a generous set rather than a minimal one.
Which files a change reaches is read off this table, the last row being the
override:

| touched in `src/` | run |
| --- | --- |
| `declare`, `assembly`, `build`, `tracer`, or a new kind in `diagnostics.jl` | `declare assembly build diagnostics leaves show`; a change in `build.jl`'s `compile` half adds the next row |
| `executor`, `stepper`, `localization` | `executor stepper continuous discrete events localization failures` |
| `dataplane`, `roster`, `bindings`, `control`, `devices`, `trace` | `dataplane roster bindings devices trace lifecycle log` |
| `checkpoint` | the row above, plus `discrete events linearize` |
| `readers`, `conditions`, `trim`, `linearize` | `readers conditions trim linearize` |
| a new `AbstractComponent` fixture in any test file | add `build`, since `test_build.jl`'s Dual-activation sweep pins the skipped count |
| `show` | `show` |
| `sim`, `deployment`, `store`, `leaves`, `Cadence`, or `diagnostics.jl` beyond a new kind | all of it |

To check a refactor for test loss, compare the suite's own assertion total;
`grep -c '@test '` misses the loops that multiply them.

**The gate** is the full suite under the sandbox flags:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

A stage commit inside an increment runs its routed subset under the same
flags and no more. The gate runs once per increment, by the cold reviewer,
and again by the fixer after a review fix. A loose fix outside an increment,
and any commit in the table's last row, runs the gate itself. The suite is
green at every push.

`--project=test` alone leaves three ambient sources on the load path that
can satisfy a dependency the suite never declared, `startup.jl`, the default
environment and the stdlib directory, and each has already masked one. The
load path `@` and the startup flag remove them, as `Pkg.test()`'s sandbox
does. `--check-bounds=yes` ignores every `@inbounds` in the tree and its
dependencies, which `Pkg.test()` does not (on 1.13 the test process inherits
the parent's setting). Run `julia --project=. -e 'using Pkg; Pkg.test()'`
only after a change to `Project.toml`, `test/Project.toml` or the workspace
stanza: it proves the conventional entry point still resolves, and nothing
else the gate does not.

`-t auto` makes the gate run multi-threaded whatever `JULIA_NUM_THREADS`
says. The suite does not depend on the thread setup, and it passes under
`-t 1` as well. There every rostered run carries §12.2's `ThreadBudget` in
the loop writer's first-frame delta and totals, or in the tail's residue when
no frame ran, so an assertion on that writer names its field. A deviceless loop
never yields (§12.2), so a test that spawns an advance and waits on it from its
own task rosters a device first, `TailProbe` under `NoClaim()`. The loop then
yields every frame, and the waiting task gets its turn on any thread layout.
Without the device, the test holds only while Julia gives the main task an
interactive thread, which the bare `julia` and `-t auto` do on 1.13 and `-t 1`
does not. There the spawned loop shares the waiter's thread and holds it until
its run ends.
