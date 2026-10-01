# A2 verify, phase 1 (blind): assertions in new.md

Intro (l.3-10)
- V1 The build's three steps leave their products on a `Build` [§9.1].
- V2 Deploying a build at grid parameters leaves a second artifact, the `Deployment`, scalar-free, fixed by the grid parameters.
- V3 The deployment carries the `Schedule`, the typed per-component `(D, Φ, Δt)` tick table.
- V4 A `Simulation` materializes a deployment at a scalar type.
- V5 (pointer) Section states contents, printing, binding, grid explanation, warnings.

The `Build`
- V6 [bold] `build(world) → Build` is a standalone entry point [D-049].
- V7 CI checks a model by calling `build`.
- V8 Acceptance tests target `build` errors directly.
- V9 `attach!` validates device bindings against the Build.
- V10 Build living only inside the `Simulation` constructor was rejected.
- V11 [bold] A `Build` is structure, outputs, events, the activations and `warnings` [D-253].
- V12 The first three are the products of §9.1's three steps.
- V13 [bold] Deploying and materializing are two steps, with two sugar forms over them [D-254].
- V14 The `Deployment` constructor takes a `Build` and the grid parameters.
- V15 `Simulation(deployment, T)` materializes a deployment at a scalar type.
- V16 `Simulation(build; kw...)` composes the two steps.
- V17 `Simulation(world; kw...)` calls build first.
- V18 The artifact deployed is the very build CI checked / acceptance test targeted / face-route table printed from, never an assumed-equal reconstruction.
- V19 Computed interface-connection bodies are ordinary user code re-evaluated on every build.
- V20 So equality between two builds of the same world is an assumption; the factorization removes it.
- V21 [bold] The `Build` is immutable and may back any number of deployments and Simulations, concurrently [D-135].
- V22 True by construction once buffers are single-owner.
- V23 §9.4 states the ownership rule and the activation dictionary's torn-state-free insertion.
- V24 The `Build` is the inspectable derived contract of the instantiation that §8.8 gestures at.
- V25 Its parts hold wire list, face table, root inputs and execution order as plain printable data.
- V26 First three sit on `Structure` (components, wires, faces, tiers).
- V27 Execution order sits on `Outputs` (nominal evaluation's product; port classes and execution order).
- V28 "Printable" names the representation: paths, names, rationals inspectable as fields; any REPL prints them without a method of their own.
- V29 That is the diagnostic form, set against the compiled form [§9.7].
- V30 [bold] The face table on `Structure` is two-sided [D-207].
- V31 Beside each level's output faces and routes, it retains that level's input faces.
- V32 Each input face is resolved producer-ward to the one feed its consumers share, a root input or a producer inside the model.
- V33 The record is total, because one-level routing gives every signal a declared face at every boundary it crosses [§6.1].
- V34 The input side is what a fragment's `u` payload resolves against from any authoring level [§14.2, §14.3].
- V35 [bold] `Structure`'s timing tables are anchor-relative, and the `Deployment` binds them [D-186].
- V36 The structure step gives two printable tables.
- V37 Anchor table: each anchor's exact `(T, τ)` rationals with declaring scope's path and key.
- V38 Component table: `(anchor, m, c)` triples with rate chain (Relative/Absolute chain down the tree).
- V39 `A₀` has its own anchor-table row with dash in scope/key columns, because no scope declares it.
- V40 Its `(T, τ)` stays symbolic until `Δt_base` binds.
- V41 For a fully relative model the only anchor is `A₀` and the triples are the final base-tick `(D, Φ)` pairs.
- V42 When anchors exist, final divisors cannot live here: they don't exist until `Δt_base` binds, and the same Build backs many deployments with different grid parameters.

Rendering
- V43 [bold] An artifact holds declared facts; a consumer compiles what it needs once, at one home [D-261].
- V44 The activation's cell layout is that home for address facts.
- V45 A compiled form stored beside its declared one is a second home with no enforcer but the constructor that filled both.
- V46 [bold] Each artifact renders itself through `show`, with no accessors [D-257].
- V47 show(::Structure) prints anchor table with A₀ row, component table with rate-scope rows (assembly's `sample_times` against enclosing scope), and root's face routes, one line per chain [§13.7].
- V48 show(::Outputs) prints execution order with each port's class.
- V49 show(::Schedule) prints rows and the hyperperiod chart.
- V50 show(::Build) and show(::Deployment) print a summary and their parts.
- V51 A REPL user gets each table by evaluating the value.
- V52 Chart pattern repeats with period lcm(Dᵢ) base ticks; gate is pure modulo arithmetic; so one hyperperiod is complete truth.
- V53 [bold] The chart guard is binary [D-257].
- V54 Chart prints whole over k = 0 … lcm−1 when lcm(Dᵢ) ≤ 100 base ticks; otherwise show prints the hyperperiod length and "chart omitted".

The `Deployment`
- V55 [bold] A `Deployment` is scalar-free and carries everything the grid parameters fix [D-254].
- V56 Its constructor sits after the three steps; nothing in them depends on it.
- V57 Constructor consumes Build and grid parameters; binds grid params, algorithm and three event params; runs harmonic-grid validation; builds the schedule.
- V58 The Deployment holds build, grid params, algorithm, three event params, Schedule, grid diagnostics, own `warnings`.
- V59 `Simulation` materializes it at scalar type T.
- V60 Two deployments compare as values; replay's header check reads that [§12.7].
- V61 [bold] `Δt_base` has exactly one of three sources, cross-validated [D-186].
- V62 Explicit keyword (Rational, Period or Hz); N_base derived Δt_base/h, validated integer ≥ 1.
- V63 N_base·h product when only N_base is given, today's rule, default N_base = 1.
- V64 Derivation, permitted only when every discrete component is anchored (anchor 0 unpopulated).
- V65 Derivation requested explicitly with `Δt_base = :derive`; never by default; N_base·h stays what silence means.
- V66 [bold] If any unanchored component exists, deployment must declare Δt_base [D-186].
- V67 The refusal is constructive, carrying the grid diagnostics' suggestion message.
- V68 Under anchored-only, Δt_base is pure bookkeeping no component's period depends on.
- V69 Unanchored component's period is m·Δt_base; deriving with one present would let an anchor edit anywhere silently rescale it (action at a distance).
- V70 Admissibility is exact GCD arithmetic over the pool; table: pool = every anchor period and nonzero offset; admissible divides every entry ⇔ divides gcd(pool); set gcd/k; derived = gcd itself, coarsest; per anchor Dₖ=Tₖ/Δt_base, Φₖ=τₖ/Δt_base; per component D=m·Dₖ, Φ=Φₖ+c·Dₖ, Δt=D·Δt_base.
- V71 Resolution is one division pair per anchor and one multiply-add per component.
- V72 Dₖ and Φₖ must both be exact integers, else DeploymentInvalid naming anchor with declaring scope and key.
- V73 The per-component triples are the schedule the constructor builds and the Deployment carries.
- V74 [bold] Deployment validation is collected like its declarative siblings [§13.1, D-229].
- V75 Violations collected and reported as DeploymentInvalid [App C], carrying parameter, value, violated constraint; list of 8 violation kinds.
- V76 Event parameters validate on their own terms only; grid-independent, no part in harmonic-grid check [§10.4, §10.6].
- V77 [bold] The `Schedule` lives on the `Deployment` [D-254].
- V78 Constructor builds it from structure's triples and anchors; it is the typed schedule.
- V79 One row per discrete component, (D, Φ, Δt) with anchor and rate-chain columns; rate-scope rows each with (Dₛ, Φₛ).
- V80 Per-component (D, Φ, Δt) the executor compiles over are derived at compile, never stored beside them [D-261].
- V81 Schedule is single source of truth for Δt [§10.5]; substrate of grid diagnostics; answers "when does what run, what coincides".
- V82 Worked example: §10.5 model, three components, two scopes; deploy at 2 ms; Absolute entry seeds A₁ = (1//50, 0); rest on anchor 0; table values.
- V83 gnss's divisor could not exist before Δt_base bound; D = m·D₁, D₁ = (1//50)/(1//500) = 10.

Grid diagnostics
- V84 [bold] Grid diagnostics live on the Deployment and print from the pool, exactly [D-254].
- V85 Refusal path's suggestion and derivation path's info line share one substrate: coarsest admissible Δt_base with set gcd/k, and per-entry attribution.
- V86 Leave-one-out factors r_p = gcd(pool∖p)/gcd(pool), integer ≥ 1, "how much coarser without this entry".
- V87 [bold] Every r_p > 1 is listed rather than one culprit crowned [D-187]; joint responsibility is the honest answer.
- V88 Prime attribution: each prime power of 1/Δt_base traced to the pool entries whose denominators supply it; pinpoints what an edit changed.
- V89 When an offset is a driver, message adds nearest non-refining alternatives (admissible offsets on the grid the rest supports); turns diagnostic into repair.
- V90 [bold] Blame is computed against the actual pool [D-187]; simple-fraction-of-period test stays authoring guidance, never the engine's.

Warnings
- V91 [bold] A completing step carries warnings on the artifact; entry point logs each once at return [D-250].
- V92 A throwing step renders its warnings with the collection it throws.
- V93 Logging is presentation, never a home [§13.2].
- V94 A warning raised in a declaration body has no artifact in hand; the build binds a scoped channel around its three steps; helper appends without knowing the build; standalone call logs directly.
- V95 That is how EmptyFaceSelection [§8.8] reaches the Build's list.
- V96 The derivation path is the one place refinement happens silently.
- V97 It always prints the derived value with its drivers.
- V98 It carries the one advisory, GridUtilization [App C].
- V99 Advisory reports min_i Dᵢ as "grid is N× finer than the fastest declared work" with drivers named.
- V100 Information rather than scolding; a scope declared finer than its fastest member for stagger room [§10.5] legitimately inflates the metric.
- V101 GridUtilization is a deployment warning, lives on the Deployment's list, constructor logs it once at return.
- V102 [bold] `warnings(x)` defined on Build and Deployment, and on Simulation as concatenation of its artifacts' lists [D-250].
- V103 It reads the list.
- V104 Warnings raised while mutating state stay in that state's status record [§11.8], never here.
