# Brief: the roster is read once per run

The second "Retire alone" bullet of `pending.md`, ruled 2026-09-30. One Opus
agent, one commit, the gate run by the agent (the change touches `sim.jl`).

## The ruling

`pending.md`:

> **The roster is read once per run** (§11.3, E 4.4, M-B26): the loop
> re-reads `plane.roster` every frame, and the freeze is `assert_stopped`'s
> gate, where §11.3 makes the roster a plain immutable value the loop reads
> once at `run!`. Ruled 2026-09-30: the run takes a copy at `run!`, and the
> drain and the status iterate that. `_init_devices!` already derives `live`
> from the roster at run start.

Design and code are peers, neither subservient. The ruling is settled; the
shape below is the coordinator's. Where the tree contradicts a claim made
here, follow the tree and say so in the report.

## Reading, in order

- `docs/design/pending.md` lines 40–92 and the bullet above.
- `docs/design/spec.md` §11.3, the paragraph "The roster is frozen per run"
  (lines 5934–5958). §12.6 for the advance entries and the doors, by line
  range (starts at 7712). Never the whole file.
- `docs/design/decisions.md` D-260 (from line 9762): the position's first
  three bullets, which put the drain's bookkeeping *off* the `Run` and make
  the stop policy the advance's argument. That is why the copy is threaded,
  not stored.
- `docs/design/implementation.md`: the `src/sim.jl` row (lines 295–416,
  especially the pacer bullets, "the `Pacer` is threaded the way the policy
  is"), the `src/devices.jl` row (620–659), the `src/roster.jl` row
  (550–572); "Authoring caveats" (778–842); "Naming" (843–920); "Running the
  suite" (921–end), the one home of test policy.
- Every reader of `plane.roster` in `src/`, found with
  `grep -n 'plane\.roster\|\.roster\b' src/*.jl`. Sort them into the run's
  readers and the stopped-sim readers before touching any.
- `src/sim.jl`: `_run_body!` (1276–1430), `_advance!` (1496–1560), `step!`
  (1716–1780), `drain!` and `_replay_drain!` (2040–2110), `publish!` and
  `_status` (2150–2200), the doors' `publish!` calls (lines 817 and 877),
  `_reset_accounts!` (660–670), `report_thread_budget!` (1445–1455).
  `src/devices.jl`: `_init_devices!` (452–475), `_sweep_tail!` (570–585).
  `src/localization.jl` lines 15–45 and 155–165, where the pacer is threaded
  through `frame!`.
- `test/test_roster.jl` (the freeze testset at line 208) and
  `test/test_dataplane.jl` (the drain's allocation testset near line 195).

## The shape

**The copy is the advance's argument, threaded as the pacer is.** At the top
of `_run_body!`, right after the lifecycle flips to `:running`, bind
`roster = copy(plane.roster)`; `step!` binds the same at its top. From
there the copy rides as a positional argument beside `pacer` through
`_advance!`, `frame!` and `_localized_frame!`, `publish!`, `_status`,
`drain!`, `_replay_drain!` and `_sweep_tail!`; `_init_devices!`,
`_reset_accounts!` and `report_thread_budget!` take it too. Every `for entry
in plane.roster` on the run's path iterates the copy, and the run's three
`isempty(plane.roster)` reads (the yield in `_advance!`, §13.4's disposition
in `_run_body!`) read it. The parameter is named `roster` everywhere; a
`Vector{RosterEntry}` annotation where the siblings annotate.

**The stopped-sim readers keep the plane's.** `attach!`, `detach!`,
`reclaim!`, `_install_writers!`, `_writer_schemas`, the doors' own
`publish!(sim)` at boundary zero and at the restore, and anything else that
runs behind `assert_stopped`, read `plane.roster` as they do now; the doors
pass `sim.plane.roster` where `publish!` now wants a roster. Nothing here
changes what `attach!`/`detach!` mutate.

**No new field anywhere.** D-260 puts the drain's bookkeeping off the `Run`,
and §11.3 says there is no roster reference to publish. If threading turns
out to need a signature the brief does not list, add it and say so; if it
needs a field, stop and report instead.

## Tests

In `test/test_roster.jl`, beside the freeze testset: a test that the drain
and the status iterate the run's copy. The gate makes the copy unobservable
through the API, so the test bypasses it: a device whose `loop` body, once,
mutates `sim.plane.roster` directly (`empty!` it, or `push!` a second entry
built the way `attach!` builds one, whichever is simpler), then returns.
Assert that every snapshot of the run, `logged(sim)` after it ends, carries
a status naming exactly the devices rostered at `run!`, in attachment
order, and that the run ended `stopped` with the device's `shutdown!` seen.
Restore nothing: the simulation is discarded. Name the testset for what it
tests (§11.3), and say in a comment why it reaches past the gate. The
drain's zero-allocation testset in `test_dataplane.jl` must stay green as it
stands; if `drain!`'s new argument changes its call there, update the call
and nothing else.

## Bookkeeping

- `docs/design/implementation.md`, `src/sim.jl` row: a bullet under
  "Staging/drain/publication" saying the run copies the roster at the top of
  `run!` and `step!` and threads it as the policy and the pacer are, the
  doors passing the plane's; the `src/devices.jl` row where `_init_devices!`
  and `_sweep_tail!` are described, if their arguments are named there. Run
  `docs/design/tools/check_refs.jl`, `check_rows.jl` and `linkify.jl`
  afterwards; all green.
- `docs/design/pending.md`: delete the "roster is read once per run" bullet
  whole. Nothing else there moves.
- The gate, foreground, 600 s timeout, green before the one commit:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

## Rules

- One commit. Message: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds untracked directories that are not
  yours (`docs/design/gui_*`, `docs/reports/`).
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`).
- Every changed line traces to this brief.

## Report

The commit hash and subject; the signatures that changed, one line each;
the test added; the gate's summary line; any deviation from this brief and
why; anything left for the user.
