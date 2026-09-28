# Brief: the panel kit, §11.7's framework half (D-270)

Tip at launch: `c56ad79`, the docs commit that fixed the framework's half of
the panel convention (§11.7, D-270). One stage, one cold review, one
fixer. Retires `pending.md`'s first bullet under "Not yet built", "§11.7's
GUI write path". §14 is the next bullet and stays out.

Design and code are peers, neither subservient. The ruling landed
docs-first; this increment conforms the code to the amended text. If the
spec's shape proves wrong at the keyboard, stop and report rather than
deviate silently.

## What the spec says

Read these by line range at `c56ad79`, not whole sections:

- §11.7, `spec.md` 6752–6907, in full. The section's earlier rules, 6752–6844,
  are the semantics this increment serves: the port resolution and the two
  outcomes (6756–6768), derived liveness baked at run start (6787–6809), the
  peek rule (6810–6819), the staging contract (6821–6834), the orphan case
  (6836–6844). The new block, 6846–6906, is what this increment builds: the
  three-value contract (6846–6853), the port-view rule with its four-row
  table (6855–6873), the peek rule and the drain-to-publication window
  (6875–6891), the orphan-fact rule (6893–6898), and the GUI package's half,
  which stays out (6900–6906).
- §11.6, 6395–6403: the handle carries the primitive capabilities and
  deliberately not the `Simulation`; the two new references keep that true.
- §11.4, 6010 on, the staging cell and the drain, for the peek's soundness
  argument; §11.8, 6908 on, the writer records the orphan fact reads.
- Appendix B, 10723–10727: the handle row gains `pending`, and the panel kit
  row lists the new functions.
- D-270, `decisions.md` 10693 on: the position's five bullets and the six
  rejections. The rationale's third paragraph is the peek's soundness and
  its fourth the bake site; the code's docstrings say the same in fewer
  words.
- `implementation.md`: the entries for `src/dataplane.jl` (413–440),
  `src/roster.jl` (466–490) and `src/devices.jl` (535–557); the rule at 637;
  the authoring caveats at 652–712 in full; the "Naming" section (714) and
  "Running the suite" (791), both cited below and never restated.
- `pending.md`, 21–25.

## What exists

- `devices.jl` 30–49, the handle's docstring, and 50–61, `DeviceHandle`:
  ten fields, the plane's exclusivity index held by reference (D-261).
  63–66, `_assert_attached`. 98–235, the primitives: `running` (108),
  `latest` (140), `stage!` (154), `gather` (174), `report!` (197),
  `wait_next_snapshot` (215). Every primitive stores the heartbeat through
  `_beat!` (`dataplane.jl` 356).
- `sim.jl` 1738–1790, `attach!`: the one site that constructs a handle, at
  1770–1772. `sim.deployment.build.structure` and `sim.exec.act.layout` are
  both in scope there; the layout is already passed to `Writer` at 1768.
- `dataplane.jl` 495–498, `Batch`: `staged` and `mask`, positional over the
  writer's schema. 513–519, `Writer`: `faces` is the schema, position is the
  slot. 601–609, `stage_batch!`, the CAS merge, whose local `pending`
  (604–605) shares the name of the new primitive. 632–637, `_drain!`, the
  `atomicswap` take, with the same local at 633–635. 420–427,
  `WriterStatus`: `who`, `heartbeat`, `task_state`. 466–478, `stale`.
  483–484, `_task_state`: `:running`/`:done`/`:failed` off a `Task`, `:none`
  off `nothing`. 460–463, `FrameworkStatus.writers`, a `Vector`. 656–666,
  `Snapshot` and `port(snapshot, path, name)`.
- `roster.jl` 258–275, `reclaim!`: the third `pending` local (264, 270).
  224–236, `_claim`. 261, the index is written with `_who(entry)`, the same
  string a `WriterStatus.who` carries.
- `assembly.jl` 750–757, `ComponentEntry`: `conns` is `face => (producer
  path, port)`, one per declared input of a primitive, the terminal producer
  after the wire pass; a root-driven port's producer is `("", face)`
  (1086, 1160). 778–787, `Structure`.
- `build.jl` 515–520, `Layout`: `addr` maps `(path, name)` to a `CellAddr`
  for every produced cell and every root input; `root_inputs` lists the
  faces. `store.jl` 11–13, `CellAddr{P,K}`; 42, the `@generated`
  `gather_cell`, already specialized for every address in a model.
- `bindings.jl` 155, `_root_input_names(layout)`; 160–167, `_cells_at` and
  `_root_output_faces`, the model for enumerating `addr`'s keys.
- `test/utils.jl` 19, `fed`; 55–60, `writer_status(snapshot, who)`.
- `test/fixtures.jl` 1379 `Pad` (loop returns at once, so its task reads
  `:done` during a run), 1406 `TailProbe`, 1427 `Enumerated`, 1441 `Greedy`,
  1451 `NoClaim`; 146 `Gain` (`e` in, `out` out), 183 `DiscreteIntegrator`
  (`e` in, `u` out), 1480 `Pendulum` (`u` in, `θ`/`ω` out).
- `test/test_devices.jl` 1–248, the file's own devices at top level, `Crasher`
  at 43–49; 250–270, the staging testset, which already reads the cell's
  `pending` field directly; 324–356, the paused-run idiom with an observer
  task, `timedwait` and `parked_in`; 707–723, the crash testset; 952–972,
  the detached-handle testset. The file ends at 992.

## Scope

- `src/devices.jl`: two fields on the handle, `structure::Structure` and
  `layout::Layout`; the primitive `pending`; the panel kit under its own
  section header: `PortView`, `port_views`, `peek_port`, `incumbent_status`,
  `orphaned`. The handle's docstring and the file header mention both.
- `src/sim.jl` 1770–1772: the constructor call passes the structure and the
  layout.
- `src/dataplane.jl` 604–605 and 633–635, `src/roster.jl` 264–270: the
  three `pending` locals renamed (`held` for the CAS loop's current value,
  `taken` for the two swaps), under the rule that no local shares a
  function's name.
- `test/imports.jl`, `test/test_devices.jl`.
- `implementation.md` entries, `pending.md`, the prose under "Prose to
  correct".

Out: a `show` method for the handle (none exists; the default print already
lists every field, and the two references add to it, which is a separate
ergonomics question to raise in the report); any GUI package code; the
`gui = true` flag; the label text of a read-only widget; a change to
`stage!`, the drain or the wrapper; a fan-out fixture (one root input
feeding two ports) unless `Group`'s `inputs` admits it as written, in which
case one assertion that the two views share `slot` and `addr` is welcome.

## Shapes

The handle gains the two references, after `gatherer` and before
`last_seen`, both `const`:

```julia
    const structure::Structure                  # the build's rows, for the panel kit's bake (§11.7, D-270)
    const layout::Layout                        # the nominal activation's addresses, likewise
```

The primitive, beside `latest`, which it mirrors:

```julia
"""
    pending(handle, slot) → Some(value) | nothing

The handle's own staged value at `slot`, a position in its schema (§11.7):
one acquire load of the staging cell, never a take. A batch is never mutated
after it is published into the cell — the CAS merge builds a new one — so
the load sees a complete batch or none. `Some` keeps "nothing pending" apart
from a pending `nothing`. A read, so it stays legal on a detached handle
(D-244).
"""
function pending(handle::DeviceHandle, slot::Int)
    _beat!(handle.diag_cell)
    held = @atomic :acquire handle.writer.cell.pending
    held === nothing && return nothing
    held[].mask[slot] ? Some(held[].staged[slot]) : nothing
end
```

The view, immutable, its address field abstract (D-270):

```julia
"""
§11.7's baked verdict for one port: the port's terminal producer (`("",
face)` when root-driven), whether this handle commands it, the position in
the handle's schema when it does (`0` otherwise), the producer's cell address
for the snapshot read, and the incumbent writer of a root-driven port the
handle does not command — another device's `who`, `"harness"` for a face no
device claims, `""` for a port no device writes. Built by `port_views`, once
per run; nothing here resolves a name at render.
"""
struct PortView
    path::String
    port::Symbol
    source::Tuple{String,Symbol}
    live::Bool
    slot::Int
    addr::CellAddr
    incumbent::String
end
```

The table, `port_views(handle) → Dict{Tuple{String,Symbol},PortView}`:
one view per input port of every primitive, off `structure.components[ci].conns`,
and one per produced cell, off every key of `layout.addr` whose name is not a
root input (`_root_input_names`), which covers each primitive's output ports,
an assembly's exported output faces and the root's. A root input itself gets
no view: it is a source, not a port of a component. For an input port,
`source` is the `conns` entry; for a produced cell, `source` is the key
itself. `live` is `source[1] == "" && source[2] in handle.writer.faces`;
`slot` is `findfirst(==(face), handle.writer.faces)` when live, else `0`;
`addr` is `layout.addr[source]`; `incumbent` is `handle.who` when live,
`get(handle.claimedby, face, "harness")` for a root-driven port not live,
`""` otherwise. The docstring says where the spec says to call it, at the
top of the GUI's loop body, after the freeze, and why the incumbents are
right there and not at `attach!` (D-270).

The composed read and the orphan fact:

```julia
"""
    peek_port(view, handle, snapshot)

§11.7's peek rule: a live view's own pending value when one is touched, else
the producer's cell off `snapshot`; a read-only view reads the cell alone.
The window between a frame's drain and its publication shows the previous
snapshot's value, the rule's own consequence (D-270).
"""
function peek_port(view::PortView, handle::DeviceHandle, snapshot::Snapshot)
    if view.live
        staged = pending(handle, view.slot)
        staged === nothing || return something(staged)
    end
    gather_cell(snapshot.store, view.addr)
end

"""
    incumbent_status(view, snapshot) → WriterStatus | nothing

The incumbent's record in `snapshot`'s status, by `who`, or `nothing` for a
port no device writes (§11.7, §11.8). `orphaned` on the record is a task
that returned or crashed; `stale` is §12.2's silent heartbeat.
"""
function incumbent_status(view::PortView, snapshot::Snapshot)
    isempty(view.incumbent) && return nothing
    i = findfirst(w -> w.who == view.incumbent, snapshot.status.writers)
    i === nothing ? nothing : snapshot.status.writers[i]
end

orphaned(record::WriterStatus) = record.task_state in (:done, :failed)
```

`:none` and `nothing` are not orphaned: the first is a stopped sim, the
second the harness or the loop. `peek_port` takes a `Snapshot`, never
`nothing`; what a panel draws before the first boundary is the GUI
package's question.

## Tests

Every testset name states its property and cites its section. Fixtures at
top level of `test_devices.jl`, under a section header naming §11.7 and this
increment; grep every new fixture name across `test/` before choosing it.
Add every new name to `test/imports.jl`. Nothing passes by timing: the
paused and the orphan cases use the observer idiom of 324–356 with
`timedwait` on a snapshot predicate and `stop!` at the end.

The fixture, verified against the tree:

```julia
panel_model() = Group((; inner = Group((; c = Pendulum(), g = Gain(2.0));
                                       inputs = ("u" => "c/u", "e" => "g/e"),
                                       outputs = ("c/θ" => "θ",)),
                         ctl = DiscreteIntegrator(1.0));
                      wires = ("ctl/u" => "inner/u",),
                      inputs = ("in" => "ctl/e", "gain_in" => "inner/e"))
```

Its rows: `inner/c` with `conns` `[:u => ("ctl", :u)]`, `inner/g` with
`[:e => ("", :gain_in)]`, `ctl` with `[:e => ("", :in)]`; root inputs
`[:in, :gain_in]`; `addr` keys `("", :gain_in)`, `("", :in)`, `("ctl", :u)`,
`("inner", :θ)`, `("inner/c", :θ)`, `("inner/c", :ω)`, `("inner/g", :out)`.
So the table has eight views, three inputs and five produced cells.

- port views resolve every port across levels, and liveness follows the
  claim (§11.7): `Pad("a")` under `Enumerated("in")` as `h1`, `Pad("b")`
  under `Greedy()` as `h2`, on a stopped sim; `port_views(h1)` has eight
  keys and none for a root input; `("ctl", :e)` is live, slot 1, source
  `("", :in)`, incumbent `"device 1 (Pad)"`; `("inner/g", :e)` is not live,
  slot 0, source `("", :gain_in)`, incumbent `"device 2 (Pad)"`;
  `("inner/c", :u)` is not live, source `("ctl", :u)`, incumbent `""`; the
  five produced cells are not live with `source == (path, port)`; in
  `port_views(h2)`, `("inner/g", :e)` is live at slot 1 and `("ctl", :e)`
  names `"device 1 (Pad)"`. With `h1` alone rostered, `("inner/g", :e)`'s
  incumbent is `"harness"`.
- `pending` reads the cell without taking it, and the peek composes it with
  the snapshot (§11.7, §11.4): after `init!(sim, fragment(inputs = (in =
  1.0, gain_in = 2.0)))`, `pending(h1, 1) === nothing`; `stage!(h1, "in" =>
  3)` converts, so `pending(h1, 1) === Some(3.0)` and the cell is still
  populated after the read; `pending(h2, 1) === nothing`, another device's
  write invisible; `peek_port(views[("ctl", :e)], h1, latest(sim)) === 3.0`
  while `port(latest(sim), "", :in) === 1.0`; a read-only view peeks its
  producer's cell, `peek_port(views[("inner/g", :e)], h1, snap) === 2.0` and
  `peek_port(views[("inner/g", :out)], h1, snap) === 4.0`; a second
  `stage!(h1, "in" => 4.0)` reads `Some(4.0)`, newest wins; a `run!` over a
  few frames drains it, after which `pending(h1, 1) === nothing` and
  `port(latest(sim), "", :in) === 4.0`; after `detach!(sim, ...)`,
  `pending` on the retired handle does not throw.
- an edge widget counts multi-click through the pending peek (§11.7): on
  the stopped sim, three rounds of `stage!(h1, "in" => peek_port(view, h1,
  snap) + 1.0)` leave `Some(4.0)` from a snapshot value of `1.0`, and the
  snapshot still reads `1.0`.
- a staged edit shows through the peek while paused, and through the
  snapshot after the un-pause drain (§11.7, §12.1): the observer pauses the
  run, stages `"in" => 7.0` through `h1`, reads `peek_port` as `7.0` while
  `port(latest(sim), "", :in)` still reads the old value, resumes, and
  `timedwait`s until `port(latest(sim), "", :in) == 7.0`, after which
  `pending(h1, 1) === nothing`.
- `incumbent_status` joins the view to the writer record, and `orphaned`
  reads the task state (§11.7, §12.2): on the stopped sim, the record for
  `("inner/g", :e)` has `who == "device 2 (Pad)"`, `task_state === :none`
  and is not orphaned; `("inner/c", :u)` gives `nothing`; with `h1` alone,
  the harness record, not orphaned. During a run, with the observer waiting
  on `orphaned(incumbent_status(view, latest(sim)))` for the `Pad`'s view
  (its loop returns at once, so its record reads `:done`), and again with a
  `Crasher` under `Enumerated("gain_in")` reading `:failed`; `stale(record;
  now = record.heartbeat + 3.0)` on the record.

## Prose to correct

- `devices.jl` 30–49, the handle's docstring: the two references, held by
  reference like the index, and the panel kit that reads them.
- `devices.jl` 1–17, the file header: the panel kit lives here.
- `implementation.md` 535–557, the `devices.jl` entry: the two fields on the
  handle, `pending` among the primitives, the panel kit; cite §11.7, D-270.
  The `sim.jl` entry's `attach!/detach!` bullet: the handle is built with the
  structure and the nominal layout (D-270).

## Bookkeeping

- `pending.md`: delete the first bullet under "Not yet built". §14 then
  leads.
- `check_refs.jl` and `check_rows.jl` read both files; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

`sim.jl` is touched, so the routed subset is the table's last row, all of
it:

    JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

In the foreground, 600 s timeout, never in the background. Compare the
assertion total against `c56ad79`'s run before and after: the new testsets add
and nothing else moves. Run `devices lifecycle` under `-t 1` once as well,
and report it.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show c56ad79:path`.
- Fixtures live at top level; grep every new fixture name across `test/`.
- `pending` is an API name from this increment on: no local named `pending`
  anywhere in `src/` or `test/`. No local named `view` in a method whose
  parameter is one; `structure`, `layout`, `snapshot` and `record` name what
  they hold.
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the gate's result verbatim (pass/fail
counts, before and after, the `-t 1` run), every file touched with one line
each, any place the brief was wrong about the tree, and anything left undone
with the reason.
