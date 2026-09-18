# The pipeline redesign: settled register

The settled outcome of the 2026-09-18 design session that began as
`pending.md`'s first "Not yet built" bullet (§8.8 beyond the helper pair,
D-187's grid diagnostics, every `show`) and became a redesign of the types
between a model instance and a runnable simulation. Tip at the session's
end: `4a04f5e`. Nothing here is in the spec or the log yet; the docs commit
of step 1 below is where each item becomes normative, and this file is then
the map of what that commit and the increments after it deliver. The
reasoning behind each item is not restated here; the decision entries carry
it.

## The framing

A step is well-defined when it consumes one new piece of information and
fixes everything that piece determines. Read that way the pipeline is:
structure (the instance), dataflow (the instance and one nominal
evaluation), activation (a scalar), deployment (the grid parameters),
materialization (a scalar again, into owned buffers), composition (devices
and conditions), the run (a policy). The strata of §9.1 are the first three,
and they are sound as a dependency order.

An **artifact** is an immutable pure function of its inputs; **state** is
single-owner and mutated in place. Structure, dataflow, events, activations,
the build, the deployment, a condition plan and a trim report are artifacts.
The executor's buffers, the roster, the diagnostic cells, the live log and
trace are state. The criterion decides where warnings live (items 1–6), and
it is why the deployment and the run gain types of their own.

## Warnings and artifacts

1. The artifact criterion is the one warning policy. A warning raised
   producing an artifact lives on that artifact. A warning raised mutating
   state lives in that state's status. Logging is presentation, never a
   home.
2. `Build` and `Deployment` carry `warnings`. A stratum that throws renders
   its warnings with the collection; one that completes carries them on the
   artifact and the entry point logs each once at return.
3. A scoped channel bound by the walk lets a helper running inside a
   declaration body append to the build's warnings. A standalone call
   outside any build logs directly.
4. Appendix C's `logged` policy widens to any artifact-producing call, build
   included. The collected-warning slot stays open and empty (D-084 stands).
5. `warnings(x)` is defined on `Build` and `Deployment`, and on `Simulation`
   as the concatenation of its artifacts' lists. Status-side warnings stay in
   the status record.
6. `EmptyGreedyClaim` moves to the roster entry's diagnostic cell, since
   `attach!` mutates the roster, and surfaces through the status record. The
   log line at return stays as presentation.

## §8.8

7. Selectors are exclusive: `except`, `only` and a new `select` predicate
   over face names, one per call. The `:both_given` arm generalizes to "more
   than one selector given".
8. An empty selection warns, as a build-stage warning through item 3, when a
   selector was given and nothing survived. A bare call over a faceless
   child is silent.
9. Required-faces declarations are not owed. Recorded as possible sugar and
   dropped from the bullet.
10. The feed-list idiom gets a test transcribing the spec's sketch against
    the real helpers. No code.

## The port model

11. Auto-publishing is removed. Two port classes, stage 1 and stage 2.
    Exposed state is returned from `output_state`. "Declared but produced by
    no stage" is an error everywhere. Supersedes D-016's publication rule,
    D-152's successor and D-169. The fixture and case-study sweep needs a
    count of reliant components by probe before it starts; the reliance is
    implicit, so a grep will not find it.

## The build-side types

12. `Structure` replaces `Flat` as Stratum A's product, with `tiers` moved
    in, plus two new fields: per-component declaration provenance (the
    `Relative`/`Absolute` chain), and the scope triples of assemblies with
    an explicit `sample_times` key.
13. `Dataflow` is Stratum B's product: per component the stage-1 and stage-2
    name sets, the feedthrough edges with provenance, and the evaluation
    order.
14. `Events` is Stratum B's other product: per component the event names,
    detection policies and bundle names. Produced as B's last step, after
    the nominal stage probes.
15. Stratum B gets its own function, consuming the structure and returning
    the dataflow and events with the `Float64` stage-1 products. Stratum C
    takes those and completes an activation. No product changes.
16. `Build` survives as structure, dataflow, events and the activations, with
    `nominal` and `cache` merged into one dictionary keyed by scalar type
    under the existing lock. D-049's reasons still hold: CI targets `build`,
    conditions resolve against it, bindings validate against it, one build
    backs many deployments.
17. Structural consumers read the products, not the `Activation`. Readers,
    trim, the tracer, `compile`'s key slicing and the runtime field-error
    species take name lists from `Structure` and `Dataflow`. Port and face
    name lists are structure and live beside the classification.
18. §9.1's prose says Stratum B is the nominal evaluation's structural half,
    and the nominal activation is B's products plus C's typing.

## Deployment

19. `Deployment` is the build plus `h`, `N_base`, `Δt_base`, the algorithm
    and the three event parameters. Scalar-free. It carries the `Schedule`,
    D-187's grid diagnostics, and its warnings. `Simulation` materializes it
    at `T`. Replay compares two deployments as values.
20. `Schedule` is the typed bound schedule inside the deployment: per
    discrete component `(D, Φ, Δt)` with anchor and provenance columns, the
    rate-scope rows, and the `D`, `Φ`, `Δt` vectors.
21. The grid diagnostics land on the deployment: leave-one-out factors,
    prime attribution, nearest non-refining offsets, the derivation line and
    `GridUtilization`.

## The run

22. `Run{T}` is a mutable struct with four `const` fields, `t₀`, `mode`,
    `log` and `trace`, and three writable ones, `policy`, `frames` and
    `termination`. `init!` and `replay!` construct one; the loop's tail
    writes `termination` once. `closed(run)` is `termination !== nothing`.
23. `Run` is a `Simulation` field beside `control`, so `Simulation` becomes
    a mutable struct. `termination` leaves `Control`, which keeps the stop
    word, the lifecycle and the wait. `init!` allocates fresh objects rather
    than clearing.
24. `Trace{T}` is a fixed header plus two append-only lists, `schemas` and
    `batches`. The header loses its schema list, and `attach!` and `detach!`
    push onto the list in place. The register keeps only its cursor fields
    and the replay feed.
25. `StopPolicy` replaces `RunPolicy`: an immutable value of `t_end` plus the
    stop faces and their addresses, built and validated by each advance and
    rebound on `Run.policy`. `hit` leaves it for the loop's scratch beside
    the cursor. The introducing entry states that `ControlRequestedStop` is
    outside the policy: the policy is what the caller declares, the stop
    word is what anyone can issue.
26. `t_end` and `stop_on` leave the constructor and are keywords of `run!`
    and `replay!`, with `Inf` and no faces as defaults, validated per call.
    `step!` states the same defaults itself. §13.5's second binding site
    goes.
27. The trace header holds the `Deployment` and `t₀`, no policy, since only
    the terminating advance's policy explains the stop and the record holds
    that one.

## The `Simulation`

28. Its fields regroup. To the deployment: `h`, `N_base`, `Δt_base`, the
    three event parameters, `sched`, `D`, `Φ`, `Δt`. To the executor:
    `chunk_size`, `stepper`, `xnext`, `ẋnext`, `has_localized`. To the
    periphery's own types: `join_timeout` into `Control`, `loop_diag`,
    `loop_acct` and `published` into the plane. Remaining: the build, the
    deployment, the executor, the run, the plane and the control.

## Renderings

29. Each type renders itself, with no accessors. `show(::Structure)` prints
    the anchor table with the `A₀` row and the component table with the
    rate-scope rows. `show(::Dataflow)` prints the order with port classes.
    `show(::Schedule)` prints the rows and the hyperperiod chart.
    `show(::Build)` and `show(::Deployment)` print a summary and their
    parts. The face-provenance printer joins `Structure` when the routing
    chain is recorded (still the "Smaller" bullet's item).
30. The chart guard is binary: the chart prints whole when `lcm(Dᵢ)` is at
    most 100 base ticks, and otherwise the hyperperiod's length with "chart
    omitted". No prefix rendering, because one hyperperiod is the complete
    truth and a prefix is a sample.

## Vocabulary

31. In the spec, "bound schedule" becomes "schedule", matching `Schedule`,
    and today's "schedule", the evaluation order, becomes "dataflow", one
    word, matching `Dataflow`. The second is a sweep assigning every
    occurrence to one sense; §5.1, Stratum B's heading and the glossary's
    "sweep" entry change meaning.

## Sequencing

32. Seven steps in dependency order:
    1. the docs commit: one decision entry per settled theme, the vocabulary
       sweep, the artifact criterion, the auto-publishing removal, the type
       roster;
    2. the auto-publishing removal with its fixture sweep;
    3. the build-side types (items 12–17) with the warnings channel;
    4. the §8.8 increment (items 7–10), which needs step 3's channel;
    5. `Deployment` and `Schedule` with the grid diagnostics and the
       Stratum A recording;
    6. `Run`, the trace split and the policy change, with the greedy-claim
       move;
    7. the renderings.

    The uncommitted audit refresh under `docs/reports` is committed or set
    aside before step 1. Step 1's decision entries are drafted and shown
    before the spec is touched.
