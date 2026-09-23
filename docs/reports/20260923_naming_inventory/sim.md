# Naming inventory: src/sim.jl

Tip: f64b9f3. Sites flagged: 210. Renames: 119. Collisions: 14. Roster proposals: 1.

## Letters with more than one meaning in this file

- `t`: time (`_frames_to`, `_frame_at`, `_frame_slack`, `step!(sim; …)` line 1374), the clock bound `t_end` (`_t_bound`), tier (`_species` line 1285), task (`_register_tasks!` line 1186, `_status` line 1729), a `Trace` (`trace(sim)` line 1792) → every non-time site renamed below
- `h`: the step size, spec (`step!(sim, h)`, `_frames_to`, `_frame_slack`), the trace header (`replay!` line 937), a device handle (`attach!` line 1491, `_replay_drain!` line 1636) → header and handle sites renamed
- `e`: roster entry (most sites), the `Establish` marker (`_round!` line 510), a caught exception (`_species` line 1295) → roster entries become `entry`, the others renamed
- `f`: a face name (`_stop_faces`, `replay!`, `attach!`), the replay feed (`_replay_bound`, `_settle_mode!`, `drain!`) → feed sites renamed `feed`, face sites `face`
- `s`: a face symbol (`_stop_faces` line 270), a snapshot (`logged` line 1766); the spec reserves `s` for discrete state → both renamed
- `r`: the stop-face pair (`_stop_faces` line 295), the run (`live!`, `_settle_mode!`), a replay record (`_replay_drain!` line 1649) → the run and record sites renamed; the pair in a four-line method kept
- `a`: an address (`_stop_faces` line 280), a writer account (`_writer_status` line 1715) → renamed
- `b`: a `Build` (sugar `Simulation` line 209), a binding (`attach!` line 1461) → renamed
- `i`: loop index (most sites), a flat state index as a parameter (`_nonfinite`), a `findfirst` roster position (`attach!`, `detach!`) → non-loop sites renamed
- `n`: the event count (`event_phase!`), the record count (`_replay_drain!`) → renamed
- `entry` (a word, not a letter, but one name with three meanings): a roster entry (after the `e` renames), the structure's `ComponentEntry` (`_species` line 1284), the frame-entry boundary index (`_advance!` line 1211, `_wrap_step` line 1256) → the last two renamed
- `trc`: the caller's recording (`_compile_feed`, `replay!`) and the run's own trace (`_open_run!`, `drain!`, `_replay_drain!`) → split by role below

## `closed(run::Run)` — line 110

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 110 | `run` | param | the run whose record is asked about | collision | `run_state` (shares `Base.run`, not called in the file; see Questions) |

## `Simulation(d::Deployment, ::Type{T} = Float64; join_timeout = 5.0, chunk_size::Int = 16) where {T}` — line 185

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 185 | `d` | param | the deployment being materialized | rename | `deployment` |
| 185 | `T` | type param | the scalar | keep:typeparam | — |
| 191 | `diags` | local | the call's collected refusals | keep:roster | — |
| 196 | `act` | local | the activation at `T` the entries compile over | rename | `sim_activation` (`act` is not on the roster; `activation`, build.jl:913, is a function called on this very line) |
| 197 | `ex` | local | the compiled executor | rename | `exec` |
| 201 | `run` | local | the placeholder run | collision | `placeholder` (the docstring's word; shares `Base.run`, not called in the file) |

## `Simulation(b::Build, ::Type{T} = Float64; h, N_base, Δt_base, …, kw...) where {T}` — line 209

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 209 | `b` | param | the build being deployed | rename | `built` (`build` is a package function; `built` is build.jl's own word at line 746) |
| 209 | `T` | type param | the scalar | keep:typeparam | — |
| 209 | `h` | kwarg | the step size | keep:spec | — |
| 211 | `kw` | kwarg splat | the materialization's own keywords, passed on | rename | `keywords` |

## `Simulation(root::AbstractComponent, ::Type{T} = Float64; kw...) where {T}` — line 214

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 214 | `T` | type param | the scalar | keep:typeparam | — |
| 214 | `kw` | kwarg splat | every keyword, passed on | rename | `keywords` (alike with line 211) |

## `_t_bound(t, call::Symbol)` — line 234

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 234 | `t` | param | the unvalidated `t_end` value | rename | `t_end` (it is the `t_end` keyword's value, the refusal's `argument = :t_end`; `t` alone reads as the clock) |

## `_frame_slack(t::Real, h::Float64)` — line 247

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 247 | `t` | param | the time whose ulps set the slack | keep:spec | — |
| 247 | `h` | param | the step size | keep:spec | — |

## `_frames_to(t::Real, t₀::Real, h::Float64)` — line 248

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 248 | `t` | param | the time bound to reach | keep:spec | — |
| 248 | `t₀` | param | the origin | keep:spec | — |
| 248 | `h` | param | the step size | keep:spec | — |

## `_frame_at(t::Real, t₀::Real, h::Float64)` — line 252

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 252 | `t` | param | the time to floor onto a frame top | keep:spec | — |
| 252 | `t₀` | param | the origin | keep:spec | — |
| 252 | `h` | param | the step size | keep:spec | — |

## `_t_end_frame(sim::Simulation, te::Float64)` — line 253

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 253 | `te` | param | the policy's validated `t_end` | rename | `t_end` |

## `_stop_faces(layout::Layout, stop_on, diags::Vector{Diagnostic}; site::Symbol)` — line 261

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 261 | `diags` | param | the list the pass records into | keep:roster | — |
| 262 | `addrs` | destructure | the kept faces' compiled addresses | keep:roster | — |
| 263 | `f` | comprehension | a root input's face name | keep:glance | — |
| 267 | `out_faces` | local | the root's output faces, the refusal's `candidates` | rename | `candidates` (`out` abbreviates "output"; `output_faces` is a package function, assembly.jl:510) |
| 267 | `p`, `f` | comprehension | an address key's path and face | keep:glance | — |
| 269 | `f` | for | one requested face, as the caller spelled it (Symbol or String) | rename | `requested` |
| 270 | `s` | local | the requested face as a `Symbol`, read over 17 lines; `s` is the spec's discrete state | rename | `face` |
| 280 | `a` | local | the face's compiled root-cell address, read three times below | rename | `address` |

## `_stop_faces(layout::Layout, stop_on; site::Symbol)` — line 293

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 294 | `diags` | local | the call's collected refusals | keep:roster | — |
| 295 | `r` | local | the `(faces, addrs)` pair to return | keep:glance | — (a four-line method) |

## `_bind_policy(sim::Simulation, t_end, stop_on, site::Symbol)` — line 306

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 307 | `te` | local | the validated clock bound, beside the raw `t_end` | rename | `bound` (the `StopPolicy` docstring's "clock bound"; `t_end` is taken in scope by the raw value) |
| 308 | `addrs` | destructure | the faces' compiled addresses | keep:roster | — |

## `_record(sim::Simulation{T}, pol::StopPolicy, src::TerminationSource, residue::Vector{ResidueRecord}) where {T}` — line 369

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 369 | `T` | type param | the scalar | keep:typeparam | — |
| 369 | `pol` | param | the terminating advance's stop policy | rename | `policy` |
| 369 | `src` | param | the termination source | rename | `source` |

## `_stop_hit(sim::Simulation, pol::StopPolicy, addrs::Vector{Any})` — line 377

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 377 | `pol` | param | this advance's stop policy | rename | `policy` |
| 377 | `addrs` | param | the faces' compiled addresses | keep:roster | — |
| 379 | `snap` | local | the just-published snapshot | rename | `snapshot` |
| 380 | `i` | for | the face index | keep:index | — |

## `_assert_advanceable(sim::Simulation, op::Symbol)` — line 390

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 390 | `op` | param | the refused operation's name, the diagnostics' `op` field | rename | `operation` (see Questions: `op` mirrors the payload field) |
| 391 | `lc` | local | the lifecycle state, read four times | rename | `lifecycle_state` (`lifecycle`, sim.jl:323, is a package function) |

## `evaluate!(ex::Executor)` — line 424

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 424 | `ex` | param | the executor | rename | `exec` |

## `boundary!(sim::Simulation, tick::Int)` — line 448

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 449 | `cur` | local | the execution cursor | rename | `cursor` |

## `boundary_zero!(sim::Simulation)` — line 493

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 494 | `cur` | local | the execution cursor | rename | `cursor` |

## `_round!(ex::Executor, tick::Int)` — line 505

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 505 | `ex` | param | the executor | rename | `exec` |

## `_round!(ex::Executor, ::Nothing)` — line 507

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 507 | `ex` | param | the executor | rename | `exec` |

## `_round!(ex::Executor, e::Establish)` — line 510

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 510 | `ex` | param | the executor | rename | `exec` |
| 510 | `e` | param | the `ESTABLISH` marker in the tick's slot | rename | `tick` (every method names its parameters alike: the Int and `sim` methods call this slot `tick`, and `event_phase!` hands the marker through a `tick` parameter) |

## `event_phase!(sim::Simulation, tick)` — line 532

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 533 | `es` | destructure | the executor's event set, read over 40 lines | rename | `events` |
| 533 | `cur` | destructure | the execution cursor | rename | `cursor` |
| 536 | `n` | local | the event count | rename | `event_count` |
| 546 | `i` | for | the event index | keep:index | — |
| 551 | `path` | destructure | the event's component path | keep:spec | — (the rules' `path` exception) |

## `step!(sim::Simulation, h)` — line 588

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 588 | `h` | param | the step to advance by | keep:spec | — |

## `_check_finite!(sim::Simulation)` — line 602

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 603 | `x` | local | the flat continuous-state buffer | keep:spec | — |
| 604 | `i` | for | the flat index | keep:index | — |

## `_nonfinite(sim::Simulation, i::Int)` — line 613

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 613 | `i` | param | the flat state index that went nonfinite, read 10 lines below; a parameter, not a loop index | rename | `flat_index` |
| 614 | `ex` | local | the executor | rename | `exec` |
| 616 | `b` | lambda | one component's `x` range | keep:glance | — |
| 617 | `cur` | local | the execution cursor | rename | `cursor` |
| 620 | `names` | local | the owner's state leaf names | collision | `x_leaf_names` (shares `Base.names`, not called in the file; `leaf_names`, leaves.jl:69, is called on this line, so it is no proposal) |

## `_open_trajectory!(sim::Simulation, t₀::Float64)` — line 640

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 640 | `t₀` | param | the trajectory's origin | keep:spec | — |
| 647 | `e` | for | a roster entry | rename | `entry` |

## `_check_recording(call::Symbol, trace, log, log_every, log_max)` — line 658

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 658 | `trace` | param | the door's unvalidated `trace` keyword value | collision | `trace_switch` (`trace`, sim.jl:1790, not called in this scope; §11.5's "kill switch") |
| 658 | `log` | param | the door's unvalidated `log` keyword value | collision | `log_switch` (shares `Base.log`, not called in the file; §11.2's "plain switch") |
| 659 | `diags` | local | the collected refusals | keep:roster | — |
| 660 | `name` | local-function param | the refused keyword's name, the payload's `argument` | rename | `argument` |
| 660 | `v` | local-function param | the refused value | keep:glance | — (a one-line local function) |

## `_open_run!(sim::Simulation{T}, header, schemas, feed, trace::Bool, log::Bool, log_every::Int, log_max) where {T}` — line 678

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 678 | `T` | type param | the scalar | keep:typeparam | — |
| 679 | `trace` | param | the validated trace switch | collision | `trace_switch` (`trace`, sim.jl:1790, not called in this scope) |
| 679 | `log` | param | the validated log switch | collision | `log_switch` (shares `Base.log`, not called in the file) |
| 680 | `trc` | local | the new run's trace, or `nothing` | rename | `run_trace` |

## `init!(sim::Simulation{T}, condition = fragment(); t0::Real = 0.0, trace = true, log = true, log_every = 1, log_max = 65536) where {T}` — line 770

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 770 | `T` | type param | the scalar | keep:typeparam | — |
| 770 | `condition` | param | the authored condition overlay | collision | `authored` (`condition`, conditions.jl, the fragment generic; not called in this scope; the docstring's "from an *authored* condition") |
| 770 | `t0` | kwarg | the origin, as given | keep:spec | — (the API keyword for `t₀`) |
| 770 | `trace` | kwarg | the trace switch | collision | none: the API keyword (Appendix B); `trace`, sim.jl:1790, is not called in this scope. See Questions |
| 771 | `log` | kwarg | the log switch | collision | none: the API keyword (Appendix B); shares `Base.log`, not called. See Questions |
| 772 | `ctl` | local | the simulation's control | rename | `control` |
| 773 | `lc` | local | the lifecycle state | rename | `lifecycle_state` |

## `_compile_feed(sim::Simulation{T}, trc::Trace{T}) where {T}` — line 813

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 813 | `T` | type param | the scalar | keep:typeparam | — |
| 813 | `trc` | param | the recording offered to replay | rename | `recording` |
| 814 | `f` | comprehension | a root input's face name | keep:glance | — |
| 815 | `diags` | local | the collected refusals | keep:roster | — |

## `_compile_feed(sim::Simulation{Ts}, trc::Trace{Tt}) where {Ts,Tt}` — line 824

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 824 | `trc` | param | the recording at another scalar | rename | `recording` (alike with line 813) |
| 824 | `Ts`, `Tt` | type param | the simulation's and the trace's scalars | keep:typeparam | — |

## `replay!(sim::Simulation{T}, trc::Trace{T}; to_boundary = nothing, to_time = nothing, t_end = Inf, stop_on = (), trace = true, log = true, log_every = 1, log_max = 65536) where {T}` — line 895

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 895 | `T` | type param | the scalar | keep:typeparam | — |
| 895 | `trc` | param | the recording to re-drive, read over 70 lines | rename | `recording` (the docstring's word) |
| 896 | `trace` | kwarg | the trace switch | collision | none: the API keyword (Appendix B); `trace`, sim.jl:1790, not called in this scope. See Questions |
| 897 | `log` | kwarg | the log switch | collision | none: the API keyword; shares `Base.log`, not called. See Questions |
| 898 | `ex` | destructure | the executor, read over 50 lines | rename | `exec` |
| 898 | `ctl` | destructure | the simulation's control | rename | `control` |
| 899 | `lc` | local | the lifecycle state | rename | `lifecycle_state` |
| 923 | `t₀` | local | the header's origin | keep:spec | — |
| 932 | `pol` | destructure | this advance's stop policy, read at line 965 | rename | `policy` |
| 932 | `addrs` | destructure | the faces' compiled addresses | keep:roster | — |
| 937 | `h` | local | the trace header, read over 25 lines; `h` is the spec's step size | rename | `header` |
| 939 | `ci` | for | the component index | keep:index | — |
| 942 | `ci` | for | the component index | keep:index | — |
| 945 | `f`, `v` | for (destructure) | a root input's face and recorded value, consumed on the next line | keep:glance | — |

## `live!(sim::Simulation)` — line 995

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 997 | `r` | local | the current run | rename | `run_state` (`run` shares `Base.run`; alike with `closed` and `_settle_mode!`) |

## `run!(sim::Simulation; t_end = Inf, stop_on = ())` — line 1051

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1053 | `pol` | destructure | this advance's stop policy | rename | `policy` |
| 1053 | `addrs` | destructure | the faces' compiled addresses | keep:roster | — |

## `_replay_bound(sim::Simulation, upto::Int)` — line 1070

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1071 | `f` | local | the run's replay feed | rename | `feed` (`f` is a face everywhere else in the file) |

## `_settle_mode!(sim::Simulation)` — line 1082

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1083 | `r` | local | the current run | rename | `run_state` |
| 1084 | `f` | local | the run's replay feed | rename | `feed` |

## `_run_body!(sim::Simulation, pol::StopPolicy, addrs::Vector{Any}, upto::Int, target::Int)` — line 1103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1103 | `pol` | param | this advance's stop policy | rename | `policy` |
| 1103 | `addrs` | param | the faces' compiled addresses | keep:roster | — |
| 1103 | `target` | param | the `t_end` frame | rename | `t_end_frame` (the name `_advance!` and `step!` give the same value) |
| 1104 | `ctl` | destructure | the simulation's control | rename | `control` |
| 1107 | `term` | destructure | the §13.5 source that ended the run, or `nothing` | rename | `source` |
| 1107 | `err_src` | destructure | the `LoopError` source off a throw | rename | `error_source` |
| 1113 | `ct` | local | the position of the calling-task device among the live entries | rename | `inline_index` |
| 1113 | `e` | lambda | a live entry | keep:glance | — |
| 1124 | `e_ct` | local | the calling-task device's entry, read four times | rename | `inline_entry` |
| 1125 | `i` | comprehension | the entry index | keep:index | — |
| 1142 | `err` | catch | the loop-side exception | roster? | `err` (see Roster proposals) |

## `_reset_accounts!(sim::Simulation)` — line 1176

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1177 | `e` | for | a roster entry | rename | `entry` |

## `_register_tasks!(plane::DataPlane, entries::Vector{RosterEntry}, tasks::Vector{Task})` — line 1185

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1186 | `e` | for (destructure) | a roster entry | rename | `entry` (one-line method, but `e` means three things in the file) |
| 1186 | `t` | for (destructure) | the entry's task; `t` is time | rename | `task` |

## `_advance!(sim::Simulation, pol::StopPolicy, addrs::Vector{Any}, upto::Int, t_end_frame::Int)` — line 1204

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1204 | `pol` | param | this advance's stop policy | rename | `policy` |
| 1204 | `addrs` | param | the faces' compiled addresses | keep:roster | — |
| 1206 | `ctl` | destructure | the simulation's control | rename | `control` |
| 1207 | `nb` | local | the base-tick stride | rename | `N_base` (the spec's symbol, the `Deployment` keyword) |
| 1208 | `adv` | local | the frames advanced, returned | rename | `advanced` |
| 1211 | `entry` | local | the frame-entry boundary index, read in the catch 35 lines below | rename | `entry_boundary` (`entry` is a roster entry elsewhere in the file; the comment's own words) |
| 1221 | `k` | local | the frame index just entered, the spec's `tₖ` subscript | keep:index | — |
| 1236 | `err` | catch | the exception out of the frame | roster? | `err` |

## `_wrap_step(sim::Simulation, entry::Int, err)` — line 1256

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1256 | `entry` | param | the frame-entry boundary index, the replay pointer | rename | `entry_boundary` |
| 1256 | `err` | param | the caught exception | roster? | `err` |
| 1260 | `cur` | local | the execution cursor | rename | `cursor` |

## `_species(::Simulation, err)` — line 1272

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1272 | `err` | param | the caught exception | roster? | `err` |

## `_species(::Simulation, err::DiagnosticError{<:Diagnostic})` — line 1273

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1273 | `err` | param | the fail-fast carrier | roster? | `err` |

## `_species(sim::Simulation, err::FieldError)` — line 1280

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1280 | `err` | param | the author-facing `FieldError` | roster? | `err` |
| 1281 | `cur` | local | the execution cursor | rename | `cursor` |
| 1283 | `ci` | destructure | the cursor's component index | keep:index | — |
| 1283 | `fam` | destructure | the cursor's stage-function family, read six times | rename | `family` (the payload's own field) |
| 1284 | `entry` | local | the structure's `ComponentEntry` | rename | `comp_entry` (`entry` is a roster entry elsewhere in the file) |
| 1285 | `c` | destructure | the component instance, read over 6 lines | rename | `comp` |
| 1285 | `t` | destructure | the tier; `t` is time | rename | `tier` |
| 1286 | `s1` | local | the stage-1 port names, as a tuple | rename | `stage1_ports` (`bundle_names`' own parameter name, declare.jl:305) |
| 1289 | `bn` | local | the bundle's legal field names | rename | `legal_names` (the payload's `legal`; `bundle_names`, declare.jl:305, is called on the lines that bind it) |
| 1295 | `e` | catch | the exception out of the name read | rename | `err` (alike with every other catch in the file; `e` is a roster entry) |

## `_host_boundary_zero!(sim::Simulation)` — line 1315

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1318 | `err` | catch | the exception out of boundary zero | roster? | `err` |

## `step!(sim::Simulation; frames = nothing, t_plus = nothing, t_end = Inf, stop_on = ())` — line 1359

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1361 | `ctl` | local | the simulation's control | rename | `control` |
| 1367 | `nf` | local | the frame count this call asks for | rename | `frame_count` (`frames` is the keyword in scope) |
| 1374 | `t` | local | the clock time at the frame top | keep:spec | — |
| 1377 | `pol` | destructure | this advance's stop policy | rename | `policy` |
| 1377 | `addrs` | destructure | the faces' compiled addresses | keep:roster | — |
| 1380 | `term` | destructure | the §13.5 source that fired, or `nothing` | rename | `source` (alike with `_run_body!`) |
| 1380 | `adv` | destructure | the frames advanced, returned | rename | `advanced` |
| 1380 | `err_src` | destructure | the `LoopError` source off a throw | rename | `error_source` |
| 1387 | `err` | catch | the loop-side exception | roster? | `err` |

## `attach!(sim::Simulation, dev::AbstractDevice, b::AbstractBinding; should_abort::Bool = false)` — line 1461

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1461 | `dev` | param | the device being rostered | rename | `device` (`dev` is not on the roster) |
| 1461 | `b` | param | the binding it is rostered under, read over 40 lines | rename | `new_binding` (`binding`, devices.jl:207, is the natural noun but is called in this scope at line 1470 for the incumbent's; the role name) |
| 1467 | `e` | for | a roster entry | rename | `entry` |
| 1473 | `i` | local | the incumbent calling-task holder's roster position | rename | `holder` |
| 1473 | `e` | lambda | a roster entry | keep:glance | — |
| 1479 | `f` | for | a claimed face | rename | `face` (read three times in a two-line body; `f` is a feed elsewhere) |
| 1485 | `rg` | local | the compiled read gather, or `nothing` | rename | `gatherer` (the `DeviceHandle` field it fills) |
| 1487 | `id` | local | the device's stable id, read three times | rename | `device_id` |
| 1489 | `w` | local | the entry's compiled writer | rename | `writer` |
| 1490 | `diag` | local | the device's diagnostic cell | collision | `diag_cell` (the rules bar `diag`: it shadows `LinearAlgebra.diag`, live in trim.jl; not called in this scope) |
| 1491 | `h` | local | the new device handle, returned; `h` is the step size | rename | `handle` |
| 1502 | `egc` | local | the `EmptyGreedyClaim` warning | rename | `empty_claim` |

## `detach!(sim::Simulation, dev::AbstractDevice)` — line 1522

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1522 | `dev` | param | the device to release | rename | `device` (alike with `attach!`) |
| 1525 | `i` | local | the entry's roster position, read three times | rename | `slot` (`position` is a Base function) |
| 1525 | `e` | lambda | a roster entry | keep:glance | — |
| 1527 | `e` | comprehension | a roster entry | keep:glance | — |

## `stage!(sim::Simulation, pairs::Pair...)` — line 1554

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1554 | `pairs` | param | the staged `face => value` writes | collision | `writes` (shares `Base.pairs`, not called in the file; the docstring's "a batch of root-input writes") |
| 1556 | `w` | local | the harness writer | rename | `harness` |

## `drain!(sim::Simulation)` — line 1586

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1588 | `cur` | local | the execution cursor | rename | `cursor` |
| 1595 | `trc` | local | the run's trace, or `nothing` | rename | `run_trace` |
| 1597 | `f` | local | the run's replay feed | rename | `feed` |
| 1599 | `e` | for | a roster entry | rename | `entry` |

## `_replay_drain!(sim::Simulation, feed::ReplayFeed)` — line 1632

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1635 | `e` | for | a roster entry | rename | `entry` |
| 1636 | `h` | local | the entry's device handle, read twice; `h` is the step size | rename | `handle` |
| 1643 | `i` | destructure | the cursor into the feed's records, the `while` loop's index | keep:index | — |
| 1643 | `n` | destructure | the record count | rename | `record_count` |
| 1649 | `r` | local | the current `ReplayRecord`, read four times | rename | `replay_record` (`r.record` is its `TraceBatch`, so `record` alone would read `record.record`) |
| 1654 | `trc` | local | the run's trace, or `nothing` | rename | `run_trace` |

## `_discard_staged!(w::Writer, cell::DiagCell, frame::Int)` — line 1666

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1666 | `w` | param | the writer whose cell is taken | rename | `writer` |
| 1670 | `i` | comprehension | the mask position | keep:index | — |

## `publish!(sim::Simulation)` — line 1693

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1694 | `ctl` | local | the simulation's control | rename | `control` |
| 1696 | `snap` | local | the snapshot being published | rename | `snapshot` |

## `_writer_status(who::String, a::WriterAccount, hb, ts)` — line 1715

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1715 | `a` | param | the writer's account, read four times | rename | `account` |
| 1715 | `hb` | param | the heartbeat, or `nothing` | rename | `heartbeat` |
| 1715 | `ts` | param | the task state, or `nothing` | rename | `task_state` (`_task_state` is the function; the underscore keeps them apart) |
| 1716 | `ws` | local | the writer's status record, returned | rename | `status` |

## `_status(sim::Simulation)` — line 1725

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1727 | `ws` | local | the per-writer status records | rename | `statuses` |
| 1728 | `i` | for (destructure) | the entry index | keep:index | — |
| 1728 | `e` | for (destructure) | a roster entry | rename | `entry` |
| 1729 | `t` | local | the entry's run task, or `nothing`; `t` is time | rename | `task` |

## `logged(sim::Simulation)` — line 1760

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1762 | `L` | local | the run's snapshot log, read five times | rename | `snapshot_log` (`log` would shadow `Base.log`; no rule permits a capital `L`) |
| 1763 | `out` | local | the retained snapshots, returned | rename | `retained` (the docstring's "retained snapshots") |
| 1766 | `s` | for | a retained middle snapshot; `s` is the spec's discrete state | rename | `snapshot` |

## `trace(sim::Simulation{T}) where {T}` — line 1790

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1790 | `T` | type param | the scalar | keep:typeparam | — |
| 1791 | `lc` | local | the lifecycle state | rename | `lifecycle_state` |
| 1792 | `t` | local | the run's trace, read five times; `t` is time | rename | `run_trace` |

## `port(sim::Simulation, path::String, name::Symbol)` — line 1806

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1806 | `path` | param | the component path | keep:spec | — (the rules' `path` exception) |

## `state(sim::Simulation{T}, path::String) where {T}` — line 1813

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1813 | `T` | type param | the scalar | keep:typeparam | — |
| 1813 | `path` | param | the component path | keep:spec | — (the rules' `path` exception) |
| 1814 | `ci` | local | the component index | keep:index | — |
| 1816 | `i` | local-function param | a component index | keep:index | — |
| 1817 | `i` | local-function param | a component index | keep:index | — |
| 1818 | `off` | local | the flat offset of the component's `x` block | rename | `x_offset` (the spec's `x_offs` names the per-component vector; this is one entry of it) |
| 1819 | `i` | for | the component index | keep:index | — |

## `modes(sim::Simulation, path::String)` — line 1826

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1826 | `path` | param | the component path | keep:spec | — (the rules' `path` exception) |

## Collisions

| line | local | shares a name with | defined at | called in the binding scope |
| --- | --- | --- | --- | --- |
| 110 | `run` (`closed`) | `Base.run` | Base | no; never called in the file |
| 201 | `run` (`Simulation`) | `Base.run` | Base | no |
| 620 | `names` (`_nonfinite`) | `Base.names` | Base | no; never called in the file |
| 658 | `trace` (`_check_recording`) | `trace(sim)` | sim.jl:1790 | no |
| 658 | `log` (`_check_recording`) | `Base.log` | Base | no; never called in the file (`log!` is another function) |
| 679 | `trace` (`_open_run!`) | `trace(sim)` | sim.jl:1790 | no |
| 679 | `log` (`_open_run!`) | `Base.log` | Base | no |
| 770 | `condition` (`init!`) | the fragment generic `condition` | conditions.jl:64 (`function condition end`) | no |
| 770 | `trace` (`init!` keyword) | `trace(sim)` | sim.jl:1790 | no |
| 771 | `log` (`init!` keyword) | `Base.log` | Base | no |
| 896 | `trace` (`replay!` keyword) | `trace(sim)` | sim.jl:1790 | no |
| 897 | `log` (`replay!` keyword) | `Base.log` | Base | no |
| 1490 | `diag` (`attach!`) | `LinearAlgebra.diag` | LinearAlgebra, `using`'d at Cadence.jl:3 | no in `attach!`; called in trim.jl |
| 1554 | `pairs` (`stage!`) | `Base.pairs` | Base | no; never called in the file |

Two sites near a collision are coded `rename`, since the local itself is free and only the natural proposal is taken: `act` (line 196; `activation` is called on its own line) and `b` in `attach!` (line 1461; `binding` is called at line 1470 for the incumbent, hence `new_binding`). `bn` (line 1289) and `names` (line 620) steer clear of `bundle_names` and `leaf_names`, both called where those locals are bound.

## Roster proposals

| name | sites in this file | abbreviates | note |
| --- | --- | --- | --- |
| `err` | 8 (lines 1142, 1236, 1256, 1272, 1273, 1280, 1318, 1387), 9 with the `catch e` at line 1295 renamed to it | error, a caught exception | `error` is a Base function, so the full word is barred. `err` is already the file's dominant catch name, and the package has 8 `catch err` against 9 `catch e` (build.md proposes `exception` for one `e`). One word should win across the package |

## Questions

- The brief's collision test is "a Base function the file calls"; the rules' is "reached from Base". `run`, `names`, `log` and `pairs` pass the brief and fail the rules. They are coded `collision` here. If only called functions count, they turn back to `keep`, though `placeholder` (line 201) and the `_switch` names (lines 658, 679) still read better than the originals.
- The `trace` and `log` keywords of `init!` and `replay!` are Appendix B's API names, so they cannot be renamed, yet they collide under the rules (`trace` with the package's own `trace(sim)`). The rules should say that an API keyword parameter is exempt, the way they exempt `path`.
- The brief's regex `^(function )?name\(` misses zero-method declarations such as `function condition end` (conditions.jl:64). `condition` in `init!` was found only by reading. Other groups should add `function name end` to the sweep.
- The brief's own example proposes `activation` for `act` and `schedule` for `sch` in build.jl. `activation` is a package function (build.jl:913), and `schedule` is `Base.schedule`. That example breaks the collision rule.
- "Every method names its parameters alike" collides with dispatch on distinct types in the three `Simulation` constructors (`d::Deployment`, `b::Build`, `root::AbstractComponent`). This report proposes `deployment`, `built`, `root`, one noun per type. The rule should say whether this is compliant, or whether one role name such as `source` is wanted.
- `stage!(sim, pairs...)` shares its parameter name with `stage!(h::DeviceHandle, pairs...)` at devices.jl:228 (group F). The rename to `writes` must land in both files together to keep the methods alike.
- `op` (line 390) mirrors the `op` field of `MissingInit` and `ServiceLifecycle`. The proposal `operation` makes the call read `op = operation`. The alternative is to put `op` on the roster, as the payload's field name.
- `ex`, `ctl`, `cur` and `pol` are the file's most frequent unrostered abbreviations (7, 6, 7 and 7 sites). This report renames them to the roster's `exec` and to the full words `control`, `cursor` and `policy`, rather than proposing them for the roster. None of the full words collides.
- `run_state` is proposed for a `Run` wherever `run` would shadow `Base.run` (`closed`, `live!`, `_settle_mode!`). The docstrings say "the run". If `Base.run` is ruled out of scope, `run` is the better name at all three sites.
