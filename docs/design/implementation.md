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
| `src/leaves.jl` | the leaf walk (with the enum leaf, D-237's opaque leaf and `mutable_position`): flatten / reconstruct / the activation retype, and `leaf_names`' dotted spelling of a flat position, embed-accept's relation `_accepts` (D-166, decided on the type per D-238, an opaque leaf by identity per D-237) and the wire relation `_accepts_wire` with its abstract arm (D-236) and the checked state write `flatten_state!` (D-235) | §4.1, §4.3, §4.4, §6.1, §7.1, §7.2, §8.2, §9.5, §13.4, D-166, D-235, D-236, D-237, D-238 |
| `src/diagnostics.jl` | the diagnostic kinds with `severity`/`path`/`message`, `_typename` (a user type's name for a payload field or a label), the `DiagnosticError` carrier, parametric on policy, with `diagnostic`/`diagnostics`/`kinds` and its two renderings, `logline`, `InternalInvariant`, §13.4's runtime trio — `CursorFrame`, `StepError` (parametric on its cause, `diagnostic` defined on the species) and `NonfiniteState` — and §12.7's replay trio, `ReplayHeaderMismatch`/`ReplaySchemaMismatch`/`ReplayUnknownFace`, whose `face` carries a bare position where no schema resolves it and the name where one does | §13.1, §13.2, §13.4, Appendix C, D-058, D-059, D-157, D-214, D-215, D-222, D-225 |
| `src/declare.jl` | the declaration layer: both tiers' name families and arities, the bundle law, `probe_value` with its enum arm (D-051), the connection declarations beside `transparent_container`, the rate forms with `sample_times`, the event surface | §2.1, §5.2, §8.2, §8.5–§8.7, §9.3, D-179, D-185, D-195, D-211 |
| `src/assembly.jl` | class by declaration shape; children and containers with their collision family; `Group`, the anonymous assembly, kernel material by decision where the rest of the old `library.jl` became fixtures; paths and §6.1's one-level rule; endpoint and face resolution with the root's face invariants; the flatten pass under one Stratum A barrier (`Walk` owning the `Flat` it builds, resolvers recording into the stratum's list, `wire!` deriving the two-sided face graph after the barrier, `Flat.root_types` holding the root-input types the wire pass fixes) and the sample-time fold; §13.3's `resolve`/`resolve_terminal`/face-list primitives and the service walk `resolve_authored` over the `Flat`'s retained root, declared holdings read off the type definition (D-061, D-130), and `authored_chain`, the child names along an absolute path that `capture` spells level by level, and §8.8's `input_passthrough`/`output_passthrough` | §6.1, §8.5–§8.8, §9.1, §9.2, §13.3, §14.2, D-061, D-130, D-171, D-207–D-212, D-229, D-236 |
| `src/store.jl` | per-eltype cell stores (a handle type is its own eltype, D-237), the `StoreBundle`, gather and the checked scatter (§9.5's always-on check decided at generation, D-235), `_cell_key`, the `Clock` | §9.5, §9.7, D-162, D-235, D-237 |
| `src/executor.jl` | entries (each carrying its component's path, for the write's diagnostic; `PublishEntry`, the framework's stage-1-position copy of store fields into cells, §5.3), the chunked unrolled walk, the interior/boundary split, the `(idx − Φ) % D` gate and boundary zero's `ESTABLISH` beside it, the event set with its registers and the guard/fire/project walks, and the execution cursor every entry stores into | §5.3, §9.5, §9.7, §10.4–§10.6, §13.4, §14.5, D-059, D-205, D-235 |
| `src/build.jl` | tier classification (recording, the tier read in the walk beside the class, `build` owning Stratum A's one throw, the wire pass (both type clauses at `Float64` and at the marker scalar, the root-input type and its two refusals, the contract-bound check (`TierSignatureMismatch`'s bound arm); D-236)), the store isbits check (§7.3, D-231) and the state-leaf vocabulary check (§7.1, D-094), the probe and the event probe, `auto_published` and the published set on the `Activation` (§5.3, D-169), the feedthrough graph, the layout with the root-input meet (D-168, D-236) and `IllegalPortType`'s three arms (D-237), the probe's embedding of products (`_embed`), the `Build` and its activations, deployment binding (one throw per `Simulation` call), and `compile` → `Executor{T}` — one activation's buffer set with the bodies closed over it, one owner per set, `evaluate!`/`_round!`/`apply!` on it | §5.3, §6.1, §8.2, §9.1–§9.4, §9.7, §10.4, D-016, D-166, D-169, D-179, D-208, D-210, D-229, D-235, D-236, D-237 |
| `src/readers.jl` | the closed read-selector family, `reads`, its path selectors walked from the root (§13.3), the internal `_compile_reads` → `Reader{T}`, `gather` as `apply!`'s twin over an executor; activation identity on readers and plans as an internal invariant | §13.1, §13.3, §14.1, §14.4, §14.7, §14.10, D-125, D-130 |
| `src/sim.jl` | `Simulation` (owning its `exec`), the deployment keywords, the boundary macro-sequence and the §10.6 event phase with its `FiringBudget` degradation, `init!`, `run!`/`step!`, `replay!` over the one shared run body, `attach!`/`detach!`, staging/drain/publication with the drain's replay substitution, §12.6's input mode (`mode(sim)`, `to_time`, `live!`), the lifecycle and termination record, the frame loop's one catch site with the species rule and the interrupt carve-out and its second host around boundary zero, the seam's `isfinite` sweep over `x` as the boundary's first act, the accessors | §10.2–§10.6, §11.1–§11.4, §11.8, §12.1–§12.7, §13.4–§13.6, §14.5, §14.6, D-059, D-101, D-157, D-203, D-218, D-219, D-221, D-223, D-232, D-233 |
| `src/stepper.jl` | the seam's backend side: RK4 and Heun, the retained `startpoint`, dense output | §10.2, D-017 |
| `src/localization.jl` | the frame loop: arrival sweep, θ = 0 validation, ITP bracketing, `t*` boundaries, the localization budget and the `ChatteringBudget` degradation; the cursor's arrival/validation/trial phases | §10.2, §10.4, §13.4, D-018, D-059, D-133 |
| `src/dataplane.jl` | the compiled writer and staging cells, the drain, snapshots and the log with re-decimation, the typed diagnostic kinds and cells, and the published `FrameworkStatus` every snapshot carries | §11.1–§11.4, §11.8, §12.4, §12.6, §13.2, D-023, D-038, D-137 |
| `src/trace.jl` | the input trace: the header captured at `init!` (resolved stores, root inputs, writer schemas, deployment block), one sparse record per drained batch behind it, the only-growing schema list, `Trace.frames` — the drain count a replay reads its bound off — `trace(sim)`, and replay's up-front entry pass (`_compile_feed`) validating header, schemas and records, both stages collecting since D-217, into the `ReplayFeed` the drain reads | §11.5, §12.6, §12.7, §14.5, D-029, D-038, D-101, D-176, D-217, D-218 |
| `src/roster.jl` | device/binding traits and conformance, the roster, both claim sources, the harness writer | §11.3, §11.4, §11.6 |
| `src/bindings.jl` | `TableBinding`, `map_input` and the conditioning helper, binding reads resolved at attach (`ReadBindingUnresolved`, the source rule) | §11.2, §11.4, §11.6, §14.4 |
| `src/devices.jl` | the device contract, the handle, the task wrapper, the init bracket and the tail under `join_timeout`; the two lifecycle gates, the readers' and the roster's | §11.1, §11.3, §11.6, §12.1–§12.4, §13.5, §13.6, D-198, D-232, D-233 |
| `src/conditions.jl` | the condition algebra, one collecting pass behind both ways of applying a plan, each `at` prefix walked from its authoring level (§13.3) — `resolve_condition` (values) and `compile_plan` (`Getter{P}` lenses, `SpecializedPlan`, `ConditionShapeDrift`) — root-input totality, `capture` | §9.5, §13.1, §13.3, §14.1–§14.6, D-063–D-068, D-130, D-204, D-205, D-207 |
| `src/trim.jl` | `TrimProblem`, the `solve` seam with `LevenbergMarquardt`, `trim!` over D-213's two-half scratch world, `TrimReport`, the `Trim*` kinds | §9.6, §13.1, §14.5–§14.8, D-070, D-158, D-213, D-224 |
| `test/fixtures.jl` | the suite's fixtures: the coverage component set, the named assemblies, the devices and bindings, the `condition` fragment-function idiom, `Pendulum` — user material, and no name here is known to `src/` | — |
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
halves of `discrete`, `multirate` and `events` assert emergent properties of
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
  `DeadStage` is not built (`pending.md`);
- **extending a declaration without importing it is silent on 1.12.** After
  `using Cadence`, a bare `output_state(::MyComp, …)` creates a local generic
  with no error or warning, exported or not; Julia ≤1.11 raised, 1.12's
  binding partitions removed that (measured on 1.12.7), and only `using
  Cadence: output_state` still errors. The build sees the same
  declares-nothing component, and an optional declaration (`state_events`,
  `state_projection`, `init_m`, `init_workspace`, `sample_times`, the
  connection declarations) silently drops its feature. The diagnostic that
  would catch it, a foreign binding of a D-220 name in the component's
  module found via `parentmodule(typeof(c))`, is proposed and not designed;
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
`runonly(names...)`. `julia --project=test -L test/repl.jl` opens a session
with the same list and the fixtures in `Main`, nothing to import by hand. Each
file's tests are one function (`CadenceTests.test_trace()`), which is what the
second form runs and the tightest loop in a live session. The tests are their
own workspace member (`[workspace] projects = ["test"]`, Julia 1.12), so one
root `Manifest.toml` resolves both and `Cadence` needs no `develop`; no
`Manifest.toml` is committed.

The full run costs about 5 min. A cold process spends about 30 s before the
first file and little per file after, so name a generous set rather than a
minimal one. An `src/` edit adds about 15 s of precompile to the first run
after it. Which files a change reaches is a guess off the table above;
`sim.jl`, `store.jl` and `diagnostics.jl` are cross-cutting and mean all of
it. To check a refactor for test loss, compare the suite's own assertion
total; `grep -c '@test '` misses the loops that multiply them.

**None of the above is the gate. Before trusting a green suite, run**

    julia --project=. -e 'using Pkg; Pkg.test()'

`--project=test` leaves three ambient sources on the load path that can
satisfy a dependency the suite never declared — what the developer's
`startup.jl` loads into `Main`, the default environment, and the stdlib
directory — and each has already masked one. `Pkg.test()` runs in a sandbox
holding the declared dependencies alone, with `--startup-file=no` and
`--check-bounds=yes`, at the cost of a separate precompile.
