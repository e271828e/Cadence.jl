# Brief: the log boxes each snapshot again

The third "Retire alone" bullet of `pending.md`, ruled 2026-09-30. One Opus
agent, two commits: the spec first, then the code; the gate run by the agent
(the change touches `sim.jl`).

## The ruling

`pending.md`:

> **The log boxes each snapshot again** (§7.5, §11.2, M-B26): `publish!`
> boxes the snapshot once for `latest`, and `log!`, called with the concrete
> value, boxes it twice more, for `last` and for the middle. That is 288 B a
> frame on `feedback_model`, where §7.5 makes logging amortized-zero.
> Ruled 2026-09-30:
> - `log!` takes the box `latest` already holds, reloaded from the atomic
>   field and passed `@nospecialize`;
> - `logged(sim)` returns a vector typed by the run's concrete snapshot
>   type, since reading a `Vector{Snapshot}` costs a dynamic dispatch per
>   element (24 ns against 1 ns);
> - the storage stays a vector of references. Inline records would
>   preallocate 136 B a slot at every `init!` and would save nothing the
>   reuse does not. §7.5's sentence on inline records softens to match,
>   docs-commit-first.
>
> The check: a full run allocates the same bytes a frame with the log on as
> with it off.

Design and code are peers, neither subservient. The ruling is settled; the
shapes below are the coordinator's. Where the tree contradicts a claim made
here, follow the tree and say so in the report.

## Reading, in order

- `docs/design/pending.md` lines 40–92 and the bullet above.
- `docs/design/spec.md` §7.5's "Logging" bullet (lines 1848–1859) and §11.2's
  log paragraphs (lines 5655–5700 and 5715–5745), which already say the log
  holds the published snapshots themselves, by reference, with zero extra
  copies. Never the whole file.
- `docs/design/tools/spec_style.md` before editing the spec; the headers of
  `docs/design/tools/check_refs.jl`, `check_rows.jl` and `linkify.jl`.
- `docs/design/implementation.md`: the `src/dataplane.jl` row (471–496) and
  the `src/sim.jl` row (295–416, the accessors bullet at its end);
  "Authoring caveats" (778–842); "Naming" (843–920); "Running the suite"
  (921–end), the one home of test policy.
- `src/dataplane.jl`: `Published`, `SnapshotLog`, `log!`, `_retain!` (lines
  670–790); `Snapshot` (657–664). `src/sim.jl`: `publish!` (2153–2170),
  `latest`, `logged` (2226–2240), and the `Run{T}` struct (97–102).
- `test/test_log.jl` whole (it is short), and `test/test_conditions.jl`
  lines 515–540 for the suite's `@ballocated` idiom.

## The shapes

**`log!` takes the box.** `publish!` builds the snapshot, release-stores it
into `published.latest`, and then reloads that field and hands the loaded
reference to `log!`, whose snapshot parameter is `@nospecialize`d, so the
stores into `first`, `last` and the middle reuse the one box publication
made. Inside `log!` the field reads on the snapshot (`boundary`) become
dynamic; that is the ruling's trade. Keep the typeassert on `first` in the
form that still reads its `boundary` without a second box.

**`logged` is typed by the run's snapshot type.** Its result is
`Vector{S}` with `S` the run's concrete snapshot type, the type of what
`latest(sim)` holds once anything is published. Before the first `init!`,
and under `log = false`, the vector is empty; type it by the same `S` if the
type can be stated from the simulation without a second spelling of it
(`Snapshot{T,typeof(sim.exec.store)}` only if a test proves it equal to
`typeof(latest(sim))` after a publication), else `Snapshot[]`. Say which in
the report. The docstring says what the element type is.

**The storage stays as it is.** No inline records, no change to
`SnapshotLog`'s fields or to `_retain!`'s arithmetic.

## The docs commit (first)

§7.5's Logging bullet: replace its first two sentences so they no longer
claim inline records. The log retains the published snapshot objects
themselves, by reference, one slot per retained boundary and no copy
(§11.2), and `sizehint!` to the retention bound makes regrowth a non-event.
The sentence "The inline-storage claim is about the snapshot record's
fields, not about everything reachable from them" becomes the same claim
about the snapshot's *fields*, since what follows it (field handles riding
as references) still holds. Keep the bullet's remaining sentences. Run the
three doc tools; green. Commit the spec alone.

## The code commit (second)

- `src/dataplane.jl` and `src/sim.jl` as above; docstrings updated to match,
  concise.
- Tests, in `test/test_log.jl`:
  - the check the ruling names: on `feedback_model` at `h = 1//100`, a run
    with `log = true` allocates the same bytes as a run with `log = false`,
    measured with the suite's `@ballocated` idiom (`setup` re-initializing
    the simulation under the keyword, `evals = 1`), each after a warm-up
    run so compilation is out of the number; assert equality of the two
    byte counts, and say in a comment why equal rather than zero (§11.2
    makes the snapshot and the table copy per frame by design; see
    `pending.md`'s "Publication's garbage" entry);
  - `logged(sim)` has `eltype(logged(sim)) === typeof(latest(sim))` after a
    run, and the empty case's type, whichever you chose;
  - the existing "zero copies" testset stays as the identity check.
- `docs/design/implementation.md`: the `src/dataplane.jl` row's log bullet
  (the log stores the box publication made, `log!` `@nospecialize`d) and the
  `src/sim.jl` accessors bullet (`logged` typed by the run's snapshot type).
  `docs/design/pending.md`: delete the "log boxes" bullet whole, its check
  paragraph included; the "Retire alone" list then reads "Currently empty."
  if nothing else is left in it. Run the three doc tools again; green.
- The gate, foreground, 600 s timeout, green before the commit:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl

## Rules

- Commit messages: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds untracked directories that are not
  yours (`docs/design/gui_*`, `docs/reports/`).
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`).
- Every changed line traces to this brief.

## Report

The two commits with hashes and subjects; files touched with one line each;
the tests added and the two byte counts the allocation test saw; the
`logged` empty-case choice; the gate's summary line; any deviation from this
brief and why; anything left for the user.
