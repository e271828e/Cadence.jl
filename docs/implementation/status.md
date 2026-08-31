# Implementation status

The walking skeleton for the framework in `design/spec.md`,
built to keepable standards and grown one increment at a time — increments 2–23
so far (increment 1, the cell-store bench, is frozen in `prototypes/cellstore_bench`;
D-162 cites its numbers). This file is the orientation; read it first and
alone. On demand:

- `map.md` — what each source file implements, piece by piece, with spec
  citations: the long form of the table below, the long absence list, and the
  long form of the authoring trap.
- `tests.md` — the property-by-property record of what the tests pin down. Read
  it when modifying an existing test or wondering why one asserts what it does;
  new increments add their property bullets there.

Run the suite from the repository root:

    julia --project=test test/runtests.jl

The suite has its own environment. `test/Project.toml` holds what only the
tests need — `Test`, `BenchmarkTools`, `InteractiveUtils` — and the package's
own `[workspace] projects = ["test"]` makes it a workspace member (Julia 1.12),
so one `Manifest.toml` at the root resolves both. `Cadence` needs no `develop`
there, the two projects share one precompile cache, and a fresh clone
instantiates once from either. No `Manifest.toml` is committed.

The suite is the `CadenceTests` module in `test/CadenceTests.jl`: the includes,
the `import Cadence:` list, `runall()` — the grouped tree the summary shows —
and `runonly(names...)`. Each file's tests are one function, so the loop
between commits runs a subset:

    julia --project=test test/runtests.jl roster devices trace

Five files cost 51 s against 287 s for all of them. A cold process spends about
30 s before the first file's tests run and little per file after, so name a
generous set rather than a minimal one; going finer than a file buys nothing
against that floor. A file's time in the summary tree is amortized and
understates a solo run — `roster` reads 3.1 s there and takes 13.8 s alone. In
a live session the function re-runs in its own runtime alone,
`CadenceTests.test_trace()` in 1.2 s, which is the tightest loop there is.

Which files a change can reach: `assembly.jl`/`declare.jl`/`build.jl` →
structure, hierarchy; `executor.jl`/`stepper.jl`/`localize.jl` → the execution
files; `dataplane.jl`/`roster.jl`/`bindings.jl`/`devices.jl`/`trace.jl` → the
data-plane files; `readers.jl`/`conditions.jl`/`trim.jl` → analysis. `sim.jl`,
`store.jl` and `diagnostics.jl` are cross-cutting and mean all of it. That
mapping is a guess; the gate below is what makes a wrong one harmless.

`src/` is the `Cadence` package, so the first run after an `src/` edit pays a
precompile of about 15 s on top of the suite's own time.

**None of the above is the gate. Before trusting a green suite, run**

    julia --project=. -e 'using Pkg; Pkg.test()'

which is stricter, and slower for it. Three ambient sources can satisfy a
dependency the suite never declared, and each has masked one: a package the
developer's `startup.jl` loads into `Main` ahead of the tests (`BenchmarkTools`
was once dropped from `Project.toml` and the suite stayed green on that
machine); the developer's own default environment, and the stdlib directory,
both of which `--project=test` leaves on the load path (`InteractiveUtils`,
which `test_diagnostics.jl` reaches for `subtypes`, went undeclared and only
`Pkg.test()` said so). `Pkg.test()` runs in a sandbox holding the declared
dependencies alone, with `--startup-file=no` and `--check-bounds=yes`; the
suite is green under bounds checking, so that costs a separate precompile of
the tree and nothing else.

## What is real here

| file | implements | spec |
| --- | --- | --- |
| `src/Cadence.jl` | the package module: the dependencies and the include order the other files load in | — |
| `src/leaves.jl` | the leaf walk: flatten / reconstruct / the activation retype, and `leaf_names`' dotted spelling of a flat position | §7.1, §7.2, §13.4 |
| `src/diagnostics.jl` | the diagnostic kinds, `severity`/`path`/`message`, `_typename` (a user type's name for a payload field or a label), the `BuildError` carrier and its compiler-style rendering, `logline`, `InternalInvariant`, and §13.4's runtime trio — `CursorFrame`, the `StepError` carrier with its compact rendering, and `NonfiniteState`, the species the sweep raises | §13.1, §13.2, §13.4, Appendix C, D-214, D-215 |
| `src/declare.jl` | the declaration layer: both tiers' name families and arities, the bundle law, `probe_value`, the connection declarations beside `transparent_container`, the rate registers with `sample_times`, the event surface | §5.2, §8.2, §8.5–§8.7, §9.3, D-211 |
| `src/assembly.jl` | class by declaration shape; children and containers (bare-key transparency and its three-arm collision family); `Group`, the anonymous assembly whose `children` field is name-transparent (D-211); paths, §6.1's one-level rule, endpoint and face resolution, the root's face invariants; the flatten pass with its two-sided face graph and the sample-time fold; §13.3's `resolve`/`resolve_terminal`/face-list primitives and §8.8's `input_passthrough`/`output_passthrough` | §6.1, §8.5–§8.8, §9.1, §9.2, §13.3, D-207–D-212 |
| `src/store.jl` | per-eltype cell stores, the `StoreBundle`, gather/scatter, `_cell_key`, the `Clock` | §9.7, D-162 |
| `src/executor.jl` | entries, the chunked unrolled walk, the interior/boundary split, the `(idx − Φ) % D` gate and boundary zero's `ESTABLISH` beside it, the event set with its registers and the guard/fire/project walks, and the execution cursor every entry stores into | §9.7, §10.4–§10.6, §13.4, §14.5, D-059, D-205 |
| `src/build.jl` | tier classification, the probe, the feedthrough graph, the layout, embed-accept, the `Build` and its activations, deployment binding, and `compile` → `Executor{T}` — one activation's buffer set with the bodies closed over it, one owner per set, `evaluate!`/`_round!`/`apply!` on it | §8.2, §9.1–§9.4, §9.7, §10.4, D-166, D-208, D-210 |
| `src/readers.jl` | the closed read-selector family, `reads`, the internal `_compile_reads` → `Reader{T}`, `gather` as `apply!`'s twin over an executor; activation identity on readers and plans as an internal invariant | §14.4, §14.7, §14.10 |
| `src/sim.jl` | `Simulation` (owning its `exec`), the deployment keywords, the boundary macro-sequence and event phase, `init!`, `run!`/`step!`, `replay!` over the one shared run body, `attach!`/`detach!`, staging/drain/publication and the drain's replay substitution under §12.6's input mode — `mode(sim)`, the recording as the bound while it reads `:replay`, the flip back at the recording's end, `replay!`'s `to_time` as the time-addressed spelling of the halt and `live!` as the manual door back to live input — the lifecycle and termination record, the frame loop's one catch site with the species rule and the interrupt carve-out, the seam's `isfinite` sweep over `x` as the boundary's first act, the accessors | §10.2–§10.6, §11.1–§11.4, §11.8, §12.1–§12.7, §13.4–§13.6, §14.5, §14.6, D-059, D-101, D-157, D-203, D-218, D-219 |
| `src/stepper.jl` | the seam's backend side: RK4 and Heun, the retained `startpoint`, dense output | §10.2, D-017 |
| `src/localize.jl` | the frame loop: arrival sweep, θ = 0 validation, ITP bracketing, `t*` boundaries, the localization budget; the cursor's arrival/validation/trial phases | §10.4, §13.4, D-018, D-059, D-133 |
| `src/dataplane.jl` | the compiled writer and staging cells, the drain, snapshots and the log with re-decimation, the typed diagnostic kinds and cells, the framework status | §11.1–§11.4, §11.8, §12.6, D-137 |
| `src/trace.jl` | the input trace: the header captured at `init!` — resolved stores, root inputs, the writers' schemas and the deployment block — one sparse record per drained batch behind it, the only-growing schema list, `Trace.frames` and `ReplayUnknownFace.face` carrying a bare position (D-217), `trace(sim)`, and replay's up-front entry pass (`_compile_feed`): the header validated against the target build and its deployment binding, each schema against the target's root faces, and every record normalized to a compiled scatter into the `ReplayFeed` the loop's drain reads — the feed carrying the recording's length, the register the input mode beside it | §11.5, §12.7, D-029, D-038, D-101, D-176, D-217, D-218 |
| `src/roster.jl` | device/binding traits and conformance, the roster, both claim sources, the harness register | §11.3, §11.4, §11.6 |
| `src/bindings.jl` | `TableBinding`, `map_input` and the conditioning helper, binding reads resolved at attach (`ReadBindingUnresolved`, the source rule) | §11.2, §11.6, §14.4 |
| `src/devices.jl` | the device contract, the handle, the task wrapper, the init bracket and the tail under `join_timeout` | §11.1, §11.6, §12.1–§12.4, D-198 |
| `src/conditions.jl` | the condition algebra, one collecting pass behind both application registers — `resolve_condition` (values) and `compile_plan` (`Getter{P}` lenses, `SpecializedPlan`, `ConditionShapeDrift`) — root-input totality, `capture` | §14.1–§14.6, §13.1, D-063–D-068, D-204, D-205 |
| `src/trim.jl` | `TrimProblem`, the `solve` seam with `LevenbergMarquardt`, `trim!` over D-213's two-half scratch world, `TrimReport`, the `Trim*` kinds | §14.7, §14.8, D-213 |
| `test/fixtures.jl` | the suite's fixtures: the coverage component set, the named assemblies, the devices and bindings, the `condition` fragment-function idiom, `Pendulum` — user material, and no name here is known to `src/` | — |

Correctness is checked against analytically integrated references with a
tolerance, never `==` (D-163) — except the frame-top stamps, asserted bitwise
against the indexed grid time because that is the claim.

## What is deliberately absent

The long form, with reasons, is in `map.md`. In brief:

- **The Appendix C kinds whose mechanism is absent** — an absence gets no
  struct, so no `ThreadBudget`, `DeadStage`, `BundleFieldError`,
  `UserCodeFraming` or `UnboundedRun` is defined here, and
  `TapResolution` is raised by the read register alone, never by §14.10's
  absent tap register. Undefined for the same reason, their *check* being
  absent rather than their reporting: `IllegalStateLeaf`, `MissingProbeValue`,
  `AbstractAtRoot`, `TierSignatureMismatch` and `WalkingFaceAtFrozenEntry`. One
  periphery refusal is still a plain `error(...)` call with no kind — a datum
  naming no channel of a `TableBinding` (`bindings.jl` ~93) — because it runs
  inside the author's own mapping and reaches the framework as a `DeviceCrash`
  `cause`, `MalformedDatum`/`DeviceCrash` territory rather than a kind of its
  own (D-216); its two former neighbors are `DeviceContractMismatch` now.
  Absent with them: did-you-mean **ranking** (the candidate list a site holds
  is carried and rendered; nothing orders it by edit distance, and a mistyped
  *path* gets no list at all) and §11.8's maxlog renderer. Some resolution
  steps still refuse on the first violation though their kinds' policy reads
  `collected`: `resolve_source`/`resolve_dest`/`resolve_terminal`/
  `_one_level`/`_wrong_direction` in `assembly.jl`, and `classify_tier` per
  component in `build.jl` — reaching `UnknownPort`, `PathResolution`,
  `FaceDirectionConflict`, `ClassUnreadable`, `StoreWithoutUpdate` and
  `TierUnreadable`; retiring it needs a sentinel-returning resolution pass, its
  own increment. Appendix C's payload column also runs ahead of several kinds'
  fields (D-216): `AlgebraicCycle`'s wires and §5.6 classification,
  `FaceNameCollision`'s per-entry provenance, `ContainerMixed`'s element keys,
  `UnconnectedInput`'s declared type and chain level, the §8.1 shadowing notes
  on `ClassUnreadable`/`StoreWithoutUpdate`, `ClassUnreadable`/
  `TierUnreadable`'s type and declarations found, `DeclaredNotProduced`'s
  state-field list, `ProducedByTwoStages`' stage names,
  `TransparentContainerUnknown`'s container-field list, `StopFaceInvalid`'s
  binding site, `ConformanceFailure`'s simulation time (runtime only), and
  `TapResolution`'s candidates on path arms and its §14.10 half, and
  `ReplayHeaderMismatch`'s provenance pair (the build's and the trace's).
- **§9.5's always-on conformance check** (the return laws are checked once,
  at the probe); **§8.3 visibility**; auto-published ports; §13.3's
  load-bearing generic-holding check.
- **§8.8 beyond the helper pair** (the feed-list idiom, generic-holding sugar,
  required-faces declarations); **D-187's grid diagnostics** (the bound
  schedule is plain data; refusals name the anchor and the pool's GCD).
- **§14**: `linearize` (§14.10), mounting (§14.9), the NLopt fallback and the
  nominal-activation loop it would run on; sub-port-field addressing; index
  addressing in the binding register.
- **§11.7's GUI write path**, §10.7 pacing and its
  diagnostics, the §11.8 remainder (`DebtReanchor`, `ThreadBudget`,
  `UnboundedRun`, the maxlog renderer).
- **§12 beyond its built slices**: pause and the control plane's surface; the
  operator interrupt — §13.4's carve-out exists, the masking and the entry do
  not, so a stopped run can hold mid-boundary stores here. `run!` requires a
  finite `t_end`; every non-running state admits `attach!`/`detach!`.

## Stand-ins: where the prototype's shape is not the spec's

**Rule: nothing deviates silently.** Every construct a reader could mistake
for the design's is in exactly one of three places: the table above, the
absence list, or a row here naming the spec shape it replaces. Transactional:
the commit introducing a stand-in adds its row, the one retiring it deletes
it. No tooling enforces this (`src/` and `test/` are outside the design tools'
rosters); the diff review is the enforcement.

| spec shape | stand-in here | retirement |
| --- | --- | --- |
| the per-writer status rides inline in the snapshot's one per-boundary allocation — zero additional heap allocation on a quiet frame (§11.8) | a `Vector` of per-writer records built at each publication, the small extra allocation the simple shape costs | an allocation-tightening pass (an `NTuple` status type fixed per run) |

## Authoring caveats

**Declarations in a local scope never reach the framework.** Inside a `let`,
a function body or a `@testset`, `h_x(::MyComp, (; x)) = …` binds a *new local
function*, not a method of the global `h_x`, so the build sees a component
that declares nothing. Test fixtures — components, devices, bindings, traits —
live at top level for this reason (long form, and its D-164 ratification, in
`map.md`).

Traps hit more than once while building, for whoever builds next:

- the suite reaches the framework through `CadenceTests.jl`'s `import Cadence:`
  list, so a test that calls or extends a name not on it fails with an
  `UndefVarError` — add the name there. A fixture reusing a framework name
  collides loudly, where the old `Main` arrangement let it clobber silently;
- `===` has no curried form (`all(===(x), v)` fails — use a lambda); a
  `where`-clause method's `.sig` is a `UnionAll` (`Base.unwrap_unionall`
  before `.parameters`);
- a local named `events` inside `compile` shadows the `events(c)` accessor;
- assert a store's type on the `Ref` — `(v[ci]::Base.RefValue{S})[]` — never
  after `[]`, which boxes 16 bytes;
- **a type's printed form depends on the printing module**, so never
  interpolate one into a name a test or a trace compares: `string(typeof(x))`
  reads `Pad` from `Main` and `Main.CadenceTests.Pad` from the test module.
  Every payload field and writer label naming a *user* type goes through
  `_typename` (`diagnostics.jl`), which is `nameof` and so module-independent;
  the two `string(typeof(...))` left in `trim.jl` name a *framework* type on
  purpose, parameters and all. `Symbol(::Type)` has the same dependence — key
  buffers with `_cell_key`;
- the init-service keyword is `t0` (the spec's signatures, D-110) while the
  *concept* and `Clock`'s field stay `t₀` — `clock.t₀ = t0` inside `init!`
  is that split, not a typo; don't unify them.
