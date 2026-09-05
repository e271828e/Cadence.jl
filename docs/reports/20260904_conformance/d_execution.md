# Agent D — §10 time and execution

## 1. Header

- **Agent**: D
- **Slice**: §10 time and execution (§10.1–§10.7)
- **Spec lines**: 3680–4714 of `docs/design/spec.md`
- **Tip**: `70672d1`, Julia 1.12.7
- **Probes run**: yes, one. A four-case constructor probe of the float
  refusals on `Period`, `Hz` and `Absolute` (§10.5, line 4262), run in the
  foreground from the repository root. Reported in 4.3.
- **Forbidden files**: none opened. I read `docs/design/spec.md` 3680–4714,
  `src/` and `test/` freely, the file table in `docs/design/implementation.md`
  ("What is real here", lines 11–56, and the authoring caveats that follow it
  on the same screen), and the `D-017`, `D-018`, `D-021`, `D-133` entries in
  `docs/design/decisions.md`. I did not open `pending.md`, `briefs/`, the
  top-level `reports/`, or any other report in `docs/reports/`.

## 2. Summary

§10 is the best-built chapter I could have drawn, with one hole in it the size
of a whole section. §10.2 through §10.6 are implemented closely, in the spec's
own vocabulary, with the source comments naming the section and the decision
they answer to, and with a test file per property. The stepper seam, the
localization loop, the multi-rate gate and the budgeted event iteration all
match claim by claim, down to details a looser implementation would have
skipped: the θ = 0 validation preceding the interpolant so an epoch-caused
edge never pays for one, the eligible-but-blocked event whose last-observed
sample is deliberately *not* overwritten, boundary zero's wide gate spelled as
a marker type rather than a sentinel index so the measured hot path keeps its
shape, and the `Establish` / `Int` / `Nothing` triple that gives the three
kinds of boundary their three due sets by arity selection alone.

**§10.7 real-time pacing is not built at all.** There is no pacer, no `p`, no
`margin`, no wall-clock map, no debt, no forgiveness, no overrun accounting and
no wait statistics in the published `FrameworkStatus`. `grep` over `src/` finds
exactly two `time()` calls, both in the shutdown join and the heartbeat, and
no `sleep` anywhere. The loop's only concession to co-resident tasks is a bare
`yield()` per frame when the roster is non-empty (`sim.jl:1030`). Two files
say so in their own headers (`dataplane.jl:8`, `devices.jl:6`), so the absence
is deliberate and recorded, but it is an absence: 13 of my 14 §10.7 rows are
`absent`, and the two claims §10.1 and §10.4 make about pacing — that all six
loop activities are framework code, and that pacer deadlines are one of three
things keyed to the frame — are `short` because of it.

Everything else is small. The three deviations worth a reader's time are the
pacer, §10.1's "all six activities" rule which cannot hold while one of the six
does not exist, and the convergence law, where the code stops on
`localization_tol · h′` against the *segment* rather than D-133's
`localization_tol · h` against the frame — tighter than promised on a remainder
step, never looser, but not the stated law. Nothing I found produces a wrong
trajectory.

Test coverage over the built part is unusually dense. `test_localization.jl`
alone asserts t\* accuracy against the analytic crossing, the O(h⁴) interpolant
order, the epoch-caused discard, the `t* = tₙ₊₁` degeneracy, multi-crossing
ordering, budget degradation with the diagnostic payload read back off the
loop's own cell, the gate idiom, tick suppression at t\*, keyword validation
and a zero-allocation gate. The rows below that say "no test" are mostly
structural claims with no observable of their own.

## 3. Findings table

### §10.1 Loop ownership (3682–3698)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.1:3689 | all six loop activities are framework code, unconditionally | short | `sim.jl:1023–1063` | `test_continuous.jl:4` | five of six built; pacing has no code. See 4.1 |
| 10.1:3697 | `OrdinaryDiffEq` dropped as a dependency | accurate | `Project.toml` deps | no test | deps are ForwardDiff, LinearAlgebra, StaticArrays |
| 10.1:3692 | why (D-017 rationale, `CallbackSet` rejection) | n/a | — | — | rationale |

### §10.2 The stepper seam (3700–3778)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.2:3709 | seam clause 1: advance by arbitrary `h` | accurate | `stepper.jl:49`, `stepper.jl:85` | `test_stepper.jl:20` | `step!(m, sim, h)` |
| 10.2:3714 | seam clause 2: dense output on demand over the last completed step, constructed lazily | accurate | `stepper.jl:122–133`, called at `localization.jl:142` | `test_stepper.jl:44` | built only past a validated trigger |
| 10.2:3717 | seam clause 3: one-step methods only | accurate | `stepper.jl:40–101` | no test | both backends are one-step |
| 10.2:3722 | a model with no continuous state is legal | accurate | `sim.jl:1039` (`isempty(xbuf)`) | `test_discrete.jl:11` | discrete-only fixtures run |
| 10.2:3726 | the seam is never entered empty; no backend faces `N = 0` | accurate | `sim.jl:1039` | no test | framework-side short-circuit |
| 10.2:3733 | boundary machinery (sweeps, events, ticks) runs unchanged with an empty `x` | accurate | `sim.jl:1030–1040` | `test_discrete.jl:11` | |
| 10.2:3740 | first cut ships in-house fixed-step RK4 and Heun over the flat buffer | accurate | `stepper.jl:40–101` | `test_stepper.jl:20` | |
| 10.2:3741 | both are zero-allocation | accurate | `stepper.jl:63`, `stepper.jl:95` | `test_continuous.jl:42`, `test_stepper.jl:83` | `@ballocated == 0` gates |
| 10.2:3742 | both are `T`-generic | accurate | `stepper.jl:40`, `stepper.jl:78` | `test_stepper.jl:96`, `test_continuous.jl:50` | |
| 10.2:3746 | `RK4` is the default method | accurate | `sim.jl:130` (`method = RK4`) | `test_stepper.jl:7` | |
| 10.2:3746 | `h` has no default and is required of the caller | accurate | `build.jl:719–720` | `test_stepper.jl:7` | `DeploymentInvalid(:h, :missing)` |
| 10.2:3749 | an `OrdinaryDiffEq` stepper is not built until an offline study demands it | n/a | — | — | guarded addition, correctly absent |
| 10.2:3753 | why fixed-step low-order suffices (three numbered arguments) | n/a | — | — | domain rationale |

### §10.3 Signal-table consistency (3780–3786)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.3:3781 | during a step the signal table is integrator scratch | accurate | `sim.jl:326–332` (`evaluate!` sweeps at stage states) | `test_discrete.jl:46` | |
| 10.3:3783 | the boundary sweep restores consistency at each accepted boundary | accurate | `sim.jl:432–433` (round 1 of `event_phase!`) | `test_events.jl:247` | |
| 10.3:3785 | external readers observe the table only at step boundaries | accurate | `sim.jl:1426–1432` (`publish!` after the sequence) | `test_dataplane.jl` snapshot tests | binding rule |

### §10.4 Localization mechanics (3788–4113)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.4:3803 | a frame is the grid step `[tₙ, tₙ₊₁]`; drain, pacer deadlines and tick eligibility key to it | short | `sim.jl:1035` (drain), `sim.jl:1042` (tick gate) | `test_localization.jl:162` | two of three keyed things exist; no pacer deadline. See 4.1 |
| 10.4:3808 | a boundary is a published consistency point | accurate | `sim.jl:1426` | — | |
| 10.4:3812 | every grid point is a boundary; `t*` and boundary zero are boundaries that are not frame tops | accurate | `localization.jl:144–145`, `sim.jl:1042–1043`, `sim.jl:949` | `test_localization.jl:7` | |
| 10.4:3816 | the frame chain: integrate → arrival sweep → trigger → θ=0 → bracket → root-find → t\* → remainder | accurate | `localization.jl:41–157` | `test_localization.jl:7` | order matches line for line |
| 10.4:3820 | a `Bool` guard is boundary-detected, no root-finding | accurate | `build.jl:632`, `executor.jl:249` (`localized` mask) | `test_events.jl:108` | |
| 10.4:3820 | a nominal-scalar guard is localized | accurate | `build.jl:632–633` | `test_events.jl:108`, `test_localization.jl:135` | |
| 10.4:3830 | the build reads the policy off the probe; `StateEvent` carries no detection keyword | accurate | `declare.jl:173–180`, `build.jl:615–639` | `test_events.jl:108` | D-179 |
| 10.4:3837 | de-localizing is a one-line rewrite | n/a | — | — | authoring note |
| 10.4:3844 | boundary detection is exact for a guard reading only `u` and `m` | accurate | by construction: `sim.jl:1035` (drain at frame top only), `executor.jl:315` (`m` written by handlers alone) | `test_localization.jl:135` | no code site of its own |
| 10.4:3858 | the gate idiom `(gate) ? σ : -one(σ)` is the blessed spelling | n/a | — | `test_localization.jl:135` | authoring doctrine; the suite exercises it |
| 10.4:3869 | a localized event triggers on prior-not-holding at tₙ quiescence and holding at tₙ₊₁ | accurate | `localization.jl:64` | `test_localization.jl:7` | directional edge |
| 10.4:3875 | never a bare sign change; holding → not-holding neither fires nor localizes | accurate | `localization.jl:64` (`!es.prior[i] && es.σ1[i] ≥ 0`) | `test_events.jl:114` | |
| 10.4:3878 | the trigger check runs against the arrival sweep, before any due-gated boundary sweep | accurate | `localization.jl:55–58` (interior sweeps) | `test_localization.jl:162` | |
| 10.4:3907 | θ = 0 validation is the first act on trigger: write xₙ, one interior sweep, evaluate the guard | accurate | `localization.jl:92–97` | `test_localization.jl:48` | |
| 10.4:3910 | xₙ is already retained by the stepper for the interpolant | accurate | `stepper.jl:69`, `stepper.jl:101`, `localization.jl:44` | no test | `startpoint` |
| 10.4:3915 | σ₀ is the left bracket value the root-finder needs | accurate | `localization.jl:97`, `localization.jl:123` | `test_localization.jl:7` | |
| 10.4:3917 | σ₀ discriminates the edge's cause via the input epoch | accurate | `localization.jl:99–106` | `test_localization.jl:48` | |
| 10.4:3934 | σ₀ not-holding ⇒ trajectory-caused: pay ẋₙ₊₁, build the interpolant, root-find | accurate | `localization.jl:108–124` | `test_localization.jl:7` | |
| 10.4:3937 | σ₀ holding ⇒ epoch-caused: no in-frame crossing exists | accurate | `localization.jl:100` | `test_localization.jl:48` | |
| 10.4:3938 | an epoch-caused edge is discarded and fires inside tₙ₊₁'s ordinary iteration | accurate | `localization.jl:103–106` | `test_localization.jl:48` | fall-through is the action |
| 10.4:3942 | that path costs one interior sweep, never ẋₙ₊₁ and never an interpolant | accurate | `localization.jl:92–106` | `test_localization.jl:196` | ordering makes it true |
| 10.4:3943 | it consumes no `localization_budget` | accurate | `localization.jl:103–106` (returns before `count += 1`) | no test | |
| 10.4:3944 | it warns nothing | accurate | `localization.jl:103–106` | `test_localization.jl:48` | no `_report!` on the path |
| 10.4:3949 | the interpolant is the lazy cubic Hermite over (xₙ, ẋₙ, xₙ₊₁, ẋₙ₊₁), θ ∈ [0,1] | accurate | `stepper.jl:122–133` | `test_localization.jl:35` | |
| 10.4:3952 | ẋₙ is the step's first stage; ẋₙ₊₁ costs one sweep, paid only on a validated trigger | accurate | `stepper.jl:69` (`k₁`), `localization.jl:110–114` | `test_localization.jl:196` | |
| 10.4:3955 | uniform accuracy O(h⁴) | n/a | `stepper.jl:117` documents it | `test_localization.jl:35` | numerical property, asserted anyway |
| 10.4:3958 | a trial evaluation writes x̂(θ) and runs the interior sweep; one per trial | accurate | `localization.jl:166–172` | `test_localization.jl:162` | |
| 10.4:3961 | discrete cells hold their tick values through localization | accurate | `localization.jl:169` (zero-arg sweeps) | `test_localization.jl:162` | |
| 10.4:3966 | root-finding is bracketed and derivative-free (ITP, Brent or bisection) | accurate | `localization.jl:185–212` | `test_localization.jl:7` | ITP, D-018 |
| 10.4:3971 | convergence at bracket width below `localization_tol · h` | accurate | `localization.jl:195` | `test_localization.jl:7` | relative to the *segment* h′, not the frame h. See 4.2 |
| 10.4:3973 | `localization_tol` is a `Simulation` keyword defaulting to `1e-6` | accurate | `sim.jl:131` | `test_localization.jl:176` | |
| 10.4:3979 | post-event: boundary sequence at t\* → interpolant invalidated → resume from t\* → re-check guards | accurate | `localization.jl:142–157` then the loop's next turn | `test_localization.jl:76` | |
| 10.4:3984 | the re-check runs under the per-frame localization budget with a chattering diagnostic | accurate | `localization.jl:72–82` | `test_localization.jl:116` | |
| 10.4:3986 | multiple events in one step fire at the earliest t\*; ties fire together in declaration order | accurate | `localization.jl:120–124` (`min`), `sim.jl:431–474` | `test_localization.jl:76` | |
| 10.4:3988 | later crossings re-localize on the remainder | accurate | `localization.jl:47–50` (loop turn) | `test_localization.jl:76` | |
| 10.4:3990 | an even number of in-step crossings is a shared blind spot | n/a | — | — | documented limitation |
| 10.4:3997 | the root-finder returns the holding endpoint of its final bracket | accurate | `localization.jl:211` (`hi`) | `test_localization.jl:7` | |
| 10.4:4000 | `t* = tₙ` is structurally impossible, not clamped away | accurate | `localization.jl:187`, `localization.jl:204` (θ strictly inside) | no test | `hi` is always an observation |
| 10.4:4012 | the guard observably holds at t\*, so the post-fire prior records an observation | accurate | `localization.jl:208` | `test_localization.jl:7` | |
| 10.4:4015 | `t* = tₙ₊₁` degenerates to the grid boundary: one boundary, no zero-length remainder | accurate | `localization.jl:125–131` | `test_localization.jl:63` | |
| 10.4:4021 | grid times are indexed, never accumulated: `tₖ = t₀ + k·h` | accurate | `localization.jl:14`, `localization.jl:31` | `test_continuous.jl:4` (bitwise stamps) | |
| 10.4:4026 | the remainder step targets the grid point with `h′` derived at use | accurate | `localization.jl:48–50` | `test_localization.jl:76` | |
| 10.4:4031 | at t\* the full §10.6 event phase runs, firing budget scoped to that boundary | accurate | `localization.jl:144` → `sim.jl:363`, `sim.jl:436–437` (`count` reset per call) | `test_localization.jl:7` | |
| 10.4:4034 | the settled state is published: snapshot, boundary-counter increment, `stop_on` check | accurate | `localization.jl:145`, `sim.jl:1426–1439`, `localization.jl:151` | `test_localization.jl:23` | |
| 10.4:4036 | a crash localized at t\* ends the run from that snapshot | accurate | `localization.jl:151–155`, `sim.jl:1044–1046` | `test_failures.jl` / `test_lifecycle.jl` stop paths | via `pol.hit` |
| 10.4:4038 | ticks are never due at t\* | accurate | `sim.jl:362–372` (`event_phase!(sim, nothing)`, no `ticks` call) | `test_localization.jl:162` | |
| 10.4:4041 | staged inputs are not drained at t\* | accurate | `sim.jl:1035` (drain at frame top only) | no test | |
| 10.4:4044 | the t\* publication is not separately paced | absent | — | — | vacuous: no pacer exists. See 4.1 |
| 10.4:4049 | boundaries are indexed by a monotonic counter with recorded `t` | accurate | `sim.jl:1427` (`Snapshot(t, step, counter, …)`), `sim.jl:1435` | `test_dataplane.jl` | |
| 10.4:4051 | the trace stays frame-indexed; t\* boundaries consume no inputs | accurate | `trace.jl` records keyed by drain; `sim.jl:1035` | `test_trace.jl` | |
| 10.4:4055 | guard trial evaluations run against the raw interpolated state | accurate | `localization.jl:166–172` (no projection) | no test | |
| 10.4:4056 | projection runs at the t\* boundary and the iteration's edge checks read the projected state | accurate | `sim.jl:369–370` | `test_events.jl:247` | |
| 10.4:4063 | if projection moves the state back across a guard the event does not fire; one extra boundary published | accurate | `sim.jl:369–371` (project then guards) | no test | |
| 10.4:4069 | `localization_budget` is an integer count of localizations per frame, default 8 | accurate | `sim.jl:132`, `localization.jl:45`, `localization.jl:72` | `test_localization.jl:116` | |
| 10.4:4077 | on exhaustion localization stops for the rest of the frame; the remainder step completes | accurate | `localization.jl:72–82` (return after the segment `step!`) | `test_localization.jl:116` | |
| 10.4:4080 | further crossings fire in the next boundary's ordinary iteration | accurate | `localization.jl:81` then `sim.jl:1042` | `test_localization.jl:116` | |
| 10.4:4081 | a `ChatteringBudget` warning naming the chattering event and the localization count | accurate | `localization.jl:74–80`, `dataplane.jl:84–90` | `test_localization.jl:116` | path, event, t, budget, count |
| 10.4:4084 | the degradation is a function of the trajectory alone, never wall clock | accurate | `localization.jl:72` (`count` only) | no test | |
| 10.4:4086 | it is not a `StepError` | accurate | `localization.jl:77` (`_report!`, no throw) | `test_localization.jl:116` | |
| 10.4:4088 | both budgets degrade loudly under a warning naming the offending event | accurate | `localization.jl:74–80`, `sim.jl:447–453` | `test_localization.jl:116`, `test_events.jl:205` | |
| 10.4:4098 | both constants are `Simulation` keywords beside `h`, `n` and the algorithm | accurate | `sim.jl:130–132` | `test_localization.jl:176` | |
| 10.4:4099 | validated with their siblings: positive tolerance, integer budget ≥ 1, collected into `DeploymentInvalid` | accurate | `sim.jl:140–145`, `sim.jl:155` | `test_localization.jl:176` | collecting, one `BuildError` |
| 10.4:4101 | `firing_budget` stands beside them in every such list | accurate | `sim.jl:138–139`, `trace.jl:43–45`, `trace.jl:352–357` | `test_events.jl:205`, `test_trace.jl:209` | |
| 10.4:4103 | both are grid-independent and enter no harmonic-grid check | accurate | `build.jl:718–786` (absent from `bind_schedule`) | no test | |
| 10.4:4106 | both ride the trace header's deployment block | accurate | `trace.jl:43–45`, `trace.jl:287–292` | `test_trace.jl:75` | |
| 10.4:4107 | both join the set replay compares up front | accurate | `trace.jl:352–360` | `test_trace.jl:209` | |

### §10.5 Multi-rate tick scheduling (4115–4415)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.5:4127 | every discrete period is an integer multiple of `Δt_base`, and `Δt_base = n·h`, `n ≥ 1` | accurate | `build.jl:748–751`, `build.jl:759–770` | `test_discrete.jl:228` | exact `Rational` arithmetic |
| 10.5:4131 | ticks land on step boundaries | accurate | `sim.jl:1042` (`k % sim.n == 0`) | `test_discrete.jl:308` | |
| 10.5:4134 | one `(D, Φ)` pair per discrete component, however deeply nested the declaration | accurate | `build.jl:772–786` | `test_discrete.jl:199` | |
| 10.5:4139 | the pair is kept in the canonical residue `0 ≤ Φ < D` | accurate | `build.jl:773–780`, `assembly.jl:537–544` | `test_discrete.jl:199` | |
| 10.5:4141 | the gate: due when `(idx − Φ) % D == 0` | accurate | `executor.jl:360–367` | `test_discrete.jl:288` | truncated `rem` is safe under the residue |
| 10.5:4149 | a discrete component's `output_state`/`output_direct` run only at its own ticks; cells hold between | accurate | `build.jl:934`, `build.jl:946`, `executor.jl:365` | `test_discrete.jl:46` | |
| 10.5:4156 | two statically distinct sweep variants compiled from one entry list | accurate | `executor.jl:415–447` | `test_discrete.jl:46` | D-147 |
| 10.5:4160 | the interior sweep walks continuous entries only; RK stages and trial evaluations run it | accurate | `executor.jl:445`, `sim.jl:328–329`, `localization.jl:169` | `test_discrete.jl:46` | |
| 10.5:4164 | the ZOH holds mid-step by construction, with no gating test on the hot path | accurate | `executor.jl:420`, `executor.jl:445` | `test_discrete.jl:337` | |
| 10.5:4167 | the boundary sweep walks the full list with discrete entries gated against the tick index | accurate | `executor.jl:421`, `executor.jl:446–447` | `test_discrete.jl:288` | |
| 10.5:4170 | different boundaries run different subsets of the schedule | accurate | `executor.jl:360–367` | `test_discrete.jl:178` | |
| 10.5:4172 | the split applies to both sweep blocks | accurate | `build.jl:934` and `build.jl:946` both push `gate(ci)` | `test_discrete.jl:46` | |
| 10.5:4174 | interior bodies take no arguments, boundary bodies take the tick index | accurate | `executor.jl:420–421` | `test_discrete.jl:337` | |
| 10.5:4178 | the due set is computed once for the boundary and reused by every re-sweep | accurate | `sim.jl:431–474` (one `tick` value for the whole iteration) | `test_events.jl:186` | the modulo is re-evaluated, the index is not |
| 10.5:4187 | at a frame top the due set is the gate's image of the frame index | accurate | `sim.jl:1042` | `test_discrete.jl:308` | see friction 6.2 for `n > 1` |
| 10.5:4188 | at a t\* boundary the due set is empty | accurate | `sim.jl:362–372`, `sim.jl:405–406` | `test_localization.jl:162` | arity selection, not a sentinel index |
| 10.5:4192 | at boundary zero it is everything with `Φ = 0`, falling out of the ordinary gate | accurate | `sim.jl:392–399`, `executor.jl:371–372` | `test_discrete.jl:290` | |
| 10.5:4197 | dueness at boundary zero governs `state_update` alone; output stages publish due or not | accurate | `sim.jl:397–398` (`ESTABLISH` for sweeps, `0` for ticks) | `test_discrete.jl:290` | D-205 |
| 10.5:4200 | an offset component's first tick is at `Φ·Δt_base`; until then its cells hold the boundary-zero publication | accurate | `executor.jl:339–352`, `sim.jl:397–398` | `test_discrete.jl:290` | |
| 10.5:4210 | all due components run their output stages in topological order within the sweep | accurate | `build.jl:938` (`for ci in b.order`) | `test_discrete.jl:308` | |
| 10.5:4211 | all due `state_update` calls run after it, in any order, each writing only its own `s` | accurate | `sim.jl:356–357`, `executor.jl:160–164` | `test_events.jl:186` | |
| 10.5:4216 | coincidence and stagger as modeling choices | n/a | — | `test_discrete.jl:178` | rationale; the chart is asserted anyway |
| 10.5:4236 | there are no atomic assemblies and no opt-in variant | accurate | absence: no such construct in `assembly.jl` | — | D-019 |
| 10.5:4236 | a rate scope is an assembly's `sample_times` against the enclosing scope | accurate | `declare.jl:171`, `assembly.jl:592–617` | `test_discrete.jl:199` | |
| 10.5:4240 | why no coarsening is needed | n/a | — | — | rationale |
| 10.5:4246 | a discrete component or sub-assembly is scheduled by a `sample_times` entry in its enclosing assembly | accurate | `assembly.jl:696–706` | `test_discrete.jl:199` | |
| 10.5:4252 | `Relative(K, Φ=0)`: every K-th scope tick from its Φ-th; `K ≥ 1`, `0 ≤ Φ < K` | accurate | `declare.jl:143–147`, `assembly.jl:565–567` | `test_discrete.jl:105` | |
| 10.5:4253 | `Absolute(q, τ=0)`: `t = τ + k·period(q)`; `T > 0`, `0 ≤ τ < T` | accurate | `declare.jl:154–162`, `assembly.jl:568–569` | `test_discrete.jl:105` | |
| 10.5:4255 | `K = 1` admits no stagger | accurate | falls out of `0 ≤ φ < K` at `assembly.jl:566` | `test_discrete.jl:105` | |
| 10.5:4259 | `q` is `Period(1//50)` or `Hz(50)`, normalized to the exact rational at construction | accurate | `declare.jl:125–136` | `test_discrete.jl:162` | |
| 10.5:4261 | every period and offset is an exact `Rational{Int}` | accurate | `declare.jl:126`, `declare.jl:157`, `build.jl:697–706` | `test_discrete.jl:228` | |
| 10.5:4262 | a float argument throws the teaching error naming the exact spelling | accurate | `declare.jl:129–130`, `declare.jl:133–134`, `declare.jl:158–159` | `test_declare.jl` / `test_discrete.jl:105` | probe in 4.3 |
| 10.5:4265 | the wrappers are the whole vocabulary; a bare integer or bare quantity is a declaration error | accurate | `assembly.jl:558–561` (`:value_vocabulary`) | `test_discrete.jl:111` | |
| 10.5:4267 | an unlisted discrete child defaults to `Relative(1)` | accurate | `assembly.jl:597–610` (returns the enclosing scope) | `test_discrete.jl:199` | implemented by nothing |
| 10.5:4271 | validation belongs to Stratum A and is collected with path attribution | accurate | `assembly.jl:551–575`, `assembly.jl:698` | `test_discrete.jl:105` | |
| 10.5:4274 | it covers `K ≥ 1`, `0 ≤ Φ < K`, `T > 0`, `0 ≤ τ < T` and keys naming discrete or scope children | accurate | `assembly.jl:565–573`, `assembly.jl:702–706` | `test_discrete.jl:105`, `test_discrete.jl:140` | `:continuous_child` covers the last clause |
| 10.5:4275 | the constructors are plain data carriers with no checks of their own | accurate | `declare.jl:143–162` | no test | D-185; the float refusal is the spec's own carve-out |
| 10.5:4279 | `Relative(K, φ)` under `(D_s, Φ_s)` compiles to `D = K·D_s`, `Φ = Φ_s + φ·D_s` | accurate | `assembly.jl:610–612`, `build.jl:773` | `test_discrete.jl:199` | |
| 10.5:4284 | composition preserves the canonical residue | accurate | `assembly.jl:543–544`, `build.jl:772–773` | `test_discrete.jl:199` | |
| 10.5:4286 | all scoping compiles away to one `(D, Φ)` per discrete component | accurate | `build.jl:772–786` | `test_discrete.jl:162` | |
| 10.5:4288 | the interior sweep still holds no discrete entries to gate | accurate | `executor.jl:445` | `test_discrete.jl:46` | |
| 10.5:4290 | why relative is the default register; the fastest-member convention | n/a | — | — | rationale |
| 10.5:4296 | two structural properties confine grid cost to the other register | n/a | — | — | rationale |
| 10.5:4304 | an `Absolute` entry may appear in any scope's `sample_times`, not only the root's | accurate | `assembly.jl:613–616` | `test_discrete.jl:199` | |
| 10.5:4306 | the `(T, τ)` pair is an anchor; the child is severed from the enclosing scope's grid | accurate | `assembly.jl:613–616` (re-seeds at `(k, 1, 0)`) | `test_discrete.jl:199` | |
| 10.5:4312 | an anchored child may tick faster than its scope | accurate | `assembly.jl:616` (no relation to the scope triple) | `test_discrete.jl:199` | |
| 10.5:4314 | the fastest-member convention counts relative members only | n/a | — | — | convention |
| 10.5:4316 | phase relationships with anchored siblings are deployment-emergent | n/a | — | `test_discrete.jl:178` | consequence |
| 10.5:4321 | relative children of an anchored subtree compose against the anchor; a nested anchor severs again | accurate | `assembly.jl:610–616` | `test_discrete.jl:199` | |
| 10.5:4323 | absolute periods and nonzero offsets join the deployment-time constraint pool | accurate | `build.jl:727–728` | `test_discrete.jl:270` | |
| 10.5:4329 | the worked example compiles to the stated pairs and hyperperiod | n/a | — | `test_discrete.jl:162`, `test_discrete.jl:178` | worked example; asserted anyway |
| 10.5:4365 | mid-tree anchor doctrine; the framework cannot police the distinction | n/a | — | — | authoring doctrine |
| 10.5:4382 | the component type stays rate-agnostic and consumes the `Δt` of its bundle | accurate | `executor.jl:116`, `executor.jl:53` | `test_discrete.jl:308` | |
| 10.5:4390 | `Δt` arrives read-only as a field of every discrete-tier bundle: `output_state`, `output_direct`, `state_update` | accurate | `declare.jl:298` (`t === DISCRETE && push!(names, :Δt)`) | `test_declare.jl:45–48` | |
| 10.5:4393 | the field is absent from continuous bundles, so touching it there is a missing-field error | accurate | `declare.jl:298`, `executor.jl:105–120` | `test_declare.jl:38–41` | absent, never `nothing`-filled |
| 10.5:4395 | it must be readable in the stages, not just in `state_update` | accurate | `declare.jl:298` (unconditional on the tier) | `test_declare.jl:45–48` | |
| 10.5:4401 | a `comp.Δt` virtual property is impossible here | n/a | — | — | rationale |
| 10.5:4404 | author rule: never store `Δt` or a `Δt`-derived coefficient as a parameter | n/a | — | — | authoring doctrine |
| 10.5:4409 | relative declaration structurally enforces that rule | n/a | — | — | rationale |
| 10.5:4413 | the bundle's `Δt` is `D·Δt_base`; a phase shifts instants, never the period | accurate | `build.jl:774–776` (`Δt = D * Δtb`) | `test_discrete.jl:308` | |

### §10.6 Event iteration at boundaries (4417–4630)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.6:4422 | the phase iterates: one round re-runs the boundary sweep, evaluates all guards, fires the eligible | accurate | `sim.jl:431–474` | `test_events.jl:138` | |
| 10.6:4425 | at most one firing per component per round, each firing `handler → state_projection` | accurate | `sim.jl:455–460`, `executor.jl:303–311` | `test_events.jl:153` | |
| 10.6:4427 | rounds continue to quiescence | accurate | `sim.jl:439`, `sim.jl:468` | `test_events.jl:138` | |
| 10.6:4428 | an event fires iff holding, previously not-holding, and count < `firing_budget` | accurate | `sim.jl:443–445` | `test_events.jl:205` | |
| 10.6:4435 | `firing_budget` is a `Simulation` keyword, integer ≥ 1, default 4, capping per declared event per boundary | accurate | `sim.jl:130`, `sim.jl:138–139`, `sim.jl:440` | `test_events.jl:205` | |
| 10.6:4438 | the three loop-state registers are the prior, the last-observed sample and the firing count | accurate | `executor.jl:250–254` | `test_events.jl:153` | named normatively |
| 10.6:4440 | the prior is the previous boundary's quiescent sample, tested by the first round | accurate | `sim.jl:436` (`copyto!(es.last, es.prior)`) | `test_events.jl:114` | |
| 10.6:4442 | the last-observed sample is initialized from the prior and overwritten by every round | accurate | `sim.jl:436`, `sim.jl:464` | `test_events.jl:153` | |
| 10.6:4445 | the exception is an eligible-but-blocked event, whose sample stands | accurate | `sim.jl:462–464` | `test_events.jl:153` | D-191 |
| 10.6:4447 | the firing count is incremented at each firing and reset when the boundary ends | accurate | `sim.jl:437`, `sim.jl:459` | `test_events.jl:205` | reset at boundary entry |
| 10.6:4457 | sticky predicates fire once, at the boundary where they first held | accurate | `sim.jl:443` (edge against `last`) | `test_events.jl:114` | |
| 10.6:4460 | a predicate falsified and re-enabled inside the boundary fires again against a fresh sweep | accurate | `sim.jl:443`, `sim.jl:469` | `test_events.jl:153` | D-181 |
| 10.6:4460 | the sketch's ordering: `last ← now` before the firings, `prior ← last` after the loop | accurate | `sim.jl:462–467`, `sim.jl:471` | `test_events.jl:153` | matches line for line |
| 10.6:4473 | the prior is updated at each quiescence, unconditionally, from the final samples | accurate | `sim.jl:471` | `test_events.jl:114` | |
| 10.6:4480 | all three registers are outside every state store, reconstructed deterministically | accurate | `executor.jl:250–254` (plain vectors on the `EventSet`) | no test | |
| 10.6:4485 | boundary zero establishes every prior as not-holding; a predicate holding in the authored state fires at t₀ | accurate | `sim.jl:540` (`fill!(prior, false)`) | `test_events.jl:126` | |
| 10.6:4488 | a warm restart resets all three registers, `init!` re-running boundary zero | accurate | `sim.jl:540`, `sim.jl:436–437` | `test_events.jl:205` | |
| 10.6:4492 | why iterate (cascade latency, orthodoxy) | n/a | — | `test_events.jl:138` | rationale; the h-independence is asserted |
| 10.6:4507 | a round re-runs the whole gated schedule | accurate | `sim.jl:405–411`, `sim.jl:469` | `test_events.jl:138` | |
| 10.6:4515 | the signal table has a single writer, the sweep; a handler writes nothing to it | accurate | `executor.jl:313–317` (stores only) | `test_events.jl:186` | |
| 10.6:4519 | the framework latches returned transitions and `state_projection` normalizes them | accurate | `executor.jl:307–308`, `executor.jl:319–324` | `test_events.jl:247` | |
| 10.6:4523 | the epoch rule: a handler executes against exactly the world its guard fired on | accurate | `executor.jl:307` (bundle built at dispatch from the live table) | `test_events.jl:153` | |
| 10.6:4528 | no bundle straddles two epochs; serialization delivers it | accurate | `sim.jl:455–460` (one event per component per round) | `test_events.jl:153` | |
| 10.6:4530 | a component's other eligible events are blocked, not lost, and re-decided next round | accurate | `sim.jl:455–456`, `sim.jl:462–464` | `test_events.jl:153` | |
| 10.6:4533 | declaration order is a priority with re-decision | accurate | `build.jl:986–994` (global index order), `sim.jl:455` | `test_events.jl:153` | |
| 10.6:4536 | blocking is register-visible: the blocked sample is not overwritten | accurate | `sim.jl:462–464` | `test_events.jl:153` | D-191 |
| 10.6:4543 | handler order across components is unobservable; execution order is executor component order then declaration order | accurate | `build.jl:979–994`, `executor.jl:301–311` | no test | |
| 10.6:4549 | the single-pass executor builds each handler's bundle at dispatch, with no staging pass, shadow table or allocation | accurate | `executor.jl:303–311` | `test_events.jl:273` | |
| 10.6:4553 | a handler cannot opt into seeing a same-round foreign transition | accurate | `executor.jl:313–317` | `test_events.jl:138` | the trade, as recorded |
| 10.6:4570 | termination is budget-bounded: at most `firing_budget · E` firings per boundary | accurate | `sim.jl:444`, `sim.jl:459` | `test_events.jl:205` | |
| 10.6:4573 | a livelock does not resolve silently: each toggler spends its budget and warns, and the run proceeds | accurate | `sim.jl:447–453`, no throw | `test_events.jl:205` | |
| 10.6:4579 | no deferral machinery: no manufactured prior, no re-arm flag, no `EventDeferred` warning | accurate | absence in `executor.jl:242–262`, `dataplane.jl` kind set | no test | D-020, D-181 |
| 10.6:4584 | on exhaustion the event's further edges at this boundary are lost; it is skipped by the eligibility test | accurate | `sim.jl:444` | `test_events.jl:205` | |
| 10.6:4587 | every other event iterates normally | accurate | `sim.jl:442–466` (per-event registers) | `test_events.jl:205` | asserted on the sibling |
| 10.6:4588 | a `FiringBudget` warning, at most once per event per boundary | accurate | `sim.jl:445–453`, `sim.jl:438` (`warned` reset) | `test_events.jl:205` | raised on a *lost edge*, not on the exhausting firing; friction 6.1 |
| 10.6:4590 | the warning carries the component path, the event name, the boundary time, the budget and the firing count | accurate | `dataplane.jl:93–98`, `sim.jl:449–451` | `test_events.jl:205` | |
| 10.6:4593 | the default of 4 (rationale) | n/a | — | — | rationale |
| 10.6:4598 | ticks stay outside the iteration, after quiescence | accurate | `sim.jl:355–357` | `test_events.jl:186` | |
| 10.6:4602 | due output stages are gated into the boundary sweep against a due set fixed for the whole iteration | accurate | `sim.jl:432`, `sim.jl:469` (same `tick`) | `test_events.jl:186` | |
| 10.6:4604 | every round refreshes them against the same `s` and post-transition inputs | accurate | `sim.jl:405–411` (`state_update` outside the loop) | `test_events.jl:186` | |
| 10.6:4614 | ticks → events is structurally impossible: `s⁺` is first decoded at the owner's next tick | accurate | `executor.jl:160–164`, `sim.jl:356–357` | `test_events.jl:186` | |
| 10.6:4623 | the final macro-sequence: integrate → project → [sweep → guards → handlers] → all due `state_update` → logging / I/O | accurate | `sim.jl:349–358`, `sim.jl:1041–1043` | `test_events.jl:186` | |
| 10.6:4623 | boundary zero is the same sequence with an empty integrate | accurate | `sim.jl:392–399` | `test_discrete.jl:290` | |
| 10.6:4626 | the mixed case worked example (engine transition under a 50 Hz FCS) | n/a | — | `test_events.jl:186` | worked example |

### §10.7 Real-time pacing (4632–4714)

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| 10.7:4634 | the pacer inserts waits between completed frames and never reorders, skips or alters the boundary sequence | absent | — | — | no pacer exists. See 4.1 |
| 10.7:4636 | a paced and an unpaced run with identical input traces are bit-identical | absent | — | — | vacuously true; nothing implements the paced side |
| 10.7:4639 | event localization runs identically paced or unpaced, its sweep cost absorbed as debt | absent | — | — | no debt accounting |
| 10.7:4643 | wall-clock map `τ(t) = τ_anchor + (t − t_anchor)/p`, re-anchored at every knee | absent | — | — | no `p`, no anchor pair |
| 10.7:4646 | a live pace change and un-pause re-anchor; debt is cleared at re-anchor and the counters record the forgiveness | absent | — | — | |
| 10.7:4650 | deadline law: absolute schedule, a frame exceeding `h/p` leaves debt repaid by later frames | absent | — | — | |
| 10.7:4653 | debt beyond `5·h/p` is forgiven by re-anchor plus warning | absent | — | — | `DebtReanchor` named absent at `dataplane.jl:36` |
| 10.7:4660 | `p = ∞` is pacer-off, not a limit value: no waits, no debt, no warnings | absent | — | — | the only mode that exists, by default |
| 10.7:4664 | hybrid sleep-then-spin: sleep toward `deadline − margin`, then spin | absent | — | — | no `sleep` anywhere in `src/` |
| 10.7:4680 | `margin` is a single constant defaulting to 2 ms | absent | — | — | no such keyword on `Simulation` |
| 10.7:4685 | `margin = 0` / 2 ms / `∞` span the design space | n/a | — | — | rationale for a knob that does not exist |
| 10.7:4695 | when the frame budget is at or below the margin the hybrid degenerates to pure spin | absent | — | — | |
| 10.7:4699 | the coarse phase uses task-yielding `sleep` | absent | — | — | `sim.jl:1032` yields once per frame, unconditioned on any deadline |
| 10.7:4703 | overrun count, current and peak debt, forgiven-debt events and wait statistics are published as framework status | absent | `dataplane.jl:368–370` (`FrameworkStatus` holds writer records only) | — | See 4.1 |
| 10.7:4708 | forward pointers to §11 and §12 | n/a | — | — | pointer |

## 4. Deviations in detail

### 4.1 §10.7 is not built, and §10.1 and §10.4 carry the shortfall

Spec, §10.1 line 3689: "Six activities make up the simulation loop: the §5.3
boundary sequence, tick dispatch, event handling, logging, input staging, and
pacing (waits inserted between completed frames, never altering the boundary
sequence). **Rule.** All six are **framework code, unconditionally**."

Five of the six are built and are framework code. The sixth is not built.
`grep -rn "sleep\|Timer(\|time()" src/` returns five hits: two in
`devices.jl:440–442` (the shutdown join deadline under `join_timeout`) and
three in `dataplane.jl` (the heartbeat stamp and the `stale` read). None of
them is a pacer. The frame loop at `sim.jl:1023–1063` contains no wait of any
kind; its only scheduling concession is `isempty(plane.roster) || yield()` at
`sim.jl:1032`, which exists to give co-resident device tasks a slot, not to
meet a deadline.

The consequences reach two other claims in my slice. §10.4 line 3803 lists
"pacer deadlines (§10.7)" as one of the three things keyed to a frame; only
the input drain (`sim.jl:1035`) and tick eligibility (`sim.jl:1042`) exist.
§10.4 line 4044 says "The `t*` publication is not separately paced", which is
true only because nothing is paced.

§10.7's diagnostics clause (line 4703) asks for overrun count, current and peak
debt, forgiven-debt events and wait statistics to be published as framework
status. `FrameworkStatus` at `dataplane.jl:368–370` carries a
`Vector{WriterStatus}` and nothing else, and `WriterStatus`
(`dataplane.jl:352–359`) carries `who`, `recent`, `suppressed`, `totals`,
`heartbeat` and `task_state`. There is no field for any pacer quantity.

The absence is documented at the two file headers that would own the feature:
`dataplane.jl:8` ("what stands further out in the spec — the pacer diagnostics
— is deliberately absent") and `devices.jl:6` ("pause, pacing and the operator
interrupt are absent"). `dataplane.jl:36` names `DebtReanchor` as one of three
diagnostic kinds absent with their features. D-021 (decisions.md:643) is
ratified and specifies the whole design, so this is an unbuilt feature rather
than a ratified departure from one.

Why it matters: the pace-independence guarantee that §10.4 leans on three
times ("deterministic and pace-independent like any other localization
outcome", "never of wall clock", "the run replays identically") is currently
unfalsifiable, because there is no paced run to compare an unpaced one
against. Nothing is wrong today; the claim is simply untested by construction.

### 4.2 The convergence law is relative to the segment, not the frame

Spec, §10.4 line 3971: "Localization stops once the bracket is narrower than
`localization_tol · h`", and the sketch at line 3892 spells it out as
"relative: bracket width (hi − lo)·h vs. tol·h". D-133 (decisions.md:3877)
repeats the same form: "localization converges when the bracket is narrower
than `localization_tol · h`".

The code stops at `localization.jl:195`, `while hi - lo > tol`, where `lo` and
`hi` are θ coordinates over the *current segment*, whose width is
`h′ = t_to - t_seg` (`localization.jl:49`). On the first segment of a frame
`h′ = h` and the two laws coincide exactly. On a remainder step after a `t*`
firing, `h′ < h`, so the code's stopping bracket in time is `tol · h′`, which
is strictly tighter than `tol · h`.

The deviation therefore never loses accuracy; it buys a little more than
promised, at the cost of a trial or two on remainder steps. I have marked the
row accurate because it covers the whole claim. It is recorded here because
the letter of the law differs and because the docstring at
`localization.jl:178` states the code's version ("relative: the bracket in θ
against the segment, D-133") rather than the spec's, so a reader comparing the
two texts will find them disagreeing about what D-133 says.

### 4.3 Probe: the float refusals

§10.5 line 4262 says "A float argument throws the teaching error naming the
exact spelling (`Period(1//50)`, or `Hz(1//2)` for 0.5 Hz)." I ran a probe
because the claim is about message text, which reading alone does not settle.

```
julia --project=. -e 'using Cadence; Cadence.Period(0.02)'
```

The four cases returned:

```
BuildError: ArgumentInvalid: a period is an exact Rational — write `Period(1//50)`, not 0.02: grid derivation is GCD arithmetic (§10.5)
BuildError: ArgumentInvalid: a frequency is an exact Rational — write `Hz(1//2)` for 0.5 Hz, not 0.5: grid derivation is GCD arithmetic (§10.5)
BuildError: ArgumentInvalid: an offset is an exact Rational — write `Absolute(Hz(50), 1//500)`, not 0.5: grid derivation is GCD arithmetic (§10.5)
BuildError: ArgumentInvalid: `Absolute` takes a quantity value: `Period(1//50)` or `Hz(50)` — got 0.02 (§10.5)
```

All four name the exact spelling, including the two the spec quotes verbatim.
The row is accurate. No deviation.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 165 |
| short | 2 |
| stand-in | 0 |
| absent | 14 |
| n/a | 23 |
| **total** | **204** |

The two `short` rows are §10.1:3689 (five of six loop activities) and
§10.4:3803 (two of three things keyed to a frame). Both are short for the same
reason: §10.7 is not built. Thirteen of the 14 `absent` rows are §10.7's; the
fourteenth is §10.4:4044, whose claim about pacing is vacuous for the same
reason.

## 6. Friction

**6.1 When does `FiringBudget` fire?** §10.6 line 4584 reads "When an event
has fired `firing_budget` times at a boundary, its further edges there are
**lost** ... Exhaustion emits a `FiringBudget` warning". Two readings fit. The
code (`sim.jl:445`) warns when an exhausted event *presents an edge that is
then discarded*: `edge && !eligible && !warned`. A literal reading of
"exhaustion emits" would warn on the budget-consuming firing itself, whether or
not a further edge appears. The difference is observable: an event that fires
exactly four times and then quiesces warns under the literal reading and stays
silent under the code's. I lean to the code, because the section is titled
"Budget exhaustion degrades; it does not throw" and nothing degraded in that
case, and because the payload's `count` field would be a constant equal to
`budget` under the literal reading. But the sentence does not settle it. The
symmetric `ChatteringBudget` site (`localization.jl:73`) makes the same choice,
and §10.4's wording there ("any further crossings fire ... under a
`ChatteringBudget` warning") supports it more clearly than §10.6's does.

**6.2 §10.5's three kinds of boundary omit a fourth.** Line 4187 says "At a
**frame top**, the due set is the gate's image of the frame index." With
`n > 1`, a frame top is a base tick only every `n` frames, and the frame index
is not the tick index. The code handles this correctly — `sim.jl:1042` routes
`k % sim.n == 0` to `boundary!(sim, k ÷ sim.n)` and everything else to
`offtick_boundary!`, so a non-tick frame top gets the same empty due set a
`t*` boundary gets — but §10.5's enumeration has no row for it, and the phrase
"the gate's image of the frame index" is wrong for `n > 1` as written. A
reader implementing from the prose alone would pass `k` to the gate.

**6.3 The spec and the decision log disagree on a keyword's name.** D-133 calls
the per-frame allowance `event_budget`; §10.4 and the code call it
`localization_budget`. Harmless, but it cost me a grep.

**6.4 §10.4 line 3986's "in declaration order within the iteration" needs
§10.6 to mean anything.** Two tied events on the same component do not fire in
the same round; the second fires in round two under §10.6's one-per-component
rule. The sentence reads as if they fire together in order. The code is right;
the prose is compressed.

**6.5 §10.1's six activities include logging and input staging**, which are
§11's to build and §11's to audit. I checked only that they exist as framework
code in `src/` (`dataplane.jl`, `trace.jl`), not that they are correct.
