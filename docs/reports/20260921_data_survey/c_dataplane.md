# Data survey, slice C: data plane and periphery

Tip `aa9162a` (the brief names `34f8a39`; `aa9162a` adds the brief and
changes no `src/`). Files: `src/dataplane.jl`, `src/roster.jl`,
`src/bindings.jl`, `src/devices.jl`, `src/trace.jl`. Structs surveyed: 23,
every non-diagnostic struct in the five files. Date 2026-09-21.

Method: for each field, `rg '\.name\b' src/` and `rg 'TypeName(' src/`,
narrowed by receiver where the name is common; readers in `test/` counted
separately where `src/` has none. Runtime claims were checked with the
fixtures loaded (`julia --project=test`, a `two_root_inputs` model, one `Pad`
under `Enumerated("a")`, `init!`, `run!` to 0.5); each entry says what the
run confirmed.

## Findings

### `DataPlane.store` — misplaced (courier), duplicate
`src/roster.jl:190`. `store::Any`. Writers: the constructor
`DataPlane(layout, store, trc)` at `src/roster.jl:198`, from
`Simulation(deployment, T)` at `src/sim.jl:221` with `ex.store`; no writer
after construction. Readers: `_install_writers!` at `src/trace.jl:196,199`,
as the first argument of `_drain_thunk`, and nothing else.
Evidence: `rg 'plane\.store\b' src/` returns the two `trace.jl` lines;
`attach!` compiles its provisional thunk from `sim.exec.store` directly
(`src/sim.jl:1461`), so the two spellings of one value coexist. REPL:
`sim.plane.store === sim.exec.store` is `true`. `Simulation.exec` is `const`
and never rebound, so the pair cannot drift today; nothing enforces that
beyond the field's comment.
Proposal: remove the field. `_install_writers!(plane, store, trc)` and
`reclaim!(plane, layout, store, trc)` take the store as an argument, exactly
as D-260 made them take `trc`; the callers `attach!`, `detach!` and
`_open_run!` all hold `sim.exec.store`, and `DataPlane(layout, store, trc)`
keeps its argument for the first harness thunk without retaining it. This
is the same shape D-260 removed for the trace: state the executor owns,
copied onto the plane so a callee without the executor could reach it.
Spec: not rostered. D-256 lists what moved to the plane (`loop_diag`,
`loop_acct`, `published`); the store is not among them.

### `DeviceHandle.id` — dead
`src/devices.jl:123`. `const id::Int`. Writers: the positional constructor
at `src/sim.jl:1458`, argument 1. Readers: none in `src/`, none in `test/`.
Evidence: `rg '\.id\b' src/ test/` returns `e.id` (the roster entry's, keys
of `run_tasks`) and diagnostic payloads only; no `h.id` or `handle.id`
anywhere. The handle's `who` string already renders the id
(`"device $id (Pad)"`), and `_who(e)` reads that. Not confirmable by
running: absence of a reader is a claim about authored code.
Proposal: drop the field; `attach!` stops passing `id` to the handle.
Spec: not rostered on the handle. §11.6 gives the handle "the two primitive
capabilities, read and stage, plus control access"; §12.4 places the stable
device id on the roster entry ("what survives a stop is the roster entry:
binding, claims, stable device id").

### `RosterEntry.writer`, `RosterEntry.diag`, `RosterEntry.binding`, `RosterEntry.id` — duplicate (spec-rostered for `binding` and `id`)
`src/roster.jl:121–127`. `binding::AbstractBinding`, `id::Int`,
`writer::Writer`, `diag::DiagCell`. Writers: the constructor at
`src/sim.jl:1460` (arguments 2, 3, 4, 7) and its rebuild at
`src/trace.jl:194` copying the same four off the old entry. Readers of the
entry's copies: `e.writer` at `src/roster.jl:249`, `src/trace.jl:149,196`,
`src/sim.jl:663,1605`; `e.diag` at `src/sim.jl:1570,1605–1606,1698`,
`src/devices.jl:350,381,471`; `e.binding` at `src/sim.jl:1437`; `e.id` at
`src/sim.jl:1100,1158,1697`. The handle's copies: `h.writer`
(`src/devices.jl:229`), `h.diag` (every handle primitive), `h.b`
(`src/devices.jl:205`), `h.id` (none, above).
Evidence: `attach!` builds `w`, `diag`, takes `b` and `id`, passes them to
`DeviceHandle(...)` and then to `RosterEntry(dev, b, id, w, ..., diag, ..., h)`,
so the entry holds four values and the handle that holds the same four.
REPL: `e.writer === h.writer`, `e.diag === h.diag`, `e.binding === h.b`,
`e.id == h.id`, `e.handle === h`, all `true`. The entry already reads one
handle field through the handle: `_who(e) = (e.handle::DeviceHandle).who`
(`src/roster.jl:134`). The handle cannot point the other way: the entry is
immutable and `_install_writers!` replaces it at every recompile, so a
handle holding an entry would go stale at the first roster change.
Proposal: the handle is the home of the four, and the entry reads them
through `e.handle` as `_who` does. What changes: the readers above become
`e.handle.writer`, `e.handle.diag`, `binding(e.handle)`, `e.handle.id`;
`handle::Any` (kept for include order) gets the typeassert `_who` already
pays, or `RosterEntry` moves below `DeviceHandle` so the field is typed and
the frame-top `_fold!(e.acct, e.diag)` loses nothing. The entry keeps `dev`,
`drain`, `should_abort`, `acct`, `handle`. If the ruling is to keep the
entry's `binding` and `id` because §12.4 names them, the finding reduces to
`writer` and `diag`.
Spec: §12.4 ("what survives a stop is the roster entry: binding, claims,
stable device id") rosters `binding` and `id` on the entry; `writer` and
`diag` are not rostered on either type. D-193 (the loop "already owns the
device `Task` handles") keys `run_tasks` by the entry's id.

### `DeviceHandle.plane` — misplaced; `DeviceHandle.published` — duplicate
`src/devices.jl:127,129`. `const plane::DataPlane`,
`const published::Published`. Writers: the constructor at
`src/sim.jl:1458–1459` (arguments 5 and 7, `plane` and
`sim.plane.published`). Readers: `h.plane` once, as `h.plane.claimedby` in
`stage!` (`src/devices.jl:229`); `h.published` once, in `latest(h)`
(`src/devices.jl:213`).
Evidence: `rg 'h\.plane\b' src/` returns the one line; `rg '\.published\b'
src/` shows `published` is written at the plane's construction only and
never rebound; `rg '\.claimedby\b' src/` shows the Dict mutated in place
(`empty!`, `[f] =`) and never rebound. REPL:
`h.published === h.plane.published` and `h.plane === sim.plane`, both
`true`. The handle holds the whole plane (roster, harness writer, store,
the loop's cells) to reach one Dict, while §11.6 says "what a device may
touch is what the handle holds"; and beside the plane it holds a second
reference to one of the plane's own fields, so that `latest(h)` is one load
(`Published`'s docstring, `src/dataplane.jl:607–614`).
Proposal: replace `plane::DataPlane` with `claimedby::Dict{Symbol,String}`,
the plane's own Dict by reference (its identity is stable, above). `stage!`
reads `h.claimedby`; `attach!` passes `plane.claimedby`. `published` then
stands alone and stops being a duplicate. The alternative, dropping
`published` and reading `h.plane.published.latest`, costs one load per
`latest(h)` and keeps the over-broad reach.
Spec: not rostered. §11.6 names the capabilities, not the fields; D-244's
`detached` and D-193 say nothing of the plane.

### `Snapshot.frame` — dead in `src/`, read by tests only
`src/dataplane.jl:593`. `frame::Int`. Writers: the constructor in
`publish!` at `src/sim.jl:1664`, argument 2, `clock.step`. Readers in
`src/`: none. Readers in `test/`: 20 sites across `test_log.jl`,
`test_dataplane.jl`, `test_lifecycle.jl` (`[s.frame for s in logged(sim)]`,
`latest(sim).frame`).
Evidence: `rg '\.frame\b' src/` returns `TraceBatch.frame`,
`ReplayRecord.frame`, `CursorFrame` and diagnostic payloads only. The log
indexes by `snap.boundary` (`src/dataplane.jl:671`), the tail by `s.boundary`
(`src/devices.jl:449`). REPL after `run!` to 0.5: `frame = 5`,
`boundary = 5`; the two part where a `t*` boundary publishes
(`test_log.jl:19`, `[0, 1, 2, 3, 4, 4, 5]`).
Proposal: none to make without a ruling. The field is an inspection value
the tests lean on; if it stays, it is by choice, since nothing in the
framework reads it.
Spec: §11.2 rosters what a snapshot carries as "the boundary-consistent
signal table, `t` and the framework status"; §12.3 adds "the trajectory's
published-boundary ordinal with `t`". D-230's rationale mentions "the frame
index at 0" as a snapshot field in passing. The frame index is not in
either roster.

### `Writer.types` — duplicate
`src/dataplane.jl:448`. `types::Vector{Any}`. Writers: the constructor
`Writer(layout, faces)` at `src/dataplane.jl:457–462`, computed as
`_port_type(a) for a in addrs`. Readers: `_normalize`
(`src/dataplane.jl:510,512`) and `_compile_records!`
(`src/trace.jl:417,420`), both `w.types[i]` with `i` from the face lookup.
Evidence: `types[i] === _port_type(addrs[i])` by construction, `addrs` is a
tuple of `CellAddr{P,K}` and `_port_type` reads `P`. REPL:
`w.types == Any[_port_type(a) for a in w.addrs]` is `true`. The only
constructor derives one from the other and the struct is immutable, so the
invariant holds by construction; it is a duplicate with an enforcer, kept
because a `Vector{Any}` indexes cheaply where a heterogeneous tuple would
not, on a path (`_normalize`) that is already `Any`-typed and off the frame.
Proposal: leave, or replace the two reads with `_port_type(w.addrs[i])`
and drop the field. Low consequence either way.
Spec: not rostered. §11.4 names the schema and the compiled scatter, not
the type list.

### `TraceHeader.layout.root_faces` — duplicate (spec-rostered)
`src/trace.jl:47`. `layout::@NamedTuple{sizes, root_faces, paths, stypes, mtypes}`.
Writers: `_capture_header` at `src/trace.jl:232` via `_fingerprint(sim)`,
which builds `root_faces` from `layout.root_inputs` in the same order
`roots` is built from two lines above. Readers: `_check_header!` at
`src/trace.jl:262` (`l.root_faces == f.root_faces`) and `_detach`.
Evidence: `first.(h.root_inputs) == h.layout.root_faces` by construction.
REPL: `true`. The same header holds `paths`, equal to
`h.deployment.build.structure.paths` (REPL: `true`), so the fingerprint
duplicates two things the header also carries whole.
Proposal: none without a ruling. `_fingerprint` is one function with two
sides on purpose (`src/trace.jl:203–209`), and §12.7's disposition table
lists "store layout, root-input faces" as trace content of its own.
Removing `root_faces` would have `_check_header!` compare
`first.(h.root_inputs)` against the target's face list, breaking the
one-function symmetry the comment defends.
Spec: §11.5, §12.7 (disposition table row "store layout, root-input faces |
compared against the `Build`").

## Clean

`WriterStatus`, `FrameworkStatus`, `ResidueRecord` and `Snapshot.status` are
published artifacts. No `src/` code reads their fields except `stale`
(`WriterStatus.heartbeat`); every other read is in `test/` (`w.who`,
`w.totals`, `w.recent`, `w.task_state`, `r.writer`, `snap.status.writers`).
Read by tests only, by design: §11.8 and §13.5 roster them as what a
snapshot and a termination record carry.

| struct | file:line | fields | note |
| --- | --- | --- | --- |
| `StagingCell{B}` | `dataplane.jl:24` | 1 | |
| `KindCounts` | `dataplane.jl:218` | 11 | fields read generically, through `fieldnames` in `_bump`, `+`, `_total`; no field is read by name |
| `DiagBatch` | `dataplane.jl:264` | 2 | |
| `DiagCell` | `dataplane.jl:288` | 2 | `heartbeat` is stored and read for roster entries only; the harness and loop cells carry it at `0.0`, per the docstring |
| `WriterAccount` | `dataplane.jl:333` | 3 | |
| `WriterStatus` | `dataplane.jl:377` | 6 | published artifact, read by tests only (above) |
| `FrameworkStatus` | `dataplane.jl:394` | 1 | published artifact, read by tests only (above) |
| `Batch{V,M}` | `dataplane.jl:428` | 2 | |
| `Writer{B,A}` | `dataplane.jl:446` | 5 | `types` reported above; `faces`, `addrs`, `blank`, `cell` clean |
| `Snapshot{T,S}` | `dataplane.jl:591` | 6 | `frame` reported above; `status` read by tests only (above) |
| `Published` | `dataplane.jl:615` | 1 | |
| `SnapshotLog` | `dataplane.jl:646` | 9 | `every` is read once beyond construction, at `_open_run!` to build the next run's log (`sim.jl:681`); it is the authored parameter, `stride` the derived state. `live` in Questions |
| `RosterEntry` | `roster.jl:120` | 9 | four fields reported above; `dev`, `drain`, `should_abort`, `acct`, `handle` clean |
| `DataPlane` | `roster.jl:179` | 12 | `store` reported above; `run_tasks` in Questions; the other ten clean |
| `TableBinding{T}` | `bindings.jl:35` | 1 | |
| `ReadGather{L,A}` | `bindings.jl:121` | 1 | |
| `ResidueRecord` | `devices.jl:25` | 3 | artifact; `recent` and `suppressed` read by `_residue!`'s rendering, `writer` by tests only |
| `Control` | `devices.jl:65` | 6 | `stopped` and `lifecycle` in Questions |
| `DeviceHandle` | `devices.jl:122` | 11 | `id`, `plane`, `published` reported above; the other eight clean |
| `TraceHeader{T}` | `trace.jl:40` | 7 | `layout.root_faces` reported above; `x`, `s`, `m`, `root_inputs`, `deployment`, `t₀` each read by `replay!` (`sim.jl:897–919`) and spec-rostered (§11.5) |
| `TraceBatch` | `trace.jl:58` | 3 | |
| `Trace{T}` | `trace.jl:87` | 4 | |
| `ReplayFeed` | `trace.jl:116` | 3 | `frames` is the recording's length and its one home once the recording `Trace` is out of hand; not derivable from `records` (a frame may carry no batch) |

`ReplayRecord` (`trace.jl:101`) is a NamedTuple alias, not a struct; its
three fields are all read (`sim.jl:1616–1624`, `trace.jl:433`).

## Questions

- `DataPlane.run_tasks` (`roster.jl:188`) is filled by `run!` at spawn and
  emptied at run end (`sim.jl:1100,1127,1158`), read by `_status` alone. It
  is per-`run!` state on the plane. The `Run` spans advances, so it fits
  there no better; D-193 says the loop owns the task handles. A ruling on
  whether the plane is its home, or whether `run!` should carry the
  `Dict` (or the `tasks` vector it already holds) into `publish!`'s status
  assembly instead.
- `SnapshotLog.live` (`dataplane.jl:654`) equals `count(!isnothing, L.snaps)`
  at every point (REPL: `true` after a run). It is a cached count kept so
  `_retain!`'s fill test is O(1); the two are mutated together in one
  function. A duplicate by the letter, with a stated cost to removing it.
- `Writer.blank` (`dataplane.jl:450`) is read for `blank.vals` and
  `typeof(blank.vals)` only; its `mask` half is never read (`_normalize` and
  `_compile_records!` build a fresh `fill(false, n)`). The `Batch` type of
  `blank` is what fixes `B` for the cell and `_stage!`, so the field earns
  its place as a type carrier; whether it should be the values tuple alone
  is a spelling question.
- `Control.stopped` and `Control.lifecycle` (`devices.jl:67,70`) both say
  whether a run is under way, with a deliberate gap: `stopped` flips at tail
  step (1), `lifecycle` leaves `:running` after the joins. The docstring
  argues the gap. Not a duplicate, but the two must be read together, and a
  reader of one alone can be misled during the tail.
- `TraceHeader.deployment` carries the whole `Deployment`, and through it
  the `Build` with the component instances, into an artifact the spec calls
  primary data. `Deployment`'s `==` excludes the build, so replay never
  compares it. Whether the header should hold the build-free half is a
  design question for D-254, not a smell this survey can rule on.

## Coverage

Every struct in the five files was reached. The eleven diagnostic kinds in
`dataplane.jl` (`MalformedDatum` through `ReplayDiscardedStaging`) are out
of scope per the brief and were not surveyed. `DiagValue`, `DiagBatch`'s
sentinel `EMPTY_DIAG` and the constants are not structs.
