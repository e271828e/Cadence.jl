# Agent C — §9 the build pipeline

## 1. Header

- **Agent**: C
- **Slice**: §9 the build pipeline (§9.1–§9.7)
- **Spec lines**: 2847–3660 of `docs/design/spec.md`
- **Tip**: `70672d1`, Julia 1.12.7
- **Probes run**: yes. Four foreground `julia --project=.` scripts from the
  repository root, in `scratchpad/agentC/`. They exercised abstract entries,
  abstract root inputs, `probe_value` fallback, enum root inputs, the
  walk-compatibility clause, the runtime conformance check on three kinds of
  branch divergence, the dead-stage rule, the derivative shape predicate, and
  build-time framing of a throwing stage.
- **Accidental read of a forbidden file**: yes, partial. Grepping the file
  table out of `docs/design/implementation.md` with a trailing context window
  overran into the start of its "Authoring caveats" section (about ten lines),
  which mentions in passing that `DeadStage` is not built. I had already read
  `src/` and reached that conclusion independently; no other part of that file
  was read, and `pending.md`, the other reports and `briefs/` were not opened.

## 2. Summary

Strata A and B are in good shape. The tree walk, the one-writer rule, the
whole-tree obligation check, the did-you-mean payloads, the sample-time fold to
`(anchor, m, c)` triples, the feedthrough graph, the topological order and the
cycle refusal are all there, mostly with tests that pin the spec's own worked
numbers. Deployment binding is exact-rational throughout and implements all
three `Δt_base` sources including the `:derive` restriction, with the eight
listed `DeploymentInvalid` conditions all present. Stratum C, activations and
the compiled executor are close to the spec: lazy caching keyed by concrete
scalar, per-activation executable sets, frozen discrete products carried
across, chunked two-arity phase bodies, the `(idx − Φ) % D` gate, per-eltype
cell storage, and a warm-then-assert allocation suite at per-body granularity.

The gaps cluster in three places.

**§9.5 has no runtime half.** The always-on conformance check does not exist.
`run!(::StageEntry)` scatters the stage's return straight into the table
(`src/executor.jl:145-149`), and `scatter_group!` fetches each declared name by
`getfield` and stores its leaves into a typed buffer
(`src/store.jl:82-88`, `src/leaves.jl:135-152`). A probe confirmed the three
consequences: a field that arrives `Int64` where `Float64` was declared is
**silently converted**, an extra returned field is **silently ignored**, and a
missing field surfaces only as a raw `FieldError` wrapped by the generic
`StepError`, with no field-level diff. Convert-on-write at the table write is
the exact shape D-053 lists as *rejected*, so this is the slice's most serious
deviation.

**The three type clauses are one clause, and it is the wrong one.** Stratum A's
bound check (`producer <: entry` at nominal) is not implemented as a subtype
test; the only wire check is `_accepts` at the probe (`src/build.jl:179-190`),
which is equality modulo the `Dual`/`Float64` embedding. A lawful abstract entry
on a component-fed input is therefore **refused**, and an abstract root input is
refused with a `WireTypeMismatch` that blames the synthesized value. The
walk-compatibility clause and `WalkingFaceAtFrozenEntry` do not exist at all; a
walking producer feeding a pinned `Float64` entry builds clean at nominal and
only detonates if someone later materializes a `Dual` activation.

**The printable artifacts of §9.2 are data without a rendering, and the grid
diagnostics stop at `gcd(pool)`.** There is no `show` for `Build` or for the
bound schedule, no anchor table, no `A₀` row, no provenance column on the
component triples, no hyperperiod chart, no rate-scope rows. Of D-187's four
attribution forms only the coarsest admissible value is printed: no
leave-one-out refinement factors, no prime attribution, no nearest non-refining
offsets, no derivation info line, and no `GridUtilization` advisory. Both
D-053 and D-187 are ratified, so neither absence is settled by the log.

Smaller but real: `DeadStage` is not built; `probe_value` has no enum method and
a missing method escapes as a bare `MethodError` instead of the didactic
face-and-type refusal D-051 ratifies; the closed leaf vocabulary is checked on
ports and root inputs but **not** on `init_x`, so a bad state leaf crashes inside
`reconstruct`; `ProbeDual`/`ProbeTag` do not exist and the test suite uses a
local `D8`; a stage that throws at the probe is not wrapped in `UserCodeFraming`;
`phase_bodies` returns the four bodies but not the guards, handlers and
projection callables; and the whole notion of an **auto-published port** is
absent from `src/` and `test/`, which makes §9.1's three-way port classification
a two-way one.

What surprised me: the deployment-keyword validation collects, and
`bind_schedule`'s anchor loop collects, but they sit behind two sequential
barriers with a fail-fast run of `h`/`n`/`Δt_base` checks between them, so a
model with a bad `h` and a bad `firing_budget` reports only the second.

## 3. Findings table

| § (line) | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 9 (2849) | `build` produces resolved wires, typed signal table, schedule, absolute rate divisors, flat state layout, root inputs | accurate | `src/build.jl:381-393`, `src/assembly.jl:630-676` | `test_build.jl:44` "the schedule follows the feedthrough graph" | divisors become absolute only at `bind_schedule`, as §9.1 says |
| 9.1 (2859) | face derivation is bottom-up | accurate | `src/assembly.jl:439-471` | `test_assembly.jl:496` "a face's type and tier are its internal endpoint's" | |
| 9.1 (2862) | unconnected-input and cross-level two-producer detection are global, at the root | accurate | `src/assembly.jl:643-655`, `src/assembly.jl:754-765` | `test_assembly.jl:547` "every input is fed exactly once, across levels" | |
| 9.1 (2865) | stage membership is derived by probing the stage-1 functions | accurate | `src/build.jl:114-131`, `src/build.jl:216-249` | `test_build.jl:44` | |
| 9.1 (2871) | Stratum A runs no user stage code | accurate | `src/assembly.jl:630-676` | no test | `flatten` calls only declaration bodies |
| 9.1 (2877) | components collected by path | accurate | `src/assembly.jl:677-753` | `test_assembly.jl:103` "container children are path-named" | |
| 9.1 (2878) | class read off declaration shape | accurate | `src/assembly.jl:40-60` | `test_assembly.jl:29` "class is read off the declaration shape" | |
| 9.1 (2880) | leaf contracts collected (`input_types`, `output_types`, `init_*`, `state_events`) | accurate | `src/build.jl:34-39`, `src/build.jl:398-427` | `test_build.jl:145` "tier is read off the declaration shape" | |
| 9.1 (2882) | face derivation records input and output faces per level with the chain each routes through | short | `src/assembly.jl:660-673` | `test_assembly.jl:496` | both sides recorded; the routing *chain* is collapsed to the ultimate endpoint, no provenance kept. See 4.7 |
| 9.1 (2884) | global wiring resolution resolves wires to absolute leaf terminals | accurate | `src/assembly.jl:439-478` | `test_assembly.jl:325` "a wiring endpoint names one child and one of its faces" | |
| 9.1 (2891) | one-writer-per-input | accurate | `src/assembly.jl:754-765` | `test_assembly.jl:547` | `TwoProducers` |
| 9.1 (2892) | typo did-you-mean: offending name plus list-in-hand | accurate | `src/assembly.jl:479-491`, `src/assembly.jl:273-291` | `test_assembly.jl:325`, `test_assembly.jl:399` | `UnknownPort.candidates`, `PathResolution.candidates` |
| 9.1 (2894, 2902) | the bound check: producer declaration at `Float64` `<:` the entry at `Float64` | stand-in | `src/build.jl:179-190`, `src/build.jl:1016-1035` | `test_build.jl:201` "embed-accept keeps the constant branch legal" | equality-modulo-embed at the probe, not a subtype test at Stratum A; refuses a lawful abstract entry. See 4.1 |
| 9.1 (2894, 2906) | the walk-compatibility clause, diagnostic `WalkingFaceAtFrozenEntry` | absent | — | — | nothing checks it; only a `Dual` activation catches the case, as `WireTypeMismatch`. See 4.2 |
| 9.1 (2895) | the whole-tree obligation check | accurate | `src/assembly.jl:643-652` | `test_assembly.jl:547` | `UnconnectedInput` |
| 9.1 (2896) | closed leaf vocabulary checked on every `init_x` | absent | — | — | checked on ports and root inputs (`src/build.jl:275-281`) but never on `init_x`. See 4.3 |
| 9.1 (2899) | root inputs fall out as the root component's input faces | accurate | `src/assembly.jl:684-693`, `src/assembly.jl:733-741` | `test_assembly.jl:62` "a primitive root is the whole model" | |
| 9.1 (2905) | abstract-at-root is detected here | stand-in | `src/build.jl:1029-1033` | no test | detected at the probe as `WireTypeMismatch` blaming the synthesized value, not at Stratum A. See 4.1 |
| 9.1 (2913) | Stratum A checks: a store without its update | accurate | `src/build.jl:73-77` | `test_build.jl:28` (`NoFlow` → `StoreWithoutUpdate`) | |
| 9.1 (2914) | an event missing a guard or handler method | accurate | `src/build.jl:398-427` | `test_events.jl:72` | `EventHalfMissing` |
| 9.1 (2915) | a leaf mixing tier families | accurate | `src/build.jl:85-96` | `test_build.jl:145` | `DeclarationOnWrongTier`, collected |
| 9.1 (2916) | a contract signature whose form contradicts the leaf's tier | accurate | `src/build.jl:66-70`, `src/build.jl:79-83` | `test_build.jl:145` (`BothArities`, `WrongArity`) | |
| 9.1 (2918) | `sample_times` per-entry validity, collected with path attribution | accurate | `src/assembly.jl:551-582` | `test_discrete.jl:105` "the fold validates with path attribution" | wrapper vocabulary, `K ≥ 1`, `0 ≤ φ < K`, `T > 0`, `0 ≤ τ < T` all present |
| 9.1 (2923) | keys name discrete or scope children | accurate | `src/assembly.jl:577-580`, `src/assembly.jl:700-705` | `test_discrete.jl:105` | `:unknown_child`, `:continuous_child` |
| 9.1 (2926) | compilation into `(anchor, m, c)` triples | accurate | `src/assembly.jl:600-618`, `src/assembly.jl:504-514` | `test_discrete.jl:199` "relative scopes compose affinely; anchors sever" | |
| 9.1 (2934) | root scope seeds `(A₀, 1, 0)` | accurate | `src/assembly.jl:637` | `test_discrete.jl:162` | |
| 9.1 (2935) | `Relative(K, φ)` under `(a, mₛ, cₛ)` → `(a, K·mₛ, cₛ + φ·mₛ)` | accurate | `src/assembly.jl:611-613` | `test_discrete.jl:199` | |
| 9.1 (2936) | `Absolute(q, τ)` severs and re-seeds `Aₖ = (period(q), τ)`, subtree at `(Aₖ, 1, 0)` | accurate | `src/assembly.jl:615-617` | `test_discrete.jl:199`, `test_discrete.jl:162` | |
| 9.1 (2940) | anchor 0 stays symbolic until deployment | accurate | `src/build.jl:757-759` (`Dk = [1]`) | `test_discrete.jl:228` "one Build backs many Simulations" | |
| 9.1 (2942) | canonical residue `c < m` holds per anchor subtree | accurate | `src/assembly.jl:611-613` + the `0 ≤ φ < K` check | `test_discrete.jl:199` | by induction; no runtime check needed |
| 9.1 (2946) | everything except binding `Δt_base` happens in Stratum A | accurate | `src/build.jl:381-393` | `test_build.jl:54` (build refuses without a deployment) | |
| 9.1 (2948) | workspace allocated at the probing scalar, before Stratum B probes | accurate | `src/build.jl:453`, `src/build.jl:462-465` | no direct test | reads only instance and scalar (D-077) |
| 9.1 (2952) | stage-1 probes run at `Float64` on `init_x`/`init_s`/`init_m` values | accurate | `src/build.jl:114-131`, `src/build.jl:133-147` | `test_build.jl:28` | |
| 9.1 (2955) | ports classified stage-1 / auto-published / stage-2 remainder | short | `src/build.jl:120-131`, `src/build.jl:504-518` | `test_build.jl:44` | two classes only; **auto-published ports do not exist** anywhere in `src/`. See 4.8 |
| 9.1 (2957) | feedthrough graph from stage-2-carrying wires; topological order | accurate | `src/build.jl:216-243` | `test_build.jl:44` | |
| 9.1 (2958) | §5.5 cycle rejection applies | short | `src/build.jl:245-249` | `test_build.jl:54` "an algebraic loop is a build error" | `AlgebraicCycle.members` is every unscheduled component, not the SCC; no per-member local trace (§5.6). See 4.9 |
| 9.1 (2960) | the Stratum B output is names only, `T`-independent | accurate | `src/build.jl:451-457` (`order` computed once, reused by every activation) | `test_build.jl:241` "a non-nominal activation re-runs Stratum C" | |
| 9.1 (2968) | producers' output declarations evaluated at the activation's `T` | accurate | `src/build.jl:34-39` | `test_build.jl:241` | |
| 9.1 (2973) | `init_x`-derived state type walked; `init_s`/`init_m` pin | accurate | `src/build.jl:35-38`, `src/leaves.jl:183-192` | `test_discrete.jl:73` "the discrete tier is frozen at a non-nominal activation" | |
| 9.1 (2975) | probe chain runs in topological order, observed compared against declared | accurate | `src/build.jl:509-522`, `src/build.jl:152-168` | `test_build.jl:28` | |
| 9.1 (2977) | flat `x` buffer and the table laid out | accurate | `src/build.jl:267-302`, `src/build.jl:884-893` | `test_store.jl` (cell store), `test_leaves.jl` | |
| 9.1 (2979) | nominal `Float64` activation runs at build; others re-run only Stratum C | accurate | `src/build.jl:387`, `src/build.jl:429-434` | `test_build.jl:241` | |
| 9.1 (2985) | deployment binds `Δt_base`, `h`, `n`, `t_end`, algorithm, `localization_tol`, `localization_budget`, `firing_budget` | accurate | `src/sim.jl:130-177` | `test_discrete.jl:228` | all eight are keywords of `Simulation` |
| 9.1 (2986) | deployment runs harmonic-grid validation and instantiates the tick schedule | accurate | `src/build.jl:748-789` | `test_discrete.jl:228` | |
| 9.1 (2988) | nothing in A–C depends on deployment | accurate | `src/build.jl:381-393` (no `h`/`n`/`Δt_base` reaches `build`) | `test_discrete.jl:228` (one `Build`, four deployments) | |
| 9.1 (2991) | source 1: explicit `Δt_base` keyword, a `Rational`/`Period`/`Hz`, `n = Δt_base/h` derived and validated integer ≥ 1 | accurate | `src/build.jl:740-752` | `test_discrete.jl:228` | |
| 9.1 (2993) | source 2: the `n·h` product, default `n = 1` | accurate | `src/build.jl:743` | `test_discrete.jl:228` | |
| 9.1 (2995) | source 3: `Δt_base = :derive`, never by default, permitted only when every discrete component is anchored | accurate | `src/build.jl:730-739` | `test_discrete.jl:270` "Δt_base derivation demands an all-anchored model" | |
| 9.1 (3000) | rationale for the anchoring restriction | n/a | — | — | rationale |
| 9.1 (3005) | the refusal is constructive, pointing at the suggestion message | short | `src/diagnostics.jl:820-825` | `test_discrete.jl:270` | names the unanchored paths and offers `Δt_base`/`n`, but carries no pool arithmetic |
| 9.1 (3011) | constraint pool = every anchor period plus every nonzero offset | accurate | `src/build.jl:728-729` | `test_discrete.jl:270` | |
| 9.1 (3013) | admissible `Δt_base` divides `gcd(pool)`; derived value is `gcd(pool)` | accurate | `src/build.jl:740`, `src/build.jl:756` | `test_discrete.jl:270`, `test_discrete.jl:228` (`admissible == 1//50`) | |
| 9.1 (3018) | per anchor `Dₖ = Tₖ/Δt_base`, `Φₖ = τₖ/Δt_base`; per component `D = m·Dₖ`, `Φ = Φₖ + c·Dₖ`, `Δt = D·Δt_base` | accurate | `src/build.jl:760-786` | `test_discrete.jl:162` "the worked example compiles to the spec's pairs" | the spec's own `(1,0)/(5,2)/(10,0)` are asserted |
| 9.1 (3021) | `Dₖ`, `Φₖ` must be exact integers, else `DeploymentInvalid` naming the anchor with scope and key | accurate | `src/build.jl:761-773`, `src/assembly.jl:616` | `test_discrete.jl:228` (`occursin("key \`gnss\`", d.provenance)`) | |
| 9.1 (3022) | the per-component triples are the bound schedule, a printable artifact | short | `src/build.jl:777-788`, `src/sim.jl:34` | `test_discrete.jl:162` | plain data only; no `show`, no anchor or provenance column. See 4.6 |
| 9.1 (3027) | deployment validation is collected | short | `src/sim.jl:136-160`, `src/build.jl:718-774` | `test_discrete.jl:228` | three sequential barriers, and the middle one is fail-fast. See 4.5 |
| 9.1 (3030) | collected kind: a nonpositive `h` | accurate | `src/build.jl:722-723` | `test_discrete.jl:228` | thrown alone |
| 9.1 (3031) | collected kind: an `n < 1` | accurate | `src/build.jl:724-725` | `test_discrete.jl:228` | thrown alone |
| 9.1 (3032) | collected kind: a harmonic-grid violation | accurate | `src/build.jl:746-749` | `test_discrete.jl:228` | thrown alone |
| 9.1 (3033) | collected kind: a non-dividing anchor period or offset | accurate | `src/build.jl:760-773` | `test_discrete.jl:228` | genuinely collected |
| 9.1 (3034) | collected kind: `Δt_base` disagreeing with `n` | accurate | `src/build.jl:750-752` | `test_discrete.jl:228` | thrown alone |
| 9.1 (3035) | collected kind: an algorithm the stepper seam does not know | accurate | `src/sim.jl:137-138` | no test | collected with its keyword siblings |
| 9.1 (3036) | collected kind: a nonpositive `localization_tol` | accurate | `src/sim.jl:141-142` | no test | |
| 9.1 (3037) | collected kind: `localization_budget`/`firing_budget` not an integer ≥ 1 | accurate | `src/sim.jl:139-144` | no test | |
| 9.1 (3040) | event parameters take no part in the harmonic-grid check | accurate | `src/sim.jl:139-140` vs `src/build.jl:718` | no test | validated on their own terms |
| 9.2 (3046) | `build(world) → Build` is a standalone entry point | accurate | `src/build.jl:381` | `test_build.jl:54` | |
| 9.2 (3049) | two constructors: `Simulation(build::Build; …)` and `Simulation(world; …) = Simulation(build(world); …)` | accurate | `src/sim.jl:130`, `src/sim.jl:179-180` | `test_discrete.jl:228` | literally the spec's factorization |
| 9.2 (3056) | rationale for the factorization | n/a | — | — | rationale |
| 9.2 (3061) | deployment binding happens only at `Simulation` construction | accurate | `src/sim.jl:162` | `test_discrete.jl:228` | |
| 9.2 (3063) | the `Build` is immutable and may back any number of `Simulation`s | accurate | `src/build.jl:364-371`, `src/build.jl:873-880` | `test_discrete.jl:228` | each `compile` makes its own stores and buffers |
| 9.2 (3063) | …concurrently | short | `src/build.jl:429-434` | no test | the only mutable field is the activation cache, and its insertion has no guard. See 4.10 |
| 9.2 (3068) | the `Build` is inspectable printable data: wire list, face table, schedule, root inputs | short | `src/assembly.jl:504-514` | `test_discrete.jl:149` (reads `sim.build.flat.paths`) | data present, no `show` method anywhere. See 4.6 |
| 9.2 (3071) | the face table is two-sided: output faces with provenance, plus every input face resolved producer-ward | short | `src/assembly.jl:509-510`, `src/assembly.jl:657-673` | `test_assembly.jl:496` | both sides present and total; the output side carries no provenance column. See 4.7 |
| 9.2 (3078) | CI checks a model by calling `build`; `attach!` validates bindings against it | accurate | `src/build.jl:381`, `src/roster.jl`, `src/bindings.jl` | `test_bindings.jl`, `test_roster.jl` | §11's detail |
| 9.2 (3083) | the `Build` gains an anchor table: exact `(T, τ)` with the declaring scope's path and key | short | `src/assembly.jl:512-513` | `test_discrete.jl:228` (asserts `provenance`) | `anchors` + `aprov` hold the data; no table, no rendering |
| 9.2 (3086) | …and a component table of `(anchor, m, c)` triples with declaration provenance | short | `src/assembly.jl:511` | `test_discrete.jl:199` | triples present, **no provenance column**; the `Relative`/`Absolute` chain is not recorded |
| 9.2 (3088) | the base grid `A₀` takes an anchor-table row of its own with dashes | absent | — | — | `flat.anchors` holds anchors 1…K only |
| 9.2 (3095) | binding produces the bound schedule with anchor and provenance columns carried through | short | `src/build.jl:779-788` | `test_discrete.jl:162` | rows are `(path, D, Φ, Δt)` only |
| 9.2 (3101) | rate scopes appear in the bound schedule beside the discrete components with their own `(Dₛ, Φₛ)` | absent | `src/build.jl:779-787` | — | only `tiers[ci] === DISCRETE` gets a row; assemblies get none |
| 9.2 (3104) | the bound schedule's `show`-form is the hyperperiod chart over `k = 0 … lcm(Dᵢ) − 1`, with an absurd-hyperperiod guard | absent | — | `test_discrete.jl:178` reads cells instead | no `show` for the schedule, no chart, no guard |
| 9.2 (3108) | the worked example's numbers | accurate | `src/build.jl:776-786` | `test_discrete.jl:162` | the test asserts the spec's table verbatim |
| 9.2 (3126) | refusal and derivation share one substrate: coarsest admissible plus per-entry attribution | short | `src/build.jl:756`, `src/diagnostics.jl:806-807` | `test_discrete.jl:228` | only `gcd(pool)` is printed. See 4.4 |
| 9.2 (3131) | leave-one-out refinement factors `r_p`, every `r_p > 1` listed | absent | — | — | rejected-shape-free absence; D-187 ratifies the form. See 4.4 |
| 9.2 (3136) | prime attribution of `1/Δt_base`'s prime powers to pool entries | absent | — | — | See 4.4 |
| 9.2 (3140) | nearest non-refining alternative offsets when an offset drives | absent | — | — | See 4.4 |
| 9.2 (3144) | blame computed against the actual pool; no simple-fraction test (D-187) | accurate | `src/build.jl:728-729`, `src/build.jl:756` | `test_discrete.jl:228` | vacuously: no heuristic was introduced |
| 9.2 (3146) | the derivation path always prints the derived value with its drivers | absent | `src/build.jl:730-740` | `test_discrete.jl:270` (asserts the value, no output) | `bind_schedule` prints nothing on the derive path |
| 9.2 (3149) | the `GridUtilization` advisory reporting `min_i Dᵢ` with drivers | absent | — | — | no such kind in `src/diagnostics.jl` |
| 9.3 (3157) | the nominal activation probes every user function once, at the initial state, discarding results | accurate | `src/build.jl:114-131`, `src/build.jl:483-575`, `src/build.jl:615-640` | `test_build.jl:28`, `test_events.jl:72` | stages, `state_derivative`, `state_update`, guards, handlers, `state_projection` all probed |
| 9.3 (3163) | probes see only the initial state's branch; completeness is §9.5's backstop | short | as above | — | true of the code, but the backstop does not exist. See 4.11 |
| 9.3 (3167) | `x`/`s`/`m` come from `init_*` declarations | accurate | `src/build.jl:133-147`, `src/build.jl:447-449` | `test_declare.jl` (bundle law) | |
| 9.3 (3169) | the stage-1 hand-down carries the stage-1 probes' returns | accurate | `src/build.jl:131`, `src/build.jl:513-517` | `test_build.jl:44` | |
| 9.3 (3170) | an auto-published name is absent from the hand-down | n/a | — | — | vacuous: auto-published ports are not built (row at 2955) |
| 9.3 (3172) | wired inputs come from upstream products, the chain probed in topological order | accurate | `src/build.jl:1016-1035`, `src/build.jl:509` | `test_build.jl:241` (`rd/out === 6.0` from a real upstream) | |
| 9.3 (3176) | a stage returning something other than a `NamedTuple` fails here | accurate | `src/build.jl:122-126`, `src/build.jl:515-518` | no direct test | `ConformanceFailure(reason = :return_type)` |
| 9.3 (3177) | the dead-stage rule: a stage returning bare `(;)` is `DeadStage`, fail-fast | absent | — | — | probed: such a build succeeds. See 4.12 |
| 9.3 (3180) | `t` is probe-scoped `0.0` | accurate | `src/build.jl:144` | no test | `zero(T)` |
| 9.3 (3183) | `ws` comes from `init_workspace` at the probing scalar, before the Stratum B probes | accurate | `src/build.jl:453`, `src/build.jl:462-465` | no test | |
| 9.3 (3186) | root-input values synthesized via `probe_value(::Type)`: `Real` → `zero(T)` | accurate | `src/declare.jl:326` | `test_devices.jl`/`test_dataplane.jl` (root inputs hold 0.0) | |
| 9.3 (3188) | `Bool` → `false` | accurate | `src/declare.jl:327` | no test | |
| 9.3 (3188) | enums → first instance | absent | — | — | no `Enum` method; probed, an enum-typed root input is refused as leafless. See 4.13 |
| 9.3 (3189) | ultimate fallback `T()` | accurate | `src/declare.jl:329` | no test | plus an unspecced `StaticArray` method at `:328` |
| 9.3 (3191) | `probe_value` is overridable | accurate | `src/declare.jl:326-329` | no test | ordinary generic function |
| 9.3 (3195) | no method → didactic build error naming face and type and the two fixes | absent | — | — | probed: a bare `MethodError`. See 4.13 |
| 9.3 (3201) | synthesis never meets an abstract type | stand-in | `src/build.jl:294-296` | no test | not enforced; probed, `probe_value(Real)` returns `0::Int64` and the mismatch surfaces one step later. See 4.1 |
| 9.3 (3206) | rationale for accepting silly values | n/a | — | — | rationale |
| 9.3 (3207) | rejected alternatives (D-051) | n/a | — | — | rejected alternatives |
| 9.3 (3209) | probe values are strictly probe-scoped; never initial root-input values | accurate | `src/build.jl:909-918` (cells seeded, then overwritten at `init!`), `src/conditions.jl:486-497` | `test_discrete.jl:290` "boundary zero … publishes every output stage" | |
| 9.3 (3213) | discrete-tier probes supply a placeholder period `1.0` | accurate | `src/build.jl:121`, `src/build.jl:519` | no test | |
| 9.3 (3218) | the pre-write `UninitializedInputs` check on every complete-world application | accurate | `src/conditions.jl:486-497` | `test_conditions.jl`, `test_trim.jl` | §14.6's detail; present |
| 9.3 (3222) | stage code must be total over type-valid inputs | n/a | — | — | an obligation on the author, not the code |
| 9.3 (3231) | at build a totality failure is a `UserCodeFraming`-wrapped build failure | absent | — | — | probed: an `ErrorException` escapes `build` raw. See 4.14 |
| 9.3 (3233) | at runtime it is a `StepError` and the run ends `errored` | accurate | `src/sim.jl:1059-1067` | `test_failures.jl:32` | §13.4's; present |
| 9.3 (3236) | the three sanctioned spellings (`stop_on`, tests, constructor validation) | n/a | — | — | authoring guidance |
| 9.4 (3255) | producer-fed cells re-typed by evaluating the producer's declaration at `T` | accurate | `src/build.jl:34-39` | `test_build.jl:241` (`port(simd,"src",:val) isa D8`) | |
| 9.4 (3259) | root-input cells re-typed by evaluating the consuming entry at `T`, permissively | accurate | `src/build.jl:318-336` (`check` only at nominal) | `test_build.jl:90` "two consumers of one root input declare one concrete type" | |
| 9.4 (3263) | the state type by the walk over `init_x`, table and buffers re-laid-out | accurate | `src/build.jl:35`, `src/build.jl:456`, `src/build.jl:893` | `test_build.jl:241` | |
| 9.4 (3265) | workspace allocators re-invoked at `T`, not introduced | accurate | `src/build.jl:462-465` | no test | |
| 9.4 (3269) | the probe chain re-run | accurate | `src/build.jl:452-457` | `test_build.jl:241` | |
| 9.4 (3270) | structure and schedule are `T`-independent by construction | accurate | `src/build.jl:433`, `src/build.jl:454` | `test_build.jl:241` | `order` is passed in, never recomputed |
| 9.4 (3276) | each activation probes exactly its executable set: discrete stages, `state_update`, guards and handlers excluded at non-nominal | accurate | `src/build.jl:477-479`, `src/build.jl:487-495`, `src/build.jl:543`, `src/build.jl:615` | `test_build.jl:241`, `test_discrete.jl:73` | |
| 9.4 (3280) | continuous output stages and `state_derivative` are probed at every activation | accurate | `src/build.jl:509-521`, `src/build.jl:538-552` | `test_build.jl:241` | `state_projection` too, correctly |
| 9.4 (3286) | the global set-tracer is an activation like any other | absent | — | — | no tracer scalar in `src/`; §5.6's construct |
| 9.4 (3288) | the cycle classifier runs in Stratum B's failure path and is not an activation | absent | `src/build.jl:245-249` | — | See 4.9 |
| 9.4 (3291) | non-nominal activations run at first request, not at build | accurate | `src/build.jl:429-434` | `test_build.jl:241` (`activation(b,D8) === activation(b,D8)`) | |
| 9.4 (3295) | `build` succeeding does not certify linearizability; the pinned leaf detonates at the first `Dual` probe naming the offending leaf | accurate | `src/build.jl:192-194`, `src/diagnostics.jl:287-290` | `test_build.jl:265` (`PinnedGetsDual`) | the `_pin_hint` text is the spec's |
| 9.4 (3301) | `build(world; activations = (Float64, ProbeDual))` runs the exhaustive set | short | `src/build.jl:381`, `src/build.jl:389-391` | `test_build.jl:265` | the keyword exists; `ProbeDual` does not. See 4.15 |
| 9.4 (3301) | every component gets a `Dual` activation built in CI (D-166 policy) | absent | — | one fixture at `test_build.jl:267` | no suite-wide sweep; `test/utils.jl:3` defines a local `D8` |
| 9.4 (3302) | …"or a `check` entry" | absent | — | — | no such entry point |
| 9.4 (3309) | `const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}` is exported | absent | — | — | neither name exists in `src/`. See 4.15 |
| 9.4 (3316) | an activation is a pure function of build and concrete scalar; the cache is the `Build`'s, keyed by that type | accurate | `src/build.jl:369`, `src/build.jl:429-434` | `test_build.jl:241` | |
| 9.4 (3320) | buffers are never cached; one owner per buffer set | accurate | `src/build.jl:347-352` (layouts only), `src/build.jl:873-880` | `test_discrete.jl:228` (two sims, independent state) | `_activation_mismatch` at `src/build.jl:855-864` guards the pairing |
| 9.4 (3327) | nothing numerical is ever cached | short | `src/build.jl:347-352` | no test | `Activation` caches `stage1`/`products`, the probe's numerical returns; they seed cells (`src/build.jl:909-914`), by design (§10.5) |
| 9.4 (3334) | a different seeding width is a different scalar type and a separate entry | accurate | `src/build.jl:369` (`Dict{DataType,Any}`) | no test | |
| 9.4 (3337) | lazy materialization is torn-state-free; a guard around insertion | absent | `src/build.jl:431-433` | — | bare `get!`; See 4.10 |
| 9.5 (3344) | the probe's comparison is left permanently in place at the table write | absent | `src/executor.jl:145-149`, `src/store.jl:82-88` | — | **the whole always-on check is missing**. See 4.11, **rejected D-053** |
| 9.5 (3348) | the executor holds a complete expected return type per (component, stage) | absent | — | — | the entry holds an address group, not an expected type |
| 9.5 (3355) | auto-published names belong to no stage's expected type | n/a | — | — | vacuous (row at 2955) |
| 9.5 (3357) | canonicalizing type-level reorder `NamedTuple{names(Expected)}(y2)` | stand-in | `src/store.jl:82-88` | no test | `scatter_group!` fetches by name via `getfield`, so order-insensitivity holds; there is no type to canonicalize to |
| 9.5 (3358) | a single `y2 isa Expected` test at the write point | absent | — | — | See 4.11 |
| 9.5 (3361) | the test folds on type-stable code, survives on divergent code as a located error | absent | — | `test_executor.jl:22` proves zero allocation, which is vacuous without the check | See 4.11 |
| 9.5 (3367) | names are the pairing; a return in any field order conforms | accurate | `src/store.jl:82-88` | no test | by-name `getfield` |
| 9.5 (3382) | a key-set mismatch or per-field type mismatch is the error | absent | — | — | probed: extra key ignored, wrong type converted, missing key a bare `FieldError`. See 4.11 |
| 9.5 (3386) | exact type match at the nominal activation, no convert-on-write | stand-in, **rejected D-053** | `src/build.jl:179-190` (probe only), `src/leaves.jl:135-152` (runtime converts) | `test_build.jl:201` | exact at the probe; convert-on-write at every runtime table write. See 4.11 |
| 9.5 (3388) | a didactic error naming expected vs observed | accurate | `src/diagnostics.jl:671-673` | `test_build.jl:28` | at the probe; the "return `zero(x.ω)`" register is not reproduced |
| 9.5 (3393) | a declared-`T` leaf accepts the activation scalar or an embedded `Float64` | accurate | `src/build.jl:179-190`, `src/build.jl:196-206` | `test_build.jl:201` "embed-accept keeps the constant branch legal (D-166)" | |
| 9.5 (3396) | struct-valued ports use the cross-eltype constructor, a missing one failing loudly with both types named | short | `src/build.jl:203-206` (`reconstruct`) | no test | a missing constructor surfaces as a raw `MethodError` from the generated body |
| 9.5 (3399) | a declared-pinned leaf takes the exact check at every activation; an observed `Dual` is the forgotten-`T` error with a hint | accurate | `src/build.jl:181-185`, `src/build.jl:192-194` | `test_build.jl:265` | |
| 9.5 (3407) | rationale for the leniency (promotion is airtight; stop-gradient) | n/a | — | — | rationale |
| 9.5 (3424) | `state_derivative` checks against `X`'s own shape at `T`, field by field | short | `src/build.jl:1039-1060` | `test_build.jl:28` (`BadDerivative`) | the predicate is leaf **count**, not leaf type at `T`; probed, an `Int64` derivative leaf is accepted. See 4.16 |
| 9.5 (3429) | guards check against their probe-derived predicate form | accurate | `src/build.jl:629-635` | `test_events.jl:72` | |
| 9.5 (3430) | `state_update` checks against its leaf's `s` shape | accurate | `src/build.jl:1064-1076` | `test_build.jl:145` | exact `typeof` match, as §7.3 asks |
| 9.5 (3430) | handlers check against the §5.2 return law, key by key | accurate | `src/build.jl:649-691` | `test_events.jl:72` | |
| 9.5 (3431) | `state_projection` checks against `X`'s shape at `T`, complete | short | `src/build.jl:554-573`, `src/build.jl:585-611` | no test | complete field set enforced; per-field predicate is leaf count. See 4.16 |
| 9.5 (3437) | handler key set checked first, with did-you-mean against `{x, m}` narrowed to what exists | accurate | `src/build.jl:655-668` | `test_events.jl:72` (`d.stores == [:m]`) | |
| 9.5 (3442) | `x` must be complete; `m` may be partial (names-subset with matching types) | accurate | `src/build.jl:669-690` | `test_events.jl:72` | |
| 9.5 (3446) | an absent key is not an error | accurate | `src/build.jl:669-671` | `test_events.jl` (handlers writing only `m`) | |
| 9.5 (3450) | guards have two admissible forms; any other return is a build error naming both | accurate | `src/build.jl:629-635`, `src/diagnostics.jl:683-693` | `test_events.jl:72` (`GuardForm`, `observed === String`) | |
| 9.5 (3453) | guards run only at the nominal activation, so no parametrized-leaf case arises | accurate | `src/build.jl:615`, `src/build.jl:969-996` | `test_build.jl:241` | |
| 9.5 (3458) | failure payload: component path, function, field-level diff, simulation time | short | `src/diagnostics.jl:627-680` (build), `src/diagnostics.jl:178-200` (runtime) | `test_build.jl:28`, `test_failures.jl:136` | at build: path, function, per-field expected/observed, no `t` (none exists). At runtime the diff is absent because the check is |
| 9.5 (3460) | deliberately absent: the source branch | accurate | — | — | vacuously honoured |
| 9.5 (3461) | the failure is reproducible by replay; the error names `to_boundary` | accurate | `src/diagnostics.jl:178-200` | `test_failures.jl:251` "the error's pointer reproduces the failure on a fresh twin" | §13.4's; present |
| 9.6 (3467) | the C172 trim problem transfers; trim is a write→sweep→read loop on an activation, `Dual` by default | accurate | `src/trim.jl:384-475`, `src/trim.jl:420` | `test_trim.jl` | §14's detail |
| 9.6 (3474) | a derivative-free fallback runs the same loop on the nominal activation | absent | `src/trim.jl:158-164` (only `LevenbergMarquardt`) | — | the `solve` seam exists; no derivative-free backend ships. §14.7's detail |
| 9.6 (3480) | `assign!` inverts to a pure function returning a condition value the service writes | accurate | `src/conditions.jl`, `src/trim.jl:384-410` | `test_conditions.jl`, `test_trim.jl` | §14's |
| 9.6 (3488) | linearization is a `Dual` activation plus seeded sweeps over the canonical layout | absent | — | — | no linearization service in `src/`. §14.10's detail |
| 9.6 (3494) | the generic service loop replaces per-aircraft NLopt plumbing | accurate | `src/trim.jl:179-330`, `src/trim.jl:460-478` | `test_trim.jl` | |
| 9.6 (3496) | a failed trim leaves the simulation's stores untouched | accurate | `src/trim.jl` (D-213 two-half scratch world) | `test_trim.jl` | §14.8's |
| 9.7 (3502) | in the `Build` the schedule is plain printable data; at `Simulation` construction it compiles | accurate | `src/build.jl:364-371`, `src/build.jl:873-1013` | `test_continuous.jl:29` | "printable" unrealized (row at 3068) |
| 9.7 (3506) | the execution form is a concretely-typed tuple of entries over statically typed cell storage, walked unrolled | accurate | `src/executor.jl:412-448`, `src/executor.jl:398-408` | `test_executor.jl:22` "the chunk walk is allocation-free at any width" | |
| 9.7 (3511) | an entry carries code-selecting facts in type parameters, data in fields | accurate | `src/executor.jl:43-58`, `src/executor.jl:60-96` | `test_store.jl:125` | |
| 9.7 (3513) | gating compiles to `(idx − Φ) % D == 0` inside the boundary body; interior bodies hold no discrete entries | accurate | `src/executor.jl:357-364`, `src/executor.jl:441-447` | `test_discrete.jl:46` "the ZOH holds by compile-time absence", `test_discrete.jl:162` | |
| 9.7 (3516) | cells stored per element type, one contiguous block each; a cell address is a build-time offset carried in a field with the port type as parameter | accurate | `src/store.jl:11-31`, `src/build.jl:275-284` | `test_store.jl` | |
| 9.7 (3521) | gathers reconstruct and scatters flatten through the same leaf walk | accurate | `src/store.jl:41-68`, `src/leaves.jl:117-152` | `test_leaves.jl` | |
| 9.7 (3523) | two instances of one component type share an entry type and compile to one body | accurate | `src/executor.jl:39-41`, `src/build.jl:877-882` | `test_executor.jl:22` (six identical sub-models) | |
| 9.7 (3527) | D-162's measurement | n/a | — | — | prior art |
| 9.7 (3529) | phase bodies are the outer decomposition: stage-1 order-free, stage-2 the only ordered block, `state_derivative` and `state_update` order-free with disjoint writes | accurate | `src/build.jl:920-967`, `src/executor.jl:152-168` | `test_build.jl:44` | |
| 9.7 (3538) | guards and handlers are their own small callables inside the §10.6 iteration | accurate | `src/executor.jl:283-320` | `test_events.jl` | |
| 9.7 (3541) | each sweep block compiles in two arities off one entry list | accurate | `src/executor.jl:412-448` | `test_executor.jl:8` "the phase-body roster is fixed and total" | |
| 9.7 (3543) | zero-arg `sweep_1()`/`sweep_2()` are the interior variants over continuous entries only | accurate | `src/executor.jl:444-447` | `test_discrete.jl:162` (`isempty(walked(...,:interior))`) | |
| 9.7 (3548) | `sweep_1(tick)`/`sweep_2(tick)` gate discrete entries by `(idx − Φ) % D`, symmetric with `ticks(tick)` | accurate | `src/executor.jl:359-364` | `test_discrete.jl:337` | |
| 9.7 (3550) | `rhs` takes no index (D-147) | short | `src/build.jl:958-960` (all `rhs_gates` are `nothing`), `src/sim.jl:319-325` | `test_executor.jl:8` calls `b.rhs(0)` | `rhs` is a `PhaseBody` like the rest, so a one-arg form exists and is exercised; semantically inert |
| 9.7 (3552) | `t*`'s empty due set is arity selection, not an index trick | accurate | `src/executor.jl:405-411`, `src/executor.jl:441-447` | `test_discrete.jl:46` | |
| 9.7 (3555) | bodies communicate only through the stores and the table; no value crosses a seam | accurate | `src/executor.jl:145-168` | `test_executor.jl:22` | |
| 9.7 (3559) | fusion is an optimization the executor may take or decline | n/a | — | — | permission, not obligation |
| 9.7 (3562) | two doors recorded, not committed | n/a | — | — | explicitly not committed |
| 9.7 (3568) | chunking: a large block splits into chunks behind non-inlined statically typed barriers | accurate | `src/executor.jl:392-396`, `src/executor.jl:434-448` | `test_executor.jl:22` (`chunk_size = 1`, 18 chunks) | |
| 9.7 (3574) | chunk size is the implementation's only representation freedom | accurate | `src/build.jl:873` (`chunk_size = 16`), `src/sim.jl:135` | `test_executor.jl:22` | |
| 9.7 (3579) | measured compile-time anchors | n/a | — | — | measurements |
| 9.7 (3595) | mitigation 1: activations are lazy | accurate | `src/build.jl:429-434` | `test_build.jl:241` | |
| 9.7 (3596) | mitigation 2: non-nominal activations may compile at reduced optimizer level | absent | — | — | no per-module optimizer policy; arguably downstream's |
| 9.7 (3598) | mitigation 3: activations bake into package images via precompile workloads | n/a | — | — | an aircraft package's job; `src/` carries no precompile workload |
| 9.7 (3603) | views are rebuild-per-call, no framework hoisting | accurate | `src/executor.jl:100-138` | `test_executor.jl:22` (zero allocation) | |
| 9.7 (3611) | construction is type-opaque; the compiled tuple's only consumer is the walk | accurate | `src/executor.jl:434-448` | `test_executor.jl:22` | entries built into `Any[]` and splatted once |
| 9.7 (3618) | `phase_bodies(sim)` returns the nominal bodies as named callables over the simulation's own buffers | accurate | `src/sim.jl:316` | `test_continuous.jl:29` (`phase_bodies(sim) === ex.bodies`) | |
| 9.7 (3623) | the four blocks are `rhs`, `sweep_1`, `sweep_2`, `ticks` | accurate | `src/build.jl:1003-1006` | `test_executor.jl:8` (`keys(b) === (:sweep_1,:sweep_2,:rhs,:ticks)`) | |
| 9.7 (3628) | returned with them: per-event guards and handlers and per-component `state_projection` callables, keyed by the model's roster | absent | `src/sim.jl:316` | — | the accessor returns only the four bodies. See 4.17 |
| 9.7 (3630) | the four-body roster is fixed and total; empty bodies are legal no-ops | accurate | `src/executor.jl:421-431`, `src/build.jl:1002-1006` | `test_executor.jl:8` (`b.ticks() === nothing`) | |
| 9.7 (3639) | one promise: these are the bodies the loop runs, not re-derivations | accurate | `src/sim.jl:316` | `test_continuous.jl:29` | identity, not equality |
| 9.7 (3644) | CI is warm-then-assert over the roster, per-body, each arity in its own right, the boundary call at a due index | accurate | — | `test_executor.jl:8`, `test_executor.jl:22`, `test_discrete.jl:337` | `body(); body(0)` then two `@ballocated` assertions |
| 9.7 (3652) | publication is not a phase body | accurate | `src/build.jl:1002-1006` vs `src/dataplane.jl` | `test_dataplane.jl` | |
| 9.7 (3654) | invoking bodies in isolation leaves buffers valid but off-trajectory; re-run `init!` to continue | accurate | `src/executor.jl:145-168` | `test_executor.jl:8` (bodies called bare, then the sim is discarded) | documented in the docstring; nothing enforces it, and nothing should |

## 4. Deviations in detail

### 4.1 The bound check is an equality test, so a lawful abstract entry is refused

Spec, line 2902: "**The bound check** is the first type clause, and it applies
at nominal faces: the producer's declaration at `Float64` must be `<:` the entry
at `Float64`. Equality is the concrete degenerate case. Abstract-at-root is
detected here." Spec, line 3201: "Synthesis never meets an abstract type: root
inputs are concrete by the tight-bound rule ([§8.2]) … and abstract entries only
occur on component-fed inputs, which the probe sources from upstream products."

There is no subtype test in `src/`. The only wire-type check is `_accepts`
(`src/build.jl:179-190`), called from `_probe_input` (`src/build.jl:1029-1033`)
against the *value* the upstream probe produced:

```julia
function _accepts(::Type{P}, ::Type{V}, ::Type{T}) where {P,V,T}
    P === V && return true
    if P <: Real
        return V <: Real && P === T && (V === T || V === Float64)
    ...
```

For `P = Real` (an abstract entry) and `V = Float64` the second arm requires
`P === T`, i.e. `Real === Float64`, so it returns `false`. Probe
(`scratchpad/agentC/p1.jl`), a `Float64`-declaring producer wired into an entry
declared `Real`:

```
BuildError: WireTypeMismatch: `k`.i declared Real, fed from `s`.o::Float64
```

The spec makes this model lawful (`Float64 <: Real`), so a correct model is
refused. The same probe shows the root-input case: an abstract root input
reaches `probe_value(Real)`, which returns `0::Int64`, and the refusal reads

```
BuildError: WireTypeMismatch: `k`.i declared Real, fed from root input `i`::Int64
```

Abstract-at-root is thus "detected", but late, under the wrong kind, and with a
message that blames a synthesized `Int64` rather than naming the abstract
declaration as the fault. Since the tight-bound rule is §8.2's, the refusal is
arguably right in outcome for the root case and wrong for the component-fed case.

### 4.2 The walk-compatibility clause does not exist

Spec, line 2906: "**The walk-compatibility clause** is the second, and it
applies to continuous consumers only. It is decided by evaluating both
declarations at a marker scalar and comparing per leaf, and its diagnostic is
`WalkingFaceAtFrozenEntry`."

`WalkingFaceAtFrozenEntry` appears nowhere in `src/` or `test/`, and nothing
evaluates two declarations at a marker scalar. Probe
(`scratchpad/agentC/p4.jl`): a producer declaring `o = T` wired into a consumer
declaring `i = Float64` builds clean at nominal, and only a `Dual` activation
refuses it:

```
nominal build: ACCEPTED
D1 activation refused: BuildError: WireTypeMismatch: `k`.i declared Float64,
  fed from `s`.o::ForwardDiff.Dual{Tag, Float64, 1}
  — if this leaf participates in differentiation, declare it `T`
```

Two consequences. First, the model ships and only detonates when someone
linearizes, which is exactly the lurking-failure mode the Stratum A clause
exists to close. Second, the hint misdirects: it tells the author to declare the
*consumer's input entry* `T`, whereas §8.2 reads input entries permissively and
the real fix is on the producer or on the wire.

### 4.3 The closed leaf vocabulary is not checked on `init_x`

Spec, line 2896: "the closed leaf vocabulary ([§7.1]), checked on every `init_x`
because the walk in [§8.2] rests on it (`init_s` is exempt, pinning
wholesale)."

`IllegalPortType` is raised only from `place!` in `cell_layout`
(`src/build.jl:275-281`), over declared ports and root-input faces. `init_x` goes
straight into `retype_value` (`src/build.jl:35`), which calls
`reconstruct` (`src/leaves.jl:155-162`). Probe (`scratchpad/agentC/p3.jl`), a
component whose `init_x` is `(; z = "hello")`:

```
MethodError: no method matching String()
```

The generated reconstruction emits `String()` because `String` is neither a
`Real` nor a `StaticArray` and has no fields. The author gets a `MethodError`
naming a constructor they never wrote, with no path attribution and no mention
of the closed vocabulary.

### 4.4 Grid diagnostics stop at `gcd(pool)`

Spec, lines 3126–3153, and D-187 (ratified). Four attribution forms are
specified: the coarsest admissible `Δt_base` with the set `gcd(pool)/k`,
leave-one-out refinement factors `r_p = gcd(pool ∖ p)/gcd(pool)` with every
`r_p > 1` listed, prime attribution of `1/Δt_base`'s prime powers to the pool
entries supplying them, and the nearest non-refining alternative offsets when an
offset drives.

`bind_schedule` computes `adm = reduce(gcd, pool)` (`src/build.jl:756`) and
carries it on the `admissible` field of the anchor `DeploymentInvalid`s. The
rendering is one clause (`src/diagnostics.jl:806-807`):

```julia
_dep_admissible(d) = d.admissible === nothing ? "" :
                     " — an admissible Δt_base divides gcd(pool) = $(d.admissible)"
```

Nothing else exists. There is no `pool ∖ p` computation, no factorization, no
alternative-offset search. The derivation path (`src/build.jl:730-740`) computes
`gcd(pool)` and returns; it prints no info line and emits no advisory, so the
one place refinement happens silently stays silent. `GridUtilization` is not a
`Diagnostic` in `src/diagnostics.jl`. The consequence is that the diagnostic
that is meant to be a repair only says "divide this number", leaving the author
to find which of several anchors drove the grid.

### 4.5 Deployment validation collects in three groups, not one

Spec, line 3027: "Deployment validation is collected like its declarative
siblings ([§13.1]). Collected and reported as `DeploymentInvalid`", followed by
a list of eight conditions.

The eight are all implemented, but under three sequential barriers.
`Simulation` collects the keyword-range violations (method, budgets,
tolerance, and the non-§9.1 keywords) and throws at `src/sim.jl:160`. Only then
does `bind_schedule` run, and its first five checks — missing `h`, nonpositive
`h`, `n < 1`, an inexact `Δt_base`, a non-harmonic `Δt_base`, a `Δt_base`
disagreeing with `n` — each `throw` on the spot (`src/build.jl:719-752`). The
anchor loop that follows does collect (`src/build.jl:760-774`).

So a deployment with a bad `firing_budget` and a bad `h` reports only the
budget; one with a bad `h` and a non-dividing anchor reports only `h`. The test
at `test_discrete.jl:249-258` asserts `only(failure(f).diagnostics)` for each
case in isolation, which is consistent with fail-fast and does not detect it.

### 4.6 The `Build` and the bound schedule are data with no rendering

Spec, line 3068: the `Build` is "the inspectable derived contract … as plain
printable data". Line 3095: binding produces "the **bound schedule**, a named
printable artifact on the `Simulation`". Line 3104: "The bound schedule's
`show`-form is the **hyperperiod chart**".

There is no `Base.show` method for any build artifact in `src/`; the only two
`show` methods in the package are `showerror` for `BuildError` and `StepError`
(`src/diagnostics.jl:90`, `:178`). `sim.sched` is a
`Vector{@NamedTuple{path,D,Φ,Δt}}` (`src/sim.jl:34`) — no anchor column, no
provenance column, no `A₀` row, and no rows for rate scopes, since
`bind_schedule` pushes a row only where `b.tiers[ci] === DISCRETE`
(`src/build.jl:779-787`). The hyperperiod chart and its absurd-hyperperiod guard
are not built; the test that names the chart (`test_discrete.jl:178`) reads port
values off the cells instead.

### 4.7 The face table has no provenance column

Spec, line 3071: "**The face table is two-sided.** Beside each level's output
faces and their provenance it retains that level's *input* faces, each resolved
producer-ward…"

Both sides are built and the input side is total, which is the harder half:
`Flat.in_faces` and `Flat.out_faces` (`src/assembly.jl:509-510`), populated at
`src/assembly.jl:657-673`. But an entry is `(path, face) => (producer path,
port)`: the ultimate resolved endpoint only. The chain of intermediate faces the
signal routed through, which §9.1 line 2882 asks the face derivation to record
and which §9.2 calls "provenance", is discarded by `resolve_source`'s tail
recursion (`src/assembly.jl:444-448`).

### 4.8 Auto-published ports do not exist

Spec, line 2955: "[Ports] are classified over `output_types` alone: stage-1,
auto-published, and the stage-2 remainder ([§8.3])." Line 3355: "Auto-published
names belong to no stage's expected type; the framework writes those cells
itself."

`grep -rn "auto.publish" src/ test/` returns nothing. Classification is
two-way and comes from the probe returns, not from `output_types`: `stage1[ci]`
is `output_state`'s return (`src/build.jl:131`) and the stage-2 remainder is
`output_direct`'s (`src/build.jl:521`). The completeness check at
`src/build.jl:528-535` then requires every declared port to be produced by one
of the two stages, so a port naming a state field that no stage produces —
§5.3's auto-published case — is a `DeclaredNotProduced` build error rather than
a framework write. The construct is §8.3's, so the owning agent should confirm;
within §9 it means the three-way classification is a two-way one.

### 4.9 The cycle refusal names too much and does not classify

Spec, line 3288: "The cycle classifier ([§5.6]) is the other variant, the
schedule-free per-member local trace, which runs in Stratum B's failure path."

`schedule_stage2` runs Kahn's algorithm and, on failure, reports every
unscheduled component (`src/build.jl:245-249`):

```julia
if !isempty(remaining)
    cycle = sort!(collect(remaining))
    throw(BuildError(AlgebraicCycle(members = String[flat.paths[ci] for ci in cycle])))
end
```

`remaining` is the set of components never made ready, which includes everything
downstream of a cycle as well as the cycle itself, so a single loop feeding a
long chain names the whole chain. There is no SCC decomposition and no
per-member local trace. `AlgebraicCycle`'s payload is agent A's to judge; the
Stratum-B failure-path obligation is the row here.

### 4.10 Activation-cache insertion has no guard

Spec, line 3337: "**Lazy materialization is torn-state-free**, normatively:
concurrent first requests for the same activation must never expose partially
populated cache state. The mechanism is unspecified — a guard around insertion
suffices."

`activation` is a bare `get!` over a plain `Dict` (`src/build.jl:429-434`), with
no lock and no atomic. Its docstring says the guarantee "this single-threaded
implementation meets by having none", but §9.2 line 3063 promises a `Build` may
back many `Simulation`s *concurrently*, and §9.4 line 3305 recommends the
`activations` keyword precisely for the parallel-sweep register — where two
tasks calling `activation(b, T)` on a shared `Build` is the expected shape. A
concurrent `Dict` insertion can corrupt the dictionary, not merely duplicate
work.

### 4.11 The always-on conformance check is not built, and the runtime converts on write

Spec, line 3344 onward, and D-053 (ratified). "At the point where the [executor]
stores a stage return into the table, it holds the complete expected return type
at this [activation] … The executor canonicalizes the observed return to that
type's field order … and performs a single type test against that type
(conceptually `y2 isa Expected`)." D-053 explicitly *rejects* "Field-assignment
`convert` semantics".

The executor's write path is (`src/executor.jl:145-149`):

```julia
@inline function run!(e::StageEntry, store, xbuf, ẋbuf)
    e.cursor.comp = e.ci; e.cursor.fn = e.fname
    y = e.fn(e.comp, make_bundle(e, store, xbuf))
    scatter_group!(store, e.outs, y)
end
```

`scatter_group!` (`src/store.jl:82-88`) emits one `scatter!` per *address-group
name*, fetching the field with `getfield(y, name)`; `scatter!` flattens leaves
into a typed buffer with `buf[i] = v` (`src/leaves.jl:135-152`), which converts.
There is no expected type, no reorder, no `isa`.

Probe (`scratchpad/agentC/p2.jl`), three kinds of branch divergence past the
probe's branch, with the port declared `T`:

- return `1` (an `Int64`) where `Float64` is declared: accepted, cell reads
  `1.0`. This is the convert-on-write D-053 rejects, and it is exactly the
  "`Int` sloppiness passing at nominal but detonating under `Dual`" failure the
  decision names.
- return an extra field `bogus`: accepted silently, because the address group
  was built from the probe's key set and never looks at the extra name.
- omit a declared field `r`: raises, but as
  `FieldError: type NamedTuple has no field `r`` inside a `StepError`. The
  component path, function and time do arrive via §13.4's framing; the
  field-level diff the spec's payload calls for does not.

The zero-allocation assertions in `test_executor.jl` pass, but they are vacuous
with respect to §9.5: they measure a walk that carries no check to fold.

### 4.12 `DeadStage` is not built

Spec, line 3177: "The second is the dead-stage rule: a stage returning bare
`(;)` produces no [ports] at all, and is `DeadStage`, fail-fast."

No `DeadStage` kind exists in `src/diagnostics.jl` and nothing tests for an
empty return. `probe_stage1` guards only `has_stage` and `y isa NamedTuple`
(`src/build.jl:118-126`). Probe (`scratchpad/agentC/p2.jl`): a component whose
`output_state` returns `(;)` and whose `output_direct` produces the declared
port builds successfully. The stage becomes an entry writing nothing on every
sweep.

### 4.13 `probe_value` has no enum method and no missing-method refusal

Spec, line 3186: "framework methods for `Real` (`zero(T)`), `Bool` (`false`),
enums (first instance), ultimate fallback the zero-argument constructor `T()`".
Line 3195: "No method → build error, in the didactic register: it names the
[face] and the type, and asks for one of the two fixes". D-051 ratifies the
chain including the enum arm and the named refusal.

`src/declare.jl:326-329` defines four methods: `Real`, `Bool`, `StaticArray`
(unspecced, harmless) and the `P()` fallback. No `Enum` method. Probe
(`scratchpad/agentC/p1.jl`):

- a `NoDefault` struct with no zero-argument constructor produces
  `MethodError: no method matching NoDefault()` escaping `build` raw — no face
  name, no type name, no mention of `probe_value`.
- an enum-typed root input never reaches `probe_value` at all; `place!` refuses
  it first with `IllegalPortType: root input `i` declares Colour, which has no
  leaves`, because `leaf_types` returns empty for a non-`Real` fieldless type.
  Whether enums belong in §7.1's closed vocabulary is agent A's question; the
  §9.3 obligation is unmet either way.

### 4.14 A probe throw is not framed

Spec, line 3231: "at build it is a `UserCodeFraming`-wrapped build failure
([§13.1]) whose diagnostic points at code that is 'correct' on every trajectory
it has ever seen".

`UserCodeFraming` appears nowhere in `src/`. Probe
(`scratchpad/agentC/p3.jl`): a stage whose body is `error("boom from user
code")` yields, from `build`, a bare `ErrorException: boom from user code`. No
component path, no stage name, no indication that the value it choked on was
synthesized by the probe rather than produced by a trajectory. The runtime half
of the same sentence — `StepError` — is built and well tested
(`src/sim.jl:1059-1067`, `test_failures.jl:32`).

### 4.15 `ProbeDual` and the CI activation policy

Spec, line 3309: "[`ProbeDual`] is the framework's exported canonical probe
scalar — `const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}`". Line 3301:
"**every component gets a `Dual` activation built in CI** —
`build(world; activations = (Float64, ProbeDual))` (or a `check` entry)".

The `activations` keyword exists and works (`src/build.jl:381`, `:389-391`), and
`test_build.jl:265-270` exercises it on one fixture. Neither `ProbeDual` nor
`ProbeTag` exists in `src/`; the suite uses its own
`const D8 = ForwardDiff.Dual{Nothing,Float64,8}` (`test/utils.jl:3`). There is
no `check` entry point and no suite-wide sweep materializing a `Dual` activation
for every component, so the D-166 policy the spec calls "policy rather than
advice" is unbuilt.

### 4.16 The state-shape predicate is leaf count, not leaf type

Spec, line 3424: "`state_derivative` checks against `X`'s own shape at the
activation's `T` ([§7.1]: a scalar leaf expects a `T`, an `SArray` leaf the same
`SArray` at `T`)."

`_check_derivative` (`src/build.jl:1039-1060`) and `_check_state_write`
(`src/build.jl:585-611`) compare `nleaves(typeof(ẋ[k])) == nleaves(typeof(x[k]))`
per field, after an exact key-set check. Leaf count is not leaf type. Probe
(`scratchpad/agentC/p3.jl`), both accepted:

- `init_x = (; z = 0.0)` with `state_derivative` returning `(; z = 1)` — an
  `Int64` derivative leaf where a `T` leaf is declared;
- `init_x = (; z = SVector(0.0,0.0,0.0))` with a returned
  `SVector{3,Int64}`.

At nominal the `Int64` is converted on the way into `ẋbuf`, so the run is
numerically fine; the checked property is weaker than the stated one, and the
same weakness applies to `state_projection` and to a handler's `x` key, which
share `_check_state_write`. The nleaves predicate does catch the shape errors the
suite tests (`test_build.jl:33-35`, an `SVector{2}` field returned as a scalar).

### 4.17 `phase_bodies` returns four bodies and nothing else

Spec, line 3628: "Returned with them are the per-event guards and handlers and
the per-component `state_projection` callables, keyed by the model's own
roster."

`phase_bodies(sim) = sim.exec.bodies` (`src/sim.jl:316`), and `bodies` is the
four-entry NamedTuple built at `src/build.jl:1002-1006`. The guard, handler and
projection callables live on `Executor.events` as an `EventSet`
(`src/executor.jl:245-268`) and are reachable only through the private field, in
global-index order rather than keyed by the model's roster. A §7.5 measurement
consumer iterating `phase_bodies` therefore never measures a guard, a handler or
a projection.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 133 |
| short | 21 |
| stand-in | 5 |
| absent | 29 |
| n/a | 14 |
| **total** | **202** |

Markers: 2 rows carry **rejected D-053** (the always-on check's absence and the
runtime convert-on-write). No row is ratified by the log; D-051, D-053, D-166
and D-187 are all ratified in the shape the spec states, so the corresponding
gaps stand unsettled.

## 6. Friction

- **The §9.5 boundary is hard to score.** The section states one mechanism (the
  baked table-write test) and then, under "Uniform across all probed
  functions", a list of per-function predicates. The predicates are built, at
  the probe; the mechanism is not. I gave the mechanism its own rows and the
  predicates theirs, but a reader tallying "§9.5" as a unit will get a very
  different impression depending on which half they count.
- **Two readings of line 2955.** "Ports are classified over `output_types`
  alone" and line 2865's "stage membership is derived by probing the stage-1
  functions" pull in opposite directions: the first says the classification is a
  declaration read, the second says it is a probe product. The code takes the
  second. I scored it accurate on that basis and short only for the missing
  auto-published class.
- **`AlgebraicCycle`'s payload straddles the slice boundary.** §9.4 line 3288
  places the cycle classifier in Stratum B's failure path, which is mine; §5.6
  owns what the classifier is, which is agent A's. I reported the Stratum-B
  obligation and left the payload to A, but the two reports may collide here.
- **`test_executor.jl`'s allocation assertions promise more than they check.**
  They are titled after §9.7 and are correct for it, but a reader could take
  them as evidence that §9.5's fold-away check exists and folds. It does not
  exist.
- **The scratchpad directory is shared.** My first probe file was overwritten by
  another agent between the write and the run. I moved to a `agentC/`
  subdirectory; a future brief should assign one per agent.
- **Deciding "printable".** Several §9.2 artifacts are specified as "plain
  printable data". I read that as requiring a rendering, since §9.2 names a
  `show`-form for the bound schedule and a printed face-provenance table. If the
  intended reading is only "inspectable plain data", four of my `short` rows
  become accurate.
