# Cold verification — runtime claims (v2)

**Tip.** 70672d1, Julia 1.12.7, package precompiled.
**Method.** Adversarial re-read of each cited report entry, of the code at the
cited lines, of `spec.md` at the cited lines, and of `### D-133` in
`decisions.md`. Three probes run in the foreground from the repository root
under `julia --project=.`, in
`/private/tmp/claude-501/-Users-miguel--julia-dev-Cadence-jl/124e226d-cd72-4408-ae47-a86fb39129da/scratchpad/verify2/`:
`p1.jl` (the `t_end` landing rule and the `t0` interaction), `p3.jl` (the
`unblock!`-provoked raise), `p5.jl` (the interrupt against the stop word).
Nothing under `src/`, `test/` or `docs/design/` was modified. The test suite
was not run.

Line numbers below are the ones I read at this tip. Where a report's citation
drifts from the line it names I say so; in every such case the substance stood.

---

## 1. `t_end` is rounded, not ceiled — and it ignores `t0`

**CONFIRMED** (the reported claim), **with an added, previously unreported
defect: the target frame ignores a nonzero `t0`.**

All three advance entries compute the target frame with `round`:

```
src/sim.jl:792   _run_body!(sim, pol, upto, te === nothing ? typemax(Int) : round(Int, te / sim.h))   # replay!
src/sim.jl:885   _run_body!(sim, pol, typemax(Int), round(Int, te / sim.h))                            # run!
src/sim.jl:1133  t_end_frame = sim.t_end === nothing ? typemax(Int) : round(Int, sim.t_end / sim.h)    # step!
```

Spec §12.4 (`docs/design/spec.md:6324–6325`): "**`t_end` lands on the grid.**
The run ends at the first grid boundary whose time reaches or exceeds `t_end`."
Appendix B (`docs/design/spec.md:9917–9918`) repeats it. D-133
(`decisions.md`, §"Position", final sentence) states the same rule and its
"Rejected" list names *"Ending at the last boundary before `t_end`"* explicitly
as rejected. `ceil` is required; `round` is built.

Probe `p1.jl`:

```
A) t_end=0.54, h=1/10 -> final t = 0.5  source = EndTimeReached()
C) step! t_end=0.54    -> final t = 0.5  source = EndTimeReached()
```

**The added claim is also true, and is the sharper of the two.** `t_end_frame`
is compared against `sim.exec.clock.step` (`src/sim.jl:1033`), and
`_open_trajectory!` sets `sim.exec.clock.step = 0` at every `init!`
(`src/sim.jl:539`) regardless of `t₀` (`src/sim.jl:537–538` set
`clock.t = clock.t₀ = t₀`). So the target is a *frame count from zero*, never a
grid time. Probe `p1.jl`:

```
B) t0=10.0, t_end=12.0, h=1/10 -> final t = 22.0 source = EndTimeReached()
```

`run!(sim; t_end = 12.0)` on a trajectory opened at `t₀ = 10.0` runs 120 frames
and stops at `t = 22.0`, reporting `EndTimeReached()`. The correct landing under
§12.4 is `t = 12.0` (frame 20). The fix is one expression:
`ceil(Int, (te - t₀) / h)` against the step count, or equivalently a comparison
of `clock.t` against `t_end` rather than of `clock.step` against a count. The
reports missed this; it is a larger error than the rounding, because the
overshoot is unbounded in `t₀` rather than bounded by `h/2`.

Citation drift in `f_lifecycle.md` §4.2: it names `src/sim.jl:891` for `run!`
(actual 885), `1136` for `step!` (actual 1133) and `793` for `replay!` (actual
792).

## 2. The localization stopping law is relative to the segment, not the frame

**CONFIRMED.**

`src/localization.jl:195`: `while hi - lo > tol`, with `lo`/`hi` in θ over the
current segment whose width is set at `src/localization.jl:49`:
`h′ = t_to - t_seg`. `_trial!` maps θ back as `t_seg + θ * h′`
(`src/localization.jl:168`). On the first segment `h′ = h`; on a remainder
segment after a `t*` firing `h′ < h`, so the bracket in time is `tol·h′`,
strictly tighter than the specified `tol·h`.

**Which form the log states: `localization_tol · h`, the frame period.** D-133
("Position"): "`localization_tol`, a *relative* bracket-width convergence test
for §10.4's root-finder (localization converges when the bracket is narrower
than `localization_tol · h`), default `1e-6`". Spec §10.4
(`docs/design/spec.md:3971–3972`): "Localization stops once the bracket is
narrower than `localization_tol · h`". Neither text mentions a segment.

The docstring misattribution is real. `src/localization.jl:178–179`:

```
convergence certificate. Stops once `hi - lo ≤ localization_tol` (relative: the
bracket in θ against the segment, D-133) and returns the **holding endpoint of
```

D-133 says no such thing. A second, smaller docstring defect the report did not
flag: the docstring says the loop stops once `hi - lo ≤ localization_tol`, while
the code's guard is `hi - lo > tol` — the same predicate, so the text is right
by accident, but it also omits the `·h′` scaling it claims to be describing.

The deviation is conservative (tighter than promised, at the cost of a trial or
two on remainder steps), which matches the report's own assessment.

## 3. `_wrap` files a `DeviceCrash` for the `unblock!`-provoked raise

**CONFIRMED.**

`src/devices.jl:348–358` in full:

```julia
function _wrap(e::RosterEntry)
    try
        loop(e.dev, e.handle)
    catch err
        _report!(e.diag, DeviceCrash(err, e.should_abort))
    finally
        _shutdown!(e)
        e.should_abort && stop!(e.handle)
    end
    nothing
end
```

Every throw out of `loop` becomes a `DeviceCrash`. Nothing consults
`ctl.stopped`, so the wrapper cannot discriminate. Spec §12.4(3)
(`docs/design/spec.md:6270–6273`): "A network input's override closes its own
socket, which raises in the blocked task. The framework wrapper catches that
raise and treats it as shutdown."

Probe `p3.jl` — a top-level `Blocked` device whose `unblock!` closes its channel
and whose body is the plain `while running(h); take!(d.ch); end`, run to a clean
`t_end = 0.5`:

```
source = EndTimeReached()  t = 0.5
dev.log = [:init, :loop, :unblock, :shutdown]
residue writer = device 1 (Blocked)
   recent: DeviceCrash -> DeviceCrash(InvalidStateException("Channel is closed.", :closed), false)
   suppressed = KindCounts(0, 0, 0, 0, 0, 0, 0, 0, 0)
--- warnings ---
Warn | DeviceCrash from device 1 (Blocked), past the final snapshot's account: DeviceCrash(InvalidStateException("Channel is closed.", :closed), false) (§11.8)
```

A clean run of a spec-conforming device leaves a `DeviceCrash` in the
termination record's residue and emits a warning. With `should_abort = true`
the same path would also call `stop!(e.handle)` from the `finally`.

## 4. No `InterruptException` branch in `_wrap`; the loop-side carve-out exists

**CONFIRMED.**

The `_wrap` body quoted under claim 3 has no branch on `err isa
InterruptException`; the sole `catch` files `DeviceCrash(err, e.should_abort)`
and the `finally` consults `e.should_abort`, so a Ctrl-C into a
`needs_calling_task` device's inline body reports a crash by that device's name
and, under `should_abort`, requests a stop attributed to the device
(`src/devices.jl:216`: `stop!(h::DeviceHandle) = _request_stop!(h.ctl, h.who)`).

The loop-side carve-out is present, at `src/sim.jl:1058` (the report's citation
is exact):

```julia
err isa InterruptException && return (ControlRequestedStop(:interrupt), adv)
```

`grep -rn InterruptException src/` returns exactly two hits: `src/sim.jl:1058`
and a prose mention at `src/devices.jl:28`. No signal probe was needed.

## 5. The interrupt carve-out bypasses the stop word and overrides the first issuer

**CONFIRMED**, and reproduced behaviourally.

**Which function decides the termination source: `_advance!`, and only
`_advance!`.** It reads the stop word once, at the frame top
(`src/sim.jl:1031–1032`):

```julia
issuer = @atomic ctl.stop_issuer
issuer === nothing || return (ControlRequestedStop(issuer), adv)
```

and it returns `ControlRequestedStop(:interrupt)` from its `catch`
(`src/sim.jl:1058`) **without reading `ctl.stop_issuer` and without calling
`_request_stop!`**. `_request_stop!` has exactly three call sites in `src/`
(`src/devices.jl:121` — the definition, `src/devices.jl:216` — `stop!(handle)`,
`src/sim.jl:1174` — `stop!(sim)`); the carve-out is not among them.

`_run_body!` then passes `_advance!`'s return value straight through:
`ctl.termination = _record(sim, term, residue)` (`src/sim.jl:985`), and
`_record` (`src/sim.jl:276–280`) only pairs the source with `latest(sim).t`. The
stop word is never re-read on the way to the record. The same holds on the
`step!` path (`src/sim.jl:1141`, `1153`).

Probe `p5.jl` — a top-level component that, inside one frame, first wins the CAS
via `stop!(sim)` (issuer `:code`) and then raises an `InterruptException` from
model code, so the interrupt lands in the catch before the next frame top:

```
lifecycle = stopped
stop word = code
termination source = ControlRequestedStop(:interrupt)   t = 0.2
```

The stop word holds `:code`, the record reports `:interrupt`. First-writer-wins
(`src/devices.jl:118–122`, `@atomicreplace ctl.stop_issuer nothing => issuer`)
is respected in the word and contradicted in the record.

## 6. The heartbeat is read at publication, not at the drain

**CONFIRMED** (one citation corrected).

`_heartbeat` has exactly one call site in `src/`:

```
src/dataplane.jl:291  _heartbeat(cell::DiagCell) = @atomic :acquire cell.heartbeat
src/sim.jl:1461       ws[i] = _writer_status(_who(e), e.acct, _heartbeat(e.diag), _task_state(t))
```

`src/sim.jl:1461` is inside `_status` (`src/sim.jl:1456–1466`), which is called
from `publish!`. `drain!` (`src/sim.jl:1326–1344`) folds accounts
(`_fold!(e.acct, e.diag)`) but never touches the heartbeat field.

Spec §11.8 (`docs/design/spec.md:6000–6001`): "as an atomic timestamp field the
device task stores on every loop pass … and the loop acquire-loads **at the
drain**." Spec §11.2 (`docs/design/spec.md:4862–4863`): "liveness timestamps
the loop takes at frame top". (`e_dataplane.md` cites §11.2 as 4866–4868; the
sentence is at 4862–4863.)

The `t*` claim also holds, but the report's line reference is wrong. **Corrected
citation:** the drain-less `t*` publication is at `src/localization.jl:144–145`
(`offtick_boundary!(sim); publish!(sim)`), inside `_localize!`, not at
`src/sim.jl:1052–1056` — which is the `catch` block. `src/sim.jl` has exactly
one in-frame `publish!` (line 1042) and it is preceded by the frame-top
`drain!` (line 1037); `src/localization.jl:145` is the only publication in a
frame that is not. So a `t*` boundary does publish a heartbeat read at a moment
the spec's rule never names, exactly as the report says.

## 7. `DataPlane.roster` is a mutable vector under a lifecycle gate

**CONFIRMED.**

```
src/roster.jl:168  mutable struct DataPlane
src/roster.jl:169      roster::Vector{RosterEntry}     # attachment order (§11.3): the drain applies in it
```

Mutated in place at `src/sim.jl:1243` (`push!(plane.roster, RosterEntry(...))`)
and `src/sim.jl:1269` (`deleteat!(plane.roster, i)`). Re-read every frame at
`src/sim.jl:1336` (inside `drain!`) and `src/sim.jl:1459` (inside `_status`,
per publication), plus `src/sim.jl:1035` (the `yield()` guard) and
`src/sim.jl:543` (trajectory open).

The only freeze is the lifecycle gate: `assert_stopped`
(`src/devices.jl:131–133`) has exactly three call sites —
`src/sim.jl:1216` (`attach!`), `src/sim.jl:1265` (`detach!`) and
`src/sim.jl:1492` (`logged`). Nothing makes the vector itself immutable; a
caller reaching `sim.plane.roster` directly during a run meets no obstacle.

(`e_dataplane.md` cites `drain!`'s iteration at `src/sim.jl:1339`; it is at
1336.)

## 8. No `sizehint!` in `src/`; the log holds references over per-boundary copies

**CONFIRMED.**

`grep -rn "sizehint" src/` exits 1 with no output — zero occurrences anywhere
in `src/` (and none in `test/` either).

```
src/dataplane.jl:577  capture(b::StoreBundle) = StoreBundle(map(cs -> CellStore(copy(cs.buf)), b.stores))
src/dataplane.jl:625      snaps::Vector{Union{Nothing,Snapshot}}   # the bounded middle; `nothing` = released
```

`CellStore{T}` wraps a `Vector{T}` (`src/store.jl:15–17`) and `StoreBundle`
holds one per element type present in the model (`src/store.jl:20–30`), so
`capture` is a fresh per-eltype buffer copy per published boundary — the
comment at `src/dataplane.jl:575–576` says so ("fresh buffers, one allocation
per boundary"). `SnapshotLog` (`src/dataplane.jl:617–629`) stores those
snapshots as heap references in `snaps`, plus the two endpoint references
`first`/`last` (lines 623–624), never inline records. Spec §7.5's two named
mechanisms — inline storage and `sizehint!` — are neither of them built.

## 9. The device-side diagnostic write is the internal `_report!`

**CONFIRMED.**

Spec §12.4 (`docs/design/spec.md:6418–6420`): "**Rule.** The report is written
through the ordinary `report!(address, diagnostic)` entry point, addressed by
the roster entry rather than by a handle."

Every `report!`/`_report!` **method signature** in `src/` — two, in total:

```
src/devices.jl:291    report!(h::DeviceHandle, d::MalformedDatum) = (_beat!(h.diag); _report!(h.diag, d))
src/dataplane.jl:271  function _report!(cell::DiagCell, d::DiagValue)
```

There is no `report!` method taking a `RosterEntry`, and the single public
`report!` is narrowed to `MalformedDatum` on a `DeviceHandle`. The device-side
writes all go through the internal `_report!`, addressed by the entry's cell
rather than by the entry:

```
src/devices.jl:352   _report!(e.diag, DeviceCrash(err, e.should_abort))            # _wrap
src/devices.jl:382   _report!(e.diag, DeviceCrash(err, e.should_abort))            # _init_devices!
src/devices.jl:448   _report!(sim.loop_diag, DeviceJoinTimeout(...))
src/localization.jl:77, src/sim.jl:451   _report!(sim.loop_diag, ...)
src/sim.jl:1403      _report!(cell, ReplayDiscardedStaging(...))
src/dataplane.jl:475, 477, 479, 486      _report!(cell, ...)
```

The identity the spec wants is supplied — `e.diag` is the entry's own cell — so
the observable account is right; what is absent is the public, address-taking
entry point the Rule names. "stand-in" is the right verdict on that row.

## 10. `FrameworkStatus` carries only `writers`; no pacing anywhere

**CONFIRMED.**

```
src/dataplane.jl:368  struct FrameworkStatus
src/dataplane.jl:369      writers::Vector{WriterStatus}
src/dataplane.jl:370  end
```

One field. `WriterStatus` (`src/dataplane.jl:351–358`) carries `who`, `recent`,
`suppressed`, `totals`, `heartbeat`, `task_state` — no pacer quantity.

Greps over `src/`:

- `sleep` — **zero hits.**
- `margin` (case-insensitive) — **zero hits.**
- `debt` (case-insensitive) — one hit, `src/dataplane.jl:36`, prose naming
  `DebtReanchor` as a diagnostic kind whose feature is absent.
- `pace|pacer|pacing` (case-insensitive) — two hits, both prose declaring the
  absence: `src/devices.jl:6` ("pause, pacing and the operator interrupt are
  absent") and `src/dataplane.jl:8` ("the pacer diagnostics — is deliberately
  absent").
- `Timer(|time()` — five hits, none a pacer: `src/devices.jl:440,442` (the
  shutdown join deadline), `src/dataplane.jl:290` (the heartbeat stamp),
  `src/dataplane.jl:376,385` (`stale`, docstring and body).
- `yield()` — **exactly one hit in all of `src/`.**

**One citation corrected:** the frame loop's `yield()` is at `src/sim.jl:1035`,
not 1032 —

```
src/sim.jl:1035            isempty(plane.roster) || yield()
```

— and it is guarded by `isempty(plane.roster)`, so a deviceless run performs no
scheduling act at all. `d_execution.md` §4.1 names 1032. The substance stands:
there is no wait, no sleep and no deadline anywhere in `_advance!`
(`src/sim.jl:1023–1060`).
