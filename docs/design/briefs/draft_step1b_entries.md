# Draft: step 1b's decision entries

The nine entries the pipeline redesign adds to `decisions.md`, drafted for
review before the spec is touched (`roadmap_pipeline_redesign.md`, step 1b).
Written to `tools/decisions_style.md`'s template; citations bare, linkified
on landing. Each entry's rationale is the 2026-09-18 session's, as
`notes_pipeline_redesign.md` settled it and as the 2026-09-18 probe and
sweeps refined it. Status changes to older entries, and the spec edits the
commit makes beyond the entries, are listed at the end.

---

### D-250 — Warnings live where the artifact criterion puts them

**Status.** ratified

**Position.** One warning policy replaces the two streams of §13.2. An
artifact is an immutable pure function of its inputs; state is single-owner
and mutated in place. A warning raised while producing an artifact lives on
that artifact. A warning raised while mutating state lives in that state's
status. Logging is presentation, never a home.

- `Build` and `Deployment` carry `warnings`. A stratum that throws renders
  its warnings with the collection. One that completes carries them on the
  artifact, and the entry point logs each once at return.
- A scoped channel bound by the walk lets a helper running inside a
  declaration body append to the build's warnings. The same helper called
  standalone, outside any build, logs directly.
- Appendix C's `logged` policy widens from stopped-sim service calls to any
  artifact-producing call, the build included. The collected-warning slot
  stays open and empty (D-084 stands).
- `warnings(x)` is defined on `Build` and `Deployment`, and on `Simulation`
  as the concatenation of its artifacts' lists. Status-side warnings stay in
  the status record.
- `EmptyGreedyClaim` moves from a log line to the roster entry's diagnostic
  cell, since `attach!` mutates the roster, and surfaces through the status
  record. The log line at return stays as presentation.

**Spec.** §9.1, §9.2, §11.3, §11.8, §13.2, Appendix C

**Rationale.** §13.2 placed warnings by where they were raised: the build's
collection, the runtime's per-writer cells, and a third home for service
warnings that "belong to neither stream" and are emitted once at return
beside the value. That third home was the tell. `trim!` returns a
`TrimReport` and duplicates its warnings into the report's fields because
the report is where a caller looks, which is the artifact criterion applied
once by hand. Stated generally, the criterion decides every case the
redesign meets. A build is an artifact, so an empty selection in a
passthrough helper (D-251) belongs on the `Build`, not on a logger the CI
run never reads. A deployment is an artifact, so `GridUtilization` belongs on
it (D-254). `attach!` mutates the roster, so `EmptyGreedyClaim` belongs in
the entry's cell beside the other writer diagnostics, and the status record
is where a reader finds it after the fact. The channel exists because a
helper inside `input_connections` has no artifact in hand; the walk that
owns the barrier binds one, and the helper appends without knowing the
build. Outside a build there is no artifact, and a log line is the honest
fallback. Logging each artifact warning once at return keeps the interactive
experience unchanged while the artifact keeps the record.

**Rejected.**
- *The logger as the home:* a CI run, a test and a second session read the
  artifact, never the log; a warning that lives only in a log line is lost
  to every reader but the one at the terminal.
- *A global warning collector:* two concurrent builds would interleave, and
  the collector would outlive the artifact it described.
- *Promoting build warnings to errors under a CI switch:* §13.2 already
  rejects it; an empty selection is a fact about the model worth knowing,
  not a defect.
- *Superseded position — service warnings as a third stream with no home:*
  the artifact criterion covers them; a `TrimReport` is an artifact, and its
  duplicated fields were the criterion applied ad hoc.

---

### D-251 — Make the passthrough selectors exclusive and warn on an empty selection

**Status.** ratified

**Position.** `input_passthrough` and `output_passthrough` take one selector
per call: `except`, `only`, or a new `select` predicate over face names.

- More than one selector given is `UnknownFaceSelection` with reason
  `:multiple_selectors`, generalizing `:both_given`; the payload names the
  selectors given.
- A selection that names a selector and keeps nothing is the warning
  `EmptyFaceSelection`, a build-stage warning through D-250's channel. A
  bare call over a faceless child is silent.
- Required-faces declarations are not owed. Recorded as possible sugar.
- The feed-list idiom of §8.8 gets a test transcribing the spec's sketch
  against the real helpers, and no code.

**Spec.** §8.8, Appendix C

**Rationale.** §8.8's `except` and `only` were mutually exclusive by rule;
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

---

### D-252 — Remove auto-publishing: two port classes, exposed state returned by stage 1

**Status.** ratified

**Position.** A declared output is produced by stage 1 or by stage 2, and by
nothing else. A component exposes a state or mode field by returning it from
`output_state`. A declared output that no stage produces is
`DeclaredNotProduced`, everywhere and at every tier. Supersedes D-016's
publication rule, D-152's successor in D-154's sequence, and D-169.

**Spec.** §5.2, §5.3, §8.3, §9.1, §9.3, §10.6, §13.2, Appendix B, Appendix
C, Appendix D

**Rationale.** Auto-publishing was a third port class the framework wrote.
It cost more than the line it saved. Stage 1's hand-down had to exclude the
published names (D-169), the classifier probed by name and type and silently
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
homogeneous, the `Dataflow` artifact (D-253) classifies by return alone, and
the trace and status surfaces stop distinguishing a framework write from a
stage write.

**Rejected.**
- *Keeping publication as it stood:* the machinery above, for one line per
  exposed field.
- *Opt-in publication sugar (a declaration listing fields to expose):* a
  second way to write `output_state`'s return, with the same classification
  seam.
- *A dev-mode flag publishing every state field (§11.7's note):* still
  possible as a debugging aid, but it would be a reader over the stores, not
  a port class; it is recorded, not built.
- *Refusing only at the root:* an unproduced port inside an assembly is the
  same silent zero, one level down.

---

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
  dataflow and the events with the `Float64` stage-1 products. Stratum C
  takes those and completes an activation. No product changes across
  activations.
- `Build` is structure, dataflow, events and the activations, the nominal
  and the cache merged into one dictionary keyed by scalar type under the
  existing lock.
- Structural consumers read the products, not the `Activation`: readers,
  trim, the tracer, `compile`'s key slicing and the runtime field-error
  species take their name lists from `Structure` and `Dataflow`.
- §9.1 says Stratum B is the nominal evaluation's structural half, and the
  nominal activation is B's products plus C's typing.

**Spec.** §9.1, §9.2, §9.3, §9.4, §13.3, §13.4, §13.7, §14.1, §14.4

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
execution order should not need the event table. D-049's reasons for a
standalone `Build` hold unchanged: CI targets `build`, conditions resolve
against it, bindings validate against it, one build backs many
deployments. The `Dataflow` name stays although the prose calls the order
"execution order" (D-258): the artifact carries the edges and the name sets
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

---

### D-254 — `Deployment` and `Schedule` as artifacts between the build and the simulation

**Status.** ratified

**Position.** Deployment binding produces an artifact, and the `Simulation`
materializes it.

- `Deployment` is the build plus `h`, `N_base`, `Δt_base`, the algorithm
  and the three event parameters. It is scalar-free. It carries the
  `Schedule`, the grid diagnostics of D-187 and its warnings.
  `Simulation` materializes a deployment at `T`. Replay compares two
  deployments as values.
- `Schedule` is the typed schedule inside the deployment: per discrete
  component `(D, Φ, Δt)` with anchor and provenance columns, the rate-scope
  rows, and the `D`, `Φ`, `Δt` vectors.
- The grid diagnostics land on the deployment: leave-one-out factors, prime
  attribution, nearest non-refining offsets, the derivation line and
  `GridUtilization`, the last as a deployment warning under D-250.
- `Simulation(build; kw...)` and `Simulation(root; kw...)` stay as sugar
  composing the deployment constructor.

**Spec.** §9.1, §9.2, §10.5, §11.5, §12.7, Appendix C

**Rationale.** Deployment consumes the grid parameters and fixes everything
they determine, the bound schedule and the grid diagnostics among them, and
none of it depends on the scalar type. Today that step ran inside the
`Simulation` constructor and its products lived as `Simulation` fields:
`sched`, `D`, `Φ`, `Δt`, the grid parameters, the event parameters. The
bound schedule was "a named printable artifact on the `Simulation`"
(D-187) with no type of its own, and the grid diagnostics it was to
substrate were never built. A deployment that is an artifact can be
compared, which is what replay's header check does with the deployment
block today by hand, and it can be printed, which is what the anchor and
component tables and the hyperperiod chart need (D-257). It also separates
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
  `Simulation` (D-187):* the artifact it names now has a type and an owner.

---

### D-255 — `Run`, the trace split and `StopPolicy`

**Status.** ratified

**Position.** A run is state with a type of its own, and its policy is a
value bound per advance.

- `Run{T}` is a mutable struct with four `const` fields, `t₀`, `mode`, `log`
  and `trace`, and three writable ones, `policy`, `frames` and
  `termination`. `init!` and `replay!` construct one; the loop's tail writes
  `termination` once. `closed(run)` is `termination !== nothing`.
- `Run` is a `Simulation` field beside `control`, so `Simulation` is a
  mutable struct. A `Simulation{T}` is constructed with a placeholder run
  (`t₀ = zero(T)`, `mode = :live`, empty log and trace, no termination) that
  `init!` and `replay!` replace; `Control.lifecycle` says whether it
  started. `termination` leaves `Control`, which keeps the stop word, the
  lifecycle and the wait. `init!` allocates fresh objects rather than
  clearing.
- `Trace{T}` is a fixed header plus two append-only lists, `schemas` and
  `batches`. The header loses its schema list; `attach!` and `detach!` push
  onto the list in place. The register keeps its cursor fields and the
  replay feed.
- `StopPolicy` replaces `RunPolicy`: an immutable value of `t_end` plus the
  stop faces and their addresses, built and validated by each advance and
  rebound on `Run.policy`. `hit` leaves it for the loop's scratch beside the
  cursor. `ControlRequestedStop` is outside the policy: the policy is what
  the caller declares, the stop word is what anyone can issue.
- `t_end` and `stop_on` leave the constructor and are keywords of `run!` and
  `replay!`, with `Inf` and no faces as defaults, validated per call.
  `step!` states the same defaults itself. §13.5's second binding site goes.
  A run with `Inf` and no faces is allowed and raises `UnboundedRun` into
  the loop's diagnostic cell, the status record carrying it.
- The trace header holds the `Deployment` and `t₀`, no policy. Only the
  terminating advance's policy explains the stop, and the termination record
  holds that one.

Supersedes D-091, D-217's header-records-the-constructor-pair bullet, and
D-060's "policy at `Simulation` construction" clause; D-060's rule that
termination is state, never an exception, stands.

**Spec.** §11.5, §12.1, §12.4, §12.6, §12.7, §13.5, Appendix C

**Rationale.** The run was spread across the `Simulation`'s fields and the
control plane. `termination` sat on `Control` beside the stop word, so the
outcome of a run and the surface anyone may poke shared a struct;
`RunPolicy` was mutable because `hit` was written into it by the loop, so a
declared policy and a loop scratch shared a struct; the trace header grew
its schema list in place, so an artifact captured at `init!` was not
immutable; and `t_end`/`stop_on` had two homes, the constructor and the
call, which §13.5 called "the honest cost" of D-091. Each of those is the
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
(§13.5); the advisory lives in the loop's cell because `run!` mutates state.

**Rejected.**
- *Constructor defaults for `t_end` and `stop_on` (D-091):* two homes for
  one fact, with a precedence rule to reconcile them.
- *A mutable `RunPolicy` carrying `hit`:* the declared policy and the loop's
  scratch in one struct.
- *`Run` as an immutable value rebuilt per frame:* the log and trace are
  append-only state; copying them per frame is the allocation §7.5 forbids.
- *`termination` staying on `Control`:* the control plane is what anyone
  may poke; a run's outcome is not.
- *A `Union{Nothing,Run}` field:* every accessor branches on a state
  `lifecycle` already reports.
- *Refusing an unbounded run:* the interactive session's ordinary shape
  would need a sentinel `t_end`.

---

### D-256 — Regroup the `Simulation`'s fields by owner

**Status.** ratified

**Position.** `Simulation` keeps six fields: the build, the deployment, the
executor, the run, the plane and the control. Every other field moves to its
owner.

- To the deployment: `h`, `N_base`, `Δt_base`, the three event parameters,
  `sched`, `D`, `Φ`, `Δt` (D-254).
- To the executor: `chunk_size`, `stepper`, `xnext`, `ẋnext`,
  `has_localized`.
- To the periphery's own types: `join_timeout` into `Control`; `loop_diag`,
  `loop_acct` and `published` into the plane.
- To the run: `t_end`, `stop_on`, `stop_addrs`, `policy`, `log`, `trace`
  (D-255).

**Spec.** §9.7, §11.2, §11.8, §12.1, §12.4

**Rationale.** The `Simulation` had twenty-eight fields because it was the
only struct standing between a build and a running loop, so every value
deployment or the loop needed landed on it. With `Deployment` and `Run`
typed, each field has an owner by the same criterion that placed the
warnings: an artifact's fields go to the artifact, a piece of state goes to
the state that mutates it. The executor owns its stepper and the arrival
buffers because it is the one thing that writes them. `join_timeout` is the
shutdown tail's parameter and the tail runs on `Control`. The loop's
diagnostic cell and account are one more writer's, and the plane holds the
writers. The six that remain are the six things a simulation is.

**Rejected.**
- *Leaving the fields flat:* every reader of a grid parameter or a buffer
  goes through the `Simulation`, so nothing below it can be tested or printed
  alone.
- *A separate `Periphery` struct for the plane, control and published
  holder:* the plane already is that struct.

---

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

**Spec.** §9.2, §13.7

**Rationale.** §9.2 owes the anchor table, the component table and the
hyperperiod chart, and D-187 gave the chart a guard "against absurd
hyperperiods" without saying what the guard does. With the artifacts typed
(D-253, D-254), each table is one type's `show`, and a REPL user gets it by
evaluating the value, which is what "printable" has meant since D-049. The
guard is binary because one hyperperiod is the complete truth: the pattern
repeats with period `lcm(Dᵢ)`, so a prefix is a sample that the chart's own
argument says not to trust. A hundred base ticks is a screen.

**Rejected.**
- *Accessor functions returning tables:* a second API for what `show`
  already is.
- *Prefix rendering of a long hyperperiod:* a sample presented as a chart
  whose claim is completeness.
- *Superseded position — an unspecified guard (D-187):* the guard is now a
  rule.

---

### D-258 — "Schedule" is the tick timing and "execution order" the stage sequence

**Status.** ratified

**Position.** The spec uses "schedule" for the per-component tick timing,
matching `Schedule`, and "execution order" for the order in which the stage
functions run, carried by the `Dataflow` artifact. "Ordering" is the
activity. "Bound schedule" is retired. §5.1 is "The ordering problem",
Stratum B's heading is "execution order", and the glossary's "sweep" is one
pass through the execution order.

**Spec.** §5.1, §5.3, §9.1, §9.2, §10.5, Appendix D

**Rationale.** One word carried two senses: the topological order Stratum B
computes and the `(D, Φ, Δt)` table deployment binds. With both becoming
types (D-253, D-254) the prose had to pick. The tick table keeps "schedule"
because that is what the word means in the multi-rate literature and in
§10.5. The stage sequence is an order, so it is called one. A first sweep
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

---

## Status changes to older entries

- D-091 `superseded → D-255`.
- D-169 `superseded → D-252`.
- D-016, D-035, D-060, D-187, D-209, D-217 stay `ratified`; each new entry
  names the clause it supersedes as a *Superseded position* or in its
  Position. D-152 keeps `superseded → D-154`.

## Spec edits the commit makes beyond the entries

Each item lands in the section the entry cites, under `spec_style.md`.

- §5.3: the publication rule and the hand-down's exclusion go; the port
  classes are two; "declared and produced by no stage" cites
  `DeclaredNotProduced`. First prose use of "execution order" gets its
  glossary link (the sweeps left the section unlinked).
- §8.3: the auto-published class leaves the classification.
- §8.8: `select`, the exclusivity rule, `EmptyFaceSelection`.
- §9.1: the strata's products named; Stratum B's prose as the nominal
  evaluation's structural half; deployment binding as the `Deployment`
  constructor; the `Simulation` materializing at `T`.
- §9.2: the `Build` roster (structure, dataflow, events, activations,
  warnings); the anchor-relative tables on `Structure`; the `Schedule` on
  the `Deployment`; the chart guard; `show` per type.
- §11.5: the header holds the `Deployment` and `t₀`, no policy; the schema
  list beside the batches.
- §12.1, §12.4, §12.6: `Run`, `closed(run)`, `termination` off `Control`,
  the placeholder run.
- §12.7: replay compares deployments as values.
- §13.2: the two streams become the artifact criterion; the service-warning
  paragraph goes.
- §13.5: the second binding site goes; `run!`, `replay!` and `step!`
  defaults; the unbounded run and `UnboundedRun`.
- Appendix C: `logged` widened; `EmptyGreedyClaim` to the roster entry's
  cell; `GridUtilization` to the deployment's warnings; `EmptyFaceSelection`
  added; `UnknownFaceSelection`'s reason column; `DeclaredNotProduced`'s
  remedy.
- Appendix D: "auto-published port" retired; "execution cursor" reworded
  (the "as" hinge); `Structure`, `Dataflow`, `Events`, `Deployment`,
  `Schedule`, `Run` entries added; "artifact" and "state" entries added.
- Generic "dataflow" at three sites (§9.7, §15) respelled so the word is
  reserved for the type.
- `pending.md`: the first bullet becomes the umbrella bullet naming the
  roadmap.
