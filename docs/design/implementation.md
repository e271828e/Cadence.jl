# Implementation status

The implementation of the framework in `spec.md`, grown one increment at a
time (increment 1, the cell-store bench, is frozen in
`prototypes/cellstore_bench`; D-162 cites its numbers). Spec and code are
peers: neither is subservient, and both are kept in agreement. This file is
the map and the traps; `pending.md` is what the code still owes the spec. Why
a given test asserts what it does is carried by the suite itself: every
testset name states its property and cites the section it answers to.

## What is real here

One line per file: which constructs live where, and the sections they answer
to. For more than a line, read the file itself and the sections it cites.

| file | implements | spec |
| --- | --- | --- |
| `src/Cadence.jl` | the package module: the dependencies and the include order the other files load in | — |
| `src/leaves.jl` | the leaf walk (with the enum leaf, D-237's opaque leaf, `Symbol` among them by D-243, and `mutable_position`): flatten / reconstruct / the activation retype, and `leaf_names`' dotted spelling of a flat position, embed-accept's relation `_accepts` (D-166, decided on the type per D-238, an opaque leaf by identity per D-237) and the wire relation `_accepts_wire` with its abstract arm (D-236) and the checked state write `flatten_state!` (D-235) | §4.1, §4.3, §4.4, §6.1, §7.1, §7.2, §8.2, §9.5, §13.4, D-166, D-235, D-236, D-237, D-238, D-243 |
| `src/diagnostics.jl` | the diagnostic kinds with `severity`/`path`/`message`, `_typename` (a user type's name for a payload field or a label), the `DiagnosticError` carrier, parametric on policy, with `diagnostic`/`diagnostics`/`kinds`, the build's `warnings` beside the `carried` collection — a warning joins no collection, and both renderings end with one line apiece (D-250) — and its two renderings, `logline`, the build's warning channel `BUILD_WARNINGS` with `_warn!` appending to the bound list or logging outside any build (D-250), the grid records `GridEntry` and `GridReport` — deployment substrate, defined here because the payloads naming them are — with `DeploymentInvalid`'s `grid` payload and `GridUtilization`'s, both rendered by `_grid_block` as the structured block every grid consumer appends to its first line, the pool table with each entry's refinement factor and a driving offset's repair, then the prime attribution with its suppliers (D-187), `ArgumentInvalid`'s materialization arms — `join_timeout`, `trace`, `log`, `log_every`, `log_max` and `t_end` carry the constraint text and section they carried on `DeploymentInvalid`, whose parameter set is now Appendix C's row (D-256) —, `InternalInvariant`, §13.4's runtime trio — `CursorFrame`, `StepError` (parametric on its cause, `diagnostic` defined on the species) and `NonfiniteState` — and §12.7's replay trio, `ReplayHeaderMismatch`/`ReplaySchemaMismatch`/`ReplayUnknownFace`, whose `face` carries a bare position where no schema resolves it and the name where one does and whose deployment arm has a second rendering for a schedule row, named by the component path and the column (D-255) | §9.1, §13.1, §13.2, §13.4, Appendix C, D-058, D-059, D-157, D-214, D-215, D-222, D-225, D-250 |
| `src/declare.jl` | the declaration layer: both tiers' name families and arities, the bundle law with the legal bundle sets and `classify_bundle_field` (§5.2, Appendix B), `probe_value` with its enum arm (D-051), the connection declarations beside `transparent_container`, the rate forms with `sample_times`, the event surface, the declaration family `DECLARATION_FAMILY` and `foreign_declarations` | §2.1, §5.2, §8.1, §8.2, §8.5–§8.7, §9.3, D-179, D-185, D-195, D-211, D-246, D-248 |
| `src/assembly.jl` | class by declaration shape; children and containers with their collision family; `Group`, the anonymous assembly, kernel material by decision where the rest of the old `library.jl` became fixtures; paths and §6.1's one-level rule; endpoint and face resolution with the root's face invariants; the flatten pass under one structure-step barrier (`Walk` accumulating what `wire!` returns as the `Structure`, the tiers and the two rate-provenance tables among them, resolvers recording into the step's list, `wire!` deriving the two-sided face graph after the barrier, `Structure.root_types` holding the root-input types the wire pass fixes) and the sample-time fold; §13.3's `resolve`/`resolve_terminal`/face-list primitives, the walk recording each assembly's evaluated face lists in `Walk.faces` and binding them as `WALK_FACES` so the primitives read them once per call (Appendix C) and evaluate a body only outside a walk, and the service walk `resolve_authored` over the `Structure`'s retained root, declared holdings read off the type definition (D-061, D-130), and `authored_chain`, the child names along an absolute path that `capture` spells level by level, and §8.8's `input_passthrough`/`output_passthrough` with the three exclusive selectors and `EmptyFaceSelection` through the channel (D-251); the shadowing check ahead of `classify` in the walk (D-246); the store-form gate ahead of the classifier in the walk (D-247); the component frame around the walk's two branches (D-248) | §6.1, §8.1, §8.5–§8.8, §9.1, §9.2, §13.3, §14.2, D-061, D-130, D-171, D-207–D-212, D-229, D-236, D-246, D-247, D-248, D-251, D-253 |
| `src/store.jl` | per-eltype cell stores (a handle type is its own eltype, D-237), the `StoreBundle`, gather and the checked scatter (§9.5's always-on check decided at generation, D-235), `_cell_key`, the `Clock` — its `t` in the deployment's scalar and its origin `t₀` a `Float64`, taken by the constructor and converted into `t` (D-260) | §9.5, §9.7, D-162, D-235, D-237, D-260 |
| `src/executor.jl` | entries (each carrying its component's path, for the write's diagnostic, an event entry its event name beside it (D-249)), the chunked unrolled walk, the interior/boundary split, the `(idx − Φ) % D` gate and boundary zero's `ESTABLISH` beside it, the event set with its registers and the guard/fire/project walks, and the execution cursor every entry stores into, carrying the loop's stop hit beside the frame it names (§13.5, D-255) | §5.3, §9.5, §9.7, §10.4–§10.6, §13.4, §13.5, §14.5, D-059, D-205, D-235, D-249, D-255 |
| `src/build.jl` | the user-code frame — `invoke_declaration`, `invoke_probed`, `at_component` (§13.2, D-248); tier classification (recording, the tier read in the walk beside the class, `build` owning the structure step's one throw, the wire pass (both type clauses at `Float64` and at the marker scalar, the root-input type and its two refusals), the contract-form check — `TierSignatureMismatch`'s arity arm in the vote loop, its bound arm in the wire pass (D-249); D-236), the store-form check `check_store_form` (§8.2, D-247), the store isbits check (§7.3, D-231) and the state-leaf vocabulary check (§7.1, D-094), the probe and the event probe, the dead-stage rule at both stage probes and `MissingProbeValue` in `cell_layout` (§9.3), the feedthrough graph with its edge provenance, Kahn's execution order into the `Dataflow` and, at a stall, the SCC decomposition into one `AlgebraicCycle` per cluster (§5.6, D-012), `_probe_direct!` shared with the classifier's prefix probe, the layout with the root-input meet (D-168, D-236) and `IllegalPortType`'s three arms (D-237), the probe's embedding of products (`_embed`), the nominal evaluation `_nominal` returning the `Dataflow`, the `Events` and the nominal activation, `_activate` for every other scalar, the `Build` as structure, dataflow, events, one activation dictionary and `warnings`, `activation` over that dictionary and `warnings(::Build)` beside it, `build` binding the warning channel once around its three steps — a throw leaving it rewrapped with the list, a completed build logging each warning once at return (D-250) —, `ProbeTag`/`ProbeDual`, the canonical probe scalar (§9.4), and `compile` → `Executor{T}`, its name lists off the products — one activation's buffer set with the bodies closed over it, one owner per set, `evaluate!`/`_round!`/`apply!` on it, the executor owning its stepper (built here from the `algorithm` keyword), its arrival buffers, the `chunk_size` it was compiled at and the localized-event key (D-256) | §5.3, §5.5, §5.6, §6.1, §8.2, §9.1–§9.4, §9.7, §10.4, §13.2, D-012, D-051, D-166, D-179, D-208, D-210, D-229, D-235, D-236, D-237, D-247, D-248, D-249, D-250, D-252, D-253, D-256 |
| `src/tracer.jl` | §5.6's set-propagation scalar `Tracer{S}` (global on `true`, local on `false`, `Undecidable` the marker between them), the leaf-wise lift and tag walks, and `_classify` — the schedule-free per-member trace at the probe point, its prefix probe, D-245's port-graph verdict and the sampled fallback at a fixed seed | §5.4, §5.6, §9.3, D-012, D-140, D-245 |
| `src/readers.jl` | the closed read-selector family, `reads`, its path selectors walked from the root (§13.3), the internal `_compile_reads` → `Reader{T}`, `gather` as `apply!`'s twin over an executor, the output-port candidates read off the `Dataflow`; activation identity on readers and plans as an internal invariant | §13.1, §13.3, §14.1, §14.4, §14.7, §14.10, D-125, D-130, D-253 |
| `src/sim.jl` | §13.5's block — the four termination sources, `StopPolicy`, the immutable value each advance declares, and the termination record carrying the terminating advance's policy beside its source and the tail's residue (D-203, D-255) — then `Run{T}` — §12.6's run state in four fields, the log and the trace fixed by the door that built it (the trace `nothing` under §11.5's switch, which rides here) and the two the run evolves, the attached recording and the termination record the tail writes, with `closed(run)` beside it; the origin, the stop policy and the mode are not fields of it, the clock holding `t₀` as a `Float64`, each advance carrying its own policy and `mode(sim)` reading the feed (D-255, D-260) — and the mutable `Simulation` of five fields — the deployment, the executor, the run, the plane and the control, every other value belonging to one of them (D-256, §12.1) —, the materialization `Simulation(deployment, T)` with its own keywords under `ArgumentInvalid`, its placeholder run built ahead of the plane and carrying the recording flags to `init!`, the trace switch among them, and the two sugar forms defined as the composition (D-254), `warnings(::Simulation)` as the concatenation (D-250), the boundary macro-sequence and the §10.6 event phase with its `FiringBudget` degradation, `init!`, `run!`/`step!`, `replay!` over the one shared run body — the three doors that build a run, `_open_trajectory!` and `_open_run!` shared by the two that open a trajectory —, `attach!`/`detach!`, staging/drain/publication with the drain's replay substitution, §12.6's input mode (`mode(sim)`, `to_time`, `live!`, the mode read off the run's `feed` so a change of mode is a write to the run, never a change of run, D-260), the `StopPolicy` each advance builds and validates per call and then carries as an argument, from the call through the frame loop to `_record`'s assembly — `t_end` and `stop_on` are keywords of `run!`/`replay!`/`step!`, never of the constructor, and the unbounded run's advisory is raised at `run!` (D-255, D-260) —, the lifecycle and termination record, the frame loop's one catch site with the species rule — the runtime bundle-field match in it (§13.2, §13.4, D-248), its stage-1 names off the `Dataflow` — and the interrupt carve-out and its second host around boundary zero, the seam's `isfinite` sweep over `x` as the boundary's first act, the accessors | §10.2–§10.6, §11.1–§11.4, §11.8, §12.1–§12.7, §13.2, §13.4–§13.6, §14.5, §14.6, D-059, D-101, D-157, D-203, D-218, D-219, D-221, D-223, D-232, D-233, D-248, D-253, D-255, D-256, D-260 |
| `src/stepper.jl` | the seam's backend side: RK4 and Heun, the retained `startpoint`, dense output | §10.2, D-017 |
| `src/deployment.jl` | deployment binding and its two artifacts (D-254): `bind_schedule` with `_exact`/`_as_int`, the typed `Schedule` over `ScheduleRow` and `ScopeRow` — the anchor and provenance columns beside `(D, Φ, Δt)`, the rate-scope rows, and the `D`/`Φ`/`Δt` vectors the executor compiles over — and the `Deployment` itself: the build plus the grid parameters, the algorithm and the three event parameters, scalar-free, with one throw per call, `==`/`hash` by value over everything but the build, the grid and the warnings (§12.7), and `warnings(::Deployment)`; the grid attribution `_grid_report` (D-187) — the constraint pool with each entry's leave-one-out refinement factor, the prime attribution of `gcd(pool)`'s denominator and a driving offset's nearest non-refining neighbours — computed once per call ahead of the `Δt_base` branch, carried on the artifact and handed to the three refusals whose remedy is a `Δt_base` the pool admits, and the derivation path's info line, the derived value over the same block with both attribution forms, with the `GridUtilization` advisory at `min_i Dᵢ > 1` | §9.1, §9.2, §10.5, §12.7, Appendix B, Appendix C, D-187, D-227, D-229, D-250, D-254, D-256 |
| `src/localization.jl` | the frame loop: arrival sweep, θ = 0 validation, ITP bracketing, `t*` boundaries, the localization budget and the `ChatteringBudget` degradation; the cursor's arrival/validation/trial phases; §13.5's stop-face read at every `t*` publication, off the policy `frame!` carries, the frame's remainder abandoned when a face holds | §10.2, §10.4, §13.4, §13.5, D-018, D-059, D-133, D-255, D-260 |
| `src/dataplane.jl` | the compiled writer and staging cells, the drain, snapshots and the log with re-decimation, the typed diagnostic kinds and cells — `UnboundedRun` among them, the loop's own advisory (§13.5, D-255), and `EmptyGreedyClaim`, declared with the service kinds and reported by `attach!` into the roster entry's own cell (§11.3, D-250) — and the published `FrameworkStatus` every snapshot carries | §11.1–§11.4, §11.8, §12.4, §12.6, §13.2, §13.5, D-023, D-038, D-137, D-250, D-255 |
| `src/trace.jl` | the input trace: `TraceHeader` captured at `init!` (resolved stores, root inputs, the run's `Deployment` and its `t₀`, a `Float64` like `h`, D-260) and the mutable `Trace{T}` behind it — the header plus two lists that grow in place, the writers' schemas and one sparse record per drained batch, and the length a replay reads its bound off, which is also the ordinal each record carries, advanced at the top of the drain (D-255, D-260) —, `_install_writers!`'s growth rule, compiling each drain thunk against the run's trace with the appended range as a local, `trace(sim)` handing back a detached value, and replay's up-front entry pass (`_compile_feed`) validating header, schemas and records, both stages collecting since D-217, into the `ReplayFeed` the drain reads — the header's deployment half being one `==` with `_walk_deployment!` naming what it refused, the schedule's rows and scopes by path and column (§12.7) | §11.5, §12.6, §12.7, §14.5, D-029, D-038, D-101, D-176, D-217, D-218, D-254, D-255, D-260 |
| `src/roster.jl` | device/binding traits and conformance, the roster, both claim sources, the harness writer, and §11.5's drain thunks beside them — `DataPlane(layout, store, trc)` compiling the harness thunk against the run's trace, which `reclaim!` takes from `attach!` and `detach!` rather than reading off the plane (D-260); the loop is a writer too, so the plane holds its diagnostic cell and account, and §11.2's published holder with them (D-256) | §11.2, §11.3, §11.4, §11.5, §11.6, §11.8, D-255, D-256, D-260 |
| `src/bindings.jl` | `TableBinding`, `map_input` and the conditioning helper, binding reads resolved at attach (`ReadBindingUnresolved`, the source rule), the candidates on the two name-shaped read misses (§14.4) | §11.2, §11.4, §11.6, §14.4 |
| `src/devices.jl` | the device contract, the handle, the task wrapper, the init bracket and the tail under `join_timeout`, which `Control` carries (D-256); the two lifecycle gates, the readers' and the roster's; `ResidueRecord`, the tail's product, beside the sweep that builds it (§13.5, D-203); `Control` keeping the stop word, the lifecycle, the wait and the shutdown cap, the termination record having left it for the `Run` (D-255, D-256) | §11.1, §11.3, §11.6, §12.1–§12.4, §13.5, §13.6, D-198, D-232, D-233, D-244, D-255, D-256 |
| `src/conditions.jl` | `condition`, the fragment function's generic (§14.2, Appendix B); the condition algebra, one collecting pass behind both ways of applying a plan, each `at` prefix walked from its authoring level (§13.3) — `resolve_condition` (values) and `compile_plan` (`Getter{P}` lenses, `SpecializedPlan`, `ConditionShapeDrift`) — root-input totality, `capture` | §9.5, §13.1, §13.3, §14.1–§14.6, D-063–D-068, D-117, D-130, D-204, D-205, D-207, D-226 |
| `src/trim.jl` | `TrimProblem`, the `solve` seam with `LevenbergMarquardt`, `trim!` over D-213's two-half scratch world, the frozen copy over the `Dataflow`'s port list, `TrimReport`, the `Trim*` kinds | §9.6, §13.1, §14.5–§14.8, D-070, D-158, D-213, D-224, D-253 |
| `test/fixtures.jl` | the suite's fixtures: the coverage component set, the named assemblies, the devices and bindings, the `condition` methods (the fragment-function idiom over the framework's generic, `src/conditions.jl`), `Pendulum`, the `ForgottenImport` module, the forgotten-import fixtures, importing nothing — user material, and no name here is known to `src/` | — |
| `test/imports.jl` | the suite's `import Cadence:` list, shared with `repl.jl` — the one place a framework name the tests call or extend is admitted | — |
| `test/repl.jl` | the REPL bootstrap: `julia --project=test -L test/repl.jl` loads the list and the fixtures into `Main` | — |

Correctness is checked against analytically integrated references with a
tolerance, never `==` (D-163) — except the frame-top stamps, asserted bitwise
against the indexed grid time because that is the claim.

**Rule: nothing deviates silently.** Every construct a reader could mistake
for the design's is in exactly one of three places: the table above, or
`pending.md`'s absence list or deviation list, the latter naming the spec
shape it replaces. The rule itself is unenforceable — no tool can see a
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
  `let`, a function body or a `@testset`, `output_state(::MyComp, (; x)) = …`
  binds a new local function, not a method of the global one, and the build
  sees a component that declares nothing. The periphery's traits, the device
  contract's four functions and the mapping conventions hit it identically; a
  local `loop` leaves the global fallback in place and crashes the device by
  name. Fixtures live at top level for this reason. Nothing names the trap:
  the build refuses the component as having no class to read (§8.5), and
  `DeadStage` does not reach it — a method the framework never sees is not a
  method returning `(;)` (§5.2, §9.3);
- **extending a declaration without importing it is silent on 1.12.** After
  `using Cadence`, a bare `output_state(::MyComp, …)` creates a local generic
  with no error or warning, exported or not (Julia ≤1.11 raised; only `using
  Cadence: output_state` still errors). The build sees the same
  declares-nothing component, and an optional declaration (`state_events`,
  `state_projection`, `init_m`, `init_workspace`, `sample_times`, the
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
  is that split, not a typo; don't unify them.

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
| `declare`, `assembly`, `build`, `tracer`, or a new kind in `diagnostics.jl` | `declare assembly build diagnostics leaves`; a change in `build.jl`'s `compile` half adds the next row |
| `executor`, `stepper`, `localization` | `executor stepper continuous discrete events localization failures` |
| `dataplane`, `roster`, `bindings`, `devices`, `trace` | `dataplane roster bindings devices trace lifecycle log` |
| `readers`, `conditions`, `trim` | `readers conditions trim` |
| `sim`, `deployment`, `store`, `leaves`, `Cadence`, or `diagnostics.jl` beyond a new kind | all of it |

To check a refactor for test loss, compare the suite's own assertion total;
`grep -c '@test '` misses the loops that multiply them.

**The gate** is the full suite under the sandbox flags:

    JULIA_LOAD_PATH="@" julia --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

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
