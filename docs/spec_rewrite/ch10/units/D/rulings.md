# Unit D (§10.6): rulings

Log line numbers are `docs/design/decisions.md` as of today's working tree.
Old line numbers are `units/D/old.md`.

## Ruled edits applied

- **R3**, 5612–5615 (old 152–155): the list of rejected shapes is cut. "D-154
  records the rejected shapes" stays as the pointer. Three items map to D-154
  Rejected (log 5273–5285). The fourth, "a table copy per firing round", is
  in D-100 Rejected (log 2893), not D-154's. Per the coordinator's ruling the
  pointer reads "D-154 and D-100 record the rejected shapes", and the item
  maps to D-100's Rejected field.
- **R3**, 5630–5634 (old 170–174): the first two sentences stay. "What that
  buys" and its list are cut, mapped to D-181 Rationale (log 6359–6362) and,
  for the collapse of re-arms, D-181 Rejected (log 6373). A one-clause pointer
  stays: "D-181 records what that buys."
- **R4**: the `#g-input-epoch` link on "epoch rule" is dropped. The name
  stays. The text now says that the epoch is the world one round's sweep
  produces, so no bundle mixes values from two rounds' sweeps, and that it is
  not the input epoch of §10.4.
- **R8 F5**: "cross-frame re-localization" became "re-localization within the
  frame" in the moved budget comparison (M4).
- **R8 F8**: "They are not traced, and they are reconstructed
  deterministically" is replaced by "The trace header is such a checkpoint.
  `restore!` copies a checkpoint's prior back (D-274). The other two registers
  are reset on entering each boundary, as the sketch shows." "Not model
  memory" and "absent from every state store" are kept.
- **R8 F9**: the `f_step!` sentence is kept and cites D-020. `f_step!` gets
  a gloss, "an unconditional per-step hook", from §2.2 (spec 285).
- **R8 F14**: the engine and the FCS get one introducing sentence: "The
  engine is a continuous component, and the FCS (the flight control system)
  is a discrete component that observes it." Both facts come from the old
  sentence before it ("a continuous component's handler and its discrete
  observers' ticks") and the one after ("re-runs the FCS's stages", "its
  `s_update`").
- **Coordinator fixes after the cold verifier:**
  - "Serialization is what delivers this" became "... delivers the epoch
    rule", since R4's sentences now stand between it and its referent.
  - R4's added "so no bundle mixes values from two rounds' sweeps" is
    dropped. It repeated the old "No bundle ever straddles two epochs".
  - "It needs no pre-materialization, no staging pass, no carrier and no
    shadow table" became "It needs none of the extra machinery that D-154
    made unnecessary". D-154 Rationale (log 5266–5269) carries all four
    names in the same sense: "D-100's pre-materialization mechanism",
    "f.10's staging pass, carrier … are mooted", "no shadow table, no
    allocation becomes trivially true". No name stays.
  - The rejection sentence stays plain. Two added sentences follow it in
    the rejecting entries' words: the deferral design fired a re-enabled
    event one step late, through a manufactured not-holding prior (D-181
    Rejected, log 6371–6373); the per-round cap bounded the number of rounds
    at a boundary (D-020 Rejected, log 709).
  - "trace header" links `#g-trace-header`, glossed "the trace's fixed
    preamble".
- **M2**: "§10.3 extends naturally. External readers observe the table only
  after the boundary sequence completes." map to `units/A/old.md`. The
  pointer kept here: "§10.3 states when external readers may observe the
  table."
- **M4**: the two-budget comparison sits last in "The firing budget". "The
  same doctrine governs §10.6" became "The doctrine of §10.4 governs both
  budgets". The comparison now gives each budget's scope (per event per
  boundary, per frame), and the default sentence says "the per-frame
  localization budget's 8".
- **M9**: "Why iterate" and the h-dependence paragraph moved up, after the
  rule, under "Why the phase iterates".

## Corrections proposed

None of fact. Two of form:

- Old 215 (spec 5675): the blockquote bolded `[sweep → guards → handlers]`
  as grouping. Bold marks rulings only, and the bold check fails a bold span
  with no D-citation in its sentence. The bold markers are removed; the
  brackets still group. The text is unchanged.
- Old 216: the `#g-firing-budget` link moved from the blockquote to the
  term's first prose use, the first sentence of "The firing budget".

## Citations added or replaced

| where (new) | entry | the words that rule it |
|---|---|---|
| "The phase iterates" | D-020 | Position: "Boundary event phase iterates to quiescence — rounds of full re-sweep → guards → handlers" (log 695) |
| "A component fires at most one event per round" | D-154 | Position: "a component fires at most one event per round" (log 5248) |
| "An event fires in an iteration round if and only if three conditions hold" | D-181 | Position: "an event may fire up to `firing_budget` times per boundary …, eligibility = intra-boundary not-holding → holding edge on a last-observed sample initialized from the prior" |
| "The edge is read against the last-observed sample …" | D-181 | the same Position clause; repeated because the paragraph split separated it from the old D-181 citation |
| "The prior is updated at each boundary's quiescence" | D-082 | Position: "previous boundary's quiescent sample, updated at quiescence" (log 2361) |
| "They are correctly absent from every state store" | D-082 | Position: "detection bookkeeping, not model memory: not in `z`" (log 2362) |
| "The trace header is such a checkpoint. `restore!` copies a checkpoint's prior back" | D-274 | Position bullet 1: "the guard priors, the one event register that crosses a boundary" (log 11102); bullet 3: "copies the state back" (log 11114); bullet 4: "The trace header is the checkpoint `init!` takes" (log 11119) |
| "Boundary zero sets every prior to not-holding" | D-082 | Rationale: "Boundary-zero baseline = nothing-holds" (log 2367) |
| "A `restore!` keeps the checkpoint's priors and runs no boundary zero" | D-274 | Position bullet 3: "runs no boundary zero. No sweep, no guard evaluation, no update, no prior reset" |
| "This is the same class of footgun §2.2 cited when killing `f_step!`" | D-020 | Rejected: "Single pass per boundary: cascade latency N·h — step-size-dependent semantics, the §2.2 `f_step!` footgun class" (log 706–708) |
| "Each round re-runs the whole boundary sweep, gated entries included" | D-020 | Position: "rounds of full re-sweep" (log 695–696) |
| "Within a round, the signal table has a single writer, and it is the sweep" | D-154 | Position: "the signal table is written only by sweeps" (log 5247–5248) |
| "A handler executes against exactly the world its guard fired on" | D-154 | Position: "a handler executes against exactly the world its guard fired on" (log 5253–5254) |
| "A component's other eligible events are blocked, not lost" | D-191 | Position: "blocking defers the edge rather than consuming it" (log 6702); Rejected quotes "blocked, not lost" (log 6720) |
| "Each is re-decided in the next round, against the post-transition sweep" | D-154 | Position: "a blocked event is re-decided next round against the post-transition sweep" (log 5257) |
| "Across components, handler order within a round is semantically unobservable" | D-154 | Position: "cross-component handler order is unobservable with no delivering mechanism" |
| "a handler cannot opt into seeing a same-round foreign transition" | D-100 | Rejected: "An opt-in for same-round foreign visibility: same-instant cross-component coupling is a cascade" (log 2895–2897) |
| "the arbitrary-K objection (D-020)" | D-020 | Rejected: "Bounded-rounds cap: arbitrary K knob" (log 709) |
| "D-181 records what that buys" | D-181 | Rationale: "manufactured-prior exception, re-arm flag and `EventDeferred` retired" (log 6359–6360) |
| "Budget exhaustion degrades; it does not throw" | D-181 | Rationale: "exhaustion loses that event's further edges for the boundary under a `FiringBudget` warning naming the chatterer — degrades, never errors" (log 6362–6364) |
| "Ticks stay outside the iteration, after quiescence" | D-020 | Position: "due `g` updates run after quiescence, outside the iteration" (log 698–699) |
| "Boundary zero is the same sequence with an empty integrate" | D-067 | Position: "Boundary zero is the §10.6 macro-sequence run with an empty integrate" (log 1858) |
| "The doctrine of §10.4 governs both budgets" | §10.4 | replaces the self-citation "governs §10.6", which the move made meaningless |
| "none of the extra machinery that D-154 made unnecessary" | D-154 | Rationale: "f.10's staging pass, carrier and `u`/`y` split are mooted and \"no shadow table, no allocation\" becomes trivially true" (log 5266–5269) |
| "D-154 and D-100 record the rejected shapes" | D-100 | Rejected: "A table copy per firing round: identical semantics, pays an allocation pre-materialization avoids" (log 2893–2894) |

Removed: D-016, D-100 and D-152 inside the cut list (R3); D-152 is
superseded by D-154.

## Rationale-only rulings

Each is bold here and cites the entry whose non-Position field states it.
The log owes a Position for each.

| ruling | entry | field | log line |
|---|---|---|---|
| Boundary zero sets every prior to not-holding | D-082 | Rationale | 2367 |
| A handler cannot opt into seeing a same-round foreign transition | D-100 | Rejected | 2895–2897 |
| Budget exhaustion degrades; it does not throw | D-181 | Rationale | 6362–6364 |

Unbolded, as descriptions or reasons, but ruled only outside a Position:
the three registers "named normatively" (D-181 Rationale, log 6360–6361);
termination bounded by `firing_budget · E` (D-181 Rationale, log 6364–6365);
the fixed handler order across components (D-100 Rationale, log 2883–2885);
the single-pass executor (D-154 Rationale, log 5267–5269); the `f_step!` footgun
(D-020 Rejected, log 706–708); ticks cannot cause events (D-020 Rejected,
log 711–712). `FiringBudget` "at most once per event per boundary", its
payload and the reason for the default 4 have no entry (survey part E).

## Inbound citations affected

- D-154 Rejected (log 5281): "Live-table reads under canonical order: §10.6's
  standing rejection". After R3, §10.6 no longer names live-table reads; it
  points to D-154. The citation now points back at its own entry. Track 2.
- spec 5945 (§11.2): "§10.3 as extended by §10.6". After M2, §10.3 holds the
  full rule and §10.6 points to it. The pair stays true; "§10.3" alone would
  be exact.
- D-274 Spec (log 11148) lacks §10.6, which now cites D-274 three times.
- D-082 Position (log 2362) says the baseline is "not captured, reconstructed
  on warm restart". D-274 captures the priors in every checkpoint and copies
  them back. The text here follows D-274 (F8); D-082 wants an annotation.
  Track 2.
- No inbound row relies on the cut list of rejected shapes, the cut
  deferral list, or the moved budget comparison.

## Open questions

All four earlier questions are ruled. One item stays for track 2:

- D-100 is half-superseded by D-154 (log 5264–5266) but its status still
  reads "ratified". The bold "a handler cannot opt into seeing a same-round
  foreign transition" keeps its D-100 citation for now. Track 2 should move
  the opt-in rejection (D-100 Rejected, log 2895–2897) into D-154 and
  repoint the citation.
