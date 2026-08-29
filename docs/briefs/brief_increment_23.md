# Increment 23 — the input trace (§11.5) and replay (§12.7)

> **Historical record.** Written before the 2026-08-29 spin-off, so the paths
> below are the old layout: the worktree `~/.julia/dev/Flight.jl-core-redesign-2`
> is now this repository, `prototypes/kernel/` is its root, `README.md`, `MAP.md`
> and `NOTES.md` are `docs/kernel_guide.md`, `docs/kernel_map.md` and
> `docs/kernel_notes.md`, and the design documents live in `docs/`.

Worktree `~/.julia/dev/Flight.jl-core-redesign-2`, branch `core-redesign-2`,
tip at launch `0cb491e0`. Prototype in `prototypes/kernel/`; read its
`README.md` first, then `MAP.md`/`NOTES.md` on demand. Spec sections to read
in full before touching code: §11.5 (lines ~5345–5438 of
`docs/notes/design/framework_spec.md`), §12.7 (~6643–6796), §14.5 (the
capture placement), §12.6 (the lifecycle and its `replay!` sentence),
Appendix C rows `ReplayHeaderMismatch`, `ReplaySchemaMismatch`,
`ReplayUnknownFace`, `ReplayDiscardedStaging`; decisions D-029, D-038, D-101,
D-176 in `framework_decisions.md`.

Run the suite in the foreground with a 600 s timeout, never in the
background: `julia --project=. test/runtests.jl` from `prototypes/kernel`.
One commit per stage, suite green at each. Commit subject: one sentence, no
body, no attribution. Do not push.

## Scope

**In.** The trace register (types, the constructor kill switch `trace = true`,
the header capture at `init!`, sparse recording at the drain, the `trace(sim)`
accessor); the replay entry `replay!(sim, trc; to_boundary, t_end, stop_on)`
as the ordinary loop with D-101's two substitutions; the four replay kinds;
the up-front validation + normalization pass; re-recording under replay;
continuation after replay.

**Out.** §13.4 (the cursor, `StepError`, the nonfinite sweep — increment 24);
disk serialization of the trace; the what-if register beyond what falls out
for free (a changed parameter replays deterministically — one test, no API);
§10.7 pacing; did-you-mean ranking; the header's provenance payload fields
(README's payload-shortfall list gains them, D-216 pattern).

## The shapes

New file `src/trace.jl`, included after `roster.jl` and before `sim.jl`
(`init!`/`drain!` in `sim.jl` call into it; it needs `Writer`, `Batch`,
`Layout`, `_apply!`, `scatter!`/`gather`).

```julia
# §11.5: the header — the full initial state as resolved values, never the overlay
struct TraceHeader{T}
    x::Vector{T}                      # a copy of xbuf after apply!
    s::Vector{Any}                    # per component: sstores[ci][] (deepcopy) or nothing
    m::Vector{Any}                    # likewise for the mode stores
    root_inputs::Vector{Pair{Symbol,Any}}   # face => the resolved value in the cell
    schemas::Vector{Pair{String,Vector{Symbol}}}   # writer tag => face-name-by-position
    #   tags: `_who(entry)` for roster entries, "harness" for the register — the §11.8 names
    deployment::@NamedTuple{t₀::T, Δt_base::Float64, h::Float64, n::Int, method::Symbol,
                            localization_tol::Float64, localization_budget::Int,
                            firing_budget::Int, t_end::Union{Nothing,Float64},
                            stop_on::Vector{Symbol}}
    #   method = nameof(typeof(sim.stepper)); t_end/stop_on are the *effective* pair at init!
    #   (the constructor's — init! predates run!'s overrides; record what init! knows)
    layout::@NamedTuple{sizes::Vector{Pair{DataType,Int}}, root_faces::Vector{Symbol},
                        paths::Vector{String}, stypes::Vector{Any}, mtypes::Vector{Any}}
    #   the structural fingerprint replay compares: the layout's cell sizes, the root
    #   input face list, the flat's component paths, and each store's value type
end

# one drained batch, sparse (D-176): position ⇒ value against the writer's schema
struct TraceBatch
    frame::Int                        # the frame ordinal it replays at (below)
    writer::Int                       # index into header.schemas
    entries::Vector{Pair{Int,Any}}    # only the masked positions
end

# what trace(sim) returns: a value, detached from the register
struct Trace{T}
    header::TraceHeader{T}
    batches::Vector{TraceBatch}       # in drain order: by frame, then by writer index
    frames::Int                       # frames drained since the header — the recording's length
end

# the Simulation's mutable holder (a new field `trace::TraceRegister`)
mutable struct TraceRegister
    enabled::Bool                     # the kill switch, fixed at construction
    header::Union{Nothing,TraceHeader}
    batches::Vector{TraceBatch}
    frames::Int
    feed::Union{Nothing,ReplayFeed}   # non-nothing while replay! drives the loop
end
```

**Frame ordinal.** The drain runs before `clock.step += 1`, so the batch
drained at the top of frame `k` is recorded with `frame = clock.step + 1 = k`.
Under replay the feed applies exactly the batches with `frame == clock.step + 1`.
`frames` counts drains since the header (one per frame), so the recording's
last frame is `trace.frames`; a trace with no batch in its last frames still
knows how long it ran. (This field is a small extension of §11.5's "header +
batches"; note it in the report.)

**Recording at the drain** — inside the drain thunk, so nothing boxes on the
frame path. `_drain_thunk(store, w, reg::TraceRegister, widx::Int)` closes over
the register and the writer's schema index; `_drain!` becomes

```julia
function _drain!(store, w::Writer, reg, widx)
    ref = @atomicswap w.cell.pending = nothing
    ref === nothing && return nothing
    batch = ref[]
    _apply!(store, w.addrs, batch)
    reg.enabled && _record!(reg, widx, batch)     # one small allocation per drained batch (§11.5)
    nothing
end
```

`_record!` scans `batch.mask` (a plain loop over `1:length(mask)`, the tuple
fields read by index; the one allocation is the `entries` vector plus its
boxed values) and pushes a `TraceBatch(reg_frame, widx, entries)`, where the
register's current frame was set by `drain!(sim)` before the thunks run
(`reg.frame = clock.step + 1`, a field on the register). `drain!(sim)` ends
with `reg.frames += 1` when enabled. Writer indices: the roster's entries in
attachment order, then the harness register last — the drain order, and the
order `schemas` is captured in. **The schema list only grows.** A roster
change is a stopped-sim point that recompiles the harness writer (its schema
changes) and may add or remove device writers; batches already recorded
reference the old indices. So `attach!`/`detach!` (and `init!`'s capture,
and `replay!`'s install, below) *append* the current writer set — every
roster entry in attachment order, then the harness — as fresh entries at the
end of `header.schemas`, and recompile every drain thunk with its new index.
Earlier entries stay, referenced by earlier batches. A run's `schemas` may
therefore carry superseded entries; the report notes it, and a
`live_writers::UnitRange{Int}` field on the register names the current ones.
Before the first `init!` there is no header, and `attach!` records nothing.

**Header capture in `init!`** — after `apply!(sim, plan)` and the clock
writes, before `boundary_zero!`, exactly §14.5's placement: `_reset!(sim.trace)`
(clears batches, `frames = 0`, `header = nothing`) then
`sim.trace.header = _capture_header(sim)` when enabled. Root-input values are
`gather`ed from the store through `layout.addr[("", face)]` for each
`(face, _) in layout.root_inputs`.

**`trace(sim)`** returns `Trace(header, copy(batches), frames)`; refused
(`ArgumentInvalid(call = :trace, reason = :disabled)`) under `trace = false`,
and `ArgumentInvalid(call = :trace, reason = :no_header)` before the first
`init!`. Check `ArgumentInvalid`'s existing reasons in `diagnostics.jl` and
add the two; if a `MissingInit`-style kind fits the second better, use it and
say so.

**The four kinds** in `diagnostics.jl` (the three errors) and `dataplane.jl`
(the warning, beside its eight siblings — it also needs a `KindCounts` field
and a `_kind` symbol, `:replay_discarded`):

```julia
@kwdef struct ReplayHeaderMismatch <: Diagnostic
    what::Symbol            # :store | :root_input | :deployment | :scalar
    path::String = ""       # component path for :store
    name::Symbol = Symbol("")   # the store (:x/:s/:m), the root-input face, or the parameter
    expected::Any = nothing # the trace's value
    found::Any = nothing    # the target's
end
@kwdef struct ReplaySchemaMismatch <: Diagnostic
    writer::String; schema::Vector{Symbol}; unknown::Vector{Symbol}; faces::Vector{Symbol}
end
@kwdef struct ReplayUnknownFace <: Diagnostic
    face::Union{Symbol,Int}   # the name when the schema has one, else the bare position
    frame::Int; writer::String; faces::Vector{Symbol}
end
struct ReplayDiscardedStaging <: Diagnostic   # warning; writer attribution is the cell's
    faces::Vector{Symbol}; frame::Int
end
```

Severity: the three are `:error` by default; the warning overrides. `path`:
`ReplayHeaderMismatch`'s `path` field for `:store`, `""` otherwise. Messages
render the list-in-hand (`_facelist`) where a list is carried.

**The validation + normalization pass** (`_compile_feed(sim, trc) →
ReplayFeed`), run before any state is touched:

1. Scalar: `replay!(::Simulation{T}, ::Trace{T})` is the method; the fallback
   `replay!(::Simulation, ::Trace)` throws `ReplayHeaderMismatch(what = :scalar,
   expected = T_trace, found = T_sim)`.
2. Structure, collected into one vector: `layout.sizes`, root face list, the
   flat's paths, per-component `s`/`m` value types, each mismatch one
   `ReplayHeaderMismatch(what = :store | :root_input, …)`; then the seven
   deployment parameters (`Δt_base`, `h`, `n`, `method`, `localization_tol`,
   `localization_budget`, `firing_budget`) as `what = :deployment`. `t₀`,
   `t_end`, `stop_on` are not compared (§12.7's table).
3. Schemas: each header schema's faces ⊆ the target's root faces, else one
   `ReplaySchemaMismatch` per writer. Throw here if anything collected so far
   (the fail-fast half of the two-pass shape: header errors precede entry
   errors).
4. Entries, collected: each batch's positions resolved through its writer's
   schema to a face, each face to the target's cell address. A position outside
   the schema is `ReplayUnknownFace(face = position, …)`; a face absent from
   the target cannot occur after step 3 but is guarded by the same kind with
   the name. Throw the collection if non-empty.
5. Normalize: per recorded writer, a scatter compiled against the target
   layout — reuse `Writer(sim.exec.act.layout, schema_faces)` for its `addrs`
   and `blank`, build each batch as `blank` with the positions set (values
   `convert`ed to `w.types[i]`), and close `() -> _apply!(store, addrs, batch)`
   per record. The feed is `Vector{Pair{Int,Function}}` sorted by
   `(frame, writer)` with a cursor, plus the original `TraceBatch` beside each
   thunk for re-recording, and `last_frame = trc.frames`.

**`replay!`** in `sim.jl`, beside `init!`:

```julia
function replay!(sim::Simulation{T}, trc::Trace{T}; to_boundary = nothing,
                 t_end = nothing, stop_on = nothing) where {T}
```

- Lifecycle gate as `init!`'s (`ServiceLifecycle(op = :replay!, …)` for
  `:running`/`:errored`); `to_boundary` validated: an integer `0 ≤ k` with
  `k * sim.n ≤ trc.frames`, else `ArgumentInvalid(call = :replay!, reason = :range,
  argument = :to_boundary, value = k)`. `t_end`/`stop_on` validated exactly as
  `run!` does; unlike `run!`, `t_end` may be absent — the recording bounds the
  replay.
- Compile the feed (above) — every refusal precedes every write.
- Apply the header: `xbuf .= header.x`; `sstores[ci][] = deepcopy(header.s[ci])`
  where non-nothing, likewise `m`; scatter each root-input value. Then the
  `init!` tail verbatim: clock (`t = t₀ = header.deployment.t₀`, `step = 0`),
  prior reset, log reset, accounts reset, cells cleared, stop issuer cleared,
  termination cleared. Trace register: reset, then **the recording's header
  is installed** (§12.7: "the new trace inherits the old header") with this
  sim's writers *appended* to its schema list under the growth rule above, so
  the re-recorded batches keep the recording's indices (each feed thunk
  carries its original `TraceBatch`) and a continuation's live drains record
  under this sim's own. Under `trace = false` nothing is installed. Then
  `boundary_zero!`, `publish!`.
- Set `sim.trace.feed`, then run the loop: factor `run!`'s device bracket and
  topology into `_run_body!(sim, pol, upto, target)` that `run!` calls with
  `upto = typemax(Int)` and `replay!` with `upto = to_boundary === nothing ?
  trc.frames : to_boundary * sim.n`; `target` from `t_end` or `typemax(Int)`.
  The terminal mapping is `step!`'s: `term === nothing` → `:initialized`
  (the frame budget ran out: replay ended at a frame top, §12.7), a §13.5
  source → `:stopped`, a throw → `:errored`. `feed` is cleared in the
  `finally`, before the lifecycle store.
- **Drain under a feed.** `drain!(sim)` branches on `sim.trace.feed`: with a
  feed, each roster cell is swapped to `nothing` and a non-empty take is
  reported on the entry's own diag cell as `ReplayDiscardedStaging(faces,
  frame)` — once per drained batch, which coalescing makes at most once per
  writer per frame, the rate limit §11.8 asks for — the harness cell likewise
  on its cell; the diag folds run as usual; then the feed applies every thunk
  whose frame is `clock.step + 1`, re-recording each original `TraceBatch`
  through the register (`reg.enabled` permitting) and advancing the cursor;
  `frames += 1`.
- **Devices are readers**: the bracket, spawn and tail are `run!`'s, untouched.

## Tests — new file `test/test_trace.jl`, included after `test_trim.jl`

Fixtures at top level (README's local-scope rule). Use existing library
material where it fits (`feedback_model()`, the lifecycle fixtures, a
staging device from `test_devices.jl`); add a deterministic scripted device
only if none stages on a frame schedule already.

Properties to pin (each a `@testset`; the bit-identity assertions are `==`
on buffers — that *is* the claim, like the frame-top stamps; everything else
per D-163):

1. **Sparse record.** `stage!` one face on a wide harness surface, `step!`
   once: one `TraceBatch` with one entry at that face's position, `frame == 1`,
   writer index = the harness's. An untouched frame records nothing but
   advances `frames`.
2. **Header placement.** A model whose boundary-zero sequence moves a store
   (a `Trigger`-style event that fires at `ESTABLISH` on a condition-set root
   input): the header's `s`/`m` holds the *pre-sequence* value while
   `latest(sim)`'s table holds the post-sequence one. And the header carries
   the resolved root input (`mixture = 0.5`-style: a face never staged).
3. **Kill switch and clearing.** `trace = false` → `trace(sim)` refused and
   the drain records nothing; `init!` again empties the batches and re-captures.
4. **Bit-identity, deviceless.** Record a staged `step!`-driven session
   (several stages across frames, a localized event in the model); `replay!`
   a fresh `Simulation` of the same build: every logged snapshot's `store`
   buffers `==` the original's, boundary for boundary, `t` stamps included;
   lifecycle ends `:initialized`.
5. **Bit-identity with a device.** A rostered staging device drives a `run!`;
   replay on a deviceless twin reproduces the log bitwise (no roster needed —
   "no devices or mappings present").
6. **Partial replay and reproduction.** `replay!(sim2, trc; to_boundary = k)`
   halts with `clock.step == k * n`; `step!(sim2)` then equals the original's
   frame `k·n + 1` bitwise — the §13.4 workflow's shape, minus the error.
7. **Continuation.** `run!` after `replay!` proceeds from the replayed
   boundary; and the continued session's `trace` has the recording's batches
   as a prefix (`==` on `TraceBatch`es) plus its own.
8. **Discarded staging.** A device that stages during a replay: its batch is
   never applied (the replayed trajectory is still bitwise the recording) and
   `ReplayDiscardedStaging` appears in its writer status, `faces` naming the
   discarded faces.
9. **Refusals.** Scalar mismatch; a different build (an extra component) →
   `ReplayHeaderMismatch(what = :store)`; a changed `h` → `:deployment` with
   `name === :h`; a hand-built trace whose schema names a foreign face →
   `ReplaySchemaMismatch`; an out-of-range position → `ReplayUnknownFace`
   collected with the others; `to_boundary` past the recording →
   `ArgumentInvalid`; `replay!` while running → `ServiceLifecycle`.
10. **What-if.** Same structure, a changed parameter (a condition on a
    component's parameter through `init!`'s… no — parameters are constructor
    values: rebuild with a different gain) → no error, a different
    trajectory, `:initialized`.
11. **Roster change after `init!`** appends the new writer set: a batch
    recorded before an `attach!` and one after resolve through different
    schema entries, both correct.

## Bookkeeping (each stage its share)

- README: a `src/trace.jl` row (§11.5, §12.7, D-029, D-101, D-176); remove
  `§11.5's input trace` and `replay (§12.7)` from the absence list, remove the
  replay kinds and `ReplayDiscardedStaging` from the absent-kinds sentences
  (`dataplane.jl`'s docstring lists the four absent warning kinds — update it
  to three); add `ReplayHeaderMismatch`'s provenance fields to the payload
  shortfall list; the §12 absence bullet keeps pause/control-plane surface and
  §13.4. The deviation rows: none expected — if a stand-in is needed, add its
  row in the same commit.
- MAP.md: the file's piece-by-piece entry.
- NOTES.md: the increment paragraph and the property bullets, including the
  `frames` field and the `ReplayUnknownFace` position arm as the two places
  the prototype runs ahead of the spec's letter, flagged for the spec pass.
- `runtests.jl`: the two includes.

## Stages

- **Stage 1 (Opus)** — `trace.jl` types and register, the `trace` keyword,
  the drain recording through the thunks, the header capture in `init!`, the
  roster-change re-capture, `trace(sim)`; tests 1–3, 11. Commit: "Record the
  input trace: the header at init! and one sparse record per drained batch".
- **Stage 2 (Opus)** — the four kinds, `_compile_feed` (validation +
  normalization), `ReplayFeed`; tests 9's kind arms against hand-built traces
  (no `replay!` yet — test through `_compile_feed`). Commit: "Validate and
  normalize a trace against the target build, with the replay kinds".
- **Stage 3 (Opus)** — `replay!`, `_run_body!`, the drain substitution,
  `ReplayDiscardedStaging`, re-recording; tests 4–8, 10, the lifecycle arms
  of 9. Commit: "Replay a trace as the ordinary loop with D-101's two
  substitutions".
- Cold review (Opus) over `0cb491e0..HEAD`, then the fixer, then the
  reviewer's delta check.

## Report format (every stage)

Commit hash; files touched; the suite's final tally; every deviation from
this brief with its reason; friction (a spec sentence that resisted, a shape
that fought the code); what the next stage must know (handoff notes).
