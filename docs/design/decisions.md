# Framework Design Decisions

The decision log for the modeling & simulation framework specified in
`spec.md`. Each entry records a settled decision and — the reason
this file exists — the alternatives that were considered and rejected, with
the reasoning that rejected them.

Entries are identified as `D-nnn`. Identifiers are stable and never reused;
they preserve the row numbers of this log's earlier table form. The spec and
its companions cite entries by identifier, as links into this file. Entries
appear in numeric — that is, chronological — order.

Each entry states its **current** position under a fixed set of fields:
**Status** (`ratified`, or `superseded → D-nnn` when a later entry replaced
it), **Position** (the ruling), **Spec** (the sections of `spec.md`
where the decided mechanism lives), **Rationale**, **Rejected** (one item per
rejected alternative — where a position was revised within a surviving
decision, the superseded position appears here with the reason it fell), and
occasionally **Divergence** (explicit contrasts with other tools). The full
chronological evolution of the design lives in the git history of
`framework_design.md`, the original document from which the spec and this log
were derived.

## Index

| ID | Title | Status |
|---|---|---|
| [D-001][d-001] | Hybrid causal formalism with two-tier events and projection | ratified |
| [D-002][d-002] | Adopt the causal, port-based paradigm | ratified |
| [D-003][d-003] | Component taxonomy: hybrid primitive, periodic discrete, assemblies | ratified |
| [D-004][d-004] | Immutable value signals in a typed signal table | ratified |
| [D-005][d-005] | Reject algebraic loops at build | ratified |
| [D-006][d-006] | Two-stage structural feedthrough via `h_x`/`h_xu` | ratified |
| [D-007][d-007] | Aggregation mechanism | superseded → [D-037][d-037] |
| [D-008][d-008] | Function-valued environment signals with the handle pattern | ratified |
| [D-009][d-009] | Restrict deep paths to owned assembly types | superseded → [D-207][d-207] |
| [D-010][d-010] | Structure continuous state as immutable values over a flat backing | ratified |
| [D-011][d-011] | Eltype genericity on the continuous path | ratified |
| [D-012][d-012] | Set-propagation tracers and SCC-based cycle diagnostics | ratified |
| [D-013][d-013] | Immutable discrete state via cells, workspace, and snapshot | ratified |
| [D-014][d-014] | Scoped allocation invariant, CI-enforced | ratified |
| [D-015][d-015] | Fused evaluation of derivatives and outputs | ratified |
| [D-016][d-016] | Uniform component interfaces via `h_x` and per-event re-decode | ratified |
| [D-017][d-017] | Framework-owned simulation loop with a stepper seam | ratified |
| [D-018][d-018] | Tier-2 event localization via dense output and bracketed root-finding | ratified |
| [D-019][d-019] | Harmonic tick grid with virtual assemblies and rate scopes | ratified |
| [D-020][d-020] | Boundary event phase iterates to quiescence | ratified |
| [D-021][d-021] | Pacer: piecewise-affine wall-clock mapping with bounded debt | ratified |
| [D-022][d-022] | Periphery architecture: no shared mutable model | ratified |
| [D-023][d-023] | Snapshot publication via atomic acquire-release | ratified |
| [D-024][d-024] | Inbound staging: per-device atomic batch cells | ratified |
| [D-025][d-025] | One uniform device kind | ratified |
| [D-026][d-026] | GUI write path: panels name their own ports | ratified |
| [D-027][d-027] | Pacer coarse phase uses task-yielding sleep | ratified |
| [D-028][d-028] | Next-snapshot wait via monotonic counter and condition variable | ratified |
| [D-029][d-029] | Input trace on by default | ratified |
| [D-030][d-030] | Shutdown protocol: publish, wake, unblock, join | ratified |
| [D-031][d-031] | Mid-run mutation doctrine: staging and control commands only | ratified |
| [D-032][d-032] | Component declaration: trait layer with probe-checked schema authority | ratified |
| [D-033][d-033] | Declaration inventory: by-value, by-type, by-allocation conventions | ratified |
| [D-034][d-034] | Contract visibility: declared fields are public | ratified |
| [D-035][d-035] | Stores and views: components read zero-copy view bundles | ratified |
| [D-036][d-036] | Table mechanics: stage returns are NamedTuples of port values | ratified |
| [D-037][d-037] | Aggregation by explicit summing junctions | ratified |
| [D-038][d-038] | Snapshot and log: derived trajectory, primary trace header | ratified |
| [D-039][d-039] | Assembly declaration is type-based | ratified |
| [D-040][d-040] | Slash-string paths as the canonical path form | ratified |
| [D-041][d-041] | Dedicated `exports` for assembly faces | ratified |
| [D-042][d-042] | `rates` declaration on immediate children only | ratified |
| [D-043][d-043] | Computed exports via ordinary code and `faces` | ratified |
| [D-044][d-044] | Slot exclusivity and the write-surface rule | ratified |
| [D-045][d-045] | Periphery input semantics: derived liveness, conditioning, mappings, edge logic | ratified |
| [D-046][d-046] | Face names are opaque string tokens; slash is reserved for structure | ratified |
| [D-047][d-047] | Stage widgets on interaction events, not every pass | ratified |
| [D-048][d-048] | Three-stratum build pipeline: structure, schedule, activation | ratified |
| [D-049][d-049] | Standalone `build(world)` artifact wrapped by `Simulation` | ratified |
| [D-050][d-050] | Probe every user function once at build, at nominal `T` | ratified |
| [D-051][d-051] | Synthesize probe inputs via a `probe_value(::Type)` fallback chain | ratified |
| [D-052][d-052] | Scope Dual probing to each activation's executable set | ratified |
| [D-053][d-053] | Bake one always-on conformance check at every table write | ratified |
| [D-054][d-054] | Producers determine activation types; consumers stay generic | ratified |
| [D-055][d-055] | Require strict `local_types` declaration for cross-stage cells | ratified |
| [D-056][d-056] | Uphold the two-kind taxonomy against the integrate-and-dump challenge | ratified |
| [D-057][d-057] | Batch declarative-check violations; abort on first user-code exception | ratified |
| [D-058][d-058] | Diagnostics as structured values under one `BuildError` carrier | ratified |
| [D-059][d-059] | Catch runtime failures at one boundary site into `StepError` | ratified |
| [D-060][d-060] | Graceful termination is model state, never an exception | ratified |
| [D-061][d-061] | `resolve` walks declared types to enforce the generic-boundary rule | ratified |
| [D-062][d-062] | Tooling commitments: face predicates, build printer, component library | ratified |
| [D-063][d-063] | Conditions are path-addressed sparse overlays on `init_*` defaults | ratified |
| [D-064][d-064] | Compose per-component init by pull, via fragment functions | ratified |
| [D-065][d-065] | Fragments form a lazy inert tree, resolved against the `Build` | ratified |
| [D-066][d-066] | Two ways to apply one plan: specialized `apply!` vs dynamic entry-list walk | ratified |
| [D-067][d-067] | Boundary zero runs the macro-sequence with an empty integrate | ratified |
| [D-068][d-068] | Enforce slot totality at the init/commit service boundary | ratified |
| [D-069][d-069] | Trim problem spelling: NamedTuples, residual vector, exact AD Jacobians | ratified |
| [D-070][d-070] | Trim service: in-house dense LM behind a swappable backend | ratified |
| [D-071][d-071] | Mount trim as an implicitly specified condition via `at` | ratified |
| [D-072][d-072] | Linearization surface: three selector lists, one chunked Dual pass | ratified |
| [D-073][d-073] | Companion sketches carry the settled condition-algebra design | ratified |
| [D-074][d-074] | Hand off component-function arguments as one named bundle | ratified |
| [D-075][d-075] | Name flow/update/output stages by letter and dependence class | ratified |
| [D-076][d-076] | Name declarations `input_types`/`output_types`/`local_types` by convention | ratified |
| [D-077][d-077] | Allocate workspace via a per-activation `workspace` method | ratified |
| [D-078][d-078] | Treat input entries as face constraints checked by subtyping | ratified |
| [D-079][d-079] | Type declarations concretely, resolved by an activation leaf walk | ratified |
| [D-080][d-080] | Keep Tier-2 event detection pace-independent | ratified |
| [D-081][d-081] | Treat `t*` as a boundary, not a frame | ratified |
| [D-082][d-082] | Define guard conditions against a per-event baseline | ratified |
| [D-083][d-083] | Bind output-device reads to snapshot paths, not just faces | ratified |
| [D-084][d-084] | Drop the unconnected-output warning | ratified |
| [D-085][d-085] | Unpack `Tuple`/`NamedTuple` fields as container children | ratified |
| [D-086][d-086] | Compile the executor's schedule into unrolled statically-typed entries | ratified |
| [D-087][d-087] | Freeze the device roster as a build-validated immutable value | ratified |
| [D-088][d-088] | Define the run lifecycle: built → initialized → running → stopped/errored | ratified |
| [D-089][d-089] | Route supervisor gains and resets through ordinary ports | ratified |
| [D-090][d-090] | Return handler updates as bundle-law NamedTuples | ratified |
| [D-091][d-091] | Override `t_end`/`stop_on` per run at `run!` | superseded → [D-255][d-255] |
| [D-092][d-092] | Normative diagnostic kind table (Appendix C) | ratified |
| [D-093][d-093] | Spawn device tasks per run, not per attach | ratified |
| [D-094][d-094] | Close the state-leaf vocabulary to plain scalars and `SArray`s | ratified |
| [D-095][d-095] | Prefix the read-selector family with `get_` | ratified |
| [D-096][d-096] | Define the harness writer: `stage!`/`latest`/`step!` duration | ratified |
| [D-097][d-097] | Split device shutdown failures into two diagnostic kinds | ratified |
| [D-098][d-098] | Resolve selectors against a source before client policy | ratified |
| [D-099][d-099] | Spell the CI activation invariant with a canonical probe scalar type | ratified |
| [D-100][d-100] | Freeze `u` at round start for within-round event visibility | ratified |
| [D-101][d-101] | Implement replay as the ordinary loop with two substitutions | ratified |
| [D-102][d-102] | Author-owned device loop inside a framework-owned bracket | ratified |
| [D-103][d-103] | Detect a binding's sides by method presence at attach | ratified |
| [D-104][d-104] | Coalesce staged writes by CAS merge with per-attachment positional shape | ratified |
| [D-105][d-105] | Split device-side bad-datum handling into tolerated garbage and propagated crashes | ratified |
| [D-106][d-106] | Freeze the device roster for the duration of a run | ratified |
| [D-107][d-107] | Match trace record density to batch density, not surface width | ratified |
| [D-108][d-108] | Gate stopped-sim services by input-derived lifecycle preconditions | ratified |
| [D-109][d-109] | Fix device identity, roster admission and calling-task topology at attach | ratified |
| [D-110][d-110] | Give `trim!` an explicit `t0` argument and state its recording clear | ratified |
| [D-111][d-111] | Fold `project` into the always-on conformance check | ratified |
| [D-112][d-112] | Add `events` to the tier-consistency markers | ratified |
| [D-113][d-113] | Close four kindless diagnostic rules with new payload fields | ratified |
| [D-114][d-114] | Order snapshot publication before the boundary counter increment | ratified |
| [D-115][d-115] | Source the bundle law's remaining probe fields `t` and `ws` | ratified |
| [D-116][d-116] | Expose `phase_bodies(sim)` as the zero-allocation invariant's measurement seam | ratified |
| [D-117][d-117] | Extend declarations and stages via explicit per-name import | ratified |
| [D-118][d-118] | TrimProblem authoring surface | ratified |
| [D-119][d-119] | Add `Simulation(build::Build; …)` as a second constructor | ratified |
| [D-120][d-120] | Reconcile rigs with abstract-at-root via stub children | ratified |
| [D-121][d-121] | Partition the cell/store vocabulary and bless "staging cell" | ratified |
| [D-122][d-122] | Resolve de-polysemy by giving each overloaded term one owner | ratified |
| [D-123][d-123] | Add a non-normative Appendix D glossary | ratified |
| [D-124][d-124] | Widen §14.7's `reads` grammar to the full service selector set | ratified |
| [D-125][d-125] | Admit `get_face` to the service `reads` set | ratified |
| [D-126][d-126] | Give trim-commit events a report channel | ratified |
| [D-127][d-127] | Add a deployment block to the trace header for replay validation | ratified |
| [D-128][d-128] | Define `to_boundary` as the frame-entry boundary index | ratified |
| [D-129][d-129] | Restate the two-notation rule as directional (structure vs contract) | ratified |
| [D-130][d-130] | Scope `resolve`'s generic-boundary duty by client (wiring/service/inspection) | ratified |
| [D-131][d-131] | Apply the round-4 consistency sweep (findings 4–11) | ratified |
| [D-132][d-132] | Treat operator interrupt (Ctrl-C) as a control-plane stop, not a failure | ratified |
| [D-133][d-133] | Split spec-invoked numeric constants into deployment parameters vs owning-section defaults | ratified |
| [D-134][d-134] | Declare the interactive write-surface class via a binding marker method | ratified |
| [D-135][d-135] | Scope the activation cache to immutable compiled artifacts, keyed on the Build | ratified |
| [D-136][d-136] | Unify diagnostics and liveness heartbeat into one per-writer diagnostic cell | ratified |
| [D-137][d-137] | Bound snapshot-log retention by count, with amortized doubling stride | ratified |
| [D-138][d-138] | Make device `init!` an explicit, bracketed step of the run-start protocol | ratified |
| [D-139][d-139] | Give environment field handles a value-level constructor to prevent drift | ratified |
| [D-140][d-140] | Add a three-rung remedy ladder for artificial algebraic-loop dependencies | ratified |
| [D-141][d-141] | Continuous state resets are events, owned by the reimplemented PIVector | ratified |
| [D-142][d-142] | Stage code must be total over type-valid inputs | ratified |
| [D-143][d-143] | Add a `Constant` source block for zero-contributor aggregates | ratified |
| [D-144][d-144] | Rename the computed-exports helper `faces` to `passthrough` | ratified |
| [D-145][d-145] | Deduplicate pass-through `except` lists with a shared feed-list idiom | ratified |
| [D-146][d-146] | Rename `faces`/`selectors` to `claims`/`reads` on the binding interface | ratified |
| [D-147][d-147] | Split the sweep into static interior and boundary variants | ratified |
| [D-148][d-148] | Select converters per leaf by resolved condition-shape type | ratified |
| [D-149][d-149] | Check slot totality wherever a virgin world is established | ratified |
| [D-150][d-150] | Make the service the sole authority on convergence | ratified |
| [D-151][d-151] | Canonicalize NamedTuple field order at every author↔framework seam | ratified |
| [D-152][d-152] | Join auto-publication to the per-event re-decode at stage 1 | superseded → [D-154][d-154] |
| [D-153][d-153] | Add re-arm tracking to complete the once-per-event rule | ratified |
| [D-154][d-154] | Remove per-event re-decode; serialize same-component events | ratified |
| [D-155][d-155] | Name projection as the second legitimate mover of the committed point | ratified |
| [D-156][d-156] | Legalize the three degenerate trim/integration shapes | ratified |
| [D-157][d-157] | Check for nonfinite `x` immediately after integrate | ratified |
| [D-158][d-158] | Pin the backend seam to one required `solve` signature | ratified |
| [D-159][d-159] | Define `warning (service)` as a sixth severity | ratified |
| [D-160][d-160] | Rename `report` to `report!` | ratified |
| [D-161][d-161] | Grow the naming audit to the full class-violation set | ratified |
| [D-162][d-162] | Adopt per-eltype homogeneous cell stores over per-instance | ratified |
| [D-163][d-163] | Ban `==` for separately-compiled float comparisons | ratified |
| [D-164][d-164] | Reject components that declare nothing and define no stage | ratified |
| [D-165][d-165] | Split output-stage returns into public `y` and private `w` | superseded → [D-194][d-194] |
| [D-166][d-166] | Mandate `Type{T}` output signatures on continuous producers | ratified |
| [D-167][d-167] | Mandate `Type{T}` input signatures under the permissive reading | ratified |
| [D-168][d-168] | Root-slot fan-out tolerance combines by meet, not agreement | ratified |
| [D-169][d-169] | `y_x`/`y_z` carry stage-1 ports only, auto-published excluded | superseded → [D-252][d-252] |
| [D-170][d-170] | Split assembly connections into child/input/output declarations | ratified |
| [D-171][d-171] | Rename `passthrough` to `input_passthrough` | ratified |
| [D-172][d-172] | Rule "face" kind-blind, defined at first use | ratified |
| [D-173][d-173] | Fuse the discrete state letter `z` into `x` | superseded → [D-195][d-195] |
| [D-174][d-174] | Re-class the GUI as an ordinary enumerated writer | ratified |
| [D-175][d-175] | Re-scope `gui = true` to a run-scoped attachment | ratified |
| [D-176][d-176] | Unify trace retention on one sparse record format | ratified |
| [D-177][d-177] | Re-found the periphery on mandatory roots plus declared traits | ratified |
| [D-178][d-178] | Reaffirm component-side rejections against the periphery's new idiom | ratified |
| [D-179][d-179] | Derive detection policy from the guard's return type | ratified |
| [D-180][d-180] | Bank per-event `direction` as an unbuilt guarded addition | ratified |
| [D-181][d-181] | Replace once-per-boundary firing with budgeted re-firing | ratified |
| [D-182][d-182] | Add a θ=0 validation probe to the localization trigger | ratified |
| [D-183][d-183] | Retire workspace poisoning | ratified |
| [D-184][d-184] | Fold `Group` into the spec as an ordinary library component | ratified |
| [D-185][d-185] | Adopt the phased, two-form sample-time declaration | ratified |
| [D-186][d-186] | Legalize absolute declarations in any scope via anchors | ratified |
| [D-187][d-187] | Make the bound schedule a named artifact with exact grid diagnostics | ratified |
| [D-188][d-188] | Construct `TrimProblem` by keyword everywhere | ratified |
| [D-189][d-189] | Unify `report!` on a single `(address, diagnostic)` shape | ratified |
| [D-190][d-190] | Reject a separate `derivative_type` declaration | ratified |
| [D-191][d-191] | Defer, not consume, the edge on a blocked event | ratified |
| [D-192][d-192] | Let the greedy claim empty the harness remainder | ratified |
| [D-193][d-193] | Keep per-writer liveness on one timestamp plus task state | ratified |
| [D-194][d-194] | Retire the `w` channel: intermediates are declared ports | ratified |
| [D-195][d-195] | Give the discrete state its own letter `s` | ratified |
| [D-196][d-196] | Rename the phase-body sweeps to stage-numbered names | ratified |
| [D-197][d-197] | Reject discrete stores in linearization's `x`-tap list | ratified |
| [D-198][d-198] | Promote the shutdown join timeout to a deployment keyword | ratified |
| [D-199][d-199] | The `reads` enumeration returns a labeled NamedTuple of selectors | ratified |
| [D-200][d-200] | The harness writer has its own cell and is diagnostic only | ratified |
| [D-201][d-201] | The terminal account closes at the final frame top | ratified |
| [D-202][d-202] | Stage batches as values plus touched-mask, never union tuples | ratified |
| [D-203][d-203] | The termination record carries typed sources and the tail residue | ratified |
| [D-204][d-204] | Rename the condition algebra's symmetric combinator to `combine` | ratified |
| [D-205][d-205] | Boundary zero publishes every discrete output stage, due or not | ratified |
| [D-206][d-206] | Rename root slots to root inputs | ratified |
| [D-207][d-207] | Route every connection one level: faces are the only cross-boundary currency | ratified |
| [D-208][d-208] | Root inputs are the root component's input faces, whatever its class | ratified |
| [D-209][d-209] | Build `output_passthrough` | ratified |
| [D-210][d-210] | Tighten the input boundary: class-uniform face uniqueness and no empty routing | ratified |
| [D-211][d-211] | Let a component declare one container name-transparent | ratified |
| [D-212][d-212] | Refuse the transparent bare key that shadows a sibling container field | ratified |
| [D-213][d-213] | Establish a service's frozen cells from the authored discrete state | ratified |
| [D-214][d-214] | Split Appendix C's severity column into severity, raised and policy | ratified |
| [D-215][d-215] | Extend Appendix C with the kinds the prototype raised | ratified |
| [D-216][d-216] | Conform Appendix C to the prototype's diagnostic sites | ratified |
| [D-217][d-217] | Conform the trace and replay sections to the prototype's record | ratified |
| [D-218][d-218] | Make the replay/live distinction an explicit input mode | ratified |
| [D-219][d-219] | Add a time-addressed replay halt and a manual door to live | ratified |
| [D-220][d-220] | Rename the authoring family to words: stage, update, projection, event and workspace declarations | ratified |
| [D-221][d-221] | Unwrap a single-diagnostic carrier at the runtime catch site into a `StepError` species | ratified |
| [D-222][d-222] | Replace `BuildError` with the policy-parametric `DiagnosticError` carrier | ratified |
| [D-223][d-223] | Host the runtime catch in boundary zero under the service's disposition | ratified |
| [D-224][d-224] | Let a throw inside a trim commit propagate as the commit's `StepError` | ratified |
| [D-225][d-225] | Parametrize `StepError` on its cause's type | ratified |
| [D-226][d-226] | Reach the public surface by qualified name until §16's export audit | ratified |
| [D-227][d-227] | Select the stepper by type under the `algorithm` keyword | ratified |
| [D-228][d-228] | Attribute runtime diagnostics by cell, never by payload | ratified |
| [D-229][d-229] | Collect to the stratum barrier under a dependency rule | ratified |
| [D-230][d-230] | Stamp the snapshot with the trajectory's boundary ordinal, not the wait counter | ratified |
| [D-231][d-231] | Require isbits store values, checked at build | ratified |
| [D-232][d-232] | Refuse the roster operations on an errored simulation | ratified |
| [D-233][d-233] | Retire the termination record's absent-time arm | ratified |
| [D-234][d-234] | Rename the deployment keyword `n` to `N_base` | ratified |
| [D-235][d-235] | Realize the always-on check at the generated write, against the cell type | ratified |
| [D-236][d-236] | Type-check a wire by one relation with embedding, in Stratum A | ratified |
| [D-237][d-237] | Classify a non-isbits immutable port type as one opaque leaf | ratified |
| [D-238][d-238] | Decide embed-accept on the type: lift the arrival, compare exactly | ratified |
| [D-239][d-239] | Report a typo'd return field alone, without the unproduced port | ratified |
| [D-240][d-240] | Read the heartbeat at publication, beside the task state | ratified |
| [D-241][d-241] | Keep the status a vector of records, one small allocation per publication | ratified |
| [D-242][d-242] | Name the resolution cases wiring, service and inspection, and retire "register" and "load-bearing" as spec vocabulary | ratified |
| [D-243][d-243] | Classify `Symbol` as an opaque port leaf | ratified |
| [D-244][d-244] | Refuse the write primitives of a detached handle by name | ratified |
| [D-245][d-245] | Classify a cycle cluster by a surviving traced cycle and carry each member's tracing mode | ratified |
| [D-246][d-246] | Diagnose a foreign declaration binding as its own fail-fast kind | ratified |
| [D-247][d-247] | Accept the `NamedTuple` as the only store declaration form | ratified |
| [D-248][d-248] | Frame every user-authored method the build invokes, declarations included | ratified |
| [D-249][d-249] | Settle three payload columns: contract arity, runtime time and face provenance | ratified |
| [D-250][d-250] | Warnings live where the artifact criterion puts them | ratified |
| [D-251][d-251] | Make the passthrough selectors exclusive and warn on an empty selection | ratified |
| [D-252][d-252] | Remove auto-publishing: two port classes, exposed state returned by stage 1 | ratified |
| [D-253][d-253] | Stratum products as artifacts: `Structure`, `Dataflow`, `Events`, one activation store | ratified |
| [D-254][d-254] | `Deployment` and `Schedule` as artifacts between the build and the simulation | ratified |
| [D-255][d-255] | `Run`, the trace split and `StopPolicy` | ratified |
| [D-256][d-256] | Regroup the `Simulation`'s fields by owner | ratified |
| [D-257][d-257] | Each artifact renders itself | ratified |
| [D-258][d-258] | "Schedule" is the tick timing and "execution order" the stage sequence | ratified |
| [D-259][d-259] | Retire the strata: the build is three steps named by their products | ratified |
| [D-260][d-260] | Trim the run to what lasts it and retire the trace register | ratified |
| [D-261][d-261] | Three ownership rules for fields, with the placements they settle | ratified |

### D-001 — Hybrid causal formalism with two-tier events and projection

**Status.** ratified

**Position.** Hybrid causal formalism; two-tier events; projection; no
DAE/SDE/per-step hook. Tier-2 detection is pace-independent ([D-080][d-080]); guard
conditions are normative — positive = holding, edge semantics ([D-082][d-082]).

**Spec.** [§2.2][s2-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *DAEs:* projection suffices.
- *SDEs:* shaping filters suffice.
- *`f_step!`:* step-size-dependent semantics.

### D-002 — Adopt the causal, port-based paradigm

**Status.** ratified

**Position.** Causal port-based paradigm.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Acausal/MTK:* fights interactivity, discrete logic, live introspection.
- *Hierarchical callables:* rigor by convention — today's footguns.
- *Thin SciML library:* nothing for GUI/logging/hierarchy to hang onto.

### D-003 — Component taxonomy: hybrid primitive, periodic discrete, assemblies

**Status.** ratified

**Position.** Taxonomy: hybrid continuous primitive + periodic discrete +
assemblies; both mode factorings.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Strict purity/no modes:* loses reset maps; latch logic becomes wiring
  ceremony.
- *Uniform hybrid kind:* intra-component ordering semantics murky.

### D-004 — Immutable value signals in a typed signal table

**Status.** ratified

**Position.** Immutable value signals in a typed signal table.

**Spec.** [§4.1][s4-1]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Shared mutable buffers:* aliasing/staleness, concurrent-read hazards.
- *Mixed semantics:* second thing to document/test.
- *A monolithic per-component `y` struct:* freshness is per-struct, so it can
  be half-fresh mid-sweep with no way for a reader to tell — per-cell freshness
  is tied to the producer's schedule position.

### D-005 — Reject algebraic loops at build

**Status.** ratified

**Position.** Reject algebraic loops at build, explicit breaks.

**Spec.** [§5.5][s5-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Implicit delays:* silent math changes.
- *Per-step numerical solving:* jitter, runtime failures; additionally
  conflicts with immutable signals — the iterate has nowhere to live under
  value semantics.

### D-006 — Two-stage structural feedthrough via `h_x`/`h_xu`

**Status.** ratified

**Position.** Strict two-stage structural feedthrough (state decoder `h_x` +
all-inputs `h_xu`, named per [D-075][d-075]); component split as the refinement.

**Spec.** [§7.4][s7-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *N output groups with declared input subsets:* declaration/validation surface
  for a case that never materialized.
- *Per-output declarations + tracer verification:* under-declaration = silent
  wrongness.
- *Traced multi-pass:* hot-path cost, branch unsoundness.
- *Component-atomic conservative:* false loops everywhere.

### D-007 — Aggregation mechanism

**Status.** superseded → [D-037][d-037]

**Position.** Aggregation is by explicit summing junctions ([D-037][d-037]).

**Spec.** [§6.2][s6-2], [§8][s8]

**Rationale.** See [D-037][d-037] for the surviving decision.

**Rejected.**
- *Superseded position — reduce-ports with a canonical fold (the earlier design
  of record):* reversed because it was the declaration vocabulary's last
  wrapper, a three-site census (all Newton–Euler, one library file) could not
  justify canonical-fold, multi-connection legality and identity-element
  machinery, and the aggregate wasn't even observable.
- *Σ-junctions as default:* arity/positional ceremony — objection dissolved by
  [§8][s8]'s loud declarations.
- *Contribution buses:* invisible dataflow — verdict unchanged; they also
  import scoping rules and admit accidental contributions — a component
  contributes by being in scope rather than by being wired.

### D-008 — Function-valued environment signals with the handle pattern

**Status.** ratified

**Position.** Function-valued environment signals + handle pattern.

**Spec.** [§4.4][s4-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Resource injection:* second composition mechanism, invisible.
- *Pre-sampling as mechanism:* dependency inversion at struts.

### D-009 — Restrict deep paths to owned assembly types

**Status.** superseded → [D-207][d-207]

**Position.** Deep paths within owned assembly types only.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Unrestricted deep wiring:* breaks substitutability across generic
  boundaries.
- *Strict one-level:* re-export ceremony.

### D-010 — Structure continuous state as immutable values over a flat backing

**Status.** ratified

**Position.** Structured immutable state over a framework-owned flat
`Vector{T}`.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Mutable views:* aliasing; silent missing-ẋ.
- *Fully structured, no flat vector:* the same machinery is needed anyway;
  loses the standard integrator interface.

### D-011 — Eltype genericity on the continuous path

**Status.** ratified

**Position.** Eltype genericity on the continuous path, three-tier scoping.

**Spec.** [§7.2][s7-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Float64-only + finite differences:* FD noise, keeps hand-written state-space
  layer, no tracer.

### D-012 — Set-propagation tracers and SCC-based cycle diagnostics

**Status.** ratified

**Position.** Set-propagation tracers (global + sampled-local),
diagnostic-only; cycle diagnostics from SCC decomposition of the Stratum-B
topological stall (one SCC = one named loop), classified by a schedule-free
per-member local trace at the probe point (each member evaluated once in
isolation; in-cycle cells from `probe_value` under tracer tags) — real iff
every structural hop survives, artificial iff one dies; conservative on
discrete members (pinned signatures admit no tracer scalar), classification
optional on the error. Superseded on the verdict clause by [D-245][d-245] — over a
cluster the loop is real iff a traced cycle survives, which reduces to this
reading on a simple cycle.

**Spec.** [§5.6][s5-6], [§9.4][s9-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Dual-based tracing:* derivative-zero blind spot.
- *Tracing as scheduling input:* soundness.
- *Naming the cycle by the topological stall's raw residue:* over-reports — the
  residue holds the innocent downstream cone.
- *Naming the cycle by a single DFS back edge:* under-reports — one edge of a
  possibly large tangle; both alternatives rejected, which is what the SCC
  decomposition buys.

### D-013 — Immutable discrete state via cells, workspace, and snapshot

**Status.** ratified

**Position.** Immutable `z` in cells + workspace + snapshot idiom.

**Spec.** [§7.3][s7-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Mutable discrete state:* aliasing, snapshot cost.
- *Double-buffering:* deferred; publication races.

### D-014 — Scoped allocation invariant, CI-enforced

**Status.** ratified

**Position.** Scoped allocation invariant, CI-enforced on the hot path.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Blanket dogma:* fights logging reality.
- *No policy:* loses the type-instability canary.

### D-015 — Fused evaluation of derivatives and outputs

**Status.** ratified

**Position.** Fused evaluation: `f`/`h` read the fresh table (own `y`
included), and additionally receive state views ([D-035][d-035]); single computation
site for derivatives and outputs is the *rewarded* idiom, not an impossibility
claim.

**Spec.** [§5.3][s5-3], [§7.4][s7-4], [§15.2][s15-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Mutable caches between `f` and outputs:* S-function/FMI style — hidden
  state, purity violation.
- *Accepting duplicate computation:* drift bug class — edited law in `f`, stale
  copy in `g`.
- *Derivative binding:* a declaration feature subsumed by `y`-access.
- *Orthodox `f(x,u)` + atomization as standard idiom:* 2× components/wiring for
  the domain-normal overlap case.

### D-016 — Uniform component interfaces via `h_x` and per-event re-decode

**Status.** ratified

**Position.** Uniform component interfaces via the no-feedthrough state decoder
`h_x`, with selective auto-publication of declared state/mode fields ([D-035][d-035]);
guards and handlers read the fresh boundary table, with per-event re-decode
(`handler → project → h_x → h_xu`); `project` is the sole raw-state function
(schedule-structural).

**Spec.** [§4.2][s4-2], [§5.3][s5-3], [§7.4][s7-4], [§10.6][s10-6], [§8.3][s8-3], [Appendix D][sD]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — identity publication of state and modes as the
  default, plus an unlisted-port convention for interface noise (the earlier
  design of record):* retired because contract visibility ([D-034][d-034]) makes
  publicity a declaration, and `unlisted` pretended privacy without enforcing
  it (hidden but connectable).
- *Passing state alongside `y`:* double-passing; two idioms in the wild.
- *Fully private discrete state:* breaks uniformity; the codebase culturally
  publishes state anyway.
- *One-handler-per-component-per-boundary restriction:* the cheap per-event
  re-decode removes the need.
- *Exposing `z` without an unlisted convention:* RNG/log noise.
- *The `unlisted` motivating case — RNG state feeding the component's own
  update:* dissolved entirely once [D-035][d-035] gave every function direct `x` views,
  so nothing needed publishing to be readable.

### D-017 — Framework-owned simulation loop with a stepper seam

**Status.** ratified

**Position.** Framework-owned simulation loop; stepper seam (advance by
arbitrary `h` + on-demand dense output over the last step; one-step methods
only); in-house fixed-step RK4/Heun as the sole first-cut backends;
`OrdinaryDiffEq` dropped from dependency to possible future extension adapter.

**Spec.** [§10.1][s10-1], [§10.2][s10-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`OrdinaryDiffEq` as substrate with `CallbackSet` choreography:* semantics by
  convention in a foreign event loop; demonstrated churn — the
  `task_local_storage` regression — in exactly the interactive multi-task
  usage. The substrate rejection's evidence dossier, from FlightCore's own
  `sim.jl`: a hand-rolled periodic callback with explicit `add_tstop!`
  bookkeeping after a DiffEqCallbacks release moved `PeriodicCallback` onto
  `task_local_storage`, per-evaluation state copying in and out of the
  integrator, stateless models integrating a dummy `[0.0]`, and log saving
  detoured through `deepcopy` in a `SavingCallback` — each a tax paid to
  express our semantics in someone else's loop, which `run!` was already
  driving manually anyway.
- *Fused loop without the seam:* loses the adaptive/stiff escape hatch for
  ~zero savings.
- *Multistep methods:* history rebuild after every handler.

### D-018 — Tier-2 event localization via dense output and bracketed root-finding

**Status.** ratified

**Position.** Tier-2 localization: lazy cubic Hermite dense output + bracketed
derivative-free root-finding (ITP/Brent) on guard probes that run the sweep;
post-event interpolant invalidation + remainder step + bounded event budget
whose exhaustion *degrades* — localization off for the rest of the frame,
further crossings firing at Tier-1 granularity in the next boundary's
iteration, with a chattering warning; trajectory-determined, never wall-clock
([D-080][d-080] intact), and never a `StepError`; probes evaluate the raw interpolated
state (off-manifold like RK stages), projection running at the `t*` boundary
where [§10.6][s10-6]'s edge checks read it — a projection that undoes the crossing costs
one extra harmless boundary.

**Spec.** [§10.4][s10-4], [§10.6][s10-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Per-probe projection:* projection cost inside the root-finder loop, for
  interpolant drift far below localization tolerance.
- *Newton/AD localization:* guards C⁰ not C¹ — kinks and σ′ = 0 stretches;
  discards the bracket certificate for local guarantees; negligible savings on
  rare microsecond probes.
- *Re-integration probes:* 4× cost; σ becomes trial-h-dependent.
- *Solver-matched high-order interpolants:* only matter above order 4.

### D-019 — Harmonic tick grid with virtual assemblies and rate scopes

**Status.** ratified

**Position.** Harmonic tick grid on step boundaries; discrete stages gated to
own tick instants (ZOH by construction); assemblies virtual for execution, rate
scopes for declaration (integer multipliers $K \ge 1$ composing down the tree,
compiled to absolute divisors); `Δt` arrives as a discrete-bundle field
([D-074][d-074]), single source of truth, no stored `Δt`-derived parameters.

**Spec.** [§5.4][s5-4], [§10.5][s10-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — a `comp.Δt` virtual property (the earlier design of
  record):* impossible, because `===`-identical siblings can sit under
  different `rates` keys, so the period is a schedule-position fact, not a
  component fact ([D-074][d-074]).
- *Atomic assemblies, incl. opt-in:* coarsened schedulable unit → [§5.4][s5-4]
  artificial loops at assembly scale; interleaving protection meaningless under
  the signal table; FlightCore's whole-tree atomicity was a call-tree artifact.
  The atomic-assembly census behind that rejection: Simulink documents the
  artificial-loop hazard for its Atomic Subsystems, and the construct's other
  roles there — code-generation units, enabled/triggered execution — have no
  counterpart in the consumers, conditional behavior ("on ground, force
  `direct`") being mode logic.
- *Arbitrary tick periods via time queue:* variable `h`, irregular frames, no
  demonstrated need.
- *Absolute-period declaration as default:* welds deployment rates into
  reusable designs; base-period variables don't compose across independently
  authored assemblies.
- *Re-running discrete stages every boundary:* un-samples sampled-data
  semantics.
- *Phase offsets:* no demonstrated use.
- *`Δt` via `h`-argument only:* discretized laws live in the feedthrough stage.

### D-020 — Boundary event phase iterates to quiescence

**Status.** ratified

**Position.** Boundary event phase iterates to quiescence — rounds of full
re-sweep → guards → handlers (declaration order, per-event re-decode) — each
event firing at most once per boundary, with "newly fired" made precise via
per-event baselines in loop state ([D-082][d-082]); due `g` updates run after
quiescence, outside the iteration.

**Spec.** [§2.2][s2-2], [§3.1][s3-1], [§10.6][s10-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Single pass per boundary:* cascade latency N·h — step-size-dependent
  semantics, the [§2.2][s2-2] `f_step!` footgun class, made common by [§3.1][s3-1] externalized
  FSMs.
- *Bounded-rounds cap:* arbitrary K knob; livelock burns the budget then errors
  instead of degrading to Tier-1 granularity.
- *Event/tick fixed-point iteration:* structurally unnecessary — `z⁺` is
  invisible until the next tick decode.

### D-021 — Pacer: piecewise-affine wall-clock mapping with bounded debt

**Status.** ratified

**Position.** Pacing outside the semantics (bit-identical paced/unpaced
trajectories); piecewise-affine wall-clock map, anchor re-established at pace
change and un-pause (debt cleared, counted); absolute deadlines with bounded
debt + re-anchor on excess; `p = ∞` as explicit pacer-off; hybrid
sleep-then-spin toward `deadline − margin`, with `margin` the single knob (0 =
pure sleep, ∞ = pure busy-wait = FlightCore).

**Spec.** [§10.7][s10-7]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Relative deadlines:* permanent sim-vs-wall slip.
- *Unbounded catch-up:* burst after long stalls.
- *Keeping the anchor across pace changes:* retroactively reinterprets elapsed
  history at the new pace.
- *`p = ∞` as arithmetic limit:* perpetual-overrun diagnostics under debt
  accounting.
- *Dedicated busy-wait mode flag:* subsumed by `margin = ∞`.
- *Separate primitive-resolution threshold:* absorbed into `margin`
  calibration.

### D-022 — Periphery architecture: no shared mutable model

**Status.** ratified

**Position.** Periphery architecture: no shared mutable model — staged inputs
drained at frame top + immutable snapshot published per boundary; every handoff
one atomic reference op, GC as reclamation; no user code or unbounded work in
framework critical sections; control on a separate atomic surface (staging
cannot un-pause a drainless loop); interactive = batch + devices.

**Spec.** [§11.1][s11-1]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Transplanted `io_lock`:* loop budget hostage to arbitrary code under the
  lock; input timing scheduler-determined and unrecorded — replay undefinable
  in principle; protects a live-mutation idiom the immutable table removed.
- *Full message-passing periphery:* per-device typed channels — same design
  with heavier ceremony.

### D-023 — Snapshot publication via atomic acquire-release

**Status.** ratified

**Position.** Snapshot publication: build private → release-store `@atomic
latest`; readers acquire-load; wait-free both ways; nothing reachable from a
published snapshot ever written again; allocate per boundary; log = retained
snapshot references.

**Spec.** [§10.3][s10-3], [§11.2][s11-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Preallocated snapshot rings:* reintroduce the reader-liveness reclamation
  proof the GC already provides.
- *`deepcopy` `SavingCallback` logging:* the capture *is* the publication
  mechanism.
- *Mid-step publication:* see [§10.3][s10-3].

### D-024 — Inbound staging: per-device atomic batch cells

**Status.** ratified

**Position.** Inbound staging: one atomic batch cell per device; complete
writers overwrite, sparse writers CAS-merge own cell (retry bounded by drain
interception); drain by `atomicswap` in attachment order; conflicts resolved by
slot exclusivity ([D-044][d-044]); levels-never-deltas doctrine; mappings pure, on the
device task; device-tagged replayable input trace.

**Spec.** [§11.4][s11-4], [§15.3][s15-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — attachment order as the cross-device conflict
  precedence policy (the earlier design of record):* superseded by slot
  exclusivity, which removes the conflict instead of ranking it (the per-device
  cells, CAS merge and drain are retained for atomicity and coalescing).
- *Per-slot cells:* conflicts by hardware store order — run-to-run behavioral
  variance; cross-device peek; no trace provenance; atomic-width fallback on
  wide slots.
- *Shared batch stack:* temporal conflict order; unbounded pending under pause,
  taxing peeks.
- *Ordered write queue:* preserves intra-frame order nothing downstream can
  observe.

### D-025 — One uniform device kind

**Status.** ratified

**Position.** One device kind: uniform handle with read (snapshot /
next-boundary) + stage + control capabilities; input-only/output-only as
degenerate uses; bidirectional peer = one device; GUI an ordinary device
(main-thread affinity and RMW widgets its only peculiarities).

**Spec.** [§11.6][s11-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Input/output/GUI taxonomy:* lock choreography artifact — blocking rules of
  `get_data!`/`extract_output` under `io_lock`; forces bidirectional peers into
  two devices sharing a socket and shutdown.
- *Special-cased GUI interface:* `sync = 0` + render-under-lock ceremony,
  obsolete without the lock.

### D-026 — GUI write path: panels name their own ports

**Status.** ratified

**Position.** GUI write path: per-component panels name own ports; build-time
resolution to root input slots; live vs first-class read-only rendering (with
wiring provenance); own-pending-else-snapshot peek; active widgets stage on
interaction events ([D-047][d-047]).

**Spec.** [§11.7][s11-7]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — staging every render pass (the earlier design of
  record):* its motivating contest (two writers racing within a frame) died
  with slot exclusivity, and as insurance it masks invariant violations at
  render rate.
- *Slot-naming panels:* kills reuse across configurations.
- *Always-hot widgets:* FlightCore's dead slider — visually live, silently
  overwritten.
- *Cross-device peek:* re-couples devices for sub-perceptual benefit.
- *Stage-on-change only:* streaming device reasserts control mid-grab.

### D-027 — Pacer coarse phase uses task-yielding sleep

**Status.** ratified

**Position.** Pacer coarse phase = task-yielding `sleep` (`margin` covers its
overshoot); with devices attached every frame yields at least once (explicit
`yield()` in unpaced/pure-spin frames); spin never yields; thread budget =
sizing rule + startup warning; per-device liveness heartbeat in framework
status.

**Spec.** [§12.2][s12-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`Libc.systemsleep`:* second knob inside `margin`; correctness re-hinges on a
  hard thread requirement; starves co-resident tasks silently — worse failure
  mode than diagnosed overruns.
- *Hard `nthreads` error:* the freeze it prevented cannot reproduce — no
  framework thread monopolist, no stall coupling, GUI on the calling task.
- *Yielding spin:* µs precision traded for scheduler noise.

### D-028 — Next-snapshot wait via monotonic counter and condition variable

**Status.** ratified

**Position.** Next-snapshot wait: monotonic boundary counter ([D-081][d-081]) +
`Threads.Condition`, per-waiter predicate (`counter > last_seen && running`);
newest-wins, no queues — outbound coalescing mirrors inbound ZOH;
shutdown-interruptible via the predicate.

**Spec.** [§12.3][s12-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`Event`-based per-frame gate:* recurring signal on a latch — the reset has
  no correct placement under asynchronous waiters; cf. FlightCore's `io_start`
  reset comments.
- *Per-consumer every-boundary queues:* unbounded under slow consumers;
  complete history is the log.
- *Polling `latest` on a timer:* wasted wakeups, aliasing against the boundary
  rate.

### D-029 — Input trace on by default

**Status.** ratified

**Position.** Input trace on by default, cleared at `init!`, plain kill switch.

**Spec.** [§11.2][s11-2], [§11.5][s11-5], [Appendix B][sB]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Opt-in:* the trace is primary data — the log is recomputable from it, never
  the reverse; the session you need replayed is the one you didn't plan to
  record.
- *Tying trace to the log switch:* conflates primary and derived recording.
- *Rolling window/sampling:* complexity without a customer.

### D-030 — Shutdown protocol: publish, wake, unblock, join

**Status.** ratified

**Position.** Shutdown: complete the boundary → publish final snapshot → sticky
stopped status → wake framework waits → `unblock!` hook (close-own-socket
idiom; EOT demoted to wire courtesy) → join with named timeout; device crash =
`should_close` path; loop failure runs the same protocol from the catch path.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *EOT as the relied-on unblock mechanism:* protocol detail doing framework
  work.
- *Unbounded join:* one wedged device hangs `run!`.
- *Mid-frame abort:* torn final snapshot; consumers observe un-swept state.

### D-031 — Mid-run mutation doctrine: staging and control commands only

**Status.** ratified

**Position.** Mid-run mutation doctrine: root-input staging + control commands,
nothing else; sim-time scripts = scenario components (clock criterion),
wall-clock interaction = devices; `user_callback!` eliminated (cheap
composition removed its reason to exist); manual events = slot + guard;
init/trim = stopped-sim services ([§14][s14]); mid-run intervention command = guarded
addition with shape on record.

**Spec.** [§12.5][s12-5], [§14][s14]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Scripts as input devices:* breaks unpaced — wall-clock staging against µs
  frames lands at scheduler-determined sim times; both demo archetypes run at
  `pace = Inf`.
- *Retaining `user_callback!`:* the periphery's `f_step!` — unrecorded
  mutation, ordering by convention, invisible to replay.
- *A raw poke API:* nothing demonstrated needs it; every mid-run mutation in
  the codebase is a `u`-write in disguise.

### D-032 — Component declaration: trait layer with probe-checked schema authority

**Status.** ratified

**Position.** Component declaration: declarative trait layer in plain Julia
(well-known functions returning plain values; stage functions ordinary
methods); schema authority — declarations define, probe evaluation checks
(build probe with real values + free always-on conformance); convenience macros
addable a posteriori, never essential.

**Spec.** [§8.1][s8-1], [§8.4][s8-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Inference-by-evaluation as schema authority:* error locality inverts —
  failures inside correct code; schemas sample/branch-dependent; annotations
  homeless. The five [§8.4][s8-4] walkthroughs traced under inference-by-evaluation,
  recorded as the grounding evidence: (1) a typo'd wire (`:throtle`) gives a
  missing-field error inside a correct `h_xu` at probe time, the input set
  silently *defined* by the typo; (2) a forgotten wire read only by a guard is
  detected only if the probe exercises that guard, and then as a missing field
  in event code; (3) a forgotten branch field yields a schema silently derived
  from whichever branch the initial state took, then a mid-run error or a
  silently absent port at the first transition; (4) a type mismatch surfaces as
  a `MethodError` deep inside user math; (5) a typo'd return field silently
  *defines* a new cell, the intended name's absence surfacing later as a
  missing-field error inside correct `f`/guard code.
- *Macro DSL as substrate:* opaque codegen, tooling/stack-trace tax, only ever
  lowers to the trait layer.
- *Optional declarations with inference fallback:* two idioms; the quick hacks
  most likely to skip are most likely to harbor branch bugs.

### D-033 — Declaration inventory: by-value, by-type, by-allocation conventions

**Status.** ratified

**Position.** Declaration inventory: `init_*` by value (type derived — nothing
to drift); `input_types(::C)` bare NamedTuple of types at `Float64` faces,
wiring check `producer_face <: entry` ([D-078][d-078]);
`output_types(::C)`/`local_types(::C)` plain concrete nominal declarations on
both tiers, per-activation cell types from the framework leaf walk ([D-079][d-079]);
`workspace` registered by allocation ([D-077][d-077]); `events(::C)` ordered + per-event
`localize` flag (`true` = Tier 2, default `false` = Tier 1); stage membership
derived (inputless `h_x` probes first, remainder is stage 2), no stage tags.

**Spec.** [§4.2][s4-2], [§8.1][s8-1], [§8.2][s8-2], [§9.7][s9-7]

**Rationale.** The inventory is self-classifying by convention: by value
`init_*`, by type `*_types`, by allocation `workspace` ([D-076][d-076]). Contract
declarations are functions of the component's *type*, parameters included
(`SumJunction{W,N}`, `Or{N}`), never of field values — `workspace` explicitly
exempt (by-allocation, [D-077][d-077]) — because [§9.7][s9-7]'s entry typing derives the bundle
key set from the type; a rule authors keep, not a check the build can run
([§8.1][s8-1]).

**Rejected.**
- *Superseded position — `outputs(::C, ::Type{T})` on continuous components
  with plain `outputs(::C)` on discrete as the tier-in-signature marker (the
  earlier design of record):* functions of the sweep scalar, literal `Float64`
  = deliberate non-participation; retired with the `T`-signature ([D-079][d-079]).
- *Exact-equality wiring check:* relaxed to subtype, equality the concrete
  degenerate ([D-078][d-078]).
- *The names `inputs`/`outputs`/`locals`:* renamed for self-classification by
  convention and to dissolve the `inputs` vs `input_faces` ambiguity
  ([D-076][d-076]).
- *Under-the-hood `Float64→T` substitution:* reflection-heavy; cannot
  distinguish honest `Float64`s.
- *Sentinel eltype tokens:* same machinery, worse spelling.
- *Subtype/pattern matching on the output side:* motivating case dissolved by
  `T`; abstract slots break concrete typing.
- *Names-only input contracts:* lose wiring-time type errors and standalone
  checkability.
- *Per-stage output lists:* stage membership is internal, [§4.2][s4-2].

### D-034 — Contract visibility: declared fields are public

**Status.** ratified

**Position.** Contract visibility: declared = public; absent `output_types()` =
no outputs; intermediates declared via strict `local_types` ([D-055][d-055]) — table
cells, non-connectable, snapshot-visible, presentation-filtered;
branch-shape-stable returns; undeclared stage-return fields = build error.

**Spec.** [§5.4][s5-4], [§8.3][s8-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — private intermediates recognized by probe observation,
  with a `Private(T)` fallback and a structurally local blast radius (the
  earlier design of record):* retired because observation authority is unsound
  (pinned intermediates drop partials that flow out through `f`; return typos
  silently define new cells).
- *`unlisted` presentational flag:* hidden but connectable — pretends privacy
  without enforcing it.
- *Identity-public on missing `outputs()`:* implicit publicity.
- *`Private(T)` contract entries:* ceremony without a demonstrated customer —
  fallback on record.

### D-035 — Stores and views: components read zero-copy view bundles

**Status.** ratified

**Position.** Stores and views: every component function receives zero-copy
views of the stores it genuinely reads — `h_xu`, `f`, `h_zu`, `g`, guards and
handlers alike — arriving as one named bundle destructured in the signature
([D-074][d-074]); the table holds produced signals only, never transported ones (one
home per datum); selective auto-publication of declared state/mode fields;
`h_x`/`h_z` = the no-feedthrough stage.

**Spec.** [§5.2][s5-2], [§5.3][s5-3], [§7.4][s7-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — state-free evaluation prototypes with identity
  transport (the earlier design of record, [D-015][d-015]/[D-016][d-016] as argued):* the
  "published anyway" camouflage fell with contract visibility, and the
  drift-unwritability claim was overstated — `f` always had `u` plus published
  state.
- *Packing `u` into the stage-2 product / `f(comp, y, t)`:* the reductio —
  republishing foreign cells under local names.
- *Transition-functions-only middle position:* fixes handlers but keeps hidden
  state transport for `f`/`h`.
- *State cells mirroring the buffer:* dead stores — no own-function reader
  remains.

### D-036 — Table mechanics: stage returns are NamedTuples of port values

**Status.** ratified

**Position.** Table mechanics: stage returns are NamedTuples of port values;
aggregate `y` = virtual merge, gathered per call, never stored; custom structs
are port values — one port, one cell, atomic in wiring; granularity guideline:
bundle what shares a stage and is consumed together.

**Spec.** [§4.3][s4-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Bare-struct returns with field-splatting:* ambiguous, type-lossy merge,
  reflection-hungry. "Type-lossy" spelled out: neither the struct type nor the
  methods that justify its existence can be reassembled from a flat merged
  namespace.
- *Sub-field wiring:* the port stops being the atomic unit; field-projection
  connector kept as guarded addition.
- *Per-field cells for struct internals:* nested display is a lazy view, not
  storage.

### D-037 — Aggregation by explicit summing junctions

**Status.** ratified

**Position.** Aggregation by explicit summing junctions (generic positional or
named site-specific — plain components); hierarchical idiom: junctions at
ownership boundaries, totals exported across generic boundaries; fold order
author-visible; helper/macro sugar guarded.

**Spec.** [§6.2][s6-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Reduce-ports ([D-007][d-007], reversed):* the declaration vocabulary's last wrapper;
  three-site census, all Newton–Euler, one library file; canonical-fold,
  multi-connection legality and identity-element machinery all retired for
  free; the aggregate wasn't even observable.
- *FlightCore tree walks:* silent omission — the zero-edit convenience *is* the
  hazard.
- *Bundled wrench/mass/momentum contribution structs:* ragged contributors →
  identity-element noise.
- *Annotation (from [§6.2][s6-2]'s inline treatment, migrated at the P3.2 rewrite,
  2026-08-15):* the raggedness census behind that rejection — aero has wrench
  but no mass, fuel the reverse, only `pwp` has angular momentum; a bundle
  forces zero-filled identity noise through every port, the "silently sum
  nothing" hazard in a new coat.

### D-038 — Snapshot and log: derived trajectory, primary trace header

**Status.** ratified

**Position.** Snapshot = boundary table (private cells included,
presentation-filtered) + `t` + status — no state stores; trace header = full
`(x, m, z)` at `init!` (primary data); state trajectory = derived
(replay-to-inspect); checkpointing = opt-in log policy, guarded; post-run
continuation reads live stores; log retention = the trace's plain kill switch
plus keep-every-kth decimation (`log_every` — adopted in round 3, previously a
guarded addition) — admissible precisely because the log is derived
(recomputable by replay), so [D-029][d-029]'s anti-decimation argument does not reach
it; publication and tracing are unaffected.

**Spec.** [§11.2][s11-2], [§11.5][s11-5], [§15.4][s15-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Per-boundary full-state capture:* systematically records derived data —
  [D-029][d-029]'s asymmetry reversed.
- *State wanted in logs via capture rather than declaration:* publicity is the
  honest remedy, priced at one auto-published cell per sweep.
- *Dev auto-publish-all-state as default:* a diagnostic mode, kin to workspace
  NaN-poisoning, not semantics.

### D-039 — Assembly declaration is type-based

**Status.** ratified

**Position.** Assembly declaration is type-based: plain struct, children =
component-typed fields, parameters = the rest; `connections`
mandatory-even-empty as the kind marker; one root `AbstractComponent`, kind by
declaration shape — the rule is total: `connections` marks an assembly, any
leaf declaration (`init_*`, `workspace`,
`input_types`/`output_types`/`local_types`, `events`, any
stage/`f`/`g`/`project` method) marks a primitive, and declaring neither family
is a build error naming both.

**Spec.** [§8.1][s8-1], [§8.3][s8-3], [§8.5][s8-5], [§8.8][s8-8]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Builder (`add!`/`connect!`):* dispatch type and structure recipe drift apart
  — [§8.1][s8-1]'s disease at assembly scale; mutable declaration state; doesn't even
  capture source locations.
- *`AbstractAssembly` kind supertype:* single inheritance is spoken for by
  domain hierarchies; kind is an implementation detail per [§8.3][s8-3].
- *Kind inferred from field types:* heuristic where a declaration is wanted.

### D-040 — Slash-string paths as the canonical path form

**Status.** ratified

**Position.** Slash-string paths, relative to the declaring assembly, one
canonical form shared by declarations, diagnostics, devices and logs.

**Spec.** [§8.6][s8-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Instance navigation:* `===`-identical symmetric siblings make
  path-from-instance unrecoverable — proxies remain sugar.
- *Symbol tuples:* structure without readability.
- *Dotted paths:* false Julia-property affordance — the last segment is a port,
  not a field.

### D-041 — Dedicated `exports` for assembly faces

**Status.** ratified

**Position.** Dedicated `exports(::A)`: face => internal path(s), direction and
face types/tiers derived from endpoints (assemblies are tier-neutral —
derivation is forced); `connections` strictly child-to-child.

**Spec.** [§8.6][s8-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Routing values under leaf `inputs`/`outputs` names:* name-level pun —
  discrete-leaf signature with alien value semantics, kills the kind split.
- *Leaf-style typed faces + face wires in `connections`:* no `outputs`
  signature fits a tier-neutral assembly; face/child namespace collisions;
  weakest kind marker.
- *Wires-only with implicit facehood:* publicity never implicit.

### D-042 — `rates` declaration on immediate children only

**Status.** ratified

**Position.** `rates(::A)` optional declaration, immediate children only, `K`
on a continuous child = error; `Δt_base`/`h` fixed only at `Simulation`
construction.

**Spec.** [§8.7][s8-7]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Instance wrappers (`Subsampled`-style):* wraps the field type, pollutes
  paths/dispatch/contract; makes the type-intrinsic ratio a per-instance value.
- *Deep rate keys:* edit another type's design from outside.

### D-043 — Computed exports via ordinary code and `faces`

**Status.** ratified

**Position.** Computed exports as ordinary code + `faces(asm, path; prefix,
except, only)`; root slots = the root's exported input faces; generic holding =
imposed contract checked per instantiation.

**Spec.** [§6.1][s6-1], [§8.4][s8-4], [§8.8][s8-8]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Auto-bubbling:* forgotten wire silently promoted to a live root slot — [§8.4][s8-4]
  walkthrough 2 inverted.
- *Wildcard-export vocabulary:* ordinary code suffices.
- *`add_input!`-style root-slot declarations:* second vocabulary for what
  exports already are.

### D-044 — Slot exclusivity and the write-surface rule

**Status.** ratified

**Position.** Slot exclusivity: one writer per root slot at a time; device
claims at attach, conflict = attach-time error, release on detach; per-device
cells/CAS/drain retained for atomicity and coalescing. Generalized as the
write-surface rule ([§11.3][s11-3]): an entry reaches a slot iff the face is inside the
writer's surface, else discard + warn — under the [D-106][d-106] roster freeze every
surface is static per run, so all checks run at staging and the drain checks
nothing; enumerated surfaces (a device's claim set — binding-bounded even on
unclaimed faces, `OutOfClaimEntry`) vs. the derived interactive surface (GUI +
`stage!`: the unclaimed set, shared, re-derived only at stopped-sim roster
changes — a write to a claimed face is `ClaimedFaceEntry` at staging;
`StaleInteractiveEntry` and its moved-between-staging-and-drain scenario are
dead); autonomous opportunistic writing does not exist, so cross-writer races
structurally cannot arise and drain order stays diagnostic.

**Spec.** [§11.3][s11-3], [§11.6][s11-6], [§11.7][s11-7], [§15.4][s15-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Cross-device attachment-order precedence as conflict policy:* resolves races
  the [§15.4][s15-4] cast shows nobody wants — every dual writer is a stream shadowed by
  a mirror.
- *FlightCore-style concurrent multi-device writing of one input:* a bug
  surface, not a feature.
- *Discard-outside-the-claim as literal drain rule:* an empty claim set would
  discard every GUI write.
- *Ownership-only discard (claimed-by-another):* leaves enumerated bindings
  unenforced at the drain and reopens unclaimed multi-writer races.
- *Unclaimed-surface opportunism "for any device":* reinstates the rejected
  attachment-order policy; breaks [§11.7][s11-7]'s stays-put and sole-writer arguments.

### D-045 — Periphery input semantics: derived liveness, conditioning, mappings, edge logic

**Status.** ratified

**Position.** Periphery input semantics are settled on five points — liveness,
conditioning, mappings, edge logic and pokeability:

- GUI liveness is fully derived: transitive root-slot resolution ∧ slot
  unclaimed.
- Faces carry writer-independent post-conditioning semantics, the GUI-parity
  test.
- Mappings are declarative binding data with per-axis conditioning params,
  living on the device task.
- Edge logic is staged counters plus model-state accumulators.
- Unexported ports are unpokeable.

**Spec.** [§11.7][s11-7], [§15.4][s15-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Per-port "GUI-controlled" markings:* the export chain is the marking, owned
  by the right author.
- *Nominally-connected + GUI override channel:* second write path; breaks frame
  purity and trace; done right it collapses into root slots.
- *Conditioning in-model:* fails GUI-parity — sliders and scripts would be
  deadzoned.
- *Shaping as per-device mapping code:* aircraft semantics duplicated per
  device — today's demonstrated smell.
- *Joystick-as-component and root-level `PilotInterface`* ([§15.4][s15-4]): replay
  same-build, single audit point, no natural home in `World`. Annotation (from
  [§15.4][s15-4]'s inline treatment, migrated): devices-as-components also duplicates
  [§12.4][s12-4]'s device lifecycle in component vocabulary and costs the drain its
  standing as the single audit point for external data, while the GUI stays
  irreducibly a staging device so inbound uniformity is unreachable either way
  — and the rejection rests on these invariants, not on [§12.5][s12-5]'s clock
  criterion, the scheme being internally consistent in an interactive paced
  world.
- **Bundled command faces** (`pilot_inputs` as one struct port): kills
  per-field claiming, liveness and trace provenance — the port is the
  periphery's atomic unit on the write side too, [§4.3][s4-3] — and the routing
  convenience it bought under argument threading is the namespace prefix plus
  `input_passthrough` here.

### D-046 — Face names are opaque string tokens; slash is reserved for structure

**Status.** ratified

**Position.** Face names = arbitrary strings; build invariants only no-`/` +
per-assembly uniqueness; slash = structure, face names = opaque contract
tokens; the periphery speaks face names on the *write* side ([D-083][d-083]); `exports`
returns pairs like `connections`; `faces(asm, path; prefix, sep, except, only)`
with dot-prefix *defaults* (convention, not law).

**Spec.** [§8.6][s8-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Mandated dot convention:* a naming law where two invariants suffice.
- *NamedTuple-returning `exports`:* `var"..."` noise for non-identifier names;
  asymmetric with `connections`.
- *Slash-composed prefixes:* face names would collide with structural path
  notation.
- *`rename` hooks in `faces`:* `exports` is ordinary code — map over the pairs.

### D-047 — Stage widgets on interaction events, not every pass

**Status.** ratified

**Position.** Widgets stage on interaction events only (value widgets on edit,
edge widgets on activation with peek-computed counter levels); levels ×
own-pending-first peek give idempotent repeat and correct multi-click; snapshot
includes root slots (peek fallback + read-only mirrors); trace header extends
to initial slot values; engage semantics stay in the FCS (the existing
`ControlLaws` transition latch — uniform across writers), GUI peek-batch
demoted to display-sync sugar.

**Spec.** [§11.3][s11-3]

**Rationale.** No claim-transition policy exists — mid-run claim transitions
cannot occur under the [D-106][d-106] freeze, liveness is baked once per run, and the
orphan case (claiming device's task dead) renders in the widget's provenance.

**Rejected.**
- *Stage-every-pass:* motivating contest died with exclusivity; as insurance it
  masks invariant violations at render rate — anti-diagnostic; render-rate
  trace noise.
- *Held-button re-staging:* auto-repeat at frame rate once the snapshot catches
  up.
- *Capture-on-engage as a GUI/framework obligation:* already aircraft design,
  shipped in `ControlLaws`.
- *Slot-initial-values as export-entry defaults:* trim writes slot values it
  *solved for* — services own initialization.

### D-048 — Three-stratum build pipeline: structure, schedule, activation

**Status.** ratified

**Position.** The build pipeline runs as three strata — A structure, B schedule,
C activation — with deployment binding at `Simulation` construction only.

- A, structure: pure declaration reading — tree/kinds/contracts, bottom-up
  faces, global wiring + obligations, rate compilation.
- B, schedule: `h_x` probe → port classification → feedthrough graph →
  topo/cycle.
- C, activation: per-`T` slot typing + probe chain + layouts.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Single-pass tree walk with per-level validation:* obligation/two-producers
  undecidable below the root.
- *Pure collect-then-validate:* stage membership requires the `h_x` probe —
  evaluation feeds structure exactly once, at the blessed spot.

### D-049 — Standalone `build(world)` artifact wrapped by `Simulation`

**Status.** ratified

**Position.** Standalone `build(world) → Build` artifact — inspectable wire
list/face table/schedule/root slots; `Simulation(world; ...)` wraps it.

**Spec.** [§9.2][s9-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Build inside the `Simulation` ctor only:* CI forced through dummy deployment
  params; acceptance tests and `attach!` want the contract artifact; the phase
  outputs exist anyway — the artifact just names them.

### D-050 — Probe every user function once at build, at nominal `T`

**Status.** ratified

**Position.** All user functions — the `h_*` stages, `f`, `g`, guards, handlers
and `project` — are probed once, at the initial state and nominal `T`.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Schema-critical-only probing:* a malformed `f` return waits for the first
  integrator step; probing buys earliness on the happy path at one pure
  evaluation each — the always-on check is the completeness backstop either
  way.

### D-051 — Synthesize probe inputs via a `probe_value(::Type)` fallback chain

**Status.** ratified

**Position.** Probe input synthesis via `probe_value(::Type)`:
`zero(T)`/`false`/first enum instance/`T()` fallback chain, overridable,
missing-method error names face + type; probe values strictly probe-scoped
(never initial slot values).

**Spec.** [§6.1][s6-1], [§9.3][s9-3]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Inputs declared by value à la `init_x`:* reads as an unwired-input default —
  [§6.1][s6-1] contradiction; every leaf pays for a root-slot-only need; fan-in faces
  need an agreement rule; reopens [D-033][d-033].
- *NaN poison probes:* `Bool`/enums unpoisonable; probe values are meant to be
  read.
- *Init-service values:* build is standalone; services post-date it.

### D-052 — Scope Dual probing to each activation's executable set

**Status.** ratified

**Position.** Each activation probes exactly its executable set (`Dual` =
continuous `h_*` chain + `f`; guards/handlers/discrete stages never see
`Dual`); activations lazy at first request, opt-in exhaustive `activations` for
CI; caching = implementation detail (layouts + buffers + validated flag keyed
by concrete scalar type; Julia caches the compilation — the buffer clause
rescinded by [D-135][d-135]: the cache holds immutable artifacts only and lives on the
`Build`, buffers being single-owner).

**Spec.** [§9.5][s9-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Full-set probing at every activation:* checks code against number types it
  cannot receive.
- *Eager `Dual` at every build:* doubles compile latency for a CI-only
  guarantee.
- *Treating "builds" as "linearizable":* weakening accepted and priced openly.

### D-053 — Bake one always-on conformance check at every table write

**Status.** ratified

**Position.** Always-on conformance = one baked expected-`NamedTuple` type test
at the table-write point, no convert-on-write; folds away when inferrable;
uniform across `f` (state-field completeness), guards (form-aware against the
two [§2.1][s2-1] forms: `Bool` for predicates, the nominal scalar for continuous
guards; anything else, and a Tier-2 guard probing `Bool`, a build error naming
both forms), output stages, handlers (partial-`m` subset predicate); failure =
path + stage + field diff + `t`, reproducible by trace replay. Exact match is
scoped to the nominal activation; parametrized leaves under non-nominal
activations accept `{T, Float64}` with zero-partial embedding ([D-079][d-079]).

**Spec.** [§2.1][s2-1], [§9.5][s9-5]

**Rationale.** Recorded only through the rejections below.

Annotation (2026-09-08): realized at the generated write, against the cell
type, per [D-235][d-235].

**Rejected.**
- *Field-assignment `convert` semantics:* `Float64 → Dual` silently zeroes
  partials — wrong Jacobian, no error; `Int` sloppiness passing at nominal but
  detonating under `Dual` makes "it runs" activation-dependent.
- *Per-field checks:* one whole-type test suffices and folds.
- *Branch identification in the error:* values carry no provenance — the diff +
  replay suffice.

### D-054 — Producers determine activation types; consumers stay generic

**Status.** ratified

**Position.** Producers determine activation types, consumers accept — consumer
obligation is genericity, checked by the `Dual` probe.

**Spec.** [§8.2][s8-2]

**Rationale.** Symmetric `T` on `input_types` is rejected as
impossible-by-construction: an input's activation-time type depends on the
producer's tier through the wiring (continuous → `Dual`, gated discrete → held
`Float64`; consumers promote). The envelope reading (per-leaf genericity
marking) is also rejected — zero information ([D-078][d-078]).

**Rejected.**
- *`input_types(::C, ::Type{T})`:* forces the consumer to declare its
  producer's tier; breaks on discrete-for-continuous substitution behind the
  same face; [D-033][d-033]'s exact-`Float64`-face check was already the only coherent
  consumer statement.

### D-055 — Require strict `local_types` declaration for cross-stage cells

**Status.** ratified

**Position.** Strict `local_types(::C)` declaration: every non-`output_types`
return field declared; empty framework default; no auto-publication;
component-scoped cross-stage cells ≠ workspace; schema authority total
(supersedes [D-034][d-034]'s observation exception; adds [§8.4][s8-4] walkthrough 5); concrete
nominal on both tiers, same activation leaf walk as `output_types` ([D-079][d-079]).

**Spec.** [§5.4][s5-4], [§8.3][s8-3], [§8.4][s8-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Superseded position — the earlier `T`-signature spelling `locals(::C,
  ::Type{T})`, in which the declared eltype was the participation statement
  under `Dual`:* retired with the `T`-signature ([D-079][d-079]).
- *`Private(T)` wrapper inside `outputs`:* breaks "declared = public"; the
  layer's first wrapper type.
- *Opt-in `locals` + `Float64`-under-`Dual` diagnostic:* legislates an
  ambiguity strictness dissolves.
- *Observation-authority status quo:* pinned intermediates drop partials that
  flow out through `f` in conformant types — blast radius never was local for
  values; return typos silently define new cells.

### D-056 — Uphold the two-kind taxonomy against the integrate-and-dump challenge

**Status.** ratified

**Position.** The two-kind taxonomy is upheld under the integrate-and-dump
challenge ([§15.5][s15-5]): the kinds are time bases, sweep-driven vs. tick-driven, and
cross-tier coupling always routes through table cells.

- The idiom is integrate-and-difference: cumulative integrals in `x`,
  previous-sample latch in the sampler's `z`.
- It is exact whenever interval-dependence is a left action by the
  interval-start value of a cumulatively-integrable quantity (inertial-rate
  anchoring required; RK-exact by linearity of the kinematics).
- A latch-back wire — a feedthrough-stage ZOH latch — carries interval-relative
  flow terms.
- Tick-triggered continuous handlers are the recorded, unbuilt escape hatch.
- Boundary-sampling semantics are promoted to taught contract.

**Spec.** [§3.2][s3-2], [§3.3][s3-3], [§15.5][s15-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *All-in-one component kind:* an assembly in a trench coat: the halves still
  communicate through cells — one home per datum, sole-reader `z`, no
  cross-tier state views — so zero expressiveness gained; costs stage doubling
  with tier-tagged names, per-port tier vocabulary, facet-conditional
  obligations; hides the sampling seam — Simulink/FMI's documented sample-time
  confusion.
- *`z` view in `f` / discrete writes into `x`:* un-samples the sampled-data
  semantics, breaks held-`z` linearization exactness, coupling invisible to
  table, trace and feedthrough graph.
- *Periodic reset via time-guard events:* hand-rolls the tick scheduler,
  forfeits the harmonic grid and the discrete-bundle `Δt`.

### D-057 — Batch declarative-check violations; abort on first user-code exception

**Status.** ratified

**Position.** Reporting policy split: declarative checking passes batch (the
full violation list is the pass's natural output); the first user-code
exception (`exports` bodies, probes) aborts the phase; strata are barriers; no
cascade suppression within a stratum.

**Spec.** [§13.1][s13-1]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Uniform fail-fast:* N build cycles for N clustered wiring errors.
- *Full compiler-style batching:* poisoned nodes, cascade suppression,
  dependent-check skipping — machinery for failures that are singular in
  practice.
- *Suppression heuristics:* adjacent path-sorted pairs are self-explanatory.

### D-058 — Diagnostics as structured values under one `BuildError` carrier

**Status.** ratified

**Position.** Diagnostics are plain structured values from a closed kind set —
paths and names as strings, expected/observed port types, lists-in-hand,
severity — carried by a single `BuildError` thrown at the stratum barrier, with
compiler-style rendering.

- User-code exceptions are wrapped in framing diagnostics, the original riding
  as `cause`.
- Warnings ride the same stream and never throw.
- The didactic style is policy.
- Tests match kind + payload, never message text.

**Spec.** [Appendix C][sC]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`error()` strings:* acceptance tests pinned to message text; no batch
  carrier.
- *One exception type per failure class:* throw vehicles for data that is
  collected, not thrown.
- *Instances/model types in diagnostics:* the `compact_backtrace` lesson.
- *A separate warning channel:* two pipelines; blocks a warnings-as-errors
  switch.

### D-059 — Catch runtime failures at one boundary site into `StepError`

**Status.** ratified

**Position.** Runtime failures are caught at one site, around the boundary
macro-sequence, against an execution cursor — schedule index, function kind,
boundary phase, one plain store per dispatch.

- `StepError` carries the cursor frame, the boundary time, a replay pointer and
  `cause`.
- [§9.5][s9-5]'s conformance failure is a species of it.
- A loop-level nonfinite-`x` check runs at the boundary.
- Status goes terminal `stopped`/`errored`, and synchronous runs rethrow after
  the tail.

**Spec.** [§12.6][s12-6], [§9.5][s9-5], [§13.4][s13-4], [§14][s14]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Per-call try/catch:* exception frames in the hot path to gather what a
  cursor store provides.
- *Naked task death:* unframed exception, hanging devices.
- *Resumable-after-error simulations:* stores may be mid-boundary; reproduction
  is trace replay, not resurrection.

### D-060 — Graceful termination is model state, never an exception

**Status.** ratified

**Position.** Graceful termination is model state, never an exception:
detection by ordinary guard/handler machinery (Tier-2 event where the stop must
be localized), publication as an exported `Bool` face, policy as `stop_on` root
faces at `Simulation` construction (OR-combined, `Build`-validated,
metadata-recorded, sampled at completed boundaries); exceptions from model code
always abnormal; no `SimulationTermination` exception type.

**Spec.** [§13.5][s13-5], [§14.4][s14-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Termination-by-exception:* aborts a boundary [§12.4][s12-4] is built on completing;
  models never state their terminal dynamics.
- *`stop_when` predicate closures:* opaque, unserializable, a public snapshot
  API — `user_callback!` redux. Annotation (from [§13.5][s13-5]'s inline treatment,
  migrated): the closure rejection also rests on the extra expressiveness being
  logic that belongs in-model in every use found.
- *Root-type-declared policy:* stopping is run policy; absolutes bind at
  deployment — overridable default the one variant on record.
- *Scanned terminal types / `terminal` event flags:* action at a distance: deep
  declarations halt the world, root contract silent, disabling needs masking;
  the localization they promise is the event idiom under `stop_on` anyway. The
  scanned-terminal-type rejection also rests on substitution — swapping an
  aircraft silently changes when runs end, with the root contract still silent
  about it.
- *Control-plane capability components* ([§12.1][s12-1]): components live inside
  boundary semantics.
- *Observation-by-path:* service observation must speak the contract;
  inspection observation sees everything — [§6.1][s6-1]'s knowledge rule applied to
  reads.

### D-061 — `resolve` walks declared types to enforce the generic-boundary rule

**Status.** ratified

**Position.** `resolve(asm, path)` walks declared field types alongside
instances, enforcing [§6.1][s6-1]'s generic-boundary rule at the primitive
(past-generic segment = diagnostic even where the instance resolves;
client-scoped by [D-130][d-130] — wiring and service clients enforce, the inspection
client takes the instance walk); `input_faces`/`output_faces` return
declaration-ordered face-name strings; the wiring resolver splits a terminal
path's final segment (slash the only structural separator).

**Spec.** [§6.1][s6-1]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Instance-only walk:* blind to generic holding — [§6.1][s6-1] unenforceable where
  paths are actually resolved.
- *Set-valued face lists:* nondeterministic printouts and unstable diagnostics.

### D-062 — Tooling commitments: face predicates, build printer, component library

**Status.** ratified

**Position.** Three tooling commitments are made:

- `faces` gains predicate selection.
- The `Build` printer renders face provenance, the root face → producing
  terminal chain.
- A standard component library (summing junctions, Bool gates) ships as ordinary
  components, demand-driven, arity by type parameter (`Or{N}` — computed
  contracts), stateless-continuous hence tier-transparent.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Framework-privileged library blocks:* schema authority no longer total; the
  library stops testing the declaration layer's ergonomics.
- *Upfront Simulink-scale inventory:* a language, not a toolbox.
- *Per-site hand-written junctions:* prices [§6.2][s6-2]'s explicit-junction doctrine
  dishonestly.

### D-063 — Conditions are path-addressed sparse overlays on `init_*` defaults

**Status.** ratified

**Position.** Conditions are path-addressed values: sparse overlays of
`x`/`m`/`z` fields ([§8.6][s8-6] path + field) and root slots (by face) on the
declared `init_*` defaults; never outputs or workspace; warm restart =
`capture` reads current stores back as a condition value (capture → tweak →
apply).

**Spec.** [§8.6][s8-6], [§14.1][s14-1]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Mirror-tree spelling:* a second structure artifact, ragged under partiality,
  outside the path vocabulary.
- *Current-stores overlay base:* run-history dependence breaks header
  reproducibility.
- *Condition-by-contract-only:* forfeits the concrete-build authoring idiom
  that `connections` already occupies.

### D-064 — Compose per-component init by pull, via fragment functions

**Status.** ratified

**Position.** Per-component init knowledge = fragment-returning user functions
dispatched on component types, composed by pull (`at`/`merge` invoked by the
structure's owner); pre-sweep doctrine: a condition value needing swept outputs
is caller-computable (trim's `α_filt = α_a` — a decision variable) or an
equilibrium constraint for the trim service.

**Spec.** [§14.2][s14-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`initialize(::C, spec)` schema + assembly routing:* call-tree composition
  reborn: spec tree mirrors assembly tree = [D-039][d-039] two-artifact drift; spec
  defaults = second home competing with `init_x`; per-field partiality
  protocol; slots still need the path layer — two mechanisms.
- *Init as a third scheduled sweep:* what "component-local `α_filt = α`"
  actually requires.

### D-065 — Fragments form a lazy inert tree, resolved against the `Build`

**Status.** ratified

**Position.** Fragments form a lazy inert tree (`Fragment`/`Scoped`/`Merged`;
`at`/`merge` store, never apply — stack-only rebuild per iteration); all
flattening/validation/addressing at resolution against the `Build`; duplicate
leaf = error with both provenances; converters and `m`/`z` overlay bases baked
at compile; slots resolve through export chains (unexported = unwritable, init
included); locality law = [§6.1][s6-1]'s, third instance (own fields, declared
children, own faces; deep `at` only within owned concrete subtrees) — absolute
paths are compiled derivatives, so [§13.5][s13-5]'s observation-by-path rejection is
untouched.

**Spec.** [§6.1][s6-1], [§13.5][s13-5], [§14.2][s14-2]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Eager path concatenation in `at`:* strings and allocation on the hot path.
- *Eager duplicate checks in `merge`:* requires flattening at composition.
- *Last-writer-wins merge:* silent near-certain bug — slot-exclusivity spirit.
- *Machine-enforced ownership:* not build-visible; same convention status as
  [§6.1][s6-1].

### D-066 — Two ways to apply one plan: specialized `apply!` vs dynamic entry-list walk

**Status.** ratified

**Position.** Two ways to apply one compiled plan: specialized
`apply!` (`Getter{P}` lenses, unrolled baked stores, zero-alloc; [§9.5][s9-5]-style
shape check via tree type + literal `===` sweep; ~10–50 ms codegen once per
shape) for iterating services; dynamic entry-list walk (microseconds, no
per-shape codegen, allocation fine per [§7.5][s7-5]) for one-shot init; compiled
readers as the gather twin (cost reads, linearization gather, `capture`) — one
primitive family in the `Build`'s client kit.

**Spec.** [§7.5][s7-5], [§9.5][s9-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *A single always-specialized form:* per-shape codegen tax on scripted
  one-shot conditions.
- *A single always-dynamic form:* forfeits the zero-alloc trim loop.
- *Per-write convert decisions:* the converter is a resolution-time fact;
  [§9.5][s9-5]'s no-convert-on-write stands for table cells.

### D-067 — Boundary zero runs the macro-sequence with an empty integrate

**Status.** ratified

**Position.** Boundary zero is the [§10.6][s10-6] macro-sequence run with an empty
integrate: project → sweep (every tick due; discrete stages publish from the
authored `z`) → events to quiescence → due `g` updates → header capture + first
snapshot.

- Interval alignment is a taught contract, sibling of [§15.5][s15-5]'s boundary-sampling
  line: a boundary's update is the *outgoing* transition — `z_{k+1}` from
  `t_k`'s samples — so boundary zero's incoming transitions on both tiers are
  replaced by authorship, and the update at `t₀` is the `t₀` sample's only
  chance.
- `t₀` is an init-service argument anchoring the harmonic grid (conditions
  time-free; `capture` returns condition and time separately).
- Trim iterations bypass boundaries entirely — raw write→sweep→read on the
  activation — and only the commit runs boundary zero, a guard firing at commit
  replacing today's hand-written trim asserts.

**Spec.** [§10.6][s10-6], [§14.5][s14-5], [§15.2][s15-2], [§15.5][s15-5]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Condition-authoritative boundary zero:* no events/updates: delays the
  identical firings one step while hiding non-quiescence — [§11.7][s11-7]'s
  insurance-masking-invariants pattern; skipping the update deletes the `t₀`
  sample and starts the sampled-data lattice one period late — the authored
  `z(0)` needs no protection, it is published at `t₀` regardless.
- *Update before the sweep or republish-from-`z⁺`:* stale-table sampling or
  Mealy update-feedthrough: same-boundary circularity, kills [§10.6][s10-6]'s structural
  termination.
- *`t₀` as a condition entry:* time is not a store.

### D-068 — Enforce slot totality at the init/commit service boundary

**Status.** ratified

**Position.** Slot totality is enforced at the service: `init!` and commit
compare resolved slot coverage against `input_faces` before writing anything,
and a shortfall raises one batched, declaration-ordered `UninitializedSlots`
diagnostic, all-or-nothing — a rejected init leaves the sim untouched.

- `probe_value` is structurally unreachable from the services path: a condition
  value or an error, no third branch; replay applies header-recorded slots and
  never synthesizes, header slot capture being complete by construction.
- Baselines are aircraft-shipped full-coverage condition functions
  (`ready_for_taxi(ac)` — `SystemsInitializer` defaults reborn as user math, one
  home).
- `override(base, patch)` is admitted as the fourth node kind: ordered and
  asymmetric against `merge`'s symmetric collision-intolerance, patch winning
  with dual provenance; within-layer collisions still error; layering is
  variadic; trim commits `override(baseline, solution)`.

**Spec.** [§14.6][s14-6]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Face-declaration defaults:* condition data inside the wiring contract;
  reopens [§11.3][s11-3] bare-types and the competing-defaults problem.
- *Silent zero-fill of uncovered slots:* the [§9.3][s9-3] probe-value leak — a
  fabricated zero is a fine probe input and a terrible flight condition.
- *Totality as a condition-value property:* conditions are legitimately
  partial; totality belongs to boundary-zero application.
- *Service-level base keyword:* hard-codes two layers; composition semantics in
  a service signature instead of the condition algebra.

### D-069 — Trim problem spelling: NamedTuples, residual vector, exact AD Jacobians

**Status.** ratified

**Position.** A trim problem is spelled as a residual *vector*: the user returns
a physically scaled NamedTuple, making trim a nonlinear least squares on $r(d)$
with exact AD Jacobians, the Dual activation seeded through the `T`-generic
assignment math.

- Decisions, guess and bounds are same-shaped all-`Float64` NamedTuples, which
  the service packs and unpacks by field order; `TrimParameters` is a plain user
  struct.
- Assignment is the pure `trim_condition` fragment function, and reads are
  declared via `deriv`/`output` selectors compiled to a stack NamedTuple reader.
- The vector formulation carries per-residual tolerances, unbalanced-equation
  failure reports, graceful non-squareness, and $\partial r / \partial d$ as
  free control-effectiveness data.
- The analytic-elimination doctrine (`θ_constraint`, by-construction
  filter/actuator equilibria) is preserved verbatim as user math.
- The derivative-free scalar fallback is the service squaring the residuals,
  today's BOBYQA as the degenerate case.
- Recorded unbuilt: closed-loop trim via $h(z) - z$ scratch residuals, and
  ground static equilibrium as another problem value.

**Spec.** [§14.7][s14-7]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Framework decision-variable supertype* (`AbstractTrimState`/`FieldVector`):
  vocabulary whose only job was vectorization.
- *Scalar cost as the primary formulation:* flat $|r|^2$ valley for
  derivative-free search, absolute `stopval` brittleness, per-equation
  diagnostics discarded — FlightCore's rational choice only because Jacobians
  through mutating `f_ode!` were unreachable.
- *`local_types`-addressable readers:* private intermediates; a cost needing
  one is an export signal.

### D-070 — Trim service: in-house dense LM behind a swappable backend

**Status.** ratified

**Position.** The trim service defaults to an in-house dense LM solver behind a
value-passed backend contract: the `NLoptBackend` extension takes squared
residuals, putting today's algorithm one keyword away, and core carries zero
optimizer deps.

- Box bounds are applied by step projection, with saturated-at-solution flagged
  in the report.
- Scratch store sets are instantiated per invocation from activation layouts —
  the layout reusable, the buffers dying with the call, Dual un-aliasability
  being defense in depth and not the mechanism — while authoritative stores have
  exactly one writer, the commit through boundary zero.
- `TrimReport` is a no-throw structured value: non-convergence is an expected
  envelope-sweep outcome, a malformed problem a `BuildError` at setup.
- The AD obligation is scoped to continuous stages, `f` and user
  assignment/residual math, the discrete tier frozen-exact — identical to
  linearization's activation, and build-checked by the Dual probe.
- The C172 audit is Interpolations tables (prefer cubic knots), saturation
  rank-deficiency (LM-tolerated, reported), gear zero airborne.

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *External NLS packages:* heavy dep for ~100 lines; [§10.2][s10-2] stepper precedent;
  per-residual tolerance test not natively spelled.
- *NLopt as core dependency:* no LM; fallback-only role.
- *Iterating on the nominal activation's singleton buffers:* aliases the sim's
  authoritative stores — warn-but-assign reborn.
- *Throw-on-non-convergence:* an expected outcome, not broken machinery.

### D-071 — Mount trim as an implicitly specified condition via `at`

**Status.** ratified

**Position.** A `TrimProblem` is an implicitly specified condition — a
condition-valued function over decisions plus pinning equations, made explicit
by solving and committed by initializing with the solved condition — which
unifies the services as condition-algebra clients.

- `at(prefix, problem)` lifts a problem in five lines: the condition is
  post-composed and the reads wrapped, inert selector data reusing the `Scoped`
  node, while guess, bounds and residuals pass through path-free.
- Slots resolve through export chains from the mount point, so an unexported
  face is untrimmable from outside — correctly, it being a model-driven input,
  named by the build.
- The world-level `f_init!` wrapper dissolves into the `baseline` condition:
  method nesting becomes value layering.
- `design_world(ac)` promotes today's ad-hoc linearize models to a shipped rig
  ("root" = shallowest world, one idiom).
- A swarm takes one problem per solve — sequential commits, or user-side joint
  composition (concatenated decisions, merged trees, stacked residuals).
- A `product()` helper is recorded for the [§13.7][s13-7] library, unbuilt.

**Spec.** [§13.7][s13-7]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *World-level trim wrapper methods:* call-tree reuse: one method per
  container, ad-hoc plumbing per multi-aircraft case.
- *Literal aircraft-as-root idiom:* environment inputs must be wired from
  providers; a second idiom to maintain.
- *Framework-side joint-trim machinery now:* user-side value composition
  suffices until routine.

### D-072 — Linearization surface: three selector lists, one chunked Dual pass

**Status.** ratified

**Position.** The linearization surface is three selector lists —
`state`/`slot`/`output`, each entry with an optional component index and a
NamedTuple key that is the control-design label — validated against schema,
compiled to offsets, relocatable via `at`.

- The `get_*_ss`/`assign_*_ss!` shuttle layer is deleted, discharging [§7.1][s7-1].
- Evaluation is one chunked Dual pass on per-invocation scratch at the operating
  point, yielding exact `A`/`B`/`C`/`D` and `ẋ₀`/`y₀` simultaneously; unseeded
  states stay constant, the discrete tier frozen-exact.
- Linearization is a pure query — no commit, no boundary zero, no restore dance
  — and its default operating point is `capture(sim)`, `capture` settled as the
  full-store gather returning `(condition, t)`.
- It returns labeled data, with `subsystem`/`delete_vars` as pure label-indexed
  slicing.
- `LinearizedSS` survives as an ordinary continuous component.
- Guidance: surfaces select minimal-coordinate mechanizations, the `{NED}` rig
  practice, now stated.

**Spec.** [§7.1][s7-1], [§14.10][s14-10]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Four `FiniteDiff` jacobians:* step-size heuristics, ~4n evaluations,
  exactness lost.
- *Hand-written per-variant gather/scatter structs:* ~150 lines of bookkeeping
  each.
- *Linearize-as-committing-service:* nothing becomes authoritative.
- *Post-linearization trim restoration:* an artifact of probing the live model.
- *Naive quaternion-component seeding:* off-manifold; the coordinate choice is
  the surface author's.

### D-073 — Companion sketches carry the settled condition-algebra design

**Status.** ratified

**Position.** Companion sketches: `sketch_decoder.jl`/`sketch_io.jl` carry the
settled design; a runnable dependency-free `condition_demo.jl` exercises the
[§14][s14] algebra and [§14.9][s14-9] mounting (printed trees and flattened entry lists);
declaration-by-initial-value upheld ([§8.2][s8-2]); sampled-data Dual activation
recorded unbuilt ([§14.10][s14-10]); [§6.2][s6-2]'s `SumJunction` dispatches on its
unparametrized type constructor.

**Spec.** [§6.2][s6-2], [§8.2][s8-2], [§14][s14], [§14.9][s14-9], [§14.10][s14-10]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Split-form sketch files and separate `navsensors.jl`/`imu.md` notes:*
  retired, content absorbed into [§15.5][s15-5].
- *`init_*` as types + `probe_value` synthesis:* defaults are the [§14.1][s14-1] overlay
  base; the [§14.6][s14-6] probe-value barrier; a per-field two-form protocol,
  [§14.2][s14-2]. The `init_*`-as-types grounds spelled out ([§8.2][s8-2]): the condition
  substrate needs an authored value under every leaf ([§14.1][s14-1]'s overlays fall
  back leaf by leaf and the compiled store writers bake `merge(defaults,
  overlay)`), a synthesized initial state crosses [§14.6][s14-6]'s probe-value barrier
  (a fabricated zero is a fine probe input and a terrible flight condition —
  states no less than slots), and every field where synthesis picks wrong
  (modes, `Ranged` values excluding zero, trim-sensitive states) would need an
  authored default *beside* its type — the per-field two-form protocol
  [§14.2][s14-2] kills for `initialize` specs, aggravated in Julia by types being
  first-class values, the two forms distinguishable only by `isa Type`.
- *Extending differentiation through the discrete tier now:* frozen-`z` is
  exact for every built consumer; $\Phi$ differentiability breaks at events —
  kept as an opt-in door.
- *Deferring the demo to the framework prototype:* the algebra is freestanding
  — strings, NamedTuples, four structs.

### D-074 — Hand off component-function arguments as one named bundle

**Status.** ratified

**Position.** Named-bundle hand-off: every component function is `fn(comp,
args)` — one NamedTuple bundle of zero-copy views, destructured by name in the
signature; `project(comp, x)` alone stays positional.

**Spec.** [§5.2][s5-2], [§11.4][s11-4]

**Rationale.** The bundle law (a field exists iff the store or tier fact
exists: undeclared stores absent, never `nothing`-filled; `t` everywhere, `Δt`
discrete-only, `ws` iff `workspace` declared); closed per-function-kind name
sets, growth = a decision-log event; probe failures carry did-you-mean against
the legal set, synthesized from a `FieldError` (structured: type + field as
data, Julia ≥ 1.12) matched against the bundle's own NamedTuple type — no
message-text scraping, the bundle staying a bare NamedTuple, a getproperty
wrapper the recorded fallback.

**Rejected.**
- *Positional signatures + a clock-view type:* dead slots written unread,
  un-droppable mid-list holes; the view type subsumed by naming.
- *Keyword arguments via `Base.kwarg_decl` reflection:* a relied-on seam on an
  internal binding — the [§10.1][s10-1] `task_local_storage` lesson.
- *Keyword + `_...` slurp:* permanent noise; "signature = read-set" weakens to
  "at least".
- *One context object carrying workspace too:* grab-bag accretion; mutable
  member muddies the immutable-views teaching.
- *Time as a wired `Clock` component:* time is ambient in `f`/output
  stages/guards/handlers — two access idioms for one quantity.
- *`nothing`/`(;)` padding for undeclared stores:* defers the error from
  destructuring to first field access, with a worse message.
- *A `comp.Δt` virtual property:* [D-019][d-019] — the period is a schedule-position
  fact, and `===`-identical siblings may sit under different `rates` keys.
- *Positional signatures, additionally:* leave the `t`/`Δt` scalar pair
  swappable without any error, both being bare same-typed reals.

### D-075 — Name flow/update/output stages by letter and dependence class

**Status.** ratified

**Position.** Letters and stage names: `f` = continuous flow, `g` = discrete
update, `h_x`/`h_xu` (continuous) and `h_z`/`h_zu` (discrete) = output stages
with products `y_x`/`y_xu`/`y_z`/`y_zu` — the hybrid-systems flow/jump pair
(Goebel–Sanfelice–Teel) joined to the control/estimation `y = h(x, u)`
convention.

**Spec.** [§5.3][s5-3]

**Rationale.** Bare `h` = step size only (double booking retired); suffix = the
*dependence class* (state-only vs state-plus-input — `y = h(x)` vs `y = h(x,
u)` in the name; modes fold under the state letter, ambient `t`/`Δt`/`ws`
unnamed); the tier pairs mirror exactly (`x`/`xu` ↔ `z`/`zu`); declaration on
the wrong tier = build error (`DeclarationOnWrongTier` — widened from stage
names to all tier markers, `events` included, [D-112][d-112]); three-level narrowing
taught (stage name ⊇ bundle ⊇ destructured reads).

**Rejected.**
- *`h` for the discrete update:* collides with the step size; forfeits the
  jump-map alignment.
- *`g` for outputs:* the complementary collision.
- *`h_xm`/`h_xmu` letter-exhaustive suffixes:* traded for tier symmetry and the
  textbook mirror — the suffix's job is the feedthrough split, not an argument
  inventory.
- *Verb names (`decode`/`compute`):* encode nothing.
- *`Moore`/`Mealy`:* exact, opaque.
- *A tier-neutral stage pair:* no honest neutral state letter; tier-distinct
  names double as cheap drift checks. Superseded on this point by [D-173][d-173] —
  fusing the discrete state into `x` supplies the honest neutral state letter
  whose absence was the rejection's whole ground, and the drift-check value
  dies with the distinction it policed.
- *The earlier `g_s1`/`g_s2` stage spelling:* numbered stages name a schedule
  position, not a dependence class, and leave `h` double-booked.

### D-076 — Name declarations `input_types`/`output_types`/`local_types` by convention

**Status.** ratified

**Position.** Declaration names: `input_types`/`output_types`/`local_types` —
the inventory becomes self-classifying by convention (by value `init_*`, by type
`*_types`, by allocation `workspace`).

**Rationale.** The `input_types`-vs-`input_faces` types/names near-collision
dissolves; tier comes from declaration shape ([D-079][d-079]), not from the method
signature.

**Rejected.**
- *`*_ports`:* the methods type ports, not just enumerate them.
- *`*_schema`:* vaguer than what it replaces.
- *The bare `inputs`/`outputs`/`locals` status quo:* two unmarked classes in
  one inventory; `inputs(c)` vs `input_faces(c)` ambiguity.

### D-077 — Allocate workspace via a per-activation `workspace` method

**Status.** ratified

**Position.** Workspace by allocation: `workspace(::C, ::Type{T})` (continuous)
/ `workspace(::C)` (discrete) — the method *is* the allocator, called per
activation and per scratch-store set.

**Spec.** [§7.3][s7-3], [§8.1][s8-1], [§8.2][s8-2], [§9.1][s9-1], [§9.3][s9-3]

**Rationale.** Sizes from the instance, eltypes from the activation; `undef`
construction the recommended idiom; availability on both tiers (continuous
scratch joins the `T`-generic surface, generic in-place fallbacks under
`Dual`); scoped debug poison (`NaN` on float eltypes, `typemin` on integer
eltypes, element types with no sentinel skipped and the skip reported once per
activation) and no-information-between-calls contract.

**Rejected.**
- *Concrete-nominal allocation + framework `similar`-based re-scalaring
  ([D-079][d-079]-style):* no schema stake here; reconstruction cannot cover non-array
  scratch (plans, factorizations, index buffers); authors legitimately allocate
  scalar-dependent structure (`Dual` chunk-width buffers).
- *Superseded position — `init_workspace` by value (earlier design of record):*
  a workspace is not memory that conditions overlay, and no [§8.2][s8-2] by-value
  argument (condition overlay base, probe-value barrier) covers a store
  conditions exclude and the poison overwrites.
- *`workspace_type` returning types with framework instantiation:* array types
  carry no dimensions; runtime sizes like `kf.n` invisible to any zero-arg
  constructor; size-in-type-parameters lands on the `MMatrix` codegen
  catastrophe.
- *Keeping the discrete-only restriction:* an asymmetry without a principle;
  the multiplicity of continuous calls is the poison check's case, not
  prohibition's.

### D-078 — Treat input entries as face constraints checked by subtyping

**Status.** ratified

**Position.** Input entries are face constraints: wiring check `producer_face
<: entry` at nominal faces — one uniform rule, exact equality the concrete
degenerate.

**Spec.** [§4.4][s4-4]

**Rationale.** Abstract entries = structural substitutability ([§4.4][s4-4] field
handles), never needed for eltype genericity (an eltype-generic producer's
nominal face is concrete by construction); root-slot carve-out — only a tight
(concrete) bound determines a producerless cell's type, abstract-at-root a
build error; under fan-out the slot type is the unique concrete declaration
among consumers, abstract co-consumers checked against it; doctrine:
declarations record choices, obligations are checked.

**Rejected.**
- *Exact-equality-only status quo:* welds [§4.4][s4-4] consumers to one concrete
  producer type, or leaks wiring facts into component type parameters —
  `Strut{H}` cascading through every owning assembly.
- *Symmetric `T` as genericity envelope:* a per-leaf marking that is a constant
  function across components — zero information, wrong granularity,
  false-affordance pins; the predictive reading remains impossible per [D-054][d-054].
- *Phantom root producer with `output_types`-style slot declarations:*
  re-enumerates what exports already are — [D-043][d-043]'s `add_input!` reborn;
  two-artifact drift; root-ness is deployment, not type; its pin bit is policy
  wearing a description's syntax — pinned ≡ unseeded to every derivative.

### D-079 — Type declarations concretely, resolved by an activation leaf walk

**Status.** ratified

**Position.** Concrete nominal declarations + activation leaf walk:
`output_types(::C)`/`local_types(::C)` plain on both tiers; per-activation cell
types from the framework leaf walk — on continuous producers `Float64` leaves
and `Real` *type* parameters follow the activation scalar, `Int`/`Bool`/enum
leaves, reference-typed fields and non-type (value) parameters pin, with the
companion obligation that a Tier-1 type be constructible at the walked type —
enforced by construction at the `Dual` probe.

**Spec.** [§7.1][s7-1], [§8.5][s8-5], [§14.10][s14-10]

**Rationale.** The type derived from `init_x` walks like a continuous
producer's ([§7.1][s7-1]'s all-real-leaves rule checked in Stratum A, didactic
diagnostic) while `init_m`/`init_z` pin wholesale, declared `Float64` initial
values embedding as zero-partial constants; discrete producers pin wholesale
(frozen-exact by typing rule; tier from declaration shape, [§8.5][s8-5]); root slots
walk the consumer declaration; conformance split: exact match at nominal,
parametrized leaves accept exactly `{T, Float64}` with zero-partial embedding —
exact because promotion is airtight and there is no lossy `Dual → Float64` cast
(an observed `Float64` means no `Dual` entered the computation; true derivative
zero); differentiation participation = per-invocation seeding, never typing;
deliberate `value()` stripping = stop-gradient, deliberate-lie class,
schema-visible freezing a recorded [§14.10][s14-10] door.

**Rejected.**
- *Superseded position — the `T`-signature on the output side ([D-033][d-033]/[D-055][d-055],
  earlier design of record):* participation ceremony on every continuous
  component; the forgotten-`T` bug class; piecewise `0.0` branches detonating
  state-dependently under `Dual`; its two real losses — schema-visible
  participation and whole-leaf stripping detection — are tooling niceties, both
  equally blind to mid-expression stripping.
- *Probe-inferred participation:* inverts declarations-define-probes-check; one
  probe point cannot speak for branch-dependent participation.
- *Per-surface slot typing:* layouts keyed by seed set defeat activation
  caching.

### D-080 — Keep Tier-2 event detection pace-independent

**Status.** ratified

**Position.** Tier-2 detection is pace-independent: localization runs
identically in every execution mode, its sweep cost absorbed as [§10.7][s10-7] pacer debt
like any other expensive frame.

**Spec.** [§10.4][s10-4], [§10.7][s10-7]

**Rationale.** Events are rare by nature.

**Rejected.**
- *Superseded position — degrade to Tier-1 under real-time pacing (earlier
  design of record):* reversed because it moves `t*` and diverges paced from
  unpaced trajectories, violating [§10.7][s10-7]'s bit-identical invariant; the "blowing
  the frame budget" worry it answered is dissolved by absolute deadlines + debt
  accounting.

### D-081 — Treat `t*` as a boundary, not a frame

**Status.** ratified

**Position.** `t*` is a boundary, not a frame: frames = grid steps, the
scheduling unit (input drain, pacer deadlines, tick eligibility); boundaries =
published consistency points (grid, `t*`, boundary zero).

**Spec.** [§10.6][s10-6], [§12.3][s12-3]

**Rationale.** At `t*` the full [§10.6][s10-6] iteration runs with once-per-event scoped
per boundary, snapshot published, [§12.3][s12-3] boundary counter incremented, `stop_on`
checked (a crash localized at `t*` ends the run from that snapshot; boundary
zero likewise checked before the first step); ticks never due at `t*`, staged
inputs not drained, publication not separately paced; replay pointers =
monotonic boundary counter + recorded `t`, trace stays frame-indexed.

**Rejected.**
- *Frame-only publication:* contradicts [§13.5][s13-5]'s snapshot-at-the-crossing
  promise.
- *Drain at `t*`:* input timing dependent on localization arithmetic — replay
  indeterminism.
- *Per-`t*` pacing:* wall placement below pacer resolution; the [§10.7][s10-7] invariant
  concerns trajectories.
- *A frame counter in [§12.3][s12-3]:* devices assuming fixed-`h` wake spacing — nothing
  settled does.

### D-082 — Define guard conditions against a per-event baseline

**Status.** ratified

**Position.** Guard conditions and baselines: a guard defines a condition
(`Bool` predicate, or continuous with positive = holding, `σ ≥ 0`); events fire
on not-holding → holding edges against a per-event baseline held in loop state
(previous boundary's quiescent sample, updated at quiescence — detection
bookkeeping, not model memory: not in `z`, not captured, reconstructed on warm
restart).

**Spec.** [§14.5][s14-5]

**Rationale.** Boundary-zero baseline = nothing-holds (authored guard-true
conditions fire at `t₀`, [§14.5][s14-5] derived); opposite direction = second event with
negated guard; localization returns the holding endpoint of the final bracket —
`t* = tₙ` structurally impossible (left end strictly not-holding; published
boundaries immutable), guard observably holds at `t*`, `t* = tₙ₊₁` degenerates
to the grid boundary (Tier-1-coincident, one snapshot); grid times indexed,
never accumulated (remainder step targets the grid point).

**Rejected.**
- *Direction-agnostic sign-change firing:* no coherent boundary-zero behavior;
  hysteresis wants two events anyway.
- *Baseline in `z`:* detection policy leaking into model state, wrongly
  captured and replayed.
- *Level-triggered per-boundary firing:* sticky flags re-fire every boundary.
- *Midpoint or not-holding-end `t*` return:* handler fires where its own
  condition reads false; baseline records an assumption.
- *Suppressing `t₀` firings:* [§14.5][s14-5]'s anti-diagnostic insurance.
- *Accumulated time `t ← t* + h′`:* ulp drift into every tick comparison and
  deadline.

### D-083 — Bind output-device reads to snapshot paths, not just faces

**Status.** ratified

**Position.** Output-device reads are snapshot-path bindings: writes speak the
root contract (faces, claims, exclusivity — service by definition), reads see
the whole table (inspection observation, the log/GUI/replay clients; local
cells accessible — presentation filters are defaults, not walls).

**Spec.** [§13.3][s13-3], [§13.5][s13-5], [§14.4][s14-4]

**Rationale.** Attach validation against the `Build` makes structural drift
loud; two-sided guidance — deep path = inspection (zero promises, right for
this build), exported output face = integration (curated writer-independent
meaning, the only shield against silent semantic drift under
same-path/same-type substitution); generic consumers bind faces, aircraft
families export conventional surfaces with wrapper types (`VelocityData` —
field meaning defined at the type; wrong quantity = deliberate lie, not drift)
as the checkable fraction of semantics; [§13.5][s13-5]'s observation-by-path rejection
rests on the service/inspection split alone.

**Rejected.**
- *Faces-only reads:* export bloat: the root contract as a peripheral dumping
  ground; no decoupling gained: diagnostic consumers are build-specific by
  nature; unenforceable: the log and GUI already see everything; and
  restricting reads does not create meaning-stability — exporting curated
  surfaces does.
- *Semantic validation machinery:* meaning is not in the schema; the
  wrapper-type idiom is the checkable fraction.

### D-084 — Drop the unconnected-output warning

**Status.** ratified

**Position.** No unconnected-output warning: under mandatory `output_types`
models carry many observation-oriented ports no wire consumes ([§11.2][s11-2] blesses
exactly that), and [D-083][d-083]'s path-bound readers attach post-build, so "unused" is
undecidable at build.

**Spec.** [§6.1][s6-1], [§11.2][s11-2], [§11.7][s11-7], [§13.2][s13-2], [Appendix C][sC]

**Rationale.** Such a warning fires on every honest port and poisons the sole
warning stream ([§11.7][s11-7]'s anti-diagnostic lesson); the hazard it would guard (a
wire someone meant to draw) is the consumer side's unconnected-*input* error,
where the information actually lives; the warning stream survives, empty.

**Rejected.**
- *Superseded position — warning on unconnected outputs (earlier design of
  record):* a stream of false positives trains users to skip it.
- *Narrowing it:* no principled subset exists — "should have been wired" is not
  decidable from structure, and every candidate predicate still hits honest
  diagnostic ports.

### D-085 — Unpack `Tuple`/`NamedTuple` fields as container children

**Status.** ratified

**Position.** Container children: `Tuple`/`NamedTuple` fields with
all-component elements unpack as children (`"field/1"`/`"field/key"` path
segments, declaration-order layout); containers are transparent grouping — no
contract, no `connections`, no rate scope.

**Spec.** [§8.8][s8-8], [§14.9][s14-9]

**Rationale.** Elements are the *parent's* children, wired/exported/rated by
element name; parametric rosters (`Formation{NT <: NamedTuple}`) compose per
instantiation via [§8.8][s8-8] generic holding, wires generated by comprehension
(arity-via-computed-contracts at structure scale; [§14.9][s14-9] swarms and
`at`-mounting consume directly); mixed component/non-component elements = build
error, zero-component containers = inert data, no container nesting (first
cut), empty containers legal, `rates` keys = element names with bare-field-name
uniform-`K` sugar.

**Rejected.**
- *One-field-per-child + programmatic struct generation:* roster frozen in
  source text; fights the no-macros stance.
- *Homogeneous-`NTuple`-only:* the per-element complexity objection was hollow
  — element types are static either way; named and mixed rosters are the [§14.9][s14-9]
  case, user call.
- *`Vector{C}` children:* runtime-sized, mutable — breaks the immutable tree
  and the type-stable layout.
- *Containers as anonymous assemblies:* a second composition boundary without a
  type — wiring must stay with the parent.

### D-086 — Compile the executor's schedule into unrolled statically-typed entries

**Status.** ratified

**Position.** The compiled executor ([§9.7][s9-7]): schedule data compiled per
activation into a concretely-typed entry tuple over statically typed storage,
walked by compile-time unrolling — [§7.5][s7-5]/[§9.5][s9-5]/[§5.1][s5-1] are reachable only under
full specialization.

**Spec.** [§5.1][s5-1], [§7.5][s7-5], [§9.5][s9-5], [§9.7][s9-7]

**Rationale.** Phase bodies as the semantically forced outer decomposition
(order-free `h_x`/`f`/`g` blocks, topo-ordered `h_xu` block, event callables —
seams cost nothing; parallel-evaluation and incremental-recompile doors
recorded); chunking behind statically-typed function barriers bounds compile
cost (superlinear → linear, measured; chunk size the only representation
freedom); mitigation ladder = lazy activations, reduced opt-level for
non-nominal activations, precompile-workload caching (TTFX a CI artifact);
views rebuild-per-call (hoisting = compiler CSE, whose legality condition is
the staleness rule); schedule tuples constructed type-opaquely, consumed only
by the walk.

**Rejected.**
- *Vector-of-abstract entries:* per-entry dynamic dispatch boxes stage returns
  — kills [§7.5][s7-5] and its canary role, unfolds [§9.5][s9-5]'s check; union splitting
  rescues only toy scale and cannot close an open method set.
- *Type-erased call tables (`FunctionWrapper`-style):* same specialization
  count as chunk-of-one with extra machinery, no cross-entry inlining/SROA,
  a relied-on seam on internal ABI — the [§10.1][s10-1] lesson.
- *Framework-maintained view hoisting:* manual cache-invalidation duty for
  loads the compiler hoists exactly where legal; mis-scoping = silent
  stale-state reads.

### D-087 — Freeze the device roster as a build-validated immutable value

**Status.** ratified

**Position.** Device roster representation and provenance ([§11.3][s11-3]), as narrowed
by the [D-106][d-106] freeze: the roster (entries, claims, order) is a plain immutable
value the loop reads once at `run!` — no republication, no per-frame
acquire-load, no sequence numbers (attachment order = the roster's own order).

**Spec.** [§11.3][s11-3]

**Rationale.** The roster post-dates the build and `attach!` validates against
the `Build` artifact; trace device tags are stable ids, never roster indices —
ids read across runs, where the roster does change.

**Rejected.**
- *Superseded position — attach/detach legal at any time, an atomically
  republished roster acquire-loaded per frame top with mid-frame attach taking
  effect next frame, sequence numbers for order stability, claim release on
  detach and on the `should_close` exit path (earlier design of record):*
  superseded wholesale by the [D-106][d-106] roster freeze.
- *Roster fixed at build:* devices post-date the build.
- *Roster-index trace tags:* indices unstable *across runs* — replay provenance
  broken.
- *Mid-run claim release on task death:* the freeze adopts the reverse: see
  [D-106][d-106]'s reversal note.

### D-088 — Define the run lifecycle: built → initialized → running → stopped/errored

**Status.** ratified

**Position.** Run lifecycle ([§12.6][s12-6]): built → initialized (`init!` ran boundary
zero) → running → stopped/errored; `init!` mandatory before `run!`/`step!` (its
absence a distinct diagnostic from `UninitializedSlots`).

**Spec.** [§12.4][s12-4], [§12.6][s12-6]

**Rationale.** Deviceless `run!` synchronous on the calling task; `step!(sim;
frames)` = synchronous partial advance through ordinary frames, bit-identical
to the same frames under `run!`; stopped → `init!` → `run!` supported (trace
*and* log cleared at `init!`; attachments persist as roster entries —
orthogonal to the run lifecycle, tasks per-run per [D-093][d-093]); between `step!`
calls the status is `initialized` (boundary-consistent, ready to advance),
`run!` may follow `step!` from the current boundary, `t_end`/`stop_on` honored
during `step!` through the ordinary [§12.4][s12-4] tail, and `step!` returns the frames
*actually* advanced; `t_end`/`stop_on` re-bindable per run at `run!` ([D-091][d-091]);
`errored` terminal ([D-059][d-059]).

**Rejected.**
- *`run!`-only surface:* kills the test-harness advance-assert idiom and the
  REPL fly-inspect-continue idiom — neither is a [§12.5][s12-5] script.
- *Implicit auto-`init!`:* which condition? silent defaults are [§14.6][s14-6]'s
  rejected zero-fill.
- *Resumable errored sims:* [D-059][d-059] — stores may be mid-boundary.

### D-089 — Route supervisor gains and resets through ordinary ports

**Status.** ratified

**Position.** Supervisor idioms ([§15.2][s15-2]): scheduled gains are input ports —
scheduler components own lookup tables as inert parameters and publish
per-compensator gain bundles (gain trajectories observable in log/trace/replay,
dependency visible to the feedthrough graph, linearization holds unseeded gains
constant).

**Spec.** [§15.2][s15-2], [§16][s16], [Appendix A][sA]

**Rationale.** One-shot design-time gains = construction-time parameters or
stopped-sim service outputs; commanded resets are same-tick inputs consumed in
the *output stage* with `g` storing the matching `z⁺` ([Appendix A][sA] entry; reset
honored only in `g` = one-tick-late outputs, legal where that is meant).

**Rejected.**
- *Writable parameter store / `Ref`-mutable component parameters:* invisible to
  log, trace, replay and the feedthrough graph — [D-031][d-031]'s raw-poke rejection
  applied to parameters; breaks immutable component structs.
- *A framework reset capability:* ordinary ports suffice — a second mechanism.
- *Reset-in-`g`-only as the idiom:* publishes the stale command at the
  engagement tick — the bump bumpless transfer removes; [§10.6][s10-6]'s `z⁻¹` discipline
  makes the output stage the only same-tick path, [D-067][d-067].

### D-090 — Return handler updates as bundle-law NamedTuples

**Status.** ratified

**Position.** Handler returns are NamedTuples under the bundle law ([§5.2][s5-2],
[§9.5][s9-5]): `(; x, m)`, a key present iff the store exists AND the handler updates
it — a pure FSM returns `(; m = …)`, a reset map `(; x = …)`.

**Spec.** [§5.2][s5-2], [§9.5][s9-5]

**Rationale.** Checks per key: `x` present ⇒ complete against the state field
set, `m` present ⇒ names-subset, unknown key ⇒ did-you-mean against `{x, m}`
narrowed to the declared stores — the argument-side `FieldError` machinery run
in both directions.

**Rejected.**
- *Positional pair `(x⁺, m⁺)`:* reintroduces the padding [D-074][d-074] bans on
  arguments — `((;), m⁺)` / `(x⁺, (;))` for single-store components — and lets
  the two stores swap with a diff-shaped rather than name-shaped error.

### D-091 — Override `t_end`/`stop_on` per run at `run!`

**Status.** superseded → [D-255][d-255]

**Position.** `t_end`/`stop_on` are `Simulation` defaults overridable per run
at `run!` ([§13.5][s13-5], [§12.6][s12-6]): the `run!` argument binds that run only, nothing on
the `Simulation` mutates.

**Spec.** [§12.6][s12-6], [§13.5][s13-5]

**Rationale.** Effective values recorded in run metadata, `stop_on` face
validation identical at both binding sites.

**Rejected.**
- *Ctor-only binding:* a different stop policy across [§12.6][s12-6]'s re-run/`step!`
  cycles costs a rebuild.
- *Root-type-declared policy:* [D-060][d-060] stands — the override moves binding
  *later* along the deployment axis, not into the model; the root-declared
  *default* variant remains the [§16][s16] residual.

### D-092 — Normative diagnostic kind table (Appendix C)

**Status.** ratified

**Position.** The diagnostic kind set is a normative table — [Appendix C][sC]: kind
name, payload fields, owning section, severity (five values, incl. `service`
for post-build validation against the `Build`; six since [D-159][d-159]).

**Spec.** [Appendix C][sC]

**Rationale.** [D-058][d-058]'s missing deliverable and the acceptance-test contract —
adding a kind is a decision-log entry.

**Rejected.**
- *Illustrative prose enumeration ("roughly one per rule"):* [D-058][d-058] makes tests
  bind to kinds, so the set is API and "roughly" is unwritable-against.
- *Deferring the table to migration:* assembling it is itself a spec audit — it
  surfaced kinds named in prose with no payload stated anywhere.

### D-093 — Spawn device tasks per run, not per attach

**Status.** ratified

**Position.** Device tasks are per-run artifacts ([§11.1][s11-1], [§12.4][s12-4], [§12.6][s12-6]): `run!`
spawns one task per roster entry after per-run device `init!` (resource
acquisition per run — FlightCore's create-a-new-socket-each-`init!` in
network.jl the precedent; `attach!` never spawns — one semantics, register,
[D-106][d-106]).

**Spec.** [§11.1][s11-1], [§11.6][s11-6], [§12.2][s12-2], [§12.3][s12-3], [§12.4][s12-4], [§12.6][s12-6], [§13.4][s13-4]

**Rationale.** [§12.4][s12-4] joins all tasks at every stop with `shutdown!` releasing
OS resources; what persists across `stopped → init! → run!` is the roster entry
(binding, claims, stable device id); spawn-inside-`run!` replaces the start
gate, and first-boundary synchronization is [§12.3][s12-3]'s counter-plus-condition
predicate wait; `should_close` and the [§12.2][s12-2] liveness heartbeat are run-scoped,
unplug-while-stopped surfaces as the next run's device-`init!` failure. The GUI
is the one rostered device *without* a spawned task — CImGui pins rendering to
the calling task, so the loop is the movable piece: with a calling-task device
rostered the loop moves to a spawned task for the run — roster-derived, `gui =
true` mere ensure-rostered sugar ([D-109][d-109]) — otherwise the loop runs on the
calling task (preserving [§13.4][s13-4]'s synchronous rethrow and inline threading of
parallel batch sweeps); `run!` blocks its caller either way. Stepping sessions
are deviceless by construction (`attach!` registers only, tasks appear at the
next `run!`); the write/read paths while stepping are [D-096][d-096]'s harness writer;
`init!` discards staged batches along with trace and log.

**Rejected.**
- *`Event` start gate "as today":* [§12.3][s12-3]'s rejected primitive — the `io_start`
  reset race, re-imported for the re-run cycle [§12.6][s12-6] newly supports.
- *Persistent tasks parked across stops:* `while running(handle)` false from
  the first iteration; contradicts [§12.4][s12-4]'s guaranteed `finally shutdown!`;
  gives liveness and `should_close` no meaning while stopped.
- *Task handles or lifecycle state in the roster:* mixes mutable lifecycle into
  [D-087][d-087]'s immutable roster value.
- *Always-spawned loop task FlightCore-style:* uniform topology whose only
  beneficiary is the GUI case: costs the [§13.4][s13-4] synchronous rethrow —
  `TaskFailedException` wrapping — inline `@threads` composability of batch
  sweeps, and direct interrupt delivery.
- *GUI as a genuinely spawned task pinned to thread 1:* falsifies [§12.2][s12-2]'s
  cannot-fail-to-be-scheduled argument; buys nothing CImGui permits.

### D-094 — Close the state-leaf vocabulary to plain scalars and `SArray`s

**Status.** ratified

**Position.** State leaf vocabulary closed ([§7.1][s7-1]): `init_x` leaves are plain
real scalars and `SArray`s at the common eltype — no domain wrapper types.

**Spec.** [§7.1][s7-1], [§10.4][s10-4], [§14.3][s14-3]

**Rationale.** Views therefore materialize by ordinary invariant-free
construction (bit-faithful round trip, no constructor bypass, no
layout-coincidence machinery in the executor), `Ẋ` has `X`'s shape at `T`, and
off-manifold state is visible to [§10.4][s10-4]'s probes by construction; domain
semantics are explicit casts at the point of use (`RQuat(x.q, normalization =
false)` — today's `f_ode!`-over-raw-views pattern made immutable); invariants
live in `project` and on the write paths (condition apply's baked converts
[§14.3][s14-3], `capture`'s gather, handlers' own constructors).

Annotation (2026-09-14): the declaration is also flat. A `NamedTuple` field
would materialize without invariants, but the condition algebra and the
readers address an `init_x` field as one leaf ([§14.3][s14-3], [§14.4][s14-4]), and structure is
the component tree's to express; the check that enforces the vocabulary
refuses nesting with the rest.

**Rejected.**
- *Invariant-carrying leaves with constructors run on read:*
  `reconstruct(flatten(x)) ≠ x`: every consumer sees a silently projected value
  over a runaway buffer — a clamped `Ranged` hiding its own divergence —
  `project` view-redundant yet buffer-necessary, [§10.4][s10-4]'s off-manifold probes
  impossible.
- *Invariant-carrying leaves with constructor bypass:*
  `reinterpret`/`unsafe_load` over the struct-buffer layout coincidence —
  documented-C-layout-safe under the common-eltype rule and build-time
  verifiable via `fieldoffset`, but internals-adjacent cleverness in the
  executor core to save one cast line per method.
- *Per-leaf lossless-round-trip certification:* an unverifiable convention, not
  a checkable rule.

### D-095 — Prefix the read-selector family with `get_`

**Status.** ratified

**Position.** Read-selector family spelled with a `get_` prefix and completed
([§14.4][s14-4]): `get_state`/`get_deriv`/`get_output`/`get_local`/`get_slot`/`get_face`
— a selector is a *deferred read*, so the prefix names the eventual action,
keeps six short common nouns out of the namespace user declarations share with
domain code, and restores the `local_types` ↔ `get_local` pairing.

**Spec.** [§11.2][s11-2], [§14.4][s14-4]

**Rationale.** `get_face` gives [§11.2][s11-2]'s integration reads their spelling
(previously recommended but unspellable); validation = three policies: the
services `get_state`/`get_deriv`/`get_output`/`get_slot` (completed by
[D-125][d-125]: `get_face` admitted) within owned scopes (no `get_local` — export
instead), inspection readers the whole family (within [D-098][d-098]'s later
source axis), `stop_on` outside the family entirely (root-exported `Bool` faces
only, [D-060][d-060]).

**Rejected.**
- *Bare-noun family:* `local(path, field)` is unparseable — reserved word,
  parses as a scope declaration — and `state`/`output`/`face` collide with
  domain code exactly where declarations use them unqualified.
- *`intermediate` rename alone:* fixes the parse, breaks the
  declaration-selector symmetry.
- *Unexported qualification (`Sel.state(…)`):* taxes every use site and one
  `using` reinstates the collisions.
- *`stop_on` as a family client:* [§13.5][s13-5] forbids path-addressed termination —
  the round-1 slip that motivated the rewrite.
- *`get_slot` doubling for output faces:* opposite directions under one name.

### D-096 — Define the harness writer: `stage!`/`latest`/`step!` duration

**Status.** ratified

**Position.** The harness writer ([§12.6][s12-6], [§11.3][s11-3], [§11.2][s11-2]): `stage!(sim, "face" =>
value, ...)` = task-free staging from the calling task into the interactive
writer ([D-044][d-044]'s derived surface) — traced, surface-checked, drained *last* at
the frame top (the explicit hand of code beats a widget interaction; sequencing
within one writer, not cross-device policy), so the mutation doctrine
(staging and control, nothing else) and replay bit-identity hold.

**Spec.** [§11.2][s11-2], [§11.3][s11-3], [§12.6][s12-6]

**Rationale.** `latest(sim)` = the current published snapshot, the same
immutable value device handles read; `step!` gains the duration spelling
`t_plus` (whole frames until the boundary time covers the duration, mutually
exclusive with `frames`); together the write/read halves of [D-088][d-088]'s
advance-assert and fly-inspect idioms and the migration path for the suite's
dominant write-`u` → `step!` → assert idiom.

**Rejected.**
- *A special harness device:* a device with no task is `stage!` with extra
  ceremony.
- *`step!(sim; inputs = …)` drain-from-argument:* a second staging spelling
  with no `run!` analogue.
- *Direct slot pokes from the calling task:* [§2.2][s2-2]/[§12.5][s12-5]'s rejected
  unrecorded-mutation idiom — breaks replay.
- *Leaving reads to device handles or the log:* the log can be off, a handle
  needs a device, and [D-088][d-088]'s "inspect" must be spellable.
- *A public closure-evaluation API:* [§13.5][s13-5]'s rejected cost — an inspection
  *accessor* returning the immutable snapshot is not it.

### D-097 — Split device shutdown failures into two diagnostic kinds

**Status.** ratified

**Position.** Device shutdown diagnostics get kinds: `DeviceJoinTimeout`
(device id, the join timeout, boundary time/index at shutdown) and
`DeviceCrash` (device id, exception as `cause`, the `should_abort`
disposition), both warning (runtime).

**Spec.** [§12.4][s12-4], [§13.2][s13-2], [§13.4][s13-4], [Appendix C][sC]

**Rationale.** [§12.4][s12-4]'s committed abandoned-join warning and device-crash log
join [§13.2][s13-2]'s closed inventory per [D-092][d-092]'s rule; two kinds, not one, because the
payloads differ in the decisive field (`cause`) and [§13.4][s13-4]'s domain
separation already treats the crash path as its own species.

**Rejected.**
- *A single merged device-failure kind:* union payload; blurs abandoned-join vs
  caught-crash, which [D-058][d-058]'s kind+payload test binding must distinguish.
- *Leaving them prose-only warnings:* a committed warning with no kind is
  [D-092][d-092]'s rejected "unwritable-against" state.

### D-098 — Resolve selectors against a source before client policy

**Status.** ratified

**Position.** Selector source axis: a selector resolves against a *source*
before any client policy — table selectors
(`get_output`/`get_local`/`get_slot`/`get_face`) against boundary snapshots;
store selectors (`get_state`/`get_deriv`) only against live stores, which only
stopped-sim service evaluations, `capture` and post-run inspection ever hold.

**Spec.** [§14.4][s14-4]

**Rationale.** A snapshot-bound reader naming a store selector is an
attach-time `ReadBindingUnresolved` (new `reason` payload field), didactic
style, remedy = declare the field public and read the auto-published port;
[D-083][d-083]'s client split rides on top unchanged, [D-095][d-095]'s family stays closed and
identically spelled.

**Rejected.**
- *Client-only validation:* [D-095][d-095]'s original "diagnostic readers admit the
  whole family": an output device binding `get_state` passes attach — the
  schema knows the field — then has nothing to gather from at run time, the
  silent-garbage failure attach validation exists to prevent; `get_deriv` worse
  — `ẋ` is integrator scratch, not boundary-consistent.
- *Runtime resolution failure:* defers the error [§11.2][s11-2]/[§15.4][s15-4] deliberately moved
  to attach.
- *Snapshots carrying stores to make such bindings resolvable:* [D-038][d-038] stands —
  the source axis enforces it.

### D-099 — Spell the CI activation invariant with a canonical probe scalar type

**Status.** ratified

**Position.** CI activation invariant spelled with an exported canonical
concrete probe scalar: `const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64,
1}`, so the pin reads `build(world; activations = (Float64, ProbeDual))`.

**Spec.** [§14.10][s14-10]

**Rationale.** Activations are keyed by concrete scalar types ([D-052][d-052]) and a
bare `Dual` `UnionAll` cannot key one, be walked to, or answer `zero(T)`; the
width is arbitrary (CI pins genericity, not a Jacobian — [§14.10][s14-10] chunks at its
own widths).

**Rejected.**
- *Bare `Dual` in the invariant:* [§9.4][s9-4] contradicted its own caching paragraph
  twelve lines down.
- *Documented sugar (`build` expanding `Dual` to the canonical type):*
  type-rewriting magic inside an entry-point keyword.
- *A `probe_dual()` helper method:* the value is in essence a type alias, and a
  tuple mixing a type with a call result reads incoherent.

### D-100 — Freeze `u` at round start for within-round event visibility

**Status.** ratified

**Position.** Within-round event visibility: handler-phase `u` gathers
materialize at round start — after guard evaluation, before any handler runs —
and the per-event re-decode reuses that round-start `u`; `y` binds live (own
cells only, disjoint from `u`'s foreign set), so same-component successors see
refreshed own ports (handler returns latch per-event) while foreign transitions
arrive only through the next round's re-sweep.

**Spec.** [§5.3][s5-3], [§10.6][s10-6], [§11.2][s11-2], [§13.4][s13-4]

**Rationale.** Immutable cell values make early reference-loading a zero-copy,
zero-allocation capture ([§11.2][s11-2]'s publication trick applied within a boundary);
cross-component handler order is thereby semantically unobservable and is fixed
(executor component order, declaration order within a component) only for [§13.4][s13-4]
cursor/diagnostic determinism; `u` binds round-start uniformly, the own-wired
corner included.

**Rejected.**
- *Live-table reads under the canonical order:* deterministic, but trajectories
  then depend on the executor's schedule order — a rewiring that permutes it
  silently changes model semantics, the structure-the-framework-inserts class
  [§10.6][s10-6] rejects.
- *A table copy per firing round:* identical semantics, pays an allocation
  pre-materialization avoids.
- *An opt-in for same-round foreign visibility:* same-instant cross-component
  coupling is a cascade — one round per link — and tighter coupling belongs
  inside one component, the synchronous-languages position.

### D-101 — Implement replay as the ordinary loop with two substitutions

**Status.** ratified

**Position.** Replay: `replay!(sim, trace(sim0); to_boundary)` is the ordinary
loop with exactly two substitutions — boundary zero initialized from the trace
header, and the frame-top drain fed by the recording's batches keyed by frame
ordinal (exact: the frame sequence is itself deterministic), applied verbatim
with no surface re-check (the write-surface rule ran at recording time).

**Spec.** [§12.7][s12-7], [§14.5][s14-5]

**Rationale.** The header captures the resolved stores + slots after `apply!`
and BEFORE the boundary-zero sequence — [§14.5][s14-5]'s end-of-sequence capture
placement corrected, since a post-sequence capture would re-fire authored
conditions onto already-latched state — and boundary zero is re-executed under
replay, firings recomputed never recorded; replay ends `initialized`
(replay-to-inspect, replay-to-k−1-then-`step!` error reproduction, `run!`
continuation) and re-records its own trace (header inherited, bit-identical
prefix); pacing/control plane unchanged (paced replay + visualizer = session
playback); rostered devices run as snapshot readers, live staging never drained
(`ReplayDiscardedStaging`); entry validation loud and up front
(`ReplayHeaderMismatch`, `ReplayUnknownFace`), the same pass normalizing the
interactive writer's sparse records to positional batches against the
header's schemas ([D-107][d-107] — once, off the loop, so the replay drain applies
compiled scatters exactly as the live drain); structural mismatch errors,
parametric difference = the what-if replay (determinism promised,
reproduction only against the identical build).

**Rejected.**
- *A `run!(sim; replay = trc)` flag:* replay replaces `init!` and swaps the
  drain source — a lifecycle entry, not a run option; muddies [§12.6][s12-6]'s
  mandatory-`init!` rule.
- *A synthetic playback device staging recorded batches:* wall-clock staging
  cannot hit recorded frame ordinals — reintroduces the scheduler-determined
  input timing [§11.1][s11-1] indicts.
- *Replay ending `stopped`:* kills inspect/step/continue.
- *Re-checking write surfaces at replay drain:* claims are live-roster facts of
  the recorded session; re-derivation would discard valid recorded writes.
- *Header = the authored sparse condition:* [§14.5][s14-5]'s old wording — silently
  replays a different initial state after an `init_*` default edit, [D-038][d-038]'s
  trap.

### D-102 — Author-owned device loop inside a framework-owned bracket

**Status.** ratified

**Position.** Device authoring contract: author-owned loop body inside a
framework-owned bracket — a device implements `init!(dev)` (per-run resource
acquisition, calling task, pre-spawn), `loop(dev, handle)` (the task body,
owning its own wait structure, composed from handle primitives),
`shutdown!(dev)` (guaranteed via the wrapper's `finally`) and optional
`unblock!(dev)`.

**Spec.** [§11.1][s11-1], [§11.6][s11-6], [§12.4][s12-4], [Appendix A][sA]

**Rationale.** The wrapper is try/catch/finally with `DeviceCrash` on catch and
claims-release/detach on every exit; `should_close` dissolves into the loop
body returning (voluntary exit); the GUI implements the same contract, called
inline on the calling task ([§11.1][s11-1]); heartbeat timestamps ride inside handle
primitives, so liveness needs no loop ownership; the two author obligations
(`running(handle)` predicate, interruptible blocking) are taught ([Appendix A][sA])
and diagnosed (`DeviceJoinTimeout`, stale heartbeat), never forced.

**Rejected.**
- *Framework-owned hook loop (FlightCore's shape):* its eight hooks were never
  sufficient alone, the loop came in three taxonomy-carried flavors; one kind
  would force a declared wait kind = the taxonomy as a trait; the bidirectional
  peer needs two waits a hook loop cannot serve without a select engine; the
  GUI fits no hook set.
- *A two-hook middle (`wait_datum` + `process`):* same failures, softer.

### D-103 — Detect a binding's sides by method presence at attach

**Status.** ratified

**Position.** Binding interface: a binding is a value whose type implements
`faces(b)`/`map_input(datum, b)` (input half: enumeration → claim; mapping
arbitrary and never inspected) and/or `selectors(b)`/`map_output(nt, b)`
(output half: [§14.4][s14-4] selectors compiled to one gather at attach); sides detected
by method presence at attach (the [§8.5][s8-5] declaration-shape idiom; `hasmethod` is
public stable API at a service point, not [D-074][d-074]'s internal-reflection seam),
neither side = attach error.

**Spec.** [§11.4][s11-4], [§11.6][s11-6], [§8.5][s8-5], [§14.4][s14-4]

**Rationale.** No datum-shape contract exists — the datum travels only between
`loop` and `map_input`, same author; binding is an `attach!` argument, never a
device field (narrowing the binding narrows the claim); `TableBinding` is the
one shipped data-driven type (entries in the type ⇒ per-table specialization),
its generic `map_input` owning [§11.4][s11-4]'s conditioning helper; `map_input` purity
taught: cross-datum state lives in the device struct, arrives inside the datum.

**Rejected.**
- *Abstract binding-type taxonomy:* resurrects the [§11.6][s11-6] kill one level down; a
  bidirectional binding cannot be two types at once.
- *A declared `sides(b)` trait:* redundant with the methods that must exist,
  one more thing to drift.
- *Per-device custom mapping code as the norm:* the table case is data, not
  code — one framework `map_input` serves every pairing.

### D-104 — Coalesce staged writes by CAS merge with per-attachment positional shape

**Status.** ratified

**Position.** Staged representation and coalescing: one policy — CAS merge,
newest wins per face (merge is always correct: complete writers get overwrite's
result, sparse writers are protected from its lost-write bug); enumerated
writers get a per-attachment fixed shape compiled at attach — positional tuple
over the claim set, `Union{Nothing,T}` isbits per face, `nothing` = not touched
(never reset), schema in the roster entry — giving positional merge, an
attach-compiled drain scatter (mirror of [§11.2][s11-2]'s gather), and `stage!`-side
normalization (name → position, convert, fill `nothing`) so authors return
sparse face ⇒ value pairs and the name-shaped dynamism is confined to one
framework conversion on the device task.

**Spec.** [§11.2][s11-2], [§11.4][s11-4]

**Rationale.** The interactive writer gets the same treatment under the [D-106][d-106]
freeze — positional shape over the unclaimed set, recompiled at each
stopped-sim `attach!`/`detach!` (which also renormalizes pending batches:
reshape, discard newly-claimed faces with `ClaimedFaceEntry`) — one
representation, no name resolved inside the loop's frame; diagnostic sites all
at staging — `OutOfClaimEntry`, `ClaimedFaceEntry`, `EntryTypeMismatch` — and
the drain checks nothing ([D-106][d-106]); trace records match batch density ([D-107][d-107]);
user-proposed shape (fixed tuple with `nothing` markers), framework-relocated
normalization.

**Rejected.**
- *Name-keyed interactive batches, the earlier design of record:* justified
  only by the mid-session-mutable surface the [D-106][d-106] freeze removed.
- *The `complete(binding)` overwrite opt-in, drafted then dropped:* under
  positional merge the fast path saves a pending-read and a tuple rebuild on
  the device task — not worth a declarable promise whose false direction loses
  writes; supersedes the earlier attach-flag sketch.
- *Author-built total tuples:* a padding form — the [D-074][d-074] / handler-return-law
  disease.
- *Name-keyed batches everywhere:* dynamic dispatch in the drain, inside the
  loop's frame.
- *One build-wide shape over all root faces:* trace memory inflates by
  faces/entries, and only the interactive writer would need it.

### D-105 — Split device-side bad-datum handling into tolerated garbage and propagated crashes

**Status.** ratified

**Position.** Device-side bad-datum policy: two failure classes, two fates —
environmental garbage (truncated datagram, malformed JSON, out-of-range field)
is tolerated in the loop body (catch, stage nothing, `report(handle,
MalformedDatum(cause))`, continue; rate-limited per device — the `maxlog = 25`
successor), any other exception propagates to the wrapper as `DeviceCrash`.

**Spec.** [§11.6][s11-6], [§13.2][s13-2], [§13.4][s13-4]

**Rationale.** Classification is the author's, as FlightCore's
`InputMappingError` docstring already assigned it; `report(handle, …)` is
scoped to device-attributed runtime warnings, not a general user-diagnostics
channel; companion drain-family kind `EntryTypeMismatch` for values
unconvertible to the slot's declared type, checked at staging for every writer.

**Rejected.**
- *A marked exception type (`InputMappingError` successor):* vestigial under
  the author-owned loop, since no framework per-iteration catch site exists to
  consume it.
- *Spec silence:* the natural reading reproduces first-bad-packet-kills-device,
  for the whole run under [D-093][d-093].
- *Tolerate-everything:* hides bugs as "device attached, nothing happens".

### D-106 — Freeze the device roster for the duration of a run

**Status.** ratified

**Position.** Roster freeze: `attach!`/`detach!` are stopped-sim operations —
legal in `built`/`initialized`/`stopped`, an error while `running`, pause
included (pause is inside a run) — so the roster and the partition of the root
face set into per-writer surfaces plus the interactive remainder are static,
inspectable facts of each run; attach has one semantics (register; tasks appear
at `run!`, [D-093][d-093]).

**Spec.** [§11.3][s11-3], [§12.3][s12-3], [§12.5][s12-5], [§12.7][s12-7], [§9.7][s9-7]

**Rationale.** All write-surface checks move to staging and the drain is pure
application, fully compilable against the frozen roster (specialization an
implementation freedom, not an obligation — the [§9.7][s9-7] per-configuration compile
trade); device death mid-run is not detach — the task dies, the heartbeat
reports it, claims and roster entry persist to run end (**reversal of [D-087][d-087]'s
zombie-claims rejection**: that rejection served dynamic liveness derivation,
and with liveness baked per run the rationale inverts — a mid-run release would
move a surface nothing can soundly recompute); orphan recovery is between runs
(stop → `detach!` → `init!`, or `replay!`-to-end + `run!` continuation, [§12.7][s12-7]);
[§12.5][s12-5]'s doctrine reaches final form — the running periphery stages writes and
issues control commands, and nothing else changes. **Guarded addition on
record**: mid-run attach for pure readers (no input half — claims nothing,
moves no surface; a dynamic reader list touches only [§12.3][s12-3] wakeups, heartbeat
and shutdown join, never the drain), cleanly severable should
join-a-running-session find a customer. Supporting fact: FlightCore has no
mid-run attach — every demo attaches before `run!`, and `run!` blocks its
caller in both designs, so the dropped capability had no demonstrated customer
and was barely reachable.

**Rejected.**
- *The earlier attach-anytime design of record:* [D-087][d-087]'s republished-roster
  machinery, drain-time derived-surface membership checking via
  `StaleInteractiveEntry`, [§11.7][s11-7]'s mid-drag claim-transition policy, per-attach
  thread-budget re-checks — all priced for a hypothetical workflow.
- *Mid-run claim release on device death:* the reversed [D-087][d-087] rejection — under
  a frozen surface it is the *release* that would be unsound.
- *Attach-while-paused:* a surface change inside a run — forfeits every
  staticity benefit at the moment it is exercised.
- *Reader exception adopted now rather than guarded:* no customer; the freeze
  stays maximally simple.

### D-107 — Match trace record density to batch density, not surface width

**Status.** ratified

**Position.** Trace records match batch density: enumerated writers' positional
batches are retained verbatim, zero-copy (claim-narrow, dense by nature); the
interactive writer's wide mostly-`nothing` tuple is converted at the drain on
retention — (position ⇒ value) pairs for the non-`nothing` entries, an
O(surface-width) scan and one small allocation at most once per frame, only on
interactive-active frames, inside the [§7.5][s7-5] retention carve-out the log already
occupies — so trace size tracks information, not surface width, preserving
[D-029][d-029]'s two-orders-below-the-log budget at every world scale.

**Spec.** [§7.5][s7-5], [§11.5][s11-5], [§12.7][s12-7]

**Rationale.** The header carries each writer's face-name → position schema
(positional records are meaningless without it and replay does not reconstruct
claims); replay pays the inverse conversion once, up front, in the [§12.7][s12-7]
validation pass — no name resolved per frame under replay either; conversion
site is the drain, not the staging shim (the drained tuple is the coalesced
truth; a shim-side sparse log would need its own merge).

**Rejected.**
- *Verbatim retention of interactive positional batches:* size tracks surface
  width × edit rate — at hundreds of unclaimed faces, render-rate dragging
  inflates the trace past the budget that justifies trace-on-by-default; a
  mostly-`nothing` tuple is also schema-bound and hostile to inspection.
- *Sparse records for enumerated writers too:* their batches are dense — sparse
  encoding adds names for nothing.
- *Shim-side sparse recording:* needs its own merge to match coalescing.
- *Keeping name-keyed replay application:* re-imports the dynamic drain path
  replay exists to avoid.

### D-108 — Gate stopped-sim services by input-derived lifecycle preconditions

**Status.** ratified

**Position.** Service lifecycle preconditions: every stopped-sim service
requires a non-running simulation, pause included (the [D-106][d-106] doctrine — the
loop owns the stores between drains); within the stopped states legality
follows each service's inputs — `capture` requires `initialized`/`stopped`
(reads committed stores), `init!` and `trim!` are additionally legal from
`built` (inputs are authored conditions; trim's scratch world comes from
`override(baseline, condition(guess))`, never the sim's stores), `linearize`
inherits `capture`'s precondition with the defaulted operating point and
`init!`'s with an explicit `about`.

**Spec.** [§11.3][s11-3], [§13.6][s13-6], [§14][s14]

**Rationale.** `errored` is terminal for all four ([D-059][d-059]) — a captured
condition is indistinguishable from a healthy one once produced, so
`capture(errored)` would be resurrection with extra steps and defaulted
`linearize(errored)` a warn-but-assign re-entry; post-mortem stores/log/trace
stay readable as diagnostics, never as condition values; one kind
`ServiceLifecycle` (operation, current status, legal statuses) shared with
`attach!`/`detach!`-while-running — closing the kind [D-106][d-106]'s gating text
lacked.

**Rejected.**
- *Folding `MissingInit` into `ServiceLifecycle`:* distinct cases: a
  missing prior step pointing forward to `init!` vs. an operation illegal in
  the current state — different messages, different tests.
- *Tolerating `capture` on `errored` for diagnostics:* the produced condition
  value is healthy-looking by construction; diagnostic reads need no condition
  value.
- *Gating `trim!`/`init!` out of `built`:* their inputs are authored — the gate
  would forbid mechanically sound calls.

### D-109 — Fix device identity, roster admission and calling-task topology at attach

**Status.** ratified

**Position.** Device identity, roster admission and calling-task topology:
identity is the instance (`===`, one roster entry each; two instances of one
type are two devices), the stable device id is assigned at `attach!` (monotonic
per `Simulation`, never reused, lives with the entry across runs); admission is
a three-part check at attach — identity (`AlreadyAttached`; rebinding =
`detach!` + `attach!`), affinity (at most one `needs_calling_task` holder,
`CallerTaskConflict`), claims (`ClaimConflict`, now always between distinct
devices).

**Spec.** [§11.1][s11-1], [§11.3][s11-3], [§11.6][s11-6], [§12.4][s12-4], [§12.6][s12-6], [Appendix B][sB]

**Rationale.** Calling-task affinity is a device-contract trait (default
`false`, the shipped GUI's CImGui constraint made declarable), task topology is
derived from the frozen roster alone, never from `run!` keywords — with an
affine device rostered the loop moves to a spawned task and the calling task
runs that device's loop body inline in the identical [§11.6][s11-6] wrapper, else the
loop runs on the calling task; the affine device is outside [§12.4][s12-4]'s join and
abandonment (nothing can abandon the task `run!` stands on — its authoring
obligation is a loop body that never blocks between `running` checks); `gui =
true` becomes idempotent attach sugar (ensure-rostered, attach only if absent,
never detaches), so a persisted GUI renders on every later run without the
flag.

Annotation (from the R3(a) adjudication, 2026-08-13): the derivation point and
its `init!`-outcomes term were sharpened after this entry was written —
topology is derived *after initialization*, from the roster **plus `init!`
outcomes**, not from the frozen roster alone. [§11.1][s11-1] and [§12.4][s12-4] carry the
canonical statement, and the looser "roster-derived" shorthand elsewhere
([D-093][d-093], [§12.6][s12-6]) stands as shorthand for it.

**Rejected.**
- *Sugar-only idempotency guard:* leaves explicit double-attach of the GUI
  undefined — two render loops contending for the calling task would falsify
  [§11.1][s11-1]'s topology by user action.
- *Idempotent no-op on re-`attach!` of a rostered device:* silently discards
  the binding the caller handed over — the warn-but-continue pattern.
- *Flag-derived loop placement:* contradicts roster persistence on the second
  run: a rostered GUI must render without the flag.
- *Special-casing the shipped GUI type instead of a trait:* a user-authored
  calling-task device — another renderer — would get no admission check and no
  topology treatment.
- *Silent double-rostering of claim-free readers:* two tasks racing on one
  device instance's own state, double `init!`/`shutdown!` on one OS resource.

### D-110 — Give `trim!` an explicit `t0` argument and state its recording clear

**Status.** ratified

**Position.** `trim!` commit clock and recording clear: `trim!` gains the
init-service `t0` argument (`trim!(sim, problem; baseline, t0 = 0.0, backend)`)
— [D-067][d-067]'s rule applied to the second init-service entry point, never a
`TrimProblem` field (problems stay time-free, [§14.9][s14-9]'s lift untouched); default
`0.0` matching `init!` (one rule for both entry points), resume-at-time spelled
explicitly via `capture`'s returned `t` passed as `t0`.

**Spec.** [§12.6][s12-6], [§14.5][s14-5], [§14.6][s14-6], [§14.8][s14-8], [Appendix B][sB]

**Rationale.** The commit's side effects stated where the reader looks ([§14.8][s14-8]):
an `init!` in every respect — boundary zero, [§14.6][s14-6] pre-write totality,
guards-at-commit, `t0` anchoring, and the [§12.6][s12-6] three-item clear (trace, log,
staged batches).

**Rejected.**
- *Default `t0` = current boundary time (the review's proposal):* two defaults
  to remember across the two init-service entry points, and a context-dependent
  default value, ill-defined from `built`; the defect was the silence, not the
  choice.
- *`t0` as a `TrimProblem` field:* times a relocatable, time-free problem
  value.
- *Leaving the recording clear unstated:* a user who trims to refine an
  operating point loses the session's record with no warning.

### D-111 — Fold `project` into the always-on conformance check

**Status.** ratified

**Position.** Conformance completeness: `project` joins the always-on uniform
check — complete against `X`'s own shape at the activation's `T`, the same
predicate as a handler's `x` key, because its return is written back to the
buffer wholesale at both [§7.1][s7-1] schedule positions and a mode-dependent
projection first executes its second branch at run time (the branch-dependent
hole the always-on check exists to close).

**Spec.** [§7.1][s7-1], [§9.5][s9-5], [§13.4][s13-4], [Appendix C][sC]

**Rationale.** `ConformanceFailure`'s payload field renamed `stage` →
`function` (its values are function kinds — [§13.4][s13-4]'s cursor vocabulary;
`UndeclaredReturnField` keeps `stage`, which for it is exact).

**Rejected.**
- *Leaving `project` probe-checked only:* the probe exercises one branch once —
  precisely the miss the always-on doctrine forbids.
- *A separate project-specific kind:* same predicate, payload and site as the
  existing check — a second kind splits tests for nothing.

### D-112 — Add `events` to the tier-consistency markers

**Status.** ratified

**Position.** `events` joins the tier markers: the tier-consistency rule
enumerates four declaration families — stage names, the `init_*` family,
`workspace` arity, and (when declared) `events`, a continuous-tier marker since
the event system is continuous-side only.

**Spec.** [§3.2][s3-2], [§5.2][s5-2], [§8.2][s8-2], [Appendix C][sC]

**Rationale.** The kind is widened and renamed `StageOnWrongTier` →
`DeclarationOnWrongTier` (payload: the offending declaration — a stage name or
`events` — and the tier the leaf's other declarations announce): one rule, one
kind, keeping the kind list flat (user's call — the exception list is long
already); [D-075][d-075] amended.

**Rejected.**
- *A separate `EventOnWrongTier` beside `StageOnWrongTier`:* additive and
  rename-free, but mints a second kind for the same tier-agreement rule —
  taxonomy economy won.
- *Leaving `events` outside the rule:* a discrete leaf declaring `events` is
  illegal by [§5.2][s5-2]/[§3.2][s3-2]/[Appendix B][sB]'s testimony yet checkable nowhere, and
  tier-exclusive `events` outside a list that includes tier-symmetric
  `workspace` is indefensible asymmetry.

### D-113 — Close four kindless diagnostic rules with new payload fields

**Status.** ratified

**Position.** The kind audit closes four kindless rules and makes one sketch
honest:

- `UnknownPort` is widened with a wire-end discriminator —
  `source`/`destination`, that end's path and port list — a typo'd source port
  being the same walkthrough-1 mistake read at the other end.
- `DeploymentInvalid`: deployment parameter, value in hand, violated constraint;
  service batch per [D-057][d-057]'s declarative class, sibling of `StopFaceInvalid` at
  the `Simulation`-construction site.
- `TrimProblemInvalid`: offending problem field, shapes/names in hand; service
  batch, mirroring `SurfaceResolution` — the residual/tolerance length case
  joins when improvement #7's `tolerances` field is adjudicated in the authoring
  cluster (discharged, [D-118][d-118]).
- `ConditionNodeMisuse` for [§14.2][s14-2]'s mixed-`merge` error method: offending
  argument type, node kinds in hand; raised at composition time before any
  resolution pass or provenance chain exists — hence its own kind, not a
  `ConditionResolution` sub-kind.
- `faces` enforces `except`/`only` mutual exclusivity with a
  `declaration_error`, and `UnknownFaceSelection` gains a reason field (unknown
  names / both selectors given).

**Spec.** [§6.1][s6-1], [§8.4][s8-4], [§8.8][s8-8], [§9.1][s9-1], [§14.2][s14-2], [§14.8][s14-8], [Appendix C][sC]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *`UnknownSourcePort` as a second kind:* the two ends are one mistake; an
  `end` payload field tests exactly as precisely without doubling the taxonomy.
- *Folding the merge rejection into `ConditionResolution` sub-kinds:* misstates
  the site — no provenance chain exists at merge time.
- *Dropping the sketch's mutually-exclusive comment instead of enforcing it:*
  silent-ignore of a passed argument is the warn-but-continue pattern the spec
  rejects everywhere else.
- *A dedicated kind for the both-selectors case:* same site, severity and
  audience as `UnknownFaceSelection` — a reason field suffices.

### D-114 — Order snapshot publication before the boundary counter increment

**Status.** ratified

**Position.** Snapshot/counter publication order and the counter's home: the
boundary index is carried *in* the snapshot (with `t`) — what [§10.4][s10-4]/[§13.4][s13-4]'s
boundary indexing from retained snapshots presupposes — and additionally
mirrored in the loop state the wait predicate tests; publication order is
normative: the release-store of `latest` happens before the counter increment
under the lock, so `counter > last_seen` implies `latest` holds at least that
boundary; waking onto a newer snapshot than the increment that woke the waiter
is expected — newest-wins.

**Spec.** [§10.4][s10-4], [§12.3][s12-3], [§13.4][s13-4]

**Rationale.** Recorded only through the rejections below.

**Rejected.**
- *Counter incremented before the release-store:* a woken waiter satisfying the
  predicate can acquire-load the *previous* snapshot — wake-with-stale-data,
  invisible in testing at 50 Hz, catastrophic for rate-matched telemetry:
  boundary n transmitted twice, n+1 never.
- *Counter as loop state only:* unreachable from a retained snapshot — breaks
  [§10.4][s10-4]/[§13.4][s13-4]'s counter-plus-recorded-`t` boundary indexing.
- *Counter as snapshot field only:* the wait predicate tests it under the
  Condition's lock.
- *Leaving the order unstated:* a fact about two mechanisms owned by no single
  section — the classic gap where implementations silently diverge.

### D-115 — Source the bundle law's remaining probe fields `t` and `ws`

**Status.** ratified

**Position.** Probe sourcing completed for the bundle law's remaining fields:
`t` is probe-scoped `0.0` — deployment binds no clock and `t₀` post-dates even
deployment, [D-051][d-051]'s strict probe-scoping applied to the clock, matching the
settled `Δt = 1.0` placeholder; `ws` comes from invoking the component's
`workspace` allocator at the probing scalar before the Stratum B probes, sound
because [D-077][d-077]'s allocator reads only the instance and the scalar, deriving
nothing from layouts — no Stratum C dependence created, nothing moves between
strata ([D-048][d-048]).

**Spec.** [§9.1][s9-1], [§9.3][s9-3], [§9.4][s9-4]

**Rationale.** [§9.4][s9-4]'s activation-time allocator invocation clarified as a
re-invocation, not an introduction.

**Rejected.**
- *Workspace allocation left as an activation-only (Stratum C) act:* the
  stage-1 probes run in Stratum B and a Kalman-shaped `h_z` reads `ws` on line
  one — the bundle would be incomplete exactly where [§5.2][s5-2]'s law says it exists.
- *Sourcing `t` from deployment or `t₀`:* both post-date the standalone build,
  [§9.2][s9-2].
- *Leaving the two fields unsourced:* the bundle law makes sourcing a
  completeness obligation — "`t` always" — with two implementer-invented
  answers waiting.

### D-116 — Expose `phase_bodies(sim)` as the zero-allocation invariant's measurement seam

**Status.** ratified

**Position.** The zero-allocation invariant's measurement seam:
`phase_bodies(sim)` returns the compiled bodies of the nominal activation as
named callables bound over the simulation's own buffers — the four blocks
(`rhs`, `sweep_hx`, `sweep_hxu`, `ticks` taking the tick index its entries gate
on) plus per-event guards/handlers and per-component `project`, keyed by the
model's roster; one inspection promise: identity with the bodies the
loop runs, so the in-loop argument types come by construction; CI is
warm-then-assert at per-body granularity (a documented tolerance loosens
exactly one assertion).

**Spec.** [§7.5][s7-5], [§9.7][s9-7], [§16][s16], [Appendix B][sB]

**Rationale.** [§7.5][s7-5]'s tiers completed: guards and `project` (unconditional per
boundary/frame) join the exactly-zero tier, handlers (episodic, only on firing)
join the tick tier's zero-by-idiom; publication is not a phase body — the [§7.5][s7-5]
carve-out made structural; isolated invocation leaves buffers valid but
off-trajectory (re-`init!` to continue); [§16][s16]'s FlightCore allocation comparison
measures through the seam.

**Rejected.**
- *Per-body exported functions (`rhs!(sim)`, `guard!(sim, path, name)`, …):*
  five-plus exported names, an invented addressing mini-language for the
  per-event callables, and hand-enumerated CI lists that go stale when a model
  gains an event, where the accessor's roster is machine-enumerable.
- *A no-publish advance mode on `step!`:* forks execution semantics for CI's
  benefit and breaks [§10.3][s10-3]'s publication-after-every-boundary property.
- *`@allocated step!` against a pinned nonzero baseline:* drifts with every
  model edit, and a regression can hide inside a legitimate baseline change —
  kills the canary.
- *Per-component standalone tests as the invariant's discharge:* they never
  call the executor, so "framework contribution exactly zero" goes unvalidated;
  hand-built argument types are not the in-loop types inference sees;
  composition-scale pathologies — union-splitting collapse, chunk-seam
  mis-specialization — are invisible; remains a fine authoring practice for
  localizing once the canary trips.

### D-117 — Extend declarations and stages via explicit per-name import

**Status.** ratified

**Position.** The declaration and stage family is extended, not called, and
enters a component module through explicit per-name `import Cadence: init_x, …,
f, g, project, connections, exports, rates` — normative authoring surface
stated in [§8.1][s8-1], with qualified definition (`Cadence.f(…) = …`, the `Base.show`
idiom) the recorded alternative for the extension-only periphery.

**Spec.** [§8.1][s8-1], [§8.4][s8-4], [§16][s16], [Appendix C][sC]

**Rationale.** `StoreWithoutUpdate`/`KindUnreadable` gain a shadowing check
(parent module defines a same-named function `!==` the framework's → the
message names the missing import); [§16][s16]'s exported-name audit widened to name
the declaration/stage family as the larger half of the unexported
extension-only surface; short names stay unexported deliberately (`f`, `g`,
`events`, `project` maximally collision-prone).

**Rejected.**
- *Relying on bare `using`:* silently defines unrelated same-named functions —
  verified: no error, no warning, and the build's diagnostics then misname a
  namespace mistake as a modeling one, the [§8.4][s8-4] error-locality inversion
  through the namespace.
- *A re-export submodule as the ergonomic fix:* `using Cadence.Declarations`
  carries identical silent-shadowing semantics — per-name `import` is the only
  extension idiom the language provides.
- *Adopting an `@declarations` macro now:* sugar addable a posteriori, never
  essential ([D-032][d-032]).

Annotation (2026-09-17): [D-246][d-246] makes the shadowing check a fail-fast kind of
its own, `DeclarationShadowed`, run before the class is read; the two
diagnostics named here carry no note.

### D-118 — TrimProblem authoring surface

**Status.** ratified

**Position.** The `TrimProblem` field set closes at seven —
`guess`/`lower`/`upper`, `condition`, `reads`, `residuals`, `tolerances` — with
`tolerances` an all-`Float64` NamedTuple same-shaped as the residual return,
carried in the problem because a relocated problem must carry its own
convergence test (`at`'s lift gains it as a path-free pass-through). The
residual signature is `residuals(reads::NamedTuple, d::NamedTuple) →
NamedTuple` under one rule: what the solver varies is passed (`d` cannot be
closed over), what is fixed per problem is closed over (`TrimParameters` stays
framework-invisible, as `condition` already holds it). Returned names are the
report's equation names; the service packs residuals and tolerances by field
order (the decisions rule, [D-069][d-069]).

**Spec.** [§14.7][s14-7], [§14.8][s14-8], [§14.9][s14-9], [Appendix B][sB], [Appendix C][sC]

**Rationale.** Shape/key-set checks at the setup guess evaluation join
`TrimProblemInvalid`, discharging [D-113][d-113]'s pre-staged clause. A worked
three-equation C172 cruise problem was added to [§14.7][s14-7].

**Rejected.**
- *Vector-returning residuals:* [§14.8][s14-8]'s failure reports name unbalanced
  equations — names must exist; packing is the service's job on both ends of
  the seam.
- *Passing `TrimParameters` as an argument:* [§14.7][s14-7] settled that the framework
  never sees it.
- *`tolerances` as a `trim!` keyword:* the [§14.9][s14-9] lift is field-by-field — a
  relocated problem would lose its convergence test.
- *Deciding the signature per backend:* the seam contract is the author's one
  implementation target.

### D-119 — Add `Simulation(build::Build; …)` as a second constructor

**Status.** ratified

**Position.** `Simulation(build::Build; …)` becomes a second constructor entry
point, with `Simulation(world; …)` defined as `Simulation(build(world); …)`.

**Spec.** [§9.2][s9-2], [Appendix B][sB]

**Rationale.** The inspected artifact — CI-checked, acceptance-tested,
provenance-printed — is the one deployed; computed `exports` bodies are
ordinary user code re-evaluated per build, so equality between two builds of
one world is an assumption the factorization removes; deployment binding is
unchanged, only at `Simulation` construction ([D-048][d-048]).

**Rejected.**
- *Declining as pure convenience:* the review's own tag — but [D-049][d-049] made
  `Build` the artifact `attach!` validates against and CI checks, and "the
  phase outputs exist anyway" argues the factorization, not just the standalone
  entry point.
- *Making `build` reproducibility a checked guarantee instead:* unenforceable
  over arbitrary user `exports` code.

### D-120 — Reconcile rigs with abstract-at-root via stub children

**Status.** ratified

**Position.** A component with abstract input entries is rigged with a concrete
stub child (`SampleTerrainField` provider) wired to the abstract face, the
concrete remainder exported via `faces(rig, child; except)` — zero new
machinery, the substitutability contract read as "the rig chooses its
substitute explicitly, as ordinary inspectable code."

**Spec.** [§4.4][s4-4], [§8.2][s8-2], [§13.7][s13-7], [Appendix C][sC]

**Rationale.** `AbstractAtRoot` gains the remedy hint (wire a concrete
producer; in a rig, a stub child).

**Rejected.**
- *Relaxing abstract-at-root:* [D-078][d-078] stands: staging cells, trace header and
  `probe_value` need concrete types at build.
- *A narrowing form at export:* new machinery, breaks the consumer-sourced
  slot-typing rule and [§13.7][s13-7]'s no-framework-support charter.
- *Leaving [§13.7][s13-7]'s "any component in isolation" claim unqualified:* false for
  exactly the class [§4.4][s4-4] exists to support.

### D-121 — Partition the cell/store vocabulary and bless "staging cell"

**Status.** ratified

**Position.** Bare *cell* denotes a signal-table entry only; `z`/`m` live in
*stores*; *staging cell* is blessed as a distinct compound term (the per-device
inbound register, mutated per frame, outside the table's publish-once
discipline).

**Spec.** [§2.1][s2-1], [§4.1][s4-1], [§5.2][s5-2], [§7.1][s7-1], [§7.3][s7-3], [§10.4][s10-4], [§10.5][s10-5], [§11.7][s11-7], [§13.6][s13-6], [§14.3][s14-3],
[Appendix A][sA], [Appendix B][sB]

**Rationale.** [§13.6][s13-6]'s integration intermediates are renamed framework-owned
integrator buffers, never a component's `workspace` ([§7.3][s7-3]'s term is
author-facing, poison-covered scratch); the four loose "sign change" spots are
restated as not-holding → holding edges against baselines — Tier-2's trigger
now states the direction and the even-crossings blind spot survives as "no edge
observed" ([D-082][d-082] restated, no semantic change).

**Rejected.**
- *Renaming "staging cell" itself:* entrenched through [D-106][d-106]–[D-107][d-107], the
  walkthrough and the commit history; the compound is unambiguous once [§4.1][s4-1]
  defines it.
- *Rewriting the log's historical [D-004][d-004]/[D-013][d-013]/[D-024][d-024] to the new vocabulary:*
  amendments annotate, never rewrite.
- *Leaving [§4.1][s4-1]'s "throughout this document" rule broken by the spec's own
  normative prose:* a reader applying it uniformly derives the wrong
  mutation invariant for staging cells.

### D-122 — Resolve de-polysemy by giving each overloaded term one owner

**Status.** ratified

**Position.** Each overloaded term keeps one owner; the evicted senses get
their own words (spec-wide; user request 2026-08-03). Event detection **Tier
1/2 → boundary-detected/localized** and genericity **Tiers 1/2/3 →
walked/pinned/exempt**, leaving bare *tier* solely continuous/discrete; guard
**condition → predicate**; event **baseline → prior**; component **kind →
class**, **function kind → function family**; error-report **batch → collect**
and **batch run → unattended run**; linearization **surface → taps**;
**recording registers → recorders** and the [§12.6][s12-6] **harness register → harness
cell**, reserving *register* for the idiom/mode sense.

**Spec.** [§11.3][s11-3], [§11.6][s11-6], [§12.6][s12-6], [§8.2][s8-2], [§14][s14], [§14.5][s14-5], [§16][s16]

**Rationale.** Event detection: Tier 1/2 → boundary-detected/localized is
descriptive, matching the `localize` flag (`Tier2GuardPredicate` →
`LocalizedGuardForm`); genericity Tiers 1/2/3 → walked/pinned/exempt uses the
leaf walk's own verbs (`DeclarationOnWrongTier` untouched, [D-112][d-112] intact — kills
the double-numbered collision inside [§8.2][s8-2]). Guard condition → predicate: [§14][s14]'s
condition value owns the word and the API (~124 vs ~18 sites; `σ` restyled the
sign value). Event baseline → prior: the `baseline` keyword of `trim!`/`init!`
owns it; *armed/arming* considered and set aside — inverts the stored sample's
sense. Component kind → class: `KindUnreadable` → `ClassUnreadable` — a
diagnostic kind named after the other sense was the worst collision; [§11.6][s11-6]
retitled "one authoring contract, no taxonomy" (diagnostic kind/payload owns
bare *kind*). Error-report batch → collect: the site column now `build/service
(collected)`; batch run → unattended run: device write batches own *batch*.
Linearization surface → taps: `linearize(sim, taps)`, `TapResolution`; write
surface untouched, freeze vocabulary. Recording registers → recorders and the
[§12.6][s12-6] harness register → harness cell ([§11.3][s11-3]'s existing name). Deliberately
kept: *boundary zero* (a hyponym — it IS a step boundary, [§14.5][s14-5]'s whole point),
*frame* both senses (loop frame ~40 entrenched sites vs. kinematic reference
frames — compound discipline instead), *entry* (always compounded).

**Rejected.**
- *Renaming the entrenched owners instead:* condition algebra, write surface,
  device batches, trim's `baseline` — all API or freeze vocabulary, maximal
  churn for the same disambiguation.
- *Compound-protection alone via glossary senses without renames:* leaves the
  [§8.2][s8-2] numbered-tier collision and the `KindUnreadable` self-collision
  standing.
- *io set for the linearization selection:* taps is shorter and signal-native.
- *Rewriting historical log rows to the new vocabulary:* amendments annotate,
  never rewrite.

### D-123 — Add a non-normative Appendix D glossary

**Status.** ratified

**Position.** [Appendix D][sD] Glossary is non-normative with a stated precedence
rule — each entry compresses its owning section's meaning and cites it, and on
divergence the owning section wins (the walkthrough explainers' rule); 146
entries in ten subject groups, alphabetical within group, one home per term,
with "not to be confused with" clauses on genuine near-collisions
(class/tier/kind, predicate/condition, prior/baseline, cell/staging cell/store,
batch/collect, register/recorders, frame/boundary).

**Spec.** [§3][s3], [§11.1][s11-1], [§11.3][s11-3]–[§11.6][s11-6], [§8.1][s8-1], [§8.2][s8-2], [§8.6][s8-6], [§9.1][s9-1], [§13.7][s13-7], [§15.4][s15-4]–[§15.5][s15-5],
[Appendix D][sD]

**Rationale.** [§11.1][s11-1] gains the **frame** anchor — one loop iteration (drain,
integrate, boundary sequence, publication), the one central term used
throughout without a defining home, with kinematic reference frames always
compounded. Drafting doubled as an audit and closed [D-122][d-122]'s application
stragglers (component-sense "kind" residue in [§3][s3], [§11.3][s11-3]–[§11.6][s11-6], [§8.2][s8-2]/[§8.6][s8-6],
[§9.1][s9-1], [§13.7][s13-7], [§15.4][s15-4]–[§15.5][s15-5]; `KindMixed` → `ClassMixed`, completing the
diagnostic-name half).

**Rejected.**
- *A normative glossary:* every entry becomes a second source of truth to
  co-edit forever, and prose redundancy has no fails-loudly protection —
  [§8.1][s8-1]'s condition for accepting redundancy cannot hold for it.
- *Flat alphabetical ordering:* pure lookup, but the near-collision clauses
  lose their locality and the groups their teaching adjacency.
- *Defining *frame* in the glossary alone:* a non-normative entry cannot own a
  term; the [§11.1][s11-1] anchor gives it a normative home.

### D-124 — Widen §14.7's `reads` grammar to the full service selector set

**Status.** ratified

**Position.** [§14.7][s14-7]'s `reads` grammar widens to the full service set
([D-095][d-095]'s four plus [D-125][d-125]'s `get_face`) with per-selector validation targets —
`get_state`/`get_deriv` against `init_x`, `get_output` against `output_types`,
`get_slot`/`get_face` against the root face lists; the two-selector alternation
was a pre-[D-095][d-095] straggler, not policy.

**Spec.** [§14.4][s14-4], [§14.7][s14-7], [§14.8][s14-8]

**Rationale.** [§14.4][s14-4]'s source axis is restated as *table sources* (a boundary
snapshot, or the scratch tables a service evaluation instantiates, [§14.8][s14-8]) vs.
store sources — the prior "boundary snapshot" wording did not cover trim, the
axis's primary service client; [D-098][d-098]'s enforcement (snapshot-bound store
selector = attach-time `ReadBindingUnresolved`) is unchanged.

**Rejected.**
- *Keeping [§14.7][s14-7]'s two-selector grammar as a deliberate narrowing:* [D-095][d-095]
  records no such decision, and a residual pinning an authored state value or a
  solved slot has legitimate need of `get_state`/`get_slot`.
- *Leaving the source axis's snapshot wording and special-casing trim in
  prose:* the axis's own point is that source precedes client policy — an axis
  that skips its primary client is not an axis.

### D-125 — Admit `get_face` to the service `reads` set

**Status.** ratified

**Position.** `get_face` is admitted to the service set — it resolves
through export chains exactly as [§14.9][s14-9]'s mounting resolves slot faces (the read
side mirroring the write side), so an equilibrium equation crossing a generic
seam binds the curated face contract. This amends [D-095][d-095]: the four-selector set
was inherited from [D-083][d-083] and predates `get_face`'s spelling ([D-095][d-095]), so this is
completion, not reversal.

**Spec.** [§6.1][s6-1], [§7.4][s7-4], [§14.4][s14-4], [§14.7][s14-7], [§14.9][s14-9], [§16][s16]

**Rationale.** Companion idiom recorded beside [§14.7][s14-7]'s `reads` bullet: a
derivative a service must read across a contract boundary is published as an
ordinary output port computed in `h_xu` ([§7.4][s7-4] step 2's one-line binding, made
contract), `get_deriv` staying scoped to owned concrete subtrees; publication
is demand-driven — the `get_local` doctrine's sibling (the need surfaces as a
resolution error with the export remedy), not a design-time obligation on
component authors, with "equilibrium-defining states have boundary-meaningful
derivatives" the library-convention heuristic deferred to the [§16][s16] migration
outline. Grounding: the C172's engine-speed equilibrium
(`ẋ.systems.pwp.engine.ω`) is unspellable under [D-083][d-083]/[D-095][d-095] alone — every level
of the real aircraft tree is a generic seam.

**Rejected.**
- *Service deep paths past generic seams / instance-resolved `reads`:*
  dissolves [D-083][d-083]'s client split exactly where it pays: a same-path/same-type
  substitution silently changes the committed trim point — the drift `get_face`
  exists to shield; breaks [§14.9][s14-9]'s relocatability; [§6.1][s6-1] forbids the traversal
  even where the concrete instantiation would resolve it, and [D-061][d-061] fixed
  `resolve` to diagnose past-generic segments even where the instance resolves.
- *A face-level `ẋ` spelling:* reintroduces a zero-promises read at the
  face level — faces are curated contract, and `ẋ` buffers are not
  boundary-consistent ([D-098][d-098]).
- *Auto-publishing every state derivative:* contract bloat, and routes
  integrator scratch into snapshots against [D-098][d-098]'s source axis.

### D-126 — Give trim-commit events a report channel

**Status.** ratified

**Position.** Events firing at trim's boundary zero get a channel — the
`TrimReport` carries the fired set (component paths and event names) beside the
saturated-bounds list, and a non-empty set raises `TrimCommitEvents`, severity
`warning (service)`.

**Spec.** [§14.5][s14-5], [§14.8][s14-8], [§14.10][s14-10], [Appendix C][sC]

**Rationale.** A commit-fired handler moves the committed stores off the
reported solution — which `capture`-defaulted `linearize` ([§14.10][s14-10]) then reads —
and [§14.8][s14-8]'s doctrine is the elimination of warn-but-assign, so a wanted failure
signal with no channel is the same silence relocated.

**Rejected.**
- *Suppressing or rolling back commit-fired handlers:* boundary zero is an
  ordinary boundary by [§14.5][s14-5]'s design — [D-100][d-100]'s visibility philosophy: surface,
  don't special-case.
- *Failing the commit when any event fires:* some transitions at the trim point
  are benign and wanted — mode latching — and the author decides from the
  report, as with non-convergence.
- *Leaving it to the log alone:* the report is the service's contract surface,
  and unattended envelope sweeps read reports, not logs.

### D-127 — Add a deployment block to the trace header for replay validation

**Status.** ratified

**Position.** The trace header gains a **deployment block** — `t₀`, `Δt_base`,
`h`, `n`, the algorithm identifier and the effective `t_end`/`stop_on` pair,
captured with the stores. [§12.7][s12-7]'s up-front pass treats it in two ways:
`Δt_base`/`h`/`n`/algorithm compared against the target's deployment binding
(widened to six by [D-133][d-133]: `localization_tol` and `event_budget` join both the
block and the comparison), mismatch = `ReplayHeaderMismatch` with a new
deployment-parameter discriminator — structural, never a what-if, since a
deployment change moves the times at which frame-ordinal batches apply
(different inputs, not a modified model); `t₀` applied rather than compared
(replay stands in the `init!` position and owns the anchor — no new `replay!`
argument); the termination pair recorded but never constraining (overrides bind
at replay as at `run!`, [D-091][d-091]).

**Spec.** [§11.5][s11-5], [§12.7][s12-7], [§13.5][s13-5], [Appendix B][sB], [Appendix C][sC]

**Rationale.** Defined as the artifact "run metadata" already named three times
without a home ([§13.5][s13-5] ×2, [Appendix B][sB]; [D-091][d-091]'s obligation, now discharged).

**Rejected.**
- *Validating the whole block uniformly:* freezes `t_end`/`stop_on`, which
  [§12.7][s12-7] explicitly leaves overridable, and a recorded `stop_on` termination
  reproduces itself anyway.
- *An overridable deployment check to allow what-if-with-different-`h`:* not a
  what-if under [§12.7][s12-7]'s own definition — what-if replay promises the recorded
  inputs, and ordinal keying re-times them under a changed grid.
- *A separate `ReplayDeploymentMismatch` kind:* one validation pass, one
  carrier — the payload discriminator mirrors the store/slot split already
  there.

### D-128 — Define `to_boundary` as the frame-entry boundary index

**Status.** ratified

**Position.** One user-facing pointer: `to_boundary = k` is defined as running
through the frame whose execution published boundary `k`, so replay always
halts at a frame top (both [§12.7][s12-7] promises preserved — ends `initialized`, the
state `step!` leaves; exact for grid boundaries; a localized `t*` boundary is
reproduced but not stoppable-at). `StepError`'s replay pointer is respelled the
**frame-entry boundary index** — the frame-top boundary (grid or boundary zero)
at which the failing frame began — making [§13.4][s13-4]'s recipe total and exact:
`replay!(to_boundary = k)` halts precisely there, `step!` re-executes the
failing frame, localized boundaries included ("trace boundary index" deleted:
the trace is frame-indexed, the pointer is a boundary index, the merged phrase
named a nonexistent object).

**Spec.** [§10.4][s10-4], [§12.6][s12-6], [§12.7][s12-7], [§13.4][s13-4], [Appendix C][sC]

**Rationale.** The boundary counter stays the reporting index ([§10.4][s10-4]'s
counter/frame-ordinal separation intact).

**Rejected.**
- *Last-published-boundary as the cursor pointer with a `k − 1` recipe:* not
  total: two localized boundaries in one frame leave `k − 1` mid-frame, and
  through-the-frame semantics would replay into the failure itself.
- *A frame-ordinal `to_frame` keyword beside `to_boundary`:* a second
  user-facing index kind for one workflow the frame-entry pointer already
  closes.
- *Halting replay mid-frame at `t*` boundaries:* breaks [§12.6][s12-6]'s whole-frame
  `step!` invariant and the `initialized` promise's ready-to-advance half.

### D-129 — Restate the two-notation rule as directional (structure vs contract)

**Status.** ratified

**Position.** The two-notation rule is restated as directional — slash is
structure, face names are contract; the write side speaks contract exclusively
([§11.3][s11-3], unchanged), the read side speaks structure in inspection reads and
contract wherever meaning must outlive the build: integration bindings
([§11.2][s11-2]'s `get_face`, [D-095][d-095]) and service reads ([§14.4][s14-4], [D-125][d-125]).

**Spec.** [§11.2][s11-2], [§11.3][s11-3], [§8.6][s8-6], [§14.4][s14-4], [Appendix D][sD]

**Rationale.** Swept: [§8.6][s8-6]'s rule sentence, [§11.3][s11-3]'s parenthetical, [§11.2][s11-2]'s
subheading (now "snapshot bindings") and the glossary face entry — all four
predated [D-095][d-095]'s `get_face` and stated read = slash-paths-only, forbidding the
binding style [§11.2][s11-2] itself recommends.

**Rejected.**
- *Keeping the read/write phrasing with a `get_face` carve-out footnote:* the
  rule's real axis was never read vs. write — the write side's exclusivity is
  about the root contract being the only write surface, and the read side's
  freedom is client choice ([D-083][d-083]); a footnoted exception would misstate the
  principle it patches.

### D-130 — Scope `resolve`'s generic-boundary duty by client (wiring/service/inspection)

**Status.** ratified

**Position.** `resolve`/`resolve_terminal`'s generic-boundary duty is
client-scoped — [D-083][d-083]'s line carried into resolution: *wiring* (connection
declarations, Stratum A) strict as stated; *service* (condition entries, trim
`reads`, taps) strict at the authoring or mount level (the locality law is
authoring-level, [§14.2][s14-2] — absolute paths are a compiled derivative — and the
mount prefix is checked by the mount itself, [§14.9][s14-9]'s contract validation);
*inspection* (device read bindings, GUI panels, snapshot/log inspection) the
instance walk — a generic seam is no error for a client that never claimed
substitutability, drift still loud at attach (`ReadBindingUnresolved`); which
of the three a client falls under is internal, never user-facing API
([§14.4][s14-4]'s `apply!` precedent). This amends [D-061][d-061].

**Spec.** [§13.3][s13-3], [§14.2][s14-2], [§14.4][s14-4], [§14.9][s14-9]

**Rationale.** Not [D-061][d-061]'s rejected instance-only walk: the declared-type walk
stays the primitive's semantics and stays enforcing where promises depend on
it.

**Rejected.**
- *A single unconditional strict rule:* as written it made [D-083][d-083]'s blessed
  inspection reads unreachable in any real tree — the shipped XPlane
  binding, GUI panels and the log all traverse generic seams — and broke
  [§14.9][s14-9]'s mounting on compiled absolute paths.
- *A public client parameter on `resolve`:* client policy is
  framework-internal; [§14.4][s14-4] precedent.
- *Permissive resolution for service clients at the compiled path:* erases
  the locality law exactly where substitution safety pays — [D-125][d-125]'s rejected
  deep-path reads.

### D-131 — Apply the round-4 consistency sweep (findings 4–11)

**Status.** ratified

**Position.** A consistency sweep over the spec and the walkthroughs —
stragglers of the restructure and of the [D-121][d-121]/[D-122][d-122] vocabulary overhauls, one
citation retarget, one lifecycle count, and the walkthroughs' self-references;
no settled decision changes, only text brought into line with decisions already
recorded.

**Spec.** [§5.3][s5-3], [§6.2][s6-2], [§7][s7], [§7.1][s7-1], [§7.5][s7-5], [§11.4][s11-4], [§11.7][s11-7], [§12][s12], [§12.6][s12-6], [§9.5][s9-5], [§13.4][s13-4],
[§14][s14], [§14.6][s14-6], [§15.4][s15-4], [§16][s16], [Appendix B][sB], [§D.3][sD-3], [§D.6][sD-6], [§D.8][sD-8]

**Rationale.** [§16][s16]'s GUI bullet lists orphan display among the settled
semantics, not the deleted claim-transition policy ([D-047][d-047], [D-106][d-106]); [§11.7][s11-7]'s
closing constraint bakes port resolution *and* the liveness verdict at run
start, matching its own mid-text, [§15.4][s15-4] and [§D.6][sD-6]; three [D-122][d-122] stragglers renamed
([§9.5][s9-5]'s probe-derived *predicate* form, [Appendix B][sB]'s bundle footnote *function
family*, [Appendix B][sB]'s `Simulation` entry *unattended run*); two [D-121][d-121] slot
slips reworded ([§14.6][s14-6] "the one initialized datum without declared defaults",
[§11.4][s11-4]'s scatter "position → slot cell"), the claims themselves intact; chapter
9's opener roadmaps only chapter 9, leaving [§12][s12]'s own opener the sole roadmap
for chapter 10; `project`'s two schedule positions cited to [§5.3][s5-3], where the
rule actually lives, from [§7.5][s7-5], [§9.5][s9-5] and [§D.3][sD-3], with a one-clause back-reference
added at [§7.1][s7-1]'s write-back bullet; [§12.6][s12-6] says *five* states, agreeing with its
own enumeration and with [§13.4][s13-4], [§14][s14]'s legality tables and [§D.8][sD-8]; and the two
walkthroughs' six self-references, mis-resolved to unrelated spec chapters by
the phase-4 linkify pass, now point at their own headings (the stray [§6.2][s6-2],
which matches no walkthrough heading, retargeted to the walkthrough's [§6][s6], token
and target together). Tooling guard so it cannot recur: linkify.jl leaves a
bare §N in a companion alone and warns when N is one of that companion's own
section numbers — an explicit link, local or cross-file, is the resolution and
survives every later run; check_refs.jl keeps validating in-file anchors
against each file's own headings and now prints the self-vs-spec set as an
advisory.

**Rejected.**
- *Renumbering the walkthrough sections to letters or names so the linkifier
  cannot mistake them:* churns two stable explainers to patch a tool defect.
- *Auto-resolving a companion's bare §N locally:* silently wrong wherever the
  spec is meant.
- *Making the self-vs-spec case a hard checker error:*
  `event_visibility_walkthrough` legitimately cites the spec's [§7][s7] while owning
  a [§7][s7] of its own — the ambiguity is real, only the author can settle it, and
  the check would fail on correct text.
- *[§12.6][s12-6]'s "four phases, the last terminal in two flavours" grouping:*
  defensible but it re-describes what [§13.4][s13-4], [§14][s14] and [§D.8][sD-8] all count as five
  statuses.

### D-132 — Treat operator interrupt (Ctrl-C) as a control-plane stop, not a failure

**Status.** ratified

**Position.** The operator interrupt (Ctrl-C) is a control-plane stop, not a
failure. It joins `t_end`, `stop_on` and the GUI/handle/code stop among
[§12.4][s12-4](1)'s initiation sources: the run completes the current boundary,
publishes the final snapshot, takes the ordinary graceful tail and ends
`stopped` — boundary-consistent, serviceable by the [§14][s14] services, resumable by
the next `run!`.

**Spec.** [§11.6][s11-6], [§12.4][s12-4](1), [§12.4][s12-4](3), [§12.4][s12-4](5), [§13.4][s13-4], [§13.5][s13-5], [§14][s14], [§14.8][s14-8],
[Appendix C][sC]

**Rationale.** **Boundary masking is normative**, not an implementation hint:
because `InterruptException` is asynchronous, the loop masks delivery across
the boundary macro-sequence (Julia's `disable_sigint`, a sigatomic counter
increment per frame) and takes the deferred raise at the unmask points — frame
top, wait and pause blocks — all boundary-consistent; the
`stopped`-with-consistent-stores guarantee depends on it. Two discrimination
clauses fall out: [§13.4][s13-4]'s catch site never wraps an `InterruptException` in
`StepError` (routes it to the stop path; unreachable in practice under masking,
kept defensively), and [§11.6][s11-6]'s device wrapper never turns one into `DeviceCrash`
— in the spawned-loop topology Ctrl-C lands in the calling task's inline device
loop body (the GUI), which forwards the stop and exits through the ordinary
`running(handle)` predicate, no `should_abort` consultation. A **second**
interrupt during the tail collapses the remaining device joins immediately —
[§12.4][s12-4](5)'s abandonment path taken at once, devices still named — and the run
still ends `stopped`; escalation shortens the tail, never reclassifies the run,
and cannot repair [§12.4][s12-4](5)'s honest asymmetry (nothing can abandon the task
`run!` stands on). Scope is the **interactive session**: outside the REPL
Julia's default `exit_on_sigint(true)` kills the process on SIGINT first, the
framework flips nothing process-global, and unattended runs rely on
`t_end`/`stop_on` as they already must. The termination record tags the stop
source ([§13.5][s13-5]), distinguishing it from `t_end`, `stop_on` and a
programmatic/GUI stop, with no new diagnostic kind; `UnboundedRun` ([Appendix C][sC])
names it as the sanctioned escape from the configuration it warns about; and
the services need no story of their own — an interrupt during a long `trim!`
unwinds an ordinary call over per-invocation scratch stores, no commit having
happened ([§14.8][s14-8]). Precedent correction, recorded because it is easy to miscite:
FlightCore's `interrupt!` (iodevices.jl:36, its one override closing UDPInput's
socket at shutdown) is a per-device unblocking hook — the direct precedent of
[§12.4][s12-4](3)'s `unblock!`, not of this path; FlightCore has no
`InterruptException`/SIGINT handling anywhere.

**Rejected.**
- *Treating the interrupt as a runtime failure — the `StepError` path an
  unguarded Ctrl-C takes today:* destroys the session it means to pause:
  terminal `errored`, no services, no resume, and with mid-boundary delivery,
  dirty stores.
- *Pausing instead of stopping:* does not return the prompt in the synchronous
  deviceless case — the very run that has no other escape — and a paused run is
  not serviceable.
- *A public `interrupt!` entry point:* redundant: the control plane already
  carries the stop, and a function call is available to code that could have
  called `stop` anyway — the FlightCore name would also import an unrelated
  per-device meaning.
- *Process-global `exit_on_sigint(false)` set by the framework:* changing
  process-wide signal behavior behind the user's back, and wrong for the
  unattended runs that want the kill.
- *Escalation reclassifying the run as `errored`:* nothing is broken — the
  operator asked twice for the same stop.

### D-133 — Split spec-invoked numeric constants into deployment parameters vs owning-section defaults

**Status.** ratified

**Position.** The constants the spec invoked but never fixed split by whether
they move the trajectory. The two **semantic** ones become deployment
parameters — `Simulation` keywords beside `h`, `n` and the algorithm:
`localization_tol`, a *relative* bracket-width convergence test for [§10.4][s10-4]'s
root-finder (localization converges when the bracket is narrower than
`localization_tol · h`), default `1e-6`; `event_budget`, the per-frame
localization allowance, default 8 — validated with their siblings into
`DeploymentInvalid` (positive tolerance, integer budget ≥ 1) but
grid-independent, hence outside [§10.5][s10-5]'s harmonic-grid check, and **recorded** in
the trace header's deployment block, which takes replay's compared set from
four to six ([§12.7][s12-7]). The four **operational** ones get spec-fixed defaults in
their owning sections and no user knobs: shutdown join timeout 5 s ([§12.4][s12-4](5));
debt forgiveness at five frames' worth of budget, `5·h/p` ([§10.7][s10-7], replacing "a
few frames' worth"); heartbeat staleness 2 s ([§12.2][s12-2]); `margin` = 2 ms ([§10.7][s10-7]'s
own arithmetic), replacing [Appendix B][sB]'s `margin = <default>` placeholder.
[§13.2][s13-2]'s per-device warning rate limit alone is **deferred** to the
diagnostic-stream decision [closed by [D-136][d-136]: the bound is the diagnostic cell's
ring, not a constant]. Finally `t_end`'s landing rule, stated once in [§12.4][s12-4](1):
the run ends at the first grid boundary whose time reaches or exceeds `t_end` —
whole frames only, overshooting by up to `h`, with the termination record
carrying the actual final `t` ([§13.5][s13-5]). This amends [D-127][d-127].

**Spec.** [§10.4][s10-4], [§10.5][s10-5], [§10.7][s10-7], [§11.5][s11-5], [§12.2][s12-2], [§12.4][s12-4], [§12.4][s12-4](1), [§12.4][s12-4](5), [§12.6][s12-6],
[§12.7][s12-7], [§9.1][s9-1], [§13.2][s13-2], [§13.5][s13-5], [Appendix B][sB], [Appendix C][sC], [Appendix D][sD]

**Rationale.** Semantic constants: `event_budget`'s default 8 covers a
legitimate multi-event frame — three landing-gear struts touching down inside
one step — needs three or four, chattering needs tens, so 8 bounds the
pathology without ever binding on a healthy model; they are
trajectory-determining in exactly the sense `h` and the algorithm are, and
[§10.4][s10-4]'s "the run replays identically" is an empty promise unless what the
localizer was told is recorded. Operational constants: the gap was ownership,
not configurability — the shutdown join timeout is generous for GUI window
teardown and socket closes, short enough that an abandoned join reads as a
diagnosed timeout rather than a hang; debt forgiveness sits above the ms-scale
GC/scheduler hiccups debt absorbs invisibly, far below the
debugger/laptop-sleep stalls forgiveness exists for; heartbeat staleness is
deliberately loose: the heartbeat is advisory, never a kill trigger, and must
tolerate a device legitimately parked in a blocking read; `margin` = 2 ms
reflects libuv's millisecond timer granularity plus `sleep`'s ≈1.4 ms measured
median overshoot, and the section's "sleeps ~90% of a 20 ms budget"
illustration is exactly this value. `t_end`'s landing rule follows [§12.6][s12-6]'s
`t_plus` precedent ("whole frames until the boundary time first covers the
duration") applied to the run clock, and marks the point where `t_end`, a grid
fact, differs in kind from `stop_on`, checked at every published boundary, `t*`
included.

**Rejected.**
- *An absolute-in-`t` localization tolerance:* breaks scale-freedom across `h`
  — one number is slack at `h = 1` and unreachable at `h = 10⁻⁴`.
- *Leaving the two semantic constants as implementation constants:* silently
  breaks [§10.4][s10-4]'s replays-identically promise — a trajectory-determining fact
  must be deployed and recorded, not buried in the localizer.
- *User knobs for the operational four:* ownership was the gap, not
  configurability — and [§10.7][s10-7] already settled `margin` as the single pacing
  knob, so a second wall-clock knob reopens a closed decision.
- *Harmonic-grid-coupled validation for `localization_tol`/`event_budget`:*
  they are grid-independent; the coupling would be invented rather than
  derived.
- *Fixing the per-device rate limit now:* the diagnostic stream's structure
  would re-decide it.
- *A short final step landing exactly on `t_end`:* grid integrity `tₖ = t₀ +
  k·h` forbids it, [§10.4][s10-4] — the bookkeeping hazard that rule kills.
- *Ending at the last boundary before `t_end`:* contradicts the `t_plus`
  precedent: a duration is covered, not approached.

### D-134 — Declare the interactive write-surface class via a binding marker method

**Status.** ratified

**Position.** The derived write side becomes **declared**: `interactive(b)` is
an optional marker method on the *binding* — the write-surface class is a
binding fact, not a device fact — probed at attach exactly like the other sides
([§11.6][s11-6]'s method-presence idiom).

**Spec.** [§11.2][s11-2], [§11.3][s11-3], [§11.4][s11-4], [§11.6][s11-6], [§11.7][s11-7], [§12.3][s12-3], Appendices B/C/D

**Rationale.** Completes [D-044][d-044]'s partition. `interactive` defined ⇒ derived
write side: no claims staked, and [§11.4][s11-4]'s positional staging shape compiled over
the unclaimed face set instead (that compilation already existed; it now has
its declared trigger). `interactive` and `faces` are **mutually exclusive** (a
surface cannot be enumerated and derived at once — attach-time error naming
both declarations); `interactive` is orthogonal to `selectors` (an interactive
front end may also drive a compiled output gather — legal, currently
uninstantiated, the plausible customer a narrow-wire interactive surface such
as a motorized control board); "neither ⇒ error" becomes "none of the three ⇒
attach-time error". **At most one interactive device per roster**, beside the
always-present harness cell: a fourth part of the attach-time admission check,
in `needs_calling_task`'s shape and error style (`InteractiveConflict`, naming
both the rostered holder and the candidate, exactly as `CallerTaskConflict`
does) — the derived surface is shared rather than partitioned, and the
singleton keeps intra-surface drain order trivial (interactive device, then
the harness cell last). The shipped GUI binding is the class's **sole shipped
instance**, declaring `interactive` only: no `faces` (its surface is computed),
no `selectors` (its read path is the handle's primitive read — VSync-paced
`latest` per render, [§12.3][s12-3] — with an ad-hoc render-time read set over the whole
snapshot in an inspection read's shape, [§11.2][s11-2], so the compiled gather has
nothing to do for it); `gui = true` becomes "attach the standard GUI device
under the standard interactive binding iff no interactive device is already
rostered" ([D-109][d-109]'s idempotency, now stated against the class rather than the
type). Two non-reopenings are on record: [§11.6][s11-6]'s rejected `sides(b)` trait is
*not* what this marker revives — that rejection turns on redundancy with
methods that must exist anyway, and nothing analogous exists here, the derived
surface being computed, so no method's presence could witness the class and a
marker is the only possible declaration, not a second copy of a fact; and
[D-044][d-044]'s rejection of unclaimed-surface opportunism "for any device" stands
unchanged — autonomous devices still enumerate, the interactive writer stays
human-mediated, singleton-limited and staging-checked (`ClaimedFaceEntry`
untouched). The marker makes the privileged class visible and checkable, not
open.

**Rejected.**
- *`faces(b) = :derived` (a sentinel return):* i.e. a dual-meaning enumeration
  contract — exactly the ambiguity the declaration vocabulary is built to
  refuse.
- *Empty-tuple-or-`nothing`-means-derived:* silent promotion of an accidentally
  empty enumeration — `faces` bodies are ordinary code, comprehensions included
  — to the interactive writer's *maximal* write surface: the silent-widening
  class this design refuses everywhere, and the most privileged classification
  must be the hardest to enter by accident; `faces(b) = ()` keeps its honest
  meaning, an inert enumerated device whose writes are still binding-bounded by
  `OutOfClaimEntry`.
- *A shipped concrete `InteractiveBinding` type:* edges toward the abstract
  binding-type taxonomy [§11.6][s11-6] already rejected, and abandons the method-presence
  idiom the other sides use.
- *Forbidding `interactive` + `selectors`:* orthogonal machinery, and a rule
  that would have to be unmade for the first narrow-wire interactive surface.
- *Leaving the class undeclared with the GUI special-cased:* the status quo
  under review — [§11.3][s11-3]'s "the GUI is not an exception but the resident of the
  second class" stays aspirational, the class has no membership test, and a
  second interactive front end has no spelling.

### D-135 — Scope the activation cache to immutable compiled artifacts, keyed on the Build

**Status.** ratified

**Position.** Amending [D-052][d-052], the activation cache is scoped to **immutable
compiled artifacts** — layouts, compiled plans, the validated flag — keyed by
concrete scalar type and living on the **`Build`**, since an activation is a
pure function of the build and the scalar ([§9.4][s9-4]'s own words).

**Spec.** [§7.5][s7-5], [§11.1][s11-1], [§9.2][s9-2], [§9.4][s9-4], [§14.8][s14-8]

**Rationale.** **Every buffer set has exactly one owner**: the `Simulation`
owns its nominal activation's buffers, materialized from the cached layouts at
construction and what the loop's zero-allocation stepping runs on; every
service invocation owns the scratch set it instantiates from those same layouts
— [§14.8][s14-8]'s per-invocation rule promoted from a trim-local statement to the
general one, [D-070][d-070] being the decision that forced it (iterating on shared
buffers aliases the sim's authoritative stores, warn-but-assign reborn). The
envelope-grid sweep's amortization is restated honestly: what the cache saves
is probe re-runs, layout construction and Julia's compilation of the `Dual`
chain — never buffer reuse, the per-point working-store allocation being
O(model size) and trivial against the solve it feeds, and [§7.5][s7-5]'s
zero-allocation invariant being scoped to the stepping loop (the services were
always allocation-tolerant, [§14.8][s14-8]). Two consequences stated where they belong:
the `Build` is an **immutable artifact that may back any number of
`Simulation`s, concurrently** ([§9.2][s9-2] — true by construction once buffers are
single-owner, which is what [§9.2][s9-2]'s `Simulation(build::Build; …)` factorization
plus [§11.1][s11-1]'s inline-`run!` parallel sweeps were already inviting), and **lazy
materialization is torn-state-free under concurrent first requests** as a
normative guarantee, mechanism unspecified (a guard around insertion suffices,
at service time and never on the hot path; purity makes the worst benign race
duplicated work). Recommended idiom for [§11.1][s11-1]'s parallel sweeps,
recorded at both sites: pre-materialize with the existing `build(world;
activations = …)` keyword and the shared artifact is fully immutable, with no
synchronization on any path.

**Rejected.**
- *Cached shared buffers:* [D-070][d-070]'s aliasing — warn-but-assign reborn — and it
  makes the `Build` mutable in exactly the way multi-`Simulation` sharing
  forbids.
- *Per-`Simulation` activation caches:* defeats the sharing [§9.2][s9-2]'s artifact
  factorization bought: every worker re-probes and re-compiles.
- *Requiring explicit pre-materialization for any concurrent use:* turns a
  safety property into a user obligation — the guard is cheap and off the hot
  path, and a sweep that forgets the keyword would get corruption rather than a
  slower first request.

### D-136 — Unify diagnostics and liveness heartbeat into one per-writer diagnostic cell

**Status.** ratified

**Position.** Closing [D-133][d-133]'s [§13.2][s13-2] deferral, the runtime diagnostic stream and
the liveness heartbeat get one mechanism — **one per-writer diagnostic cell**,
one per rostered device plus one for the loop itself, single-writer by the same
ownership argument as [§11.4][s11-4]'s staging cells (no lock, no arbitration, no new
primitive), holding a **bounded ring of 16 diagnostic values plus per-kind
suppressed counts** and an atomic heartbeat timestamp.

**Spec.** [§7.5][s7-5], [§10.7][s10-7], [§11.1][s11-1], [§11.2][s11-2], [§11.4][s11-4], [§11.6][s11-6], [§11.8][s11-8], [§12.2][s12-2], [§12.4][s12-4], [§13.2][s13-2], [§13.5][s13-5],
Appendices C/D

**Rationale.** The bound **is** the rate limit — an emission past capacity
within a frame is not stored and its kind's count increments, earliest-in-frame
retained — which homes [§13.2][s13-2]'s "rate-limited wherever its source can repeat" as
a structural property of the channel and discharges [D-133][d-133]'s deferral with no
constant to tune. The loop takes each cell with `atomicswap` at the **frame-top
drain**, [§11.4][s11-4]'s own point, swapping in a **shared empty sentinel** so a quiet
frame allocates nothing and no load-only path goes untested; the heartbeat
rides in the same cell — stored on every loop pass from inside the handle
primitives ([§11.6][s11-6]), acquire-loaded at the drain, [§12.2][s12-2]'s 2 s staleness read
against this field, and not a diagnostic kind. The published **framework status
becomes a concrete frozen value**: per writer `recent` (this boundary's drained
ring), `suppressed` (the per-kind counts the ring refused this boundary),
`totals` (loop-owned cumulative per-writer × per-kind counters, *copied* into
each status) and `heartbeat`, beside [§10.7][s10-7]'s pacer diagnostics — [§11.2][s11-2]'s binding
rule holding **by construction**, since the swap gives the loop exclusive
ownership of the batch before publication and the live accumulator is never
reachable from a snapshot. Presentation is separated from channel policy:
renderers print a writer × kind up to **25 cumulative occurrences** and then
switch to count-only display (the `maxlog` successor), counts accumulating
regardless; and the **terminal snapshot carries the final cumulative counters**
([§12.4][s12-4](1), [§13.5][s13-5]), so an unattended run's complete diagnostic account survives
its own shutdown. The allocation story is spec-stated: a quiet frame adds
**zero heap allocation**, the per-writer status riding inline in the
per-boundary snapshot allocation [§11.2][s11-2] already accepted — which requires the
per-kind counters to be a **fixed-shape isbits record, never a `Dict`**,
licensed by [Appendix C][sC]'s closed kind set — while a noisy frame allocates its
values at emission on the writer's own task and a **fresh ring** lazily at the
writer's next emission (the drained one being frozen into a snapshot and
unwritable thereafter), the same GC-over-reuse trade [§11.2][s11-2] made when it rejected
preallocated snapshot buffers; worst case per writer per boundary is therefore
one ring of 16, everything past it an integer increment, and [§7.5][s7-5]'s scoped
model-sweep zero-allocation invariant is untouched. Composition note, recorded
once: `totals` is monotone across logged snapshots, so `log_every` decimation
loses *which* boundary in a skipped stretch an occurrence fell on, never *how
many*.

**Rejected.**
- *A shared queue or buffer under a lock:* cross-task contention on the loop's
  own frame path and no single-writer ownership to reason from — the arbitrary
  shared mutable state [§11.1][s11-1]'s two rules exist to eliminate, reintroduced for
  the one structure that had escaped specification.
- *A status referencing the live accumulator:* the cheapest thing to write and
  a direct violation of [§11.2][s11-2]'s binding rule — a reader walking a structure its
  writer is still mutating.
- *Ring reuse by double-buffering:* reintroduces exactly the reader-liveness
  proof the GC provides for free — [§11.2][s11-2]'s own argument against preallocated
  snapshot buffers — to save an allocation incurred only on frames already
  doing something unusual.
- *Unbounded accumulation:* an unattended run with no status reader grows
  without bound, precisely the configuration the framework must survive, and a
  bound is what gives the drop policy a definition.
- *A separate heartbeat channel or liveness registry:* a second cross-task
  structure with the same writers, the same ownership question and the same
  drain point, for one timestamp.
- *A per-device rate-limit constant, [D-133][d-133]'s deferred option:* the structure
  carrying the stream already bounds it — a tunable would name a policy the
  channel cannot violate anyway.
- *A render threshold baked into the channel:* what is recorded must not depend
  on who is looking; 25 is a renderer's number.

### D-137 — Bound snapshot-log retention by count, with amortized doubling stride

**Status.** ratified

**Position.** Snapshot-log retention gets a **bound**, `log_max` — the maximum
number of retained snapshot references, a new `Simulation` keyword beside
`log`/`log_every`.

**Spec.** [§4.1][s4-1], [§4.4][s4-4], [§7.5][s7-5], [§10.7][s10-7], [§11.2][s11-2], [§11.5][s11-5], [§11.8][s11-8], [§12.4][s12-4], [§12.7][s12-7], [§13.5][s13-5],
Appendices B/D

**Rationale.** **A count, not a memory budget**: snapshots are immutable object
graphs with internal sharing ([§4.1][s4-1], and [§4.4][s4-4] field handles riding as references
to build-time-frozen data, [§7.5][s7-5]), so byte accounting over them is fuzzy and
platform-dependent, while a count is exact and converts to memory through one
number the user measures once (`Base.summarysize` of a single snapshot).
**Default 65536 (2¹⁶), finite unconditionally**, with `Inf` the explicit
opt-out — no modal rule keyed on `t_end`; a finite run shorter than the bound
never notices it, and at 50 Hz full density 2¹⁶ boundaries is ≈22 minutes
before the first drop. **When the log fills, the effective retention stride
doubles** — `log_every · 2^k` after k generations — so the bound holds while
coverage stays **global**: the whole run remains plottable at coarsening
density, which is [D-038][d-038]'s division of labor carried through (the log's chief
consumer is the post-run plot of a session as a whole; full density over any
*segment* of interest is what replay from the trace recovers, [§11.5][s11-5], [§12.7][s12-7]). The
licence is [D-038][d-038]'s own asymmetry, a fortiori: a thinned log costs resolution in
a *view*, never a record, whereas [D-029][d-029]'s refusal to thin the trace stands
untouched. Following [D-135][d-135]'s precedent, **the guarantees are normative and the
mechanism a sketch**: normatively the retained count never exceeds `log_max`,
coverage is global at the effective stride, and the endpoints are kept; the
sketch is that the thinning is **amortized** — the stride doubles immediately
and each subsequent retained append also releases one predecessor of the
previous generation (a cursor over the odd indices, O(1) amortized, physical
compaction once per generation), the generation's thinning completing exactly
when its refill does. Amortization is a responsiveness choice: a one-shot
halving would make ~`log_max/2` *old-generation* snapshots unreachable at a
stroke, a major-GC burst worth a pacer-absorbed, `DebtReanchor`-visible hiccup
([§10.7][s10-7]) — exponentially rare, the wall-clock gap between generations doubling,
but needless — while the amortized form drops exactly one old snapshot per
retained append, the steady trickle a rolling window would produce anyway; the
loop's own work is pointer bookkeeping, microseconds either way and on the
framework side of [§7.5][s7-5]'s scope, publication staying wait-free with readers
never blocking. **The boundary-zero ([§14.5][s14-5]) and terminal ([§12.4][s12-4](1), [§13.5][s13-5])
snapshots are retained unconditionally under any `log_every` and any `log_max`,
and do not count against the bound** — two extra references — so the run's
endpoints and, via the terminal status's final cumulative counters ([§11.8][s11-8],
[D-136][d-136]), its complete diagnostic account always survive. Compositions stated
once: `totals` monotonicity across logged snapshots ([§11.8][s11-8]) is unaffected,
re-decimation losing *which* boundary in a stretch an occurrence fell on and
never *how many*; and `log_max` is a **view policy, not
trajectory-determining** — outside the trace header's deployment block, neither
recorded nor compared by replay ([D-127][d-127], [D-133][d-133]'s compared set untouched). [§7.5][s7-5]'s
`sizehint!` for the expected duration is reconciled: now capped by `log_max`,
which is also what defines the hint when `t_end = Inf`. No new diagnostic kind
— hitting the bound is stated policy, not an event to report.

**Rejected.**
- *A rolling window:* optimizes recent-past-at-full-density, which replay
  already serves, at the cost of the whole-run overview replay is expensive for
  — and it buys no responsiveness either, its steady-state drop rate being
  exactly the amortized form's.
- *A memory-based bound in bytes:* false precision over shared immutable graphs
  — the number would be platform-dependent and unauditable, where a count is
  exact and one measurement converts it.
- *A modal default, finite only when `t_end = Inf`:* a modal rule where one
  unconditional number suffices, and the finite-`t_end` run it exempts is the
  one that never reaches the bound anyway.
- *An unbounded default, the status quo under review:* gigabytes per hour at
  C172X scale and 50 Hz in the configuration [Appendix B][sB] calls the honest
  interactive default, ending in an OOM no diagnostic mentions.
- *One-shot halving as the normative mechanism:* an old-generation major-GC
  burst once per generation — pacer-absorbed and rare, but needless when
  amortization achieves the rolling window's trickle profile at the same
  asymptotic cost.
- *A diagnostic kind for reaching the bound:* a policy operating exactly as
  configured is not a warning, and the log's density is visible in the log
  itself.

### D-138 — Make device `init!` an explicit, bracketed step of the run-start protocol

**Status.** ratified

**Position.** Device `init!` becomes an **explicit step of the [§12.4][s12-4] protocol**,
taken at the top of a run — once per roster entry, in attachment order, on the
calling task, pre-spawn — with **each call in its own bracket**: on a throw the
framework calls `shutdown!(dev)` on the failing device right there, reports
`DeviceCrash` by name and marks it dead, no task being spawned.

**Spec.** [§11.1][s11-1], [§11.3][s11-3], [§11.6][s11-6], [§11.8][s11-8], [§12.2][s12-2], [§12.4][s12-4], [§13.5][s13-5], [§14][s14], [§14.6][s14-6], Appendices
A/B/C/D

**Rationale.** Release is therefore **unconditional**, which is what makes
[§11.6][s11-6]'s "guaranteed on every exit path" and [§12.4][s12-4]'s "`shutdown!` has released
each device's OS resources" true of the one path outside the wrapper, and it
carries a **new taught obligation** ([§11.6][s11-6], [Appendix A][sA]): `shutdown!` must
tolerate a **partially initialized** device — "close only what is open" — the
same defensiveness the crash path already demands. **No new diagnostic kind**:
`DeviceCrash`'s payload (device id, `cause`, whether `should_abort` was set)
already fits an init-time failure, [Appendix C][sC]'s gloss merely naming the site. A
failed device is **dead from boundary zero** with no dead-marking machinery of
its own — it never stores a heartbeat timestamp, so its cell reads stale
against [§12.2][s12-2]'s threshold from the first frame ([§11.8][s11-8], [D-136][d-136]) — and its **claims
persist to run end**: [§11.3][s11-3]'s death-is-not-detach disposition applied one step
earlier than [§12.4][s12-4](6)'s, the orphaned slots holding their initial values,
well-defined by [§14.6][s14-6]'s slot totality where a (6) orphan holds a last drained
batch. **Run disposition splits on `should_abort`, uniformly with (6)**: clear
(the default) the remaining entries initialize, the run starts and the sim runs
with the device absent from frame zero — (6)'s semantics shifted to `t₀`; set,
the failure requests a control-plane stop that is **already pending at boundary
zero**, so the run reuses [§13.5][s13-5]'s existing terminal-at-`t₀` path — remaining
entries still initialize, every rostered device getting its `init!`/`shutdown!`
pair uniformly, boundary zero is published, the run ends `stopped` at `t₀`
through the ordinary [§12.4][s12-4] tail and the termination record names the source.
**Topology is derived after initialization** ([§11.1][s11-1]): a failed
`needs_calling_task` holder returns the loop to the calling task rather than
parking it on a device that will not exist. Finally `should_abort` gets the
**declaration site** it never had: an **`attach!` keyword, default `false`** —
matching (6)'s narrative default ("the sim continues with the device absent"; a
dead joystick must not kill a session) — with the **shipped GUI attaching
`should_abort = true`** (closing the window is the interactive session's
natural end) and `gui = true`'s standard attachment stating that value
([Appendix B][sB], [D-134][d-134]'s sugar unchanged); [Appendix D][sD] gains the glossary entry.

**Rejected.**
- *Requiring `init!` to clean up after itself on failure:* an unenforced burden
  duplicated in every device, and unenforceable in exactly the half-built cases
  that matter — the bracket does it once, for all of them.
- *Short-circuit teardown on an aborting init failure, ending the run without
  publishing:* invents a second exit path beside [§12.4][s12-4]'s one tail and yields a
  `stopped` sim with no terminal snapshot — unserviceable by [§14][s14], with nothing
  for the log's unconditionally-retained endpoints to retain.
- *A dedicated init-failure diagnostic kind:* `DeviceCrash`'s payload and
  disposition already fit, and [Appendix C][sC]'s closed set pays for every addition.
- *Topology frozen from the roster before initialization, the status quo:*
  parks the loop on a spawned task and the calling task on a loop body for a
  device that does not exist.
- *`should_abort` defaulting to `true`:* a dead peripheral kills a session —
  the opposite of [§12.4][s12-4](6)'s stated intent.
- *Declaring `should_abort` in the device authoring contract as a fifth
  function or a trait:* it is an *attachment* fact — the same device is
  advisory in one deployment and relied on in another, and the contract is
  the place where per-deployment policy least belongs.
- *Leaving initialization failure at "reported by name through (6)'s crash
  path":* the clause under review — (6) is written about a task that has
  already spawned, so it answers none of release, disposition or topology.

### D-139 — Give environment field handles a value-level constructor to prevent drift

**Status.** ratified

**Position.** Environment field handles get a **value-level constructor** — the
map (component, input values) → handle exposed as a plain, pure, exported
function (`atmospheric_field(atm; T_sl, p_sl, wind)` for the `SimpleAtmosphere`
successor), with the component's swept output stage a **one-line call to it and
never the reverse** — stated in [§4.4][s4-4] as a **shipped component's obligation**
([Appendix A][sA] taught contract, [Appendix D][sD] entry), because only the component's
author can write it: the real component composes sub-models, and anyone else
reconstructing the map has re-created the silent-drift class [§5.3][s5-3] exists to
kill.

**Spec.** [§4.4][s4-4], [§5.3][s5-3], [§9.6][s9-6], [§14.1][s14-1], [§14.2][s14-2], [§14.7][s14-7], [§14.9][s14-9], [§16][s16], Appendices A/D

**Rationale.** Bulk-data components owe only that the query math be *reachable*
as a plain function; building a handle outside a build may then cost a resource
load, acceptable because condition authoring is design-time code. [§14.1][s14-1]'s
**caller-computable escape is extended to cover environment queries**: a
condition needing one constructs the sweep's exact handle from the same values
its `baseline` writes into the environment component's slots — or, in a rig
where the handle *is* a root slot value, simply holds the value it wrote there
— and calls the same query function the consuming component calls; one
implementation of the field math evaluated one level up, no pre-sweep and no
new mechanism. [§14.1][s14-1] also records the **environment-free fallback** through the
existing second escape: promote the eliminated state coordinates to decision
variables and enforce the targets as residuals on swept outputs, which needs no
environment access at condition time at all (the detailed
elimination-vs-enlargement material stays out of the spec — companion
walkthrough, then [§16][s16]). **Trim problems never author the environment** ([§14.7][s14-7],
[§14.9][s14-9]): handles arrive through the user parameter record, the problem
*receiving* the environment and never writing it, which is what keeps **one
problem artifact valid across a full world and a thin rig** — a condition entry
naming a wired input fails resolution by name, correctly ([§14.9][s14-9]), so a problem
that wrote an environment face would apply only to rigs where that face happens
to be unconnected. [§14.9][s14-9]'s "the aircraft is never literally the root" is
**softened from doctrine to default**: leaving an environment face unconnected
is legal by construction — the face becomes an ordinary root slot holding the
handle *value*, written by the `baseline` like any other slot, the **test-rig
idiom** and the function-valued sibling of a constant source — while
`design_world(ac)` remains the shipped rig for design tasks, keeping the
environment's tunables in the slot vocabulary that conditions, `capture`,
linearization's input surface and the trace header already speak. [§9.6][s9-6]'s
"`Kinematics.Initializer` … survives untouched, aircraft-side" is
**corrected**: it survives aircraft-side with its `atmosphere::Model` argument
respelled as a field handle (built at value level per [§4.4][s4-4], or held as a rig
slot value). Recorded once, the orthogonal **2×2** the discussion established:
*elimination vs. enlargement* (where target enforcement lives — closed-form in
the condition math, or as residuals on swept outputs) × *component-produced vs.
slot-held environment* (who owns the handle in the rig). Only the first axis
decides whether a **second handle path exists at all**: under elimination the
condition-side copy is **solution-defining** and must agree with the world's,
whereas under enlargement a handle can at most inform the initial guess —
convergence-relevant, solution-irrelevant. The second axis is a rig-shape
choice and never touches trim doctrine. **Residual risk, mitigation deferred to
[§16][s16]'s migration outline**: under elimination a params-vs-world handle mismatch
converges to a *true* equilibrium at an *unintended operating point* — the
eliminated targets are never residual-checked, so nothing complains — and a
cheap post-commit read-back of EAS/γ/β against the requested targets catches
the whole class.

**Rejected.**
- *Widening the condition signature to `condition(d, baseline)` so the math
  reads the handle out of the baseline:* single-sources the handle in a rig,
  but is **rig-only** — in a full world the environment face is wired and
  absent from the baseline, and serving it there would mean pre-sweeping the
  environment subtree; it also makes every problem's meaning depend on the
  baseline it is applied against — the hidden-input shape [§14.1][s14-1]'s overlay-base
  decision kills, reintroduced one level up — and it breaks the pure condition
  algebra that makes [§14.9][s14-9]'s `at`-lifting five lines.
- *A pre-application or partial sweep making swept outputs readable at
  condition time:* reaffirms [§14.2][s14-2]'s by-name rejection of init as a third
  scheduled sweep, and deciding which subtree is state-independent and
  therefore safe to pre-sweep is graph reasoning the services deliberately do
  not do.
- *Mandating enlargement as the sole route:* discards closed-form knowledge the
  aircraft author has — the aero validity envelope is a box in (TAS, α, β) and
  nothing like a box in Cartesian `v_eb_n`, so bounds either clip the feasible
  set or admit excursions into table extrapolation, the practical source of
  failed trims — where elimination keeps today's proven 7×7 shape.
- *Reading the environment through `reads`:* circular — reads are gathered
  after the sweep the condition precedes.
- *Duplicating the atmosphere's `h_xu` in aircraft trim code:* the drift class
  itself.

Stated to forestall the reading: none of this reopens [D-008][d-008]'s rejected resource
injection — no registry, no invisible composition, just a plain function call
on values the caller already holds.

### D-140 — Add a three-rung remedy ladder for artificial algebraic-loop dependencies

**Status.** ratified

**Position.** [§5.4][s5-4]'s escape hatch becomes a **three-rung remedy ladder** for
artificial loops; [§8.3][s8-3] and [§4.3][s4-3] are unchanged.

**Spec.** [§4.3][s4-3], [§5.4][s5-4], [§5.6][s5-6], [§8.3][s8-3], [§16][s16]

**Rationale.** (i) The **two-stage split** dissolves most of the class —
[§15.1][s15-1]'s `VehicleDynamics` instance is the canonical dissolution. (ii)
**Contract re-factoring**, the new middle rung: when [§5.6][s5-6]'s tracer says
*artificial*, re-examine the cycle's wires before moving any code, because an
input the neighbor consumes **only in a fallback branch** is the archetypal
false dependency — the neighbor is computing, on the component's behalf, a
fallback whose semantics belong on the component's own side of the boundary;
move the branch to its natural owner and the wire disappears. Canonical
instance, taken from the shipped code the finding walked
(`landinggear.jl:255-323`, `:63-72`): `Strut` hands the contact-velocity
azimuth `ψ_v` to the steering model and consumes the returned `ψ_sw` throughout
the contact-frame construction, but `ψ_v` is used *only* in the steering's
disengaged (castoring) branch, and castoring is free-swiveling wheel physics —
the strut's business, not the steering law's; re-factoring `AbstractSteering`
to emit `(engaged, ψ_cmd)` and computing `ψ_sw = engaged ? ψ_cmd : ψ_v` inside
`Strut` deletes the backward wire, and the factoring **survives substitution**
— a stateful steering actuator produces `ψ_cmd` from its own state and still
needs nothing from the strut — which is the test that it records structure
rather than dodging the diagnostic. (iii) **Splitting the component** stays the
residual remedy, for cycles whose halves genuinely belong to one component, and
its cost is now **stated where it bites**: [§8.3][s8-3]'s visibility is binary, so
every intermediate shared across the new boundary becomes `output_types` —
public, connectable, substitution-relevant. The cap is [§4.3][s4-3]'s granularity
guideline, which the split case satisfies trivially (one producing stage, one
consumer): **one struct-valued bundle port** (a `StrutGeometry`-shaped value),
not N loose ports — the bundle type becomes contract, a real cost but a bounded
and honest one. [§5.6][s5-6]'s hint offers **both exits** ("split this component, or
narrow the neighbor's contract"), continuous members only as before, and the
classifier machinery is untouched: it already knows which hop died. [§5.4][s5-4]'s
"rare" is thereby **earned** rather than asserted — the split is rare *because*
rungs (i) and (ii) absorb the common shapes. [§16][s16] records the strut/steering
pair as the contract-re-factoring worked instance, beside [§15.1][s15-1]'s dissolving
`VehicleDynamics`, with the split and its bundle port noted as the residual
remedy not taken; the `AbstractSteering` contract change is an
**aircraft-library migration call living in [§16][s16]**, not framework vocabulary.

**Rejected.**
- *A visibility level for split-orphaned intermediates (`unlisted`,
  `Private(T)`):* an explicit non-reopening of [D-034][d-034] and [D-055][d-055] — the promotion
  cost is real but bounded, and the bundle port keeps it to one name, whereas a
  hiding annotation would buy back that name at the price of "public always
  means someone wrote it down".
- *Leaving [§5.4][s5-4] split-only:* the first real migration instance shows the
  diagnostic steering the author toward mid-computation surgery on seven shared
  intermediates (`l`, `r_bs_b`, `q_bs`, `ks_e`, `v_ec_b_body`, `ξ`, terrain
  data) when deleting one false wire was the answer — and the "rare" claim is
  only true with the ladder in place.
- *Framework-side auto-splitting or auto-narrowing:* the classifier's trace
  speaks only for the branch taken at the probe point ([D-012][d-012]'s diagnostic-only
  doctrine), so remedy selection is the author's — and both [§5.4][s5-4] remedies
  document real structure precisely because a human chose them.

### D-141 — Continuous state resets are events, owned by the reimplemented PIVector

**Status.** ratified

**Position.** A continuous component's state reset is an event — a new Appendix
A entry, with the tier asymmetry now taught as a contract: the same-tick reset
entry is marked explicitly discrete-tier, and [§15.2][s15-2]'s gear sentence is extended
to say why. [§3.1][s3-1], [§2.1][s2-1] and [§13.7][s13-7] are unchanged. Even a commanded continuous
reset — the condition arriving as an ordinary `Bool` input, weight-on-wheels
being the shipped instance — is spelled as an event whose guard reads that
input; the discrete tier's input answer does not transfer. Ownership settles on
the reimplemented `PIVector`, which gains a flag-gated reset face: `PIVector(;
reset = true)` adds a `Bool` input face plus the event, the default omits both,
under one fixed policy — rising edge → reset to the declared `init_x` values,
implemented internally as an ordinary guard/handler event (the [Appendix A][sA]
contract's worked instance). The gear wires `strut.wow → frc.reset` (the
touchdown edge).

**Spec.** [§2.1][s2-1], [§3.1][s3-1], [§3.3][s3-3], [§10.6][s10-6], [§8.5][s8-5], [§13.7][s13-7], [§15.2][s15-2], [§16][s16], [Appendix A][sA]

**Rationale.** The reason is semantic, not stylistic: only the discrete tier's
update stage is already a jump map (a reset there is merely another value for
`z⁺`), whereas a continuous state jump must be solver-visible and land between
integration segments — the invariant every hybrid tool enforces (Simulink
zero-crossing plus solver restart, Modelica `reinit` legal only inside `when`,
SUNDIALS stop-and-`ReInit`, DiffEq.jl callbacks), which is also why [§3.1][s3-1]'s
immutable stage views are enforcement of mathematics rather than a
discretionary restriction. No stale-output hazard rides along: [§10.6][s10-6] re-sweeps
outputs to quiescence after handlers, so a continuous edge-reset is
same-boundary by construction. The structural argument is that events are
leaf-owned — a handler resets its own `x`, and assemblies have no events — so
the state's owner is the reset's only possible home, and a cross-component
reset becomes a wired guard input to it. The demand test: genre precedent
counts as demand for a domain block's feature set (external-reset ports on
integrator and PID blocks are standard vocabulary — Simulink, PLC PIDs) even at
a single migration consumer, which is how [§13.7][s13-7]'s grow-by-migration-demand rule
reads past a literal one-consumer count. `strut.wow → frc.reset` gives fresh
regulator state per contact episode, boundary-detected (the regulator's input
ramps from zero at touchdown) and harmless at boundary zero for a sim
initialized on ground. `PistonEngine`'s two `PIVector` instances (`idle`,
`frc`) are verified reset-free in today's code (`piston.jl:295-449`: `f_ode!`
runs both in every engine state, `f_step!` does mode transitions only,
`f_init!` sets gains; windup across unused phases is already handled by the
saturation bounds and `int_halted`) and migrate untouched with the flag off,
their `f_init!` gain writes becoming construction-time parameters ([D-089][d-089]). The
PI law is shared as plain pure functions called by the block's stages ([D-139][d-139]'s
laws-as-plain-functions pattern), and `sat_ext` poses the same
always-on-vs-flag-gated face question, decided at reimplementation time on the
same axis. Recorded as general doctrine, the graduation rule: a wrapper's
pattern moves into the library at the second same-semantics demand.

**Rejected.**
- *Superseded position — a gear-owned `FrictionRegulator` leaf wrapping the PI
  law:* it buys a duplicated component whose only job is to keep the library
  block reset-free; leaf ownership already cuts toward the block, since the
  wrapper would have to own the state to own the event, and genre precedent
  supplies the demand a one-consumer count seemed to withhold.
- *An always-on reset face:* taxes every non-user — the engine's two instances
  first — with wire-false ceremony, or leaves an unwired `Bool` face that
  becomes a root slot the frozen roster, the trace header and every condition
  baseline must then speak about.
- *Simulink's full policy menu (rising/falling/either/level triggers plus an
  external-IC port):* one policy suffices, with [§13.7][s13-7]'s Bool gates covering
  falling-edge consumers and separate blocks covering level-pinning and
  reset-to-an-external-value, which is tracking — each extra option is contract
  surface every reader of the block carries forever.
- *The liftoff edge (`!wow`):* behaviorally closest to today's level reset, but
  equivalent only because `Strut`'s no-contact branch returns `v_ec_xy = [0,0]`
  and the integrator leaks — component A's reset correctness resting on
  component B's default branch, precisely the cross-component dependency the
  touchdown edge dissolves rather than documents.
- *Relaxing [§3.1][s3-1]'s immutable views* so stage methods could write `x`: forbidden
  by ODE-solver mathematics, not by taste — trial-point stage evaluations,
  error control and dense-output interpolants all presume in-segment
  continuity, and mid-segment mutation corrupts all three.
- *An assembly wrapping a `PIVector` child and resetting it externally:*
  structurally impossible — events are leaf-owned and an assembly has no
  dynamics of its own, [§3.3][s3-3].

**Divergence.** Simulink exposes this as a checkbox; the framework's flag-gated
reset face is "the honest version" — declarations are ordinary functions of the
instance ([§8.5][s8-5]), not an opaque toggle.

### D-142 — Stage code must be total over type-valid inputs

**Status.** ratified

**Position.** Stage code acquires a taught totality contract: stage code must
be total over type-valid inputs — every probed user function (stages, `f`, `g`,
guards, handlers, `project`) must evaluate without throwing on any input
satisfying its declared types. The domain is deliberately type-validity, not
the probe's synthesized domain: the branch-shape rule already bans
value-dependent return types, so type-validity is the only domain the framework
can speak of, and probe-scoped phrasing would make the probe the reason rather
than the enforcement moment, inviting the "can I detect that I am being
probed?" escape. Two enforcement moments, one throw: at build, a value-level
throw is a `UserCodeFraming`-wrapped build failure ([§13.1][s13-1]'s fail-fast user-code
population) whose diagnostic points at code that is "correct" on every
trajectory it has ever run; at runtime the identical throw is a `StepError` and
the run ends `errored` ([§13.4][s13-4]) — [§13.5][s13-5] already rules that exceptions from model
code are always abnormal, so no new failure mode is introduced, only a stated
obligation. Parameter validation is not banned but mislocated: it belongs where
user-controlled data enters — the constructors of parameter and instance
values, which run pre-build, where asserts are perfectly legitimate — never in
a constructor invoked inside a stage on probe-fed data.

**Spec.** [§9.3][s9-3], [§13.1][s13-1], [§13.4][s13-4], [§13.5][s13-5], [Appendix A][sA]

**Rationale.** [§13.1][s13-1], [§13.4][s13-4] and [§13.5][s13-5] are otherwise unchanged by this finding.
Three patterns in shipped `landinggear.jl`, all walked by the dry run, get
three distinct dispositions: (i) plausibility termination — `GroundCrash`
thrown on `α_ts`/`ξ_dot` thresholds (`:330-346`) — migrates to a published
`Bool` output face plus `stop_on`, [§13.5][s13-5]'s existing machinery, so [§9.3][s9-3] only
cross-references it; (ii) numerical self-consistency asserts — `@assert
abs(v_ec_c[3]) < 1e-8` (`:320`), the author checking their own damper-rate
cancellation algebra — is a regression test living in stage code, and its
legitimate home is the test suite; it is also the most probe-fragile of the
three, since a near-degenerate synthesized geometry (`ks_c[3]` → 0) keeps the
cancellation algebraically exact while still missing an absolute tolerance in
floating point; (iii) defensive exhaustiveness — `error("Unrecognized surface
type")` (`:191`) and the `@assert μ_s >= μ_d` / `@assert v_s < v_d`
`FrictionCoefficients` constructor asserts (`:163-167`), that constructor being
invoked per step inside stage code (`:427-428`) — where totality over a closed
enum means handling every instance, an `else error(...)` being an admission
that the function is partial. The statement lands as one [§9.3][s9-3] paragraph,
written as the dual of "physically silly values are acceptable by construction"
(they are acceptable because the author is obliged to accept them), plus one
[Appendix A][sA] recall line. [D-050][d-050]'s probe-everything scope stays unnarrowed by this
finding.

**Rejected.**
- *Probe-time exception downgrading (catch user-code throws while probing and
  warn):* it hides genuine bugs behind a warning, only defers the identical
  throw to the first real step as a `StepError`, and breaks [§13.1][s13-1]'s clean
  two-population split — declarative checks collect, user-code evaluation fails
  fast.
- *An author-visible "probing" context flag:* a stage able to ask whether it is
  being probed makes probe coverage vacuous on exactly the paths that opt out
  of it, and reintroduces context-dependent behavior into stages the design
  elsewhere keeps pure.
- *Doing nothing beyond [§13.5][s13-5]'s termination mapping:* it covers the termination
  half and covers it well, but leaves the non-terminating assert classes —
  self-consistency and exhaustiveness — with no stated rule at all, which is
  precisely the migration-day trap the dry run hit: an assertion harmless for
  years becomes a build failure with the diagnostic pointing at correct code.
- *Superseded position — phrasing the contract as totality over the probe's
  synthesized domain (the finding's own initial proposal):* it promotes the
  probe from enforcement moment to justification, and a rule scoped to the
  probe invites authors to reason about escaping the probe instead of about
  their function's declared domain.
- *Narrowing [D-050][d-050]'s probe-everything scope to spare the offending functions:*
  that coverage is the build-time earliness the probe exists to buy — what was
  missing was the contract, not less scope.

### D-143 — Add a `Constant` source block for zero-contributor aggregates

**Status.** ratified

**Position.** The component library gains a source block, `Constant{V}`, and
[§6.2][s6-2] gains the spelling for a zero-contributor aggregate. Contract: an ordinary
component, no framework privileges, no inputs, no state,
`output_types(::Constant{V}) = (out = V,)` with the value type from the type
parameter and the value itself held by the instance, and a stage-1 body
returning it; `Constant(Wrench()) → dynamics/wr_ext` is the whole remedy. Two
clarifications ride with it: (i) this is not [§6.1][s6-1]'s banned default in component
clothing but its opposite — the banned default is silent and consumer-declared,
the `Constant` is loud and assembly-declared, the author writing both the child
and the wire, both inspectable structure; (ii) the value is instance data, not
an overridable default — like junction arity it is baked into the instance, and
a configuration wanting an externally settable source uses a root slot ([§11.3][s11-3]),
the boundary that keeps the block from drifting into a back-door input default.
Tier: stateless continuous, so [§13.7][s13-7]'s existing tier-transparency argument (a
stateless `h_xu` recomputes every sweep, so fed ZOH-held signals its output
changes only at ticks) already covers discrete consumers — no discrete variant.

**Spec.** [§6.1][s6-1], [§6.2][s6-2], [§11.3][s11-3], [§13.7][s13-7], [Appendix D][sD]

**Rationale.** [D-037][d-037]'s retirement and [§6.1][s6-1]'s ban are preserved, not reopened,
by this decision. The gap the dry run walked: `Vehicle{NoVehicleSystems}`
(`aircraftbase.jl:27-35`) contributes zero to both external wrench and internal
angular momentum while `VehicleDynamics` requires both inputs unconditionally,
[§6.1][s6-1] forbids unconnected inputs and silent defaults, a zero-arity `SumJunction`
would need the identity element [D-037][d-037] retired on purpose, and the library had
no block that produces without consuming — so the bare-propagation
configuration (`test_dynamics.jl`, any kinematics-only world) had no legal
spelling at all. The argument is visible structure: the zero total becomes a
declared wire and an observable port — the configuration stating "external
wrench ≡ 0" out loud — instead of FlightCore's silent identity methods, whose
zero-edit convenience is the hazard ([D-037][d-037]'s own words). It also subsumes the
rig stub: [D-120][d-120]'s concrete `SampleTerrainField` provider wired to an abstract
`terrain` face is typically just a `Constant` holding the test handle — the
block's first shipped instance — while bespoke stubs stay ordinary components
wherever the double must compute something. Admission honors [§13.7][s13-7]'s strictly
from demonstrated need charter: the dry run demonstrated the need twice, at the
zero-contributor totals and at the rig. [Appendix D][sD] gains a constant source
entry.

**Rejected.**
- *A zero-arity summing junction with an identity element:* [D-037][d-037]'s retirement
  stands — reintroducing identity machinery for the degenerate case buys
  nothing the source block does not, and reopens the canonical-fold and
  identity-element rules retired wholesale.
- *Consumer-side optional inputs or unwired defaults:* [§6.1][s6-1]'s ban — the silence
  is the hazard, the same property [D-037][d-037] rejected in the tree walk.
- *A configuration-aware `VehicleDynamics` branching on whether contributors
  exist:* pushes configuration structure into component code, where no diagram,
  printer or diagnostic can see it, and makes a component's contract depend on
  the assembly it sits in.
- *Bespoke per-configuration stub components as the general answer:* legal, and
  still the answer for computing stubs, but boilerplate at every
  zero-contributor site — `Constant` subsumes the constant-valued case, which
  is all of them.

### D-144 — Rename the computed-exports helper `faces` to `passthrough`

**Status.** ratified

**Position.** The computed-exports helper is renamed `faces` → `passthrough`;
keyword arguments (`prefix`, `sep`, `except`, `only`) and semantics are
unchanged. [§11.6][s11-6]'s `faces(b)` claim-set declaration is deliberately untouched:
the rename dissolves the overload rather than propagating it, leaving the
device-binding declaration sole owner of the name. The rename is the first
application of the four-class naming convention now recorded as [§16][s16]'s
API-audit criterion: (1) declarations (author defines, framework calls) are
bare nouns or `init_*`/`_types` — `connections`, `exports`, `events`,
`input_types`, `output_types`, `local_types`, `init_x`/`init_z`/`init_m`,
`workspace`, `probe_value`, the stages `h_x`/`h_xu`/`h_z`/`h_zu`, `f`, `g`,
`project`, and `faces(b)`; (2) value selectors called against `reads` and
snapshots carry `get_` — `get_state`, `get_deriv`, `get_output`, `get_local`,
`get_slot`, `get_face` ([§14.4][s14-4]); (3) lifecycle and mutating actions are verbs,
`!` when they mutate — `build`, `run!`, `step!`, `replay!`, `init!`, `attach!`,
`detach!`, `shutdown!`, `apply!`; (4) build primitives ([§13.3][s13-3],
framework/tooling-facing) are plain verbs — `resolve`, `resolve_terminal`. A
name in the wrong class is a rename candidate on that ground alone. Two
residuals are flagged and deferred to the [§16][s16] audit, not renamed now:
`input_faces`/`output_faces` (noun accessors punning on the `_types`
declarations, mitigated by being framework-facing rather than daily authoring
surface) and `workspace` (a declaration whose bare noun reads as an accessor —
borderline, every rename candidate clunkier, lean keep).

**Spec.** [§11.6][s11-6], [§8.6][s8-6], [§8.8][s8-8], [§9.1][s9-1], [§13.3][s13-3], [§13.7][s13-7], [§14.4][s14-4], [§15.4][s15-4], [§16][s16], Appendix
B (swept)

**Rationale.** Two ambiguity axes motivated it: the helper wore the declaration
class — a bare noun like `connections`, `exports`, `events`, `input_types`,
`workspace`, things an author defines and never calls — while actually being a
helper the author calls inside an `exports` body; and it collided with
`get_face`, the value selector, so "faces" named both a selection of values and
a generation of export pairs. `passthrough` names the helper's purpose in
[§8.8][s8-8]'s own words ("the helper exists for the pass-through case, where an
assembly hands a child's unfed requirements up one level"), reads as an
operation rather than a declaration, and stays accurate if [§8.8][s8-8]'s guarded
output-direction addition ever lands.

**Rejected.**
- *`get_children_faces`:* `get_` is reserved for value selectors, so the name
  would deepen the `get_face` collision it is meant to fix; the plural also
  misstates the signature — the helper takes exactly one child — and what it
  returns is labeled export pairs, not faces.
- *`reexport`:* false — a leaf's input faces were declared, never previously
  exported, so there is nothing to re-export — the word would only be honest
  for the assembly-child case.
- *`child_faces`:* fixes plurality alone, keeping both ambiguity axes — still a
  bare noun in the declaration class, still colliding with `get_face`.
- *Renaming `input_faces`/`output_faces` or `workspace` in the same pass:*
  audit-time calls whose cost lands when the real export surface exists;
  deciding them now would settle by anticipation what [§16][s16] exists to settle
  against the migrated code.

### D-145 — Deduplicate pass-through `except` lists with a shared feed-list idiom

**Status.** ratified

**Position.** Pass-through exports duplicate the wiring list at every generic
seam — every level of the real tree is a generic seam, so each pilot- and
environment-facing input surfaces through four `exports` declarations
(`Systems` → `Vehicle` → `Aircraft` → `SimpleWorld`), and because `passthrough`
is inputs-only and re-exporting a fed face is a two-producers error, each call
carries an `except` tuple restating by name the wire list in the same
assembly's `connections`. No new vocabulary and no framework change: [§8.8][s8-8]
gains a worked shared-feed-list idiom beside the two-entry-`except` `World`
example — the author writes one constant, the feed list mapping the actuator
child's output faces to destination child faces, and both declarations compute
their share of it (`connections` maps the list into wires; each `passthrough`
call takes its `except` set from a small `fed_faces(feeds, child)` projection),
[§8.5][s8-5]'s blessing of declaration bodies as ordinary code doing the work.

**Spec.** [§8.1][s8-1], [§8.4][s8-4], [§8.5][s8-5], [§8.8][s8-8], [§14.6][s14-6]

**Rationale.** [D-043][d-043] is reaffirmed, not reopened, by this finding, which closes
the round-4 dry-run report. The drift is caught loudly — the design working —
but the duplication is [§8.1][s8-1]'s and [D-039][d-039]'s "structure kept in two artifacts"
(~10 names at `Systems`, everything `c172.jl:697-713`'s `assign!` writes).
Doctrine recorded with it: adding a channel is one edit (the pair
simultaneously creates the wire and removes the face from the export surface),
the two declarations cannot drift because neither holds the shared names — the
drift class is removed, not merely detected — and every existing error stays
loud (a misspelled destination is an unknown-face error with the child's face
list in hand, whether the wire or the `except` entry meets it first); one
honest asymmetry: a pair omitted from the list is not an error but a legible
structural change — the face joins the export surface, ultimately a root slot
for conditions to cover ([§14.6][s14-6]) — what the idiom preserves and the rejected
helper surrenders is that the feed statement exists to be reviewed, an omission
being legible in one authored artifact rather than defined away as the
complement of the wire list. The gap being closed was pedagogical, not
semantic: the section's only example hand-wrote a two-entry `except`, reading
as though the duplication stays small, when at C172X scale it is four
hand-synchronized name lists.

**Rejected.**
- *A framework helper deriving `except` from `connections`* (`except = fed(s,
  "aero")` reading the assembly's own wire list): auto-bubbling on [D-043][d-043]'s
  exact ground — the author's explicit statement of which faces are fed
  disappears, so a forgotten wire stops being a build-time unconnected-input
  error and becomes a silent promotion of that face to a live root slot, caught
  at best later as an `UninitializedSlots` deployment error of misleading
  shape, at worst not at all once a GUI or condition writes it — [§8.4][s8-4]'s
  walkthrough 2 inverted; the single source must be authored data, never
  inferred structure.
- *Wildcard-export vocabulary:* [D-043][d-043] stands — ordinary code suffices, and this
  row is the demonstration that was missing.
- *Doing nothing:* the status quo prices the idiom's absence at four
  hand-synchronized lists per generic seam chain, a measured migration-day cost
  rather than a hypothetical one.

### D-146 — Rename `faces`/`selectors` to `claims`/`reads` on the binding interface

**Status.** ratified

**Position.** Binding-interface enumeration renames: `faces(b)` → `claims(b)`
and `selectors(b)` → `reads(b)`; signatures, semantics and
detection-by-method-presence unchanged. Rows ≤ [D-145][d-145] are historical and stay
unamended. `claims(b)`: what the declaration does is stake the claim set ([§11.3][s11-3])
— the enumerated faces become the device's claimed write surface — so the name
plugs straight into [§11.3][s11-3]'s central claim vocabulary (claim set, claim
partition, `ClaimedFaceEntry`, claims orphaned to run end) and retires the last
method-name use of the spec's most polysemous noun, "face" ([D-144][d-144] dissolved the
other one, leaving this the sole survivor). `reads(b)`: the declaration
establishes the binding's declared read set — a tuple of [§14.4][s14-4] selectors,
validated at attach and compiled to one per-boundary gather whose labeled
NamedTuple `map_output` receives — and [§14.7][s14-7]'s `TrimProblem` already carries
that exact concept under that exact name, with the identical declared-set →
validated-at-mount → compiled → materialized lifecycle (its `reads` field
resurfacing as the `reads` argument of `residuals(reads, d)`): same concept,
same name. The interface thereby gains a clean sim-centric write/read pair,
`claims(b)`/`reads(b)`, sitting over the existing sim-centric
`map_input`/`map_output` pair. Scope fence: the vocabulary "selector(s)" is
untouched wherever it names the `get_*` values or their families (table
selectors, store selectors, path selectors, [§14.10][s14-10]'s tap selectors, "[§14.4][s14-4]
selectors"); only the binding method renames, and `reads(b)` still returns
[§14.4][s14-4] selectors.

**Spec.** [§11.3][s11-3], [§11.6][s11-6], [§14.4][s14-4], [§14.7][s14-7], [§14.10][s14-10], [§16][s16], [Appendix B][sB], [Appendix C][sC],
[Appendix D][sD] (swept)

**Rationale.** This is the first application of [D-144][d-144]'s four-class
convention on its semantic axis: both names sat in the right class —
bare-noun declarations the author defines and the framework calls — but were
content-named where the spec's own `exports` precedent is consequence-named,
naming the role the declaration plays rather than the material it returns. The
side-detection prose improves in the same stroke: "`claims` defined ⇒
enumerated write side, claims staked". The client difference (trim's `reads`
service, a device read binding inspection) is no obstacle — [D-130][d-130] made the
client an internal framework fact, never user-facing API.

**Rejected.**
- *Keeping `selectors(b)`:* defensible status quo — content-accurate and
  unambiguous — but it names the material rather than the role, and forgoes the
  [§14.7][s14-7] unification a shared `reads` buys.
- *`taps(b)`:* spoken for by [§14.10][s14-10]'s linearization vocabulary — the
  `x`/`u`/`y` tap sets — so importing it here would manufacture the very
  polysemy this rename retires.
- *`gather(b)`:* names the compiled artifact, not the declaration — the gather
  is what the framework builds from the declared read set, and a declaration
  named after its downstream product is the class error one level over.
- *Direction words such as `outputs(b)`:* invite the writer/reader direction
  confusion `selectors` was originally chosen to avoid — a device's "output" is
  the sim's input.
- *Renaming the selector vocabulary itself instead of the method:* it names the
  `get_*` values, which is precisely what it is good at — the ambiguity was
  only ever in the method name.

### D-147 — Split the sweep into static interior and boundary variants

**Status.** ratified

**Position.** The sweep is two statically distinct variants compiled from one
entry list, because discreteness is a build-time fact and the split by
discreteness is therefore static rather than a runtime gate. The interior sweep
walks continuous entries only and is what RK stage evaluations and localization
guard probes run, so the mid-step ZOH holds by construction ([D-019][d-019]'s ZOH
semantics reaffirmed) — discrete entries are not gated out at runtime, they are
absent from the walk at compile time, and the hottest path in the framework
carries no gating test at all. The boundary sweep walks the full list, with
discrete entries gated by counter modulo against the boundary's tick index —
the pre-existing [§10.5][s10-5] mechanism, now explicitly scoped to boundaries, the only
place anything discrete ever happens ([§10.6][s10-6]'s macro-sequence is its sole
caller). Both blocks split identically: discrete `h_z` entries are as absent
from the interior `h_x` walk as discrete `h_zu` entries are from the interior
`h_xu` walk. Phase-body surface, amending [D-116][d-116]: the two sweep bodies gain an
arity distinction — zero-arg `sweep_hx()`/`sweep_hxu()` are the interior
variants, which is what makes `@ballocated(sweep_hxu()) == 0` a well-defined
measurement of the interior path rather than of whichever tick phase the
simulation happens to be sitting in, while `sweep_hx(tick)`/`sweep_hxu(tick)`
are the boundary variants gating by modulo against the passed index, symmetric
with `ticks(tick)`; `rhs` is unchanged, and each arity is asserted in its own
right at the CI seam. The due set is a property of the boundary, computed once
and reused by every re-sweep of its quiescence iteration (a due component is at
its tick instant for the whole boundary, not for one round of it): the
counter-modulo image of the frame index at a frame top, empty at `t*` — the
tick counter has not advanced there, so no component is at a tick instant and a
naive modulo test against the unadvanced index would wrongly re-admit the
previous frame's due set — and everything at boundary zero, which is [§14.5][s14-5]'s
existing rule (`t₀` is a grid point of every divisor, and no earlier tick
exists for a ZOH to hold) rather than a new one.

**Spec.** [§5.3][s5-3], [§10.3][s10-3], [§10.4][s10-4], [§10.5][s10-5], [§10.6][s10-6], [§9.7][s9-7], [§14.5][s14-5], [Appendix D][sD]

**Rationale.** The split also recovers an implicit commitment: [§9.7][s9-7]'s
recompilation-granularity sentence — editing a discrete component invalidates
the boundary body, not the RHS body — is true only under a two-body split, and
was quietly falsified by the single-mechanism reading.

**Rejected.**
- *Superseded position — counter-modulo gating as the sole mechanism (the prior
  single-mechanism reading, and the finding):* at divisor 1 — the common `n = K
  = 1` configuration — the test admits every discrete entry at every
  evaluation, so an `h_zu` re-runs against interpolated `u` at each interior RK
  stage and at every localization probe, and the `f` reading its cell
  integrates a continuously re-sampled controller — precisely the un-sampling
  [§10.5][s10-5]'s own rejected alternative names, and undiagnosable: such a run is as
  type-stable, allocation-free and bit-reproducible against itself as the
  correct one, so a C172X at `h = 0.02, n = 1` under a 50 Hz FCS simply flies a
  different trajectory with nothing anywhere to flag it.
- *A single parameterized body taking a sentinel "no ticks due" index* on
  mid-step calls: identical semantics, rejected on three counts — it pays a
  dead runtime test per discrete entry in the framework's hottest path, where
  the static split pays nothing at all; it puts discrete entries back into the
  RHS-side body, falsifying [§9.7][s9-7]'s recompilation-granularity claim; and it
  conflates two execution contexts inside one measured body, so `@ballocated`
  at the seam measures whichever context the sentinel selects and the
  zero-allocation canary loses its per-path meaning.
- *Reading the tick index out of simulation state inside an unparameterized
  `sweep_hxu()`:* [D-116][d-116]'s surface read literally — the accessor can then no
  longer express "the interior variant", and the measurement silently depends
  on the tick phase the simulation happens to be paused at.

### D-148 — Select converters per leaf by resolved condition-shape type

**Status.** ratified

**Position.** The condition plan's baked converter is selected **per leaf,
keyed by that leaf's type in the resolved condition shape**. Two cases: (i) a
leaf **already at the activation's scalar type** is decision-descended and
takes the type's ordinary `convert`/constructor methods *at that eltype* (an
authored `RQuat` of `Dual`s → the `SVector{4}` state leaf at `Dual`), partials
crossing the write boundary untouched — the trim case, since under a
`Dual`-seeded evaluation of a type-stable `trim_condition(d)` every
decision-dependent leaf is `Dual`-typed in the shape ([§14.7][s14-7]), which is what
makes the seeded decisions reach the sweep at all; (ii) a plain **`Float64`
leaf against a non-nominal activation's scratch** is a held constant and takes
the `Float64 → Dual` zero-partial embedding, whose "held at the operating point
*is* zero partials" justification thereby sits exactly and only on the leaves
where it is true.

**Spec.** [§9.5][s9-5], [§14.3][s14-3], [§14.4][s14-4], [§14.7][s14-7], [§14.10][s14-10]

**Rationale.** A round-5 kernel dry-run finding (finding 2; [§14.10][s14-10] unchanged),
reaffirming [D-066][d-066]'s resolution-time bake with its selection rule refined. Leaf
types are **shape facts** — [§14.4][s14-4] already fixes that the tree type carries the
full nesting, every field name *and every leaf type* — so per-leaf selection
consults no runtime fact whatsoever and stays a one-time resolution-time bake,
[D-066][d-066]'s timing exactly. **No new machinery, no new user surface**: under the
seeded evaluation the type system itself classifies decision-descended against
held leaves, so the author writes the same `trim_condition(d)` and the
framework reads the classification off the shape it already compiles against.
**[§14.10][s14-10] needs no amendment** — a linearization operating-point condition is
authored decision-free, so all its leaves are `Float64`-typed and case (ii)
reproduces its behavior by construction — and the surrounding commitments are
intact: [§9.5][s9-5]'s nominal exact-match doctrine for table cells is untouched (at
the nominal activation the activation scalar *is* `Float64`, so case (i) is the
ordinary conversion), and converters still run only on the write paths, never
on state views.

**Rejected.**
- *A uniform zero-partial embedding for every non-nominal condition write:* the
  prior literal reading of [§14.3][s14-3], and the finding — trim's decision-descended
  leaves arrive at the write boundary already carrying live partials, so the
  strict spelling — a `Float64`-only converter method — raises a `MethodError`
  from inside the baked plan naming no authored line, while the natural robust
  spelling `Dual(value(v), zero(P))` accepts them and strips exactly the
  partials the solve exists to compute, leaving `J ≡ 0` structurally: the
  damping loop stalls, LM *honestly* reports non-convergence on a perfectly
  well-posed problem, `trim!` correctly refuses to commit, and every health
  signal is green (type-stable, zero-alloc, conformance check passing,
  provenance clean) with no diagnostic anywhere pointing at the converter —
  after which the derivative-free fallback backend "fixes" the symptom and
  entrenches the defect permanently.
- *Per-write runtime convert decisions:* [D-066][d-066]'s rejected alternative, still
  rejected, and the refinement strengthens the rejection rather than reopening
  it — selection needs no runtime fact at all, the leaf type being a property
  of the very shape the plan is compiled against, so a runtime decision buys
  nothing and costs the unrolled zero-alloc store.
- *Explicit user marking of decision-dependent leaves:* a per-leaf annotation,
  or a second "held"/"seeded" condition vocabulary — redundant with what the
  seeded eltype already proves, and a second source of truth free to drift from
  the actual dataflow — an annotation reading "held" on a leaf the decisions do
  descend into restores the silent zero-Jacobian bug with paperwork on top of
  it.

### D-149 — Check slot totality wherever a virgin world is established

**Status.** ratified

**Position.** **Slot totality is checked at every application that establishes
a complete world over virgin stores — `init!`, trim setup, trim commit** — one
class, one mechanism, one `UninitializedSlots` kind, collected and
declaration-ordered; the governing principle replaces the enumeration.

**Spec.** [§11.3][s11-3], [§9.3][s9-3], [§14.6][s14-6], [§14.8][s14-8], [Appendix B][sB], [§D.8][sD-8]

**Rationale.** A round-5 kernel dry-run finding (finding 4; [§11.3][s11-3], [§9.3][s9-3],
[Appendix B][sB] and [§D.8][sD-8] swept), amending [D-068][d-068]'s two-site placement. Coverage is a
**plan-level fact** — the check compares the resolved plan's slot coverage
against the `Build`'s `input_faces`, both resolution-time data — so the setup
check costs one comparison and runs *before the first evaluation*, not merely
before a write. [§14.8][s14-8]'s raw scratch instantiation is thereby sound **because**
of the check: setup's checked totality guarantees every slot written before any
read. And since commit applies the same composite over the same `baseline` as
setup (`override(baseline, condition(d*))`, coverage identical), commit's
totality check is structurally unfailable *through the trim path* — it remains
as the shared `init!`-boundary defense, no `TrimReport` committed flag exists
or is needed, and [§14.8][s14-8]'s no-throw doctrine holds without exception. [§14.6][s14-6]'s
no-third-branch ban on `probe_value` is untouched.

**Rejected.**
- *`probe_value`-filling the scratch slots:* the [§14.6][s14-6] ban stands — it would
  silently manufacture a world instead of diagnosing the incomplete one — a
  fabricated zero is a fine probe input and a terrible flight condition.
- *Trusting the `baseline`, per the prior literal text:* the finding's
  divergence — an entire solve against undefined inputs — for a `Bool` slot an
  undefined byte, UB rather than a wrong value — with the `UninitializedSlots`
  diagnostic arriving only at commit, after the expensive part is sunk, and a
  converged-but-uncommittable solve left with no reporting channel.
- *A `committed` flag on `TrimReport` carrying commit-time totality failure:*
  treats the symptom, institutionalizes discarding converged work against the
  no-throw doctrine's own grain, and is dead surface once setup's check makes
  the failure unreachable.

### D-150 — Make the service the sole authority on convergence

**Status.** ratified

**Position.** **The convergence verdict is the service's, uniformly and
backend-independently** — `converged ⟺ all(abs.(rᵢ) .≤ tolᵢ)`, [§14.7][s14-7]'s
per-residual box test in its own physical units, evaluated **by the service at
the backend's returned point** (one residual evaluation, noise against the
solve). That verdict, and nothing else, gates the commit and fills
`TrimReport.converged`; the backend's returned `status` is demoted to recorded
diagnostic data alongside the iteration/evaluation counts, authoritative over
nothing.

**Spec.** [§14.7][s14-7], [§14.8][s14-8], [Appendix B][sB]

**Rationale.** A round-5 kernel dry-run finding (finding 6), extending — not
amending — [D-069][d-069]'s service-side squaring. **The tolerance translation into each
backend's stopping language is the service's too**, per backend family: under
Levenberg–Marquardt the tolerances feed the per-residual test directly; for the
derivative-free scalar fallback the service squares *and normalizes*,
minimizing $\sum_i (r_i/\mathit{tol}_i)^2$ at `stopval = 1` — dimensionless in
place of FlightCore's hand-scaled absolute threshold, and a well-scaled valley
where a raw $|r|^2$ sums forces against moments. **Soundness (inscribed
sphere)**: $\sum_i (r_i/\mathit{tol}_i)^2 \le 1$ implies every
$(r_i/\mathit{tol}_i)^2 \le 1$, so the `stopval` sphere sits inside the
tolerance box and a fallback stopping at `stopval` necessarily passes the
service's box test — the two criteria cannot disagree in the dangerous
direction, and the converse disagreement (a backend stopping early with an
optimistic status) is caught by the re-check, which remains the single
authority. Not claimed: point identity — different backends may still land on
different solutions, an algorithmic difference and a legitimate one; what is
eliminated is per-backend *meanings* of `converged`.

**Rejected.**
- *Backend-owned verdict:* the prior literal reading of the seam sentence,
  which handed tolerances and verdict alike across it, and the finding —
  `converged` then means whatever each backend's status means, the
  derivative-free path inheriting exactly the hand-scaled absolute `stopval`
  [§14.7][s14-7] itself criticizes FlightCore for, and the finding's divergence follows
  — the same problem with the same guess commits under one backend and not
  under another, with `TrimReport.converged` carrying two different meanings
  and the commit gate riding on which keyword the caller passed.
- *Tolerance translation without a service re-check:* fold the tolerances into
  the objective and still trust the returned status — fixes the fallback's
  scaling but leaves the verdict per-backend and the sphere-vs-box relationship
  unstated, so a backend that stops early and claims success reaches the commit
  unchecked — the normalization is the translation, not the guarantee.

### D-151 — Canonicalize NamedTuple field order at every author↔framework seam

**Status.** ratified

**Position.** **At every author↔framework `NamedTuple` seam the names are the
pairing and field order carries no semantics**. Three canonical orders, each
the *declared* side's: `guess`'s field order for decisions/bounds (and it is
the solver-vector packing order, so "packed by field order" survives, now
well-defined), `tolerances`' for residuals (the residual return canonicalized
to it before packing), `Expected`'s derived order for stage returns — demoted
to an internal fact the author never reproduces. At each seam the framework
canonicalizes by a **type-level reorder** (`NamedTuple{canonical_names}(y)`), a
compile-time permutation of an already-typed value that SROA folds away exactly
where the existing test folds — so [§9.5][s9-5] keeps one whole-type `isa` (never
per-field checks) and [§7.5][s7-5]'s canary verifies the fold empirically.

**Spec.** [§7.5][s7-5], [§9.5][s9-5], [§14.7][s14-7], [§14.8][s14-8], Appendices B/C/D (as touched)

**Rationale.** A round-5 kernel dry-run finding (findings 7 and 8): [D-053][d-053]'s
fold economics preserved, [D-118][d-118]'s setup placement kept and its key-set check
completed. The errors are unchanged and are the real ones: key-set mismatches
and per-field type mismatches, `ConformanceFailure`'s diff and
`TrimProblemInvalid`'s payload as they stand; trim-side checks stay at setup,
conformance stays always-on at the table-write point. A permutation is a
non-event.

**Rejected.**
- *Key-set check plus positional packing:* the prior reading, and finding 7 — a
  permuted `lower` passes the check and applies α's bound to `throttle` — the
  solve searches the wrong box, the report names the wrong variable saturated,
  and the failure is indistinguishable from bad physics; the residual/tolerance
  pair carries the same hazard one step further from the author, its key order
  chosen inside a lambda.
- *Strict identical-`NamedTuple`-type matching with a "same keys, different
  order" directive diagnostic:* sound, but the merge-collision-intolerance
  analogy fails — a merge collision is genuinely ambiguous — two writers, one
  leaf — while a permutation has exactly one sound interpretation, so
  strictness rejects unambiguous input and forces authors to reproduce a
  derived order no single declaration shows them — finding 8's divergence — for
  zero soundness gain, downstream consumption being name-keyed throughout.
- *Per-field checks:* [D-053][d-053]'s rejection stands — canonicalize-then-single-test
  keeps the fold that per-field checking would spend.

### D-152 — Join auto-publication to the per-event re-decode at stage 1

**Status.** superseded → [D-154][d-154]

**Position.** **Auto-publication joins the per-event re-decode at its stage-1
position** — the sequence is `handler → project → auto-publish → h_x → h_xu`,
the framework rewriting the firing component's auto-published cells from the
just-latched state stores, so a later handler of the same component reads `y`
coherent with the live `x`/`m`.

**Spec.** [§5.3][s5-3], [§10.6][s10-6], [§9.5][s9-5]

**Rationale.** A round-5 kernel dry-run finding (finding 5), amending [D-016][d-016].
Auto-published cells belong to no stage ([§9.5][s9-5]), so [D-016][d-016]'s stages-only
spelling left them stale between same-component events (a second handler
reading its own auto-published mode/state port — the Engine's `ω`, the LQR's
`sat_out_0` — would latch a pre-transition value silently, the next round's
re-sweep repairing the cell but not the latched value).

**Rejected.**
- *Stage-products-only handler-phase `y` with the hole documented:* preserves
  [D-016][d-016]'s letter but silently abandons the `y = h(x)` coherence invariant that
  motivates live `y` in the first place, precisely for the mode- and
  state-publishing components most likely to carry multiple events.

### D-153 — Add re-arm tracking to complete the once-per-event rule

**Status.** ratified

**Position.** **The event phase's per-event loop state is named and normative —
the prior ([D-082][d-082]), a `fired` flag (the once-per-event rule's register), and a
within-boundary `re-arm` flag**, set when a round observes the event fired and
its guard not-holding; `EventDeferred` emits (at most once per event per
boundary) when a round observes fired ∧ re-armed ∧ holding — the genuine
intra-boundary falling-then-rising edge, never the blessed sticky case
(fired-and-keeps-holding warns nothing).

**Spec.** [§10.6][s10-6], [§11.7][s11-7], [§11.8][s11-8], [Appendix C][sC]

**Rationale.** A round-5 kernel dry-run finding (finding 9), completing [D-082][d-082]'s
prior rule. **A deferred event's quiescence prior is recorded not-holding**
(the intra-boundary re-arm edge survives the boundary), so it genuinely fires
at the next boundary — under the bare prior rule the quiescent holding sample
would swallow the edge and the promised "waits one step" would never resolve.
All three registers are detection bookkeeping in loop state — not `z`, not
captured, reset by warm restart ([D-082][d-082]'s doctrine extended); cost budgeted
explicitly: two `Bool`s per event beyond the prior.

**Rejected.**
- *The warn-on-holding-after-fired rule:* the only one implementable from the
  spec's stated registers — false-positives on every sticky flag, a
  per-boundary warning stream consuming the 16-entry ring [§11.8][s11-8] budgets for real
  diagnostics — the anti-diagnostic pattern [§11.7][s11-7] names.
- *Dropping `EventDeferred`:* silent deferral, against the
  flag-the-granularity-cost doctrine the once-per-event rule was adopted with.
- *Prior = final quiescent sample unconditionally:* [D-082][d-082] as written — swallows
  the re-arm edge, so the deferral never resolves and "waits one step" is
  false.

### D-154 — Remove per-event re-decode; serialize same-component events

**Status.** ratified

**Position.** **The per-event re-decode is removed — the signal table is
written only by sweeps — and a component fires at most one event per round**,
declaration order picking among its simultaneously-eligible events (guards stay
evaluated every round for [D-153][d-153]'s samples; the firing step is what's capped;
once-per-event-per-boundary and the quiescence iteration unchanged, so
multi-event components keep full within-boundary expressiveness, serialized
across rounds). The single epoch rule follows: **a handler executes against
exactly the world its guard fired on** — own `y`, foreign `u` and own `x`/`m`
are all the firing round's sweep, so `y = h(x)` holds at every handler entry
(f.5's incoherence dissolved by deletion where [D-152][d-152] dissolved it by addition),
a blocked event is re-decided next round against the post-transition sweep
(fire-on-falsified-premise gone), and cross-component handler order is
unobservable with no delivering mechanism (nothing writes mid-round).

**Spec.** [§5.3][s5-3], [§10.6][s10-6]

**Rationale.** A round-5 kernel dry-run finding (finding 10), resolved by
redesign after re-examining the within-round visibility rule it implements —
supersedes [D-016][d-016]'s per-event re-decode, its [D-152][d-152] auto-publish amendment, and
[D-100][d-100]'s pre-materialization mechanism ([D-100][d-100]'s round-start-`u` *semantics*
survives, now by construction). The natural single-pass executor is correct:
f.10's staging pass, carrier and `u`/`y` split are mooted and "no shadow table,
no allocation" becomes trivially true; cost = one extra intra-boundary sweep
per serialized same-component event, rare and microseconds.

**Rejected.**
- *Per-event re-decode + frozen `u`:* [D-016][d-016]/[D-100][d-100]/[D-152][d-152] as landed — two
  freshness classes needed [D-152][d-152]'s repair, and delivery needed f.10's two-pass
  staging with `Union{Nothing,·}` carrier slots — standing machinery buying
  only same-round multi-handler own-`y` freshness, which serialization provides
  free.
- *Retained guard-gathers as the carrier:* this round's interim proposal —
  sound, union-free, but dominated once serialization removes the need to
  freeze at all.
- *Live-table reads under canonical order:* [§10.6][s10-6]'s standing rejection —
  executor order becomes semantics.
- *Handlers stripped of own `y`:* the `h_x`-no-`u` move — makes the incoherence
  unwritable but keeps the two-epoch bundle and fire-on-falsified-premise, and
  forfeits the coherent own-`y` serialization provides free.

### D-155 — Name projection as the second legitimate mover of the committed point

**Status.** ratified

**Position.** **Projection is named the second legitimate mover of the
committed point** — boundary zero's first act makes the committed `x`
`project(x*)`, not `x*` (a quaternion normalized by ulps), alongside the
already-channeled commit-fired handlers — and the `TrimReport` carries both
residual sets: the solved-point residuals ([D-150][d-150]'s verdict numbers, unchanged,
gating the commit) and the **committed-state residuals, re-gathered from the
boundary-zero world** (nearly free — boundary zero's sweep has already run —
and they describe the state the simulation is actually in, the point
`capture`-defaulted `linearize` reads); a converged solve whose committed-state
residuals violate the box test raises the new service warning
`TrimCommitResiduals` ([Appendix C][sC]: offending residual names, committed values,
tolerances) — flag-when-it-occurs applied to the moved point.

**Spec.** [§14.5][s14-5], [§14.8][s14-8], [Appendix C][sC]

**Rationale.** A round-5 kernel dry-run finding (finding 11), upholding
[D-149][d-149]/[D-150][d-150].

**Rejected.**
- *Reporting the solver's last evaluation only:* residuals belonging to a state
  the simulation is not in; an out-of-tolerance commit invisible.
- *Refusing or reverting the commit on post-commit violation:* the movers are
  legitimate semantics — projection is ulps, events already flagged via
  `TrimCommitEvents` — and refusal re-institutionalizes discarding converged
  work against [D-149][d-149]'s grain.

### D-156 — Legalize the three degenerate trim/integration shapes

**Status.** ratified

**Position.** **The three degenerate shapes are decided, all in favor of
legality.** Zero decision variables: `TrimProblem(guess = (;))` bypasses the
solver — no packing, no seeded activation, no backend call — the service
evaluates the residuals once at the baseline and [D-150][d-150]'s box test decides
`converged` and the commit as usual: the "is this operating point an
equilibrium?" probe, useful in its own right. Empty continuous block: integrate
degenerates to advancing `t` to the next boundary — **the stepper seam is never
invoked with a zero-length buffer**, no backend faces N = 0, completing [§10.1][s10-1]'s
removal of the dummy-`[0.0]` tax structurally. Empty phase bodies:
**`phase_bodies` always returns the fixed four-body roster**, missing phases
compiled to no-ops whose `@ballocated` assertions pass vacuously — consumers
iterate uniformly.

**Spec.** [§10.1][s10-1], [§10.2][s10-2], [§9.7][s9-7], [§14.8][s14-8]

**Rationale.** A round-5 kernel dry-run finding (finding 12).

**Rejected.**
- *`TrimProblemInvalid` on an empty guess:* the shape check written without
  thinking; forfeits the baseline-equilibrium probe.
- *Requiring stepper backends to accept zero-length state:* pushes the corner
  into every backend's contract for zero gain.
- *Omitting empty bodies from the roster:* every consumer grows an existence
  check, and the uniform-iteration idiom breaks.

### D-157 — Check for nonfinite `x` immediately after integrate

**Status.** ratified

**Position.** **The nonfinite-`x` check is the boundary's first act —
immediately after integrate, before `project` and the boundary sweep** — so a
diverged component is named by `NonfiniteState` before its NaN reaches an
innocent downstream component and surfaces as a lookup-table `DomainError`
([§8.4][s8-4]'s error-locality inversion, otherwise reintroduced at runtime); **`ẋ`
does not participate, with the reason stated**: any nonfinite `ẋ` contaminates
the same state block's step result within that very step, so the `x` check at
the next boundary is the same detection with identical component attribution,
and `ẋ` buffers are integrator scratch, not boundary-consistent ([D-098][d-098]'s
source axis).

**Spec.** [§8.4][s8-4], [§13.4][s13-4]

**Rationale.** A round-5 kernel dry-run finding (finding 13).

**Rejected.**
- *Checking after the event phase or after `g`:* sweep and guards run on the
  NaN state first — the locality inversion the check exists to prevent.
- *Adding an `ẋ` sweep:* redundant by the contamination argument, and it would
  bless reading integrator scratch against [D-098][d-098]'s source axis.

### D-158 — Pin the backend seam to one required `solve` signature

**Status.** ratified

**Position.** **The backend seam is a pinned signature, not prose** — one
required method, `solve(backend, eval!, d0, lower, upper, tol) -> (; d, status,
nevals, niters)`: `eval!(r, J, d)` in-place, always filling `r` (packed in
`tolerances`' field order), filling `J` iff `J !== nothing`
(request-by-argument — a Jacobian-free backend always passes `nothing`);
`d0`/`lower`/`upper` packed in `guess`'s field order with ±Inf = unbounded;
`tol` in `tolerances`' order, data a backend may stop on ([D-150][d-150]'s per-backend
translation), decisive of nothing; `status::Symbol` a deliberately **open** set
recorded verbatim ([D-150][d-150] demoted status to diagnostic — a closed enum would
launder foreign solver vocabularies back into per-backend meaning);
`nevals`/`niters` diagnostic counts; the name `solve` rides the [§16][s16] naming
audit like all API spellings.

**Spec.** [§14.8][s14-8], [§16][s16]

**Rationale.** A round-5 kernel dry-run finding (finding 14), making [D-118][d-118]'s
one-implementation-target real and upholding [D-150][d-150]/[D-151][d-151].

**Rejected.**
- *Closure-style `d -> (r, J)` returns:* allocates every iteration.
- *Jacobian via a second method or a boolean flag:* doubles [D-118][d-118]'s single
  implementation target, or turns one call shape into two.
- *Bounds as a vector of tuples:* both shipped backend families take two
  vectors.
- *A closed status enum:* re-imports the per-backend `converged` meanings [D-150][d-150]
  removed.

### D-159 — Define `warning (service)` as a sixth severity

**Status.** ratified

**Position.** **`warning (service)` defined as a sixth severity** — raised by a
stopped-sim service call that completed, emitted at the call site beside the
returned value through the standard logging backend, never thrown, part of no
collection, unlimited because each kind fires at most once per call, payload
drawn from the report the call returns; [§13.2][s13-2]'s two-stream partition stands — a
service warning is not a stream but a synchronous per-call annotation.

**Spec.** [§13.2][s13-2], [Appendix C][sC]

**Rationale.** A round-5 landing-audit finding (finding 1), completing
[D-126][d-126]/[D-155][d-155] and superseding [D-092][d-092]'s five-value count to six.

**Rejected.**
- *Demoting `TrimCommitEvents`/`TrimCommitResiduals` to report-only data:*
  silently reverses [D-126][d-126]/[D-155][d-155]'s made-visible-rather-than-silent doctrine and
  removes the kinds acceptance tests match on.
- *Folding under `service`:* every `service` kind throws, singly or collected —
  these must not.

### D-160 — Rename `report` to `report!`

**Status.** ratified

**Position.** **`report` renamed `report!`** — it writes device-attributed
runtime warnings into the device's diagnostic cell ([§11.6][s11-6], [§11.8][s11-8]) and mutating
actions carry the bang, beside its already-banged contract neighbours `stage!`
and `mark_dead!`.

**Spec.** [§11.6][s11-6], [§11.8][s11-8]

**Rationale.** A round-5 vocabulary finding (finding 2.1), per [D-144][d-144]'s class
(3).

**Rejected.**
- *Keeping the bare spelling:* a mutating action in noun dress — the class
  violation [D-144][d-144]/[D-146][d-146] exist to retire.

### D-161 — Grow the naming audit to the full class-violation set

**Status.** ratified

**Position.** **The naming audit's flagged list grows from two residuals to the
full class-violation set** — `loop` (mutating task body as bare noun in the
verb-`!` device contract; `run!` taken, prose entrenched), the bare-noun
accessor family
`trace(sim)`/`latest(sim)`/`binding(handle)`/`phase_bodies(sim)` against
class (2)'s `get_` rule with `trace`'s kill-switch/accessor collision the
sharpest case (one name, two senses — the [D-122][d-122]/[D-144][d-144] pattern), and an explicit
class-(1) exemption question for markers (`interactive`) and predicate
traits (`needs_calling_task`).

**Spec.** [§16][s16]

**Rationale.** Round-5 vocabulary findings 2.2–2.4.

**Rejected.**
- *Renaming any of them now:* each needs the whole-surface view the audit
  exists to take; piecemeal renames outside it are how classes drift.

### D-162 — Adopt per-eltype homogeneous cell stores over per-instance

**Status.** ratified

**Position.** **C2 adopted — per-eltype homogeneous cell stores: cells
flattened by [§7.1][s7-1]'s leaf walk into one contiguous buffer per element type,
build-time offsets carried in entry fields, the port type in the address
token's parameter** ([§9.7][s9-7] amended).

**Spec.** [§7.1][s7-1], [§9.7][s9-7]

**Rationale.** Kernel prototype increment 1 — the parked f.3 cell-store
representation bench (`prototypes/cellstore_bench`, 2026-08-08; Apple Silicon,
Julia 1.12.6, chunk 16, one cold process per point). Gate 1 (mandatory) tied —
both candidates zero-allocation, sweep and snapshot, at every N. Gate 2 decided
it: C1's cold sweep compile ran 0.60 s → 56.2 s over N = 1 → 400 identical
instances, visibly superlinear (15.7 s at N = 200), against C2's 0.64 s → 1.14
s — flat, the code sharing real, confirmed structurally by
compiled-MethodInstance counts at N = 100 (C2: 4 `run!`, 3 `gather`, 3
`scatter!`; C1: 103/105/306), which also closes the parked const-prop risk:
offsets are not propagated as constants across the measurement's `@constprop
:none` barrier, which is the real loop's condition. On the 8-partial `Dual`
activation the ratio narrows (3.5× at N = 200) but the shape is what counts:
C2's compile *saturates* at ~9 s from N ≈ 50, bounded by chunk-type count
rather than model size — which demotes [§9.7][s9-7]'s mitigation ladder to optional —
while C1's climbs unbounded (0.83 → 35.1 s at N = 200, still rising). Gate 3
followed: C2's per-entry sweep cost is flat (~7.1 ns nominal, ~48 ns Dual)
where C1's degrades (5.0 → 48.9 ns nominal, 17.9 → 85 ns Dual — 403 distinct
bodies plus a pointer chase per gather); snapshot runtime ties (~1130 ns at N =
400, zero-alloc both).

**Rejected.**
- *Hybrid forms:* rejected by user before measurement.
- *C1 in either form — the tuple-of-`Ref`s built here, or a per-model generated
  inline-field struct:* improves only gate 3's locality term and cannot touch
  gate 2, since type-domain addressing is what forces one compiled body per
  instance.

### D-163 — Ban `==` for separately-compiled float comparisons

**Status.** ratified

**Position.** **Float outputs are compared leaf-wise with a tolerance, never
`==`, wherever the two sides are separately compiled** — the executor contracts
`a*b - c*d` into an FMA where a differently-compiled reference (a type-unstable
evaluator, a hand-rolled per-component check, today's FlightCore path in [§16][s16]'s
comparison) does not, and along a dependency chain the last-ulp difference
accumulates.

**Spec.** [§6.2][s6-2], [§7.5][s7-5], [§9.7][s9-7], [§16][s16]

**Rationale.** Increment-1 observation promoted to doctrine; measured in
`prototypes/cellstore_bench`'s `check.jl`, same class as the main line's
3945596. Two consequences past test hygiene: [§9.7][s9-7]'s chunk size remains a
genuine implementation freedom only while no test asserts bit-exactness across
chunk sizes, and [§16][s16]'s FlightCore value comparison is a tolerance comparison by
construction, not by concession. Determinism is untouched — within one build
the schedule is fixed and [§6.2][s6-2] made every sum an ordered junction entry, so a
run reproduces itself bit-for-bit.

**Rejected.**
- *Bit-exact assertions under a `muladd`-free or pinned-math build:* buys a
  brittle equality by giving up the codegen [§7.5][s7-5]'s invariant depends on.
- *Per-test ad-hoc tolerances:* precisely what stating it once as doctrine
  prevents.

### D-164 — Reject components that declare nothing and define no stage

**Status.** ratified

**Position.** A component that declares nothing and defines no stage is a build
error; the authoring rule is that declarations live at module top level. An
increment-2 finding, extending [§8.1][s8-1].

**Spec.** [§8.1][s8-1]

**Rationale.** **Declarations written in a local scope silently do not exist**
— inside a `let`, a function body or a `@testset`, `h_x(::MyComp, (; x)) = …`
binds a new *local* function rather than adding a method to the global `h_x`,
so calls inside the block resolve correctly while the build, dispatching on the
generic function, sees a component that declares nothing and proceeds. The
local-scope sibling of [§8.1][s8-1]'s `using Cadence` trap, and worse-behaved: the
existing shadowing check cannot reach it, there being no parent-module binding
to compare against — the shadow is a local binding that vanishes with its
block. Mitigation adopted at the other end: an inert component is unwritable on
purpose, which costs a line and catches the misspelled-declaration family too.
Found the hard way in the kernel prototype's early `check.jl`, since retired
into `test/`, where fixture components defined inside their own testset made
the probe's own rejection tests pass vacuously; diagnosed first as a world-age
effect and disproved by direct test (a method defined in a function body *is*
visible to that body's later calls — the shadowing is what bites).

**Rejected.**
- *Documenting the caveat only:* the failure is silent and its symptom — an
  inert component — is exactly what the check names.
- *A world-age-style check comparing `which(...).primary_world` against the
  caller's world:* measures a mechanism that turned out not to be the cause.

### D-165 — Split output-stage returns into public `y` and private `w`

**Status.** superseded → [D-194][d-194]

**Position.** Every output stage returns either `y::NamedTuple` (ports only) or
`(y, w)::Tuple{NamedTuple, NamedTuple}`; a `nothing` in either slot is a probe
error; an empty `y = (;)` is legal, so port-less stages fall out of the general
law (stages are discovered by method existence, membership is a partition of
declared ports that may be empty) — a stage producing neither ports nor `w` is
a dead-stage build error (`DeadStage`).

**Spec.** [§5.2][s5-2], [§5.4][s5-4], [§7.5][s7-5], [§11.2][s11-2], [§8.3][s8-3], [§9.5][s9-5], [§9.7][s9-7], [§13.2][s13-2], [§14.4][s14-4]

**Rationale.** `w` carries the component's private intermediates: an
`isbits`-leaf NamedTuple, never a table cell.

**One-hop law**: `h_x`'s `w` flows to `h_xu` if defined, otherwise to the
downstream set (`f`, guards, handlers); `h_xu`'s `w` flows to the downstream
set; nothing flows implicitly — forwarding across hops is an explicit re-return
(`(y, (; w..., extra))`). Symmetric on the discrete tier (`h_z` → `h_zu` →
`g`), stated once.

`w` joins the closed bundle name sets of `h_xu`, `f`, guards, handlers, `h_zu`,
`g`; presence in a bundle follows the producing stage's probed return (bare-`y`
producer ⇒ no `w` key ⇒ the [§13.2][s13-2] framing diagnostic on a consumer that
destructures it).

`w` is **SSA-passed inside fused executor passes** (the step fuses sweep + `f`;
each event round fuses sweep + guards + fired handlers) and never persisted —
freshness by construction, recomputation cost zero, and the executor commits to
round-fusion as a design constraint.

`w` types are probe-observed; the probe validates the NamedTuple form and
consumer reads against the observed field set (did-you-mean from actual fields,
weaker than declaration-backed but located).

`w` joins the branch-shape rule and the **always-on check at the nominal
activation**: expected = the nominal probe's observed type, one baked `isa`
beside the `y` test — folds to zero instructions when stable, and converts the
unintended-branch-divergence class (which otherwise surfaces only as
allocations in testing) into a loud, located, field-naming error at first
divergent execution, with blame text honestly citing the probe ("expected what
the nominal probe observed"), complementing [§7.5][s7-5]'s canary (detection) with
localization.

**Non-nominal activations run no `w` check**: with no declaration for a
branch-independent anchor and no store to embed into, a strict probe-observed
check there false-positives on the legal constant-branch idiom
(probe-branch-dependent expectations — the one-probe-point argument), while
correctness needs no guard (a `Float64` in `w` under `Dual` is an honest
zero-partial constant by the embedding guarantee; downstream promotion is
exact).

`local_types` is deleted with its satellites: stage membership derives over
`output_types` alone; `ContractNameCollision` retired; `UndeclaredReturnField`
candidates = `output_types`; `get_local` retired from the [§14.4][s14-4] selector family
and [§11.2][s11-2]'s read bindings — the inspection path for intermediates is
*promote to output* (FlightCore precedent: intermediates were only ever
inspected by inclusion in the `Model` output); local cells leave the [§9.7][s9-7]
store; [§8.3][s8-3] visibility becomes: declared in `output_types` = public, returned
in `w` = private **by construction** (nothing to connect, list or filter);
walkthrough 5 rewritten.

Guidance, not law: a `w`-only `h_x` is redundant when `h_xu` exists (fold it in
— both run once per sweep); it is the honest spelling of `u`-independent shared
intermediates when no `h_xu` exists.

**Rejected.**
- *Walking the nominal-observed type to synthesize non-nominal expectations:*
  rejected as machinery kept alive for a check that catches nothing the nominal
  one misses.
- *`local_types` status quo ([D-034][d-034]/[D-055][d-055]):* declaration + table cells +
  presentational filtering for values that were never interface; threading is
  structurally private and cheaper, and per-activation probe observation
  dissolves the dropped-partials objection that rightly killed observation
  authority for *pinned* locals.
- *Pass-through on bare `y`:* the one implicit flow in the design, plus a
  bare-`y`-vs-`(y, nothing)` subtlety needing a didactic paragraph.
- *The `(y, nothing)` chain-terminate form:* no demonstrated customer; extra
  fields downstream are harmless to a destructuring consumer.
- *Opaque `isbits` `w`:* no name-shaped diagnostics.
- *Persisted `w` slots / table cells for `w`:* a cell needs a fixed
  per-activation type, and with `local_types` gone there are only bad sources —
  probe-observed types detonate branch-dependently, the
  `output_types`-inference flaw re-imported; a declaration resurrects what is
  being deleted; an anchor+walk keeps the output-side walk alive for private
  values. SSA-passing dissolves the question: a flowing value has no type
  contract to violate, promotion handles mixed branches exactly — this is what
  makes probe-observation sound here where [D-034][d-034]/[D-055][d-055] rightly rejected it for
  cells. Also: staleness class, store traffic for register-resident values, `w`
  names re-entering the cell namespace, and the loss of "every cell is a
  connectable port". The forfeited snapshot visibility is covered by
  promote-to-output, with a debug-mode SSA capture recorded as the cell-free
  door.
- *Restricting port-less stages to `h_xu`:* the one-hop law routes a sole
  `h_x`'s `w` directly downstream; with no `h_xu` defined, port-less `h_x` is
  the spelling whose no-`u` view set honestly declares the intermediates
  `u`-independent.

### D-166 — Mandate `Type{T}` output signatures on continuous producers

**Status.** ratified

**Position.** `output_types(::C, ::Type{T}) where {T <: Real}` is **mandated on
continuous producers**; plain `output_types(::C)` is **mandated on discrete
producers**; both are Stratum-A-checkable (tier is known from declaration
shape, [§8.5][s8-5]), so the whole-signature forgotten-`T` variant — the nastiest
member of the class in the [D-033][d-033] world, where the plain form *was* the tier
marker — is extinct by construction.

**Spec.** [§7.1][s7-1], [§7.3][s7-3], [§8.1][s8-1], [§8.2][s8-2], [§8.5][s8-5], [§9.4][s9-4], [§9.5][s9-5], [§14.10][s14-10], [Appendix D][sD]

**Rationale.** Semantics are **literal**: cell types per activation = the
declaration evaluated at that activation's `T`; the output-side leaf walk is
deleted.

Per leaf: `T` (alone or as a parameter, `MyStruct{T}`) = participating;
`Float64` = deliberately pinned — **schema-visible whole-leaf freezing,
delivering [§14.10][s14-10]'s recorded door** (declare `Float64`, strip with `value()` in
the stage; the freeze is declared and conformance-checked); `Int`/`Bool`/ enum
and reference-typed leaves as before.

[§9.5][s9-5]'s embed-accept is re-keyed on declared-`T` leaves: a `T` leaf accepts
exactly {activation scalar, `Float64`-embedded-as-zero-partial}; the
constant-branch idiom (`flow > 0 ? f(x) : 0.0`) stays legal as written.

An **observed `Dual` at a declared-pinned leaf** has one honest cause and gets
the didactic hint: "if `F` participates in differentiation, declare it `T`".

The residual per-leaf forgotten-`T` is a lurking-loud class (caught at first
`Dual`-activation build, never silent — no lossy `Dual → Float64` cast exists),
contained by an **adopted CI policy: the test suite builds a `Dual` activation
of every component** (activations are Stratum-C re-runs; cheap, per the kernel
prototype).

Macro sugar over the declaration layer is a recorded door, compatible with
[§8.1][s8-1]'s position (optional, on top, never required).

`init_x`/`init_m`/`init_z` **stay one-argument**, and the criterion is
recorded: **by-value declarations state nominal physics** (their *types* walk
by rule — [§7.1][s7-1] forces every state leaf to follow the activation scalar;
partials enter by per-invocation seeding, never initialization); **by-type
declarations are functions of the activation scalar**; **by-allocation takes
the scalar** ([D-077][d-077]'s `workspace(c, T)` precedent).

Reversal grounds vs [D-079][d-079], recorded so it is never re-litigated from a worse
memory: reader-honesty revalued (the sole author is also the six-months-later
reader; the plain nominal declaration is misleading to anyone not carrying the
walk rule in their head), and two of the three grounds that decided [D-079][d-079] had
already dissolved independently — tier-by-declaration-shape removed the
tier-marker trap, and embed-accept removed the constant-branch detonation that
made the original `T`-form look fragile. [D-079][d-079]'s two conceded losses
("schema-visible participation, whole-leaf stripping detection — tooling
niceties") are re-valued as the point.

Annotation (post-[D-173][d-173] re-examination, 2026-08-16): with `init_z` fused into
`init_x`, the discrete tier also declares `init_x`, and the one-argument ruling
was re-examined and holds — the discrete form stays plain by the same tier rule
as `output_types`, and [§7.1][s7-1]'s ground is fusion-independent. The criterion's
sharpest form, recorded so the next re-examination starts here: a `T` belongs
in a signature exactly where the declaration's non-nominal behavior is
underdetermined by its nominal restriction — by the per-leaf pin/walk choice on
output contracts (this entry), by the tolerant/demands-frozen choice on input
contracts ([D-167][d-167]), by vocabulary freedom on workspace ([D-077][d-077], which no walk
rule could cover) — and nowhere else: [§7.1][s7-1]'s walk being total, a two-argument
`init_x`'s output at any `T` is fully recoverable from its one-argument
restriction, so its `T` would carry no information, only ceremony on values and
a new forgotten-`T` class caught only at activation build.

Annotation (2026-09-08): the per-leaf statement of embed-accept is decided on
the type, by lifting and exact comparison, per [D-238][d-238].

**Rejected.**
- *Plain declaration + leaf walk on the output side ([D-079][d-079]'s design):*
  writer-honest — nothing to forget, no lurk — but reader-opaque, and
  deliberate pinning of a real leaf inexpressible.
- *The one-argument `Float64` fallback on continuous producers:* reopens the
  whole-signature hole just closed; the "doesn't care about AD" population is ≈
  empty in a flight library — trim and linearization sweep whole aircraft
  assemblies — so the fallback mostly manufactures components that poison
  model-wide `Dual` activations at someone else's first trim.
- *Two-argument `init_x` by evaluation:* the `T` records no choice — [§7.1][s7-1]
  admits no pinned state leaf; `zero(T)`/constructor ceremony on values; a new
  forgotten-`T` class *on values* caught only at activation build; the didactic
  side-by-side reading is bought instead by the recorded signature criterion.
- *Two-argument `init_m`/`init_z`:* nothing could ever follow `T`; the
  signature would invite exactly the misplacement [§8.2][s8-2]'s didactic errors exist
  to catch.
- *Blanket `T`-signatures on all declarations:* ritual dilutes the signal — the
  reader-honesty of `T` depends on its appearing exactly where a choice was
  made; the criterion, not uniformity, is the rule.

### D-167 — Mandate `Type{T}` input signatures under the permissive reading

**Status.** ratified

**Position.** `input_types(::C, ::Type{T}) where {T <: Real}` is **mandated on
continuous consumers**, plain on discrete consumers, under the **permissive
reading**: entries state per leaf what the consumer *allows* — `T` = tolerant
(the activation scalar or a frozen `Float64` are both lawful arrivals; walking
producers, frozen discrete producers and root slots all admissible —
substitution intact), `Float64` = **demands frozen** (this input must never
carry partials — the FFI door: a component whose internals cannot propagate
`Dual`s declares it, its AD-incompatibility becomes schema-visible, and the
failure moves from a `MethodError` inside user math at the `Dual` probe to a
named wiring error at build), `Int`/`Bool` and abstract reference-typed entries
(field handles) as today.

**Spec.** [§6.1][s6-1], [§8.2][s8-2], [§8.5][s8-5], [§13][s13], [§14.10][s14-10], [Appendix D][sD]

**Rationale.** Entries remain face bounds, not cell types: the nominal bound
check is now "the producer's declaration evaluated at `Float64` <: the entry
evaluated at `Float64`", unchanged in force.

Wiring acquires a second clause beside it, **evaluable in Stratum A at a marker
scalar** (both sides are declaration functions of `T`; no user stage code
runs): *for a continuous consumer, a walking producer leaf requires a `T`
entry; a pinned producer leaf satisfies either* (frozen values embed upward),
violation being `WalkingFaceAtFrozenEntry` (consumer path + entry, producer
path + face, the leaf, both declared leaf types, both remedies in the message;
[§13][s13]).

**The clause is tier-scoped, and the scope is decisive**: discrete
consumers take the nominal bound check only, because their stages read
exclusively at real ticks in the nominal world — a `Dual`-carrying cell exists
only inside activations discrete stages never run in — so continuous → discrete
wires are unconditionally legal; unscoped, the clause would reject the entire
sensor → controller pattern.

Failure asymmetry, recorded: input-side forgotten-`T` (habitual `Float64` on a
promoting input) fails **at first nominal build, at the wire, both endpoints
named** — inputs have a build-time counterparty, outputs don't — with the
didactic hint "if `C` promotes, declare the entry `T`".

Root slots: the slot type remains the entry at `Float64` (concrete tight bound,
unchanged); slot cells walk by evaluating the entry at the activation's `T`,
making **seedability schema-visible** — a `T`-entry slot is a lawful
linearization `B`-matrix tap, a `Float64`-entry slot is declaredly unseedable.

The genericity obligation ("whatever scalars the wiring delivers, the
consumer's math promotes") stays checked by the `Dual` probe, now scoped to the
`T`-entries — a `Float64`-entry input imposes no such obligation, that being
its point.

Escape from [D-033][d-033]'s rejection, recorded: the permissive reading predicts
nothing and is not constant across components (pinned entries are rare but
real), which is the reading the original adjudication never had on the table.

**Rejected.**
- *The predictive reading ("this is what will arrive") and the envelope reading
  ("I promise to promote"), [D-033][d-033] upheld:* the predictive reading remains
  rejected — producer-, tier- and activation-dependent, breaks substitution
  behind a face; the envelope reading remains rejected — a universal
  obligation, zero information.
- *Symmetric `T`-forms on the discrete tier:* both directions
  unfalsifiable-or-false: no execution path puts a `Dual` in a discrete cell,
  and discrete reads never see one; if [§14.10][s14-10]'s sampled-data door opens, the
  opt-in participation trait brings the `T`-signature with it — the hinge is
  recorded here so the forms stay compatible.
- *The unscoped wiring clause:* rejects every continuous → discrete wire;
  caught in adjudication, recorded so the bug is never reconstructed as
  intended semantics.

### D-168 — Root-slot fan-out tolerance combines by meet, not agreement

**Status.** ratified

**Position.** Root-slot fan-out under permissive entries combines **tolerance
by a meet, not by agreement**: the slot *type* stays the unique concrete
declaration among its consumers at nominal (`RootSlotTypeConflict` unchanged —
a tolerance difference is not a type conflict, `SVector{3,T}` and
`SVector{3,Float64}` both evaluating to `SVector{3,Float64}`), while the slot's
cells **pin at every activation if any consumer entry pins** and follow the
activation scalar only when every consumer tolerates.

**Spec.** [§6.1][s6-1], [§11.3][s11-3], [§8.2][s8-2], [§9.5][s9-5], [§14.10][s14-10]

**Rationale.** Mixed tolerance is a legitimate configuration rather than a
mistake — one command consumed by a promoting aerodynamics leaf and by an
AD-opaque table is [§8.2][s8-2]'s FFI door in use — and the meet is the only
assignment satisfying every consumer at once, forced by the direction of
embedding: a pinned cell feeds a `T` entry lawfully (zero-partial embedding,
[§9.5][s9-5]) while a `Dual` arriving at a `Float64` entry is exactly what that entry
forbids; it is the mirror of [§6.1][s6-1]'s producer-side walk-compatibility clause.

The cost is stated where it is paid: such a slot is declaredly unseedable, and
a `B`-matrix tap selecting it is rejected at tap resolution naming the
**pinning consumer** and its entry (`TapResolution` payload extended), not the
face alone, because the author's next move — promote that leaf, or route the
tap around it — depends on knowing which leaf froze the slot.

Closes the fan-out gap left open by [D-167][d-167].

Annotation (2026-09-08): read at the level of the whole root input, with the
two-candidate computation, per [D-236][d-236].

**Rejected.**
- *Requiring agreement at the marker scalar (mixed = build error):* turns a
  legitimate model into an error whose only remedies are a duplicated slot or a
  false declaration, and makes one component's private AD limitation contagious
  across wiring its author does not control.
- *Join semantics (the slot walks if any consumer tolerates):* unsound in the
  direction that matters — it delivers `Dual`s to an entry that declared it
  cannot take them, the exact failure [§6.1][s6-1]'s clause exists to prevent, moved
  from build time to inside user math.
- *Per-tolerance-class slot cells (one cell per class):* duplicates the slot,
  defeating [§11.3][s11-3]'s one-cell-per-slot staging, the trace header's single type
  and `probe_value`'s single synthesis.

### D-169 — `y_x`/`y_z` carry stage-1 ports only, auto-published excluded

**Status.** superseded → [D-252][d-252]

**Position.** `y_x`/`y_z` carry the stage-1 **return only, auto-published names
excluded** — the underspecification left by the bundle law's "iff stage-1 ports
exist", settled on the narrow reading: an auto-published port is the framework
copying a state, mode or `z` field into a cell at stage-1 position ([§5.3][s5-3]), and
stage 2 already holds `x`/`m`/`z` directly, so carrying it in the hand-down
would be [§7.4][s7-4] step 4's rejected identity transport relocated from the table
into a bundle.

**Spec.** [§5.2][s5-2], [§5.3][s5-3], [§5.6][s5-6], [§7.4][s7-4], [§9.3][s9-3], [§13.2][s13-2], [Appendix B][sB], [Appendix D][sD]

**Rationale.** It is also what [§9.3][s9-3] already sources (the stage-1 *probe's
return*), so the clause records existing machinery rather than changing it;
corollary, stated because it is the case a reader will hit: a component whose
only stage-1 ports are auto-published has no `y_x` in its stage-2 bundle at
all, and a stage-2 function destructuring one meets [§13.2][s13-2]'s framing diagnostic.

Context: this arose while re-examining whether `y_x` survives [D-165][d-165] at all — it
does, and the theme it was suspected of violating ("`y` is public-only") is
what [D-165][d-165] delivered: `y_x` is now declared ports only, `w` carries the private
population, and the pair is one hand-down mechanism over the two populations
the design already distinguishes, with visibility deciding the channel rather
than the author.

**Rejected.**
- *Broad reading (`y_x` = every cell written at stage-1 position,
  auto-published included):* transport for its own sake, since the underlying
  stores are already in the same bundle, and it would make the hand-down's
  contents depend on the *contract* rather than on what the stage computed.
- *Dropping `y_x` entirely and re-routing public stage-1 values through `w`
  (raised and rejected in the same discussion):* forces a public value into the
  channel defined as private, costs a `(y, y)`-style repack idiom or
  hand-copied fields with a drift hazard, makes stage 2 the one own-function
  denied the fused idiom's "publish once, read your own product" that
  `f`/`g`/guards get through `y`, and would unpick [§5.6][s5-6]'s tracer boundary
  argument, in which `y_x` is the named never-seeded stage-2 input.

### D-170 — Split assembly connections into child/input/output declarations

**Status.** ratified

**Position.** Assembly routing declarations renamed and split: `connections` →
**`child_connections`** (strictly child-port → child-port, keeps the
mandatory-even-empty assembly kind-marker role); `exports` **splits by
direction** into **`input_connections`** (face => internal input path or
tuple-of-paths fan-out; entry spelling unchanged) and **`output_connections`**
(internal source path => face, now flow-ordered); direction is *declared by the
method*, [D-041][d-041]'s endpoint derivation becoming a cross-check with a sharper
error and the mixed-entry class inexpressible; face-name uniqueness spans both
boundary declarations; one invariant spans all three: every pair's arrow points
the way the signal flows, left = producer or entry point, right = consumer,
every right side fed exactly once.

**Spec.** [§3.3][s3-3], [§6.1][s6-1], [§6.2][s6-2], [§11.3][s11-3], [§8.2][s8-2], [§8.5][s8-5], [§8.6][s8-6], [§8.8][s8-8], [§9][s9], [§13.3][s13-3], [§16][s16]
(swept)

**Rationale.** Supersedes [D-041][d-041]'s single-method shape; [D-039][d-039]'s marker role
transfers. Motivation: the old `exports` held two opposite flow directions in
one list — spelling-uniform (face on left) at the price of flow-uniformity, and
any single mixed-direction list must sacrifice one.

**Rejected.**
- *Status quo (the sacrifice above — the output entries read against the
  signal).*
- *Consequence-named family `wires`/`imports`/`exports`:* convention-purist, but
  `imports` needs decoding and a *narrowed* `exports` is a stale-citation
  hazard across 169 rows — a dead name cannot be misread, a narrowed one can.
- *`inner_connections`/`internal_connections`:* visual near-collision with
  `input_connections`.
- *`children_connections`:* English compounds take the singular noun-adjunct.

### D-171 — Rename `passthrough` to `input_passthrough`

**Status.** ratified

**Position.** `passthrough` → **`input_passthrough`**.

**Spec.** [§8.8][s8-8], [§16][s16]

**Rationale.** Annotates [D-144][d-144]: its "stays accurate if the output-direction
addition lands" clause assumed a direction *keyword* on one helper; after
[D-170][d-170]'s split a single call cannot emit into two declarations, so the guarded
addition's landing shape is a sibling `output_passthrough` splatted into
`output_connections` — the prefix is the split's consistent consequence, and
[§8.8][s8-8]'s inputs-only-by-definition paragraph shrinks to the guarded-addition
pointer, the name now carrying the direction.

**Rejected.**
- *Bare `passthrough`:* [D-144][d-144]'s premise retired by the split.
- *Plural `input_passthroughs`:* a bare plural collection noun re-enters the
  declaration class [D-144][d-144] moved the helper out of; return cardinality never
  drives operation naming.
- *Building `output_passthrough` now:* stays guarded — no demonstrated
  consumer.

### D-172 — Rule "face" kind-blind, defined at first use

**Status.** ratified

**Position.** "Face" is ruled kind-blind and defined at first use ([§3.3][s3-3], [§4.3][s4-3],
[§8.2][s8-2] fixed; the term was never adjudicated — presupposed by [D-033][d-033]/[D-041][d-041] — this
row records it as deliberate): a component's *ports* are its signal endpoints
(one cell, one producer — [§4.3][s4-3]'s periphery atom); its *faces* are the names
those ports wear on its boundary — coinciding for a leaf, aliasing interior
ports for an assembly ([D-170][d-170]'s declarations), never creating an endpoint; N
faces across nesting levels may alias one port; wiring and the periphery
address a child's faces without knowing whether it is primitive or composite
([§6.1][s6-1]'s generic seam requires the kind-blindness).

**Spec.** [§3.3][s3-3], [§4.3][s4-3], [§6.1][s6-1], [§11.2][s11-2], [§8.2][s8-2], [§8.3][s8-3], [§8.6][s8-6]

**Rationale.** Wording fixes: [§3.3][s3-3] "exported ports" → boundary faces; [§8.2][s8-2] "a
primitive root has no faces" → no root slots (its faces are its own port
names).

**Rejected.**
- *Unifying on "port"/"assembly ports":* kind-qualified vocabulary cannot state
  [§6.1][s6-1]'s generic-seam rule; calling aliases ports falsifies [§4.3][s4-3]'s
  one-port-one-cell atomicity and forces "port alias" repair vocabulary; "port
  name vs port path" loses the two-notation rule's lexical anchor, [§8.6][s8-6]/[§11.2][s11-2].
- *Replacement terms surveyed and rejected:* `gate` (flow-control connotation
  plus fatal collision with multi-rate gating), `pin` (collides with pinned
  cells, [D-166][d-166]–[D-168][d-168], and is the endpoint, not the name), `terminal`
  (`resolve_terminal`; endpoint again), `handle` (`binding(handle)`),
  `alias`/`label` (mechanism-true but obligation-weak — faces carry claims and
  unconnected-input errors), `socket`/`portal` (passage metaphors); "face" is
  the morphological root of [§8.3][s8-3]'s own "interface".

### D-173 — Fuse the discrete state letter `z` into `x`

**Status.** superseded → [D-195][d-195]

**Position.** The discrete state letter `z` fuses into `x`: `h_z`/`h_zu` →
`h_x`/`h_xu`, `init_z` → `init_x`, `y_z` → `y_x`, bundle field `z` → `x`, `z⁺ =
g(z,u,t)` → `x⁺ = g(x,u,t)`; `f`/`g` stay distinct (flow and jump maps); `m`
and `Δt` keep their tier-scoped meanings; the per-function closed bundle-name
sets become per-function-per-tier.

**Spec.** [§3.2][s3-2], [§5.2][s5-2], [§5.3][s5-3], [§7.3][s7-3], [§8.2][s8-2], [§8.7][s8-7], [§9.3][s9-3], [§9.5][s9-5], [§13.7][s13-7], [§14.1][s14-1],
[§15.2][s15-2], [§15.5][s15-5], [Appendix C][sC] (all companions swept), [Appendix D][sD]

**Rationale.** [D-056][d-056] untouched and central — it is what makes the fusion
safe, a leaf being strictly one tier and no component reading another's state.

Tier doctrine restated: stateful leaves declare tier by update law (`f` vs `g`,
with `events`/`init_m`/`workspace`/`output_types`/`input_types` arities
agreeing, [D-166][d-166]–[D-167][d-167]); a stateless leaf's tier is decided by its contract
arities (`output_types` mandatory hence always the decider, `input_types`
agreeing where declared) — no mere marker, the arity IS the tier's semantics
(walking at `T` vs pinned, [D-166][d-166]–[D-167][d-167]) — and `DeclarationOnWrongTier` survives
on the reduced member set while the wrong-letter error class dies with the
distinction it policed.

Motivation: `z` collided with the shift operator (`z⁻¹`, five spec sites —
[§13.7][s13-7]'s `UnitDelay` bullet had the letter meaning two things in three lines)
and was nonstandard besides — discrete state-space writes `x[k+1] = g(x[k],
u[k])` and hybrid-systems notation (Goebel–Sanfelice–Teel) writes flow `ẋ =
f(x)` / jump `x⁺ = g(x)` with one letter, a convention the spec already
inhabited (`f`/`g`, `x⁺ = project`); the fusion halves the stage/init surface;
timing deliberate — increment 3 (the discrete engine) is unbuilt, so it is
written once under the fused names.

**Rejected.**
- *Renaming `z` to another letter:* fixes the collision only, keeps the doubled
  API; every candidate letter is taken — `s` is the Laplace variable, the
  mirror collision; `q` is spoken for by quaternions; `d` reads
  disturbance/derivative — when every letter is taken the doubled scheme is the
  problem.
- *`is_discrete(::C)::Bool` trait as stateless-leaf tier decider:* derivable
  hence redundant — restates what `f`/`g`, `events`, `init_m`, `workspace`
  arity and `output_types` arity already fix, joining the
  `DeclarationOnWrongTier` agreement set with zero new information; mandatory =
  boilerplate on every leaf, defaulted = class-by-omission, which [D-039][d-039] refused
  for kind; the corner it protects is rare — [§13.7][s13-7] steers stateless leaves
  continuous — already netted by [§8.7][s8-7]'s rates-on-continuous error and [D-166][d-166]'s
  Dual-activation CI policy, and behaviorally near-neutral under
  tier-transparency; stays a cheap purely-additive retrofit if migration
  falsifies the premise.
- *Fusing `z` into `m` instead:* semantically tempting — discrete state is
  latched memory — but it kills the method fusion, breaks the `x[k]`/`x⁺`
  convention, and [§3.2][s3-2] already ruled the discrete tier's state IS its memory.

### D-174 — Re-class the GUI as an ordinary enumerated writer

**Status.** ratified

**Position.** The GUI is re-classed as an ordinary enumerated writer and the
derived surface class retires: a binding's claim set has two *sources* and one
meaning — **returned** by `claims(b)`, or **computed** by the framework at
attach as the unclaimed complement (all root input faces minus the union of the
rostered claims) when the binding declares `is_greedy(b) = true` — so
greediness is a claim source, not a device class, and everything downstream of
claim acquisition is identical for both: exclusivity validation (trivially
satisfied for the complement, disjoint from every rostered claim by
construction), roster-entry storage, staging-shape/shim/merge/scatter
compilation, drain, trace and detach-releases-claims.

**Spec.** [§11.3][s11-3], [§11.4][s11-4], [§11.6][s11-6], [§11.7][s11-7]

**Rationale.** A second greedy attach finds an empty complement and stakes an
**empty claim** — legal, [§11.6][s11-6]'s honest may-write-nothing degenerate — plus the
attach-time diagnostic `EmptyGreedyClaim` (warning (service), [D-159][d-159]'s sixth
severity); partial-claims GUI bindings are legal, and **multiple interactive
front ends with explicit disjoint claims** become legal (a web console claiming
the autopilot faces beside a local GUI claiming the stick faces), only
`needs_calling_task` staying singleton.

The `interactive(b)` marker and `InteractiveConflict` are retired and admission
narrows to three parts — identity, affinity, claims.

The **harness writer** (renamed from the interactive writer) is the sole
remaining derived surface: the framework-owned `stage!(sim, ...)` entry point
and its always-present cell, covering the unclaimed complement, recomputed at
every stopped-sim `attach!`/`detach!`, with the pending-batch renormalization
seam now applying to it alone and `ClaimedFaceEntry` narrowed to it (an
enumerated writer's out-of-surface entry, the GUI's included, is the ordinary
`OutOfClaimEntry`).

Widget liveness becomes: live iff the port's feed chain terminates in a root
slot **inside the GUI's own claim**; the harness cell still drains last, now as
plain convention, the "explicit hand of code beats a widget interaction"
arbitration rationale being objectless once surfaces are disjoint.

Supersedes the interactive-writer halves of [D-044][d-044], [D-104][d-104] and [D-106][d-106].

**Rejected.**
- *`UserInput`-as-device:* a taskless degenerate inside a loop-body device
  contract, a claim-totality precondition on every other device, and an engine
  auto-attach policy.
- *Run-entry re-staking of greedy claims:* a second claim-staking point in the
  lifecycle, where attach-time computation already has every fact it needs.
- *A `GreedyConflict` singleton mirroring the retired `InteractiveConflict`:*
  the empty remainder is well-defined under attach-time semantics and
  diagnosable as a warning, while two explicit-claims front ends are just two
  enumerated devices — nothing left to police.

### D-175 — Re-scope `gui = true` to a run-scoped attachment

**Status.** ratified

**Position.** `gui = true` is re-scoped from persistent attach sugar to a
run-scoped attachment: at run entry the flag attaches the shipped GUI device
under the greedy binding with `should_abort = true` iff no GUI is rostered, and
at run exit it detaches what it attached — the detach sitting in [§12.4][s12-4]'s
shutdown tail, so it is taken on the error path too. A persistent GUI session
is spelled manual `attach!`, and against a manually attached GUI the flag does
nothing and detaches nothing.

**Spec.** [§11.6][s11-6], [§12.4][s12-4], [§12.6][s12-6], [Appendix B][sB]

**Rationale.** Motivation: under [D-174][d-174]'s computed claims a persisted greedy
claim is a **stale-claim trap** — the everything-claim staked on run 1 survives
into run 2, where a joystick attached between runs collides with it
(`ClaimConflict`) although nothing in the user's model of the flag says a GUI
is holding those faces; run-scoping dissolves it without introducing a second
claim-staking point in the lifecycle, since the flag's attach happens at a
stopped-sim instant like any other.

Cost accepted: per-run device-id churn for the flag-attached GUI (ids exist to
be read across roster changes, and each run's trace header carries its own
schemas, so nothing that reads a completed run is affected).

**Rejected.**
- *The prior [§12.6][s12-6] semantics — an idempotent flag that never detaches:* hidden
  roster state accumulated by a convenience argument, plus the `ClaimConflict`
  trap above, whose only remedy is a `detach!` the user never issued an
  `attach!` for.

### D-176 — Unify trace retention on one sparse record format

**Status.** ratified

**Position.** Trace retention unifies on one sparse record format (supersedes
[D-107][d-107]'s density rule): the verbatim-vs-sparse dichotomy is eliminated —
**every** writer's drained batch is sparse-converted at the drain into
(position ⇒ value) pairs against the header's schema, so the trace has one
consumer-facing record format, no per-entry format flag, and replay one
inverse-conversion path.

**Spec.** [§7.5][s7-5], [§11.5][s11-5], [§12.7][s12-7], [Appendix D][sD]

**Rationale.** Costs recorded where they are paid: ~2× trace size on the dense
component (two small values per touched face where the tuple held one, the
order unchanged and [D-029][d-029]'s two-orders-below-the-log budget untouched); the
conversion allocates once per drained batch, in-class with [§7.5][s7-5]'s retention
carve-out and smaller than the log's per-boundary snapshot, which the carve-out
already covers. The decision is **reversible as pure implementation**:
conversion is lossless both ways, so verbatim retention could return as a
per-entry storage optimization without touching the record semantics, the
header or replay. Motivation: [D-174][d-174] made "enumerated ⇒ claim-narrow ⇒ dense"
false — a greedy claim is enumerated and as wide as the root contract — so
density could only be re-keyed on the claim source, i.e. on a distinction [D-174][d-174]
exists to erase.

**Rejected.**
- *Keying retention by claim source:* a dichotomy needing re-justification at
  every change to the surface machinery, resting on a premise — enumerated
  means narrow — that `is_greedy` falsifies.
- *Deciding density per batch at the drain:* per-frame heterogeneous record
  formats, a format flag on every entry and two decoders in every consumer, for
  no customer that ever asked to tell the two apart.

### D-177 — Re-found the periphery on mandatory roots plus declared traits

**Status.** ratified

**Position.** The periphery's declaration idiom is re-founded on declared
traits over mandatory neutral roots: every device subtypes `AbstractDevice` and
every binding `AbstractBinding`, mandatorily, so `attach!(sim,
dev::AbstractDevice, binding::AbstractBinding; should_abort = false)` gates at
dispatch — [§8.5][s8-5]'s one-root rejection does not transfer, the periphery's
single-inheritance slot being vacant (no domain hierarchies compete for it) and
a binding's sidedness being its **public contract**, not the [§8.3][s8-3]-hidden
implementation class a component's tier is.

**Spec.** [§11.3][s11-3], [§11.6][s11-6], [§8.1][s8-1], [§8.3][s8-3], [§8.5][s8-5], Appendices A/B/C, glossary [§D.6][sD-6]

**Rationale.** Binding sides are **declared by Bool traits** with framework
defaults on the root — `is_input`/`is_output` false, `is_greedy` false, the
claim-source selector *within* the input side — and the enumeration obligations
are enforced by **error fallbacks** (`claims(::AbstractBinding)`,
`reads(::AbstractBinding)`) plus a **bidirectional conformance check at
attach**: is_input && !is_greedy ⇒ `claims(b)` called once (a missing method
fires the fallback loudly); is_input && is_greedy ⇒ claim computed and a
defined `claims` method is an error; is_output ⇒ `reads(b)` called; neither
side declared ⇒ attach-time error; is_greedy && !is_input ⇒ error; and a
*specific* method of `claims`/`reads` defined for the binding type while the
corresponding trait is false ⇒ error, detected by `which` against the fallback
([§8.1][s8-1]'s reflection class, run at a stopped-sim service point).
Trait-true-method-missing and method-defined-trait-false both report the new
diagnostic `BindingContractMismatch` (service), naming the trait and the method
at fault. `map_input`/`map_output` remain conventions of the author-owned loop
idiom the framework never calls — taught in [Appendix A][sA], never checked. What
this closes: under method-presence detection a bidirectional binding whose
`claims` was written *without* extending the framework generic (the [§8.1][s8-1]
shadowing trap, one level down) degraded **silently to output-only** — the
device attached, staked nothing and wrote nothing; `is_input = true` now makes
the absence loud. The `sides(b)` rejection is **answered rather than ignored**:
its ground was redundancy with methods that must exist anyway, and redundancy
*with a cross-check* is drift detection, which is what the bidirectional check
makes of it — annotated inline where [§11.6][s11-6] lists the rejection. Side-encoding
supertypes stay rejected (a bidirectional binding cannot subtype two sides),
and the empty-enumeration doctrine survives untouched: `is_input(b) = true` +
`claims(b) = ()` is the honest may-write-nothing degenerate, while the maximal
surface still requires the explicit `is_greedy` declaration.

**Rejected.**
- *Presence-only probing, the prior design of record:* silent partial
  degradation of a shadowed bidirectional binding, and `hasmethod` is the rarer
  Julia interface idiom beside the AbstractArray/IndexStyle pattern of roots
  plus traits.
- *Optional, unenforced supertypes:* a signal half the ecosystem skips is worse
  than no signal at all — the dispatch gate is the whole value.
- *Side-encoding supertypes `AbstractInputBinding`/`AbstractOutputBinding`:*
  unchanged from the standing rejection — a bidirectional binding cannot
  subtype two sides.
- *Annotation (from [§11.6][s11-6]'s inline treatment, migrated at the P3.2 rewrite,
  2026-08-14):* under presence detection the degradation was not merely silent
  but actively misdirecting — every diagnostic available pointed away from the
  missing import.

### D-178 — Reaffirm component-side rejections against the periphery's new idiom

**Status.** ratified

**Position.** The component side is reaffirmed against the periphery's new
idiom — no spec change ([D-177][d-177]'s clarity-supertype argument explicitly does
*not* transfer).

**Spec.** [§8.1][s8-1], [§8.5][s8-5]

**Rationale.** Tier supertypes `ContinuousComponent`/`DiscreteComponent` stay
rejected, because the single-inheritance slot of a concrete leaf is owned by
the domain hierarchies (`AbstractAircraft`, engine families) — threading domain
abstractions under tier roots forecloses cross-tier substitution in one slot (a
continuous PID and a discrete compensator in the same avionics slot) and
assemblies in domain slots (an assembly is tierless) — and because a nominal
tier would be a **third copy of a twice-declared, cross-checked fact**
(`f`-vs-`g` plus the [§8.5][s8-5] signature arities, `TierSignatureMismatch`), which
is [D-173][d-173]'s `is_discrete` rejection restated one level up: the periphery's
traits add information no method carries, a tier supertype would add none.
**Value fallbacks** on the component root (`init_x(::AbstractComponent) =
nothing`, `input_types(::ContinuousComponent, ::Type{T}) = (;)`) stay rejected
on a sharper doctrine than convenience: they would make every component
"declare" everything, so class and feature presence stop being readable from
the declaration set ([§8.5][s8-5]'s class-by-declaration-shape), they silence both
[D-164][d-164]'s declares-nothing build error and [§8.1][s8-1]'s shadowing defense — the two
checks that catch the silent-degradation family — and they reinstate
sentinel-meaning returns (`nothing` = no state) that the declaration vocabulary
refuses. Doctrine recorded in one line: **error fallbacks are interface
machinery, value fallbacks are semantics**, and semantics-by-default is banned
where absence means nonexistence. Residual, recorded rather than remedied:
partial local-scope shadowing of *optional* feature declarations (`events`,
`workspace`) still builds silently with fewer features, since presence is the
whole signal there and no trait declares them; if it ever bites, the remedy is
build-time legibility of the declaration set (printing what a component was
read as declaring), never per-feature intent Bools, which would be the
boilerplate-on-every-leaf outcome [D-039][d-039], [D-173][d-173] and this row all refuse.

**Rejected.** The rejected alternatives are this row's subject:
- *Tier supertypes* `ContinuousComponent`/`DiscreteComponent`.
- *A nominal `is_discrete`-style tier marker* ([D-173][d-173], upheld).
- *Value fallbacks on `AbstractComponent`'s declaration generics.*
- *Per-feature intent Bools for the optional declarations.*

### D-179 — Derive detection policy from the guard's return type

**Status.** ratified

**Position.** Detection policy is declared by the guard's return type — `Bool`
⇒ boundary-detected, nominal scalar ⇒ localized — and `Event(guard, handler)`
loses the `localize` keyword: de-localization = casting the guard to its
predicate (`σ ≥ 0`, the [§2.1][s2-1] definition, semantics-preserving by construction).

**Spec.** [§2.1][s2-1], [§10.4][s10-4], [§8.1][s8-1], [§9.3][s9-3], [§9.5][s9-5]

**Rationale.** The localized-`Bool` combination becomes unrepresentable and
`LocalizedGuardForm` retires, `GuardForm` remaining the sole guard diagnostic;
recorded doctrine: guards over `u`/`m` alone are piecewise frame-constant so
boundary detection is *exact* for them, and the gate idiom `(gate) ? σ :
-one(σ)` is the blessed way to localize a mixed predicate (gates frame-constant
through probes).

**Rejected.**
- *The `localize` keyword, the prior design:* redundant with the probed form —
  the [§9.3][s9-3] probe already observes it; every policy flip touches two sites,
  manufacturing the desync mistake the build check then polices.
- *Two nominal `Event` types (`LocalizedEvent`/`NonLocalizedEvent`):* the best
  spelling of declared-intent-plus-check, but isomorphic to the flag — restores
  the two-axis design, the resurrected build error and two-site flips; kept as
  a guarded addition should habit-driven accidental localization prove a real
  nuisance in migration.
- *Per-relation-atom crossing decomposition à la Modelica:* requires owning the
  AST — excluded by [§8.1][s8-1]'s no-macros/no-introspection foundations.

### D-180 — Bank per-event `direction` as an unbuilt guarded addition

**Status.** ratified

**Position.** Per-event `direction` (`:upward`/`:downward`/`:both`) is recorded
as a guarded addition, unbuilt.

**Spec.** [§2.1][s2-1]

**Rationale.** `:downward` is pure sign-flip sugar (desugars to the negated
predicate); `:both` (fire on any predicate change) costs little machinery —
compile-folded edge test, direction-blind root-finder, endpoint policy
generalizing to the post-edge endpoint — but serves only the shared-handler use
case, and the domain's transitions are asymmetric-handler pairs ([D-082][d-082]:
hysteresis wants two events anyway); strong precedent exists (MATLAB events
`direction = 0`, Simulink either-direction zero-crossings, Modelica both-edge
relation events), so it is banked until migration shows demand.

**Rejected.**
- *Building it now:* machinery cheap but no grounded use case; [§2.1][s2-1]'s
  negated-guard second event covers every current need.
- *Rejecting it permanently:* the precedent is universal and the analysis shows
  no structural obstacle.

### D-181 — Replace once-per-boundary firing with budgeted re-firing

**Status.** ratified

**Position.** Once-per-event-per-boundary and its deferral compensation are
replaced by budgeted re-firing: an event may fire up to `firing_budget` times
per boundary (deployment keyword, default 4, integer ≥ 1,
validated/recorded/replay-compared with its siblings), eligibility =
intra-boundary not-holding → holding edge on a last-observed sample initialized
from the prior.

**Spec.** [§10.4][s10-4], [§10.6][s10-6]

**Rationale.** Priors are always honest quiescent samples (manufactured-prior
exception, re-arm flag and `EventDeferred` retired; registers = prior +
last-observed + firing count); a re-enabled event fires at its true boundary
against a fresh sweep (no one-step h-artifact); exhaustion loses that event's
further edges for the boundary under a `FiringBudget` warning naming the
chatterer — degrades, never errors; termination budget-bounded (≤
budget·events) instead of structural; rescues [D-020][d-020]'s rejected rounds-cap in
repaired form (per-event, degrade-not-error — the [§10.4][s10-4] doctrine that postdates
the rejection); `event_budget` renamed `localization_budget` (a second budget
made the name ambiguous; semantics unchanged).

**Rejected.**
- *Deferral, the design of record:* manufactured not-holding prior — a lie
  breaking the localization left-end argument; fires one step late, an
  h-artifact on a logically-instantaneous cascade; collapses multiple re-arms
  into one firing.
- *Plain loss:* once fired, further edges dropped — permanent silent misses
  with no step-size mitigation — cascades are logically simultaneous,
  h-independent.
- *Honest prior + explicit pending bit:* identical behavior to the lie with one
  more register, and composes worse with [D-182][d-182]'s θ=0 check.
- *A joint firing pool:* one chatterer starves innocent cascades — [D-020][d-020]'s
  collective-punishment defect.
- *Reusing one knob for both budgets:* irreconcilable exhaustion semantics —
  localization exhaustion must preserve firings, firing exhaustion must
  suppress them or the iteration never terminates.

### D-182 — Add a θ=0 validation probe to the localization trigger

**Status.** ratified

**Position.** Localization trigger gains a θ=0 validation probe: trigger checks
run against the arrival sweep (before the due-gated boundary sweep, making the
ZOH clause's ordering explicit); on trigger the first act writes xₙ (already
stepper-retained for the interpolant) and sweeps once under post-drain `u`,
sourcing the previously-unsourced left bracket value for the value-based
root-finders and discriminating the edge's cause.

**Spec.** [§10.6][s10-6], [§8.1][s8-1]

**Rationale.** Only `u` can differ from the prior's context (`m`/cells/`t`
boundary-stable, sweeps deterministic): σ₀ not-holding ⇒ trajectory-caused, pay
ẋₙ₊₁ + interpolant and root-find; σ₀ holding ⇒ epoch-caused (the frame-top
drain flipped the guard, no in-frame crossing exists) — localization discarded,
the event fires in the boundary's ordinary iteration, one sweep spent, no
budget, no warning (input timing is a frame fact; boundary detection is exact
for epoch-caused edges), the left-end mirror of the t*=tₙ₊₁ degeneracy; "t*=tₙ
structurally impossible" restated on the observed left end, unconditional under
[D-181][d-181]'s honest priors (drain = sole disagreement source).

**Rejected.**
- *Forbidding `u`-reading localized guards:* unenforceable without the
  introspection [§8.1][s8-1] forbids; kills the gate idiom [D-179][d-179] blesses.
- *Draining before the boundary sequence:* rewrites the epoch structure —
  boundary sweeps would mix post-drain `u` with `u`-old-evolved state, ticks
  would resample, trace conventions shift — settled machinery churn out of
  proportion to the corner.
- *Frozen-`u` probes:* a sweep has one `u`; two-epoch bundles are [§10.6][s10-6]'s
  rejected two-freshness-classes shape.
- *Trusting the prior as the left bracket value:* testimony, not observation —
  exactly the hole.

### D-183 — Retire workspace poisoning

**Status.** ratified

**Position.** Workspace poisoning is retired — the framework never inspects or
mutates a workspace: it is an opaque, opt-in escape hatch used at the author's
own risk, its rules stated as contract only (at call entry, contents are
unspecified beyond structure the allocator established; scratch is garbage
until written this call; no information carried between calls).

**Spec.** [§7.3][s7-3]

**Rationale.** `undef` allocation stays the recommended idiom and becomes the
sole visible marker of meaningless contents; `PoisonSkip` retired; `debug`
retired from `run!` (the poison was its only referent); supersedes [D-077][d-077]'s
poison clause.

**Rejected.**
- *Scoped eltype poison of record ([D-077][d-077]: `NaN`/`typemin` + loud
  `PoisonSkip`):* the poisonable/skipped boundary is an ill-defined
  classification over opaque author-owned data (plans and factorizations are
  valid from allocation; a recursive fill would corrupt them, the eltype
  heuristic spares them only by coincidence), and a loudly-partial guarantee
  still trains authors onto a net that may not be under them.
- *Full-coverage poison:* not well-defined for arbitrary contents.
- *Keeping `debug` as an empty hook:* speculative.

### D-184 — Fold `Group` into the spec as an ordinary library component

**Status.** ratified

**Position.** `Group` is folded into the spec — the on-the-fly assembly as an
ordinary library component (ex-Addendum A of the extensions charter): a single
library type `Group{C <: NamedTuple, W, I, O}` whose `NamedTuple` `children`
field contributes path-named children via [§8.5][s8-5]'s container-children rule and
whose `child_connections`/`input_connections`/`output_connections` return
instance fields — every ad-hoc topology a value of one type, defined once.

**Spec.** [§8.5][s8-5], [§13.7][s13-7]

**Rationale.** Stratum C specialization, the compiled executor, wiring
validation, did-you-mean and two-producer checks all run against the instance
exactly as for a named assembly; gives up dispatchable identity, which
exploratory/programmatic composition does not want; serves the model-assembler
persona with zero new declaration rules — [§8.5][s8-5]'s builder rejection stands
untouched (immutable grouping needs no builder), and the component enters
[§13.7][s13-7]'s inventory as its one persona-admitted member.

**Rejected.**
- *The mutable builder (`Assembly()` + `add!`/`connect!`):* [§8.5][s8-5]'s standing
  rejection — type/recipe drift, mutable state through declaration code, no
  source-location capture.
- *Named types as the only spelled-out route:* the actual bias — the type-based
  semantics were always sound for anonymous topologies too.
- *Leaving `Group` chartered in the extensions document:* it needs no guarded
  seam — it is expressible under today's rules, so the charter's
  none-built-until-need gate had nothing left to guard.

### D-185 — Adopt the phased, two-form sample-time declaration

**Status.** ratified

**Position.** Sample-time declaration gains phases and becomes two-form —
`sample_time_proposal.md` adopted (the proposal remains the worked companion):
a `sample_times` entry (the method renamed from `rates`, faithfulness over
brevity) declares one (period, phase) pair as an explicit wrapper type naming
the unit system — `Relative(K, Φ = 0)` in scope ticks (`K ≥ 1`, `0 ≤ Φ < K`),
`Absolute(q, τ = 0)` in exact rational seconds (`T = period(q) > 0`, `0 ≤ τ <
T`, `q` a `Period`/`Hz` quantity normalized to its rational period at
construction; float arguments throw a teaching error naming the exact spelling)
— the wrappers the whole value vocabulary, an unlisted discrete child
defaulting to `Relative(1)`, validation Stratum A's with path attribution and
the constructors plain data carriers.

**Spec.** [§10.5][s10-5], [§8.7][s8-7], [§9.7][s9-7], [§13.1][s13-1], [§14.5][s14-5], [§14.8][s14-8]

**Rationale.** Composition: multipliers multiplicative, phases affine (`D =
K·Dₛ`, `Φ = Φₛ + φ·Dₛ`), preserving the canonical residue `0 ≤ Φ < D` with no
normalization pass, all scoping still compiling to one `(D, Φ)` pair per
discrete component; the boundary gate is `(idx − Φ) % D == 0` — one gate for
all three tick-sensitive blocks, due-ness per component per boundary never per
stage, `t*` emptiness remaining arity selection (no sentinel index fails every
gate); boundary zero refines from "everything due" to "everything with `Φ =
0`", implemented by nothing — the ordinary gate at index 0 under the residue
invariant — an offset component holding its probe-populated cells until its
first tick at `Φ·Δt_base` ([§14.5][s14-5]'s sweep bullet and [§14.8][s14-8]'s committed-residual
read-back each carry the caveat); `Δt` semantics explicitly unchanged
(`D·Δt_base`; a phase shifts firing instants, never the period); relative
phases never refine the base grid and cannot leave the scope grid, and `K = 1`
admits no stagger — same-rate siblings stagger one level down, the scope
declared at twice their rate.

**Rejected.**
- *Bare-value sugar behind a normalization function (`ratespec`: bare `Int` ⇒
  `Relative`, bare quantity ⇒ `Absolute`):* implicit form inference; the
  form stays visible at every declaration site, the common case handled by
  the unlisted-child default instead.
- *Floats in periods or offsets:* GCD derivation over floats is ill-defined;
  `Rational{Int}` fields make exactness structural.
- *Constructor-side range validation:* instant REPL feedback, but fails a
  `sample_times` body's *evaluation* with a raw exception against [§13.1][s13-1]'s
  collect-the-checks policy.
- *Materialized due sets:* a precomputed hyperperiod table (the lcm grows
  multiplicatively where the gcd-derived grid grows slowly, and it converts two
  arithmetic ops into a dynamically-indexed load of runtime data) and a
  per-frame recomputed mask (mutable state threaded through the sweep to
  replace a subtraction and a remainder with a load) — both lose to the pure
  gate, which also generalizes to the extensions charter's triggered updates
  where a table does not.
- *`RelativeRate`/`AbsoluteRate`:* clash-safer exports, worse at the
  declaration site; the recorded fallback if clashes bite.

### D-186 — Legalize absolute declarations in any scope via anchors

**Status.** ratified

**Position.** Absolute declarations become legal in any scope — anchors,
severing, and the derive-vs-declare rule: the `(T, τ)` pair an `Absolute` entry
establishes is an **anchor**, severing its child from the enclosing scope's
grid — no relation to the scope's ticks remains, so `K ≥ 1` reads "a child
cannot tick faster than the scope it is *relative* to" (an anchored child may
outpace its scope), the fastest-member convention counts relative members only,
and anchored-vs-relative phase relationships are deployment-emergent, the
printable bound schedule the way to audit them.

**Spec.** [§10.5][s10-5], [§9.1][s9-1], [§9.2][s9-2], [Appendix B][sB]

**Rationale.** The doctrinal line sharpened rather than dropped: an absolute
declaration inside a library type is legitimate when the rate is **a fact about
the modeled system, not a preference about the simulation** (a GPS's emission
rate, a bus schedule, an ADC's conversion offset — forcing them to the root
breaks encapsulation, the root re-declaring device internals), deployment
preferences keep the exposed-multiplier idiom, and the framework cannot police
the distinction — authoring doctrine, one paragraph beside the declaration
forms; never-cache-`Δt` fully intact (the pinning sits in the enclosing
assembly's `sample_times`, the same site the multiplier lives; the component
type stays rate-agnostic and consumes the bundle's `Δt`); Stratum A compiles to
**`(anchor, m, c)` triples** — seed `(A₀, 1, 0)` with anchor 0 the symbolic
base grid, `Relative(K, φ)` step `(a, K·mₛ, cₛ + φ·mₛ)`, `Absolute` severs and
re-seeds `(Aₖ, 1, 0)`, nested anchors just seeding again — the `Build` gaining
the anchor and component tables with declaration provenance, final divisors for
anchored entries deferred to binding (they do not exist until `Δt_base` does,
and one `Build` backs many `Simulation`s); deployment: the **constraint pool**
is every anchor period plus every nonzero offset, `Δt_base` admissible iff it
divides the pool's GCD; **derive `Δt_base` only when every discrete component
is anchored** — an unanchored period is `m·Δt_base`, and silent derivation
would let an anchor edit anywhere rescale it, action at a distance — otherwise
deployment must declare it, the refusal constructive; `Δt_base` binds from
exactly one of three cross-validated sources — explicit keyword
(`Rational`/`Period`/`Hz`, `n` derived and validated an integer ≥ 1), the `n·h`
product, or derivation at the pool GCD — and resolution is one exact division
pair per anchor (`DeploymentInvalid` naming the anchor's declaring scope and
key when non-dividing) plus one multiply-add per component, the residue
invariant surviving into the bound `(D, Φ, Δt)`.

**Rejected.**
- *Root-only absolute declaration (the superseded [§10.5][s10-5] clause):* right about
  deployment preferences, wrong for device-intrinsic rates; kept only as the
  default-form rationale.
- *Silent `Δt_base` derivation with unanchored components present:* the
  logger-rescaled-by-an-offset-edit case.
- *Absolute pinning from outside a subtree's contract:* standing rejection,
  upheld.
- *Any required relation between anchors:* they share only the base lattice,
  which the grid derivation guarantees.

### D-187 — Make the bound schedule a named artifact with exact grid diagnostics

**Status.** ratified

**Position.** The bound schedule becomes a named artifact and the grid gets
exact diagnostics: deployment binding produces the **bound schedule** on the
`Simulation` — per discrete component `(D, Φ, Δt)` with anchor and provenance
columns, the single source of truth for `Δt` and the substrate every grid
diagnostic reads; its `show`-form is the **hyperperiod chart**, exact because
the gate is pure modulo arithmetic (the pattern repeats with `lcm(Dᵢ)` base
ticks — one hyperperiod is the complete truth, not a sample), guarded against
absurd hyperperiods.

**Spec.** [§9.1][s9-1], [§9.2][s9-2], Appendices B/C

**Rationale.** The refusal path's suggestion message and the derivation path's
info line share one substrate: coarsest admissible `Δt_base`, the admissible
set `gcd(pool)/k`, **leave-one-out refinement factors** `r_p = gcd(pool ∖
p)/gcd(pool)` with every `r_p > 1` listed (joint responsibility is the honest
answer), **prime attribution** of `1/Δt_base`'s factors to the pool entries
supplying them (pinpointing exactly what an edit changed), and — when an offset
drives — the nearest non-refining alternatives on the grid the rest of the pool
supports, turning the diagnostic into a repair; the derivation path, the one
place refinement happens silently, always prints the derived value with drivers
and carries the single new advisory **`GridUtilization`** (warning (service),
deployment binding, derivation path only): `min_i Dᵢ` reported as "grid is N×
finer than the fastest declared work" with drivers named — information, never a
scold, a scope deliberately declared finer than its fastest member to buy
stagger room legitimately inflating the metric; no new error kinds,
`DeploymentInvalid` covering refusal and non-dividing anchors.

**Rejected.**
- *The simple-fraction-of-its-period offset test as the engine's warning:*
  authoring guidance only — demand is relational: `τ = T/10` can cost nothing
  and `τ = T/15` cost 3× against the same pool, so blame is computed against
  what is actually declared.
- *Threshold warnings on the refusal and declared paths:* the design already
  creates the right moments — the suggestion message is guaranteed an audience,
  the build refusing to proceed without it.
- *Crowning the single largest refinement factor:* leave-one-out honestly
  fingers *joint* drivers — in the companion's worked case the innocent-looking
  anchor, not the offset, is the larger marginal one.

### D-188 — Construct `TrimProblem` by keyword everywhere

**Status.** ratified

**Position.** `TrimProblem` is constructed by keyword everywhere: the `at` lift
rewritten from the seven-argument positional form to the keyword spelling
[§14.7][s14-7]'s worked example already uses.

**Spec.** [§14.7][s14-7], [§14.9][s14-9]

**Rationale.** So the type's own constructor honors the rule [§14.7][s14-7] states for
decisions and residuals — the names are the pairing, order carries no
semantics.

**Rejected.**
- *Keeping the positional lift:* `lower`/`upper` are adjacent and same-typed,
  silently swappable — precisely the hazard [D-074][d-074] rejected positional
  signatures for on the argument side, and the spec was arguing against its own
  code sketch.

### D-189 — Unify `report!` on a single `(address, diagnostic)` shape

**Status.** ratified

**Position.** `report!` regains a single shape, `report!(address, diagnostic)`:
the diagnostic is always a constructed value and the first argument is the cell
address — the device handle inside the task, the roster entry in [§12.4][s12-4]'s
pre-spawn init bracket, where no handle exists yet.

**Spec.** [§11.6][s11-6], [§11.8][s11-8], [§12.4][s12-4], [Appendix B][sB], [Appendix C][sC]

**Rationale.** The address supplies the device identity, which is why no call
passes a device id even though [Appendix C][sC] lists it in both payloads; [D-160][d-160]'s
definition and [Appendix B][sB]'s handle-capability listing stand unchanged.

**Rejected.**
- *Renaming the framework-internal form:* treats one operation — write a
  device-attributed diagnostic into that device's [§11.8][s11-8] cell — as two, when only
  the addressing differs.
- *Keeping the kind-first positional form `report!(DeviceCrash, dev, e)`:* a
  bare type in argument position beside the constructed-value form every other
  site uses, and one name owning two unrelated signatures — the polysemy [D-122][d-122]
  legislates against.

### D-190 — Reject a separate `derivative_type` declaration

**Status.** ratified

**Position.** No `derivative_type` declaration: `Ẋ` has `X`'s shape at the
activation scalar.

**Spec.** [§7.1][s7-1], [§9.5][s9-5]

**Rationale.** Derived from the closed leaf vocabulary ([D-094][d-094]) and the
build-time flat layout — derivative completeness is a property of the layout,
checked structurally at [§9.5][s9-5] (each field of `f`'s return scatters into its
field's block at `T`), never of author discipline.

**Rejected.**
- *A per-leaf `derivative_type` override hook:* a second source for a fact
  the layout already knows — the two can disagree, and the disagreement has no
  adjudicator; the case that would motivate it, a leaf whose derivative lives
  off its own type, is exactly what [D-094][d-094]'s closed vocabulary excludes.

### D-191 — Defer, not consume, the edge on a blocked event

**Status.** ratified

**Position.** Blocked-event edge mechanics (completes [D-154][d-154]'s serialization;
P3.2 chapter-8 rewrite finding): **blocking defers the edge rather than
consuming it** — an eligible-but-blocked event is the one exception to the
every-round overwrite of its last-observed sample; the sample stands, so a
guard still holding next round fires on the same unconsumed edge (re-decision
satisfied, against the post-transition sweep), while one the transition
falsified records not-holding normally and any later re-rise is a fresh edge.

**Spec.** [§10.6][s10-6]

**Rationale.** Prior honesty is preserved for free — the quiescent round fires
nothing, hence blocks nothing, so every sample takes its final update and
[§10.6][s10-6]'s unconditional prior update stands; firing counts untouched (they track
firings, not eligibility); the restored round-loop sketch carries the corrected
update line.

**Rejected.**
- *The unconditional `last ← now` refresh (the removed sketch's line):* the
  verifier's HIGH-severity finding — a blocked event whose guard keeps holding
  presents holding → holding next round and never fires — "blocked, not lost"
  rendered inert in executable form.
- *Marking the blocked event for unconditional firing next round:*
  fire-on-falsified-premise reborn — the defect [D-154][d-154] exists to kill — and the
  [D-153][d-153]/[D-181][d-181] deferral shape: a firing manufactured from bookkeeping rather
  than decided against a fresh sample.
- *An explicit pending flag with re-decision:* behaviorally identical, pays a
  fourth register and abandons eligibility-is-always-an-edge.
- *Reading "re-decided" as premise-recheck only:* the other horn of the flagged
  tension — quietly loses the still-holding blocked event, contradicting the
  blocked-not-lost promise.

### D-192 — Let the greedy claim empty the harness remainder

**Status.** ratified

**Position.** A rostered greedy claimant empties the harness writer's derived
surface: the greedy claim wins and the harness surface genuinely goes empty, so
every `stage!` in such a session is rejected at staging with `ClaimedFaceEntry`
naming the incumbent — already-specified behavior, not a new diagnostic.

**Spec.** [§11.3][s11-3]

**Rationale.** The precedence is an *implication* of the claimed-versus-derived
distinction [§11.3][s11-3] already draws, not a new rule: the greedy claim is a **rostered
claim** whose computed source is exhausted at the attach point, while the
harness writer's surface is the **derived** complement of the rostered claims
— the faces no rostered device speaks for. A rostered greedy claimant therefore
leaves that complement empty by construction. The harness writer exists for
script and test sessions without an interactive claimant, and a `stage!`
rejected in a GUI session with `ClaimedFaceEntry` is informative, not broken;
[§11.6][s11-6]'s `EmptyGreedyClaim` covers greedy-vs-greedy only and wants no companion
here. Escape hatch on the record: a user who wants a non-empty harness surface
alongside the GUI attaches the GUI under a non-greedy (returned) binding — the
design already allows it, the same GUI device type being equally attachable
under a binding that returns explicit claims ([§11.6][s11-6]). Greedy-last attach is the
idiom, computed claims staying exhausted at attach: attachment order is
decisive by design.

**Rejected.**
- *Harness-first subtraction — subtract the harness remainder before computing
  the greedy complement:* it would make the derived surface behave like a claim,
  and it breaks greedy's purpose — everything unclaimed, without configuration.
- *Recomputing computed claims at roster changes:* contradicts
  exhaustion-at-attach — past the attach point nothing downstream can tell a
  computed claim from a returned one — and the frozen-surface doctrine.

### D-193 — Keep per-writer liveness on one timestamp plus task state

**Status.** ratified

**Position.** Per-writer liveness keeps the diagnostic cell's **single** atomic
heartbeat timestamp ([§11.8][s11-8]'s mechanism untouched); the published per-writer
status gains `task_state`, read by the loop from its own device `Task` handles
at publication; [§12.2][s12-2]'s "last-staged and last-read wall time" split is dropped.

**Spec.** [§11.8][s11-8], [§12.2][s12-2]

**Rationale.** [§11.8][s11-8] gives each cell a bounded accumulation plus one atomic
liveness timestamp the device task stores on every loop pass, while [§12.2][s12-2]'s
published status promised "last-staged and last-read wall time, task state" —
two timestamps plus a task state that a single store-on-every-call timestamp
cannot produce. Only one of the three is a genuine cell field: the loop already
owns the device `Task` handles and can read their state where it publishes, so
`task_state` costs the cell nothing. [§12.2][s12-2]'s "the per-writer cell and nothing
besides, specified in full by [§11.8][s11-8]" is qualified to admit those handles.

**Rejected.**
- *The two-timestamp decomposition — a three-field liveness record in the cell,
  staged and read separated:* its signal is weakest exactly where it would fire,
  a rare-data device legitimately parked in a blocking read showing a stale
  last-staged (the case [§12.2][s12-2]'s loose 2 s threshold exists to tolerate), and it
  grows the cell [§11.8][s11-8] deliberately keeps minimal.

### D-194 — Retire the `w` channel: intermediates are declared ports

**Status.** ratified

**Position.** The private `w` channel is deleted on both tiers. Every output
stage returns its port NamedTuple alone, and a cross-stage intermediate is an
ordinary declared port, reaching its consumers through the existing views.

- The `(y, w)` return form, the one-hop law, the explicit re-return idiom and
  the `w` bundle field are retired; stage returns are `y`, period.
- An intermediate a later function needs is declared in `output_types` and
  read where the bundle law already delivers it: stage-1 products through
  `y_x`, everything through `y` in `f`, `g`, guards and handlers.
- Round fusion ceases to be a design constraint on the executor ([§9.7][s9-7]):
  passes communicate only through the table and the stores, no value crosses
  a phase-body or chunk seam, and the phase-body arities carry the tick index
  alone.
- `w`'s nominal-only conformance carve-out is retired with it: promoted
  intermediates carry declared types ([D-166][d-166]), embed-accept keeps the
  constant-branch idiom legal, and the [§9.5][s9-5] check covers them at every
  activation.
- `DeadStage`'s ground simplifies: a stage returning `(;)` produces no ports
  and is dead ([§9.3][s9-3]).
- Visibility stays binary and [D-034][d-034]/[D-055][d-055] stay closed: no `Private` level
  is added, the enclosing assembly's faces remain the scoping surface ([§8.6][s8-6]),
  the [§4.3][s4-3] granularity guideline (one struct-valued bundle port) remains the
  mitigation, and [D-034][d-034]'s `Private(T)` fallback-on-record remains the door.
- The workspace and the handler return law are untouched: `ws` is the
  mutable-scratch channel ([§7.3][s7-3]), handlers return stores ([D-090][d-090]).

**Spec.** [§4.2][s4-2], [§4.3][s4-3], [§5.2][s5-2], [§5.3][s5-3], [§5.4][s5-4], [§8.3][s8-3], [§9.1][s9-1], [§9.3][s9-3], [§9.5][s9-5], [§9.7][s9-7],
[Appendix B][sB], [Appendix C][sC], [Appendix D][sD]

**Rationale.** `w` served two needs, and each is served better without it.
Recomputation avoidance is the table's existing job: evaluating the RHS means
running the sweep ([§5.3][s5-3]), so `f` always reads cells its own sweep just wrote,
and a stage-1 product reaches stage 2 as `y_x` — freshness by the same
ordering that makes the table sound everywhere. Privacy had no demonstrated
customer: the FlightCore lineage record is that intermediates were only ever
inspected by inclusion in the model output, which [D-165][d-165] itself recorded as the
promote-to-output inspection path.

What [D-165][d-165] could not see, and the kernel prototype's increment-3 design work
surfaced, is where the SSA hand-off lands: the one-hop pairs span phase
bodies, so `w` must thread through the [§9.7][s9-7] roster's call signatures and every
chunk seam between producer and consumer, round fusion hardens from
optimization into obligation, and under [§10.5][s10-5]'s gating a not-due producer
forces `Union`-shaped slots into the boundary walk's collections. That is
framework-special handling concentrated in the executor's hottest structure,
purchased for a conformance check that runs at the nominal activation only —
probe-observed types having no anchor off-nominal. A declared port rides
machinery that already exists, is already measured, and is checked at every
activation.

Simulink is corroborating precedent: S-Functions share expensive intermediates
through engine-ordered work vectors (`DWork` written in `mdlOutputs`, read in
`mdlDerivatives`, fresh at every minor step by call order — the same
sweep-precedes-`f` argument), and block diagrams publish every intermediate as
a subsystem-scoped signal. No private inter-method channel exists there.

**Rejected.**
- *Keep `w` (the [D-165][d-165] position):* the threading cost above; a whole second
  dataflow vocabulary (return law, hop law, bundle-presence rule,
  probe-observed conformance regime) for values the table can carry.
- *Auxiliary stateless leaf as the mechanism (assembly refactor):* forced
  decomposition taxes the common case, and with `y` withheld from `f` a
  component's own state-derived intermediate would round-trip through
  external wiring to reach its own `f`. Remains available as an ordinary
  modeling choice.
- *Cells with probe-observed types (declaration-free):* [D-165][d-165]'s type-sourcing
  objection stands unweakened — the probe observes one branch, so the cell
  type detonates branch-dependently at non-nominal activations.
- *`Private{P}`-tagged output entries:* re-litigated here and kept closed;
  [D-034][d-034]'s no-demonstrated-customer ground and the central binary
  visibility rule survive, [D-055][d-055]'s "first wrapper type" ground has expired
  ([D-185][d-185]'s `Relative`/`Absolute`), and the fallback stays on record.

### D-195 — Give the discrete state its own letter `s`

**Status.** ratified

**Position.** The discrete state un-fuses from `x` into its own letter `s`;
[D-173][d-173]'s `z` retirement stands untouched — bare `z` still means only the shift
operator `z⁻¹`.

- The discrete-tier names re-split: `h_x`/`h_xu` → `h_s`/`h_su`, `init_x` →
  `init_s`, `y_x` → `y_s`, bundle field `x` → `s`, `x⁺ = g(x,u,t)` → `s⁺ =
  g(s,u,t)`; the continuous tier keeps the `x` family, and `f`/`g`, `m` and
  `Δt` keep their meanings.
- The per-function-per-tier closed bundle-name sets become per-function closed
  sets again: the two tiers' name families are disjoint by construction.
- The wrong-letter error class [D-173][d-173] retired rejoins
  `DeclarationOnWrongTier`'s member set — a discrete leaf declaring `h_x`, or
  a continuous one declaring `h_s`, is statically diagnosable again.

**Spec.** [§3.2][s3-2], [§5.2][s5-2], [§5.3][s5-3], [§7.3][s7-3], [§8.2][s8-2], [§8.7][s8-7], [§9.3][s9-3], [§9.5][s9-5], [§12.5][s12-5], [§13.7][s13-7], [§14.1][s14-1], [§15.2][s15-2], [§15.5][s15-5],
[Appendix A][sA], [Appendix B][sB], [Appendix C][sC], [Appendix D][sD] (all companions swept)

**Rationale.** [D-173][d-173] correctly retired `z` but recycled the continuous letter,
erasing a real distinction: the discrete state is a different object — no
derivative, any isbits type (pinned, eltype-generic or mixed), latched between
ticks, stored in per-component state stores where the continuous state lives in
the flat buffer ([§9.1][s9-1]) — and one letter made leaf declarations and framework
prose read as one mechanism where the engine holds two.

[D-173][d-173]'s "every candidate letter is taken" premise has since emptied for `s`:
the Laplace variable appears nowhere in the spec — the document's only
transform-domain symbol is `z⁻¹` — and `s` carries unique positive precedent,
being legacy FlightCore's own discrete state field (`Model.s`), which [§12.5][s12-5]'s
consumer survey already quotes as `x`/`s`; the migration ([§16][s16]) reads the legacy
vocabulary back rather than introducing a third letter. The "doubled API"
objection is nominal, not per-leaf: a leaf is strictly one tier ([D-056][d-056]) and
still implements exactly one name family, and the doubling buys back the
wrong-letter diagnostic. The hybrid-systems `x⁺` convention [D-173][d-173] leaned on
models a single state that both flows and jumps; the framework's tiers are
disjoint ([D-056][d-056], [§3.2][s3-2]), so its premise never applied here. [D-173][d-173]'s
`is_discrete` rejection is untouched — the arity-is-the-tier doctrine survives
with the letters split.

**Rejected.**
- *`w`:* free in current text since [D-194][d-194], but permanently means intermediates
  in the log's lineage ([D-165][d-165], [D-169][d-169], [D-194][d-194]) — reuse would make one letter
  mean two things across the log's history; reads as process noise/disturbance
  in the state-space literature; prefix near-miss with the `ws` workspace
  field.
- *`d`:* `D` is already the compiled sample-rate divisor ([§8.7][s8-7], [Appendix D][sD]) and
  the feedthrough matrix in `linearize`'s return, `d` the trim decision vector
  ([§14.7][s14-7]); differential-operator reading, flagged by [D-173][d-173] already.
- *Keeping the fusion:* the collision argument that motivated it was against
  `z`, not for `x` — with a clean letter available, the shared letter's only
  remaining yield is the halved name count, which per-tier disjointness makes a
  diagnostic asset instead.

### D-196 — Rename the phase-body sweeps to stage-numbered names

**Status.** ratified

**Position.** The phase-body roster's sweep blocks rename `sweep_hx` →
`sweep_1` and `sweep_hxu` → `sweep_2`; arities, entry sets and the roster's
other members (`rhs`, `ticks`) are untouched.

**Spec.** [§9.7][s9-7], [Appendix B][sB], [Appendix D][sD]

**Rationale.** Post-[D-195][d-195] the `hx`/`hxu` spellings read as
continuous-tier-only, but each sweep is a genuinely tier-mixed body — one
block whose entries mix `h_x`/`h_s`, the other `h_xu`/`h_su`. The stage number
is the tier-neutral fact ([§5.3][s5-3]), so the names state it.

**Rejected.**
- *Keeping the fused spellings:* quietly re-fuses the letter [D-195][d-195] split, in
  the one place a reader meets both tiers inside a single compiled block.
- *Per-tier sweep pairs (`sweep_hx` + `sweep_hs`):* would split the execution
  structure to serve a name — the single topologically-ordered body per stage
  is the design.

### D-197 — Reject discrete stores in linearization's `x`-tap list

**Status.** ratified

**Position.** `linearize`'s `x`-tap list resolves against the continuous
tier's `init_x` stores only; a tap naming a discrete store is a
tap-resolution error carrying the offending entry and its tier. Trim's
`get_state` reads stay tier-spanning ([§14.7][s14-7]). The recorded sampled-data step
map extension, when built, adds a distinct `s`-tap list rather than
widening the `x` list.

**Spec.** [§14.10][s14-10]

**Rationale.** The frozen-discrete doctrine ([§14.10][s14-10]) already fixes the
semantics: a discrete leaf is frozen with zero partials in the one seeded
pass, so an admitted discrete `x`-tap could only yield zero rows and columns —
manufacturing a spurious zero eigenvalue the plant does not have. This is
[D-167][d-167]'s no-silent-zeros principle at another site: like the declaredly
unseedable slot chosen as a `B`-matrix tap, the tap is rejected at resolution
rather than silently yielding zeros, and the error's next-move guidance points
at the step map $\Phi$, the object whose differentiation the author actually
wants. Under the fused letter the question was decided by spelling accident —
"validated against `init_x`" admitted both tiers silently; [D-195][d-195]'s split makes
the rule stateable, and gives the future extension its own list with named
Jacobian blocks $\partial(x^+, s^+)/\partial(x, s)$.

**Rejected.**
- *Admitting discrete taps with zero partials:* silent zeros in `A` —
  precisely what [D-167][d-167] refused for the `B` column.
- *Building the $\Phi$ extension now:* reopens a recorded-not-built decision
  ([§14.10][s14-10]) nothing in the migration needs.

### D-198 — Promote the shutdown join timeout to a deployment keyword

**Status.** ratified

**Position.** The shutdown tail's join cap becomes `join_timeout`, a
`Simulation` deployment keyword — a positive real in seconds of wall clock,
defaulting to the 5 s the constant fixed — operational rather than
trajectory-determining, hence outside the trace header's deployment block and
invisible to replay ([§12.4][s12-4](5), [§11.5][s11-5], [§12.7][s12-7], [Appendix B][sB]). This amends [D-133][d-133]:
its semantic/operational split and its other three fixed constants stand.

**Spec.** [§12.4][s12-4], [Appendix B][sB]

**Rationale.** [D-133][d-133]'s disposition for the semantic constants — budgets and
tolerances are deployment, not implementation — reaches the join cap once a
customer for varying it exists, and the framework's own test battery is one:
exercising the abandonment path under the fixed constant costs 5 s of wall
clock per run. Deployment contexts legitimately differ in patience — an
unattended sweep wants to fail fast, a hardware rig with slow teardown may
warrant more — and the recorded 5 s rationale (generous for GUI teardown and
socket closes, short enough to read as a diagnosed timeout) was always the
default's rationale, not an argument against the knob. The promotion is weaker
than the semantic constants': by the time the join begins, the final snapshot
is published and the stopped status set, so the cap cannot move a trajectory
and stays replay-blind, the `log_max` disposition ([§11.2][s11-2]). One value for the
whole tail: the join loop has one patience.

**Rejected.**
- *Superseded position — the join timeout as an operational constant with no
  user knob ([D-133][d-133]):* the gap [D-133][d-133] closed was ownership, not configurability;
  with an owner and a default in place, refusing the knob lost its rationale
  the moment a concrete customer appeared.
- *A `run!` keyword:* the cap is a property of the deployment context —
  interactive against unattended — not something varied run to run, and the
  constructor is where every other framework knob lives: one home, one
  validation site.
- *A per-device cap (an `attach!` keyword):* the join loop has one patience,
  and a per-device cap has no customer.

### D-199 — The `reads` enumeration returns a labeled NamedTuple of selectors

**Status.** ratified

**Position.** `reads(b)` returns a NamedTuple of [§14.4][s14-4] selectors,
`(; label = get_output(…), …)`: the labels are the binding's own naming, they
ride through the compiled gather in declaration order, and they key the
NamedTuple `map_output` receives ([§11.2][s11-2], [§11.6][s11-6]).

**Spec.** [§11.2][s11-2], [§11.6][s11-6]

**Rationale.** [§11.6][s11-6] fixed what `map_output` receives — a labeled NamedTuple —
without fixing where the labels come from, and the gather cannot be compiled
without that answer. Making the enumeration itself the labeled value closes
the gap with what the interface already has: one returned value carries
names, order and reads together, the enumeration stays self-describing under
the same attach-time validation as `claims`, and the binding author names
their own wire vocabulary instead of inheriting path-derived names that would
change under substitution.

**Rejected.**
- *Selectors carrying their own labels (a label field per selector):* the
  label is the binding's naming of its wire datum, not a property of the
  read; attaching it to the selector puts two facts in one value and makes
  the same selector unshareable across bindings.
- *A parallel label list beside a selector tuple:* two sequences pairing by
  position is exactly the drift a single labeled value refuses — names and
  reads can disagree in length or order with no check to catch it.

### D-200 — The harness writer has its own cell and is diagnostic only

**Status.** ratified

**Position.** [§11.8][s11-8]'s cell roster has three writer classes: one cell per rostered device, one for the harness writer, one for the loop itself. The harness writer's staging diagnostics — `ClaimedFaceEntry`, `EntryTypeMismatch`, and the no-such-face `OutOfClaimEntry` ([§11.4][s11-4]) — are written into its cell on whichever task stages; its record rides the published status with no heartbeat and no `task_state`. This amends [D-136][d-136]: its mechanism, bound and drain stand, and the writer enumeration gains the harness writer.

**Spec.** [§11.8][s11-8], [Appendix D][sD]

**Rationale.** The enumeration followed the writer list — device tasks and the loop — but the harness is a third writer: `ClaimedFaceEntry` is harness-only by definition ([Appendix C][sC]), and a harness `stage!` runs on whatever task calls it — the calling task, a script, the GUI — which is neither a device task nor the loop. Without a cell of its own, those diagnostics have no home with the channel's bound and drain, and would fall back to an unbounded synchronous stream invisible to every status reader. The single-writer ownership argument relaxes for this one cell exactly as it already does for the harness staging cell: several tasks may stage concurrently, and the same CAS append arbitrates — no lock, no new primitive. Attribution is unchanged: the cell supplies the writer identity, and the status discriminates a staging rejection from a loop degradation by record.

**Rejected.**
- *Folding harness staging diagnostics into the loop's cell:* the writers are the staging tasks, not the loop — the loop is the channel's reader — and the merge would misattribute staging rejections to the loop's own degradations.
- *A synchronous warning at staging, outside the channel:* unbounded under a flooding stager, invisible to status readers, and a second presentation path where the design has one record.
- *One cell per staging task:* the writer identity that matters is the surface, not the task, and per-task cells would multiply drains for no attribution gain.

### D-201 — The terminal account closes at the final frame top

**Status.** ratified

**Position.** The terminal snapshot's diagnostic account is complete up to its own frame top, and diagnostics arising after it are presented, never published: the loop sweeps every cell once more at the run's end — so nothing leaks into the next run's account — and emits the residue through the standard logging backend, with `DeviceJoinTimeout`, which arises in tail step (5) by construction, emitted the same way ([§12.4][s12-4], [§11.8][s11-8]). This amends [D-136][d-136]'s completeness claim by one window: complete means complete to the final frame top.

**Spec.** [§11.2][s11-2], [§11.8][s11-8], [§12.4][s12-4], [§13.2][s13-2], [Appendix C][sC]

**Rationale.** The tail's ordering is normative — the final snapshot is published before the sticky status precisely so consumers can flush the true final state — so a join timeout postdates the run's last publishable value by construction, and a cell entry written after the final frame-top drain has no later drain to fold it. The window cannot be closed, only disposed of honestly: the run's-end sweep guarantees a bounded, attributed presentation and a clean next run, while every published status stays exactly what [§11.8][s11-8] promises — delta plus totals as of that boundary.

**Rejected.**
- *A post-tail terminal publication carrying the residue:* publication follows a boundary sequence ([§10.3][s10-3], [§11.2][s11-2]); a snapshot no boundary produced would be a second kind of published value, bought for a warning.
- *Holding the residue in the cells for the next run's status:* totals count since the run began ([§11.8][s11-8]), so the previous tail's events would be misattributed to the new run — and an unattended session's final run would still never surface them.
- *Dropping the residue silently:* a bounded diagnostic channel that loses its last entries fails its own charter.

### D-202 — Stage batches as values plus touched-mask, never union tuples

**Status.** ratified

**Position.** The batch a staging cell holds is a pair of positional tuples
over the claim set: a concretely typed values tuple `Tuple{T₁, …, Tₙ}` and a
parallel `Bool` touched-mask, with untouched positions carrying placeholder
values that the mask guard keeps dead. This amends [D-104][d-104]: its coalescing
policy, `stage!`-side normalization, staging-sited diagnostics and
schema-in-roster-entry all stand; only the batch's carrier changes, from the
`Union{Nothing,T}` positional tuple to values-plus-mask.

**Spec.** [§11.4][s11-4], [§11.5][s11-5]

**Rationale.** The union carrier falsifies [§11.4][s11-4]'s own drain guarantee. Its
per-element unions are isbits, but the batch *type* is not concrete: tuple
types are covariant and `Nothing` is a zero-size singleton, so each combination
of touched faces is its own concrete type with its own memory layout. The
frame-top scatter then cannot be compiled once at attach — applying a batch
dispatches on which faces it touched, every never-seen combination compiles a
fresh specialization inside the frame (milliseconds, against a 2ⁿ pattern
space), and even the warmed path boxes per drain. Width adds a second cliff:
past 32 faces the positional merge leaves Julia's small-tuple path for a
type-unstable, allocating fallback. Values-plus-mask restores one concrete
isbits layout per writer: one scatter specialization compiled at attach,
element loads as direct field reads, and a drain measured allocation-free at
200 faces regardless of sparsity pattern (prototype, 2026-08-26). The recorded
costs: every staged batch is claim-set-wide, so a sparse stage on a wide writer
allocates the full-width cell box (only the greedy writer's width approaches
the root's, and staging already pays one allocation per stage); and untouched
positions need a constructible exemplar, which the declaration's probe values
already supply.

**Rejected.**
- *Superseded position — the `Union{Nothing,T}` carrier ([D-104][d-104]):* the marker
  rides in the value, which reads directly, but the non-concrete batch type
  turns the drain into runtime specialization and boxing; the pattern-JIT
  stalls surface only under a wide writer varying its touched set, the exact
  migrated-GUI configuration.
- *Keeping the union carrier and dispatching the scatter on the cell's `Ref` (a
  concrete type):* kills the per-pattern compilation but not the boxing — with
  no uniform layout, every touched element's load takes the generic field path;
  a half-measure that would still need replacing.
- *In-band sentinels per slot type (`NaN` and kin) instead of a mask:* collides
  with legitimate levels and does not exist for every declared type; the mask
  is out-of-band by construction.
- *Precompiling every sparsity pattern at attach:* 2ⁿ specializations;
  unpayable beyond toy widths.

### D-203 — The termination record carries typed sources and the tail residue

**Status.** ratified

**Position.** The run's termination record is a three-field value — the final
boundary time, absent when no boundary ever ran; a typed source; the tail
residue — and this amends [D-201][d-201]'s disposal clause: the run's-end sweep folds
the residue into the record *and* presents it through the logging backend,
still never published. The bundled rulings:

- The sources follow the diagnostic kind convention — kind is identity,
  payload plain data ([§13.2][s13-2]) — without joining [Appendix C][sC]'s diagnostic set:
  `EndTimeReached` (no payload), `ModelRequestedStop` (the holding face),
  `ControlRequestedStop` (its issuer), and `LoopError` (the propagated
  cause). The record covers `errored` exactly as it covers `stopped` ([§13.6][s13-6]).
- The operator interrupt stays a tag on an ordinary stop ([§13.5][s13-5]): the
  `:interrupt` issuer arm of `ControlRequestedStop`, never a fifth kind.
- The control-plane stop word carries its issuer — the requesting device,
  `:code`, or `:interrupt` — written by compare-and-swap from empty,
  first writer wins ([§12.1][s12-1]).
- `DeviceJoinTimeout` becomes an ordinary structured kind: written to the
  loop's own cell in tail step (5), collected by the run's-end sweep
  ([§12.4][s12-4], [Appendix C][sC]).
- Source consultation order is normative: a pending control stop at frame
  top, then `t_end`, then the stop faces at each publication — the recorded
  source of a boundary where two hold is the first in that order.
- `init!` clears the record with the trajectory ([§12.6][s12-6]).

**Spec.** [§11.8][s11-8], [§12.1][s12-1], [§12.4][s12-4], [§12.6][s12-6], [§13.5][s13-5], [§13.6][s13-6], [Appendix C][sC]

**Rationale.** [D-201][d-201] disposed of the tail window's diagnostics through
presentation because the termination record did not yet exist as machinery;
with it on the bench, presentation-only fails the unattended run — [§11.8][s11-8]'s own
audience for the terminal counters. Once `run!` returns, "did a device hang
the join?" was answerable only by whoever captured the log stream, and a
harness exercising the abandonment path had to scrape logs. The record is
none of [D-201][d-201]'s three rejected disposals, which all stand: it is not a
publication — it follows no boundary sequence and sits on no data plane — it
is not cell retention across runs (`init!` clears it with the trajectory), and
it is not a drop. It is stopped-sim state on the diagnostic-observation side
of [§13.5][s13-5]'s own doctrine, and the precedent of carrying failure detail was
already spent when the abnormal path put the cause exception in the record.
The typed sources apply [§13.2][s13-2]'s convention to the outcome channel, dissolving
a flat record whose `exception` field applied only to the error case and
whose `face` field only to the stop-face case; construction simplifies with
them, the loop returning a source where it detects one and the record
assembled once, in the outermost `finally`, after the sweep has the residue
in hand. Issuer attribution is nearly free: every stop site knows its
identity — the handle carries the device name, the interrupt is caught at a
known unmask point — and the anonymous `Bool` was discarding it at the moment
of writing; first-CAS-wins matches the first-`true` doctrine for stop faces
and names the request that actually initiated the tail. The residue stays
bounded by construction: one final ring take per writer, at most sixteen
entries plus suppressed counts. The record's cost is nil on any path that
matters — it is built once per run, on the cold side of the final snapshot.

**Rejected.**
- *Superseded position — presentation-only disposal ([D-201][d-201]):* honest but
  ephemeral; the tail's facts evaporated from the program at the moment it
  regained control. [D-201][d-201]'s rejected list never weighed the record, which
  had not been built when it was adjudicated.
- *A fifth source kind for the interrupt:* [§13.5][s13-5] rules the interrupt a tag on
  an ordinary stop — nothing failed; a consumer that cares matches on the
  issuer, and a distinct type would quietly reverse a settled ruling for no
  gain.
- *A flat record with `nothing`-padded per-source fields (the prototype's
  first cut):* the shape [§13.2][s13-2] rejects for diagnostics — most fields
  meaningless for most sources, tests matching on a `Symbol` instead of a
  type.
- *`Float64` time with `NaN` for "no boundary ever ran":* time is generic —
  the clock is seeded `zero(T)` ([§7.2][s7-2]) — and `NaN` is an in-band sentinel of
  the species [D-202][d-202] rejects; absence spelled out-of-band instead.
- *Carrying the configured `t_end` in `EndTimeReached`'s payload:* the
  effective policy already lives in the run metadata ([§11.5][s11-5], [§13.5][s13-5]); a second
  home for a fact that has one.
- *Termination sources as [Appendix C][sC] diagnostics:* the record is outcome, not
  warning — three of the four sources are healthy ends, and the interrupt
  sentence in [§13.5][s13-5] already ruled the appendix gains nothing here.

### D-204 — Rename the condition algebra's symmetric combinator to `combine`

**Status.** ratified

**Position.** The symmetric, collision-intolerant combinator over condition
nodes is `combine` (`combine(nodes...)`, node type `Combined`), no longer
`merge`. The rename applies forward — the spec and its companions sweep, the
log keeps its day's vocabulary ([D-064][d-064], [D-065][d-065]) — and the mixed-argument error
methods and `ConditionNodeMisuse` stay.

**Spec.** [§14.2][s14-2], [§14.6][s14-6], [§14.9][s14-9], [§16][s16], [Appendix B][sB]

**Rationale.** `Base.merge`'s documented contract is last-writer-wins — the
exact semantics [D-065][d-065] rejects for condition composition — so the shared name
promised the behavior the algebra prohibits, and [§14.3][s14-3] uses `merge` in the
Base sense (`merge(defaults, overlay)`) one section away: one identifier,
both contracts. Packaging admits no clean spelling either: a distinct
exported `merge` collides with `Base`'s binding at `using`, so shipping the
design meant extending `Base.merge` with methods contradicting its contract —
the piracy surface [§16][s16]'s exported-name audit had flagged. Under a fresh name
the fall-through to last-wins semantics is structurally impossible, and the
mixed-argument error methods become directive diagnostics rather than
essential insurance.

**Rejected.**
- *Keep `merge`, separated by dispatch:* the original position — dispatch on
  the node types keeps the two semantics apart mechanically. Dispatch
  separates the methods, not the contract: the name still promises
  `Base.merge`'s semantics to the reader, and the packaged spelling still
  pirates the generic function.
- *`compose`:* names the umbrella activity all three combinators share
  (fragment composition), not this operation's specific claim — the symmetric
  collection of siblings.

### D-205 — Boundary zero publishes every discrete output stage, due or not

**Status.** ratified

**Position.** At boundary zero every discrete component's output stages run
in the ordinary sorted walk, publishing from the authored `s` and the `t₀`
table, while `g` updates remain gated by `Φ` — an offset component's first
consumed sample stays its `Φ·Δt_base` tick's. No published cell holds the
probe's synthesized values (the `t₀` snapshot is the authored world, fully
evaluated); the ruling amends the boundary-zero consequence recorded in
[D-185][d-185], whose gate composition and residue invariant stand.

**Spec.** [§10.5][s10-5], [§14.5][s14-5], [§14.8][s14-8]

**Rationale.** The probe-seed residue was mechanism economy, not a modeling
claim: [D-185][d-185]'s gate at index 0, "implemented by nothing", left non-due output
cells holding [§9.3][s9-3]'s synthesized values, and the spec carried the consequence
as a caveat at both sites ([§14.5][s14-5]'s sweep bullet, [§14.8][s14-8]'s committed-residual
read-back). The residue leaked exactly the values [§14.6][s14-6]'s barrier keeps out
of the running world — a fabricated probe input is a fine shape exercise and
a terrible flight condition — and [§10.5][s10-5]'s content defense ("what a tick at
`t₀⁻` would have produced") held only in the build's own world, the probe
running before any condition exists. Publishing every output stage restores
tier symmetry (the interior sweep already evaluates every continuous output
at `t₀`), dissolves [§14.8][s14-8]'s caveat — the committed snapshot sits fully at
the solved point, the projection and handler movers aside — and retires the
virgin-table precondition wholesale: with every cell boundary-zero-written,
a warm restart has no stale-cell class to guard against. The accepted cost
is one off-grid output evaluation: an input-reading stage publishes from
`u(t₀)` at an instant not on its grid. That evaluation is establishment
under [§14.5][s14-5]'s charter — authorship replaces history — and a modeled startup
hole (a device dark until its first tick) is a modeling decision for a
validity flag or mode, never a framework default drawn from build plumbing.

**Rejected.**
- *Probe-seed residue — the prior position:* non-due cells holding [§9.3][s9-3]'s
  synthesized values until first tick. Mechanism economy with an
  anti-diagnostic default; the caveats it forced onto [§14.5][s14-5] and [§14.8][s14-8] are
  the record of its cost, and its `t₀⁻` story fails under any condition
  overlay.
- *State-only publication (`h_s` due-or-not, `h_su` still gated):* spares
  the off-grid sample but leaves the input-sampling stages — the ZOH
  archetype, the commonest offset shape — holding probe residue; buys
  little.
- *Authorable output cells:* would give the pre-first-tick value an owner,
  but outputs are derived data ([§14.1][s14-1]), and deriving them from the authored
  world is what the adopted rule does.

### D-206 — Rename root slots to root inputs

**Status.** ratified

**Position.** The write surface's member term is renamed: "slot" / "root
slot" / "root input slot" → **root input** ("the model's root inputs" where
prose flow wants it), sweeping the spec and its companions per the standing
rename rule — forward, never the log. Four API spellings follow:

- the condition fragment keyword `slots` → `inputs`
  (`fragment(; x, s, m, inputs)`);
- the table selector `get_slot(face)` → `get_input(face)`;
- the diagnostic kind `UninitializedSlots` → `UninitializedInputs`;
- the diagnostic kind `RootSlotTypeConflict` → `RootInputTypeConflict`.

**Spec.** [§4.1][s4-1], [§11.3][s11-3], [§14.2][s14-2], [§14.4][s14-4], [§14.6][s14-6], [Appendix C][sC]

**Rationale.** "Slot" was opaque coinage: it demanded a recall step on every
read, where "root input" decodes itself — and under [D-208][d-208] the definition
collapses to near-tautology (a root input is the root component's input
face), which is what vocabulary should do. The qualifier "root" carries the
real distinction against the input ports, faces and entries that exist at
every level. The bare spellings `inputs` and `get_input` are safe in their
scopes — nothing else in a fragment payload or the selector family could be
meant — and `get_input`/`get_output` gain symmetry, with the inherent
addressing asymmetry (face name vs structural path, [§11.3][s11-3]'s write-surface
rule) accepted.

**Rejected.**
- *Keeping "slot":* brevity was its only virtue; it never carried its
  meaning.
- *`get_root_input`:* precise but heavy in the selector family's naming.

### D-207 — Route every connection one level: faces are the only cross-boundary currency

**Status.** ratified

**Position.** Deep connection paths are removed: every endpoint in the three
wiring declarations addresses an immediate child (container elements
included) and one of its faces. Supersedes [D-009][d-009]. The bundled rulings:

- `child_connections` wires sibling faces, `input_connections` routes each
  face to immediate children's faces, `output_connections` sources each face
  from an immediate child's face — the generic-seam stop becomes the
  universal rule.
- The face graph is therefore total — every signal crossing an assembly
  boundary bears a declared face there — and the `Build` retains it, input
  side beside the output side, so per-level `at` addressing of a fragment's
  `inputs` payload resolves (amending [D-065][d-065]'s "deep `at` only within owned
  concrete subtrees" clause: a prefix stops at faces on every child, owned
  or not).
- Deep structural paths survive on the read side — inspection, logging,
  provenance — untouched.

**Spec.** [§6.1][s6-1], [§8.6][s8-6], [§8.8][s8-8], [§9.2][s9-2], [§13.3][s13-3], [§14.2][s14-2], [§14.3][s14-3]

**Rationale.** The deep-path privilege made the face graph structurally
partial: a root claim could cross intermediate boundaries without acquiring
a face at any of them, leaving those levels blind to the signals traversing
them — surfaced by the condition algebra, where
`at("sub", fragment(inputs = …))` had no name to resolve against, and
whether it could resolve depended on how an ancestor happened to spell a
route. The privilege had meanwhile lost most of its value to the design's
own growth: every level of a realistic tree is a generic seam ([§8.8][s8-8]), where
one-level routing was already mandatory, and the worked assemblies route per
level via `input_passthrough` and the single-authored feed list. Clarity and
symmetry outrank convenience: the residual ceremony has sanctioned computed
spellings ([§8.8][s8-8]), parallel routes proliferating through several boundaries
are the signal to gather them into a custom type, and convenience remains
recoverable a posteriori as sugar where clarity does not.

**Rejected.**
- *Deep paths within owned assembly types ([D-009][d-009]'s position):* the bypass
  is the one place structure leaks across a boundary [§8.3][s8-3] declares closed,
  and the partiality it induces in the face graph is invisible from a
  fragment author's seat.
- *Keeping deep paths, retaining the partial face graph:* fixes the
  literal `at` refusal; leaves resolvability an accident of ancestor
  spelling.
- *Bundled faces as the universal ceremony mitigation:* bundling serves
  component-fed signal highways; at a root input it collides with [§4.3][s4-3]'s
  write-side granularity and forfeits partial scripting ([§8.8][s8-8]).

### D-208 — Root inputs are the root component's input faces, whatever its class

**Status.** ratified

**Position.** The build accepts any component as root, and the model's root
inputs are the root's input faces uniformly. The bundled rulings:

- For an assembly they are its `input_connections` keys, each traced
  through the total face chain ([D-207][d-207]) to leaf input entries; for a
  primitive, its `input_types` keys directly — [D-172][d-172]'s kind-blind faces
  applied at the root.
- Types keep their derivation (the ultimate consuming entry at the
  activation scalar, [§8.2][s8-2]'s tight-bound rule; a primitive root's face is its
  own consuming entry), and [§8.2][s8-2]'s primitive-root refusal is retired.
- Abstract-at-root is unchanged: a primitive with an abstract input entry
  still cannot be built bare, and the component test rig ([§13.7][s13-7]) keeps its
  stubbing role, losing only its gate status.

**Spec.** [§8.2][s8-2], [§8.6][s8-6], [§9.1][s9-1], [§9.3][s9-3], [§11.3][s11-3], [§13.7][s13-7]

**Rationale.** The refusal existed because no rule made a primitive root's
unfed inputs root inputs; the uniform doctrine supplies one with no new
vocabulary, and the one-child wrapper it forced on leaf exercise added a
level of ceremony without adding information.

**Rejected.**
- *Keeping the assembly-only root:* with the doctrine uniform, the
  remaining justification was the rig idiom, which survives on its own
  merits.

### D-209 — Build `output_passthrough`

**Status.** ratified

**Position.** `output_passthrough` is promoted from guarded addition to
built helper (annotating [D-171][d-171]): the sibling of `input_passthrough`,
splatted into `output_connections`, reading `output_faces(child)` with the
same `prefix`/`sep`/`except`/`only` surface.

**Spec.** [§8.8][s8-8], [Appendix B][sB]

**Rationale.** [D-171][d-171] kept it guarded for want of a demonstrated consumer.
[D-207][d-207] supplies one: with deep sourcing removed, every level re-exports the
outputs it surfaces, and the output side needs the computed spelling the
input side already has.

**Rejected.**
- *Keeping it guarded:* the consumer has arrived.

### D-210 — Tighten the input boundary: class-uniform face uniqueness and no empty routing

**Status.** ratified

**Position.** Two input-boundary rules tighten, each completing a
consequence [D-207][d-207] and [D-208][d-208] left implicit. The bundled rulings:

- [§8.6][s8-6]'s face-name uniqueness invariant applies to the root component
  whatever its class: a primitive root's face set is the union of its
  `input_types` and `output_types` keys, and a key declared in both is the
  same build error a duplicate face name is. Non-root primitives are
  untouched.
- An `input_connections` entry routes to at least one internal endpoint:
  the empty tuple is a declaration error.

**Spec.** [§8.2][s8-2], [§8.6][s8-6]

**Rationale.** [D-208][d-208] made a primitive root's two contract declarations share
the periphery's face namespace for the first time, and the prototype's
conformance build showed what the gap costs: a primitive root declaring one
key in both declarations places two cells at one address, the root-input
placement silently overwriting the output port's. The repro authored
`u = 5.0`, the stage published `10.0`, and the root input read back `10.0` —
boundary-zero-ordered, and silent. An assembly root is protected by [§8.6][s8-6]'s
uniqueness invariant; a primitive root had no analogue. The empty routing
tuple is the same class of silence one level down: it contributes no
consumer, so it is invisible to the total face graph [D-207][d-207] requires ([§9.2][s9-2]),
and a condition addressing that face at a non-root level misdiagnoses as
"declares no input face" — byte-identical to the diagnostic a bare typo
earns. A face feeding nothing declares nothing.

**Rejected.**
- *Extending uniqueness to every primitive:* below the root a primitive's
  input faces alias their producers' cells and place nothing, so there is no
  addressable collision to forbid, and the rule would constrain leaf authors
  for nothing.
- *A sentinel entry in the face graph for a consumerless face:*
  representation for a declaration with no meaning, and the misdiagnosis
  survives in a new shape.

### D-211 — Let a component declare one container name-transparent

**Status.** ratified

**Position.** A component type may declare at most one of its container
fields **name-transparent** — the opt-in declaration
`transparent_container(::MyType) = :field` beside the connection
declarations, default `nothing` — and that field's elements are then
contributed as children under their bare keys: `"key"`/`"1"` in place of
`"field/key"`/`"field/1"`, everywhere a child name appears — wiring
endpoints, `sample_times` keys, read paths, `at` prefixes, diagnostics. A
bare key colliding with any sibling child name is a build error naming both.
`Group` declares its `children` field transparent, so its values address
their children directly — `"ctl/out" => "plant/u"`, `(ctl = Relative(2),)`,
`at("ctl", …)` — amending [D-085][d-085]'s naming clause and [D-184][d-184]'s
zero-new-declaration-rules framing; undeclared containers keep their key
segment exactly as before, [D-207][d-207]'s one-level reading unchanged.

**Spec.** [§6.1][s6-1], [§8.5][s8-5], [§8.6][s8-6]

**Rationale.** [§8.5][s8-5] already rules containers "transparent grouping, not
assemblies" — transparent in structure and contract, yet opaque in naming:
the field segment rides every child name. The segment earns its keep where
the parent mixes child sources or the roster name informs (`"aircraft/2"`);
it carries nothing where the container is the type's sole child source, and
`Group` is the extreme case — every child of every `Group` is
`children/<key>`, boilerplate on all three authoring surfaces at once:
wiring endpoints, rate keys (a slash-bearing key forcing the
`var"children/ctl"` spelling), and the whole read/address side
(`state(sim, "children/f/children/a")`, `at("children/ctl", …)`, every error
message). Under [D-207][d-207] the composite name also became grammatically
anomalous: a `Group` endpoint spells three segments where the rule reads
immediate child + face, indistinguishable on sight from the deep paths just
removed. With bare keys, a `Group`'s declarations are textually identical to
a named assembly's — the anonymous-beside-named promise made literal. The
declaration is opt-in with a collision check rather than a naming change,
keeping the informative segment where parametric rosters and mounting rely
on it; one transparent container per type keeps a bare name's provenance
evident, and nothing wants two.

**Rejected.**
- *Qualification inside `Group`'s accessors — the connection declarations
  prepending `children/` to what the author wrote:* zero framework change,
  but it cleans only the declaration surface and splits the namespace — the
  author declares `"ctl/out"` yet reads `"children/ctl/out"`, and build
  errors quote strings never written. One consistent composite name beats two
  inconsistent ones.
- *Dropping the field segment universally:* breaks the informative naming
  parametric rosters and mounting rely on (`"aircraft/2"`), and invites
  collisions in multi-container types with no opt-out.
- *Renaming `Group`'s field to something short (`c::C`):* shortens the
  boilerplate without removing it from any surface.
- *Sanctioning child discovery itself as an overloadable declaration:*
  strictly more power than the defect calls for — naming is the flaw;
  discovery stays structural.

### D-212 — Refuse the transparent bare key that shadows a sibling container field

**Status.** ratified

**Position.** Completing [D-211][d-211]'s collision family (annotating [D-211][d-211]): a
name-transparent element's bare key equal to the name of a sibling container
field that contributes children is a build error naming both parties, although
no child bears that name — the key shadows the container's `"field/key"`
segment grammar ([§6.1][s6-1]), leaving its elements unreachable behind a one-level
diagnostic that blames the wrong child. An empty field reserves nothing: it
reaches no children, its value cannot be told from empty inert parameter data,
and the judgment is per-instantiation, like every wiring judgment.

**Spec.** [§8.5][s8-5]

**Rationale.** Surfaced by increment 20's cold review: [D-211][d-211]'s collision check
compares the names children actually bear, and the shadow collides with none of
them — the build succeeded while the shadowed container's elements stayed in
the flat list yet became unreachable in wiring resolution, the one-level
rejection reporting them as reaching past the bare child and advising a route
through that child's faces. The empty-field exemption was settled the hard
way: uniform reservation was built first and immediately displaced the
instantiation-dependence onto inert fields, where the refusal is a false
positive — an empty `Tuple`/`NamedTuple` is an empty container and empty inert
parameter data at once, the value cannot tell them apart, and [§8.5][s8-5] keeps empty
containers legal precisely so parametric code needs no special case.
Per-instantiation legality is the norm, not a defect: every wire is validated
against the instance too.

**Rejected.**
- *Leaving it to [D-211][d-211]'s duplicate-name check:* it compares the names children
  bear, and the shadow collides with none — a grammar collision, not a name
  collision.
- *Reserving every empty `Tuple`/`NamedTuple` field's name (uniform refusal):*
  built and reverted within the increment — it refuses a bare key over inert
  data where no shadow exists (`Group`'s own empty `wires` beside a child
  named `wires`), trading a true per-instantiation refusal for a false one.
- *A better diagnostic only, admitting the shadow:* the ambiguity is real —
  one grammar answering for two children — and the same instinct as [§8.6][s8-6]'s
  face-name uniqueness invariant applies: ambiguity is refused, not
  documented.

### D-213 — Establish a service's frozen cells from the authored discrete state

**Status.** ratified

**Position.** A service's seeded scratch set takes its frozen discrete cells from a
nominal scratch set on which the composite condition has been applied and one
establishment round run — every discrete output stage, due or not ([D-205][d-205]), with
no projection, events or `g` — copied as zero-partial constants; the probe's
synthesized products never reach a service evaluation. Iterations remain raw
write → sweep → read cycles at the seeded activation ([§14.5][s14-5]).

**Spec.** [§14.8][s14-8]

**Rationale.** Surfaced while briefing the prototype's trim increment: the prototype
seeds every cell of a fresh store set from the build probe, and at a `Dual`
activation a frozen component's stages never run, so a scratch world's discrete
output cells were the probe's — an FCS command feeding a continuous actuator
would be a fabricated zero through the whole solve, a wrong residual with no
diagnostic. [D-205][d-205] removed that class from the published world, but its "no
published cell holds probe values" carried an unstated frozen-component
asterisk, and [§9.4][s9-4]'s "gated off holding `Float64` values" never said which
values. The nominal half answers it with machinery that already exists — the
dynamic walk and boundary zero's establishment sweep — at the cost of one
nominal store set and one sweep per invocation, noise against the solve. Both
halves die with the call, so the one-writer invariant is untouched, and the
zero-decision probe falls out as the nominal half alone.

**Rejected.**
- *Probe products as the frozen constants — the implicit prior position:* wrong
  numbers for any discrete producer upstream of the continuous dynamics, and
  [§14.6][s14-6]'s barrier rationale applies verbatim: a fabricated zero is a fine probe
  input and a terrible flight condition.
- *Running the discrete output stages at the seeded activation:* they would see
  a `Dual`, against [§9.4][s9-4]'s executable-set rule and [§8.2][s8-2]'s frozen-constant
  semantics; and it would invite discrete `s` decision variables whose partials
  the frozen tier cannot carry.
- *Seeding from the simulation's committed cells:* trim's scratch world is the
  composite condition, never the sim's stores ([§14][s14]'s lifecycle table) — the sim
  may be `built`, with no committed cells at all.

### D-214 — Split Appendix C's severity column into severity, raised and policy

**Status.** ratified

**Position.** A kind's severity, a property of the kind read as `severity(d)`, is
`error` or `warning`, nothing else.
[Appendix C][sC]'s former severity column, which braided seriousness with stage and
reporting policy, splits into three: **severity** (the kind's), **raised** (the
stage an occurrence surfaces in — `build`, `service`, `runtime` — with its
placement notes) and **policy** (how it is reported — `collected`, `fail-fast`,
`logged`, `rate-limited`). A kind raised at more than one stage lists each.

**Spec.** [§13.2][s13-2], [Appendix C][sC]

**Rationale.** Surfaced while briefing the prototype's diagnostic-carrier
increment: [§13.2][s13-2] says severity is a payload field from which the column derives,
but the column's vocabulary — `build (collected)`, `warning (service)`, `build
(fail-fast) at probe; runtime as a StepError species` — is not a value one field
can hold. Stage and policy belong to the occurrence: `BundleFieldError` and
`ConformanceFailure` are raised at the probe and again at runtime. Seriousness
alone is the kind's — whether an occurrence ever throws — and that two-way split
is what a test needs to know first. Stage and policy are independent facts with
vocabularies of three and four words, so they take a column each: the preamble
defines nine words instead of seven compound pairs, and the occupied cells of the
stage × policy grid fall out of the rows. `fail-fast` deliberately covers three
mechanisms — the build's phase abort, a service call's single throw, the runtime
`StepError` — because the policy is the same in each: the first occurrence
throws and nothing else is gathered. No kind currently needs two rows; the two
dual-stage kinds are fail-fast at both stages.

**Rejected.**
- *A stage or policy field on the kind, the columns mapping onto it:* falsifies
  the two-stage kinds, and puts a per-occurrence fact into a value that is data,
  not a throw site.
- *Severity as the braided vocabulary (a kind carrying `build_collected`):* the
  same objection, with the enum growing a value per stage × policy pair while
  the question tests ask is two-way.
- *One compound `raised` column holding stage-policy pairs:* seven values to
  memorize for what are three independent facts, some pairs valid for one
  severity only.
- *Dropping stage and policy, leaving them to the owning sections:* the table is
  the acceptance-test index; whether a test expects a thrown collection, a
  single throw, or a logged warning beside a return value is exactly what it
  has to know.

### D-215 — Extend Appendix C with the kinds the prototype raised

**Status.** ratified

**Position.** Seven kinds join [Appendix C][sC]'s closed set, and two vocabularies widen.

- Build, collected: `ChildNameCollision` (a bare container key against the
  `sample_times` sugar or a sibling field, or two children with one name),
  `TransparentContainerUnknown`, `TierUnreadable` (the tier twin of
  `ClassUnreadable`), `IllegalPortType` (the port twin of `IllegalStateLeaf`).
- Service, fail-fast: `ArgumentInvalid` (the twin of `DeploymentInvalid` for
  arguments that are not deployment parameters — `step!`'s, `trim!`'s,
  `TableBinding`'s, a period constructor's), `ReadSetMisuse` (the read
  side's twin of `ConditionNodeMisuse`), `NotAttached` (`detach!`'s mirror
  of `AlreadyAttached`).
- `UnknownPort`'s wire end admits `connection`, an interface-connection entry's
  internal side ([D-210][d-210]); `EventHalfMissing`'s reason admits an entry that is
  not an `Event`.
- Internal invariant checks are not diagnostics: they raise a distinct
  `InternalInvariant` exception outside the kind set.

**Spec.** [§13.2][s13-2], [Appendix C][sC]

**Rationale.** Surfaced by the site inventory for the prototype increment
retiring its string stand-in: 31 of its 144 refusal sites matched no [Appendix C][sC]
row, and [Appendix C][sC] makes adding a kind a decision-log entry. Most are
behaviors the log already rules without naming the kind — [D-210][d-210]'s empty route,
[D-211][d-211]'s and [D-212][d-212]'s child-name collisions — or twins of existing kinds on
another axis: class versus tier, state leaf versus port type, condition node
versus read selector, attach versus detach. The argument checks share one kind
because they share one payload shape — the call, the argument, the value, the
constraint — exactly as the deployment parameters share `DeploymentInvalid`.
An internal invariant has no fix for the user to be told; a kind for it would
put an unreachable check into the acceptance-test contract.

**Rejected.**
- *A kind per argument check (`StepArgumentInvalid`, `TableBindingInvalid`,
  …):* the row count grows with the API surface while the payload shape stays
  identical.
- *Folding `TierUnreadable` into `ClassUnreadable`:* a different axis —
  primitive-versus-assembly against continuous-versus-discrete — with a
  different list-in-hand.
- *Internal invariants as a kind:* a diagnostic states the user's fix; an
  invariant has none, and its row would be an untestable contract.
- *Leaving the unmapped sites as message-only errors:* the string stand-in
  reintroduced inside the increment retiring it.

### D-216 — Conform Appendix C to the prototype's diagnostic sites

**Status.** ratified

**Position.** The first increment to raise every refusal as a kind is Appendix
C's first test, and the table moves where the sites showed it wrong.

- `StopFaceInvalid` and `ClaimConflict` are collected — over the given faces,
  over the device's claim set — and `ArgumentInvalid` collects over a
  `TableBinding`'s entry table; they sit beside `DeploymentInvalid`, already
  collected.
- `AttachUnknownFace` and `ReadBindingUnresolved` name the device by type: a
  refusal that precedes admission cannot carry the roster id admission assigns.
- `ConditionResolution`'s payload lists what its sub-kinds differ by;
  `DeploymentInvalid`'s parameter list gains the run-shaping keywords
  (`join_timeout`, `log`, `log_every`, `log_max`, `t_end`);
  `BindingContractMismatch` gains the binding declaring neither side.
- `DeviceContractMismatch` joins the set: the device twin of
  `BindingContractMismatch` (no `loop` method; `gather` against a binding with
  no output side).
- Every other payload the prototype carries short of its column stays as
  written: the column is the design, and the prototype records its own gaps.
  A selector carried as its rendered spelling is licensed — [§13.2][s13-2]'s rule is
  against instances and model types, and a spelling is a string.

**Spec.** [§13.2][s13-2], [Appendix C][sC]

**Rationale.** The payload and policy columns were untested design claims
until a site had to construct each value. Three findings needed the table to
move rather than the code. A check that runs over a list — the stop faces
given, the faces a device claims, the entries of a table — is collecting by
its shape, and making it throw on the first would discard violations the pass
already holds, the cost [§13.1][s13-1] exists to avoid. An id assigned at admission
cannot be in a refusal that keeps the device out. A column narrower than the
sub-kinds it names cannot be the acceptance contract for tests that match on
those sub-kinds' payload. Everything else — the wires on an `AlgebraicCycle`,
the provenance on a `FaceNameCollision`, the shadowing notes, the binding site
of a stop face — is data the design wants and the prototype does not yet
gather; the column keeps naming it and the prototype's absence list carries the
shortfall until a later increment closes it.

**Rejected.**
- *Making the three service checks fail-fast to match the column:* throws
  away violations the pass already has, against [§13.1][s13-1]'s reasoning.
- *Reserving a roster id before admission:* an id for a device the roster
  never held, in every refusal's payload.
- *Shrinking every column the prototype falls short of:* the table would
  document the prototype rather than the design, and the shortfalls would
  stop being visible as such.
- *A datum naming no channel as a kind (`bindings.jl`'s third plain error):*
  it runs on the device task inside the author's mapping, so it reaches the
  framework as the wrapper's `cause` — `MalformedDatum` / `DeviceCrash`
  territory, not a kind of its own.

### D-217 — Conform the trace and replay sections to the prototype's record

**Status.** ratified

**Position.** The first increment to record a trace and replay it is [§11.5][s11-5]
and [§12.7][s12-7]'s first test, and the sections move where the mechanism showed them
short.

- The trace carries its length beside the header and the batches: the number
  of drains since the capture. A recording whose last frames drained nothing
  still ran them, and replay's frame budget is that count.
- The header's schema list only grows. Every capture and every roster change
  appends the current writer set, earlier records keep their index, and a
  record resolves only through its own schema entry.
- `ReplayUnknownFace` carries the bare position where the writer's schema has
  no name for it.
- The entry pass validates each batch's frame ordinal against the recording's
  length, as a `ReplayHeaderMismatch` discriminator, and the replay drain keys
  records to the frame exactly.
- `ReplayHeaderMismatch` and `ReplaySchemaMismatch` are collected.
- The header records the `t_end`/`stop_on` pair bound at construction. A run's
  effective bound is reported by its termination record when it fires.

**Spec.** [§11.5][s11-5], [§12.7][s12-7], [§13.5][s13-5], [Appendix B][sB], [Appendix C][sC]

**Rationale.** Positional records are meaningless without a schema, and the
header outlives a run: `attach!` and `detach!` are legal at every stopped
point between `init!` and the next advance ([§12.6][s12-6]), and a roster change
recompiles the harness writer against a new complement, so the same face
moves position. A schema list that only grows keeps every recorded index
valid without rewriting a record. The same positional shape is why an
unresolvable entry has no name to report. A frame ordinal the entry pass does
not check lets a hand-edited record apply at a frame not its own, silently,
and re-record as if it were; [§12.7][s12-7] promises exact ordinal keying, so the check
belongs with the other up-front ones. The two header kinds collect for [D-216][d-216]'s
reason: a check that runs over a list is collecting by its shape. The
termination pair is the one place the sections contradicted each other. [§11.5][s11-5]
captured "the effective pair" at `init!`, while [§13.5][s13-5] binds a `run!` override
for that run only, after `init!` and possibly several times per trace. The
header can only hold what `init!` knows, and the termination record already
names what fired: `EndTimeReached` carries the final `t`, `ModelRequestedStop`
the holding face. Replay neither compares nor applies the pair, so nothing
rides on it.

**Rejected.**
- *A mutable termination slot in the header, rewritten at every advance:* one
  slot holds one run's pair, and the header stops being a single-instant
  capture, which [§11.5][s11-5] relies on.
- *Moving the pair out of the header into the termination record:* the next
  run overwrites the record, so the pair would leave the one persistent
  artifact.
- *Rewriting recorded positions at a roster change:* the values are recorded
  and the positions are the index into a schema; a rewrite is a second record
  format.
- *A feed cursor that applies any record at or before the current frame:* it
  masks a stale ordinal by applying it late, and under a `to_boundary`
  truncation it would sweep every record past the cut into the last replayed
  frame.

### D-218 — Make the replay/live distinction an explicit input mode

**Status.** ratified

**Position.** A `Simulation` carries an input mode, `:live` or `:replay`, read
as `mode(sim)` beside its lifecycle state, and the one drain branch ([D-101][d-101]'s
second substitution) is driven by that mode.

- `replay!` attaches the recording and enters `:replay`. `step!` and `run!`
  consume it frame by frame from there, live staging taken and discarded
  (`ReplayDiscardedStaging`), devices running as readers.
- While the mode is `:replay` the recording is the bound: every advance's
  frame budget is capped at the recording's last frame, `to_boundary` capping
  it earlier, and the halt leaves the simulation `initialized`.
- The mode becomes `:live` exactly when a halt lands at the recording's end,
  the records exhausted, and stays `:replay` otherwise. `init!` and a fresh
  `replay!` reset it with the trajectory.

**Spec.** [§12.6][s12-6], [§12.7][s12-7], [§13.4][s13-4]

**Rationale.** [§13.4][s13-4] promises that after `replay!(sim2, trc; to_boundary = k)`
a `step!` re-executes frame k+1 on its recorded inputs. The promise needs the
recording to still have a consumer after `replay!` returns, which a mode
outliving the call supplies. [D-101][d-101]'s shape is untouched — one loop, one drain
branch, replay as the ordinary loop with two substitutions — and only what
selects the branch's source moves, from the incidental presence of a feed to a
register the caller can read. The recording as the bound is what keeps the
distinction honest across a halt: an advance never leaves the records behind
and keeps going, so every frame of a session is either record-driven or live,
and which one it was is readable before it runs.

**Rejected.**
- *The implicit switch — a feed present only while the replay call runs:* the
  feed is dismantled when the replay loop exits, so after a partial replay the
  record at ordinal k+1 has no consumer and the following `step!` runs a live
  frame with empty staging. [§13.4][s13-4]'s reproduction workflow then reproduces a
  different frame, silently.
- *Re-staging the halt-adjacent records into the live staging cells:* it needs
  a write path that bypasses the write-surface rule ([§11.3][s11-3]), recorded batches
  applying with no surface re-check, and it covers one frame only — the next
  advance is live again.
- *A silent mid-run flip to `:live` when the recording runs out:* one `run!`
  would change input source mid-call, and nothing the caller reads afterwards
  would say where the reproduction stopped reproducing.

### D-219 — Add a time-addressed replay halt and a manual door to live

**Status.** ratified

**Position.** Two additions to the replay surface, both serving one workflow:
replay to a chosen time, inspect the halt, then continue live from it.

- `replay!(sim, trc; to_time)` halts at the last frame top at or before
  `to_time`, `k = ⌊(to_time − t₀)/h⌋` against the header's `t₀`. It is
  mutually exclusive with `to_boundary` and validated the same way: real,
  finite, at least `t₀`, and within the recording, the refusal preceding every
  write.
- `live!(sim)` sets the input mode to `:live` and detaches the recording's
  remainder, touching nothing else. It is a stopped-sim operation, legal only
  on an `initialized` simulation in `:replay`; an already live one refuses.

**Spec.** [§12.6][s12-6], [§12.7][s12-7], [Appendix B][sB]

**Rationale.** The workflow is the interactive rewrite: interrupt at t = 110,
replay to t = 100, fly the last ten seconds again. [D-218][d-218] flips the mode to
`:live` only at a halt on the recording's last frame, which is right for an
unattended reproduction and wrong here — the caller wants the remainder
abandoned, not consumed. `live!` is the door for that, and it needs to touch
nothing but the mode: the trajectory stands at the halt, and the trace register
keeps the header it inherited, so the frames flown after the call append to the
re-recorded prefix and the session leaves behind one seamless recording of
itself. The time spelling exists because the caller of that workflow knows a
time, not a boundary index; the arithmetic that converts one to the other is the
framework's, and doing it by hand at the call site is where an off-by-one lives.
The refusals are loud rather than silent no-ops: a call that quietly did
nothing on an already live simulation would let a caller believe a recording was
dropped that was never attached. [D-218][d-218] is extended here, not superseded — the mode register and
its automatic flip stand exactly as ratified.

**Rejected.**
- *A `then = :live` keyword on `replay!`:* the decision to go live is made
  after inspecting the halt, not before it. A caller who could commit to it at
  the call site would not have needed the halt in the first place.
- *A symmetric `mode!(sim, mode)` setter:* `mode!(sim, :replay)` is meaningless
  with no recording attached, so half the setter's domain is an error message.
  The asymmetric verb says what it does.
- *`to_boundary` accepting a `Real` directly:* one keyword whose semantics
  depend on its argument's type, an integer counting boundaries against a float
  naming a time. A reader of the call site cannot tell which was meant without
  knowing what the variable holds.
- *Rounding `to_time` to the nearest frame top, or to the covering one:* the
  halt must stand before the anomaly, never on or past it. The asymmetry with
  `t_end`'s reach-or-exceed rule is the point of the keyword, not an
  inconsistency in it: `t_end` bounds a run, `to_time` positions an inspection.

### D-220 — Rename the authoring family to words: stage, update, projection, event and workspace declarations

**Status.** ratified

**Position.** The component-authoring family drops its single letters and bare
nouns for distinctive words; the spec's formulas keep `f`, `g` and `h` as
mathematical symbols.

- `f` → `state_derivative`, `g` → `state_update`.
- `h_x` and `h_s` → `output_state`; `h_xu` and `h_su` → `output_direct`. One
  pair of names serves both tiers, "direct" naming direct feedthrough.
- `project` → `state_projection`, positional shape unchanged.
- `events` → `state_events`, and the pair type `Event` → `StateEvent`.
- `workspace` → `init_workspace`, arity unchanged: `(::C, ::Type{T})`
  continuous, `(::C)` discrete.
- Anything naming a Julia method takes the new word; a symbol in an equation or
  a name for a mathematical object keeps its letter.
- What stays: every bundle field (`x, s, m, u, y, y_x, y_s, t, Δt, ws`); the
  `guard`/`handler` halves and the word "event" in prose; `init_x`, `init_s`,
  `init_m`, `input_types`, `output_types`, `sample_times` and the connection
  declarations; the stage-numbered sweep names of [D-196][d-196]; the executor's
  phase symbol `:project`; the diagnostic kind names, `EventHalfMissing`
  included. No aliases and no deprecation shims: there are no external users,
  and a half-renamed surface is the ambiguity this entry removes.

**Spec.** [§2.1][s2-1], [§3.2][s3-2], [§4.3][s4-3], [§4.4][s4-4], [§5.2][s5-2], [§5.3][s5-3], [§5.4][s5-4], [§6.2][s6-2], [§7.1][s7-1], [§7.3][s7-3], [§7.4][s7-4],
[§7.5][s7-5], [§8.1][s8-1], [§8.2][s8-2], [§8.5][s8-5], [§9.3][s9-3], [§9.4][s9-4], [§9.5][s9-5], [§9.7][s9-7], [§10.4][s10-4], [§10.5][s10-5], [§10.6][s10-6], [§12.5][s12-5],
[§13.4][s13-4], [§13.5][s13-5], [§13.6][s13-6], [§13.7][s13-7], [§14.5][s14-5], [§14.7][s14-7], [§14.8][s14-8], [§14.10][s14-10], [§15.1][s15-1], [§15.2][s15-2], [§15.5][s15-5],
[§16][s16], [Appendix A][sA], [Appendix B][sB], [Appendix C][sC], [Appendix D][sD]

**Rationale.** On Julia 1.12 a declaration written without `import Cadence: …`
creates a fresh local generic, silently, whether or not the name is exported,
and the build sees a component that declares nothing. When the author already
owns a function of that name the definition adds a method to *theirs* instead,
and no diagnostic can tell a forgotten import from a legitimate user function —
`f` is the commonest throwaway name in any REPL, `g` is gravity in a flight
package, and `update`, `project` and `events` are ordinary user verbs and
nouns. The work queue's shadowed-declaration diagnostic would have had to hedge
on every one of them. Distinctive names make the check decidable instead: a
foreign binding of `state_derivative` or `init_workspace` in a component's
module is unambiguous evidence of a forgotten import, so the diagnostic can
name it.

Two further gains ride along. The underscored suffixes read as subscripts and
suggest partial derivatives, which the stage names never meant; the new names
state the dependence class in words, `output_state` for `y = h(x)` and
`output_direct` for `y = h(x, u)`. And the two output stages are machinery
shared by both tiers, so one pair of names is the honest spelling of what the
compiled sweep blocks already do ([D-196][d-196]).

Two earlier rulings retire in part. [D-195][d-195]'s output-stage split (`h_x`/`h_xu`
against `h_s`/`h_su`) goes, and with it the output-stage member of
`DeclarationOnWrongTier` and the "no tier qualifier" reading of the closed
bundle-name sets: `output_state` and `output_direct` take one legal set per
tier again. The tier is still fully determined without them — `init_x` versus
`init_s`, `state_derivative` versus `state_update`, and the `T`-form arity of
`input_types`/`output_types`/`init_workspace` — so a leaf declaring
`state_derivative` beside `init_s` is `StoreWithoutUpdate` or a tier
disagreement exactly as before. [D-195][d-195]'s state-letter split itself stands
untouched. [D-077][d-077]'s rejection of `init_workspace` also goes: it rested on a
workspace not being memory that conditions overlay and on the poison
overwriting it, and [D-183][d-183] removed the poisoning, while `init` in this API
already means *establish* — the device contract's `init!` — rather than
*initial value*, and `init_x`'s own value is a default that conditions overlay.
[D-077][d-077]'s position, declaration by allocation called per activation and per
scratch-store set, stands unchanged. Both entries keep `ratified`: the log has
no partial status, and neither position is replaced. [D-144][d-144]'s naming
convention is amended rather than retired: its class 1 reads *noun phrases*
from here, the stage and update-law names no longer being bare nouns, and the
`workspace` item it flagged for the [§16][s16] audit is settled by this entry.
[D-144][d-144] keeps `ratified` for the same reason.

`state_events` also names the distinction [§2.1][s2-1] now teaches. The discrete
tier's ticks, declared by `sample_times`, are *time events*, scheduled because
their instants are known in advance; everything declared through
`StateEvent(guard, handler)` is a *state event*, whose instant is unknown and
must be detected. The criterion is detection versus scheduling, not which
bundle fields a guard reads.

**Rejected.**
- *Keeping the letters and adding a shadowing diagnostic instead:* the
  diagnostic cannot distinguish a user's own `f` from a forgotten import, which
  is the whole reason the check was never designed.
- *`derivative` and `update` unprefixed:* `derivative` is exported by
  DifferentiationInterface, Polynomials and others; `update` is a common user
  function. Both reintroduce the collision the rename exists to remove.
- *`event_list`, `event_table`, `transitions` for the events declaration:* the
  first two name a container rather than what it holds; "transition" is already
  the spec's word for the crossing itself.
- *`Transition` for the pair type:* same collision with the crossing.
- *`Jump` for the pair type:* spent on the discrete update law's lineage ([§3.2][s3-2])
  and reading as stochastic in the ecosystem.
- *`Callback` for the pair type:* a hook rather than a modeled event, and
  DiffEq's continuous/discrete callbacks use the tier words for what is here
  the detection policy.
- *Keeping `Event`:* `Base.Event` is exported from Base, so a forgotten import
  gives a `MethodError` naming `Base.Event` — loud, but misleading.
- *`alloc_workspace`:* a third prefix for one function, against an `init_*`
  convention the inventory already has.
- *Per-tier output-stage words (a second pair over `s`):* re-creates the split
  this entry retires, to state a tier the rest of the family already states.

### D-221 — Unwrap a single-diagnostic carrier at the runtime catch site into a `StepError` species

**Status.** ratified

**Position.** A fail-fast throw inside the boundary macro-sequence travels as
the ordinary carrier holding one diagnostic. The catch site unwraps it, and the
`StepError` it constructs carries that diagnostic as `cause`. A species of
`StepError` is one whose `cause` is a diagnostic.

- The catch site is the only `StepError` constructor; one arriving there is an
  invariant failure, not a re-wrap.
- A collected carrier has no single kind, so it rides as `cause` unchanged; no
  runtime check throws one.
- Deferred, registered in the pending list: parametrizing `StepError` on its
  cause's type, so a species is assertable as `StepError{Kind}`.

**Spec.** [§9.5][s9-5], [§13.2][s13-2], [§13.4][s13-4], [Appendix C][sC], [Appendix D][sD]

**Rationale.** [§13.4][s13-4] said a conformance failure "is thrown as its typed
diagnostic" and "is a species of `StepError`" without saying how the catch site
recognizes one. The prototype's spelling is ratified as the rule. A diagnostic
is a plain value and cannot be thrown on its own, so a runtime check throws the
one carrier every fail-fast site throws. The catch site already knows it is the
frame's catch, so the carrier need not encode the throw site. Unwrapping there
puts the payload one field away, which is what "carrying the field-diff
payload" promises a test. The same throw spelling serves the conformance check
at the probe and at the table-write point.

**Rejected.**
- *Throw the diagnostic bare:* Julia permits throwing any value, but
  `Diagnostic` is not an `Exception`, and making it one turns every kind into an
  exception type, which [D-058][d-058] rejects.
- *A runtime-only carrier:* encodes into a type what the catch site knows from
  where it is; a third carrier against the glossary's two; one that escaped the
  frame loop would render as nothing meaningful, where the ordinary carrier
  renders fully.
- *Leave the carrier as `cause`:* the payload sits two levels down, the render
  reaches through both, and the species predicate becomes "a carrier with one
  entry".

### D-222 — Replace `BuildError` with the policy-parametric `DiagnosticError` carrier

**Status.** ratified

**Position.** The one carrier is `DiagnosticError{P}`, `P` bounded to
`Union{Diagnostic, Vector{Diagnostic}}`: the diagnostic's kind for a fail-fast
throw, `Vector{Diagnostic}` for a collected one. The field is `carried`;
`diagnostic(e)` and `diagnostics(e)` are each defined on one parameter. No
aliases and no deprecation shims, on [D-220][d-220]'s ground.

- Rendering, the `kinds` helper and the catch site's unwrap dispatch on the
  parameter; no branch reads a count.
- The rename sweeps the spec, its companions, the code and the tests; the log
  keeps its vocabulary.

**Spec.** [§13.2][s13-2], [§13.4][s13-4], [§14.1][s14-1], [§14.8][s14-8], [Appendix C][sC], [Appendix D][sD]

**Rationale.** The name claimed a tier while the job spanned three sites: the
stratum barrier, a stopped-sim service's refusal, and a runtime check inside
the frame. Two of the three are not build failures. The carrier also erased the
reporting policy at the throw, so two functions re-derived it from cardinality:
the catch site's unwrap and the carrier's `showerror`. [D-214][d-214] made policy a
property of the occurrence, and the exception is the occurrence, so the type
carries it. Putting the kind in the parameter gives tests `@test_throws
DiagnosticError{Kind}`, a spelling of [§13.2][s13-2]'s kind-not-message doctrine in the
type system, and keeps `isa DiagnosticError` as the catch-all for both
policies.

**Rejected.**
- *Rename only, keeping the vector:* the cardinality branches stay.
- *Two structs by policy, `DiagnosticError` for one diagnostic and `BuildError`
  for the batch:* loses the catch-all and the kind in the type; "build" still
  names the attach and replay collections.
- *An abstract supertype with `FailFast{D}` and `Collected` subtypes:* the same
  benefits at the price of three names, two of them policy words standing as
  exception types.
- *A singular and plural pair:* a reader trap.

### D-223 — Host the runtime catch in boundary zero under the service's disposition

**Status.** ratified

**Position.** A throw inside boundary zero, under `init!` or `replay!`, is
wrapped by the one `StepError` constructor with the cursor's frame, `t₀`,
pointer `0` and the species rule, and the simulation returns to `built`: no
termination record, nothing published, `init!` and `replay!` legal again.

- The pointer degenerates at zero, which frame one shares: `replay!` of the
  captured header reproduces either failure, and the rendered recipe at zero
  is the bare replay.
- `built` reads "boundary zero not completed", cold or after a failure. The
  stores are retained for inspection until the next `init!` resets them.
- `trim!`'s commit inherits the rule, being an `init!`.
- An interrupt inside boundary zero moves the lifecycle to `built` and
  propagates raw; a service has no stop path.

**Spec.** [§12.6][s12-6], [§13.4][s13-4]

**Rationale.** Boundary zero runs the loop's user-code surfaces with the cursor
maintained through them, so the frame naming the failing component and
function existed at the throw and was discarded. A conformance failure at `t₀`
surfaced as the bare carrier while the same failure at `t₁` surfaced as a
species. The loop's terminal disposition does not transfer: nothing has been
published, no run is open, and the remedy for a condition that fails at `t₀`
is a corrected condition, which needs the simulation re-initializable. Before
the ruling the lifecycle word moved only at `init!`'s end, so a re-`init!`
that threw left a warm simulation reporting `initialized` with the clock reset
and the stores half-transitioned, and `step!` advanced on them.

**Rejected.**
- *Raw propagation, closing only the lifecycle hole:* forgoes the frame and
  keeps two shapes for one failure.
- *The loop's full disposition, `errored` with a termination record:* a bad
  condition would make the `Simulation` disposable, and `trim!` would need a
  fresh one per failed commit.

### D-224 — Let a throw inside a trim commit propagate as the commit's `StepError`

**Status.** ratified

**Position.** `trim!` does not catch the `StepError` a commit-time throw
raises out of its `init!`. The throw propagates, the simulation is left
`built` under [D-223][d-223], and no `TrimReport` is returned for that solve.

**Spec.** [§14.8][s14-8]

**Rationale.** A commit-fired handler that moves the stores is a modeling
event the report carries as `TrimCommitEvents`; a handler that throws is
model code failing, which [§13.5][s13-5] makes abnormal always. A report carrying an
exception would blur the two classes and hand the caller a converged verdict
over a simulation holding no committed point. The solution is not lost to a
caller who wants it: the `StepError`'s frame names the handler, the solve is
deterministic, and re-running with the event fixed reproduces it. The scratch
executor is call-local and dies with the frame, so nothing leaks.

**Rejected.**
- *Catch the commit's `StepError` into the report as a further outcome:* an
  exception as report content, the abnormal class laundered into the
  ordinary one.
- *Commit into a scratch simulation first and copy the stores on success:* a
  second boundary zero per commit and a copied trajectory, to protect
  against an authoring error.

### D-225 — Parametrize `StepError` on its cause's type

**Status.** ratified

**Position.** `StepError{C}` carries the type of its `cause`, `C` bounded to
`Union{Diagnostic, Exception}`: a species is `StepError{Kind}`, a raw throw is
`StepError{ArgumentError}` and the like, and `isa StepError` matches both.
`diagnostic(e)` is defined on the species as it is on the fail-fast
`DiagnosticError`.

- The catch site is unchanged: the one constructor infers `C` from the cause
  the species rule hands it ([D-221][d-221]).
- A collected carrier riding as `cause` falls under the `Exception` arm.
- A bare value that is neither, thrown deliberately by model code, fails the
  constructor with a `MethodError` inside the catch and leaves unframed.
  Accepted, not handled.

**Spec.** [§13.2][s13-2], [§13.4][s13-4], [Appendix C][sC], [Appendix D][sD]

**Rationale.** [D-222][d-222] put the kind in the build carrier's parameter so a test
asserts policy and kind as `@test_throws DiagnosticError{Kind}`, and [D-221][d-221]
deferred the runtime counterpart so the carrier change landed alone. Left as
`cause::Any`, a species was recognizable only by reading the field, and every
species assertion spelled the two conjuncts the build side had just retired.
The bound states in the type what [§13.4][s13-4] states in prose: the cause is the
unwrapped diagnostic of a species or the exception model code threw. Every
ordinary throw is an `Exception`, `error`, `@assert`, a `MethodError`, a
`FieldError` or a `TaskFailedException`, so the case the bound excludes is a
deliberate `throw` of a bare value, and a branch for it would be handling for
a case nobody reaches. The cost is recorded so it is a decision: for that
throw the frame and the pointer are lost, and the lifecycle word does not move
as it does on the framed path.

**Rejected.**
- *`cause::Any`, the species read off the field:* the kind stays out of the
  type, and the runtime carrier contradicts the rule the build carrier
  follows.
- *Unbounded `C`:* keeps the catch site total over any thrown value, at the
  price of a type that documents nothing; the excluded case is the deliberate
  bare throw above.
- *A species-only parameter, the raw cause under `StepError{Nothing}` or a
  second struct:* a raw cause is still the cause; two spellings for one field.
- *A policy parameter as in [D-222][d-222]:* a `StepError` is always fail-fast, so
  there is nothing to encode.

### D-226 — Reach the public surface by qualified name until §16's export audit

**Status.** ratified

**Position.** A framework name is public by standing on [Appendix B][sB]'s surface,
reached by qualified name or per-name `import`. Julia's `export` list is
decided once, by [§16][s16]'s full-surface audit, and until then the module exports
nothing.

- "Exported" keeps two senses in the spec: an assembly face raised to its
  boundary, and [§16][s16]'s audit. A function or name on the API surface is
  "public". The rename sweeps the spec and its companions, not the log.
- The interim is conformance, not a gap: the suite reaches every name through
  `using Cadence` plus a per-name `import` list, [D-117][d-117]'s idiom, and a REPL
  session loads the same list through `test/repl.jl`.
- The authoring family stays unexported under [D-117][d-117] whatever the audit
  decides for the operator half.

**Spec.** [§4.4][s4-4], [§9.4][s9-4], [§16][s16], [Appendix B][sB], [Appendix D][sD]

**Rationale.** The 2026-09-04 conformance audit read "exported" at three sites
as an obligation the module does not meet, `names(Cadence)` being
`[:Cadence]`. The sites describe visibility. [§4.4][s4-4]'s value-level constructor is
a function a model package must expose so condition math can call it outside
any sweep; [§9.4][s9-4]'s `ProbeDual` is a name a CI activation list spells. Neither
needs `export`; both need a public name. [§16][s16] already records the export list
as open, to be decided by a full-surface audit under the four-class
convention, and names what the operator half carries: `condition`,
`fragment`, `at` and `combine` share a namespace with FlightPhysics domain
code, and whether the condition algebra ships behind a submodule is the
packaging question. Exporting ahead of that audit would claim names it may
rename or move. `step!` is exported by SciMLBase, `combine` by DataFrames and
`mode` by StatsBase, and Julia settles such a clash at the first unqualified
use, which is the by-accident outcome the audit exists to prevent. Nobody is
inconvenienced meanwhile: the package has no external user, and the
developer's session pays one `-L` flag.

**Rejected.**
- *Export the operator surface now:* decides the list by accident ahead of
  the audit [§16][s16] requires, and turns a later rename or submodule move into a
  breaking change.
- *Rule that nothing is ever exported:* forecloses the audit.
- *Read "exported" as Julia's `export` and register the code as deviant:*
  creates an obligation the design itself defers.
- *A re-export submodule for the operator verbs:* the packaging [§16][s16] lists as
  open, half-decided.

### D-227 — Select the stepper by type under the `algorithm` keyword

**Status.** ratified

**Position.** The deployment keyword that picks the integration backend is
`algorithm`, and its value is a stepper type, `RK4` by default, which binding
materializes against the flat state buffer. The name reaches every surface
that records the choice: the trace header's deployment block, the replay
comparison and the `DeploymentInvalid` parameter.

**Spec.** [§9.1][s9-1], [§10.2][s10-2], [§11.5][s11-5], [Appendix B][sB], [Appendix C][sC]

**Rationale.** The code took `method = RK4` and [Appendix B][sB] spelled
`algorithm = RK4()`, with no ruling behind either. The two spellings differ
on two axes. On the value, a stepper is a runtime object owning scratch sized
to the state and typed by the deployment scalar, and both are known only at
binding: `N` comes out of compilation, `T` is the constructor's positional
argument. A type is called with `(T, N)` once both are in hand. An instance
would have to be a token that binding later materializes, a spec type per
backend plus a materialization protocol, and neither first-cut backend
carries a parameter for the token to hold. The instance form pays off only
for a parametrized backend, which [§10.2][s10-2] defers under the guarded-additions
rule, and admitting one later is an extension by dispatch on the keyword's
value, never a break. Selecting by type is also the constructor's existing
idiom: the scalar is selected the same way. On the name, "method" in Julia
and throughout the package's own commentary means a method of a generic
function, so a diagnostic naming `:method` as an invalid deployment parameter
reads as a dispatch complaint. `algorithm` is the spec's majority term and
the glossary's, and carries no such collision.

**Rejected.**
- *`algorithm = RK4()`, the instance form:* builds a materialization layer for
  backends that have nothing to parametrize; deferred with the parametrized
  backend it would serve.
- *Keep `method` and sweep the spec:* cheapest today, but fixes the
  vocabulary collision on a keyword, a header field and a diagnostic
  permanently.
- *`stepper = RK4`:* the most precise word, but the spec uses "stepper" for
  the seam and the runtime object, and the keyword selects an identifier of
  the choice, not the object.

### D-228 — Attribute runtime diagnostics by cell, never by payload

**Status.** ratified

**Position.** A rate-limited diagnostic kind names its subjects in the payload
and never its writer. The writer is the identity of the cell it was written
to, and the published status record's `who` and the tail residue carry it.

**Spec.** [§11.8][s11-8], [Appendix C][sC]

**Rationale.** [§11.8][s11-8] gives every writer its own cell: one per rostered
device, one for the harness writer, one for the loop. A device reports
through its handle, the handle owns the cell, and no call anywhere passes a
device id. At the drain each cell becomes one record of the published
framework status, keyed by the writer's name, with the ring, the suppressed
counts and the cumulative per-writer × per-kind totals beside it; the run's-end
residue is built the same way. The writer is therefore a structural fact of
the channel, and a payload field would restate what the value's container
already says, at every emission site, with room for the two to disagree.
[Appendix C][sC]'s rows had named a device or writer id in five payloads, and the
2026-09-04 audit read them as missing fields. The rows now name subjects
only. `DeviceJoinTimeout` keeps its device id: it names the abandoned device,
and the loop writes it. The one cost is a value shown apart from its record,
which is a renderer's concern: a renderer presents each value under its
record's writer.

**Rejected.**
- *A `writer` field on the five kinds:* the wrapper, the staging shim, the
  drain and the author's own loop body would each spell a name the channel
  already guarantees, and a wrong name would contradict the cell.

### D-229 — Collect to the stratum barrier under a dependency rule

**Status.** ratified

**Position.** "Collected" reaches the stratum barrier. A declarative pass
runs when the results it reads are clean, records every violation it finds,
and returns a total result; every pass that ran merges into one throw before
the next stratum. What that rule yields, pass by pass:
- A wiring failure is walked past. The resolver records it and yields no
  producer, the walk claims nothing, and the obligation check reports the
  input it left unfed beside it ([§13.1][s13-1]'s worked example).
- A structural failure throws at once and alone: an unreadable or mixed
  class, a malformed container. The subtree behind it is unknown, so no
  later pass can read it.
- A check whose subject a later user-code evaluation consumes fails fast
  with the chain: stage-2 conformance, the wire bound check, two-stage
  production.
- Outside the strata the unit is the call. Deployment validation ([§9.1][s9-1]) runs
  every check whose premise holds and throws once.

**Spec.** [§9.1][s9-1], [§13.1][s13-1], [Appendix C][sC]

**Rationale.** [§13.1][s13-1] fixed that declarative passes collect and strata are
barriers, and left unsaid what a pass does with a violation inside itself
and whether the throw belongs to the pass or the stratum. The worked example
forces one answer at one site: resolution must record an unknown port and
continue with no producer, or the unfed input it caused is never found. That
sentinel is natural, and it is where clustering actually happens: five
unwired inputs, a renamed port breaking three wires. Stratum A's other
passes read only the component list, which the walk completes whatever the
wiring did, so merging their lists into the barrier costs a returned vector
and one throw. A structural failure is different in kind: the walk cannot
decide whether to recurse into an unreadable class, and a parent's wire
resolution reads the child's container structure. Walking past one needs a
skip arm in every reader, and every wire skipped cascades into an unfed
input that the no-suppression rule ([D-057][d-057]) then reports. The dependency
rule states in one sentence which passes run and absorbs Stratum C, where a
check that reads a failed probe does not run, which is the fail-fast the
section already prescribes there. [D-057][d-057]'s rejection of dependent-check
skipping is narrowed accordingly: the rule skips a pass whose input never
came to exist, never a check inside a poisoned subtree.

Annotation (2026-09-08): the wire bound check moved to Stratum A's wire pass
with [D-236][d-236] and collects under that stratum's barrier; the chain's fail-fast
keeps stage-2 conformance and two-stage production.

**Rejected.**
- *Per-pass scope:* a typo'd wire beside a malformed `state_events` entry
  costs two build cycles, and the merge that saves the second is ten lines.
- *Per-component scope:* the worked example fails; the unfed input is found
  in a later pass over another component.
- *Stratum scope with structural sentinels:* a skip arm at each reader of
  the class and the children list, and one cascaded `UnconnectedInput` per
  wire routed through the broken component, for a co-occurrence that is
  singular in practice.
- *Deployment fail-fast under the service policy:* [§9.1][s9-1] and [§10.4][s10-4] both
  spell deployment validation collected, the keyword pass already collects,
  and the dependency rule covers the dependent `bind_schedule` arms without
  a new concept.

### D-230 — Stamp the snapshot with the trajectory's boundary ordinal, not the wait counter

**Status.** ratified

**Position.** A snapshot's boundary index is the trajectory's
published-boundary ordinal: boundary zero is 0, every publication after it
counts one, grid or `t*`, and a new trajectory restarts it. The [§12.3][s12-3] wait
counter is a separate, monotone count that is never reset, its absolute value
nowhere normative.

**Spec.** [§10.4][s10-4], [§12.3][s12-3], [§12.6][s12-6]

**Rationale.** [§12.3][s12-3] carried its counter in the snapshot and glossed it as
the boundary index, while the log, [§14.5][s14-5] and the field's own comment treat
boundary zero as 0. The two readings agree on a simulation's first trajectory
and part on the second, where the boundary-zero snapshot opened at the
previous run's count. They are different quantities. The wait counter exists
so a waiter can test `counter > last_seen`; it is monotone across runs
because a `last_seen` taken from a previous run must never exceed it, and
nothing reads its value otherwise. The snapshot is a per-trajectory value in
every other field, `t` restarting at `t₀` and the frame index at 0, so its
index restarts too, and a mechanism's private fact stays out of a published
payload. The replay pointer of [§13.4][s13-4] is a third index, the frame-entry
boundary index, a frame count that can name no `t*` boundary; [§10.4][s10-4] and
[§12.3][s12-3] had called it the counter and now name it as what it is. The cost is
one field beside the clock, reset with it and stamped at publication.

**Rejected.**
- *The wait counter as the snapshot's index:* unique across every trajectory
  a `Simulation` runs, which nothing asks for, and the one number the loop
  itself declares non-normative published as a fact.
- *Resetting the wait counter at `init!`:* a handle surviving `init!` would
  hold a `last_seen` ahead of the counter and block until the count caught up.

### D-231 — Require isbits store values, checked at build

**Status.** ratified

**Position.** Every field of a store value — a discrete leaf's `s`, and any
leaf's `m` — is isbits or a `Symbol`, and Stratum A checks every
`init_s`/`init_m` field, reporting `IllegalStoreField`. The frozen-reference
latitude of [§4.1][s4-1] stays with signals. A PRNG object is workspace; the values
that determine its next draw are the state.

**Spec.** [§3.2][s3-2], [§7.3][s7-3], [§8.2][s8-2], [§9.1][s9-1], [Appendix C][sC], [Appendix D][sD]

**Rationale.** The three sources disagreed and the code checked nothing:
[§7.3][s7-3] granted `s` "any immutable value" under the frozen-reference rule, the
declaration's docstring and [D-195][d-195] said isbits, and the build enforced neither.
Isbits is one exact predicate, `isbitstype`, checkable once at build.
"Immutable plus frozen references" is a claim about the run and can only be
contract, which contradicts [§7.3][s7-3]'s own opening — stores governed by checks,
the workspace by contract. Every discrete-state use in the grounding is
counters, enums, filter taps, timers and RNG words. The latitude was earned by
field handles on ports ([§4.4][s4-4]), and bulk data does not change between ticks, so
its home is the component instance. Isbits makes "snapshots are free" literal,
gives a future on-disk trace one fixed layout per store, and retires the
`deepcopy` hedges the implementation had placed around store capture and
replay. The RNG example never needed type freedom: the generator is mutable
and could never be a store value, and its state values are isbits. Measured on
Julia 1.12, rematerializing a `Xoshiro` from its values each tick allocates
under `randn`, whose out-of-line tail lets the object escape, and not under
`rand`; a workspace-resident generator loaded by field assignment allocates
under neither. The spec blesses the latter and stays silent on the generator's
internals, which are the stdlib's. `Symbol` is admitted because it is not
isbits in Julia yet loses nothing the rule was written for: interned,
immutable and never freed, it copies as a pointer to permanent data, reads
safely from any thread and serializes as its name. It is also how Julia code
writes a label, where `@enum` puts every instance name into the module
namespace, a cost that compounds across a component library. The check stays
one exact predicate per field and does not recurse, so a struct nesting a
`Symbol` is rejected.

**Rejected.**
- *Any immutable value under the frozen-reference rule (the prior [§7.3][s7-3] text):*
  uncheckable, so contract-only; motivated by an example that does not need
  it; leaves the copy hedges in place.
- *Isbits as contract, without a check:* the predicate is exact and one line;
  a rule that can be checked and is not is the workspace's regime applied to
  state.
- *Rematerializing the generator per tick:* allocation depends on which
  sampler is called, a property no spec should lean on.
- *Naming the generator's word count in the spec:* stdlib internals; the
  principle — mutable object in `ws`, its state values in `s` — survives a
  field added or removed.
- *Strict isbits, modes as enums:* the spec's own examples say enums and
  would have needed no change, but the rule would forbid the `Symbol` idiom
  for every author to buy a "self-contained bytes" claim nothing yet consumes.

### D-232 — Refuse the roster operations on an errored simulation

**Status.** ratified

**Position.** `attach!` and `detach!` refuse an `errored` simulation with
`ServiceLifecycle`, as they refuse a running one; [§11.3][s11-3]'s list of legal
states — `built`, `initialized`, `stopped` — is exhaustive. The stopped-sim
reads stay admitted there: post-mortem inspection is reading.

**Spec.** [§11.3][s11-3], [§13.6][s13-6], [Appendix B][sB]

**Rationale.** The implementation gated the roster operations and the log
reader behind one check that refused only `running`, and called admitting
`errored` deliberate on [§13.6][s13-6]'s post-mortem grounds. Those grounds cover the
reads: [§13.6][s13-6] and [§14][s14] retain an errored simulation's stores, log and trace as
a diagnostic read. A roster change is not a read. It configures the next run,
and an errored simulation has none, every advance entry and `init!` refusing
it under [D-059][d-059]. An attachment admitted there compiles a writer, stakes claims
and returns a handle nothing will ever drain: the "device attached, nothing
happens" shape [D-105][d-105] rejected as a hidden bug, here without a diagnostic.
`detach!` gains nothing either. `AlreadyAttached` is per roster, so the
device instance may join a fresh simulation without leaving the dead one, and
the tail already ran its `shutdown!`.

**Rejected.**
- *Adding `errored` to the legal list:* the one rationale on offer,
  post-mortem inspection, justifies reads and not configuration.
- *One gate for all three, `logged` refused beside them:* [§14][s14] mandates the
  post-mortem read.

### D-233 — Retire the termination record's absent-time arm

**Status.** ratified

**Position.** The termination record's final boundary time is always present,
a value of the deployment's scalar and never `nothing`; this amends [D-203][d-203]'s
first field.

**Spec.** [§13.5][s13-5]

**Rationale.** [D-203][d-203] admitted an absent time for "no boundary ever ran", a
[§13.6][s13-6] failure before boundary zero. No run reaches it. Only the advance
entries write the record, both refuse a `built` simulation, and after `init!`
a snapshot always exists, boundary zero having published it. A throw inside
boundary zero writes no record at all: the simulation returns to `built` under
[D-223][d-223]. The arm was dead in the code and named a case in the spec that the
lifecycle rules out. [D-202][d-202]'s argument against an in-band `NaN` stands
unaffected, there being no absence left to spell.

**Rejected.**
- *Keeping the union for a future entry that could reach it:* no entry writes
  a record before boundary zero, and [D-223][d-223] settled that a failed boundary zero
  leaves none.

### D-234 — Rename the deployment keyword `n` to `N_base`

**Status.** ratified

**Position.** The steps-per-base-tick factor, `Δt_base = N_base·h`, is spelled
`N_base` everywhere: the `Simulation` keyword, the trace header's deployment
field, the spec's prose and equations. The step subscript `tₙ` and the stepper
seam's state count `N` keep their letters.

**Spec.** [§9.1][s9-1], [§10.5][s10-5], [Appendix B][sB], [Appendix D][sD]

**Rationale.** `n` denoted a fixed integer factor while the spec's own
convention gives lowercase letters to changing indices — the frame
`[tₙ, tₙ₊₁]`, the retained pair `(xₙ, ẋₙ)` — and uppercase to the compiled
pair `(D, Φ)`, so a reader met the factor and the subscript in one section
and kept them apart by context alone. The spec keeps one name for a symbol
and its keyword (the [D-133][d-133] friction), so the rename is one name on both
sides. `N_base` anchors to the quantity it defines: `Δt_base = N_base·h`
reads as "the base period is `N_base` steps", and the pair matches in
spelling. Julia's style guide rules on module, type and function names only;
keyword names are unconstrained by it, and Base's lowercase keywords are an
unwritten practice.

**Rejected.**
- *Bare `N`:* collides with the stepper seam's state count, `Or{N}` and the
  ForwardDiff chunk width.
- *A word, `frames_per_tick`:* unambiguous, but every equation becomes prose.
- *`N_tick`:* reads as a number of ticks.

### D-235 — Realize the always-on check at the generated write, against the cell type

**Status.** ratified

**Position.** The always-on conformance check ([D-053][d-053]) is one relation, [D-166][d-166]'s
embed-accept, applied at the probe and at every table write. At the write it
holds the return to the type of the cells the stage writes, as the probe fixed
them at this activation, and it is decided when the write's method is generated
over the cell type and the return type.
- Stage returns, `state_derivative`, and the wholesale state writes of
  `state_projection` and a handler's `x` key all take it; the probe's state
  checks apply the same relation.
- A conformant return type generates the straight stores. A non-conformant one
  generates a throw of `ConformanceFailure`, a `StepError` species at runtime
  ([§13.4][s13-4]).

**Spec.** [§7.1][s7-1], [§9.5][s9-5], [Appendix C][sC]

**Rationale.** Two facts fix the shape. [D-166][d-166]'s embed-accept makes "types equal
or refuse" impossible at the write: a `Float64` at a declared-`T` cell under a
non-nominal activation is lawful, and storing it into the `T` buffer is the
zero-partial embedding [§9.5][s9-5] describes. So the write cannot be a flat type test;
it is the relation the probe applies, and the leaf store is the embedding. And
the writes are already generated functions over the cell address, whose
parameter is the cell type. Generating them over the return's type as well
evaluates the key-set comparison and the per-leaf relation on types, before any
instruction is emitted. Type-stable conformant code generates the stores it
generates today. Branch-divergent code takes one specialization per return
type, the union split the code already pays. This is [D-053][d-053]'s one baked type
test resolved by dispatch: per-leaf reasoning at generation, no per-field
instruction at runtime, so [D-053][d-053]'s rejection of per-field checks holds in the
sense it was made, which is cost.

The expected type is stated against the cell rather than against
`output_types(c, T)` so the rule does not depend on how a cell's type is fixed.
Today the two coincide, a cell's type being its producer's declaration
evaluated at the activation; the phrasing survives any later widening of
acceptance.

**Rejected.**
- *A runtime `isa` against the declaration's `NamedTuple` type:* refuses the
  `Float64` embed-accept sanctions at a declared-`T` leaf, breaking the
  constant-branch idiom [D-166][d-166] keeps legal.
- *Leaf-count comparison at the probe and no check at the write (the built
  shape):* an `Int64` leaf for a `Float64` state passes and converts, and a
  return field set the probe never saw is dropped or raises a raw `FieldError`
  inside a `StepError`, the shape [D-053][d-053] rejects.
- *Refusing a `Float64` at a declared-`T` cell to force type stability:* a
  `T`-declared output computed from a frozen discrete input is `Float64` at
  every activation, lawfully and stably, so the refusal would require the
  consumer to know its producer's tier, which [D-054][d-054] rules impossible by
  construction. Type stability under `Dual` is an authoring rule ([§7.2][s7-2]), not a
  conformance predicate.

### D-236 — Type-check a wire by one relation with embedding, in Stratum A

**Status.** ratified

**Position.** A producer's declaration is accepted at an entry when some
leafwise embedding of it, lifting any subset of its `Float64` leaves to the
activation scalar, is `<:` the entry evaluated at that scalar. Both clauses of
[§6.1][s6-1] are this relation, decided in Stratum A by evaluating the contract
declarations at a marker scalar and collected under the stratum's barrier.
- A concrete entry is checked leaf by leaf. An abstract entry is checked on the
  whole declaration: the producer's declaration, or the same with every pinned
  leaf lifted, must be `<:` the entry.
- A root input's cells at an activation take the all-walking evaluation of the
  root-input type when every consumer's entry admits it, and the root-input
  type itself otherwise: [D-168][d-168]'s meet, at the level of the whole root input.
- A root input whose entries are all abstract is `AbstractAtRoot`. Its concrete
  entries must agree at `Float64` (`RootInputTypeConflict`); abstract
  co-consumers are checked by the bound clause.

**Spec.** [§6.1][s6-1], [§8.2][s8-2], [§9.1][s9-1], [Appendix C][sC]

**Rationale.** At the nominal activation every lift is the identity and the
relation is [§6.1][s6-1]'s bound check, `<:` with equality as the concrete case. Under
a non-nominal activation the lifts express the walk-compatibility clause: a
walking producer leaf must meet a `T` entry, and a pinned producer leaf meets
either, because a frozen value embeds upward. So one relation is both clauses,
and it is [D-166][d-166]'s embed-accept read from the input side. The abstract case
cannot walk leaves. Its two candidates are exact whenever the entry's
parameters are uniformly `T` or uniformly pinned; an abstract entry mixing the
two against a producer pinning some of them is admitted by the definition but
not by the check, a recorded limit with no known instance.

The meet on a root input is stated for the whole root input rather than per
leaf, which is [D-168][d-168]'s letter. The two candidates decide it without a leaf
walk and let abstract co-consumers vote. A mixture of pins across leaves pins
the whole root input, the conservative direction, which never delivers a `Dual`
where an entry forbade one.

Stratum A is where the check runs for two reasons. The contract declarations
are functions of the scalar that construct types, so evaluating them at a
marker runs no stage code. And the timing is the promise [D-167][d-167] makes: the
input-side forgotten `T` fails at the first nominal build, at the wire. A check
at the probe sees only what the current activation shows, so at nominal the
walk clause is vacuous and the error waits for the first `Dual` activation.
The marker pass evaluates `input_types` and `output_types` alone; `init_x` is
by value and is walked, never evaluated.

**Rejected.**
- *Equality modulo embedding, with nominal identity on struct types (the built
  shape):* refuses an abstract entry's lawful concrete producer, so [§4.4][s4-4]'s
  substitutability and [§8.2][s8-2]'s abstract entries have no code.
- *The check at the probe, on the probed value's type:* one stratum late,
  fail-fast where [§13.1][s13-1] collects, and blind to the walk clause at nominal.
- *A per-leaf meet on root inputs:* legal by the clause but yields a cell type
  no consumer declared, needs a leaf walk abstract co-consumers cannot join,
  and goes beyond [D-168][d-168]'s wording for a case with no known instance.

### D-237 — Classify a non-isbits immutable port type as one opaque leaf

**Status.** ratified

**Position.** The leaf walk over a port type descends through `Real`s, static
arrays and isbits structs, and stops at an immutable type that is not isbits,
treating it as one opaque leaf: a cell of that type holds the value itself,
reference fields included. An opaque leaf is accepted by identity alone; the
embedding lift ([D-238][d-238]) never enters it. A mutable type anywhere in a port value is
refused (`IllegalPortType`), and so is a handle-typed face surfacing as a
root input.

**Spec.** [§4.3][s4-3], [§4.4][s4-4], [§9.5][s9-5], [Appendix C][sC]

**Rationale.** [§4.4][s4-4] already fixes the boundary: a bulk-data model is an
immutable struct combining isbits parameters with references to data loaded at
build time and frozen, never a `Ref`. The classification reads that
description off the type, so an author declares nothing and the walk cannot
drift from the prose. The store is the existing one: a handle type is its own
leaf eltype with one homogeneous store, and Julia keeps an immutable struct
with reference fields inline in an array, so the gather and the scatter are
one load and one store, the allocation-free rebuild [§4.4][s4-4] promises. A handle
may carry `T` among its isbits parameters; its cell is then a different type
per activation, produced at `T` by the emitter's stage, and nothing embeds
into it. An opaque leaf has no scalar positions to lift, so the relation
accepts it by identity, and a handle built from literals at a `Dual`
activation is refused at the probe with both types named; the remedy is to
build it at `T`, or to pin the parameter in the declaration. The rule reads
off the outermost type: a struct carrying a handle beside numeric fields is
itself the opaque leaf, and [§4.4][s4-4]'s isbits parameters live inside the handle,
never beside it. The wire relation ([D-236][d-236]) admits a handle at an abstract
entry by the bound clause and needs no arm of its own.

A root input of handle type has no synthesis (`probe_value`) and no producer.
Refusing it keeps the field-emitting component, with its value-level
constructor, as the one way bulk data enters a model; a caller-supplied root
handle would be a second injection path, closed for the first cut ([D-008][d-008]).

**Rejected.**
- *An author-declared trait marking handle types:* a second place for the
  boundary [§4.4][s4-4] already states, and one that can drift from it.
- *Walking into the references (the built shape):* `leaf_types` descends into a
  `Vector`'s fields, the build succeeds and the first gather dies in a raw
  `MethodError`, neither supported nor refused.
- *Supplying a handle-typed root input at build:* a second injection path
  beside the value-level constructor, reopening what [D-008][d-008] closed.

### D-238 — Decide embed-accept on the type: lift the arrival, compare exactly

**Status.** ratified

**Position.** A type `V` is accepted at a declaration `P` at activation `T`
when lifting `V`'s `Float64` positions to `T` exactly where `P` has `T`
yields `P` itself, compared by identity. [D-235][d-235]'s always-on check and the
concrete arm of [D-236][d-236]'s wire relation both take this form.

**Spec.** [§6.1][s6-1], [§9.5][s9-5]

**Rationale.** [D-166][d-166] states embed-accept per leaf: a declared-`T` leaf
accepts the scalar or a `Float64`, every other leaf is exact. The built
relation checked that statement on the leaves — a struct's name and field
types, a static array's size and eltype — and was exact on the leaves while
blind to the type around them: a `NamedTuple`'s field names, a non-numeric
type parameter and an array's mutability are type parameters, not leaves, so
`(b = T,)` passed at a `(a = T,)` entry, `Tagged{:b}` at `Tagged{:a}` and an
`MVector` at an `SVector`, each surfacing later as a raw `FieldError` or
running silently (increment 32's review). A parallel walk over the two types'
parameters, lifting a `Float64` in `V` where `P` has `T` and leaving every
other position as written, is [D-166][d-166]'s statement decided on the type: [§9.5][s9-5]'s
exact match at nominal is the case where nothing lifts and the relation is
`===`, and the embedding is the one asymmetry. The lift is positional on the
type, so it also reaches a `T` that carries no scalar, such as a tag parameter
(`Tag{T}` with no field of type `T`): the store holds leaves and rebuilds the
declaration from them, so `Tag{Float64}` arriving at `Tag{D8}` is normalized
to the declaration rather than converted, the pinned-into-walking direction
[D-236][d-236] already admits, while `Tag{D8}` at `Tag{Float64}` stays refused. A
parameterless type compares by identity, so [D-237][d-237]'s opaque leaves need no arm
of their own.

**Rejected.**
- *Superseded position — the leafwise walk:* exact on leaves, blind to the
  parameters that distinguish two concrete types with the same leaves.
- *`<:` with embedding on concrete declarations:* concrete types are final, so
  `<:` is identity there and adds nothing; the abstract case is [D-236][d-236]'s.
- *Acceptance by `convert`:* admits every lossy or renaming conversion Julia
  defines, which is the convert-on-write [D-053][d-053] rejects.

### D-239 — Report a typo'd return field alone, without the unproduced port

**Status.** ratified

**Position.** A stage returning a field `output_types` does not declare is
reported by the port check's `UndeclaredReturnField` alone.
`DeclaredNotProduced` belongs to the completeness pass over the complete
products, which runs only once every port check has passed.

**Spec.** [§8.4][s8-4], [§13.1][s13-1], [Appendix C][sC]

**Rationale.** [§8.4][s8-4]'s fifth walkthrough promised the pair: the did-you-mean
and the unproduced-port error with the product lists in hand. The port check
runs inside the probe chain, which consumes each product as it goes, so a
failed check aborts the chain under [D-229][d-229] and the completeness pass never
reaches the model; the 2026-09-04 conformance audit recorded the single
diagnostic. Delivering the pair means recomputing the unproduced set at the
throw site, where it is knowable only once the component's other stage has
run: at stage 2, or at stage 1 on a component with no `output_direct`. And
the second diagnostic carries nothing the first does not: renaming the field
produces the port, and the next build is clean. [D-057][d-057]'s no-suppression rule
is untouched. It keeps a diagnostic two passes both produce, as the
typo'd-wire pair of [§13.1][s13-1], and never asks a pass to manufacture one after the
chain has stopped.

**Rejected.**
- *Pair at the throw site:* a second copy of the completeness check with
  weaker information, silent exactly when a stage 2 exists, so the promise
  would hold except sometimes.
- *Collect the port check to the stratum barrier:* a component with an
  unproduced port has no cell for it, so every downstream probe needs a skip
  arm or a synthesized stand-in — the sentinel machinery [D-229][d-229] rejects.

### D-240 — Read the heartbeat at publication, beside the task state

**Status.** ratified

**Position.** The loop acquire-loads each device's heartbeat timestamp when
it assembles the published status, beside the `task_state` it reads off the
device's `Task` handle. The drain does not touch it.

**Spec.** [§11.8][s11-8], [§12.2][s12-2]

**Rationale.** [§11.8][s11-8] said the loop acquire-loads the heartbeat at the drain
and, twelve lines on, that it rides in the status beside the task state read
at publication. The implementation reads at publication, and that is the
site with a reason. A status published at a `t*` boundary has no drain before
it, so a drain-side read would hand it the previous frame top's timestamp.
The value is advisory ([§12.2][s12-2]), a staleness display against a 2 s threshold,
so freshness at the moment of publication is the whole of what it is for.

**Rejected.**
- *Acquire-load at the drain, copy into the status:* one more field on the
  per-writer account, carried across the frame to publish an older
  timestamp; the `t*` publication would report the drain's reading rather
  than its own moment.

### D-241 — Keep the status a vector of records, one small allocation per publication

**Status.** ratified

**Position.** The published framework status is a `Vector` of per-writer
records built at each publication, one small allocation beside the
snapshot's own. The snapshot type is fixed per model and does not vary with
the roster size.

**Spec.** [§11.8][s11-8]

**Rationale.** [§11.8][s11-8] read "zero additional heap allocation on a quiet
frame", and the implementation honoured it literally for one commit: a
status tuple sized to the roster, a snapshot type carrying it, and a
publication bound per roster change behind a barrier on the writer count,
since an immutable `Simulation` crossing a dynamic call is boxed. Measured,
the tuple saved two allocations of a few hundred bytes next to the
snapshot's store copy. It cost 30 ns of dispatch per publication and about
120 ms of compilation per roster size per process, every consumer of the
snapshot type recompiling with it. The periphery's doctrine is [D-023][d-023]'s
GC-over-reuse trade: one fresh allocation per boundary rather than buffer
management. A second small allocation beside an accepted one changes
nothing the collector feels; a snapshot type per roster size changes what
every attach costs. The decisive invariant is the one the vector keeps:
nothing on a quiet frame scales with diagnostic activity, the counters are
an isbits record, and a noisy frame allocates only its rings.

**Rejected.**
- *A status tuple sized to the roster, in the snapshot's type:* two fewer
  small allocations, bought with a compile per roster size per process and a
  publisher rebound at every roster change; the zero-additional sentence was
  [§7.5][s7-5]'s invariant extended past the scope [§7.5][s7-5] gives it.
- *A fixed-capacity tuple:* no compile per size, but a cap on the roster and
  a record's worth of bytes per unused slot in every snapshot.

### D-242 — Name the resolution cases wiring, service and inspection, and retire "register" and "load-bearing" as spec vocabulary

**Status.** ratified

**Position.** [§13.3][s13-3]'s three resolution cases are named by their client, and
two words leave the design documents' vocabulary, the log included. Every
position stands as ratified; only the words for unchanged concepts move, under
rule 2's word-substitution exception and rule 7's audit. This overturns
[D-122][d-122]'s reservation of "register" for the mode sense.
- *Wiring* replaces [D-130][d-130]'s *structural*: connection declarations, resolved
  in Stratum A under [§6.1][s6-1]'s one-level rule.
- *Service* replaces *load-bearing*: condition entries, trim `reads` and
  taps, checked at the authoring or mount level. "Service" keeps its [§14][s14]
  meaning; the paths are the ones a stopped-sim service compiles.
- *Inspection* replaces *diagnostic*: device read bindings, GUI panels,
  snapshot and log inspection, resolved by the instance walk. It is [D-083][d-083]'s
  own word for that side, so the two vocabularies for one line collapse into
  one. The paired side is *integration reads*.
- "Register" in the sense "a mode or idiom in which something is done" (the
  retired [§D.10][sD-10] entry) is gone. Its compounds are renamed by family: the
  *harness writer* and *what-if replay* (glossary anchors renamed), the run
  *modes* (unattended, test-harness, REPL), usage *idioms* (`step!`,
  test-rig, parallel sweep), the *didactic style* of errors, the
  *by-allocation convention*, the sample time's two *forms*, the naming
  convention's four *classes*, and [§14.4][s14-4]'s *two ways of applying one plan*
  named as the specialized `apply!` and the dynamic walk. The word survives
  only in its storage sense: a slot holding a value.
- "Load-bearing" is dropped outright, its plain-intensifier uses replaced by
  ordinary words.

**Spec.** [§8.1][s8-1], [§8.2][s8-2], [§10.5][s10-5], [§11.2][s11-2], [§11.3][s11-3], [§11.5][s11-5], [§12.6][s12-6], [§12.7][s12-7], [§13.2][s13-2], [§13.3][s13-3], [§13.5][s13-5],
[§14.4][s14-4], [§14.8][s14-8], [§15.5][s15-5], [Appendix A][sA], [§D.10][sD-10]

**Rationale.** Four terms failed the cold reader at once. "Register" asked
for a linguistics sense no technical reader reaches for; a heading such as
"the duty is register-scoped" was decodable only from the table beneath it,
and the same word also named storage slots elsewhere in the spec, so a reader
could not tell which sense applied. "Load-bearing" named the right case at a
distance but three quarters of its occurrences were plain intensifier, so the
term of art had no room to be one; it also named the stakes axis where the
spec's own argument turns on where a violation's cost lands. "Diagnostic"
already meant warnings and errors throughout, with an appendix named for
them, and sat a few characters from "didactic". "Structural" was
serviceable but said nothing about wiring. Naming each case by its client
lets the table's row name carry who resolves and, through the chapter the
client belongs to, what is at stake.

**Rejected.**
- *"Task", "analysis" or "operation" in place of "service":* "task" collides
  with Julia's `Task`; "analysis" excludes initialization and `capture`;
  "operation" is accurate but buys little over the compounded "stopped-sim
  service" and costs a chapter-wide rename.
- *Naming the middle case by its stakes ("portable" or "relocatable"
  paths):* self-explaining, but the other two rows name clients, and a mixed
  scheme is harder to hold.
- *Keeping "register" in the mode sense with an inline gloss at each first
  use:* the gloss fights the reader's prior at every occurrence instead of
  once.
- *Leaving the log in its old vocabulary:* rule 2's first reading; rejected
  because the substitution moves no position and the old words would mislead
  every later reader of the log, so the exception was written into rule 2.

### D-243 — Classify `Symbol` as an opaque port leaf

**Status.** ratified

**Position.** The port walk treats a `Symbol` as one opaque leaf: stored
whole in a cell of its own eltype, accepted by identity, never descended.
Julia's `ismutabletype(Symbol)` does not make it a mutable type for [D-237][d-237]'s
refusal. A `Symbol` surfacing as a root input is refused like a handle, since
it has no synthesis.

**Spec.** [§4.3][s4-3], [§7.3][s7-3], [Appendix C][sC]

**Rationale.** [§4.1][s4-1] requires of a port value immutability plus frozen
references, and [§7.3][s7-3] admits a `Symbol` in a store because it is interned,
immutable and never freed. A `Symbol` therefore meets the table's requirement
on the grounds the store already accepts. [D-237][d-237] refuses mutable types to rule
out aliasing, and no API mutates a `Symbol`; the refusal the walk raised was
an artifact of Julia's classification, not of the design's reasoning. The
cost of the refusal was concrete: the idiomatic mode label is a `Symbol`, so a
mode so labelled could not be declared public, and [§7.5][s7-5]'s remedy for the
absent event stream worked for enum modes alone. The classification is by
[D-237][d-237]'s existing rule with one exemption, so the store shape, the identity
acceptance and the outermost-type rule all carry unchanged. A struct nesting
a `Symbol` is non-isbits and immutable, hence one opaque leaf as a whole,
which mirrors [§7.3][s7-3]'s ruling that a struct nesting a `Symbol` is not a store
field. A `Symbol` root input has no first instance and no zero, so the
handle's refusal covers it.

**Rejected.**
- *Keeping the refusal and making `Symbol` store-only:* the argument that
  admits it at the store is denied at the table, and [§7.5][s7-5]'s remedy stays
  halved.
- *A scalar-like leaf with `Symbol("")` as its synthesis:* a meaningless
  default the probe would feed to a stage; the empty symbol is no instance an
  author means.

### D-244 — Refuse the write primitives of a detached handle by name

**Status.** ratified

**Position.** After `detach!`, `stage!` and `report!` on the retired entry's
handle throw `DeviceContractMismatch` with a `:detached` reason. The read
primitives stay legal.

**Spec.** [§11.6][s11-6], [Appendix C][sC]

**Rationale.** The handle keeps its own staging cell and its own diagnostic
cell, both compiled at `attach!`, and `detach!` leaves no drain over either.
A batch staged through the retired handle therefore lands in a cell nothing
reads, and a report into its diagnostic cell is equally orphaned, so no
in-channel diagnostic can surface the loss. A throw is the only disposition
that is not silent. It is safe because `detach!` is a stopped-sim operation
([§11.3][s11-3]), so no run's task holds the handle when the entry retires. A straggler
abandoned under the join timeout ([§12.4][s12-4](5)) that stages after a detach takes
the throw inside its own wrapper, which is honest for an abandoned task. The
cost is one flag on the handle, set at `detach!` and loaded once per stage;
`stage!` scans no roster. The reads touch the simulation's published state
and nothing of the entry's, so nothing is lost through them.

**Rejected.**
- *A kind of its own, `HandleDetached`:* the handle's misuse family is one
  kind, `DeviceContractMismatch`, and `gather` without an output side already
  refuses through it; a third reason arm is the whole difference.
- *A silent discard under `OutOfClaimEntry`:* it lands in the orphaned
  diagnostic cell, the same silence one channel over.
- *A roster scan in `stage!`:* the per-stage cost the compiled handle exists
  to avoid; the flag records the same fact at the one point it changes.
- *Leaving the edge unguarded as run-scoped task equipment:* `attach!` hands
  the handle to the caller, so it is not equipment of the task alone.

### D-245 — Classify a cycle cluster by a surviving traced cycle and carry each member's tracing mode

**Status.** ratified

**Position.** The classifier decides a cluster as one graph question, and the
diagnostic carries what that question rested on.
- Every wire holds. A hop inside a member holds iff the member's traced map
  routes the entering face to the leaving port. The loop is real iff a cycle
  survives in that graph, artificial iff none does.
- Every dead hop is listed under either verdict.
- Each member records its tracing mode: global, sampled or structural.

**Spec.** [§5.6][s5-6], [Appendix C][sC]

**Rationale.** [D-012][d-012] states the verdict for a simple cycle: real iff every
hop survives. A strongly connected component is one cluster of possibly many
cycles, and read literally over a cluster that sentence misreports the common
tangle. A genuine loop with one false chord would come out artificial, and
the ladder ([D-140][d-140]) would steer the author toward narrowing a contract on a
loop that only a state can break. The graph question keeps [D-012][d-012]'s answer on
a simple cycle and gives the tangle its true one. Listing the dead hops under
a real verdict keeps the false chords visible, since each is a wire the
author can still delete. The mode per member is [§5.6][s5-6]'s own demand that the
caveats ride in the diagnostic rather than being assumed away. A dead hop the
sampled tracer found rests on the paths it took, a structural map can never
kill a hop, and a reader weighing the hint needs to know which. The
structural answer extends from discrete members to any continuous face or
port declared without a walking leaf, for the same reason: no tracer scalar
can enter it.

**Rejected.**
- *Real iff every hop of every cycle in the cluster survives:* the literal
  reading of [D-012][d-012] over a cluster; it calls a tangle with one dead chord
  artificial and offers the wrong rung.
- *Listing dead hops only under an artificial verdict:* hides false wires the
  author could delete from a loop that is real through another path.
- *Omitting the tracing mode:* a sampled "artificial" and a global one would
  read alike, and the sampled miss [§5.6][s5-6] documents would be assumed away in
  the message.

### D-246 — Diagnose a foreign declaration binding as its own fail-fast kind

**Status.** ratified

**Position.** The shadowing check is one pass of Stratum A's structural walk,
run on every component before its class is read. A parent module holding a
binding of any family name distinct from the framework's function throws
`DeclarationShadowed` alone, naming the module, the foreign names and the
import line that fixes them. No other kind carries a shadowing note.

**Spec.** [§8.1][s8-1], [Appendix C][sC]

**Rationale.** [D-117][d-117] attached the check to `StoreWithoutUpdate` and
`ClassUnreadable` as a note, and [D-220][d-220] chose distinctive names so that a
foreign binding of any of them would be evidence on its own. A note reaches
the reader only where some other diagnostic notices an absence. Seven names
have no such diagnostic, because their absence is legal: `state_events`,
`state_projection`, `init_m` and `init_workspace` on a leaf; `sample_times`,
the two boundary connection declarations and `transparent_container` on an
assembly. A shadowed `state_events` drops every event silently. A shadowed
`sample_times` puts a child on its parent's grid. A shadowed
`transparent_container` renames the children, and the wires to them fail
elsewhere as `UnknownPort`. A kind of its own acts on the evidence for every
name.

Fail-fast follows from what a shadowed module means. Every declaration the
author wrote in it went to a function the framework never dispatches on, so
the component's declaration set is unreadable from the framework's side. The
whole-inventory case shows why a collected sibling would not do.
`ClassUnreadable` is fail-fast and throws alone ([D-229][d-229]), so anything collected
beside it is lost, and its message, "declares neither family", is false from
the author's chair: the declarations were written, the fix is the import line,
and nothing else names it. Running the check before `classify` makes the
shadow diagnostic the one that throws, and the existing kinds need no field.
The evidence is a fact about the module rather than the component: every
component a module defines reads the same foreign list, and the throw names
the first one the walk reaches.

The mechanism is the two-line test [D-117][d-117] described, `isdefined(M, name) &&
getfield(M, name) !== getfield(Cadence, name)` on `M = parentmodule(typeof(c))`,
verified on Julia 1.13.0: a bare definition after `using` reads as foreign, a
per-name import does not, an untouched name is undefined, and a REPL
definition in `Main` behaves the same. Three limits are accepted and
recorded. A type defined in one module and extended in another through
qualified definitions is not checked, since the check reads the type's
module. A user function that legitimately carries one of the family's names
reads as foreign, the price [D-220][d-220] chose the names to keep small. A module
that merely does `using` on a package exporting one of the family's names
reads as foreign with nothing defined locally; the import line the message
spells resolves that case too.

**Rejected.**
- *A note on the diagnostics that notice an absence ([D-117][d-117]'s shape):* leaves
  the seven optional declarations undiagnosed, and the fail-fast
  `ClassUnreadable` would have needed a payload field to carry it.
- *A collected kind:* lost beside the fail-fast `ClassUnreadable` in the
  whole-inventory case, the one [D-117][d-117] named; and a component whose namespace
  is wrong yields only cascades of the one cause when walked past.
- *Scanning every loaded module for the extension site:* heavy, and the
  type's own module is where the trap bites.

### D-247 — Accept the `NamedTuple` as the only store declaration form

**Status.** ratified

**Position.** Every by-value store declaration, `init_x`, `init_s` and
`init_m`, returns a `NamedTuple` with one named field per leaf, and no other
form is admitted. Stratum A checks the form on every primitive before the
tier classifier and the vocabulary checks read the value, and reports a bare
value as `StoreNotNamedTuple`, collected, carrying the store, the observed
type and the wrap that fixes it.

**Spec.** [§7.1][s7-1], [§8.2][s8-2], [§9.1][s9-1], [Appendix C][sC]

**Rationale.** Nothing checked the form, and every reader of a store value
assumes a `NamedTuple`: the tier classifier, the two Stratum A field checks,
`Decls`, the leaf walk and the bundle. Probed on Julia 1.13.0 with leaves
sound otherwise, a `Float64` or an `SVector` from `init_x` and an `Int` from
`init_s` failed as a raw `MethodError` converting to `NamedTuple` in Stratum
C; a `Tuple` from `init_x` failed inside the generated `reconstruct` and one
from `init_s` as a `BoundsError`; a `Vector` from `init_x` segfaulted in the
generated `reconstruct`; a `Symbol` from `init_m` failed as
`isempty(::Symbol)` in the classifier; and an `Int` from `init_m` built
silently as the mode store. The field checks read `pairs(1.0)` without
complaint, so the first refusal came from a stratum that runs user code, or
from the compiler.

The bare leaf was weighed as an ergonomic form for one-state components and
rejected on where the field name does work. Every service reaches a leaf by
its field name: the condition overlay is a `NamedTuple` merge keyed on it
([§14.1][s14-1]), readers and the trace header spell `plant/x.q` ([§11.5][s11-5], [§14.4][s14-4]), the
trim problem's decisions and residuals name it ([§14.7][s14-7]), auto-publication
publishes a state field as the port of the same name ([§5.3][s5-3]), the return laws
pair by it ([§9.5][s9-5]), and the payloads of `IllegalStateLeaf` and
`ConformanceFailure` carry it. A bare leaf would be a second store shape at
each of those seams and would forfeit auto-publication, having no name to
match. The name a one-state component's author is asked for is the name every
service then uses, the discipline `output_types` already asks of ports. The
leaf walk is not the obstacle: an `SArray` lays out wherever it sits.

The check collects under [§13.1][s13-1]'s rule for declarative checks and runs first
in the walk's primitive branch, since the classifier and the field checks
cannot read the value. A primitive that fails it records `nothing` for its
tier and is read no further in Stratum A. An empty `(;)` is the fallback's
own value and keeps reading as "declares nothing".

**Rejected.**
- *A single leaf as a second store form, addressed as the store itself:* a
  second shape at every name-keyed seam (conditions, readers, trace, trim,
  auto-publication, the return laws, the payloads), no auto-publication for
  it, and no grounding model that wants it, the case studies carrying several
  leaves per component.
- *Canonicalizing a bare value into a one-field `NamedTuple` under a synthetic
  name:* wrapped both ways, the author writes `x.value` and gains nothing;
  unwrapped into the bundle and rewrapped at the returns, the bijection is
  owed at every seam and the synthetic name still surfaces in conditions,
  readers, traces and messages.
- *A `:return_type` arm on `ConformanceFailure`:* a declaration-reading
  failure filed under [§9.5][s9-5]'s probed, fail-fast return law.
- *A whole-value arm on `IllegalStateLeaf` or `IllegalStoreField`:* two
  per-field contracts bent, and the fix the message states differs in kind.

### D-248 — Frame every user-authored method the build invokes, declarations included

**Status.** ratified

**Position.** The build frames every user-authored method it invokes through
one framing accessor, and a throw out of one is `UserCodeFraming`, fail-fast,
carrying the component path, the function, the bundle's field names, the
synthesized inputs as a spelling and the original exception as `cause`.

- The framed set is the declarations of [§8.2][s8-2] and the probed functions of [§9.3][s9-3]
  alike. [D-142][d-142]'s list is its inputs-bearing subset.
- The probe context is carried as names and a spelling, never as values,
  under [§13.2][s13-2]'s strings-never-instances rule.
- A `DiagnosticError` carrier, an `InternalInvariant` and an
  `InterruptException` pass through the frame unwrapped.
- A `FieldError` matched against the bundle is `BundleFieldError` at the
  probe and a `StepError` species at [§13.4][s13-4]'s catch site. The probe
  matches by the bundle's own type, which its accessor holds; the catch site
  matches by the bundle's field names, since the activation's bundle type is
  not in hand there. `UserCodeFraming` stays build-only.

**Spec.** [§5.2][s5-2], [§9.3][s9-3], [§13.2][s13-2], [§13.4][s13-4], [Appendix C][sC]

**Rationale.** [D-142][d-142]'s totality contract lists the functions that receive a
bundle, because totality is a claim about inputs. A declaration takes none,
so the bundle-law diagnostic cannot arise inside it, but any other throw can.
Today such a throw escapes `build` raw from whichever of the fourteen call
sites reads the declaration first, with no component path and in no
framework vocabulary, while every other user-code failure at build will name
its path and function once the frame lands. Framing costs nothing at
runtime. The frame is build-time work, a try block on the non-throwing path
is a handler push and pop, and the runtime side adds a classification at the
catch site that already exists rather than a new try. One accessor over the
fourteen sites keeps the frame from being fourteen try blocks, and removes
the repeated re-reads of `init_m` on the way. The context payload reads
"including synthesized inputs" as a spelling because the values would be
instances of the author's own port types, which [§13.2][s13-2] keeps out of every
payload and [D-216][d-216] licenses as spellings.

**Rejected.**
- *Framing [D-142][d-142]'s list alone:* leaves the declarations the one user-code
  surface that fails outside the framework's vocabulary, for no runtime
  saving.
- *One frame per stratum, recovering the function from the backtrace:* the
  frame would name the function by scraping a stack, which [§13.2][s13-2]'s
  structured-not-textual rule forbids.
- *The bundle's values in the payload:* instances of the author's port types
  in a diagnostic, against the strings-never-instances rule.
- *A `UserCodeFraming` species at runtime:* the runtime carrier already
  names the frame and the function through the cursor and carries the
  cause. A second wrapper would say the same thing twice.

### D-249 — Settle three payload columns: contract arity, runtime time and face provenance

**Status.** ratified

**Position.** Three [Appendix C][sC] columns move to what the design needs, and
every other payload shortfall `pending.md` enumerates is a fill from data its
site holds.

- `TierSignatureMismatch` owns all three signature violations [§8.5][s8-5] names, the
  arity arms on a stateful leaf included. `DeclarationOnWrongTier` keeps the
  update laws, the stores, `state_events`, `init_m`, `state_projection` and
  the `init_workspace` arity.
- A runtime `ConformanceFailure` carries no simulation time of its own. The
  `StepError` carrier's frame holds the boundary time and the replay index,
  and that satisfies [§9.5][s9-5]. A handler's occurrence names its event, at the
  probe and at run time alike.
- `FaceNameCollision` carries the assembly path and the colliding names, with
  no per-entry provenance.
- `StopFaceInvalid`'s binding site is one of three, the constructor, `run!`
  or `replay!`, since a replay binds the run policy as `run!` does ([§12.7][s12-7]).

**Spec.** [§8.5][s8-5], [§8.6][s8-6], [§9.5][s9-5], [§12.7][s12-7], [§13.5][s13-5], [Appendix C][sC]

**Rationale.** [D-216][d-216] kept the payload columns as the design and left the
prototype's gaps visible under them. Closing those gaps found three columns
the sites argue against. [§8.5][s8-5] said two things about a contract arity on a
stateful leaf. Its tier paragraph listed a `state_update` beside a
two-argument `output_types` under `DeclarationOnWrongTier`, and its
signature-shape paragraph made any of three signature violations
`TierSignatureMismatch`. One violation family split across two kinds by
whether the leaf holds a store would make an author match on the leaf's
statefulness to catch a wrong contract form. The contract's own kind takes
all three arms, and its payload already spells the form found against the
form mandated. Simulation time on a runtime `ConformanceFailure` would be a
second copy of a value the catch site stamps on every carrier, and filling it
means passing a clock into every generated store write, whose only context
today is the path and the function. The carrier's time and boundary index
are what the replay idiom reads. Provenance on a colliding face name would
say which of two declarations the author wrote by hand, when a computed
entry collides only under an empty or a coinciding prefix, the message
already names the assembly and the faces, and the fix is an `except` entry
or a prefix either way. Carrying it would make the passthrough helpers return
a marked pair, every reader of the two boundary declarations unwrap it, and
the root arm carry a tag with nothing to say, a primitive root having no
computed entries. The `replay!` site is a factual completion: [§12.7][s12-7] binds
`stop_on` there exactly as at `run!`.

**Rejected.**
- *Keeping the contract arity under `DeclarationOnWrongTier` on a stateful
  leaf:* the same wrong form reports as two kinds by the leaf's statefulness,
  and the contract kind's form-found-versus-form-mandated payload goes unused
  on the arity arms.
- *Threading the clock into the generated writes:* duplicates the carrier's
  field, and every store write grows an argument for a value read from one
  place.
- *Marking computed passthrough entries:* a public helper's return shape
  changes, and the root arm's provenance is meaningless, for one word in one
  message.
- *Leaving the three columns as written:* `pending.md` would carry three
  permanent gaps that no increment could close without one of the mechanisms
  above.

### D-250 — Warnings live where the artifact criterion puts them

**Status.** ratified

**Position.** One warning policy replaces the two streams of [§13.2][s13-2]. An
artifact is an immutable pure function of its inputs; state is single-owner
and mutated in place. A warning raised while producing an artifact lives on
that artifact. A warning raised while mutating state lives in that state's
status. Logging is presentation, never a home.

- `Build` and `Deployment` carry `warnings`. A stratum that throws renders
  its warnings with the collection. One that completes carries them on the
  artifact, and the entry point logs each once at return.
- A scoped channel bound by the build around its three steps lets a helper
  running inside a declaration body append to the build's warnings. The same
  helper called standalone, outside any build, logs directly. (Amended by
  increment 44's review: the walk was named as the binder, but a warning may
  arise in any step, so the build binds once.)
- [Appendix C][sC]'s `logged` policy widens from stopped-sim service calls to any
  artifact-producing call, the build included. The collected-warning slot
  stays open and empty ([D-084][d-084] stands).
- `warnings(x)` is defined on `Build` and `Deployment`, and on `Simulation`
  as the concatenation of its artifacts' lists. Status-side warnings stay in
  the status record.
- `EmptyGreedyClaim` moves from a log line to the roster entry's diagnostic
  cell, since `attach!` mutates the roster, and surfaces through the status
  record. The log line at return stays as presentation.

**Spec.** [§9.1][s9-1], [§9.2][s9-2], [§11.3][s11-3], [§11.8][s11-8], [§13.2][s13-2], [Appendix C][sC]

**Rationale.** [§13.2][s13-2] placed warnings by where they were raised: the build's
collection, the runtime's per-writer cells, and a third home for service
warnings that "belong to neither stream" and are emitted once at return
beside the value. That third home was the tell. `trim!` returns a
`TrimReport` and duplicates its warnings into the report's fields because
the report is where a caller looks, which is the artifact criterion applied
once by hand. Stated generally, the criterion decides every case the
redesign meets. A build is an artifact, so an empty selection in a
passthrough helper ([D-251][d-251]) belongs on the `Build`, not on a logger the CI
run never reads. A deployment is an artifact, so `GridUtilization` belongs on
it ([D-254][d-254]). `attach!` mutates the roster, so `EmptyGreedyClaim` belongs in
the entry's cell beside the other writer diagnostics, and the status record
is where a reader finds it after the fact. The channel exists because a
helper inside `input_connections` has no artifact in hand; the build that
owns the steps binds one, and the helper appends without knowing the
build. Outside a build there is no artifact, and a log line is the honest
fallback. Logging each artifact warning once at return keeps the interactive
experience unchanged while the artifact keeps the record.

**Rejected.**
- *The logger as the home:* a CI run, a test and a second session read the
  artifact, never the log; a warning that lives only in a log line is lost
  to every reader but the one at the terminal.
- *A global warning collector:* two concurrent builds would interleave, and
  the collector would outlive the artifact it described.
- *Promoting build warnings to errors under a CI switch:* [§13.2][s13-2] already
  rejects it; an empty selection is a fact about the model worth knowing,
  not a defect.
- *Superseded position — service warnings as a third stream with no home:*
  the artifact criterion covers them; a `TrimReport` is an artifact, and its
  duplicated fields were the criterion applied ad hoc.


### D-251 — Make the passthrough selectors exclusive and warn on an empty selection

**Status.** ratified

**Position.** `input_passthrough` and `output_passthrough` take one selector
per call: `except`, `only`, or a new `select` predicate over face names.

- More than one selector given is `UnknownFaceSelection` with reason
  `:multiple_selectors`, generalizing `:both_given`; the payload names the
  selectors given.
- A selection that names a selector and keeps nothing is the warning
  `EmptyFaceSelection`, a build-stage warning through [D-250][d-250]'s channel. A
  bare call over a faceless child is silent.
- Required-faces declarations are not owed. Recorded as possible sugar.
- The feed-list idiom of [§8.8][s8-8] gets a test transcribing the spec's sketch
  against the real helpers, and no code.

**Spec.** [§8.8][s8-8], [Appendix C][sC]

**Rationale.** [§8.8][s8-8]'s `except` and `only` were mutually exclusive by rule;
adding a predicate kept the rule and needed its arm to say "more than one"
rather than "both". A predicate earns its place at C172X scale, where the
feed list already computes the `except` tuple and a closure over the same
list says the same thing without the tuple. An empty selection is almost
always a typo that the unknown-names check cannot see, `only` naming faces
that exist but a `select` that matches none, or an `except` that lists every
face. It is a warning and not an error because a level may legitimately pass
nothing through under one configuration of a generic child. The
required-faces declaration was the "an assembly declares what it needs from
a child" sugar; the two-producers and obligation checks already state every
violation it would catch, so it adds a spelling and no check. The feed-list
test exists because the spec's sketch is the only statement of the idiom,
and a sketch that the helpers cannot run is a claim without a check.

**Rejected.**
- *Composable selectors (an `except` and a `select` together):* two filters
  on one call read as a set expression; one call, one selector, and a second
  call for a second rule.
- *Silence on an empty selection:* the level compiles and the missing
  faces surface later as unconnected inputs at another level, far from the
  cause.
- *An error on an empty selection:* a generic child with no faces under one
  configuration would refuse to build under a correct declaration.
- *Required-faces declarations:* a second spelling for checks the wire
  resolution already runs.


### D-252 — Remove auto-publishing: two port classes, exposed state returned by stage 1

**Status.** ratified

**Position.** A declared output is produced by stage 1 or by stage 2, and by
nothing else. A component exposes a state or mode field by returning it from
`output_state`. A declared output that no stage produces is
`DeclaredNotProduced`, everywhere and at every tier. `ProducedByTwoStages`
carries the component path and the port name; the two stages are the kind's
own, so the producer column goes with the third class. Supersedes [D-016][d-016]'s
publication rule, [D-152][d-152]'s successor in [D-154][d-154]'s sequence, and [D-169][d-169].

**Spec.** [§5.2][s5-2], [§5.3][s5-3], [§7.5][s7-5], [§8.3][s8-3], [§9.1][s9-1], [§9.3][s9-3], [§10.6][s10-6], [§13.2][s13-2], [Appendix B][sB], Appendix
C, [Appendix D][sD]

**Rationale.** Auto-publishing was a third port class the framework wrote.
It cost more than the line it saved. Stage 1's hand-down had to exclude the
published names ([D-169][d-169]), the classifier probed by name and type and silently
un-published a name held at another type, the executor grew a
`PublishEntry` beside the stage entries, the published set threaded through
every stratum and into `compile`'s key slicing, and a `ConformanceFailure`
arm existed only to refuse a `Float64`-pinned declaration of a walking field
at the `Dual` activation. Each piece was correct and each was there for one
convenience: not writing `output_state(c, (; x)) = (; q = x.q)`. The
2026-09-18 probe over the suite found nine of seventy-eight fixture
components relying on publication, six of them written to test it. The
remaining refusal already exists: `DeclaredNotProduced` names the declared
port, the stage products and the store fields, and its remedy becomes
"return it from `output_state`". With one writer per port the port model is
homogeneous, the `Dataflow` artifact ([D-253][d-253]) classifies by return alone, and
the trace and status surfaces stop distinguishing a framework write from a
stage write.

**Rejected.**
- *Keeping publication as it stood:* the machinery above, for one line per
  exposed field.
- *Opt-in publication sugar (a declaration listing fields to expose):* a
  second way to write `output_state`'s return, with the same classification
  seam.
- *A dev-mode flag publishing every state field ([§11.7][s11-7]'s note):* still
  possible as a debugging aid, but it would be a reader over the stores, not
  a port class; it is recorded, not built.
- *Refusing only at the root:* an unproduced port inside an assembly is the
  same silent zero, one level down.


### D-253 — Stratum products as artifacts: `Structure`, `Dataflow`, `Events`, one activation store

**Status.** ratified

**Position.** Each stratum returns a named, immutable artifact, and the
`Build` is their bundle.

- `Structure` replaces `Flat` as Stratum A's product, with the tiers moved
  in, per-component declaration provenance (the `Relative`/`Absolute` chain)
  and the scope triples of assemblies with an explicit `sample_times` key.
- `Dataflow` is Stratum B's product: per component the stage-1 and stage-2
  name sets, the feedthrough edges with provenance, and the execution order.
- `Events` is Stratum B's other product: per component the event names,
  detection policies and bundle names, produced as B's last step, after the
  nominal stage probes.
- Stratum B is its own function, consuming the structure and returning the
  dataflow, the events and the nominal `Float64` activation, assembled from
  its own probe chain. Stratum C runs for every other scalar, taking the
  structure, the dataflow and the nominal activation as the carry for frozen
  components. No product changes across activations. (Amended by [D-259][d-259]:
  `Events` is probed against the complete nominal products, so B runs the
  whole nominal chain, and a C run at `Float64` would be a second pass.)
- `Build` is structure, dataflow, events and the activations, the nominal
  and the cache merged into one dictionary keyed by scalar type under the
  existing lock.
- Structural consumers read the products, not the `Activation`: readers,
  trim, the tracer, `compile`'s key slicing and the runtime field-error
  species take their name lists from `Structure` and `Dataflow`.
- [§9.1][s9-1] says Stratum B is the nominal evaluation's structural half, and the
  nominal activation is B's products plus C's typing.

**Spec.** [§9.1][s9-1], [§9.2][s9-2], [§9.3][s9-3], [§9.4][s9-4], [§13.3][s13-3], [§13.4][s13-4], [§13.7][s13-7], [§14.1][s14-1], [§14.4][s14-4]

**Rationale.** A step is well-defined when it consumes one new piece of
information and fixes everything that piece determines. Stratum A consumes
the instance. Stratum B consumes one nominal evaluation. Stratum C consumes
a scalar type. The strata were sound as an order, but their products were
not named: A returned a `Flat` with the tiers alongside, B returned nothing
of its own, and every structural fact B fixed lived on the `Float64`
`Activation`, so a reader that wanted a name list took it from a `T`-typed
product. That made the tracer, the readers and trim depend on an activation
for facts no activation determines, and it made "the nominal activation" a
special field rather than the entry for `Float64` in a store of activations.
Naming the products makes the dependency order the type signature. `Events`
is separate from `Dataflow` because it is fixed by a different input, the
event declarations read after the stage probes, and a consumer of the
execution order should not need the event table. [D-049][d-049]'s reasons for a
standalone `Build` hold unchanged: CI targets `build`, conditions resolve
against it, bindings validate against it, one build backs many
deployments. The `Dataflow` name stays although the prose calls the order
"execution order" ([D-258][d-258]): the artifact carries the edges and the name sets
as well as the order, and a graph is what "dataflow" names.

**Rejected.**
- *Keeping `Flat` and the `Activation` as the only carriers:* structural
  consumers stay coupled to a scalar type, and Stratum B has no product to
  test or print.
- *Folding `Events` into `Dataflow`:* produced from different inputs at
  different points in B; a consumer of the order would carry the event table.
- *One function for Strata B and C:* the nominal activation would again fix
  structure and type in one call, which is the coupling being removed.
- *Renaming `Dataflow` to `ExecutionOrder`:* misdescribes two of its three
  parts.


### D-254 — `Deployment` and `Schedule` as artifacts between the build and the simulation

**Status.** ratified

**Position.** Deployment binding produces an artifact, and the `Simulation`
materializes it.

- `Deployment` is the build plus `h`, `N_base`, `Δt_base`, the algorithm
  and the three event parameters. It is scalar-free. It carries the
  `Schedule`, the grid diagnostics of [D-187][d-187] and its warnings.
  `Simulation` materializes a deployment at `T`. Replay compares two
  deployments as values.
- `Schedule` is the typed schedule inside the deployment: per discrete
  component `(D, Φ, Δt)` with anchor and provenance columns, the rate-scope
  rows, and the `D`, `Φ`, `Δt` vectors.
- The grid diagnostics land on the deployment: leave-one-out factors, prime
  attribution, nearest non-refining offsets, the derivation line and
  `GridUtilization`, the last as a deployment warning under [D-250][d-250].
- `Simulation(build; kw...)` and `Simulation(root; kw...)` stay as sugar
  composing the deployment constructor.

**Spec.** [§9.1][s9-1], [§9.2][s9-2], [§10.5][s10-5], [§11.5][s11-5], [§12.7][s12-7], [Appendix C][sC]

**Rationale.** Deployment consumes the grid parameters and fixes everything
they determine, the bound schedule and the grid diagnostics among them, and
none of it depends on the scalar type. Today that step ran inside the
`Simulation` constructor and its products lived as `Simulation` fields:
`sched`, `D`, `Φ`, `Δt`, the grid parameters, the event parameters. The
bound schedule was "a named printable artifact on the `Simulation`"
([D-187][d-187]) with no type of its own, and the grid diagnostics it was to
substrate were never built. A deployment that is an artifact can be
compared, which is what replay's header check does with the deployment
block today by hand, and it can be printed, which is what the anchor and
component tables and the hyperperiod chart need ([D-257][d-257]). It also separates
the two reasons a `Simulation` exists: one build backs many deployments,
one deployment backs many activations at different `T`. The convenience
constructors stay because every existing call site deploys and materializes
in one call, and nothing in the artifact is lost by composing.

**Rejected.**
- *Binding inside the `Simulation` constructor, as today:* the products
  have no type, cannot be compared or printed on their own, and the
  `Simulation` carries twelve fields that are not its.
- *The schedule on the `Build`:* it does not exist until `Δt_base` binds,
  and one build backs deployments with different `Δt_base`.
- *A `Deployment{T}`:* nothing in it depends on the scalar; parametrizing
  it would make two deployments at different `T` unequal.
- *Superseded position — the bound schedule as plain data on the
  `Simulation` ([D-187][d-187]):* the artifact it names now has a type and an owner.


### D-255 — `Run`, the trace split and `StopPolicy`

**Status.** ratified

**Position.** A run is state with a type of its own, and its policy is a
value bound per advance.

- `Run{T}` is a mutable struct with four `const` fields, `t₀`, `mode`, `log`
  and `trace`, and two writable ones, `policy` and `termination`. `init!`
  and `replay!` construct one; the loop's tail writes `termination` once.
  `closed(run)` is `termination !== nothing`.
- `Run` is a `Simulation` field beside `control`, so `Simulation` is a
  mutable struct. A `Simulation{T}` is constructed with a placeholder run
  (`t₀ = zero(T)`, `mode = :live`, empty log and trace, no termination) that
  `init!` and `replay!` replace; `Control.lifecycle` says whether it
  started. `termination` leaves `Control`, which keeps the stop word, the
  lifecycle and the wait. `init!` allocates fresh objects rather than
  clearing.
- `Trace{T}` is a fixed header plus two append-only lists, `schemas` and
  `batches`, and its length, the drains since the capture. The header loses
  its schema list; `attach!` and `detach!` push onto the list in place. The
  drain advances the length on the live trace, and `trace(sim)` freezes it
  into the value it hands back; no reader of the run needs it, every reader
  of the length reads a trace. The register keeps its cursor fields and the
  replay feed.
- `StopPolicy` replaces `RunPolicy`: an immutable value of `t_end` plus the
  stop faces and their addresses, built and validated by each advance and
  rebound on `Run.policy`. `hit` leaves it for the loop's scratch beside the
  cursor. `ControlRequestedStop` is outside the policy: the policy is what
  the caller declares, the stop word is what anyone can issue.
- `t_end` and `stop_on` leave the constructor and are keywords of `run!` and
  `replay!`, with `Inf` and no faces as defaults, validated per call.
  `step!` states the same defaults itself. [§13.5][s13-5]'s second binding site goes.
  A run with `Inf` and no faces is allowed and raises `UnboundedRun` into
  the loop's diagnostic cell, the status record carrying it.
- The trace header holds the `Deployment` and `t₀`, no policy. Only the
  terminating advance's policy explains the stop, and the termination record
  holds that one.

Supersedes [D-091][d-091], [D-217][d-217]'s header-records-the-constructor-pair bullet, and
[D-060][d-060]'s "policy at `Simulation` construction" clause; [D-060][d-060]'s rule that
termination is state, never an exception, stands.

**Spec.** [§11.5][s11-5], [§12.1][s12-1], [§12.4][s12-4], [§12.6][s12-6], [§12.7][s12-7], [§13.5][s13-5], [Appendix C][sC]

**Rationale.** The run was spread across the `Simulation`'s fields and the
control plane. `termination` sat on `Control` beside the stop word, so the
outcome of a run and the surface anyone may poke shared a struct;
`RunPolicy` was mutable because `hit` was written into it by the loop, so a
declared policy and a loop scratch shared a struct; the trace header grew
its schema list in place, so an artifact captured at `init!` was not
immutable; and `t_end`/`stop_on` had two homes, the constructor and the
call, which [§13.5][s13-5] called "the honest cost" of [D-091][d-091]. Each of those is the
state/artifact criterion violated once. A `Run` collects what one run owns.
Its `const` fields are the ones the constructing entry point fixes; its
writable ones are the ones the loop advances. A `StopPolicy` is what the
caller declares for one advance, so it is a value the advance builds, and
the defaults belong to the calls that take it. With no constructor defaults
the second binding site disappears and the trace header has no policy to
record; the terminating record carries the policy that ended the run, which
is the only one a replay reader needs. The placeholder run at construction
is preferred to a `nothing` field because every accessor then has a run to
read, and `lifecycle` already says whether it is meaningful. An unbounded
run is allowed because it is the interactive session's ordinary shape, with
`UnboundedRun` as its advisory and the operator interrupt as its escape
([§13.5][s13-5]); the advisory lives in the loop's cell because `run!` mutates state.

**Rejected.**
- *Constructor defaults for `t_end` and `stop_on` ([D-091][d-091]):* two homes for
  one fact, with a precedence rule to reconcile them.
- *A mutable `RunPolicy` carrying `hit`:* the declared policy and the loop's
  scratch in one struct.
- *`Run` as an immutable value rebuilt per frame:* the log and trace are
  append-only state; copying them per frame is the allocation [§7.5][s7-5] forbids.
- *`termination` staying on `Control`:* the control plane is what anyone
  may poke; a run's outcome is not.
- *A `Union{Nothing,Run}` field:* every accessor branches on a state
  `lifecycle` already reports.
- *Refusing an unbounded run:* the interactive session's ordinary shape
  would need a sentinel `t_end`.


### D-256 — Regroup the `Simulation`'s fields by owner

**Status.** ratified

**Position.** `Simulation` keeps five fields: the deployment, the executor,
the run, the plane and the control. The build is reached through the
deployment, which is the build plus what the grid parameters fix, so a second
reference to it would be an invariant with no enforcer. Every other field
moves to its owner.

- To the deployment: `h`, `N_base`, `Δt_base`, the three event parameters,
  `sched`, `D`, `Φ`, `Δt` ([D-254][d-254]).
- To the executor: `chunk_size`, `stepper`, `xnext`, `ẋnext`,
  `has_localized`.
- To the periphery's own types: `join_timeout` into `Control`; `loop_diag`,
  `loop_acct` and `published` into the plane.
- To the run: `t_end`, `stop_on`, `stop_addrs`, `policy`, `log`, `trace`
  ([D-255][d-255]).
- Constructor keywords follow their fields. The `Deployment` constructor
  takes the grid and event parameters and the algorithm. `join_timeout`,
  `trace`, `log`, `log_every` and `log_max` are keywords of
  `Simulation(deployment, T)` and of the two convenience forms, the
  recording flags carried to `init!`, which builds the run. `DeploymentInvalid`
  names deployment parameters only; the materialization's keywords validate
  under `ArgumentInvalid`.

**Spec.** [§9.7][s9-7], [§11.2][s11-2], [§11.8][s11-8], [§12.1][s12-1], [§12.4][s12-4], [Appendix B][sB], [Appendix C][sC]

**Rationale.** The `Simulation` had twenty-eight fields because it was the
only struct standing between a build and a running loop, so every value
deployment or the loop needed landed on it. With `Deployment` and `Run`
typed, each field has an owner by the same criterion that placed the
warnings: an artifact's fields go to the artifact, a piece of state goes to
the state that mutates it. The executor owns its stepper and the arrival
buffers because it is the one thing that writes them. `join_timeout` is the
shutdown tail's parameter and the tail runs on `Control`. The loop's
diagnostic cell and account are one more writer's, and the plane holds the
writers. The five that remain are the five things a simulation is.

**Rejected.**
- *Leaving the fields flat:* every reader of a grid parameter or a buffer
  goes through the `Simulation`, so nothing below it can be tested or printed
  alone.
- *A separate `Periphery` struct for the plane, control and published
  holder:* the plane already is that struct.


### D-257 — Each artifact renders itself

**Status.** ratified

**Position.** The build-side and deployment artifacts print through `show`
methods, with no accessors.

- `show(::Structure)` prints the anchor table with the `A₀` row and the
  component table with the rate-scope rows. `show(::Dataflow)` prints the
  execution order with port classes. `show(::Schedule)` prints the rows and
  the hyperperiod chart. `show(::Build)` and `show(::Deployment)` print a
  summary and their parts.
- The chart guard is binary: the chart prints whole when `lcm(Dᵢ)` is at
  most 100 base ticks, and otherwise the hyperperiod's length with "chart
  omitted".
- The face-provenance printer joins `Structure` when the routing chain is
  recorded; that is `pending.md`'s "Smaller" bullet, unchanged.

**Spec.** [§9.2][s9-2], [§13.7][s13-7]

**Rationale.** [§9.2][s9-2] owes the anchor table, the component table and the
hyperperiod chart, and [D-187][d-187] gave the chart a guard "against absurd
hyperperiods" without saying what the guard does. With the artifacts typed
([D-253][d-253], [D-254][d-254]), each table is one type's `show`, and a REPL user gets it by
evaluating the value, which is what "printable" has meant since [D-049][d-049]. The
guard is binary because one hyperperiod is the complete truth: the pattern
repeats with period `lcm(Dᵢ)`, so a prefix is a sample that the chart's own
argument says not to trust. A hundred base ticks is a screen.

**Rejected.**
- *Accessor functions returning tables:* a second API for what `show`
  already is.
- *Prefix rendering of a long hyperperiod:* a sample presented as a chart
  whose claim is completeness.
- *Superseded position — an unspecified guard ([D-187][d-187]):* the guard is now a
  rule.


### D-258 — "Schedule" is the tick timing and "execution order" the stage sequence

**Status.** ratified

**Position.** The spec uses "schedule" for the per-component tick timing,
matching `Schedule`, and "execution order" for the order in which the stage
functions run, carried by the `Dataflow` artifact. "Ordering" is the
activity. "Bound schedule" is retired. [§5.1][s5-1] is "The ordering problem",
Stratum B's heading is "execution order", and the glossary's "sweep" is one
pass through the execution order.

**Spec.** [§5.1][s5-1], [§5.3][s5-3], [§9.1][s9-1], [§9.2][s9-2], [§10.5][s10-5], [Appendix D][sD]

**Rationale.** One word carried two senses: the topological order Stratum B
computes and the `(D, Φ, Δt)` table deployment binds. With both becoming
types ([D-253][d-253], [D-254][d-254]) the prose had to pick. The tick table keeps "schedule"
because that is what the word means in the multi-rate literature and in
[§10.5][s10-5]. The stage sequence is an order, so it is called one. A first sweep
used "dataflow" for it and read wrongly at most sites: a dataflow is a
graph, and the spec speaks of positions in the order, subsets of it, and
re-running it, none of which a graph has. The type keeps the name because it
carries the graph. The log keeps its vocabulary of the day under
`decisions_style.md` rule 2; the sweep is the spec's and its companions'.

**Rejected.**
- *"Dataflow" for the order:* a graph has no positions.
- *Renaming `Dataflow` to match the prose:* the artifact is more than the
  order.
- *Keeping "bound schedule":* with the anchor-relative triples in
  `Structure` and the bound table in `Schedule`, "bound" no longer
  distinguishes anything.

### D-259 — Retire the strata: the build is three steps named by their products

**Status.** ratified

**Position.** The spec names the build's steps by what they produce and
retires "stratum".

- The three steps are the structure step (the root instance in, `Structure`
  out), the nominal evaluation (`Structure` in; `Dataflow`, `Events` and the
  nominal `Float64` `Activation` out) and activation at a scalar
  (`Structure`, `Dataflow` and the nominal activation in, `Activation{T}`
  out). [§9.1][s9-1] opens with a table of what each step consumes and produces,
  with the deployment and the materialization on it as the steps after the
  build.
- Each step is a barrier, as each stratum was ([§13.1][s13-1]). No user stage code
  runs before the structure step completes. The nominal evaluation's
  products are names only. Only activation re-runs per scalar.
- The activation gloss is "the build's typed products at a given scalar
  type". "Stratum A" reads "the structure step", "Stratum B" "the nominal
  evaluation", "Stratum C" "activation"; [Appendix C][sC]'s group headings, [§9.6][s9-6]'s
  heading and the glossary follow.
- The log keeps its vocabulary of the day (`decisions_style.md` rule 2).
  [D-253][d-253]'s fourth bullet is amended in place to the nominal evaluation's
  return.

**Spec.** [§5.6][s5-6], [§6.1][s6-1], [§8.2][s8-2], [§8.5][s8-5], [§9.1][s9-1], [§9.2][s9-2], [§9.4][s9-4], [§9.6][s9-6], [§13.1][s13-1], [§13.2][s13-2], [§13.3][s13-3], [§14.3][s14-3], [Appendix C][sC], [Appendix D][sD]

**Rationale.** The strata were named before any step existed as code. Once
each step had a product ([D-253][d-253]), each letter had become a second name for
that product: "Stratum A's product" for `Structure`, "a re-run of Stratum C"
for an activation. A term that needs the product's name to be understood is
the product's name. The letters also encoded a sequence the pipeline does
not run. [D-253][d-253] as first written had Stratum C complete the nominal
activation from B's stage-1 products, but `Events` is probed against every
component's complete nominal product and the layout, so B runs the whole
nominal chain, and a C run at `Float64` would be the separate pass [§9.1][s9-1]
forbade. Stating each step by what it consumes and produces says that seam
plainly: the nominal evaluation consumes one evaluation at `Float64` and
fixes both the structure and the `Float64` typing, and activation consumes
another scalar and fixes the typing at it. Everything the strata carried
survives without the word: the barrier rule, the line between declaration
reading and evaluation, and the line between structural and typed products.
"Step" is the noun because the spec already uses it for deploying and
materializing ([§9.2][s9-2]), and the integration step is always qualified
("integration step", "step boundary", `step!`).

**Rejected.**
- *Keeping the letters with restated definitions:* the definitions would
  have been the products' names with a letter in front.
- *"Stage", "phase" or "pass" as the generic noun:* each already names
  something (the stage functions, the sweep phases and the tick phase, the
  declarative passes within a step).
- *One function for the nominal evaluation and activation:* [D-253][d-253]'s
  rejection stands; the nominal evaluation fixes structure and an activation
  does not.


### D-260 — Trim the run to what lasts it and retire the trace register

**Status.** ratified

**Position.** A `Run{T}` holds what lasts from one door to the next and the
state that evolves in between. The stop policy, the origin and the drain's
bookkeeping leave it.

- `Run{T}` is a mutable struct of four fields: `const log`, `const trace`
  (`nothing` under the trace switch), `feed` (the attached recording, or
  `nothing`) and `termination`. `init!` and `replay!` construct one and
  rebind `sim.run`; nothing else rebinds it. `live!` and the halt at the
  recording's end write `feed`; the loop's tail writes `termination` once.
  `closed(run)` is unchanged.
- The input mode is read, not stored. `mode(sim)` is `:replay` while a feed
  is attached and `:live` otherwise. A change of mode is a write to the run,
  not a change of run.
- The stop policy is the advance's argument. `run!`, `replay!` and `step!`
  build it, pass it to the loop and to the record's assembly, and drop it.
  The termination record is the policy's one lasting home.
- The origin `t₀` is not a run field. The clock holds it, `init!` and
  `replay!` set it, and the trace header records it. It is a `Float64`, like
  `h` and `t_end`; the clock's `t` stays in the deployment's scalar.
- `TraceRegister` retires. The drain thunks close over the run's trace and
  are recompiled at every door and roster change, as they already were. The
  frame ordinal a record carries is the trace's own `frames`, incremented at
  the top of the drain. The current writer set's index range is local to the
  recompile. The trace switch rides on the run: a run built under
  `trace = false` has no trace.

Supersedes [D-255][d-255]'s first bullet, its "the register keeps its cursor fields
and the replay feed" clause and its "rebound on `Run.policy`" clause, and
[D-256][d-256]'s "the trace switch on the register the plane holds". [D-218][d-218]'s mode,
"a register the caller can read", is `mode(sim)`, unchanged as an
observable.

**Spec.** [§11.5][s11-5], [§12.6][s12-6], [§12.7][s12-7], [§13.5][s13-5], [Appendix B][sB]

**Rationale.** [D-255][d-255] classed the run's fields by whether the door fixed them
or the loop advanced them. The policy fit neither. An advance declares it,
the loop reads it as an argument, and the field on the run was written at
every `run!` and `step!` only so two readers without the argument, the t*
sampling read and the record's assembly, could reach it. It does not shape
the trajectory, since a stepped and a run simulation are bit-identical
whatever each call declared ([§12.6][s12-6]), and only the terminating advance's
policy is ever read afterwards, off the record. `t₀` on the run had no
reader: every consumer of the origin, the frame count, the grid time and the
header capture, read the clock's. `mode` was `const`, so a flip rebuilt the
run, but a flip keeps the log and the trace, which is what makes it the
same run; and the feed was attached exactly while the mode was `:replay`,
an invariant the code guarded with an internal throw. One field states
both. Of the register's five fields, the trace duplicated the run's, the
frame was a courier to the thunk that the trace's own drain count already
carries, the writer range was read only where it was written, and the
switch is a fact about the run's trace. The thunk cannot take the ordinal
as an argument: it is called through an untyped field, and a boxed `Int`
would allocate on the frame path ([§7.5][s7-5]). Closing over the trace, a mutable
object, keeps the ordinal reachable at no cost. The origin's type follows
the grid's. `h` and `t_end` are `Float64` already, and a `Dual` origin with
a nonzero partial, a start-time perturbation, has no reader in the design.
A `Float64` origin also lets `init!` take `t0 = 0.25` on a `Dual`
simulation, which a `T`-typed keyword refused.

**Rejected.**
- *A run per advance, owning its policy:* the log and the trace span
  advances, so consecutive runs would share them and own neither; and an
  advance that halts at a frame top leaves nothing of its policy behind.
- *An immutable `Run` rebuilt at every flip and at the close:* the flips and
  the close keep the log and the trace, so a rebuild there spells "the same
  run" as a new object.
- *The termination record as `run!`'s return value:* the errored path
  rethrows and returns nothing, `step!` already returns the frame count, and
  [D-060][d-060] chose state over exception so a stopped simulation answers from any
  task and at any later time.
- *`mode::Symbol` beside the feed:* two fields that must agree, and the
  throw that guarded them.
- *The `Run` holding the `Simulation`:* every run would be a live handle to
  the executor's buffers, so a stale run after a warm restart would advance
  the new trajectory under the old run's name, an invariant with no
  enforcer ([§9.2][s9-2]).
- *The frame ordinal as the thunk's argument:* a boxed `Int` per drain per
  writer, on the frame path.


### D-261 — Three ownership rules for fields, with the placements they settle

**Status.** ratified

**Position.** Three rules decide where a value lives, and the placements
below settle under them.

- A struct holds what it owns or what it must retain across calls. A callee
  takes what it reads as an argument, never off a field added to a container
  it already holds.
- An artifact holds declared facts. Its consumer compiles what it needs from
  them once, at one home, and the activation's cell layout is that home for
  address facts.
- An object is built after its inputs exist. The placeholder an accessor
  needs is the one exception, and it carries no configuration and no
  compiled state.
- The `Schedule` is its component rows and its rate-scope rows, the `Δt`
  column among them. The per-component `(D, Φ, Δt)` the executor compiles
  over are derived from the rows at `compile`.
- A `t*` stop hit is `frame!`'s return value, a face or `nothing`. The
  execution cursor keeps its dispatch fields alone.
- `StopPolicy` is `t_end` and the stop faces. Their compiled addresses are
  the loop's argument, bound by the advance and carried to the sampling read.
- `trace`, `log`, `log_every` and `log_max` are keywords of `init!` and
  `replay!`, the doors that build a run, with their defaults unchanged.
  `Simulation(deployment, T)` keeps `join_timeout` and `chunk_size`. The
  placeholder run is an empty log and no trace, and `trace(sim)` refuses a
  traceless `built` simulation on the lifecycle before it reads the switch.
- The roster entry keeps the stable device id and the handle drops its copy.
  The entry reads its writer, its diagnostic cell and its binding through
  the handle.
- A snapshot carries its frame index beside its published-boundary ordinal.
- The periphery resolves root faces against the activation's cell layout
  alone. It carries the root faces in structure order with their probe
  values beside the address table, so the periphery's schema lookups and
  its layout lookups ([§14.3][s14-3]'s two families) both read it, and writers,
  claims and the harness compile against it.
- The data plane compiles no drain thunk at construction. The thunks are
  compiled at each door and each roster change, at one site that takes the
  store as an argument.
- `Deployment.grid`, `Dataflow.edges`, the header fingerprint's root faces,
  and `StepError`'s time and boundary beside `NonfiniteState`'s payload stay
  as they are.

Supersedes [D-254][d-254]'s "`D`, `Φ`, `Δt` vectors" clause, [D-255][d-255]'s "stop faces
and their addresses" and "`hit` leaves it for the loop's scratch beside the
cursor" clauses, and [D-256][d-256]'s clause making the recording flags keywords of
`Simulation(deployment, T)`. [D-260][d-260]'s "the trace switch rides on the run"
stands.

**Spec.** [§9.2][s9-2], [§11.2][s11-2], [§11.3][s11-3], [§11.5][s11-5], [§12.6][s12-6], [§13.5][s13-5], [Appendix B][sB]

**Rationale.** A survey of every struct in `src/` (104 structs, 22
findings, `docs/reports/20260921_data_survey/`) found no field with two
writers and no shared mutable state without an owner. What it found was
redundancy and reach, and two mechanisms produced most of it. Reach: a
callee needs one more value, it already holds a container, and the
container grows a field instead of the callee growing an argument. The
walk's root types, the cursor's hit, the plane's store, the handle's plane
and the recording flags on the placeholder run were all this. [D-260][d-260] stated
the test for the stop policy, a field written only so a caller without the
argument can reach it, and applied it to that one field. Declared beside
compiled: an artifact is the value a user inspects and also the table the
next stage consumes, and where the two forms differ the artifact grows a
compiled shadow of itself, the schedule's vectors beside its rows, the
policy's addresses beside its faces, a plan's face slot beside its face
list. Stating the rules makes the fixes an application rather than twenty
local judgments, and gives every later increment a check.

The placements follow. The schedule's vectors are the rows re-indexed by
component, built in the same loop, and `==`, `hash` and the replay header
walk each carried a clause the rows already decide. The hit as a return
value costs no allocation and leaves the cursor to the catch site it exists
for. The addresses are derivable from the faces and the layout, and nothing
reads them off the record. The recording keywords configure the run's two
`const` fields, which the doors build, so [D-256][d-256]'s own rule, keywords follow
their fields, puts them on the doors. On the constructor they rode a
placeholder run through every later door, and `trace === nothing` meant
both "switched off" and "no door yet". Per-run recording comes with the
move, a long untraced run and then a short traced one on one simulation,
at no cost the doors did not already pay, since each rebuilds the log, the
trace and the drain thunks. The device id survives a stop on the entry
([§12.4][s12-4]), so the handle's copy was the dead one. The frame index is what
places a `t*` snapshot in its frame, since a `t*` publication counts an
ordinal of its own. The layout already holds the three facts the periphery
reads, the faces, their types through the address parameter and their
probe values, so reading both lookups off it costs one sentence where
resolving against the structure instead would cost four signatures and a
parallel-vector invariant across two structs. A thunk compiled before the
first door closes over a trace that door discards, and the constructor's
compile was the one reason the run had to be built ahead of the plane.

**Rejected.**
- *The recording flags as a sixth `Simulation` field:* a parameter nothing
  on the simulation reads, on the struct whose five fields are the five
  things a simulation is ([D-256][d-256]).
- *The flags on `Control` beside `join_timeout`:* a recorders' parameter on
  the control plane by convenience alone.
- *The periphery resolving root faces against the `Structure`, as the
  services do:* uniform, but four signatures and a parallel-vector
  invariant for names the layout already holds.
- *Dropping the schedule's `Δt` column for `D · Δt_base`:* the row is the
  printable schedule and `Δt` is what it prints; the product is the same
  float either way.
- *Skipping the thunk compile at a roster change before the first door:* a
  lifecycle test in `reclaim!` to save one small closure per attach.
- *A nullable run in place of the placeholder:* [D-255][d-255]'s rejection stands.
  The placeholder stays and is emptied.

---

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-001]: #d-001--hybrid-causal-formalism-with-two-tier-events-and-projection
[d-002]: #d-002--adopt-the-causal-port-based-paradigm
[d-003]: #d-003--component-taxonomy-hybrid-primitive-periodic-discrete-assemblies
[d-004]: #d-004--immutable-value-signals-in-a-typed-signal-table
[d-005]: #d-005--reject-algebraic-loops-at-build
[d-006]: #d-006--two-stage-structural-feedthrough-via-h_xh_xu
[d-007]: #d-007--aggregation-mechanism
[d-008]: #d-008--function-valued-environment-signals-with-the-handle-pattern
[d-009]: #d-009--restrict-deep-paths-to-owned-assembly-types
[d-010]: #d-010--structure-continuous-state-as-immutable-values-over-a-flat-backing
[d-011]: #d-011--eltype-genericity-on-the-continuous-path
[d-012]: #d-012--set-propagation-tracers-and-scc-based-cycle-diagnostics
[d-013]: #d-013--immutable-discrete-state-via-cells-workspace-and-snapshot
[d-014]: #d-014--scoped-allocation-invariant-ci-enforced
[d-015]: #d-015--fused-evaluation-of-derivatives-and-outputs
[d-016]: #d-016--uniform-component-interfaces-via-h_x-and-per-event-re-decode
[d-017]: #d-017--framework-owned-simulation-loop-with-a-stepper-seam
[d-018]: #d-018--tier-2-event-localization-via-dense-output-and-bracketed-root-finding
[d-019]: #d-019--harmonic-tick-grid-with-virtual-assemblies-and-rate-scopes
[d-020]: #d-020--boundary-event-phase-iterates-to-quiescence
[d-021]: #d-021--pacer-piecewise-affine-wall-clock-mapping-with-bounded-debt
[d-022]: #d-022--periphery-architecture-no-shared-mutable-model
[d-023]: #d-023--snapshot-publication-via-atomic-acquire-release
[d-024]: #d-024--inbound-staging-per-device-atomic-batch-cells
[d-025]: #d-025--one-uniform-device-kind
[d-026]: #d-026--gui-write-path-panels-name-their-own-ports
[d-027]: #d-027--pacer-coarse-phase-uses-task-yielding-sleep
[d-028]: #d-028--next-snapshot-wait-via-monotonic-counter-and-condition-variable
[d-029]: #d-029--input-trace-on-by-default
[d-030]: #d-030--shutdown-protocol-publish-wake-unblock-join
[d-031]: #d-031--mid-run-mutation-doctrine-staging-and-control-commands-only
[d-032]: #d-032--component-declaration-trait-layer-with-probe-checked-schema-authority
[d-033]: #d-033--declaration-inventory-by-value-by-type-by-allocation-conventions
[d-034]: #d-034--contract-visibility-declared-fields-are-public
[d-035]: #d-035--stores-and-views-components-read-zero-copy-view-bundles
[d-036]: #d-036--table-mechanics-stage-returns-are-namedtuples-of-port-values
[d-037]: #d-037--aggregation-by-explicit-summing-junctions
[d-038]: #d-038--snapshot-and-log-derived-trajectory-primary-trace-header
[d-039]: #d-039--assembly-declaration-is-type-based
[d-040]: #d-040--slash-string-paths-as-the-canonical-path-form
[d-041]: #d-041--dedicated-exports-for-assembly-faces
[d-042]: #d-042--rates-declaration-on-immediate-children-only
[d-043]: #d-043--computed-exports-via-ordinary-code-and-faces
[d-044]: #d-044--slot-exclusivity-and-the-write-surface-rule
[d-045]: #d-045--periphery-input-semantics-derived-liveness-conditioning-mappings-edge-logic
[d-046]: #d-046--face-names-are-opaque-string-tokens-slash-is-reserved-for-structure
[d-047]: #d-047--stage-widgets-on-interaction-events-not-every-pass
[d-048]: #d-048--three-stratum-build-pipeline-structure-schedule-activation
[d-049]: #d-049--standalone-buildworld-artifact-wrapped-by-simulation
[d-050]: #d-050--probe-every-user-function-once-at-build-at-nominal-t
[d-051]: #d-051--synthesize-probe-inputs-via-a-probe_valuetype-fallback-chain
[d-052]: #d-052--scope-dual-probing-to-each-activations-executable-set
[d-053]: #d-053--bake-one-always-on-conformance-check-at-every-table-write
[d-054]: #d-054--producers-determine-activation-types-consumers-stay-generic
[d-055]: #d-055--require-strict-local_types-declaration-for-cross-stage-cells
[d-056]: #d-056--uphold-the-two-kind-taxonomy-against-the-integrate-and-dump-challenge
[d-057]: #d-057--batch-declarative-check-violations-abort-on-first-user-code-exception
[d-058]: #d-058--diagnostics-as-structured-values-under-one-builderror-carrier
[d-059]: #d-059--catch-runtime-failures-at-one-boundary-site-into-steperror
[d-060]: #d-060--graceful-termination-is-model-state-never-an-exception
[d-061]: #d-061--resolve-walks-declared-types-to-enforce-the-generic-boundary-rule
[d-062]: #d-062--tooling-commitments-face-predicates-build-printer-component-library
[d-063]: #d-063--conditions-are-path-addressed-sparse-overlays-on-init_-defaults
[d-064]: #d-064--compose-per-component-init-by-pull-via-fragment-functions
[d-065]: #d-065--fragments-form-a-lazy-inert-tree-resolved-against-the-build
[d-066]: #d-066--two-ways-to-apply-one-plan-specialized-apply-vs-dynamic-entry-list-walk
[d-067]: #d-067--boundary-zero-runs-the-macro-sequence-with-an-empty-integrate
[d-068]: #d-068--enforce-slot-totality-at-the-initcommit-service-boundary
[d-069]: #d-069--trim-problem-spelling-namedtuples-residual-vector-exact-ad-jacobians
[d-070]: #d-070--trim-service-in-house-dense-lm-behind-a-swappable-backend
[d-071]: #d-071--mount-trim-as-an-implicitly-specified-condition-via-at
[d-072]: #d-072--linearization-surface-three-selector-lists-one-chunked-dual-pass
[d-073]: #d-073--companion-sketches-carry-the-settled-condition-algebra-design
[d-074]: #d-074--hand-off-component-function-arguments-as-one-named-bundle
[d-075]: #d-075--name-flowupdateoutput-stages-by-letter-and-dependence-class
[d-076]: #d-076--name-declarations-input_typesoutput_typeslocal_types-by-convention
[d-077]: #d-077--allocate-workspace-via-a-per-activation-workspace-method
[d-078]: #d-078--treat-input-entries-as-face-constraints-checked-by-subtyping
[d-079]: #d-079--type-declarations-concretely-resolved-by-an-activation-leaf-walk
[d-080]: #d-080--keep-tier-2-event-detection-pace-independent
[d-081]: #d-081--treat-t-as-a-boundary-not-a-frame
[d-082]: #d-082--define-guard-conditions-against-a-per-event-baseline
[d-083]: #d-083--bind-output-device-reads-to-snapshot-paths-not-just-faces
[d-084]: #d-084--drop-the-unconnected-output-warning
[d-085]: #d-085--unpack-tuplenamedtuple-fields-as-container-children
[d-086]: #d-086--compile-the-executors-schedule-into-unrolled-statically-typed-entries
[d-087]: #d-087--freeze-the-device-roster-as-a-build-validated-immutable-value
[d-088]: #d-088--define-the-run-lifecycle-built--initialized--running--stoppederrored
[d-089]: #d-089--route-supervisor-gains-and-resets-through-ordinary-ports
[d-090]: #d-090--return-handler-updates-as-bundle-law-namedtuples
[d-091]: #d-091--override-t_endstop_on-per-run-at-run
[d-092]: #d-092--normative-diagnostic-kind-table-appendix-c
[d-093]: #d-093--spawn-device-tasks-per-run-not-per-attach
[d-094]: #d-094--close-the-state-leaf-vocabulary-to-plain-scalars-and-sarrays
[d-095]: #d-095--prefix-the-read-selector-family-with-get_
[d-096]: #d-096--define-the-harness-writer-stagelateststep-duration
[d-097]: #d-097--split-device-shutdown-failures-into-two-diagnostic-kinds
[d-098]: #d-098--resolve-selectors-against-a-source-before-client-policy
[d-099]: #d-099--spell-the-ci-activation-invariant-with-a-canonical-probe-scalar-type
[d-100]: #d-100--freeze-u-at-round-start-for-within-round-event-visibility
[d-101]: #d-101--implement-replay-as-the-ordinary-loop-with-two-substitutions
[d-102]: #d-102--author-owned-device-loop-inside-a-framework-owned-bracket
[d-103]: #d-103--detect-a-bindings-sides-by-method-presence-at-attach
[d-104]: #d-104--coalesce-staged-writes-by-cas-merge-with-per-attachment-positional-shape
[d-105]: #d-105--split-device-side-bad-datum-handling-into-tolerated-garbage-and-propagated-crashes
[d-106]: #d-106--freeze-the-device-roster-for-the-duration-of-a-run
[d-107]: #d-107--match-trace-record-density-to-batch-density-not-surface-width
[d-108]: #d-108--gate-stopped-sim-services-by-input-derived-lifecycle-preconditions
[d-109]: #d-109--fix-device-identity-roster-admission-and-calling-task-topology-at-attach
[d-110]: #d-110--give-trim-an-explicit-t0-argument-and-state-its-recording-clear
[d-111]: #d-111--fold-project-into-the-always-on-conformance-check
[d-112]: #d-112--add-events-to-the-tier-consistency-markers
[d-113]: #d-113--close-four-kindless-diagnostic-rules-with-new-payload-fields
[d-114]: #d-114--order-snapshot-publication-before-the-boundary-counter-increment
[d-115]: #d-115--source-the-bundle-laws-remaining-probe-fields-t-and-ws
[d-116]: #d-116--expose-phase_bodiessim-as-the-zero-allocation-invariants-measurement-seam
[d-117]: #d-117--extend-declarations-and-stages-via-explicit-per-name-import
[d-118]: #d-118--trimproblem-authoring-surface
[d-119]: #d-119--add-simulationbuildbuild--as-a-second-constructor
[d-120]: #d-120--reconcile-rigs-with-abstract-at-root-via-stub-children
[d-121]: #d-121--partition-the-cellstore-vocabulary-and-bless-staging-cell
[d-122]: #d-122--resolve-de-polysemy-by-giving-each-overloaded-term-one-owner
[d-123]: #d-123--add-a-non-normative-appendix-d-glossary
[d-124]: #d-124--widen-147s-reads-grammar-to-the-full-service-selector-set
[d-125]: #d-125--admit-get_face-to-the-service-reads-set
[d-126]: #d-126--give-trim-commit-events-a-report-channel
[d-127]: #d-127--add-a-deployment-block-to-the-trace-header-for-replay-validation
[d-128]: #d-128--define-to_boundary-as-the-frame-entry-boundary-index
[d-129]: #d-129--restate-the-two-notation-rule-as-directional-structure-vs-contract
[d-130]: #d-130--scope-resolves-generic-boundary-duty-by-client-wiringserviceinspection
[d-131]: #d-131--apply-the-round-4-consistency-sweep-findings-411
[d-132]: #d-132--treat-operator-interrupt-ctrl-c-as-a-control-plane-stop-not-a-failure
[d-133]: #d-133--split-spec-invoked-numeric-constants-into-deployment-parameters-vs-owning-section-defaults
[d-134]: #d-134--declare-the-interactive-write-surface-class-via-a-binding-marker-method
[d-135]: #d-135--scope-the-activation-cache-to-immutable-compiled-artifacts-keyed-on-the-build
[d-136]: #d-136--unify-diagnostics-and-liveness-heartbeat-into-one-per-writer-diagnostic-cell
[d-137]: #d-137--bound-snapshot-log-retention-by-count-with-amortized-doubling-stride
[d-138]: #d-138--make-device-init-an-explicit-bracketed-step-of-the-run-start-protocol
[d-139]: #d-139--give-environment-field-handles-a-value-level-constructor-to-prevent-drift
[d-140]: #d-140--add-a-three-rung-remedy-ladder-for-artificial-algebraic-loop-dependencies
[d-141]: #d-141--continuous-state-resets-are-events-owned-by-the-reimplemented-pivector
[d-142]: #d-142--stage-code-must-be-total-over-type-valid-inputs
[d-143]: #d-143--add-a-constant-source-block-for-zero-contributor-aggregates
[d-144]: #d-144--rename-the-computed-exports-helper-faces-to-passthrough
[d-145]: #d-145--deduplicate-pass-through-except-lists-with-a-shared-feed-list-idiom
[d-146]: #d-146--rename-facesselectors-to-claimsreads-on-the-binding-interface
[d-147]: #d-147--split-the-sweep-into-static-interior-and-boundary-variants
[d-148]: #d-148--select-converters-per-leaf-by-resolved-condition-shape-type
[d-149]: #d-149--check-slot-totality-wherever-a-virgin-world-is-established
[d-150]: #d-150--make-the-service-the-sole-authority-on-convergence
[d-151]: #d-151--canonicalize-namedtuple-field-order-at-every-authorframework-seam
[d-152]: #d-152--join-auto-publication-to-the-per-event-re-decode-at-stage-1
[d-153]: #d-153--add-re-arm-tracking-to-complete-the-once-per-event-rule
[d-154]: #d-154--remove-per-event-re-decode-serialize-same-component-events
[d-155]: #d-155--name-projection-as-the-second-legitimate-mover-of-the-committed-point
[d-156]: #d-156--legalize-the-three-degenerate-trimintegration-shapes
[d-157]: #d-157--check-for-nonfinite-x-immediately-after-integrate
[d-158]: #d-158--pin-the-backend-seam-to-one-required-solve-signature
[d-159]: #d-159--define-warning-service-as-a-sixth-severity
[d-160]: #d-160--rename-report-to-report
[d-161]: #d-161--grow-the-naming-audit-to-the-full-class-violation-set
[d-162]: #d-162--adopt-per-eltype-homogeneous-cell-stores-over-per-instance
[d-163]: #d-163--ban--for-separately-compiled-float-comparisons
[d-164]: #d-164--reject-components-that-declare-nothing-and-define-no-stage
[d-165]: #d-165--split-output-stage-returns-into-public-y-and-private-w
[d-166]: #d-166--mandate-typet-output-signatures-on-continuous-producers
[d-167]: #d-167--mandate-typet-input-signatures-under-the-permissive-reading
[d-168]: #d-168--root-slot-fan-out-tolerance-combines-by-meet-not-agreement
[d-169]: #d-169--y_xy_z-carry-stage-1-ports-only-auto-published-excluded
[d-170]: #d-170--split-assembly-connections-into-childinputoutput-declarations
[d-171]: #d-171--rename-passthrough-to-input_passthrough
[d-172]: #d-172--rule-face-kind-blind-defined-at-first-use
[d-173]: #d-173--fuse-the-discrete-state-letter-z-into-x
[d-174]: #d-174--re-class-the-gui-as-an-ordinary-enumerated-writer
[d-175]: #d-175--re-scope-gui--true-to-a-run-scoped-attachment
[d-176]: #d-176--unify-trace-retention-on-one-sparse-record-format
[d-177]: #d-177--re-found-the-periphery-on-mandatory-roots-plus-declared-traits
[d-178]: #d-178--reaffirm-component-side-rejections-against-the-peripherys-new-idiom
[d-179]: #d-179--derive-detection-policy-from-the-guards-return-type
[d-180]: #d-180--bank-per-event-direction-as-an-unbuilt-guarded-addition
[d-181]: #d-181--replace-once-per-boundary-firing-with-budgeted-re-firing
[d-182]: #d-182--add-a-θ0-validation-probe-to-the-localization-trigger
[d-183]: #d-183--retire-workspace-poisoning
[d-184]: #d-184--fold-group-into-the-spec-as-an-ordinary-library-component
[d-185]: #d-185--adopt-the-phased-two-form-sample-time-declaration
[d-186]: #d-186--legalize-absolute-declarations-in-any-scope-via-anchors
[d-187]: #d-187--make-the-bound-schedule-a-named-artifact-with-exact-grid-diagnostics
[d-188]: #d-188--construct-trimproblem-by-keyword-everywhere
[d-189]: #d-189--unify-report-on-a-single-address-diagnostic-shape
[d-190]: #d-190--reject-a-separate-derivative_type-declaration
[d-191]: #d-191--defer-not-consume-the-edge-on-a-blocked-event
[d-192]: #d-192--let-the-greedy-claim-empty-the-harness-remainder
[d-193]: #d-193--keep-per-writer-liveness-on-one-timestamp-plus-task-state
[d-194]: #d-194--retire-the-w-channel-intermediates-are-declared-ports
[d-195]: #d-195--give-the-discrete-state-its-own-letter-s
[d-196]: #d-196--rename-the-phase-body-sweeps-to-stage-numbered-names
[d-197]: #d-197--reject-discrete-stores-in-linearizations-x-tap-list
[d-198]: #d-198--promote-the-shutdown-join-timeout-to-a-deployment-keyword
[d-199]: #d-199--the-reads-enumeration-returns-a-labeled-namedtuple-of-selectors
[d-200]: #d-200--the-harness-writer-has-its-own-cell-and-is-diagnostic-only
[d-201]: #d-201--the-terminal-account-closes-at-the-final-frame-top
[d-202]: #d-202--stage-batches-as-values-plus-touched-mask-never-union-tuples
[d-203]: #d-203--the-termination-record-carries-typed-sources-and-the-tail-residue
[d-204]: #d-204--rename-the-condition-algebras-symmetric-combinator-to-combine
[d-205]: #d-205--boundary-zero-publishes-every-discrete-output-stage-due-or-not
[d-206]: #d-206--rename-root-slots-to-root-inputs
[d-207]: #d-207--route-every-connection-one-level-faces-are-the-only-cross-boundary-currency
[d-208]: #d-208--root-inputs-are-the-root-components-input-faces-whatever-its-class
[d-209]: #d-209--build-output_passthrough
[d-210]: #d-210--tighten-the-input-boundary-class-uniform-face-uniqueness-and-no-empty-routing
[d-211]: #d-211--let-a-component-declare-one-container-name-transparent
[d-212]: #d-212--refuse-the-transparent-bare-key-that-shadows-a-sibling-container-field
[d-213]: #d-213--establish-a-services-frozen-cells-from-the-authored-discrete-state
[d-214]: #d-214--split-appendix-cs-severity-column-into-severity-raised-and-policy
[d-215]: #d-215--extend-appendix-c-with-the-kinds-the-prototype-raised
[d-216]: #d-216--conform-appendix-c-to-the-prototypes-diagnostic-sites
[d-217]: #d-217--conform-the-trace-and-replay-sections-to-the-prototypes-record
[d-218]: #d-218--make-the-replaylive-distinction-an-explicit-input-mode
[d-219]: #d-219--add-a-time-addressed-replay-halt-and-a-manual-door-to-live
[d-220]: #d-220--rename-the-authoring-family-to-words-stage-update-projection-event-and-workspace-declarations
[d-221]: #d-221--unwrap-a-single-diagnostic-carrier-at-the-runtime-catch-site-into-a-steperror-species
[d-222]: #d-222--replace-builderror-with-the-policy-parametric-diagnosticerror-carrier
[d-223]: #d-223--host-the-runtime-catch-in-boundary-zero-under-the-services-disposition
[d-224]: #d-224--let-a-throw-inside-a-trim-commit-propagate-as-the-commits-steperror
[d-225]: #d-225--parametrize-steperror-on-its-causes-type
[d-226]: #d-226--reach-the-public-surface-by-qualified-name-until-16s-export-audit
[d-227]: #d-227--select-the-stepper-by-type-under-the-algorithm-keyword
[d-228]: #d-228--attribute-runtime-diagnostics-by-cell-never-by-payload
[d-229]: #d-229--collect-to-the-stratum-barrier-under-a-dependency-rule
[d-230]: #d-230--stamp-the-snapshot-with-the-trajectorys-boundary-ordinal-not-the-wait-counter
[d-231]: #d-231--require-isbits-store-values-checked-at-build
[d-232]: #d-232--refuse-the-roster-operations-on-an-errored-simulation
[d-233]: #d-233--retire-the-termination-records-absent-time-arm
[d-234]: #d-234--rename-the-deployment-keyword-n-to-n_base
[d-235]: #d-235--realize-the-always-on-check-at-the-generated-write-against-the-cell-type
[d-236]: #d-236--type-check-a-wire-by-one-relation-with-embedding-in-stratum-a
[d-237]: #d-237--classify-a-non-isbits-immutable-port-type-as-one-opaque-leaf
[d-238]: #d-238--decide-embed-accept-on-the-type-lift-the-arrival-compare-exactly
[d-239]: #d-239--report-a-typod-return-field-alone-without-the-unproduced-port
[d-240]: #d-240--read-the-heartbeat-at-publication-beside-the-task-state
[d-241]: #d-241--keep-the-status-a-vector-of-records-one-small-allocation-per-publication
[d-242]: #d-242--name-the-resolution-cases-wiring-service-and-inspection-and-retire-register-and-load-bearing-as-spec-vocabulary
[d-243]: #d-243--classify-symbol-as-an-opaque-port-leaf
[d-244]: #d-244--refuse-the-write-primitives-of-a-detached-handle-by-name
[d-245]: #d-245--classify-a-cycle-cluster-by-a-surviving-traced-cycle-and-carry-each-members-tracing-mode
[d-246]: #d-246--diagnose-a-foreign-declaration-binding-as-its-own-fail-fast-kind
[d-247]: #d-247--accept-the-namedtuple-as-the-only-store-declaration-form
[d-248]: #d-248--frame-every-user-authored-method-the-build-invokes-declarations-included
[d-249]: #d-249--settle-three-payload-columns-contract-arity-runtime-time-and-face-provenance
[d-250]: #d-250--warnings-live-where-the-artifact-criterion-puts-them
[d-251]: #d-251--make-the-passthrough-selectors-exclusive-and-warn-on-an-empty-selection
[d-252]: #d-252--remove-auto-publishing-two-port-classes-exposed-state-returned-by-stage-1
[d-253]: #d-253--stratum-products-as-artifacts-structure-dataflow-events-one-activation-store
[d-254]: #d-254--deployment-and-schedule-as-artifacts-between-the-build-and-the-simulation
[d-255]: #d-255--run-the-trace-split-and-stoppolicy
[d-256]: #d-256--regroup-the-simulations-fields-by-owner
[d-257]: #d-257--each-artifact-renders-itself
[d-258]: #d-258--schedule-is-the-tick-timing-and-execution-order-the-stage-sequence
[d-259]: #d-259--retire-the-strata-the-build-is-three-steps-named-by-their-products
[d-260]: #d-260--trim-the-run-to-what-lasts-it-and-retire-the-trace-register
[d-261]: #d-261--three-ownership-rules-for-fields-with-the-placements-they-settle
[s10-1]: spec.md#101-loop-ownership-the-framework-owns-the-simulation-loop
[s10-2]: spec.md#102-the-stepper-seam
[s10-3]: spec.md#103-signal-table-consistency-is-a-boundary-property
[s10-4]: spec.md#104-localization-mechanics
[s10-5]: spec.md#105-multi-rate-tick-scheduling
[s10-6]: spec.md#106-event-iteration-at-boundaries-to-quiescence-budgeted
[s10-7]: spec.md#107-real-time-pacing
[s11-1]: spec.md#111-no-shared-mutable-model-staged-writes-snapshot-reads
[s11-2]: spec.md#112-outbound-snapshot-publication
[s11-3]: spec.md#113-inbound-root-inputs-claims-and-the-frozen-roster
[s11-4]: spec.md#114-inbound-per-device-staging-representation-and-the-drain
[s11-5]: spec.md#115-inbound-the-input-trace
[s11-6]: spec.md#116-devices-one-authoring-contract-no-taxonomy
[s11-7]: spec.md#117-the-gui-write-path-port-resolution-peek-staging-contract
[s11-8]: spec.md#118-diagnostics-and-liveness-the-per-writer-cell
[s12]: spec.md#12-runtime-periphery-lifecycle-and-orchestration
[s12-1]: spec.md#121-control-plane
[s12-2]: spec.md#122-loop-scheduling-wait-primitive-yields-thread-budget
[s12-3]: spec.md#123-the-next-snapshot-wait
[s12-4]: spec.md#124-shutdown-protocol
[s12-5]: spec.md#125-scripts-and-the-mid-run-mutation-doctrine
[s12-6]: spec.md#126-run-lifecycle-and-partial-advance
[s12-7]: spec.md#127-replay-the-trace-re-drives-the-ordinary-loop
[s13]: spec.md#13-error-discipline
[s13-1]: spec.md#131-reporting-policy-collect-the-checks-fail-the-evaluations-fast
[s13-2]: spec.md#132-diagnostics-structured-values-one-carrier-exception
[s13-3]: spec.md#133-build-primitives-resolve-and-the-face-list-accessors
[s13-4]: spec.md#134-runtime-failures-one-catch-site-an-execution-cursor
[s13-5]: spec.md#135-termination-is-a-state-not-an-exception
[s13-6]: spec.md#136-abnormal-shutdown-one-tail-two-entries
[s13-7]: spec.md#137-tooling-consequences-provenance-and-the-component-library
[s14]: spec.md#14-stopped-sim-services
[s14-1]: spec.md#141-conditions-are-path-addressed-overlays-on-the-declared-defaults
[s14-10]: spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s14-2]: spec.md#142-fragment-composition-locality-without-schema
[s14-3]: spec.md#143-resolution-flatten-validate-compile-once
[s14-4]: spec.md#144-one-plan-two-ways-to-apply-it
[s14-5]: spec.md#145-boundary-zero-an-ordinary-boundary-with-authored-incoming-transitions
[s14-6]: spec.md#146-root-input-totality-the-missing-value-error-and-the-override-combinator
[s14-7]: spec.md#147-the-trim-problem-namedtuple-decisions-declared-reads-named-residuals
[s14-8]: spec.md#148-the-trim-service-solver-seam-scratch-stores-commit-and-report
[s14-9]: spec.md#149-mounting-problems-as-relocatable-values
[s15-1]: spec.md#151-vehicle-today--this-framework
[s15-2]: spec.md#152-torture-tests-for-the-52-interfaces-pistonengine-and-the-fcs-pid-cascade
[s15-3]: spec.md#153-torture-test-for-the-11-staging-shapes-filter-joystick-and-gui
[s15-4]: spec.md#154-the-interactive-c172x-demo-the-periphery-under-load
[s15-5]: spec.md#155-the-strapdown-imu-integrate-and-dump-across-the-tier-boundary
[s16]: spec.md#16-open-axes
[s2-1]: spec.md#21-events-two-detection-policies
[s2-2]: spec.md#22-exclusions-deliberate
[s3]: spec.md#3-component-taxonomy
[s3-1]: spec.md#31-continuous-component-the-hybrid-primitive
[s3-2]: spec.md#32-periodic-discrete-component
[s3-3]: spec.md#33-assembly
[s4-1]: spec.md#41-immutable-value-semantics
[s4-2]: spec.md#42-consumers-see-ports-not-stages
[s4-3]: spec.md#43-table-mechanics-and-port-granularity
[s4-4]: spec.md#44-function-valued-signals-environment-access
[s5-1]: spec.md#51-the-ordering-problem
[s5-2]: spec.md#52-two-stage-outputs-signatures-bundles-and-the-hand-off-laws
[s5-3]: spec.md#53-structural-feedthrough-stage-roles-execution-order-and-step-boundaries
[s5-4]: spec.md#54-artificial-loops-and-the-escape-hatch
[s5-5]: spec.md#55-algebraic-loop-policy-reject-at-build-time
[s5-6]: spec.md#56-diagnostics-feedthrough-tracing
[s6]: spec.md#6-composition-connections-aggregation-and-hierarchy
[s6-1]: spec.md#61-connections-and-hierarchy
[s6-2]: spec.md#62-aggregation-explicit-summing-junctions
[s7]: spec.md#7-state-and-data-representation
[s7-1]: spec.md#71-continuous-state-structured-immutable-flat-backing
[s7-2]: spec.md#72-numeric-genericity-eltype
[s7-3]: spec.md#73-discrete-state-modes-and-workspace
[s7-4]: spec.md#74-the-fused-evaluation-lineage-prior-art-and-how-we-got-here
[s7-5]: spec.md#75-allocation-policy-a-scoped-invariant
[s8]: spec.md#8-the-declaration-layer-components-and-assemblies
[s8-1]: spec.md#81-position-a-declarative-trait-layer-in-plain-julia-no-macros
[s8-2]: spec.md#82-the-declaration-inventory
[s8-3]: spec.md#83-visibility-the-contract-is-the-interface
[s8-4]: spec.md#84-failure-walkthroughs-the-error-locality-grounding
[s8-5]: spec.md#85-assembly-declaration-type-based-class-by-declaration-shape
[s8-6]: spec.md#86-paths-wiring-and-faces
[s8-7]: spec.md#87-rate-scopes
[s8-8]: spec.md#88-computed-connections-and-generic-holding
[s9]: spec.md#9-the-build-pipeline
[s9-1]: spec.md#91-the-builds-three-steps
[s9-2]: spec.md#92-the-build-artifact
[s9-3]: spec.md#93-probing-and-input-synthesis
[s9-4]: spec.md#94-activations-executable-sets-laziness-caching
[s9-5]: spec.md#95-the-always-on-conformance-check
[s9-6]: spec.md#96-stopped-sim-services-as-activation-clients
[s9-7]: spec.md#97-the-compiled-executor
[sA]: spec.md#appendix-a-taught-contracts-the-author-facing-index
[sB]: spec.md#appendix-b-api-synopsis-the-entry-points
[sC]: spec.md#appendix-c-the-diagnostic-kind-set
[sD]: spec.md#appendix-d-glossary
[sD-10]: spec.md#d10-meta-vocabulary
[sD-3]: spec.md#d3-evaluation-and-scheduling
[sD-6]: spec.md#d6-runtime-periphery
[sD-8]: spec.md#d8-stopped-sim-services-and-the-condition-algebra
