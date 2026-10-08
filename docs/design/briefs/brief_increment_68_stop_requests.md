# Brief: increment 68, stop requests are structural and `stop_on` retires

One docs stage, two code stages, one cold review and a fixer if the review
needs one. Written at f851a51 while two loose commits queued at increment
67's tip (the `UnconnectedInput` hand-up chain and the §6.1 double
declaration, `pending.md`'s first two bullets) were in flight on this tree,
touching `src/assembly.jl`, `src/diagnostics.jl` and three test files. Rebased
at cacc95b on 2026-10-08, both landed: they moved only `pending.md`'s bullet
(now 93 to 104) and `src/diagnostics.jl` by three lines; every other anchor
below was recounted against `git show cacc95b:file` and holds. The tip at
launch is the commit rebasing this brief. Find passages in
`docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

The user's ruling, 2026-10-08, to be recorded by stage 0 as D-316.

- **Why.** Today a model-detected stop is a `Bool` face re-exported level by
  level to the root and named by the advance's `stop_on`. The hop per level is
  the pain. A component author wiring a stop is saying "my validity
  assumptions broke down; continue at your own risk", so stopping is the rule
  and continuing the exception. Stopping therefore becomes structural by
  default and overridable per advance, and the per-level plumbing goes.
- **The vocabulary is an eltype, not a block.** `StopFlag` is a framework
  enum, `@enum StopFlag NO_STOP STOP_REQUESTED`, defined in `src/leaves.jl`
  beside `Pinned` (line 238). An enum is already an atom of the leaf walk
  (`_atom`, line 23), one leaf of its own eltype, pinned at every
  activation. Cells are stored per eltype (§9.7, D-162), so every `StopFlag`
  port in the model lands in one buffer, `CellStore{StopFlag}`, and the loop's
  check is a scan of that buffer on the just-published snapshot. **A port
  whose declared type is exactly `StopFlag` is a stop request**, whoever
  publishes it. §13.7's doctrine that library blocks have no framework
  privileges stands: the privilege is the eltype's, as `Pinned` is a
  framework marker.
- **The library spelling.** `StopRequest(; reason = "")` in `Redstone.Blocks`,
  a stateless continuous leaf in the mould of `Constant` (`src/blocks.jl`
  lines 123 to 139):

  ```julia
  struct StopRequest <: AbstractComponent
      reason::String
  end
  StopRequest(; reason = "") = StopRequest(reason)
  x_init(::StopRequest) = (;)
  u_types(::StopRequest) = (request = Bool,)
  y_types(::StopRequest) = (flag = StopFlag,)
  y_direct(::StopRequest, (; u)) = (flag = u.request ? STOP_REQUESTED : NO_STOP,)
  stop_reason(c::StopRequest) = c.reason
  ```

  Continuous, so it refreshes at every boundary, `t*` included; assemblies
  are virtual for execution (§10.5, D-019) and rate scopes touch discrete
  children only, so one leaf sits anywhere in the tree. Its output is
  consumed by nobody, which §6.1 allows silently (D-084). Fed by a discrete
  detector it sees the tick at the tick's own boundary: the boundary sweep
  walks the full execution order in topological order (§10.5, D-147).
- **`stop_reason` is an optional declaration**, `stop_reason(::Any) = ""`
  in `src/declare.jl` beside the other optional defaults (`sample_times`,
  line 191; `transparent_container`, 128). The build consults it for every
  component that publishes a `StopFlag` port. The `String` is instance data on
  the struct, never a port value; the isbits check (`src/build.jl` line 166)
  covers stores only.
- **The roster.** `Layout` (`src/build.jl` line 520) gains
  `requesters::Vector{Requester}`, with

  ```julia
  struct Requester
      path::String      # the publishing component
      port::Symbol      # its StopFlag port
      reason::String    # stop_reason(instance)
  end
  ```

  index-aligned with the `StopFlag` buffer: `requesters[i]` owns offset
  `i - 1`. `cell_layout` (line 527) builds it after placement by walking
  `zip(structure.components, decls)` and each `decl.outs` for `P === StopFlag`,
  writing slot `addr[(path, port)].offsets[1] + 1`, never by assuming the walk
  order; the vector is preallocated at the `StopFlag` offset count and every
  slot is asserted filled. The instance comes off the component entry (grep
  the field on `ComponentEntry`, `src/assembly.jl`). `const STOP_FLAG_KEY =
  _cell_key(StopFlag)` in `src/store.jl` fixes the bundle key once, since
  `_cell_key` prints and allocates.
- **Two placement refusals** in `place!` and the root-input loop (`src/build.jl`
  lines 536 to 585), both `IllegalPortType` (`src/diagnostics.jl`, the struct at line
  798, its `message` at 807), new reasons: `:stop_flag_nested`, a
  `StopFlag` leaf inside a port whose type is not `StopFlag` itself (a struct
  field or a static array of them), since the roster is per port; and
  `:stop_flag_at_root`, a root input declared `StopFlag`, since a request is
  the model's, never an operator's (the control plane is the operator's path,
  §12.1). A `StopFlag` *input* port places nothing and is left alone.
- **The policy.** `StopPolicy` (`src/sim.jl` line 48) becomes `t_end` plus
  `ignored::Vector{String}`, the requester paths this advance does not honour.
  The keyword is `ignore_stop_requests = ()` on `run!`, `replay!` and `step!`,
  in place of `stop_on`:

  ```julia
  run!(sim; t_end = 60)                                        # every requester stops the run
  run!(sim; t_end = 60, ignore_stop_requests = :all)           # the global override
  run!(sim; t_end = 60, ignore_stop_requests = ("ldg/stop",))  # per requester, by component path
  ```

  `_bind_policy` (line 318) normalizes: `()` is none, `:all` is every roster
  path, an iterable of strings is validated path by path against the roster,
  duplicates collapsed, in the order given. A path naming no requester is
  `StopRequestInvalid(path, site, candidates)`, collected over the given
  paths as `StopFaceInvalid` was, `candidates` the roster's paths in roster
  order. The binder returns `(policy, ignore_mask::Vector{Bool})`, one entry
  per requester, `true` where ignored; the mask replaces `addrs::Vector{Any}`
  as the loop's second argument everywhere it travels (`_run_body!` 1284,
  `_advance!` 1501, `frame!` and `_localized_frame!` in `src/localization.jl`
  37 and 53, `test/test_stepper.jl` 92 to 94). D-261's rule stands: the
  policy is the advance's value, the mask its compiled companion.
- **The read.** `_stop_hit(sim, policy, ignore_mask)` (line 389): `all(ignore_mask)`
  returns `nothing` at once (the empty roster included); otherwise it binds
  `getfield(latest(sim).store.stores, STOP_FLAG_KEY).buffer` and scans
  `i` in order, returning `sim.exec.act.layout.requesters[i]` at the first
  `!ignore_mask[i] && buffer[i] === STOP_REQUESTED`. The hot path allocates
  nothing; the roster is touched on a hit only. Callers build
  `ModelRequestedStop(requester.path, requester.port, requester.reason)`,
  the source's new payload (line 26). First in roster order wins when two
  hold at one boundary; roster order is build order. D-203's source order is
  unchanged: control stop at frame top, `t_end`, then the requests at each
  publication, where the faces were.
- **`UnboundedRun`** (`src/dataplane.jl` line 115) fires at `run!` in `:live`
  when `t_end` is `Inf` and no requester is honoured, `all(ignore_mask)`:
  payload `t_end` and `ignored::Vector{String}`, the message distinguishing a
  model with no requester from one whose requests are all ignored.
- **Retired.** The `stop_on` keyword, `StopFaceInvalid` and `_stop_faces`,
  the glossary's `g-stop_on`, and `pending.md`'s "Stop candidates" bullet,
  whose object (a dropped re-export) no longer exists. Root-exported `Bool`
  faces stay legal and inspectable; they just stop nothing.
- **Doctrine, for the ruling.** §13.5's observation-by-path rejection stands
  narrowed: the ignore list reads no arbitrary cell. It addresses the
  `Build`'s requester roster, a build product like the root-input list, and
  binds at an advance, a stopped-sim point where §14.1's conditions already
  address state by path. D-060's scanned-terminal-type rejection is
  superseded on its own terms: the requester is loud at inspection (the
  roster and the record name it), substitution is answered by the override,
  and disabling is one keyword. The trigger is the author's knowledge and
  the override the integrator's, which is where each belongs. An ignored
  request is still a cell in every snapshot, so the log records when
  validity broke even on a run that continued. Two uses share the
  mechanism, validity breakdown and scenario completion, and the reason
  string is what tells a reader which; the framework never will.
- **Verified before writing.** The trace header records no policy
  (`src/trace.jl`), so replay's format is untouched. Components are never
  required to be isbits. `monitored()`, `armed()` (`test/test_lifecycle.jl`
  8 to 14), `interrupter_watched()` and `hooked_interrupted()`
  (`test/test_failures.jl` 18 to 32) and `overloaded()` (`test/fixtures.jl`
  596) are the stop-face models; `Overload`'s docstring (568 to 572) names
  `stop_on`. The suite's `stop_on` sites: `test_lifecycle.jl` 19,
  `test_trace.jl` 2, `test_linearize.jl` 2, `test_events.jl` 1,
  `test_failures.jl` 1, `test_trim.jl` 1. `ModelRequestedStop(:x)` literals:
  `test_lifecycle.jl` 111, 193, 257, 270, 279, 290, 418; `test_events.jl` 344;
  `test_failures.jl` 376. The package's enums spell their members in capitals
  (`Tier`, `Class`), hence `NO_STOP`/`STOP_REQUESTED`.

## Out of scope

- Printing the roster in `show` or the descriptor. The inspector session
  follows (`pending.md`).
- A per-port `stop_reason`. One reason per component; a component with two
  `StopFlag` ports shares it.
- Any change to the control plane, the tail, localization or the event
  phase. The request is a cell read at publication, nothing more.
- Any spec or log edit beyond what stage 0 lands. A shape that contradicts
  D-316 is a stop-and-report.

## Reading, in order

- `docs/design/pending.md`, the increment 68 bullet stage 0 adds, and the
  "Stop candidates" bullet it removes (lines 93 to 104).
- `docs/design/decisions.md` D-316 (stage 0's), then D-060 (line 1768),
  D-203 (7332), D-255 (9767), D-261 (10121), D-285 (11922), D-313 (13065),
  each with its 2026-10-08 annotation.
- `docs/design/spec.md` §13.5, lines 9524 to 9677, whole; §12.1, 7904 to
  7935; §12.4, 8146 to 8160 and 8385 to 8420; §12.6, 8729 to 8736; §13.7,
  9773 to 9830; §9.7, 4768 to 4784, cell storage; §4.3, 529 to 549, what a
  port may hold; §8.7, 3470 to 3473, a continuous child under
  `sample_times`; Appendix B, 11829 to 11860 and 11886 to 11896. Never read
  the spec whole.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/leaves.jl`, `### src/declare.jl`,
  `### src/build.jl`, `### src/store.jl`, `### src/blocks.jl`,
  `### src/sim.jl`, `### src/dataplane.jl`, `### src/diagnostics.jl` and
  `### test/fixtures.jl`; "Authoring caveats" whole; "Naming"; "Running the
  suite". Never restate either in a commit or a comment.
- `src/leaves.jl` 1 to 60 and 238; `src/store.jl` whole; `src/build.jl` 98
  to 103, 520 to 600, 630 to 634, 1398 to 1412; `src/declare.jl` 40, 128,
  191, 213; `src/blocks.jl` 1 to 12, 123 to 139, 336 to 357; `src/sim.jl` 1
  to 80, 170 to 190, 265 to 330, 355 to 395, 1046 to 1100, 1157 to 1232,
  1284 to 1300, 1495 to 1540, 1698 to 1720; `src/localization.jl` 25 to 55
  and 160 to 172; `src/dataplane.jl` 110 to 120, 165 to 176, 218 to 227,
  277, 522; `src/diagnostics.jl`, `StopFaceInvalid` (1202 to 1223) and
  `IllegalPortType`.
- `test/test_lifecycle.jl` 1 to 25, 86 to 112, 186 to 200, 219 to 336, 405
  to 420; `test/test_failures.jl` 15 to 35 and 371 to 378;
  `test/test_events.jl` 336 to 345; `test/test_trace.jl` 1186 to 1205;
  `test/test_linearize.jl` 176 to 197; `test/test_trim.jl` 684 to 688;
  `test/test_stepper.jl` 90 to 95; `test/test_diagnostics.jl` 193, 405 to
  420, 670 to 695; `test/test_build.jl` 774 to 840; `test/test_leaves.jl`
  140, 216, 249; `test/test_blocks.jl` 1 to 30, 457 to 505, 715 to 735;
  `test/fixtures.jl` 565 to 600; `test/imports.jl` 27, 36, 43, 77.

## Stage 0: the ruling and the spec

### The shape

One docs commit, written under `docs/design/tools/decisions_style.md` and
`spec_style.md`, read first. Historical entries are annotated, never
rewritten.

- **D-316** in `docs/design/decisions.md`, before the `<!-- citation link
  definitions` marker (line 13289 at f851a51), after D-315. Title the topic,
  for instance "Stop requests are structural: a `StopFlag` port ends the run
  unless the advance ignores it". Position: every bullet of "What is
  settled" that states a rule, from the eltype to `UnboundedRun`'s
  condition. Rationale: the "Why" and "Doctrine" bullets. Rejected: the
  per-level re-export plus `stop_on` (the superseded position, with why it
  fell); honouring by opt-in token with the default off (halves the gain and
  inverts the author's meaning); a global-only override (the per-instance
  mask costs a name lookup the binder already does); a `terminal` event
  flag and path-addressed faces (D-060's grounds stand for those); reading
  the reason off the block by type (the build cannot know `Blocks`, which
  is included last). Status lines: D-060 `ratified`, annotated that its
  scanned-terminal-type arm is superseded by D-316 and its
  observation-by-path arm narrowed; D-203, D-255, D-261, D-285 and D-313
  annotated where they name `stop_on`, faces, `addrs` or the inventory.
- **`docs/design/spec.md`.** Grep `stop_on`, `stop face`, `stop faces`,
  `StopFaceInvalid` and `g-stop_on` first and treat every hit, 41 lines of
  `stop_on` at f851a51 plus the prose sites. The substantive edits: §13.5
  (9524 to 9677) rewritten around requests, keeping its structure
  (detection, publication, policy, the unbounded run, the record's four
  kinds with the new payload, D-203's order, the taught contract, the
  rejected mechanisms with D-060's arms re-stated as superseded or
  narrowed, the inspection-versus-acted-on doctrine); §12.4's initiation
  item (8152 to 8158) and the deferred-interrupt rule (8415 to 8420); §12.6
  (8729 to 8736); §12.7 (8828 to 8834 and the dispositions table row at
  8983); §14.4's bullet (10368 to 10370) and 10440 to 10444; §10.4 (5464 to
  5468); §11.5 (7168 to 7173); §13.6 (9712 to 9716); §9.3's plausibility
  bullet (4335 to 4338) and Appendix A's (around 11480); §13.7's inventory
  sentence (9778 to 9781) gains `StopRequest`; §8.2's declaration inventory
  gains `stop_reason` as an optional declaration with its default; §4.3
  (541) notes `StopFlag` as the one enum with a framework meaning; Appendix
  B's three signatures and keyword table (11829 to 11860, 11886 to 11896);
  Appendix C: `StopFaceInvalid`'s row (12169) replaced by
  `StopRequestInvalid`, `IllegalPortType`'s row gains the two reasons,
  `UnboundedRun`'s row (12347 to 12354) restated; the glossary: `g-stop_on`
  (13377) becomes `g-stop-request`, `g-stop-policy` (13148) and
  `g-termination-record` restated, D.5's `Build` line (12863) says
  "`ignore_stop_requests`" where it says `stop_on`. The rendering of the
  roster is out of scope, so §9.2 gains nothing.
- **Companions.** `frame_walkthrough.md` lines 29, 214, 268 to 269;
  `library_inventory.md` line 29 ("Stop Simulation is a stop face") and one
  shipped row for `StopRequest` in whichever table fits, named in the
  report. A companion is not normative; keep each edit to the sentence
  that names the old machinery.
- **`docs/design/tools/gloss_table.md`** rows 162 and 214 follow the
  glossary.
- **`docs/design/pending.md`.** Remove "Stop candidates" (93 to 104). Add
  the increment 68 bullet at the head of the first section, in working
  order, stating what the code owes D-316: the vocabulary, the roster, the
  block, the policy and the retirement, by stage; stage 2 removes it.

### The battery

`check_refs.jl`, `check_rows.jl`, `check_glossary.jl --strict`,
`check_bold.jl`, then `linkify.jl` and `check_refs.jl` again, all green.
A scripted edit reads and asserts every file's matches before opening any
for writing; `git diff --stat` before committing. The PDFs rebuild on the
commit hook.

### Bookkeeping

Nothing in `src/` or `test/`. The commit touches the log, the spec, the two
companions, `gloss_table.md` and `pending.md`, and nothing else.

## Stage 1: the vocabulary, the roster and the block

### The shape

`StopFlag` in `src/leaves.jl` after `Pinned`, with a docstring saying what a
port of this type means and that nested or root-input placement is refused.
`stop_reason` in `src/declare.jl` with the optional defaults. `Requester`,
`Layout.requesters`, the roster pass and the two refusals in `src/build.jl`.
`STOP_FLAG_KEY` in `src/store.jl`. `StopRequest` in `src/blocks.jl` in a
section of its own after `Freeze`, the module's import list gaining
`StopFlag`, `NO_STOP`, `STOP_REQUESTED` and `stop_reason`. Nothing reads the
roster yet: `stop_on` keeps working and the suite stays green.

Probe before asserting and report the numbers: build a `Group` with two
`StopRequest` children in two subtrees and a third component publishing
`StopFlag` directly, print `layout.requesters`, and for each entry print
`layout.addr[(path, port)].offsets` beside its index.

### Tests

- `test/test_leaves.jl`, beside the enum assertions at 140 to 250:
  `leaf_types(StopFlag) == [StopFlag]`, `nleaves(StopFlag) == 1`, and a
  struct holding a `StopFlag` field walks it as a leaf of its own eltype,
  the fact the nested refusal rests on.
- `test/test_build.jl`, a new testset after the `IllegalPortType` arms:
  "the layout rosters every `StopFlag` port, aligned with its buffer, with
  its reason (§9.7, §13.5, D-316)": on the probe's model, `requesters`
  holds three entries in build order, each `addr[(r.path, r.port)].offsets ==
  (i - 1,)`, the two blocks' reasons as given and the direct publisher's
  `""`; a second model with the same type at two paths shares the entry type
  and differs in paths. Two more arms in the existing `IllegalPortType`
  testset: a port typed `(; flag::StopFlag, x::Float64)` refused
  `:stop_flag_nested` with the port's path and name, and a root input typed
  `StopFlag` refused `:stop_flag_at_root` at site `:root_input`. The direct
  publisher and the nested-port fixture are new `AbstractComponent`s, so
  `build` is on the route already; grep their names across `test/` first.
- `test/test_blocks.jl`, after the `Constant` testset: "the stop request
  publishes its flag off its input, pinned, with its reason (§13.7, D-316)":
  under `fed_by` with a `Bool` source (grep the file for one; a `Constant(true)`
  and `Constant(false)` pair as in `gate_model` will do), `flag` reads
  `STOP_REQUESTED` and `NO_STOP`; `stop_reason(StopRequest(reason = "x")) == "x"`
  and `stop_reason(StopRequest()) == ""`; under `(Float64, LinearizeDual)`
  the port is pinned (the pattern the `Source` testset at 457 uses). Add the
  block to the "structure blocks … allocate nothing" testset at 491.
- `test/test_diagnostics.jl`'s rendering testset: the two new
  `IllegalPortType` arms, message text asserted there and nowhere else.

### Routing

`leaves.jl` is in the table's last row: run the whole suite, under the
flags, in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`: `### src/leaves.jl` gains `StopFlag`;
  `### src/declare.jl` gains `stop_reason` among the optional declarations;
  `### src/build.jl` gains `Requester` and the roster beside the `Layout`
  bullet, and the two refusals beside `IllegalPortType`'s; `### src/store.jl`
  gains `STOP_FLAG_KEY`; `### src/blocks.jl` gains `StopRequest`. Constructs,
  not behaviour.
- `test/imports.jl`: `StopFlag`, `NO_STOP`, `STOP_REQUESTED`, `stop_reason`,
  `Requester` on the `import Redstone:` lines, `StopRequest` on the
  `Redstone.Blocks` line.

## Stage 2: the policy, the read, the record and the retirement

### The shape

`src/sim.jl`: `StopPolicy(t_end, ignored)`, `ModelRequestedStop(path, port,
reason)`, `_ignored_requests` in place of `_stop_faces` (validation and the
`:all` expansion, returning `(ignored, ignore_mask)`), `_bind_policy`
returning `(policy, ignore_mask)`, `_stop_hit` as settled, the keyword on
`run!`, `step!` and `replay!`, their docstrings, the `UnboundedRun` raise
(1228 to 1229) on `all(ignore_mask)`, and `addrs` renamed and retyped
through `_run_body!`, `_advance!` and the two localization functions, their
docstrings and site comments following. `src/dataplane.jl`: `UnboundedRun`'s
fields and message. `src/diagnostics.jl`: `StopRequestInvalid` in
`StopFaceInvalid`'s place, `_stop_site` renamed or dropped with it. Grep
`stop_on`, `StopFaceInvalid`, `_stop_faces`, `stop face` and `addrs` across
`src/` and `test/` when done: zero hits outside the log.

The fixtures: `monitored()`, `armed()`, `interrupter_watched()`,
`hooked_interrupted()` and `overloaded()` each gain a child `stop =
StopRequest(reason = …)` wired from the flag the face exported, the export
itself kept where a test still reads the port and dropped otherwise.
`Overload`'s docstring loses `stop_on`. A new fixture for the no-lag claim: a
discrete leaf at `Relative(3)` whose tick flips a `Bool` at a known tick,
wired to a `StopRequest` (grep `fixtures.jl` for a discrete counter to
adapt).

### Tests

`test/test_lifecycle.jl` carries the policy's tests. Each `stop_on` call
drops the keyword and each `ModelRequestedStop(:x)` literal becomes the
three-field value with the fixture's path, `:flag` and reason. The
validation testset at 219 becomes "ignore_stop_requests names requester
paths, validated at all three sites (§13.5, D-316)": an unknown path refused
at `run!`, `replay!` and `step!` with `StopRequestInvalid`, the same `path`
and `candidates` at all three and the site the one differing field; the
bound still refuses first. New testsets:

- "a request stops the run by default, and the record names the requester
  (§13.5, D-316)": `monitored()` under `run!(sim; t_end = 5.0)` ends at
  boundary 4 with `ModelRequestedStop("stop", :flag, reason)` and
  `latest(sim).t === record.t`, the assertions of the testset at 252.
- "the override is per requester, or all (§13.5, D-316)": a model with two
  requesters, `a/stop` firing first and `b/stop` later; ignoring `"a/stop"`
  ends the run on `b/stop` at its boundary; ignoring both, and `:all`, runs
  to `t_end`; the record's `policy.ignored` holds the expanded paths under
  `:all`.
- "two requests at one boundary resolve to the first in build order
  (D-316)": both fire at the same boundary; the record names the first
  declared; swap the declaration order and the record follows.
- "a tick-detected request stops at the tick's own boundary (§10.5,
  D-316)": the new discrete fixture; `record.t` equals the tick's time.
- The unbounded-run testset at 311: `run!(sim)` on a model with no
  requester raises the advisory; with a requester honoured it does not;
  with `ignore_stop_requests = :all` it does, `ignored` holding the path.
- The boundary-zero stop (264), the `t*` stop (274) and the `step!`
  truncation (409) keep their assertions under the new spelling.

Elsewhere: `test_events.jl` 342 to 344, `test_trace.jl` 1190 and 1203,
`test_linearize.jl` 179 and 195, `test_trim.jl` 687, `test_failures.jl` 375
to 376 follow; `test_stepper.jl` 92 to 94 passes `Bool[]`, and one more
assertion there: `frame!` on a model with one honoured requester allocates
exactly `publish_bytes` too. `test_diagnostics.jl`: `StopRequestInvalid`
replaces `StopFaceInvalid` at 412 to 415 and the `UnboundedRun` literal at
678 takes the new payload.

### Routing

`sim.jl` is in the table's last row: run the whole suite, under the flags,
in the foreground, 600 s.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`: `### src/sim.jl`, the §13.5 bullet names
  the new payload and `_bind_policy`'s bullet the mask, the keywords bullet
  reads `t_end` and `ignore_stop_requests`; `### src/dataplane.jl`'s
  `UnboundedRun` line; `### src/diagnostics.jl` swaps the kind; `### test/fixtures.jl`
  gains a line for the discrete fixture.
- `docs/design/pending.md`: the increment 68 bullet is removed; run the
  battery.
- `test/imports.jl`: `StopRequestInvalid` for `StopFaceInvalid`.

## The cold review

One fresh Opus reviewer over the two code commits, the docs commit read for
what they owe: open-mind stance, probe scripts in the scratchpad, "empty is
acceptable". Dimensions:

- **D-316 against the tree.** A `StopFlag` port anywhere stops a run with
  no keyword; `:all` and a path list override; the record names path, port
  and reason; the source order; `UnboundedRun`'s condition; the two
  refusals. Grep `stop_on`, `StopFaceInvalid`, `_stop_faces`, `addrs` in
  `sim.jl` and `localization.jl`, and `stop face` across `src/`, `test/`,
  `docs/design/implementation.md` and the companions: zero hits outside the
  log's history.
- **Alignment.** On a scratch copy, over every zero-argument fixture of
  `test/fixtures.jl` and the test files' top-level models that build at
  nominal: for every entry `i` of `layout.requesters`,
  `addr[(path, port)].offsets == (i - 1,)`, and the buffer length equals the
  roster's.
- **The no-lag claim.** Confirm by probe that the discrete fixture's flag
  and the request's cell agree in the same published snapshot.
- **Mutants on a scratch copy**, each named test going red: the roster
  filled in reverse walk order; the mask's sense inverted; `:all` expanding
  to none; `_stop_hit` returning on `NO_STOP`; the early return on
  `isempty(ignore_mask)` instead of `all(ignore_mask)` (the `:all` advisory
  test); the nested refusal dropped; the root-input refusal dropped;
  `stop_reason` read off the default for every requester; the block's
  output constant `NO_STOP`; the first-in-roster rule replaced by last;
  `step!`'s truncation skipped. A surviving mutant is a missing test.
- **Allocation.** `frame!` and `publish!` equal on the bouncer and on a
  model with a honoured requester, past 1000 frames.
- **The register and the docstrings.** Rows name constructs; the
  `StopRequest`, `StopFlag` and `stop_reason` docstrings say what D-316
  says and no more; the spec's §13.5 and D-316 agree with each other and
  with the code's names.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree, on the Julia floor `Project.toml` declares.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the routed subset's result with the
assertion count, the probe's numbers for every asserted value, and every
deviation from this brief with its reason.
