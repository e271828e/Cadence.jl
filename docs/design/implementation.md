# Implementation status

The walking skeleton for the framework in `spec.md`,
built to keepable standards and grown one increment at a time — increments 2–24
so far (increment 1, the cell-store bench, is frozen in `prototypes/cellstore_bench`;
D-162 cites its numbers). This file is the prototype's one register. Read it
first, and alone. Why a given test asserts what it does is carried by the
suite itself: every testset name states its property and cites the section it
answers to, and the comments carry the reasoning.

## Running the suite

From the repository root:

    julia --project=test test/runtests.jl                        # all of it
    julia --project=test test/runtests.jl roster devices trace   # named files

The suite is the `CadenceTests` module in `test/CadenceTests.jl`: the includes,
the `import Cadence:` list, `runall()` — the grouped tree the summary shows —
and `runonly(names...)`. Each file's tests are one function, which is what the
second form runs. The tests are their own workspace member (`[workspace]
projects = ["test"]`, Julia 1.12), so one root `Manifest.toml` resolves both
and `Cadence` needs no `develop`. No `Manifest.toml` is committed.

The full run costs about 5 min. A cold process spends about 30 s before the
first file's tests run and little per file after, so name a generous set
rather than a minimal one; going finer than a file buys nothing against that
floor. In a live session re-running one file's function
(`CadenceTests.test_trace()`) is the tightest loop there is. An `src/` edit
adds a precompile of about 15 s to the first run after it.

Which test files a change can reach is a guess off the table below; the gate
is what makes a wrong one harmless. `sim.jl`, `store.jl` and `diagnostics.jl`
are cross-cutting and mean all of it.

**None of the above is the gate. Before trusting a green suite, run**

    julia --project=. -e 'using Pkg; Pkg.test()'

which is stricter, and slower for it. `--project=test` leaves three ambient
sources on the load path that can satisfy a dependency the suite never
declared — packages the developer's `startup.jl` loads into `Main`, the
default environment, and the stdlib directory — and each has already masked
one. `Pkg.test()` runs in a sandbox holding the declared dependencies alone,
with `--startup-file=no` and `--check-bounds=yes`; the suite is green under
bounds checking, so that costs a separate precompile of the tree and nothing
else.

## What is real here

One line per file: which constructs live where, and the sections they answer
to. For more than a line, read the file itself and the sections it cites.

| file | implements | spec |
| --- | --- | --- |
| `src/Cadence.jl` | the package module: the dependencies and the include order the other files load in | — |
| `src/leaves.jl` | the leaf walk: flatten / reconstruct / the activation retype, and `leaf_names`' dotted spelling of a flat position | §7.1, §7.2, §13.4 |
| `src/diagnostics.jl` | the diagnostic kinds with `severity`/`path`/`message`, `_typename` (a user type's name for a payload field or a label), the `BuildError` carrier and its compiler-style rendering, `logline`, `InternalInvariant`, §13.4's runtime trio — `CursorFrame`, `StepError` and `NonfiniteState` — and §12.7's replay trio, `ReplayHeaderMismatch`/`ReplaySchemaMismatch`/`ReplayUnknownFace`, whose `face` carries a bare position where no schema resolves it and the name where one does | §13.1, §13.2, §13.4, Appendix C, D-058, D-059, D-157, D-214, D-215 |
| `src/declare.jl` | the declaration layer: both tiers' name families and arities, the bundle law, `probe_value`, the connection declarations beside `transparent_container`, the rate registers with `sample_times`, the event surface | §2.1, §5.2, §8.2, §8.5–§8.7, §9.3, D-179, D-185, D-195, D-211 |
| `src/assembly.jl` | class by declaration shape; children and containers with their collision family; `Group`, the anonymous assembly; paths and §6.1's one-level rule; endpoint and face resolution with the root's face invariants; the flatten pass, its two-sided face graph and the sample-time fold; §13.3's `resolve`/`resolve_terminal`/face-list primitives and §8.8's `input_passthrough`/`output_passthrough` | §6.1, §8.5–§8.8, §9.1, §9.2, §13.3, D-171, D-207–D-212 |
| `src/store.jl` | per-eltype cell stores, the `StoreBundle`, gather/scatter, `_cell_key`, the `Clock` | §9.7, D-162 |
| `src/executor.jl` | entries, the chunked unrolled walk, the interior/boundary split, the `(idx − Φ) % D` gate and boundary zero's `ESTABLISH` beside it, the event set with its registers and the guard/fire/project walks, and the execution cursor every entry stores into | §5.3, §9.7, §10.4–§10.6, §13.4, §14.5, D-059, D-205 |
| `src/build.jl` | tier classification, the probe and the event probe, the feedthrough graph, the layout, embed-accept, the `Build` and its activations, deployment binding, and `compile` → `Executor{T}` — one activation's buffer set with the bodies closed over it, one owner per set, `evaluate!`/`_round!`/`apply!` on it | §5.3, §8.2, §9.1–§9.4, §9.7, §10.4, D-166, D-179, D-208, D-210 |
| `src/readers.jl` | the closed read-selector family, `reads`, the internal `_compile_reads` → `Reader{T}`, `gather` as `apply!`'s twin over an executor; activation identity on readers and plans as an internal invariant | §13.1, §14.1, §14.4, §14.7, §14.10 |
| `src/sim.jl` | `Simulation` (owning its `exec`), the deployment keywords, the boundary macro-sequence and the §10.6 event phase with its `FiringBudget` degradation, `init!`, `run!`/`step!`, `replay!` over the one shared run body, `attach!`/`detach!`, staging/drain/publication with the drain's replay substitution, §12.6's input mode (`mode(sim)`, `to_time`, `live!`), the lifecycle and termination record, the frame loop's one catch site with the species rule and the interrupt carve-out, the seam's `isfinite` sweep over `x` as the boundary's first act, the accessors | §10.2–§10.6, §11.1–§11.4, §11.8, §12.1–§12.7, §13.4–§13.6, §14.5, §14.6, D-059, D-101, D-157, D-203, D-218, D-219 |
| `src/stepper.jl` | the seam's backend side: RK4 and Heun, the retained `startpoint`, dense output | §10.2, D-017 |
| `src/localize.jl` | the frame loop: arrival sweep, θ = 0 validation, ITP bracketing, `t*` boundaries, the localization budget and the `ChatteringBudget` degradation; the cursor's arrival/validation/trial phases | §10.2, §10.4, §13.4, D-018, D-059, D-133 |
| `src/dataplane.jl` | the compiled writer and staging cells, the drain, snapshots and the log with re-decimation, the typed diagnostic kinds and cells, and the published `FrameworkStatus` every snapshot carries | §11.1–§11.4, §11.8, §12.4, §12.6, §13.2, D-023, D-038, D-137 |
| `src/trace.jl` | the input trace: the header captured at `init!` (resolved stores, root inputs, writer schemas, deployment block), one sparse record per drained batch behind it, the only-growing schema list, `Trace.frames` — the drain count a replay reads its bound off — `trace(sim)`, and replay's up-front entry pass (`_compile_feed`) validating header, schemas and records, both stages collecting since D-217, into the `ReplayFeed` the drain reads | §11.5, §12.6, §12.7, §14.5, D-029, D-038, D-101, D-176, D-217, D-218 |
| `src/roster.jl` | device/binding traits and conformance, the roster, both claim sources, the harness register | §11.3, §11.4, §11.6 |
| `src/bindings.jl` | `TableBinding`, `map_input` and the conditioning helper, binding reads resolved at attach (`ReadBindingUnresolved`, the source rule) | §11.2, §11.4, §11.6, §14.4 |
| `src/devices.jl` | the device contract, the handle, the task wrapper, the init bracket and the tail under `join_timeout` | §11.1, §11.6, §12.1–§12.4, D-198 |
| `src/conditions.jl` | the condition algebra, one collecting pass behind both application registers — `resolve_condition` (values) and `compile_plan` (`Getter{P}` lenses, `SpecializedPlan`, `ConditionShapeDrift`) — root-input totality, `capture` | §9.5, §13.1, §14.1–§14.6, D-063–D-068, D-204, D-205, D-207 |
| `src/trim.jl` | `TrimProblem`, the `solve` seam with `LevenbergMarquardt`, `trim!` over D-213's two-half scratch world, `TrimReport`, the `Trim*` kinds | §9.6, §13.1, §14.5–§14.8, D-070, D-158, D-213 |
| `test/fixtures.jl` | the suite's fixtures: the coverage component set, the named assemblies, the devices and bindings, the `condition` fragment-function idiom, `Pendulum` — user material, and no name here is known to `src/` | — |

Correctness is checked against analytically integrated references with a
tolerance, never `==` (D-163) — except the frame-top stamps, asserted bitwise
against the indexed grid time because that is the claim.

## What is deliberately absent

Absent by decision, not by oversight. Where the reason is not given here, the
cited decision carries it:

- **The Appendix C kinds whose mechanism is absent** — an absence gets no
  struct (`ThreadBudget`, `DeadStage`, `BundleFieldError`, `UserCodeFraming`,
  `UnboundedRun`; likewise `IllegalStateLeaf`, `MissingProbeValue`,
  `AbstractAtRoot`, `TierSignatureMismatch` and `WalkingFaceAtFrozenEntry`,
  whose *checks* are absent; `TapResolution` comes from the read register
  alone, never §14.10's absent tap register). One periphery refusal is still
  a plain `error(...)` with no kind — a datum naming no channel of a
  `TableBinding` (`bindings.jl` ~93): it runs on the device task inside the
  author's own mapping and reaches the framework as a `DeviceCrash` `cause`,
  so D-216 leaves it there. Its two former neighbours are
  `DeviceContractMismatch` now — a device defining no `loop`, and `gather` on
  a handle whose binding declares no output side. Absent with them:
  did-you-mean **ranking** (candidate lists are carried and rendered, never
  ordered; a mistyped *path* gets no list at all) and §11.8's maxlog renderer
  (count-only display past 25 cumulative occurrences per writer × kind).
- **First-violation refusals where the kinds' policy reads `collected`**:
  `resolve_source`/`resolve_dest`/`resolve_terminal`/`_one_level`/
  `_wrong_direction` in `assembly.jl`, and `classify_tier` per component in
  `build.jl` — reaching `UnknownPort`, `PathResolution`,
  `FaceDirectionConflict`, `ClassUnreadable`, `StoreWithoutUpdate` and
  `TierUnreadable`; retiring them needs a sentinel-returning resolution pass,
  its own increment.
- **Kinds carrying less than their Appendix C payload column.** D-216 rules
  that the column is the design and the prototype's gaps stay visible as
  such, and it leaves the enumeration here: `AlgebraicCycle` no wires and no
  §5.6 real/artificial classification, `FaceNameCollision` no per-entry
  provenance, `ContainerMixed` no element keys or indices, `UnconnectedInput`
  no declared entry type and no obligation-chain level,
  `ClassUnreadable`/`StoreWithoutUpdate` no §8.1 shadowing note,
  `ClassUnreadable`/`TierUnreadable` no type and no declarations-found list,
  `DeclaredNotProduced` no state-field list, `ProducedByTwoStages` no stage
  names, `TransparentContainerUnknown` no container-field list,
  `StopFaceInvalid` no binding site (constructor vs. `run!`),
  `ConformanceFailure` no simulation time on its runtime occurrences, and
  `TapResolution` no candidates on the path-selector arms and none of
  §14.10's tap-set half.
- **§9.5's always-on conformance check** (the return laws are checked once,
  at the probe); **§8.3 visibility**; auto-published ports; §13.3's
  generic-holding check in the *load-bearing* register — increment 19 deleted
  `generically_held` when one-level routing left the structural register
  nothing to police, and nothing regrew it for the deep paths condition
  entries and trim `reads` still write, so §14.2's locality law rides as
  convention here.
- **§8.8 beyond the helper pair** (the feed-list idiom, generic-holding sugar,
  required-faces declarations); **D-187's grid diagnostics** (the bound
  schedule is plain data; refusals name the anchor and the pool's GCD).
- **§14**: `linearize` (§14.10), mounting (§14.9), the NLopt fallback and the
  nominal-activation loop it would run on; sub-port-field addressing; index
  addressing in the binding register.
- **§11.7's GUI write path**, §10.7 pacing and its diagnostics, the §11.8
  remainder (`DebtReanchor`, `ThreadBudget`, `UnboundedRun`, the maxlog
  renderer). Two unguarded edges stay: staging through a handle whose device
  was detached lands in an orphaned cell and is lost, and an
  `InterruptException` in a device loop reports as `DeviceCrash`.
- **§12 beyond its built slices**: pause and the control plane's surface; the
  operator interrupt — §13.4's carve-out exists, the masking and the entry do
  not, so a stopped run can hold mid-boundary stores here. `run!` requires a
  finite `t_end`; every non-running state admits `attach!`/`detach!`.

## Stand-ins: where the prototype's shape is not the spec's

**Rule: nothing deviates silently.** Every construct a reader could mistake
for the design's is in exactly one of three places: the table above, the
absence list, or a row here naming the spec shape it replaces. Transactional:
the commit introducing a stand-in adds its row, the one retiring it deletes
it. `check_refs.jl` and `check_rows.jl` read this file, so every `§N` and
`D-nnn` below resolves or the tools go red. The rule itself is unenforceable —
no tool can see a deviation nobody wrote down — and `src/` and `test/` sit
outside every roster, so the diff review is what holds it.

| spec shape | stand-in here | retirement |
| --- | --- | --- |
| the per-writer status rides inline in the snapshot's one per-boundary allocation — zero additional heap allocation on a quiet frame (§11.8) | a `Vector` of per-writer records built at each publication, the small extra allocation the simple shape costs | an allocation-tightening pass (an `NTuple` status type fixed per run) |

Two readings run ahead of the spec's letter, flagged for the spec pass:

- **The species rule is the prototype's spelling.** §13.4 says a conformance
  failure "is thrown as its typed diagnostic at the table-write point, and it
  arrives at the same catch site. There it is a species of `StepError`",
  without saying how the catch site recognizes one. Here a `BuildError`
  carrying exactly one diagnostic, thrown inside the sequence, arrives
  unwrapped as that diagnostic — which keeps the catch site the only
  `StepError` constructor while letting a runtime check throw its own kind. A
  multi-diagnostic carrier stays raw, having no single species.
- **Boundary zero sits outside the catch.** `init!` and `replay!` run it as
  stopped-sim services and propagate raw. The spec calls boundary zero "the
  ordinary macro-sequence with an empty integrate" and a legal replay halt, so
  a reading that wraps it too is available. The conservative choice here is
  that a service's own refusal path is not a frame, there being no frame-entry
  pointer for a frame that has not begun.

Also short of the spec's word, and needing a test before it can be called a
stand-in: §14.2 reads "rebuilding the tree per trim iteration is stack-only
construction", which does not hold for a tree carrying `at` prefixes — an `at`
node holds a `String` and is not isbits, so construction allocates. The
register's own write is free and asserted so (`test_conditions.jl`); the
construction cost is noted in that file's comments and guarded by nothing.

## Authoring caveats

**Declarations in a local scope never reach the framework.** Inside a `let`,
a function body or a `@testset`, `h_x(::MyComp, (; x)) = …` binds a *new local
function*, not a method of the global `h_x`, so the build sees a component
that declares nothing. The periphery's declarations hit it identically: the
traits (`is_input`, `is_output`, `is_greedy`, `claims`, `reads`,
`needs_calling_task`), the device contract's four functions (`init!`, `loop`,
`shutdown!`, `unblock!`) and the mapping conventions (`map_input`,
`map_output`) — a trait bound inside a `@testset` is a local function the
conformance check never sees, and a local `loop` leaves the global fallback in
place, crashing the device by name. Test fixtures live at top level for this
reason. D-164 ratified the check that would name the trap — a component
declaring nothing and defining no stage is a build error — but `DeadStage` is
not built; increment 4 catches the case one stratum earlier, a component with
no declarations having no *class* to read either (§8.5).

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
