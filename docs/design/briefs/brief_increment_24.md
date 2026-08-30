# Increment 24 — runtime failures (§13.4): the execution cursor, `StepError`, the interrupt carve-out and the nonfinite sweep

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `10fcae1`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths). Read `docs/implementation/status.md` first,
then `map.md`/`tests.md` on demand. Spec sections to read in full before
touching code, all in `docs/design/spec.md`: §13.4 (lines ~7065–7175), §13.6
(~7301–7354), §12.4's "The operator interrupt" subsection (~6416–6462), §12.7's
"Termination and partial replay" bullet (~6688–6700), §13.2's rendering rules
(~6914–6935), Appendix C rows `StepError` and `NonfiniteState` (~10114);
decisions D-059, D-157, D-203 in `docs/design/decisions.md`.

**Stance: conservative reading.** Build what the spec and this brief say.
Where the spec is silent, choose the simplest thing that does not foreclose
the spec'd shape, and record the choice in your report. Where the spec and
this brief disagree, or where following either would produce something wrong,
stop and say so in the report rather than improvising.

Run the suite in the foreground with a 600 s timeout, never in the
background: `julia --project=. --startup-file=no test/runtests.jl` from the
repository root (the first run after an `src/` edit pays a ~15 s precompile).
One commit per stage, suite green at each. Commit subject: one sentence, no
body, no attribution. Do not push.

## Scope

**In.** `ExecutionCursor` on the executor, written at every user-code dispatch
and at every phase transition; the one catch site around the frame loop's
boundary sequences, wrapping into `StepError`; the `InterruptException`
carve-out to the stop path; the `isfinite` sweep over `x` as the boundary's
first act, raising `NonfiniteState` as a `StepError` species; the compact
rendering; `to_boundary` re-expressed in grid boundaries (below); the
end-to-end reproduction test (replay to the pointer, `step!`, the same
error).

**Out.** §12.4's sigint masking (`disable_sigint`) and the operator-interrupt
entry itself — the carve-out is the catch site's discrimination alone, and
the only way to reach it is a fixture that throws `InterruptException`
inside model code; §9.5's always-on conformance check (absent, so its
`StepError` species has no producer yet — but the species rule below already
admits it); boundary zero's own failures (`init!` and `replay!` run it as
stopped-sim services and propagate raw, unchanged — a conservative choice,
flagged for the spec pass); pause and the rest of the control plane; §10.7
pacing; the optional grouping of `Simulation`'s remaining fields (not this
increment).

## The shapes

### The cursor (`executor.jl`, before the entries)

```julia
# §13.4: where in the compiled schedule execution is — one plain mutable
# struct the executor owns, overwritten per dispatch, read only at the catch
mutable struct ExecutionCursor
    comp::Int        # the schedule index: the component's index in the flat, 0 = none
    fn::Symbol       # :h_x | :h_xu | :h_s | :h_su | :f | :g | :guard | :handler | :project | :none
    phase::Symbol    # :drain | :integrate | :arrival | :validation | :trial | :project | :round | :ticks
    index::Int       # the RK stage, the event round, the trial ordinal; 0 where none applies
end
ExecutionCursor() = ExecutionCursor(0, :none, :drain, 0)
```

Every entry type — `StageEntry`, `RHSEntry`, `UpdateEntry`, `EventEntry`,
`ProjectEntry` — gains two fields, `ci::Int` and `cursor::ExecutionCursor`,
carried exactly as `clock` is today (a shared mutable object, closed over at
compile time). `StageEntry` also gains `fname::Symbol` (`nameof(fn)` computed
once in `compile`), so the dispatch store is a field read, never a `nameof`
call. The stores, one pair per dispatch, at the existing sites:

```julia
@inline function run!(e::StageEntry, store, xbuf, ẋbuf)
    e.cursor.comp = e.ci; e.cursor.fn = e.fname
    y = e.fn(e.comp, make_bundle(e, store, xbuf))
    scatter_group!(store, e.outs, y)
end
# RHSEntry: fn = :f; UpdateEntry: fn = :g; _guard_walk: :guard; _fire_walk:
# :handler before the handler and :project before _fire_project! when the
# entry has one; run_project!: :project.
```

The `@ballocated(body()) == 0` assertions must stay green: a store of an
`Int` or a `Symbol` into a mutable struct allocates nothing. If a store
shows up as an allocation anywhere, that is a finding, not something to work
around.

The phase is written by the loop, once per phase transition, never per
dispatch:

- `step!(sim, h)` (sim.jl): `phase = :integrate, index = 0` before the
  backend; `evaluate!(ex)` does `ex.cursor.index += 1`, so the stage ordinal
  counts RHS evaluations and the backends stay untouched. The localization
  loop's ẋₙ₊₁ evaluation sets `phase = :arrival` first, so it never reads as a
  stage.
- `localize.jl`: `:arrival` before the arrival sweep, `:validation` before the
  θ = 0 sweep, `:trial` with `index = j` (the trial ordinal within this
  root-find, from 1) inside `_trial!`'s callers — set it in `_crossing` before
  each `_trial!`.
- `boundary!`/`offtick_boundary!`/`boundary_zero!`: `:project` before
  `_projects!`; `event_phase!` sets `:round` with `index = r`, `r = 1` for the
  boundary sweep and incrementing per iteration (the guard walk and the fire
  walk of round *r* carry the same index); `:ticks` before `bodies.ticks`.
- `drain!`: `phase = :drain, comp = 0, fn = :none` at its top — the one store
  per frame that keeps a stale frame from being reported for a drain-side
  throw.

The executor gains `cursor::ExecutionCursor` and `xblocks::Vector{UnitRange{Int}}`
— the flat-buffer range each component's continuous state occupies (empty for
a component without one), from `x_offs[ci]` and `nleaves(typeof(decls[ci].x))`
in `compile`. `trim.jl` and `readers.jl` construct nothing that changes;
check the `Executor(...)` call sites all the same.

### The carrier and the kind (`diagnostics.jl`)

```julia
"An immutable copy of the cursor at the catch (§13.4): the frame a StepError carries."
struct CursorFrame
    path::String     # flat.paths[comp], "" when comp == 0
    fn::Symbol
    phase::Symbol
    index::Int
end

"""
§13.4's runtime carrier, `BuildError`'s counterpart: the cursor's frame, the
clock at the failure, the frame-entry boundary index (the replay pointer) and
the original exception as `cause`. A *species* is a `StepError` whose `cause`
is a typed diagnostic — `NonfiniteState` here, `ConformanceFailure` once §9.5's
runtime check exists.
"""
struct StepError <: Exception
    frame::CursorFrame
    t::Float64       # Float64(clock.t) at the catch: the boundary time in a boundary
                     # phase, the stage or trial time mid-integration
    boundary::Int    # the frame-entry boundary index: replay!(…; to_boundary = boundary)
    cause::Any
end

"§13.4: a nonfinite continuous state leaf found by the boundary's first act."
Base.@kwdef struct NonfiniteState <: Diagnostic
    path::String
    leaf::String     # the leaf's dotted spelling within the state, e.g. "q" or "v[2]"
    value::Any       # the offending value: NaN, Inf or -Inf
    t::Float64       # the frame-top time the integrate landed on
    boundary::Int    # the frame-entry boundary index, as the carrier's
end
path(d::NonfiniteState) = d.path
```

The leaf spelling needs a small `leaf_names(::Type{P})::Vector{String}` in
`leaves.jl`, walking `fieldtypes` and `StaticArray` lengths exactly as
`leaf_types` does — cold path, called once at throw time.

`Base.showerror(io, e::StepError)` renders one frame line then the cause,
§13.2's doctrine (the didactic frame first, the raw throw second). The frame
line names the path, the function, the phase with its index, the time and
the pointer, and states the reproduction:

```
StepError: in `plant` f, integration stage 3 of the frame from boundary 6 (t = 0.135):
  replay!(sim2, trc; to_boundary = 6) then step!(sim2) reproduces it
  cause: DomainError with -0.2: …
```

A `Diagnostic` cause renders as `logline(cause)`; any other as
`showerror(io, cause)`. Spell the phase per case (`integration stage k`,
`arrival sweep`, `θ = 0 validation`, `localization trial k`, `projection`,
`event round r`, `tick updates`, `drain`); `fn === :none` drops the function
from the line. The `NonfiniteState` message reads
"`plant`: state leaf `q` is NaN at the frame top t = 0.14 (from boundary 6) —
the model diverged; replay to 6 and step! to inspect the frame".

### The catch site (`sim.jl`, `_advance!`)

One `try` around the loop's body, per `_advance!` call — never per stage and
never per component. The frame-entry index is read into a local at the frame
top, before the drain, so the catch has it whether the throw came from the
drain, the integrate or a boundary:

```julia
function _advance!(sim, pol, upto, t_end_frame)
    …
    entry = 0
    try
        while true
            … the stop-word / t_end / upto checks unchanged …
            entry = sim.exec.clock.step
            drain!(sim)
            k = (sim.exec.clock.step += 1)
            frame!(sim, k)
            … boundary, publish, stop-face sampling unchanged …
            adv += 1                    # moved here: only a completed frame counts
        end
    catch err
        err isa InterruptException && return (ControlRequestedStop(:interrupt), adv)
        rethrow(_wrap_step(sim, entry, err))
    end
end
```

`_wrap_step(sim, entry, err)` builds the `StepError`: the frame from the
cursor (`flat.paths[comp]` through `sim.build.flat`), `t = Float64(clock.t)`,
`boundary = entry`, and the cause under the **species rule** — a
`BuildError` carrying exactly one diagnostic thrown inside the sequence
arrives as that diagnostic, unwrapped; anything else is the raw exception.
The rule is what makes the nonfinite sweep and a future §9.5 runtime check
plain throwers of their kind, the catch site being the only `StepError`
constructor. A `StepError` never arrives here twice (nothing inside the
sequence throws one), so no pass-through arm is needed; assert that with an
`InternalInvariant` rather than silently re-wrapping.

Downstream is untouched: `_run_body!`'s catch wraps the `StepError` into
`LoopError` exactly as it wraps the raw cause today, the tail runs, `run!`
rethrows the `StepError` after it, `step!` likewise. The `TaskFailedException`
unwrap in `_run_body!` stays — it is for the spawned-loop topology.

**The carve-out.** `InterruptException` returns from the catch as a
termination source, `ControlRequestedStop(:interrupt)` — the spec's own arm,
absent until now (`devices.jl`'s docstring says so; update it). The frame is
abandoned unpublished, the clock stays wherever the throw left it, and the
stores may be mid-boundary: `stopped` here is §12.4's masked guarantee
*without* the masking, which is exactly the defensive branch §13.4 keeps.
`run!`'s tail and terminal store then run the graceful path, so the
simulation ends `stopped` with the record's `t` the last published boundary's.
Say in the report that a stopped-with-dirty-stores simulation is still
inspectable by every stopped-sim service, and that the masking is what would
close that gap.

### The sweep (`sim.jl`, `step!(sim, h)`)

The boundary's first act (D-157): immediately after the backend returns and
before anything reads the state — `frame!`'s bare path and every segment
`step!` of `_localized_frame!` alike, which is why the site is the seam's
framework side and not the frame loop:

```julia
@inline function step!(sim::Simulation, h)
    isempty(sim.exec.xbuf) ? (sim.exec.clock.t += h) : step!(sim.stepper, sim, h)
    _check_finite!(sim)
    nothing
end

function _check_finite!(sim)
    x = sim.exec.xbuf
    @inbounds for i in eachindex(x)
        isfinite(x[i]) || _nonfinite(sim, i)   # the throw is the cold path
    end
    nothing
end
```

`_nonfinite` (`@noinline`) finds the owner through `xblocks`, sets the
cursor to `comp = owner, fn = :none` (the phase is still `:integrate`), and
throws `BuildError(NonfiniteState(path, leaf_names(XT)[i − first(block) + 1],
x[i], Float64(clock.t), clock.step − 1))`; the catch site makes it the
species. `ẋ` does not participate (D-157). The sweep runs on every segment
integrate, including the remainder steps after a `t*` boundary, and never at
boundary zero (no integrate there). The `Dual` activations run the loop too
(`test_dataplane.jl` builds a `D8` simulation): `isfinite` on a `Dual` is
defined, and `Float64(clock.t)` is already the loop's spelling in
`FiringBudget`.

### `to_boundary` in grid boundaries (`sim.jl`, `replay!`)

The pointer the error names must be the number `replay!` takes. §12.7 defines
`to_boundary = k` as running through the frame that published boundary `k`,
"for a grid boundary the halt is exactly at `k`", and the reporting index is
the boundary — the snapshot's `frame`. Every frame top is a grid boundary
(§10.4), so `k` counts frames: the halt is `clock.step == k`, the range
`0 ≤ k ≤ trc.frames`. Increment 23 spelled it in base ticks (`k · n`), which
coincides only at `n = 1`; retire that. Update `replay!`'s docstring and its
range check, `test_trace.jl`'s partial-replay test (`5 * sim2.n` → `5`), and
the `k · n` wording in `map.md` and `tests.md`.

## Tests — new file `test/test_failures.jl`, included after `test_trace.jl`

Fixtures at top level (`status.md`'s local-scope rule), the new components in
`library.jl` beside `Exploder` — user material, with a docstring each:

- `Tripwire(t_trip)`: continuous, one state `q`, `f` throws `Tripped()` when
  `t ≥ t_trip`; with `t_trip` at a half-step time it fires at RK4 stage 2.
- `Mine`: an input `sig::Bool`, an event whose guard is `u.sig` and whose
  handler throws `Detonated()`.
- `Landmine`: a localized sign-form event (model it on `Bouncer`) whose guard
  throws `Detonated()` when `t` is off the grid, `abs(t − round(t / h) · h) >
  1e-9` — reachable only by a trial evaluation, since arrival, validation and
  boundary rounds all sit on the grid before any `t*` has occurred.
- `Diverger`: continuous state `q`, `f` returns `q = NaN` when `u.arm`,
  otherwise `q = 1`; and `Consumer`, downstream of it, whose `h_xu` computes
  `sqrt(u.in)` — the innocent component a late sweep would blame.
- `Interrupter`: `f` throws `InterruptException()` when `u.arm`.

Assertions on kinds and payload fields, never on message text, except
property 11. Bit-identity is `==` (the claim), everything else per D-163.

1. **The cursor after a quiet frame.** After `step!` on `feedback_model()`,
   `sim.exec.cursor` reads `phase === :ticks` (or `:round` where nothing
   ticks) with `comp` naming the last-walked component; and the 40
   `@ballocated` assertions elsewhere in the suite still pass.
2. **Integration stage attribution.** `fed(Tripwire(0.05), "arm")` at
   `h = 1//10`: `run!` throws `StepError` with `frame == CursorFrame("c", :f,
   :integrate, 2)`, `boundary == 0`, `t == 0.05`, `cause isa Tripped`;
   lifecycle `:errored`; `termination(sim).source isa LoopError` whose
   `exception` is that `StepError`; `latest(sim).t == 0.0`. Update the §13.6
   test in `test_lifecycle.jl` to the wrapped shape (`@test_throws StepError`,
   the cause `Exploded` one level down).
3. **Event round attribution.** `fed(Mine(), "sig")`: stage `sig => true`,
   `step!` throws with `fn === :handler`, `phase === :round`, `index == 1`;
   `boundary` the entry index. And through `stage!` at a later frame,
   `boundary == k` for the frame-entry index `k` actually recorded.
4. **Trial attribution.** `Landmine`: `fn === :guard`, `phase === :trial`,
   `index ≥ 1`, `t` strictly inside the frame.
5. **Tick and projection attribution.** A `g` that throws (`Mine`-style on
   the discrete tier) gives `fn === :g, phase === :ticks`; a throwing
   `project` gives `fn === :project, phase === :project`.
6. **`step!` counts completed frames only.** With `Tripwire` tripping in
   frame 3, `step!(sim; frames = 5)` throws; the record's `t` is boundary 2's.
   (The count itself is unobservable through a throw; pin it through the
   carve-out in 7.)
7. **The carve-out.** `fed(Interrupter(), "arm")` with a `TailProbe`
   attached: arm at frame 3, `run!` returns normally, lifecycle `:stopped`,
   `termination(sim).source === ControlRequestedStop(:interrupt)`, `latest`
   is frame 2's snapshot, the probe saw `[:init, :shutdown]`; the deviceless
   `step!(sim; frames = 5)` returns `2`.
8. **The sweep names the diverging block.** `Diverger → Consumer` under a
   `Group`, armed at frame 2: the `StepError`'s `cause isa NonfiniteState`
   with `path == "div"`, `leaf == "q"`, `isnan(value)`, `boundary == 1`,
   `t == 2h`; `frame.fn === :none`, `frame.phase === :integrate`. Never a
   `DomainError` from `Consumer`. Add a `project` to `Diverger` that would
   throw on NaN, to pin "before `project`".
9. **The sweep covers remainder segments.** A localized model (a `Bouncer`
   variant) whose `f` returns NaN only *after* the `t*` boundary within a
   frame: the failure is still `NonfiniteState`, `t` the frame top.
10. **End-to-end reproduction.** Record a staged `step!`-driven session that
    fails in frame `k + 1` (`Tripwire` armed by a stage at that frame, or
    `Diverger`); read `e = termination(sim).source.exception`; on a fresh
    twin `replay!(sim2, trace(sim); to_boundary = e.boundary)` halts
    `:initialized` at `clock.step == e.boundary`; `step!(sim2)` throws a
    `StepError` whose `frame`, `t`, `boundary` and `typeof(cause)` equal
    `e`'s; `sim2` is `:errored` with `latest(sim2).t == latest(sim).t`. Run it
    for both an ordinary cause and the nonfinite species.
11. **Rendering.** `sprint(showerror, e)` for property 2's error contains
    "`c`", "f", "stage 2", "to_boundary = 0" and "step!"; for property 8's it
    contains "NonfiniteState" and "`q`".
12. **`to_boundary` counts grid boundaries.** At `n = 2`, `replay!(…;
    to_boundary = 3)` halts at `clock.step == 3` (an off-tick frame top) with
    the log a prefix of the recording's; `to_boundary = trc.frames + 1`
    refuses.

## Bookkeeping (each stage its share)

- `status.md`: the `executor.jl` row gains the cursor; `diagnostics.jl`
  gains `StepError`, `CursorFrame`, `NonfiniteState`; `sim.jl` gains the
  catch site, the carve-out and the sweep (§13.4, D-059, D-157); `leaves.jl`
  gains `leaf_names`. Remove "§13.4's `StepError` wrap, cursor and nonfinite
  sweep" from the §12 absence bullet; keep the operator interrupt and its
  masking absent, worded as "the carve-out exists, the masking and the entry
  do not". `NonfiniteState` leaves nothing in the absent-kinds sentence (it
  was never listed). Stand-in rows: none expected; if one is needed, add it
  in the same commit.
- `map.md`: the file entries; the §12 absence paragraph (lines ~148–160)
  re-worded as above; the `k · n` replay wording.
- `tests.md`: the property bullets, the `to_boundary` unit change noted
  against increment 23's bullet, and the two places this increment runs
  ahead of or beside the spec's letter, flagged for the spec pass: the
  species rule (a single-diagnostic `BuildError` unwrapped at the catch) and
  boundary zero's exclusion.
- `devices.jl`: the `TerminationSource` docstring (the `:interrupt` arm and
  the `LoopError` note); `sim.jl`'s `_run_body!` comment ("§13.4's wrap is
  absent").
- `runtests.jl`: the include and the imports (`StepError`, `CursorFrame`,
  `NonfiniteState`, `ExecutionCursor`, the fixtures and their exception
  types).

## Stages

- **Stage 1 (Opus)** — the cursor and its stores, the entry fields,
  `xblocks`, `CursorFrame`/`StepError` and the rendering, the catch site, the
  carve-out, the `:interrupt` arm; the `adv` move; tests 1–7, 11's first
  half; the §13.6 test update. Commit: "Catch runtime failures at one site
  into StepError against an execution cursor".
- **Stage 2 (Opus)** — `NonfiniteState`, `leaf_names`, the sweep in `step!`,
  the `to_boundary` unit change; tests 8–10, 11's second half, 12; the
  bookkeeping's remainder. Commit: "Sweep x for nonfinite leaves as the
  boundary's first act, and point to_boundary at grid boundaries".
- Cold review (Opus) over `10fcae1..HEAD`, then the fixer, then the
  reviewer's delta check.

## Report format (every stage)

Commit hash; files touched; the suite's final tally; every deviation from
this brief with its reason; friction (a spec sentence that resisted, a shape
that fought the code); what the next stage must know (handoff notes).
