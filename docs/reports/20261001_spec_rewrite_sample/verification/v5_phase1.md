# new5.md phase 1 (blind)

V1 By default the build types the model only at Float64.
V2 Linearization and gradient trim need the model typed at a non-Float64 scalar, namely a Dual.
V3 An activation supplies that typing.
V4 An activation is the build's typed products at a given scalar type.
V5 (structure) Section covers four topics.
V6 **For a new scalar type, only the activation step re-runs** [D-259]. (bold)
V7 An activation at T re-runs the activation step with a different scalar.
V8 It redoes five things.
V9 Re-types producer-fed cells by walking producer's output declaration at T [§8.2].
V10 A continuous producer's output declaration follows the activation scalar at every unpinned leaf.
V11 A discrete producer's output declaration pins; it does not follow the activation scalar.
V12 Re-types root-input cells by walking consumer's u_types entry at T.
V13 §8.2 reads that entry permissively.
V14 An unpinned u_types entry follows the activation's scalar.
V15 A Pinned entry stays frozen across activations.
V16 Leaf walk re-derives the state type from x_init.
V17 Table buffers and state buffers are laid out again.
V18 Workspace allocators invoked again; continuous component's allocator invoked at T [D-263].
V19 Discrete component's allocator invoked at Float64, not T [D-263].
V20 Activation does not introduce these allocators; they exist before it.
V21 Their first invocation happens before the nominal evaluation's probes [§9.1/§9.3].
V22 Continuous component's scratch carries the activation's scalar type [§7.3].
V23 The probe chain runs again.
V24 **Across activations, execution order never changes and no name list changes** [D-253]. (bold)
V25 Structure is the product of the structure step.
V26 Outputs is the product of the nominal evaluation.
V27 Neither depends on T, by construction.
V28 "This is why" execution order and name lists do not change (causal link).
V29 **Each activation probes exactly the set of functions that activation can execute, no more and no fewer** [D-052]. (bold)
V30 Linearization and gradient trim use a Dual activation.
V31 A Dual activation evaluates the model at a frozen instant.
V32 Its discrete stages are gated off and hold Float64 values.
V33 This is the frozen-constant semantics of §8.2.
V34 Its guards and handlers never run, because event localization runs as Float64 sweeps by design [§10.4].
V35 Only continuous output stages (y_state/y_direct) and x_deriv ever see a Dual.
V36 So only those are probed at Dual.
V37 Probing discrete stages, s_update or guards at Dual would check code against a number type it cannot receive.
V38 The rule has no special cases.
V39 The tracer activation of §5.6 follows it identically.
V40 "Tracer activation" names the global set-tracer [D-012].
V41 It is a whole-model run at the tracer scalar.
V42 It is an activation like any other.
V43 The other tracer variant is the cycle classifier [§5.6, D-012].
V44 Cycle classifier traces each cycle member locally.
V45 It needs no execution order.
V46 It runs in the nominal evaluation's failure path.
V47 It is not an activation at all.
V48 **Non-nominal activations run at first request, not at build** [D-052]. (bold)
V49 Dominant cost of a non-nominal activation is compiling the continuous chain a second time at Dual.
V50 Non-nominal activations are lazy because that cost is pure waste for interactive fly-around use.
V51 Laziness has a price, and the spec states it openly.
V52 The price: a successful build does not certify linearizability.
V53 A pinned Float64 [§7.2] can appear in two places that break linearizability.
V54 It may hide in a constructor.
V55 Or a Float64 may be declared Pinned at a leaf that really participates; that is §8.2's misplaced pin.
V56 Either lurks undetected until the first Dual activation.
V57 At that activation the probe fails and names the offending constructor or leaf.
V58 "To compensate", the repository's test suite makes linearizability an invariant, held by policy rather than by advice.
V59 **Every component gets a Dual activation built in CI** [D-280]. (bold)
V60 An opt-in exhaustive mode builds the Dual activation for every component.
V61 Invoked as build(world; activations = (Float64, ProbeDual)).
V62 This call runs the exhaustive set.
V63 Exhaustive mode catches genericity violations and misplaced pins at PR time.
V64 Its cost is one activation per component.
V65 **The activations keyword of build is the whole entry point for this check** [D-275]. (bold)
V66 **No separate check function exists** [D-275]. (bold)
V67 The same keyword is also recommended for the parallel-sweep idiom [§11.1].
V68 For a parallel sweep, pre-materialize the activations the sweep will need.
V69 With them pre-materialized, the shared Build is fully immutable, with no synchronization on any path.
V70 **ProbeDual is the framework's public canonical probe scalar** [D-099]. (bold)
V71 Defined as const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}.
V72 ProbeDual exists because an activation is keyed by a concrete scalar type.
V73 Bare Dual is a UnionAll, so it cannot key an activation.
V74 It cannot be walked to, and cannot answer zero(T).
V75 ProbeDual's width is arbitrary.
V76 CI pins genericity, not any Jacobian, so one canonical width suffices.
V77 §14.10 chunks at whatever widths it needs; that does not contradict one canonical width.
V78 **The activation cache lives on the Build** [D-135]. (bold)
V79 It lives there because an activation is a pure function of build and concrete scalar type.
V80 **The activation cache holds only immutable compiled artifacts** [D-135]. (bold)
V81 It is one activation dictionary keyed by concrete scalar type.
V82 Each entry holds layouts, compiled plans and a validated flag.
V83 An entry is immutable once constructed, so it is freely shareable.
V84 **The nominal Float64 entry is one key in the activation dictionary, like any other** [D-253]. (bold)
V85 **Whether an activation is cached never changes a result** [D-052]. (bold)
V86 Dual{Tag,V,N} carries the partial count.
V87 So a different seeding width is a different scalar type.
V88 It gets a separate cache entry and a separate Julia compile.
V89 **Every buffer set has exactly one owner** [D-282]. (bold)
V90 Simulation owns its nominal activation's buffers.
V91 Simulation construction materializes them from cached layouts.
V92 The loop's zero-allocation stepping runs on these buffers.
V93 Every service invocation owns the scratch set it instantiates from the same cached layouts.
V94 §14.8 states this rule for trim!.
V95 It is the general rule, not local to trim.
V96 "Because every buffer set has one owner", buffers are never cached.
V97 Julia caches compiled code process-wide.
V98 The framework's cache saves the expensive part: probe re-runs, layout construction, Julia's compilation of the Dual chain.
V99 These savings amortize in loops that reuse an activation.
V100 In envelope-grid gain-schedule, hundreds of trim-then-linearize points pay cached costs once.
V101 Per-point allocation of a working store set does not amortize.
V102 It is O(model size), trivial against the solve it feeds.
V103 Zero-allocation invariant [§7.5] covers only the stepping loop.
V104 Services were always allocation-tolerant.
V105 Nothing numerical is ever cached.
V106 **Lazy materialization of activations is torn-state-free** [D-281]. (bold)
V107 Concurrent first requests for the same activation must never expose partially populated cache state.
V108 Torn state is excluded by contract, not by luck.
V109 The mechanism is unspecified.
V110 A guard around cache insertion suffices.
V111 Its cost is paid at service time, never on the hot path.
V112 An activation is a pure function of build and scalar, so the worst benign race is duplicated work.
