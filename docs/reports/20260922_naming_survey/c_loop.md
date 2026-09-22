# Naming survey — slice C, the loop

Tip `2844584`. Files: `src/sim.jl`, `src/localization.jl`, `src/deployment.jl`.
97 function definitions examined (73 in `sim.jl` including the named inner
closures `_arg`, `_tier`, `_decls`; 5 in `localization.jl`; 19 in
`deployment.jl` including the inner closure `bind`). Date 2026-09-22.

## Conventions

- **`deployment.jl`, every `_exact` method** (lines 13, 14, 15, 16–17, 18–19):
  the raw grid-parameter value being validated is always `v`, and every body
  is one line, so `v` is one-glance regardless of which method dispatches.
- **`deployment.jl`, every `Base.:(==)` method** (`ScheduleEntry` 114–116,
  `Schedule` 144, `Deployment` 378–382): the two compared values are always
  `a`, `b`; every body is a short boolean chain, so both stay one-glance.
- **`deployment.jl`, every `Base.hash` method** (`ScheduleEntry` 117–119,
  `Schedule` 145, `Deployment` 383–386): the running hash seed is always
  `h::UInt`, Julia's own `hash(x, h)` convention, not the step — kept as `h`
  by that convention rather than by the survivor rule.

## The table

### `src/sim.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 185 | `Simulation(d::Deployment,…)` | d | Deployment | param | rename | `artifact` | collides with the module fn `deployment` |
| 209 | `Simulation(b::Build,…)` (sugar) | b | Build | param | rename | `artifact` | collides with the module fn `build` |
| 234 | `_t_bound` | t | untyped, the candidate `t_end` | param | survivor(t) | — | |
| 247 | `_frame_slack` | t | Real, time | param | survivor(t) | — | |
| 247 | `_frame_slack` | h | Float64, the step | param | survivor(h) | — | |
| 248 | `_frames_to` | t | Real, time | param | survivor(t) | — | |
| 248 | `_frames_to` | t₀ | Real, the origin | param | survivor(t) | — | decorated origin variant |
| 248 | `_frames_to` | h | Float64, the step | param | survivor(h) | — | |
| 252 | `_frame_at` | t | Real, time | param | survivor(t) | — | |
| 252 | `_frame_at` | t₀ | Real, the origin | param | survivor(t) | — | decorated origin variant |
| 252 | `_frame_at` | h | Float64, the step | param | survivor(h) | — | |
| 263 | `_stop_faces` (3-arg) | f | comprehension, a root-input face | 263–263 | glance | — | |
| 267 | `_stop_faces` (3-arg) | f | comprehension, a candidate face | 267–268 | glance | — | |
| 267 | `_stop_faces` (3-arg) | p | comprehension, a component path | 267–268 | glance | — | |
| 269 | `_stop_faces` (3-arg) | f | loop var, the raw stop-face entry | 269–270 | glance | — | |
| 270 | `_stop_faces` (3-arg) | s | the candidate face symbol | 270–286 | rename | `face` | |
| 280 | `_stop_faces` (3-arg) | a | the resolved cell address | 280–283 | glance | — | |
| 295 | `_stop_faces` (2-arg) | r | the validated `(faces, addrs)` pair | 295–297 | glance | — | |
| 380 | `_stop_hit` | i | loop var, a face index | 380–381 | glance | — | |
| 510 | `_round!(ex,e::Establish)` | e | Establish, the boundary-zero marker | param | glance | — | one-line body |
| 536 | `event_phase!` | n | the tracked event count | 536–546 | rename | `nevents` | avoids `count`, which collides with the field `es.count` |
| 546 | `event_phase!` | i | loop var, the event index | 546–566 | rename | `event_index` | |
| 603 | `_check_finite!` | x | the flat state buffer | 603–606 | survivor(x) | — | |
| 604 | `_check_finite!` | i | loop var, a flat-state index | 604–605 | glance | — | |
| 613 | `_nonfinite` | i | Int, the failing flat-state index | param | rename | `flat_index` | `index` collides with the field `cur.index` |
| 616 | `_nonfinite` | b | anon-fn arg, one xblock range | glance | glance | — | one-line body |
| 640 | `_open_trajectory!` | t₀ | Float64, the trajectory origin | param | survivor(t) | — | decorated origin variant |
| 647 | `_open_trajectory!` | e | loop var, one roster entry | 647–648 | glance | — | |
| 660 | `_check_recording`'s inner `_arg` | v | the invalid keyword's value | param | glance | — | one-line inner fn |
| 814 | `_compile_feed` | f | comprehension, a root-input face | 814–814 | glance | — | |
| 923 | `replay!` | t₀ | Float64, the recording's origin | 923–927 | survivor(t) | — | decorated origin variant |
| 937 | `replay!` | h | the trace header (`trc.header`) | 937–948 | rename | `header` | not the step — holds a `TraceHeader`, does not survive |
| 939 | `replay!` | ci | loop var, component index into `h.s` | 939–941 | survivor(ci) | — | |
| 942 | `replay!` | ci | loop var, component index into `h.m` | 942–944 | survivor(ci) | — | |
| 945 | `replay!` | f | destructure, a root-input face | 945–946 | glance | — | |
| 945 | `replay!` | v | destructure, the root-input's value | 945–946 | glance | — | |
| 997 | `live!` | r | the current run | 997–1002 | glance | — | |
| 1071 | `_replay_bound` | f | the attached replay feed | 1071–1072 | glance | — | |
| 1083 | `_settle_mode!` | r | the run | 1083–1087 | glance | — | |
| 1084 | `_settle_mode!` | f | the run's feed | 1084–1087 | glance | — | |
| 1113 | `_run_body!` | e | anon-fn arg, one live roster entry | glance | glance | — | one-line body |
| 1125 | `_run_body!` | i | comprehension, a live-entry index | glance | glance | — | one-line body |
| 1177 | `_reset_accounts!` | e | loop var, one roster entry | 1177–1178 | glance | — | |
| 1185 | `_register_tasks!` | e | destructure, one roster entry | 1185–1186 | glance | — | |
| 1185 | `_register_tasks!` | t | destructure, its spawned task | 1185–1186 | glance | — | a `Task`, not spec's `t` |
| 1221 | `_advance!` | k | the new step/frame index | 1221–1224 | glance | — | |
| 1283 | `_species(err::FieldError)` | ci | the component index | 1283–1284 | survivor(ci) | — | |
| 1285 | `_species(err::FieldError)` | c | the component instance | 1285–1293 | rename | `instance` | a `c` component instance does not survive (brief's own rule) |
| 1285 | `_species(err::FieldError)` | t | the component's tier | 1285–1304 | rename | `tier` | a `t` tier does not survive (brief's own rule) |
| 1295 | `_species(err::FieldError)` | e | caught error, probing bundle names | 1295–1296 | glance | — | |
| 1374 | `step!` (kw form) | t | the frame-top time | 1374–1375 | survivor(t) | — | |
| 1461 | `attach!` | b | AbstractBinding, the device's binding | param | rename | `new_binding` | collides with the module fn `binding`, called at line 1470 in this same function |
| 1467 | `attach!` | e | loop var, one roster entry | 1467–1471 | glance | — | |
| 1473 | `attach!` | i | `findfirst` result, a roster index | 1473–1475 | glance | — | |
| 1473 | `attach!` | e | anon-fn arg, one roster entry | glance | glance | — | one-line body, nested scope of its own |
| 1479 | `attach!` | f | loop var, one claimed face | 1479–1480 | glance | — | |
| 1489 | `attach!` | w | the new `Writer` | 1489–1491 | glance | — | |
| 1491 | `attach!` | h | the new `DeviceHandle` | 1491–1507 | rename | `handle` | |
| 1525 | `detach!` | i | `findfirst` result, a roster index | 1525–1529 | glance | — | |
| 1525 | `detach!` | e | anon-fn arg, one roster entry | glance | glance | — | one-line body |
| 1556 | `stage!` | w | the harness writer | 1556–1558 | glance | — | |
| 1597 | `drain!` | f | the run's attached feed | 1597–1598 | glance | — | |
| 1599 | `drain!` | e | loop var, one roster entry | 1599–1601 | glance | — | |
| 1635 | `_replay_drain!` | e | loop var, one roster entry | 1635–1639 | glance | — | |
| 1636 | `_replay_drain!` | h | `_handle(e)`, the entry's handle | 1636–1638 | glance | — | |
| 1643 | `_replay_drain!` | i | the feed's record cursor | 1643–1659 | rename | `next` | mirrors the field `feed.next` it is copied from |
| 1643 | `_replay_drain!` | n | the feed's record count | 1643–1648 | glance | — | |
| 1650 | `_replay_drain!` | r | the due replay record | 1650–1656 | rename | `due` | `record` would collide with the field `.record` accessed as `r.record` |
| 1666 | `_discard_staged!` | w | Writer, the writer whose batch drops | param | rename | `writer` | |
| 1670 | `_discard_staged!` | i | comprehension, a mask index | glance | glance | — | one-line comprehension |
| 1715 | `_writer_status` | a | WriterAccount, the writer's account | param | glance | — | |
| 1728 | `_status` | i | destructure, the roster position | 1728–1730 | glance | — | |
| 1728 | `_status` | e | destructure, the roster entry | 1728–1730 | glance | — | |
| 1729 | `_status` | t | `get(plane.run_tasks,…)`, a Task | 1729–1730 | glance | — | a `Task`, not spec's `t` |
| 1762 | `logged` | L | the run's snapshot log | 1762–1769 | rename | `log` | alternative considered: `snap_log`, to avoid shadowing `Base.log` |
| 1766 | `logged` | s | loop var, one retained snapshot | 1766–1767 | glance | — | a `Snapshot`, not spec's state `s` |
| 1792 | `trace` | t | the run's `Trace` object | 1792–1797 | glance | — | a `Trace`, not spec's time `t` |
| 1814 | `state` | ci | the component index | 1814–1822 | survivor(ci) | — | |
| 1816 | `state`'s inner `_tier` | i | the component index | param | glance | — | one-line inner fn |
| 1817 | `state`'s inner `_decls` | i | the component index | param | glance | — | one-line inner fn |
| 1819 | `state` | i | loop var, a component index below `ci` | 1819–1820 | glance | — | |

### `src/localization.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 17 | `_grid_time` | k | Int, the frame index | param | glance | — | one-line body |
| 33 | `frame!` | k | Int, the frame index | param | glance | — | used once, one line from the signature |
| 50 | `_localized_frame!` | n | the tracked event count | 50–130 | rename | `nevents` | consistent with `event_phase!`'s `n` |
| 51 | `_localized_frame!` | x₀ | the segment-start retained state | 51–100 | survivor(x) | — | decorated `x(t_seg)` variant |
| 56 | `_localized_frame!` | h′ | the remainder-segment duration | 56–152 | survivor(h) | — | decorated remainder-of-`h` variant |
| 70 | `_localized_frame!` | i | loop var, the event index (trigger) | 70–72 | glance | — | |
| 80 | `_localized_frame!` | i | loop var, the event index (budget warn) | 80–83 | glance | — | |
| 107 | `_localized_frame!` | i | loop var, the event index (validation) | 107–109 | glance | — | |
| 130 | `_localized_frame!` | i | loop var, the event index (root-find) | 130–132 | glance | — | |
| 129 | `_localized_frame!` | θ★ | the earliest crossing parameter | 129–152 | survivor(θ) | — | |
| 173 | `_trial!` | θ | Float64, the trial position | param | survivor(θ) | — | |
| 173 | `_trial!` | h′ | the remainder-segment duration | param | survivor(h) | — | |
| 193 | `_crossing` | i | Int, the triggered event's index | param | rename | `event_index` | |
| 193 | `_crossing` | σ₀ | Float64, the left bracket guard value | param | survivor(σ) | — | |
| 193 | `_crossing` | σ₁ | Float64, the right bracket guard value | param | survivor(σ) | — | |
| 193 | `_crossing` | h′ | the remainder-segment duration | param | survivor(h) | — | |
| 205 | `_crossing` | ε | the half-width convergence target | 205–215 | rename | `half_width` | |
| 207 | `_crossing` | j | the ITP iteration counter | 207–222 | rename | `iter` | |
| 212 | `_crossing` | s | the ITP direction sign | 212–216 | glance | — | a sign value, not spec's state `s` |
| 213 | `_crossing` | δ | the truncation half-width | 213–214 | glance | — | |
| 215 | `_crossing` | r | the projection radius | 215–216 | glance | — | |
| 216 | `_crossing` | θ | the trial position | 216–219 | survivor(θ) | — | |
| 220 | `_crossing` | σθ | the guard value at trial θ | 220–221 | survivor(σ) | — | decorated `σ(θ)` variant |

### `src/deployment.jl`

| line | function | name | type or role | span | class | proposal | note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 22 | `_as_int` | r | Rational, the exact value tested | param | glance | — | one-line body |
| 28 | `_prime_powers` | n | Int, the integer to factor | param | rename | `denom` | not §5.2's `N` |
| 30 | `_prime_powers` | m | the remaining cofactor | 30–39 | rename | `remaining` | an `m` cofactor is not §5.2's mode state |
| 30 | `_prime_powers` | q | the trial divisor | 30–37 | rename | `divisor` | |
| 33 | `_prime_powers` | e | the prime's exponent accumulator | 33–35 | glance | — | |
| 55 | `_grid_report` | k | destructure, an anchor's position (periods) | 55–56 | glance | — | |
| 58 | `_grid_report` | k | destructure, an anchor's position (offsets) | 58–60 | glance | — | |
| 67 | `_grid_report` | i | loop var, the pool-entry index | 67–87 | rename | `entry_index` | |
| 70 | `_grid_report` | g | the leave-one-out gcd | 70–74 | glance | — | |
| 70 | `_grid_report` | j | comprehension, an excluded pool index | glance | glance | — | one-line comprehension |
| 72 | `_grid_report` | r | the integer refinement factor | 72–87 | rename | `factor` | matches `GridEntry`'s refinement-factor field |
| 81 | `_grid_report` | τ | the anchor's offset | 81–83 | survivor(τ) | — | |
| 81 | `_grid_report` | T | the anchor's period | 81–83 | survivor(T) | — | see Questions |
| 89 | `_grid_report` | q | comprehension, a prime factor | glance | glance | — | |
| 89 | `_grid_report` | e | comprehension, its power | glance | glance | — | |
| 90 | `_grid_report` | i | inner comprehension, a supplying pool index | glance | glance | — | |
| 177 | `bind_schedule` | h | Float64/nothing, the continuous step | param | survivor(h) | — | positional, not a keyword here |
| 238 | `bind_schedule` | D | the anchor's divisor | 238–248 | survivor(D) | — | |
| 243 | `bind_schedule` | Φ | the anchor's phase | 243–248 | survivor(Φ) | — | |
| 261 | `bind_schedule` | D | the component's divisor | 261–263 | survivor(D) | — | rebound per iteration |
| 261 | `bind_schedule` | Φ | the component's phase | 261–263 | survivor(Φ) | — | rebound per iteration |
| 331 | `Deployment` | ws | the accumulated warnings | 331–368 | rename | `raised` | collides with the module fn `warnings` |
| 349 | `Deployment` | g | the grid attribution report | 349–361 | rename | `grid` | mirrors the field `bound.grid`/`d.grid` it is copied from |
| 358 | `Deployment` | u | the grid utilization factor (min D) | 358–361 | glance | — | not spec's input `u` |
| 383 | `Base.hash(::Deployment,…)` | d | the deployment being hashed | 383–386 | glance | — | |
| 395 | `warnings(d::Deployment)` | d | the deployment | param | glance | — | one-line body |

## Collisions

- `d::Deployment` (`sim.jl:185`) → `artifact`: collides with the module fn
  `deployment`.
- `b::Build` (`sim.jl:209`) → `artifact`: collides with the module fn `build`.
- `b::AbstractBinding` (`sim.jl:1461`, `attach!`) → `new_binding`: collides
  with the module fn `binding`, called in this same function at line 1470
  (`binding(_handle(e))`).
- `ws` (`deployment.jl:331`, `Deployment`) → `raised`: collides with the
  module fn `warnings`.
- `n` (`sim.jl:536`, `event_phase!`) → `nevents`: the natural `count` collides
  with the field `es.count`, read and written throughout the same function.
- `i` (`sim.jl:613`, `_nonfinite`) → `flat_index`: the natural `index`
  collides with the field `cur.index`, assigned two lines below.
- `r` (`sim.jl:1650`, `_replay_drain!`) → `due`: the natural `record` would
  collide with the field `.record`, read as `r.record` in the same statement.
- `L` (`sim.jl:1762`, `logged`) → `log`: no in-function collision, but shadows
  `Base.log`; alternative considered: `snap_log`.

## Neighbours

`src/sim.jl`: `ex` (the compiled `Executor`, e.g. `evaluate!(ex::Executor)`
and the four `_round!(ex::Executor,…)` methods); `lc` (`@atomic
ctl.lifecycle`, read at the top of most lifecycle-gated entries); `cur`
(`sim.exec.cursor`); `act` (`activation(d.build, T)`); `run` (the freshly
built `Run` local in the `Simulation` constructor); `te` (the validated
`t_end`, `_t_end_frame`/`_bind_policy`); `nf` (the frame count, `step!`);
`ct`/`e_ct` (the calling-task roster index/entry, `_run_body!`); `egc` (the
`EmptyGreedyClaim` warning, `attach!`); `bn` (runtime bundle field names,
`_species`); `s1` (`stage1` port names, `_species`); `hb`, `ts` (heartbeat and
task state, `_writer_status`).

`src/localization.jl`: `es` (`sim.exec.events`, bound at the top of every
event-touching function); `lo`, `hi` (the ITP bracket endpoints, `_crossing`);
`σlo`, `σhi` (the bracket's guard values, `_crossing`); `xh`, `xf`, `xt` (the
ITP midpoint, regula-falsi point and truncated trial point, `_crossing`);
`nmax` (the iteration cap, `_crossing`).

`src/deployment.jl`: `h_r`, `Δt_r`, `n_i`, `Δtb` (validated/derived grid
quantities, `bind_schedule`); `Dk`, `Φk` (per-anchor divisor/phase arrays,
`bind_schedule`); `D_c`, `Φ_c`, `Δt_c` (per-component arrays, `_gates`); `k0`,
`n_ok` (the diagnostics checkpoint and the `N_base` sanity flag,
`bind_schedule`).

## Questions

- `deployment.jl:81`'s local `T` (and the `Anchor.T` field it is read from)
  denotes the anchor's *period* — spec:4557 and spec:11771 write the anchor
  pair itself as `(T, τ)` with "`T = period(q)`". The survivor bullet names
  `T` only "as the scalar type," a different sense. This table treats
  anchor-period `T` as survivor(T) too, but the sweep's brief should say
  whether that second sense is meant to survive, or whether it needs its own
  name (e.g. `period`) so it is never confused with the scalar-type `T`
  elsewhere in the same file.
- `t₀` (the clock/trace origin) recurs as a parameter and local throughout
  `sim.jl`/`localization.jl` but is not itself in the survivor bullet's list;
  it is treated here as a decorated variant of survivor `t`, consistent with
  its use as the `Clock` and `TraceHeader` origin field. Flagging in case the
  sweep wants it recorded as its own survivor symbol rather than folded under
  `t`.
- `h′` (the remainder-segment length in `_localized_frame!`, `_trial!`,
  `_crossing`) is treated as a decorated variant of survivor `h`, though it is
  a fraction of a frame rather than "the base step" itself; flagged for the
  same reason as `t₀`.

## Coverage

All function definitions found in the three files (including named inner
closures and anonymous-function arguments) were read and tabulated; no
functions were skipped.
