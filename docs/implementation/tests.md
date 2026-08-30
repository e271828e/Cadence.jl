# Test-property notes

The optional companion to `status.md`: the property-by-property record of what
the tests pin down. Read it when modifying an existing test or wondering why one
asserts what it does; nothing here is needed to orient a coding session — that
is `status.md`'s job.

Each of these is a spec claim rather than a programming convenience:

- **The schedule is derived, not authored.** Stage-1 (`h_x` continuous, `h_s`
  discrete) ports carry no
  input dependence, so consuming one adds no edge to the feedthrough graph. The
  reference model's feedback path closes through the plant's `h_x` port and
  schedules as `sum → ctl → plant`; rewiring the same loop through the plant's
  stage-2 port makes it a genuine algebraic loop and the build rejects it by
  name.
- **Derivative completeness is structural.** `f` returns a value shaped like
  `init_x`; the probe checks the shape once and the runtime scatter into the
  flat `ẋ` block is then safe by construction. A forgotten field is impossible,
  not merely detectable.
- **The phase-body roster is fixed and total.** `phase_bodies(sim)` always
  returns all four bodies. A model with no discrete components still gets
  `ticks`, empty — it compiles to a no-op, and its `@ballocated` assertion
  passes vacuously, which is the point: consumers iterate the roster with no
  per-model branching.
- **The allocation invariant is width-independent.** Chunking bounds compile
  cost, never the runtime claim: a phase body of 18 one-entry chunks
  (`chunk_size = 1`, a chunk count no other fixture approaches) walks both
  variants at zero allocation, so the §7.5 canary covers the outer walk over
  the chunk tuple itself, not just the entry walks within one chunk.
- **Tier is read off the declaration shape, never announced.** For a stateful
  leaf the whole name family carries it — `init_x`/`h_x`/`h_xu`/`f` continuous
  against `init_s`/`h_s`/`h_su`/`g` discrete, the two disjoint (D-195), with
  the update law the decider; for a stateless one the contract arity does.
  Every other tier-implying declaration must agree, and disagreement names the
  offending one — `g` beside a two-argument `output_types`, `init_m` on a
  discrete leaf, both arities of one contract, and the wrong-letter case the
  split families restore: a continuous stage name on a leaf whose update law is
  `g`.
- **The ZOH is not implemented.** It is the absence of any way to change a
  discrete cell mid-step: the interior sweep is compiled from continuous
  entries alone, so the hot path carries no gating test, and a discrete cell
  cannot move across a step because nothing in that walk writes it.
- **A wiring endpoint reaches exactly one level.** The same `"inner/sum/a"`
  against the same `SampledLoop` value is a build error whether the field is
  declared `::SampledLoop` or `::L` — the declaring type's knowledge stopped
  being the question with D-207 — and `"inner/ref"`, the sub-assembly's own
  face, builds under either holder to the same trajectory. A container's key
  segment rides along inside the one level (`"units/1/e"`), which is what lets
  a container's elements be addressed by their parent's own declarations.
- **Being fed is a whole-tree obligation, not a per-declaration one.** An unfed
  child input inside one assembly is merely awaiting a claim from above — a
  sibling wire, or an `input_connections` entry handing it up a level, which
  an ancestor's route then feeds through the face. The error fires at the root,
  for the chain that never terminates; the one legitimate terminus is the root
  component's own input face. The one-producer rule spans levels the same way,
  so an ancestor's route onto an input a sub-assembly already wires is caught
  where the two claims meet, with both entries named.
- **A face is derived, never declared.** It owns no cell: it resolves — through
  as many levels of re-export as there are — to its ultimate internal endpoint,
  and takes that endpoint's type and tier. `Vehicle`'s `y` and `cmd` are one
  assembly's faces sourced from the two tiers, and at a `Dual` activation `y`
  walks while `cmd` stays pinned, with nothing anywhere declaring either.
- **An anchored divisor does not exist until `Δt_base` binds.** The `Build`
  carries `(anchor, m, c)` triples against exact rational anchors, and the same
  `Build` lands `MultiRate`'s gnss at `D = 10` or `D = 5` depending on the
  deployment keywords — with nothing writable shared between the two
  `Simulation`s, because each materializes its own stores and buffers. The
  worked example compiles to exactly §9.2's table.
- **Due-ness is one subtraction and one remainder, at boundaries only.** The
  interior walk is untouched by increment 5 — no index reaches it — and a step
  boundary that is not a base tick runs the zero-arg bodies, which *are* the
  boundary walk with every discrete entry gated out. The multi-rate sampled
  loop only matches its exact discretization at `Δt_ctl = D·Δt_base = 4h` if
  the gate admits the controller at exactly its own ticks, the hold spans the
  sub-ticks, and the bundle's `Δt` is the compiled schedule's — one test, three
  ways to fail it.
- **A cell holds what the build probe populated until a sweep first writes it.**
  Entry compilation seeds every cell from the probe products, so an offset
  component's pre-first-tick reads and a frozen component's pinned cells are
  the same story (§10.5, §9.3) rather than a lucky zero.
- **The nominal activation runs at build; any other is a Stratum-C re-run.**
  `activation(b, T)` materializes at first request and caches on the `Build`
  (§9.4); structure and schedule are computed once and shared. A frozen
  component sits outside the non-nominal executable set: its stages are never
  probed there, and its complete products — cells included — are carried
  across from the nominal activation, holding what a tick at `t₀⁻` computed
  from real upstream values rather than anything synthesized. That is what
  makes a discrete stage reading `t` lawful (it is `Float64` whenever the
  stage actually runs), and why a pinned-leaf lurk detonates at the `Dual`
  activation — or eagerly, via `build(root; activations = (Float64, D8))`,
  the CI idiom — rather than at `build`.
- **The guard's form is the declared policy.** `Event(guard, handler)` carries
  no detection keyword: the probe runs every guard at the nominal activation
  and its return type decides — `Bool` boundary-detected, the nominal scalar
  localized, anything else an error naming both admissible forms (D-179). The
  policy lands on `Build.policies` and compiles into the event set's mask,
  which is what the frame loop's trigger check reads — the mixed predicate
  rides the gate idiom `(gate) ? σ : -one(σ)`, whose return type keeps it
  localized. Guards and handlers are outside every non-nominal activation's
  executable set (D-052), so at a `Dual` deployment the event phase compiles
  to the bare sweep, a mode never moves, and the frame loop takes the bare
  step with no arrival machinery at all.
- **A cascade is logically simultaneous, not one link per step.** The event
  phase iterates [sweep → guards → handlers] to quiescence within one boundary,
  so a supervisor → follower → follower chain settles in three rounds at any
  `h` — the latency an integrator parameter must never buy. Eligibility inside
  the boundary is an edge like any other, read against the last-observed
  sample: a sticky predicate fires once, and firing is at most one event per
  component per round, first eligible in declaration order — priority with
  re-decision. The one register subtlety is D-191's: an eligible-but-blocked
  event's sample is *not* overwritten, so its edge stands into the next round,
  while a premise the earlier transition falsified re-decides against the
  post-transition sweep and simply does not fire.
- **Budget exhaustion degrades; it does not throw.** A toggling pair spends
  `firing_budget` per event at one boundary under a `FiringBudget` warning (at
  most once per event per boundary), the rest of the model iterates untouched,
  and the run proceeds — the quiescent samples become honest priors, so the
  chatterer presents no fresh edge afterward. The registers are detection
  bookkeeping in plain vectors, in no state store; boundary zero establishes
  every prior as not-holding, so a predicate holding in the authored state
  fires at `t₀`, and a warm restart fires it again — derived, not asserted.
- **Projection runs between a state write and its decode.** At every boundary
  `project` runs after the integrate and before the sweep — boundary zero
  included, so an off-manifold `init_x` lands on the manifold before the first
  cell is published — and each firing is `handler → project`. The probe holds
  its return complete against the state shape, which is what makes the
  wholesale buffer write-back safe by construction.
- **Due updates run after quiescence.** Ticks stay outside the iteration: at a
  wrap boundary the handler resets the state, the re-sweep publishes the
  post-transition value, and only then does a sampled consumer's `g` read it —
  one test, and the wrong order costs the full pre-reset value, orders of
  magnitude outside its tolerance.
- **`t*` is an observation, and the stamp proves it.** A handler reads `t` from
  its bundle, so a stamping handler is the direct observable: a localized
  firing lands within `localization_tol` of the true crossing — exactly, on a
  trajectory the cubic Hermite reproduces; at `O(h⁴)` on the rotor — and at
  the *holding endpoint* of the final bracket, never before the crossing. The
  trajectory-level counterpart is the discarding reset: `Bouncer`'s period is
  exact under localization where boundary-resolution firings would accumulate
  a full overshoot per reset, while `Sawtooth`'s carrying handler shows the
  complement — its boundary states are firing-resolution-invariant, so the
  boundary recursion stays its exact reference.
- **The θ = 0 validation discriminates the edge's cause, before any
  interpolant cost.** A root-input write between runs is the frame-top epoch
  seam: the re-measured σ₀ holds under the frame's own `u`, so the edge is the
  drain's, no in-frame crossing exists, and the event falls through to fire at
  the frame top *exactly* — the indexed grid time, no budget spent, nothing
  warned. The gate idiom's `Bool` flip is the same story. And a crossing
  landing on the grid point itself degenerates the other way: every interior
  trial is not-holding, the localization is discarded, and the firing is
  bitwise the boundary-detected one.
- **Multiple crossings fire earliest-first, and ties need no decision.** Each
  triggered event is root-found, the boundary fires at the minimum `t*`, and
  the later crossing simply does not hold there — it re-triggers on the
  remainder against a fresh interpolant. A tie is one localization: both edges
  stand at the shared `t*` and fire inside that one boundary's iteration,
  which a budget of 1 proves by not warning.
- **The budget counts `t*` boundaries, and exhaustion degrades.** Per segment,
  root-finding runs are structurally bounded at one per declared event; the
  segment count is what chattering inflates, so `localization_budget` prices
  exactly that. The relaxer spends 8 localizations in one frame, warns
  `ChatteringBudget` once — naming the event and the count — and its next
  crossing fires at the frame top: boundary granularity for that frame alone,
  the remainder having already completed.
- **Ticks are never due at `t*`.** The `t*` boundary is the off-tick §10.6
  sequence — projection, the full iteration, priors settled — and nothing
  else: a sampled consumer beside a localized event accumulates only frame-top
  samples, where a spurious tick would have added the mid-frame value.
  Discrete cells ZOH-hold through the trials for the increment-3 reason:
  the interior sweep the trials run has no discrete entries to gate.
- **The integration method is a deployment binding, and nothing outside its
  own struct knows which one ran.** `method = Heun` swaps the backend with the
  loop, the localization machinery and every model unchanged, and the
  convergence orders fitted through that one surface — 4 and 2 against the
  same matrix-exponential reference — pin each backend as itself, where a
  shared loose tolerance would let a mislabeled one hide. The dense-output
  obligation rides the seam too: a localized stamp under Heun lands at the
  discrete solution's O(h²) through the same Hermite trials, and the
  frame-top stamps stay bitwise, having never depended on the method.
- **A staged write is pending, never applied.** `stage!` from any task touches
  no live root input; the batch lands at the top of the next frame `run!`
  advances — and nowhere earlier. A batch staged while stopped waits through
  boundary zero (`init!` runs on the un-drained root input — the contrast with
  `set_slot!` before `init!`, which makes a holding predicate fire at `t₀`),
  and the frame's outcome is a pure function of the drained batch: the staged
  trajectory is bitwise the directly-written one.
- **Merge is the only coalescing policy, and every check runs at staging.**
  Newest wins per face and untouched faces survive — a sparse `b` batch cannot
  clobber a pending `a` (§15.3's flaps/gear hazard), a re-staged face takes
  the newest level. The checks run on the writer's side: a face with no
  position in the schema is discarded under `OutOfClaimEntry`, an
  unconvertible value under `EntryTypeMismatch`, the rest of the batch stands,
  and the drain is pure application — the shim having already converted to the
  activation's root-input types, so a `Dual` deployment stages plain reals. The
  empty drain is allocation-free: a quiet loop's frame top costs nothing.
- **Nothing reachable from a published snapshot is ever written again.**
  Publication is one buffer copy and one release-store after the boundary
  sequence completes — boundary zero included, off-tick frame tops included —
  and the snapshot is the whole table, root inputs riding along as the source
  cells they are, state stores deliberately absent (§11.2). The run moves on;
  the snapshot holds. A concurrent reader acquire-loading `latest` sees only
  coherent worlds — the in-lockstep pair `g2 = 2·g1` holds bitwise in every
  observed snapshot, and `t` never decreases — and a task staging against
  running frames loses nothing to the CAS merge: the last staged level is what
  stands.
- **One writer per root input at any time, structurally.** Claims are disjoint
  by admission, so cross-writer races on one cannot arise and no drain-order
  arbitration policy exists to need. The admission's order is itself pinned:
  the same instance re-attached under an overlapping claim is
  `AlreadyAttached`, never a self-`ClaimConflict`, because identity runs before
  claims — which is what keeps `ClaimConflict` always naming two *distinct*
  devices. Identity is the instance (`===`): the library's stub devices are
  mutable structs precisely so two same-named `Pad`s are two devices.
- **One claim mechanism, two claim sources, exhausted at the attach point.**
  A returned claim is the enumeration, validated face by face
  (`AttachUnknownFace`) — the empty enumeration an honest may-write-nothing
  degenerate, not a back door. A computed claim is the unclaimed complement at
  the attach instant, never recomputed, so attaching the greedy claimant last
  is the idiom and a second greedy stakes the empty remainder under
  `EmptyGreedyClaim`. Downstream nothing tells the sources apart: the greedy
  entry's out-of-claim staging is the same `OutOfClaimEntry` as anyone's.
- **The harness register's surface is derived, never claimed.** It is the
  unclaimed complement, recomputed at every roster change: a harness write to
  a claimed face is `ClaimedFaceEntry` naming the incumbent, a rostered greedy
  empties the surface outright and every harness `stage!` in such a session is
  rejected that way (D-192), and detach regrows it. The recompilation's one
  seam is renormalization: a batch staged before a stopped-sim `attach!` is
  reshaped through the new schema — the newly claimed face discarded with the
  incumbent and the site named, the rest surviving to the drain — so the run
  always starts with cells matching the run's schemas.
- **The roster is frozen per run, and the drain stays free.** `attach!` and
  `detach!` against a running loop are `ServiceLifecycle`, from any task, and
  the freeze lifts with the run; device ids are monotonic per `Simulation`,
  never reused, and a rejected attach consumes none. The per-writer drain
  thunks are compiled at the same stopped-sim points, so a populated roster's
  empty drain still allocates nothing — and the frame's outcome stays a pure
  function of the drained batches, whoever staged them: the device-staged
  trajectory is bitwise the directly-written one.
- **Every boundary publishes, and the log is the publications themselves.** A
  localized firing's `t*` boundary releases its own snapshot before
  integration resumes — the log holds a snapshot whose `t` is bitwise the
  stamped `t*`, carrying the settled post-transition table while the boundary
  before it still shows the armed value — and `logged(sim)[end] ===
  latest(sim)`: retention is reference-keeping over what publication already
  built, zero extra copies (D-023). What a localizing frame allocates is
  exactly that publication, the framework-side §7.5 carve-out, and nothing of
  the localization machinery's own.
- **Retention is a view policy under a continuously-held bound.** Deployments
  differing only in `log`/`log_every`/`log_max` produce bitwise-identical
  trajectories. The middle never exceeds `log_max` at any boundary — one
  release pairs with each retained append — and when the log fills the stride
  doubles: coverage stays global at `log_every · 2^k`, the middles landing on
  consecutive multiples of the effective stride with the whole run spanned,
  while the boundary-zero and latest snapshots outlive any policy, outside
  the bound. The off switch retains nothing; publication is upstream of it,
  so `latest` still sees every boundary.
- **The handle is the device's whole world.** It carries read, stage and
  control — never the `Simulation` — and a device staging through it from its
  own spawned task changes nothing the drain can see: the frame's outcome
  stays a pure function of the drained batches, and a device-requested stop
  truncates the run at a frame top with the batch it staged still pending,
  applied at the next run's first drain and nowhere earlier.
- **The bracket holds on every exit path.** Voluntary return, a crash, and a
  failed `init!` all run `shutdown!` exactly once — the crash warned as
  `DeviceCrash` with the run continuing, the failed `init!` spawning no task
  and never reaching `loop` — and in every case the claims persist to run
  end: death is not detach, and the harness register still cannot take a dead
  device's face. `should_abort` splits the run's disposition uniformly: a
  flagged crash stops the run, a flagged `init!` failure leaves the stop
  already pending and the run advances zero frames.
- **The run's end is a protocol, not a return.** The stop word is observed at
  frame top only, the final snapshot goes out before the sticky status is
  set — so a body observing `running(handle)` false can still read a complete
  final world — the waits wake, `unblock!` turns a parked blocking call into
  a clean exit inside the cap, and a body that ignores the predicate is
  abandoned under `join_timeout` with `DeviceJoinTimeout` naming it, `run!`
  returning regardless. Abandonment is not a kill: the straggler's wrapper
  still runs `shutdown!` when it finally returns. The word clears at the next
  run's top, which owes nothing to the last one's stop.
- **The calling task is pinned by trait, and the loop is the movable piece.**
  A `needs_calling_task` device's body runs on exactly the task that invoked
  `run!`, inside the same wrapper as any spawned loop, while the frame loop
  runs spawned — and the trajectory is bitwise the deviceless one, topology
  being scheduling, never semantics. A device with no `loop` method crashes
  by name at its first spawn instead of idling as attached-but-inert.
- **A waiter never wakes onto a stale snapshot.** The release-store of
  `latest` precedes the counter increment under the condition's lock — the
  §12.3 normative order — so the boundary ordinals a waiting consumer
  observes only ever advance, each snapshot indexes itself, and the stop wake
  hands the waiter the final world rather than nothing. While stopped the
  wait returns at once; only a running loop can park it.
- **Conditioning runs upstream of the face, and the face never knows.** A
  face carries post-conditioning semantics (§11.4's GUI-parity test):
  `TableBinding`'s deadzone/expo run in `map_input` on the device task, so
  the root input receives the conditioned level and the model output is
  bitwise the directly-staged one — while an entry declaring no parameter
  passes its value through untouched, which is what carries a throttle's
  `[0, 1]` level or a press counter without ever meeting the axis convention.
  The claim is the table: what the binding may write is exactly what its
  entries name.
- **A bad datum and a bug have two fates, and the bound is the rate limit.**
  The loop's tolerance idiom — catch its own parser error, stage nothing,
  `report!`, continue — keeps the link alive with the stream's good datums
  landing, while an unclassified throw is the wrapper's `DeviceCrash`; the
  classification is the author's, because only they know their parser. A
  twenty-report flood costs sixteen retained values — earliest-in-frame, the
  ones with diagnostic content — plus one integer, and nothing is lost by
  not looking: the status's totals carry the full account (since increment
  14; the per-run totals behind `diagnostics(sim)` before it), the tail
  sweeping the cells one last time at the run's end.
- **Binding drift fails at attach, never on the wire.** Every `reads`
  selector resolves against the build at the attach point — the unknown
  path, the unknown root input, the input face offered to `get_face` — so
  `map_output` receives exactly the compiled gather's labeled NamedTuple or
  the device never rosters, and a rejected attach consumes nothing. The two
  read registers agree by construction: an exported face aliases its
  producer's cell, so `get_face(:y)` and the deep `get_output` are bitwise
  equal in every observed snapshot. An output-only binding stakes no claim,
  and the harness register keeps every face.
- **The delta rides exactly one snapshot; the totals ride every one.** A
  drained occurrence appears in `recent` in precisely the first snapshot
  published after its frame-top fold — `[0, 1, 0, 0, 0, 0]` across a
  six-boundary log — while `totals` is monotone from that boundary on. That
  is §11.8's any-cadence legibility made a vector equality: a 60 Hz reader
  sees each occurrence once, an occasional sampler still reads the complete
  account, and decimation loses *which* boundary, never *how many*.
- **A diagnostic is accounted exactly once, wherever timing lands it.** A
  device-task report races the run's last frame top, so the tests assert the
  exclusive-or: in the terminal status's totals, or presented by the
  run's-end sweep — never both, never neither (`accounted` in `utils.jl`).
  The deterministic corners pin the two pure cases: a failed `init!` reports
  pre-spawn and always makes the first fold; a `should_abort` init failure
  runs zero frames and can only be swept.
- **Dead-from-boundary-zero needs no machinery.** The failed-`init!` device's
  record shows the never-stored heartbeat (`0.0`, stale against any clock)
  and `task_state === :none` — §12.4's rule that the cell's silence *is* the
  marking, asserted off the published status alone.
- **Staging diagnostics wait like staged entries.** A rejection at stopped-sim
  staging sits in the writer's cell — readable there, `(@atomic cell.batch)`
  in the tests — and surfaces in the next run's first status, the same
  lifecycle as the batch it was rejected from; the attach renormalization's
  `ClaimedFaceEntry` carries `site = :renormalization` to tell it from an
  ordinary staging rejection.
- **The drain is free, populated or empty, at any width.** The batch's
  values-plus-mask pair is one concrete isbits layout per writer (D-202), so
  the scatter is a single specialization compiled at the stopped-sim point:
  a never-before-drained sparsity pattern allocates exactly what the warmed
  one does — nothing — for the harness register and device writers alike,
  and a 34-face surface (past the 32-wide threshold where Base's tuple `map`
  leaves its inlined path, which the generated merge never touches) drains
  as free as a two-face one. Measured under `trace = false` since increment
  23: §11.5's sparse record is the drain's one admitted allocation, and what
  these assertions are about is the scatter.
- **Termination is a state with a typed record, never an exception (D-203).**
  Every ended run answers "why did it stop?" and "how did the stop go?"
  through `termination(sim)`: `EndTimeReached` with the final frame top,
  `ModelRequestedStop` carrying the first holding face in declaration order
  and the boundary time of the very snapshot that held it,
  `ControlRequestedStop` carrying its issuer — `:code` for calling code, the
  device's name when a handle or its `should_abort` spoke, first CAS wins —
  and `LoopError` with the cause retained. The record is `nothing` unless
  the lifecycle is terminal, `init!` clears it with the trajectory, and its
  residue holds what landed past the final account: the tests pin the
  `DeviceJoinTimeout` entry (who/timeout/t/boundary) on the loop's record
  for an abandoned join, the pre-spawn `DeviceCrash` on a `should_abort`
  init failure's zero-frame run, and the empty vector on a clean tail.
- **A stop face ends the run at its own boundary — `t*` included.** The
  boundary-detected face ends the run at the sweep that saw it (frame 4 for
  a ramp crossing 0.35 at h = 0.1, never t_end's frame); the localized one
  ends it at the crossing's `t*` within tol of the analytic instant, the
  clock left at `t*`, the frame's remainder never integrated, and the log's
  terminal endpoint *is* the `t*` snapshot; an authored condition already
  terminal ends the run at t₀ with boundary zero final and zero frames
  advanced.
- **`init!` is the one door, and it opens the trajectory wholesale.**
  `run!`/`step!` before it refuse naming it; `stopped → init! → run!` is the
  re-run cycle; and the §12.6 clearing is pinned beside the §11.4 wait in
  one testset — a batch staged *before* `init!` is discarded with the
  trajectory it predates, the same batch staged *after* waits for frame 1's
  drain and never reaches boundary zero. The freeze on the far side of that
  door — `init!` and `run!` both refusing while the lifecycle is `:running` —
  is pinned against a run the test holds open at *both* ends: it spins for
  `:running`, probes, and only then stages the root input that trips the stop
  face, so the run's end is that staged write's consequence rather than a frame
  count the probes have to outrace. The same testset is therefore the
  end-to-end witness for a staged root input causing a model-requested stop:
  `stage!` mid-run on a deviceless simulation reaches the whole root-input
  surface through the harness register (§11.3), the next frame's drain applies
  it, and the boundary that follows publishes the holding face.
- **A stepped frame is a run frame, bitwise.** The two advance entries share
  one frame loop, so the equality is by construction and the tests assert it
  with `===`; the count actually advanced is the return value, so t_end and
  stop-face truncation are detected without inspecting the clock.
- **§13.6 costs nothing because publication is a boundary's last act.** The
  failing frame published nothing, so the "promoted" final snapshot is
  simply the newest published one: the record and `latest` agree on it, the
  log ends at it, the device's bracket closed through the ordinary tail, the
  mid-boundary stores stay readable, and `errored` refuses `run!`, `step!`
  and `init!` alike, each by name.
- **Composition is inert, and that is testable.** A `combine`/`at` tree over
  a path that resolves against nothing *constructs*: the nodes are inspected
  for their stored prefixes, unconcatenated, and the fragments are `isbits`;
  only `resolve` throws. The same test pins the stack-only property the trim
  loop will need before trim exists.
- **`combine` collides, `override` layers, and both say who wrote what.** A
  duplicate leaf reports both provenance chains — the `at` prefixes and the
  payload position, verbatim — and names `override(base, patch)` as the
  remedy; `override` gives the shared leaf to the patch, passes untouched
  leaves through, composes variadically, and still refuses a collision
  *within* a layer. The dual provenance is asserted through a violation on
  the overridden leaf, which is where the chain surfaces.
- **Layering is keyed on the root input, not on the spelling.** A root-level
  baseline under a component-local patch on the same root input resolves to the
  patch's value, with the baseline's others untouched — §14.6's central
  use case, which a literal `(path, store, field)` key would reject with the
  very advice it was following. The same two spellings under `combine` still
  collide, so the directive that branch prints is advice that works.
- **Boundary zero publishes every output stage, due or not (D-205).** Two
  components at `Relative(2, 1)` — neither due at `t₀` — both publish there:
  the ZOH from the condition's root-input value, the integrator from its
  authored `s`, and the probe's synthesized `0.0` reaches no published cell,
  live table or `t₀` snapshot. Dueness still governs the updates: the authored
  `s` survives boundary zero untouched and the first sample the integrator
  *consumes* is its own `Φ·Δt_base` tick's, pinned analytically as one period
  times one sample. Cold and warm `init!` agree exactly, the authored
  condition determining the `t₀` table outright — which is what retired the
  virgin-table precondition rather than guarding it.
  `test_multirate.jl`'s offset testset carries the same rule at its own
  fixture: the assertions were already the evaluated values, so only the claim
  behind them was re-pointed.
- **The service entry point speaks the algebra's diagnostics.** A bare
  NamedTuple handed to `init!` where a condition belongs gets
  `ConditionNodeMisuse` and the wrap-it directive, never a `MethodError`.
- **The misuse kind is a composition-time fact.** Blending a node with a bare
  NamedTuple throws `ConditionNodeMisuse` in both argument orders, at every
  arity, in `at` and `override` too, and with no build anywhere in sight —
  which is exactly why it is its own kind rather than a `ConditionResolution`
  sub-kind.
- **Resolution collects.** Five different violations in one condition —
  unknown path, undeclared field, unconvertible value, an input face wired
  internally, one root input written twice — come back as one throw naming
  all
  five. The undeclared-field message discriminates outputs and workspace by
  name, because "conditions never specify outputs" is the rule the author is
  most likely to test.
- **An input face is resolved through the export chain, not guessed.** A face
  authored at the component that declares it lands on the root input its
  obligation chain ends at; an internally wired input is refused, because the
  first sweep would overwrite it and unexported stays unpokeable.
- **Totality is pre-write, and "pre-write" is asserted by inspection.** A
  condition short one root input is rejected with every uncovered face named in
  declaration order, and the simulation is then checked to be bit-for-bit what
  it was: same `x`, same stores, same root-input cells, same lifecycle, the
  same
  published snapshot *object*. `init!(sim)` with no condition stays legal
  exactly where the build has no root inputs.
- **The overlay base is the declared defaults, always.** A sparse condition
  leaves unnamed fields at their `init_*` values, and a second `init!` after a
  full run restores them bitwise — `SVector(0.0, 0.0)` and `(state = :armed,
  count = 0)` again, not the trajectory's endpoint. This is the D-063
  behaviour the previous `init!` silently lacked.
- **An authored state fires its guard at t₀.** Boundary zero establishes every
  prior as not-holding, so a condition landing a predicate in holding
  territory fires visibly at `t₀` — authored, not staged, and with zero frames
  advanced.
- **The fragment-function idiom composes by pull across two levels.** The
  vehicle scopes the loop's fragment under `at("loop", …)`, the loop scopes
  the plant's under `at("plant", …)`, and nothing anywhere writes
  `"loop/plant"`: the deep path exists only in the flattened entry list.
- **One-level routing is class-blind and holder-blind.** A route through the
  sub-assembly's own face builds identically whether the field is declared
  concretely or generically, and both holders are rejected identically one
  segment further in — the endpoint stops before any field the old rule could
  have policed. The message names the child it reaches past, so the repair
  (declare the face on that child's boundary) reads off the error.
- **The cross-level one-producer rule survives the reach rule that used to
  demonstrate it.** An ancestor can no longer route deep onto an input a
  sub-assembly already wires; it feeds that input *through the face*, and the
  two claims still meet with both entries named — `child_connections` at the
  sub-assembly and at the root component.
- **A primitive root is the whole model.** `build(Plant())` flattens to one
  leaf at the root path, its `input_types` keys the root inputs, and the
  deployed bare leaf integrates `ẋ = A x + B u` against the matrix-exponential
  reference under a root-input-held `u` — no wrapper assembly, no vocabulary
  the assembly root does not already use. Totality reaches it identically, and
  the leaf's own `condition` fragment composes at the root with no `at` prefix.
- **An `at` prefix stopping at an assembly resolves to the same plan the root
  spelling produces.** `at("loop", fragment(inputs = (ref = …)))`
  and `fragment(inputs = (in = …))` compile entry for entry, because the face
  graph the `Build` retains has a name to follow at every level. The two
  refusals that flank it are unchanged in kind: a component-fed face reaches
  no root input, and a state payload at an assembly prefix has nothing to
  write.
- **Face uniqueness reads the root's class, not its family (D-210).** A
  primitive root declaring one key in both contracts is rejected as the same
  build error a duplicate assembly face name is — the shape that used to build
  and place two cells at one address, the root input's over the port's. The
  identical leaf one level down still builds, which is the rule's other half:
  below the root an input face places nothing, so there is nothing to forbid.
- **A root input's concrete declaration is unique across its fan-out (§8.2,
  D-168).** Two consumers of one root input face, one declaring `T` and one
  `Bool`, are refused at the layout barrier as `RootInputTypeConflict` naming
  the face, both consuming paths and both declarations — not, as before, as the
  second consumer's `WireTypeMismatch` against the cell the first one typed. The
  test asserts that kind's absence too. Its companion is the negative: `T`
  beside a pinned `Float64` builds, because the two agree at nominal and differ
  only about partials, which is the fan-out meet rather than a mistake.
- **A face feeding nothing declares nothing (D-210).** An `input_connections`
  entry routing to the empty tuple is refused at the level that declares it,
  root or not, with the offending entry named. The condition misdiagnosis it
  used to produce is *unreachable* rather than reworded: the test authors the
  dead face, addresses it with a condition, and gets the build's refusal — the
  resolver never sees it.
- **Transparency is a naming change and nothing else (D-211).** The same two
  children, in the same declaration order, wired and read through bare keys on
  a transparent container and through `"units/1"` on an undeclared one — the
  flat list, the wiring endpoints, the read path and the exported face all land
  identically. The default is `nothing`, and `TupleRoster` sitting beside
  `TransparentRoster` in the same file is the control.
- **The collision family has three arms, and each names both parties.** The
  duplicate-*name* check is the general one, written over the collected list
  rather than over the transparent case: a bare key against a sibling component
  field, and a bare key against another container's composite name, are one
  error there. The other two arms exist because no child name collides at all,
  so that check can see neither — an element keyed with its own field's name,
  which `sample_times`' field-name sugar already spells, and one keyed with a
  sibling *container* field's name **where that field contributes children**,
  which shadows the `"field/key"` grammar reaching them. Both are refused where
  the bare key is formed, in the same naming-both-parties form the general arm
  uses. The qualifier is pinned by the same parametric type one instantiation
  apart: populated, the bare key is refused; empty, it stands and both the
  wiring register and the reads resolve it to the bare child — an empty
  container reaches nothing, so nothing is shadowed, and the value cannot tell
  it from empty inert data anyway. The declaration itself is checked too: a
  component field and an absent name are refused alike.
- **Bare rate keys drive the grid the composite ones did.** The same two
  children under the same two `sample_times` entries compile to the same
  `(D, Φ)` pairs whether the container is transparent (`a`, `b`) or not
  (`kids/a`, `kids/b`), and the field-name sugar keys on the *field*, so
  `(children = Relative(2, 1),)` still applies one declaration to every element
  of a `Group`.
- **A computed boundary is the authored one.** The assembly whose two boundary
  declarations are `input_passthrough`/`output_passthrough` calls and the twin
  that writes both out by hand produce equal declaration tuples, equal root
  inputs, equal exported faces, equal flat lists, and equal port values at the
  exported face after `init!`. The helper is sugar, and the test is what says
  so: nothing downstream can tell which of the two it was handed. The twin is
  stateless and never runs — a trajectory would pin nothing the boundary-zero
  read does not.
- **The helpers own two refusals and no more.** `except` and `only` together,
  and a filter naming a face the child does not have (with the child's face
  list in hand), are the helper's errors, because nothing downstream could name
  the offender. Everything else is left where the rule already lives:
  `prefix = ""` colliding with a hand-written face is §8.6's face-name
  uniqueness, and a face both wired and passed through is §6.1's one-producer
  rule naming `child_connections` and `input_connections` as the two claimants.
- **`child_path` is a child path, one level, whatever names the child.** A
  deeper `child_path` meets the same rejection a wiring endpoint does, and a
  child living in a name-transparent container is addressed by its bare key —
  the helper never learns which kind of field held it.

- **A simulation owns one executor, and it is the one the loop runs.**
  `phase_bodies(sim) === sim.exec.bodies`, and `sim.exec.act` is
  `activation(sim.build, Float64)` itself: the bodies §7.5's measurements time
  are the executor's own rather than a re-derivation, and the executor carries
  the activation it was materialized from. `evaluate!(sim)` and
  `evaluate!(sim.exec)` leave the same derivative buffer, and the executor form
  allocates nothing — the `Simulation` method is a spelling, not a layer.

- **Five selectors, one address space, both activations.** Each member reads
  exactly what it names off an executor — the whole `x` leaf out of `xbuf`, the
  discrete `s` out of the component's own store, `f`'s output out of `ẋbuf`, a
  port's cell, a root input's cell, and an exported face's producer cell, the
  face reading identically to the port it aliases — and `i` indexes the read
  value. At `D8` the leaf types are the activation's throughout, while the
  frozen discrete store stays pinned `Float64` (§9.4, D-166): the same read set
  compiles at both scalars and the test runs it at both.
- **The gather twin costs nothing.** `gather(reader, executor)` allocates zero
  and infers a concrete NamedTuple, which is what makes a per-iteration read
  free against the sweep it follows. The empty read set gathers `(;)` — a
  service with nothing to read pays a no-op, not a special case.
- **One call, every violation.** A misspelled path, an undeclared port, a
  `get_deriv` on a discrete `s` and an unknown root face come back as one
  refusal naming all four, each by its own label and its selector as authored;
  a second call collects the assembly path, a root input read as a face, an
  index on a scalar leaf and an undeclared state field. §13.1's register, one
  register over from the condition algebra's.
- **A read set is a type, not a NamedTuple.** The bare spelling is refused with
  the directive `combine` gives for its own misuse, and a non-selector value in
  a `reads(…)` call is refused where it is written.
- **The source rule is enforced where the source is known.** A store selector
  in a binding's `reads` is `ReadBindingUnresolved` at attach, naming the
  remedy (declare the field public, read the published port); so is an indexed
  selector, the binding register reading whole cells. Both rejections leave the
  roster untouched, like every other attach refusal.
- **`capture` is the door back out, and it is total.** The captured pair
  re-establishes the world it was read from — `xbuf`, every `s` and `m` store,
  every root input cell and the clock — through an ordinary `init!` on a twin,
  at boundary zero and again after a trajectory; its coverage is the build's
  root inputs exactly, so nothing lies under it and §14.6's check passes by
  construction. The condition is time-free and `t` rides beside it, which is
  what `t0 = t` spends. Legality is the §14 table's: `initialized` and
  `stopped`, with `built` refused for want of committed stores and `running`
  refused by the §11.3 freeze, all as one `ServiceLifecycle`.

- **One plan, one shape, many trees.** A plan compiled from a condition tree
  lands, from a *second* tree of that shape with other values everywhere, the
  same four homes the dynamic walk lands from that second tree — flat buffer,
  discrete store, mode store and both root-input cells compared whole. The plan
  holds lenses, not the values it was shown, and its type carries the tree type
  it was compiled from.
- **The specialized write is free.** `apply!(ex, plan, tree)` allocates zero
  over the four-home fixture — the prefix sweep, the flat-buffer write, both
  stores as whole values and both root-input scatters — with the tree handed in
  already built. Building it is the caller's cost, and it is *not* free here: an
  `at` node holds a `String`, so any tree carrying one is not isbits, and this
  fixture's construction measures 912 bytes — §14.2's "rebuilding the tree per
  trim iteration is stack-only construction" does not hold for a tree with `at`
  prefixes as things stand, which is recorded here rather than papered over.
  The register is measured where its own work is.
- **The store merge is the composite's.** A baseline authoring one field of a
  store and a patch authoring the other both survive the write, because the
  plan is compiled from the composite tree and the merge base is the declared
  defaults. A plan over the patch alone would reset the baseline's field to its
  default, which is the trap the composite exists to avoid.
- **Shape drift is structured, and nothing is written.** A tree of another type
  reaches the fallback and names both types; a tree of the right type with a
  different `at` prefix at the same position reaches the `===` sweep and names
  the position and both strings. Either way the executor is bit-for-bit what it
  was before the call.
- **The prefix sweep compares content, not pointers.** A prefix built afresh
  per call — a `String` at a different address, asserted to be one — passes the
  sweep of a plan compiled from the literal, because `===` on `String` is
  content equality. That is what a service rebuilding its tree per evaluation
  needs, and it is a stronger claim than "equal literals are one object".
- **The converter is the destination leaf type, and it is baked.** A plain
  `Float64` leaf into a seeded activation's `x` reads back with zero partials —
  the embedding that is exact for a value held at the operating point — and a
  leaf already at the activation's scalar reads back with its partials intact.
  A decision variable authored into a discrete `s`, frozen `Float64` at every
  activation, is refused at resolution with the clause that says why, and the
  nominal activation's own refusals are unchanged.
- **A compiled product belongs to one activation, by dispatch.** A `Float64`
  `Reader`, `ConditionPlan` and `SpecializedPlan` each refuse a `Dual` executor
  naming both scalars, and the executor is untouched. The refusal is an
  `InternalInvariant` and no diagnostic kind: §14.4 makes the pairing a
  framework invariant the services uphold, so reaching it is an internal
  assertion firing, outside the kind set on purpose (D-215).
  The scalar rides in the product's own type, so the pairing costs a method
  signature rather than a runtime test — the §7.5 gates measure zero unchanged.

- **A trim problem solves, commits, and the commit is an `init!`.** The
  one-step linear problem lands `u = (g/l)·sin θ` to its tolerance in four
  evaluations, and afterwards the simulation is `initialized` at the `t₀` it
  was given, with the authored attitude in its state and the solved torque in
  the root-input cell. A twin `init!`ed by hand with `override(baseline,
  condition(report.solution))` at the same anchor has identical buffers,
  stores, root inputs and clock — the commit is not *like* an init, it is one.
- **The nonlinear problem converges, and the box picks the branch.**
  `−(g/l)·sin θ + u = 0` has two roots in `[0, π]`; the declared box admits
  one, and the solve lands on it in four iterations, with the `Dual` decision
  leaf and the held `Float64` leaf meeting inside one fragment payload —
  §14.3's two converter arms in a single write.
- **Names pair, order never does.** The same two-decision problem with both
  bound spellings permuted *and* the tolerances permuted with them returns the
  same solution bit for bit; only the residual NamedTuple's key order follows
  the tolerances it was canonicalized to.
- **No convergence, no commit, and nothing moves.** An infeasible balance
  reports `converged == false` with the backend's status recorded and
  `committed_residuals === nothing` — the absence of a commit, not a flag. On a
  never-initialized simulation the lifecycle stays `built` and `run!` still
  refuses; on an initialized one every buffer equals its pre-call copy.
- **A saturated decision is named at the solution.** An actuator bound below
  the equilibrium torque, under a force balance declared to a tolerance the
  bound still meets, converges with `saturated == [(:u, :upper)]` and the
  bound's own value committed. The same problem unbounded names nothing.
- **The box is honored at every point the backend returns.** A guess of `100.0`
  under `[-1, 1]` comes back as `1.0`, saturated at `:upper`, with `1.0`
  committed: the guess is projected at the pack site, so the returns that never
  step — the already-within-tolerance one, a stall at iteration one — cannot
  hand back an out-of-box point as converged with `saturated` empty. A
  degenerate box (`lower == upper`) pins the decision to that one value, named
  `:lower` because the saturation check tests `lower` first.
- **The empty problem is the equilibrium probe.** `guess = (;)` bypasses the
  solver outright — `status == :bypassed`, one evaluation, no iterations, no
  seeded activation — and the nominal half's establishment round *is* the
  evaluation. On an equilibrium baseline it converges and commits; on one that
  is not, it answers no by the ordinary box test and leaves the sim `built`.
- **The setup diagnostic collects, in three observable stages.** A bounds
  key-set mismatch, an `Int` guess field and an unresolvable selector come back
  as one throw of three diagnostics — two `TrimProblemInvalid`s and the read
  set's own `TapResolution`, spliced in as the value it is; an inverted box (`lower` above
  `upper` on one decision) is collected there too, with both values named,
  because no projection can honor it, and so is a non-positive tolerance —
  zero and negative in one problem come back as one throw naming both, the
  acceptance test's divisor being the reason. The residual/tolerances key-set
  disagreement is the check only an evaluation can make (§14.7 says so), so it
  is reported from there, in its own collected throw of the same kind — and
  from *both* evaluations that can observe it: a lambda branching on the scalar
  it is handed answers one key set at the nominal guess and another at the
  first seeded point, and the seeded re-check turns what would be a bare
  `ErrorException` from the reorder into the same named refusal. Every refusal
  leaves the simulation untouched.
- **An incomplete baseline is `UninitializedInputs` at setup.** Trim's
  application to its own scratch stores is one of §14.6's three sites, and
  coverage is a plan-level fact: the check runs before any evaluation, names
  the uncovered face, and names `trim!` as the operation.
- **The scratch world's frozen cells are the authored world's (D-213).** With
  the pendulum's torque arriving from a discrete producer whose `s` the
  baseline authors, the solution is `asin(acc/(g/l))` — reachable only if the
  seeded world's frozen cell holds what that `s` publishes; the probe's
  synthesized zero would put it at `0`. Changing the authored `acc` moves the
  solution with it, which is what makes the copy load-bearing rather than
  incidental. And a decision variable authored *into* that frozen `s` is
  refused by the seeded compile's own `ConditionResolution`, with the
  frozen/pinned clause, before anything is written.
- **The commit is an ordinary boundary zero, and its movers are reported.** A
  guard the solved attitude already holds fires at `t₀` — derived, not asserted
  — and the report carries `[("trig", :fire)]` beside a `TrimCommitEvents`
  warning. A handler that only writes modes moves no residual, so the
  committed-state numbers are still the solved ones.
- **A residual mover shows in the committed-state residuals.** A handler that
  resets the solved attitude raises both warnings, in order, and
  `committed_residuals.torque` is the residual at the *reset* point, not the
  solved one. The verdict is not re-litigated: it gated the commit at the
  solved point, and both sets of numbers stand as reported.
- **A warm restart is `capture` handed back.** `run!`, then `(c, t) =
  capture(sim)`, then `trim!(sim, problem; baseline = c, t0 = t)` commits with
  the clock at `t` — the resumed spelling §14.8 names, with continuity explicit
  rather than implied.
- **The per-iteration write and read are free.** At the service's own seeded
  scalar, `apply!(ex, plan, tree)` and `gather(reader, ex)` both measure zero
  allocations, and one seeded pass yields the residual value and its Jacobian
  column together (`value` and `partials` of the same gathered leaf). The
  residual lambda is the user's and is not gated; building the tree is not
  free either, for the `at`-prefix reason increment 21's part 3 records.
- **`trim!` is a stopped-sim service on a nominal deployment.** A
  `Simulation{D8}` is refused outright — the commit runs through boundary zero
  on the simulation's own stores, and those are the nominal world's — a
  non-problem value gets a directive rather than a `MethodError`, and `running`
  is the §11.3 freeze, refused as `ServiceLifecycle` exactly as `init!` and
  `capture` are.

- **A collecting register returns kind values, and the barrier throws once.**
  The condition resolver's five violations over one tree come back as five
  diagnostics in one `BuildError` — four `ConditionResolution`s discriminated
  by `reason` and one `DuplicateConditionLeaf` — and the count is read off
  `length(e.diagnostics)` rather than out of a rendered sentence. The read
  register's four come back as four `TapResolution`s in the read set's own
  declaration order, each carrying its label and the selector as authored.
  Every payload the old message text carried is now a field: the candidate
  list in hand, the tier that has no such store, the role that made a field
  ineligible, the seeded activation on the frozen-leaf refusal.
- **Provenance is payload, not prose.** A `combine` collision names both chains
  as the two entries of `d.provenance`, and an `override` patch's chain records
  the layer it overrode inside the one string the flattening built — asserted
  as values, which is what makes them a property rather than a wording.
- **Rendering is pinned in exactly one testset.** The carrier over two kinds ×
  two paths renders the kind names leading, the groups in first-appearance
  order, the paths sorted within a group and the count line above; a lone
  diagnostic renders on one line with no count. Beside it, one did-you-mean
  render showing the candidates the site held (carried, never ranked) and one
  remedy render showing the list in hand, and `logline(d)` for a warning kind.
  Nothing else in the suite may match rendered diagnostic text (§13.2).
- **The device contract's refusal reaches its kind wherever it surfaces.** A
  device with no `loop` method crashes on its own task the instant the wrapper
  calls it, so `DeviceContractMismatch(reason = :no_loop)` rides as a
  `DeviceCrash`'s `cause` — reachable only at `run!`, never at `attach!` or
  `init!`, neither of which ever calls `loop`. `gather` against a handle whose
  binding declares no output side throws the same kind directly, `reason =
  :no_output_side`, on whichever task calls it.

- **One sparse record per drained batch, against the writer's schema.** A
  single staged face on a three-face surface records one `TraceBatch` with one
  `position ⇒ value` entry, `frame == 1` — the drain runs before the clock's
  step increments — and the harness register's schema index; the position
  resolves to the face through `header.schemas[batch.writer]`, which is the
  only way a consumer may resolve it. A merged batch is recorded once,
  coalesced, because the drain is where the conversion happens. A frame nobody
  staged into records nothing and still advances `frames`, and its drain
  allocates nothing.
- **The header is the pre-sequence state, resolved.** On a model whose
  boundary zero fires a trigger and runs a due `g`, the header's `m` and `s`
  hold the *authored* values while `modes`/`state` hold the post-sequence ones
  — §14.5's placement, load-bearing because replay re-executes boundary zero
  and a post-sequence capture would re-fire authored-condition events on top of
  already-latched state. The root inputs ride along as resolved values, which
  is the half no batch could supply: neither face in the fixture is ever
  staged. The deployment block is captured at the same instant, with the
  effective termination pair `init!` knows — the constructor's, `run!`'s
  override post-dating the capture.
- **The kill switch is a construction-time fact, and `init!` clears.** Under
  `trace = false` the drain records nothing and `trace(sim)` is refused
  (`ArgumentInvalid`, `reason = :disabled`); before the first `init!` there is
  no header and the refusal is `MissingInit`, the same way out an advance entry
  names. A warm restart empties the batches and re-captures the header against
  the new condition — a new trajectory, D-029's "cleared at `init!`".
- **A roster change appends the writer set, and earlier records still
  resolve.** A face at position 2 of the whole-surface harness schema sits at
  position 1 of the narrowed one an `attach!` leaves behind; both records
  resolve to the same face because the appended set is a new entry rather than
  a rewrite, and `live_writers` names the current one. A `detach!` appends
  again and the batches recorded under the wider set stand unchanged.
- **The scalar is dispatch, not a comparison.** A `Trace{Float64}` offered to
  a `Simulation{Dual}` reaches `_compile_feed`'s fallback and reports
  `what = :scalar`; the matching pair compiles. The refusal is therefore one
  nobody can forget to write, and `replay!` carries the same pair.
- **The header is compared against the build and the deployment binding, and
  nothing else.** An extra component moves both the path list and the cell-size
  list, and both report `:store`; a changed `h` reports `:deployment` with
  `name === :h` and drags `Δt_base` into the same collection, because the two
  are one grid; `localization_budget` and `firing_budget` each report alone.
  A target differing only in `t_end`/`stop_on` compiles: the recorded pair is a
  fact of the recorded session, never a constraint on this one, and `t₀` is
  applied rather than compared (§12.7's disposition table).
- **A recorded schema is validated, and the header goes first.** A schema
  naming a face this model does not export is one `ReplaySchemaMismatch` per
  writer, carrying the whole recorded schema and the target's face list beside
  the disagreeing names. A trace that is both schema-bent *and* entry-bent
  reports only the schema — the two-stage order, which is what keeps the
  entry-side report from being noise.
- **Every position resolves through its schema, and the misses collect.** A
  position past the schema's end, one below its start, and a batch naming a
  writer index the schema list does not have are three `ReplayUnknownFace`es in
  one carrier, each with its frame ordinal and its writer tag — the third
  spelled `"writer #9"`, the tag §11.8 cannot supply. An unconvertible recorded
  value is not among them: the face is known, so it is a
  `ReplayHeaderMismatch(what = :root_input)`.
- **A frame ordinal outside the recording's own length is refused.** Frames `0`
  and `99` against a two-frame trace are two `ReplayHeaderMismatch(what =
  :frame)`es in one carrier, each naming the writer whose schema the record was
  written under — positionally where the schema list does not reach that far,
  and then the frame is the one fault reported, the record being unreachable
  anyway. It is what lets the replay drain key its cursor on `==`.
- **A valid trace becomes compiled scatters, in the drain's own order.** The
  feed's thunks applied in order reproduce the recording's writes into the
  target's cells — sparse, so an untouched face keeps what the target's own
  header left there — and each carries its original `TraceBatch`, which is what
  lets a replay re-record the recording's own values. A recording that outlived
  a roster change replays whole: the superseded schema entry is compiled
  against the target's layout like any other.
- **A replay reproduces the recorded trajectory bitwise.** On a model reaching
  all three state homes with a bouncer resetting *between* frame tops, a fresh
  simulation initialized from a different condition replays to the same log
  boundary for boundary: the same `t` stamps, the same cells (`==`, which is
  the claim — D-163's tolerance rule is about numerical agreement, not about
  reproduction), the same live stores, and the same two localized boundaries
  the recording never stored — `t*` derives from state, so reproducing the
  state reproduces the timing. It ends `initialized`, with no termination
  record, and it re-records: the header inherited and the batches equal — equal
  *values*, never the recording's own objects, so the two traces are two values
  and a continuation's growth cannot reach the `Trace` the caller still holds.
  §12.7's own register runs too — `Simulation(world)` then `replay!`, no
  `init!` anywhere: `replay!` *is* a door into `initialized`, so it owes one to
  nothing, and a `built` target replays to the same trajectory.
- **A device's recorded batches replay on a deviceless twin.** A rostered
  device staging into a `run!` leaves its writes in the trace under its own
  schema entry, and the replay target needs no roster to apply them — "no
  devices or mappings present" (§12.7). Claims are a live-roster fact of the
  recorded session, and the replay drain re-derives none of it.
- **Partial replay halts at a frame top, and the next frame reproduces.**
  `to_boundary = k` leaves the clock at `k` and the lifecycle `initialized`,
  with the log a prefix of the recording's; `step!` then advances the frame the
  recording's own frame `k + 1` advanced, bitwise — §13.4's error-reproduction
  workflow minus the error. Increment 23 spelled the pointer in base ticks
  (`k · n`, the clock left at `k · n`), which coincides with the boundary count
  only at `n = 1`; increment 24 re-expressed it in grid boundaries, since every
  frame top is one (§10.4) and the boundary is the reporting index §13.4's
  pointer names.
- **A continuation is a live session from the replayed boundary.** `run!`
  after a full `replay!` proceeds from frame 8 rather than from zero, and the
  session leaves behind a complete, valid trace of *itself*: the recording's
  batches as a bit-identical prefix (`==` on `TraceBatch`es, across two
  registers), its own behind them, the header inherited and this session's
  writer set appended under the growth rule.
- **Live staging met by a replay is discarded, and reported.** A device
  staging a value that would move the trajectory changes nothing: the replayed
  log is still the recording's, bit for bit, and nothing of the device's is
  recorded. The drop is loud — one `ReplayDiscardedStaging` on the device's own
  cell, naming the faces it cost, accounted in the run's totals or presented by
  the run's-end sweep, exactly one of the two.
- **Live staging into the harness is discarded on its own cell.** The same
  property through the other writer, reached synchronously: a
  `needs_calling_task` device runs its loop body inline on the calling task
  while the run body is spawned (§11.1), so its `stage!(sim, …)` — the harness
  register's surface, not the device's claim — lands mid-replay, frame after
  frame. The trajectory is still the recording's bit for bit, nothing of it is
  recorded, and every drop is reported on the *harness* cell with the faces it
  cost, the device's own account untouched.
- **A changed parameter replays deterministically, and only that.** Same
  structure, a different gain: the entry pass admits it (parametric difference
  is the what-if register, not a structural mismatch), the replay ends
  `initialized`, and the trajectory differs from the recording's — while two
  what-ifs of the same modified model agree with each other boundary for
  boundary. Determinism is promised; reproduction is not.
- **`replay!`'s refusals precede its first write.** `to_boundary` past the
  recording, negative, or non-integral is `ArgumentInvalid` naming the argument
  and the value, and the target is still `initialized` afterwards; an `errored`
  simulation refuses `replay!` exactly as it refuses `init!`, terminal meaning
  terminal — reproduction is replaying the trace on a *fresh* simulation, which
  is what the bit-identity tests do. Under `trace = false` a replay still runs
  — the feed is compiled from the `Trace` in hand, never from the target's own
  register — and records nothing.
- **The cursor names where execution was, on a quiet frame as on a failing
  one.** After an ordinary `step!` the cursor reads the sequence's last block —
  `:ticks`, empty on a continuous model — with the component and function of
  the last dispatch the sweep walked. Maintaining it costs nothing measurable:
  the suite's forty `@ballocated` assertions are unmoved, a store of an `Int`
  or a `Symbol` into a mutable struct allocating nothing.
- **One catch site frames every user-code surface uniformly.** A throw from
  `f` at RK4's half step is `StepError` with the frame `("c", :f, :integrate,
  2)`; from a handler, `(:handler, :round, 1)`; from a sign-form guard, `(:guard,
  :trial, j ≥ 1)` at a time strictly inside the frame, reachable by a
  localization trial alone; from `g`, `(:g, :ticks)`; from `project`,
  `(:project, :project)`. The catch is per `_advance!` call, not per stage and
  not per component, and it names each of those without a `try` anywhere near
  the dispatch.
- **The pointer is the frame-entry boundary the failing frame began at.** Not a
  constant and not the clock's own step: a failure in frame 1 reports `0`, one
  in frame 4 reports `3`, and the record's `t` is the last *published*
  boundary's — the failed frame published nothing, so §13.6's discard-and-
  promote and §13.4's pointer agree by construction.
- **The cause is retained, and the record wraps the wrap.** `termination(sim)`
  holds `LoopError` whose `exception` is the very `StepError` the entry
  rethrew, whose `cause` is the model's own exception one level down. The
  rendering states the frame and then the reproduction — the path, the
  function, the phase spelled per case, `to_boundary = k` and `step!` — which
  is the one property asserted on message text (§13.2 otherwise forbids it).
  A `Diagnostic` cause renders as its `logline`, so the nonfinite species' line
  carries the kind name and the leaf the sweep named.
- **An `InterruptException` is a stop, never a failure.** Model code raising
  one inside the guarded sequence ends the run `stopped` with
  `ControlRequestedStop(:interrupt)`, the graceful tail run in full (a probe
  device sees `[:init, :shutdown]`) and the last published boundary final. The
  frame it interrupted is not counted: the deviceless `step!(sim; frames = 5)`
  returns the completed frames alone, which is what pins the `adv` increment's
  placement past the publication. The stores may be mid-boundary — with §12.4's
  masking absent, a `stopped` simulation here is still inspectable by every
  stopped-sim service, and the masking is what would close that gap.

- **The sweep names the block that diverged, not the one it reached next.**
  `Diverger → Consumer` under a group, armed by a stage: the `StepError`'s
  cause is a `NonfiniteState` naming `div`, leaf `q`, a NaN value, the
  frame-entry boundary and the frame top's `t` — never a `DomainError` from
  `con`'s lookup, and never `div`'s own `project`, which refuses a nonfinite
  `q` and is placed one step later in the sequence. The frame reads
  `fn === :none`, `phase === :integrate`: the sweep is the framework's own act
  inside the integrate, not a user-code dispatch.
- **The sweep is the seam's act, so remainder segments are covered.** A
  localized `LateDiverger` whose handler latches at `t*` and whose remainder
  segment integrates a NaN derivative still fails as `NonfiniteState`, with `t`
  the frame top rather than `t*`. Placing the check in `step!(sim, h)` rather
  than in the frame loop is what buys this, and the property is what would
  break if it moved.
- **The pointer the error names reproduces the failure.** A staged session that
  fails in frame `k + 1`, its `StepError` read off `termination(sim).source`;
  a fresh twin replayed with `to_boundary = e.boundary` halts `initialized` at
  `clock.step == e.boundary`, and one `step!` throws a `StepError` with the
  same frame, `t`, `boundary` and cause type, ending `errored` at the same
  published `t`. Run for an ordinary cause (`Tripwire`) and for the nonfinite
  species. **The failing frame's own drain must be empty** for this to hold:
  the replay applies records 1…`k` and `_run_body!` clears the feed on exit, so
  a batch staged *into* the failing frame is recorded at ordinal `k + 1` and
  the live `step!` after the replay never sees it. Both fixtures arm at an
  earlier frame — the diverging one through a `Follower` latch — which is why
  the reproduction is exact.
- **`to_boundary` counts grid boundaries.** At `n = 2`, `to_boundary = 3` halts
  at `clock.step == 3`, an off-tick frame top, with the log a prefix of the
  recording's, and `trc.frames + 1` refuses as `ArgumentInvalid`. The base-tick
  spelling would have refused `3` here and halted at `6` where it did not.

Three places this increment runs ahead of or beside the spec's letter, flagged
for the spec pass:

- **The species rule** is the prototype's spelling, not the spec's. §13.4 says
  a conformance failure "is thrown as its typed diagnostic at the table-write
  point, and it arrives at the same catch site. There it is a species of
  `StepError`", without saying how the catch site recognizes one. Here a
  `BuildError` carrying **exactly one** diagnostic, thrown inside the sequence,
  arrives unwrapped as that diagnostic — which keeps the catch site the only
  `StepError` constructor while letting a runtime check be a plain thrower of
  its kind. A multi-diagnostic carrier stays raw, having no single species.
- **Boundary zero is outside the catch.** `init!` and `replay!` run it as
  stopped-sim services and propagate raw. The spec calls boundary zero "the
  ordinary macro-sequence with an empty integrate" and a legal replay halt, so
  a reading that wraps it too is available; the conservative choice here is
  that a service's own refusal path is not a frame, and there is no
  frame-entry pointer for the frame that has not begun.
- **The reproduction is exact only where the failing frame stages nothing.**
  §13.4 argues reproducibility from the drain's placement: the failing frame's
  inputs "are already in the trace when it fails", so replaying to `k` and
  stepping re-executes it. The batch is indeed recorded — at frame ordinal
  `k + 1` — but the replay's budget stops at `k`, and `_run_body!` clears the
  feed on every exit, so the `step!` after the replay is a live frame whose
  drain finds nothing. A failure caused by the failing frame's *own* drained
  input therefore does not reproduce here. Closing it means letting the feed
  outlive the replay by one frame (a `step!`-after-`replay!` that keeps
  reading the trace), which is a §12.7 decision, not a §13.4 one.
