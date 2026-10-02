### 10.6 Event iteration at boundaries: to quiescence, budgeted

[§5.3][s5-3] leaves two questions open. How far does the event phase run at a
[boundary](#g-boundary) (a published consistency point, where the
macro-sequence completes), and how often may each event fire while it does?
This section answers both.

**The phase iterates** ([D-020][d-020]). One round re-runs the
[boundary sweep](#g-sweep) (the pass over the full execution order, with due
discrete entries gated in), evaluates all [guards](#g-guard) (the declared
functions defining each event's predicate) against it, and fires the eligible
events. **A [component](#g-component) fires at most one event per round**
([D-154][d-154]). Each firing is `handler → x_projection`. Rounds continue to
[quiescence](#g-quiescence), the fixed point where a round of handlers fires
nothing.

**An event fires in an iteration round if and only if three conditions hold**
([D-181][d-181]):

- Its [predicate](#g-predicate) is observed holding in that round.
- The sample observed before it was not-holding.
- The event's firing count for this boundary is below `firing_budget`.

That is the whole definition of "newly fired". The predicate is the one
[§2.1][s2-1] defines, either the `Bool` form true or `σ ≥ 0`.
[`firing_budget`](#g-firing-budget) is a deployment keyword, an integer ≥ 1
defaulting to 4. It caps how many times each declared event may fire at one
boundary.

#### Why the phase iterates

Under a single pass, a cascade of N logically simultaneous transitions
(supervisor FSM → subordinate FSM → …, where an FSM is a finite-state machine)
takes N steps to complete, at latency N·h. Model semantics would then depend on
the integrator's step size, and `h` is an execution parameter. This is the same
class of footgun [§2.2][s2-2] cited when killing `f_step!`, an unconditional
per-step hook ([D-020][d-020]). Cascades are not a corner case either.
Externalized FSM components are blessed ([§3.1][s3-1]), which makes
cross-component cascades the expected idiom.

Established practice agrees. Hybrid automata take sequences of instantaneous
transitions at one time point. Modelica iterates events to quiescence.
Stateflow runs charts to completion within a [tick](#g-tick) (an instant at
which a discrete component's stages and update run).

Boundary-detection timing remains h-dependent, but that is a different
quantity. It is the resolution at which a physical crossing is noticed. The
cascade delay would have been structure the framework inserts between
transitions the model declares simultaneous.

#### The three registers

Three registers per event decide the rule, all named normatively.

- The [prior](#g-prior) is the previous boundary's quiescent sample. The
  boundary's first round tests against it.
- The *last-observed sample* is initialized from the prior when the boundary
  opens and overwritten by every round's evaluation. Every later round tests
  against it. There is one exception. An event that was eligible but blocked
  (below) keeps its sample, because blocking defers its edge rather than
  consuming it.
- The *firing count* for the boundary is incremented at each firing and reset
  when the boundary ends.

Eligibility inside a boundary is therefore an [edge](#g-edge-semantics) like
any other. It is a not-holding → holding transition, never a bare sign change.
What differs is the reference sample. The edge is read against the
last-observed sample, not against the prior the boundary entered with
([D-181][d-181]).

Two consequences follow. Sticky predicates need no special case. An event that
fires and keeps holding presents no further not-holding → holding edge, so it
fires once, at the boundary where it first held. And a predicate that is
genuinely falsified and re-enabled inside the boundary, because another
handler's cascade reverted its effect, fires again at this boundary against a
fresh sweep ([D-181][d-181]).

The sketch below shows one boundary's iteration.

```julia
# entering the boundary, per event:  last ← prior,  count ← 0
while the previous round fired something   # the first round always runs
    boundary sweep                         # the whole boundary sweep, due set fixed for the boundary
    per event:      eligible ← last not-holding && now holding && count < firing_budget
    per component:  firing ← its first eligible event, in declaration order
    per event:      last ← now, unless eligible and not firing   # a blocked edge stays unconsumed
    fire the firing events                 # handler → x_projection, count += 1
end                                        # the exit condition is quiescence
per event:  prior ← last                   # the settled boundary's honest sample
```

The prior is updated at each boundary's quiescence, from the final
post-iteration samples ([D-082][d-082]). The update is unconditional. Every
prior is therefore an honest observation of a settled boundary. That is what
makes the θ = 0 discriminator ([§10.4][s10-4]) conclusive.

All three registers are detection bookkeeping, not model memory. They are
correctly absent from every state store ([D-082][d-082]). A
[checkpoint](#g-checkpoint) (the executor's state at a frame top, as one value)
carries the prior, the one register that crosses a boundary ([§12.6][s12-6],
[D-274][d-274]). The [trace header](#g-trace-header) (the trace's fixed
preamble) is such a checkpoint. `restore!` copies a checkpoint's prior back
([D-274][d-274]). The other two registers are reset on entering each boundary,
as the sketch shows. Beyond the prior, the cost is one `Bool` and one small
counter per event.

[Boundary zero](#g-boundary-zero) is the initialization boundary. **Boundary
zero sets every prior to not-holding** ([D-082][d-082]). A predicate already
holding in the authored state therefore fires at `t₀`. That behavior
([§14.5][s14-5]) is derived rather than asserted. A re-run from a
[condition](#g-condition) (a path-addressed overlay that sets the build to a
state, [§14.1][s14-1]) resets all three registers from scratch, because `init!`
re-runs boundary zero ([§14.5][s14-5]). Predicates holding in the newly applied
state fire again at the new `t₀`. A `restore!` keeps the checkpoint's priors and
runs no boundary zero, so nothing holding re-fires ([§12.6][s12-6],
[D-274][d-274]).

#### What a handler sees within a round

Each round re-runs the whole boundary sweep, gated entries included
([D-020][d-020]). The reason is that a transition reaches the
[signal table](#g-signal-table) (the framework-owned cells holding every
produced signal) only through a sweep. A handler writes its component's state
stores and nothing else. So neither the transitioning component's own
[ports](#g-port) (each one declared name with its cell) nor the downstream
`y_direct` chains that read them have moved. The cost is negligible. Sweeps take
microseconds, and rounds beyond the first require an actual cascade.

Within a round, the signal table has a single writer, and it is the sweep
([D-154][d-154]). A handler writes nothing to the table. It returns
transitions, the framework latches them into the component's state stores, and
`x_projection` normalizes them. Nothing moves the table mid-round.

This gives the epoch rule, which is the core of this section. An epoch here is
the world one round's sweep produces. It is not the input epoch of
[§10.4][s10-4]. **A handler executes against exactly the world its guard fired
on** ([D-154][d-154]). Its own `y`, foreign `u` and its own `x`/`m` all come
from the firing round's sweep, so `y = h(x)` holds at every handler entry. No
[bundle](#g-bundle) (the NamedTuple of zero-copy views a component function
receives) ever straddles two epochs.

Serialization is what delivers the epoch rule. A component's state stores are
written only by its own handlers, and it fires at most one event per round, so
no same-round writer precedes any handler's entry.

**A component's other eligible events are blocked, not lost**
([D-191][d-191]). Each is re-decided in the next round, against the
post-transition sweep ([D-154][d-154]). Declaration order is therefore a
priority with re-decision, not a simultaneity. An event whose premise the
earlier transition falsified simply does not fire. Under a within-round
sequence it would have fired on the stale premise.

Blocking is visible in the registers ([D-191][d-191]). An eligible-but-blocked
event is the one case whose last-observed sample is not overwritten, so the
edge it presented stands unconsumed. A guard that keeps holding therefore fires
in the next round on that same edge. One that the transition falsified records
not-holding as usual, and any later re-rise is a fresh edge. The prior stays
honest at no cost. The quiescent round fires nothing, hence blocks nothing, so
every sample takes its final update before the prior is written.

Across components, handler order within a round is semantically unobservable
([D-154][d-154]). The reason is stronger than serialization. There is no
delivering mechanism at all. Nothing writes the table mid-round, so there is
nothing for order to observe.

Execution order is fixed all the same. It follows the component order of the
[executor](#g-executor) (the compiled form of the stage execution order), then
declaration order within a component. That keeps the [execution cursor](#g-execution-cursor) (the
loop-state field recording where execution stands, [§13.4][s13-4]) and the
diagnostics stream deterministic. No trajectory depends on it. The natural
single-pass executor is therefore exactly correct. It builds each handler's
bundle at dispatch, from the live table. It needs none of the extra machinery
that [D-154][d-154] made unnecessary, and it allocates nothing.

The trade, stated openly, is that **a handler cannot opt into seeing a
same-round foreign transition** ([D-100][d-100]). Same-instant sequential
coupling across components is a cascade, one round per link, deterministic.
Coupling tighter than that belongs inside one component, where declaration
order gives exact sequencing across rounds. This is the position of the
synchronous languages. A micro-step sees the pre-state, and effects appear at
the next micro-step.

Serializing same-component firings costs one extra intra-boundary sweep per
event so serialized, which is microseconds on the rare boundary that fires at
all. [D-154][d-154] and [D-100][d-100] record the rejected shapes.

#### The firing budget

A per-event firing budget lets a re-enabled event fire at its true boundary,
against a fresh sweep. Priors stay honest as a consequence. Every prior is a
sample actually taken, never a value recorded to make a rule work out. The
deferral design and the rounds cap are both rejected ([D-020][d-020],
[D-181][d-181]). The deferral design fired a re-enabled event one step late,
through a manufactured not-holding prior ([D-181][d-181]). The rounds cap
bounded the number of rounds at a boundary ([D-020][d-020]).

Termination is then budget-bounded rather than structural. For `E` declared
events, a boundary admits at most `firing_budget · E` firings, hence a bounded
number of rounds, deterministically and independently of pace. A livelock, such
as two FSMs toggling each other, does not resolve silently. Each toggler spends
its budget and warns (below). The run proceeds, and its [replay](#g-replay) (the
ordinary loop re-driven from the trace) is identical. This is degradation, not
an error, per the doctrine of [§10.4][s10-4]. The warning names the actual
chatterer, while every other event's iteration continues untouched.

This trade is also stated openly. Because termination is budget-bounded rather
than structural, the objection that a rounds cap is an arbitrary knob
([D-020][d-020]) lives on in `firing_budget`. [D-181][d-181] records what that
buys.

**Budget exhaustion degrades; it does not throw** ([D-181][d-181]). When an
event has fired `firing_budget` times at a boundary, its further edges there
are lost for the rest of that boundary. The eligibility test skips it while
every other event iterates normally. A lost edge emits a `FiringBudget` warning
([§13.2][s13-2], [Appendix C][sC]), at most once per event per boundary. An
event that fires its budget out and then quiesces lost nothing and warns
nothing. The warning carries the component path, the event name, the boundary
time and the exhausted budget beside the boundary's firing count.

The default of 4 is chosen the way [§10.4][s10-4] chooses 8 for the
[localization budget](#g-chattering) (the count of localizations permitted
within one [frame](#g-frame), one grid step). A legitimate re-enable is one or two firings deep. A toggling
FSM pair chatters without bound. A budget of 4 separates the two without ever
binding on a healthy model. Like every other degradation here, it depends on the
trajectory alone, so the run replays identically.

The doctrine of [§10.4][s10-4] governs both budgets. Neither the boundary
iteration nor re-localization within the frame has a
structural bound, so each takes a budget. The boundary iteration takes
`firing_budget`, per event per boundary, and re-localization takes
`localization_budget`, per frame. Both degrade loudly rather than erroring,
under a warning that names the offending event. They differ only in what
exhaustion sheds. Localization sheds root-finding precision and preserves every
firing at boundary granularity. The firing budget sheds firings, which is
exactly what bounds the iteration.

#### Ticks after quiescence

**Ticks stay outside the iteration, after quiescence** ([D-020][d-020]). The
two possible couplings resolve asymmetrically.

- From events to ticks, machinery already in place handles the coupling. Due
  discrete components' output stages (`y_state`/`y_direct`) are gated into the
  boundary sweep against a due set fixed for the whole iteration
  ([§10.5][s10-5]). Every iteration round therefore refreshes them for free,
  against the same `s` and post-transition inputs. Their `s_update` has not
  run yet. At quiescence, their published outputs reflect the settled boundary
  instant, which is exactly what "sampling at t" should mean for a logically
  instantaneous cascade. Earlier rounds' tentative values are internal scratch,
  like RK stage evaluations. [§10.3][s10-3] states when external readers may
  observe the table.
- From ticks to events, a coupling is structurally impossible. A tick's output
  stages contribute nothing guards have not already seen, since they run inside
  the sweep, from current `s`. Its `s_update` writes `s⁺` after the sweep, and
  `s⁺` is first decoded at the owner's next tick. So `s⁺` is invisible to every
  reader within the boundary. This is the standard one-sample `z⁻¹` delay of
  sampled-data control, enforced here by construction. Nothing that happens
  after quiescence can flip a guard, so there is no combined event/tick fixed
  point to iterate.

The boundary macro-sequence, in its final form, is the following.

> integrate → project → [sweep → guards → handlers] iterated to quiescence
> (under the firing budget) → all due `s_update` calls → logging / I/O staging.

Boundary zero is the same sequence with an empty integrate ([§14.5][s14-5],
[D-067][d-067]).

The sequence decides the mixed case, where the handler of a
[continuous component](#g-continuous-component) (the hybrid primitive, with
continuous state, modes and events) and its discrete observers' ticks land on
one boundary. Take an engine's `starting → running` transition under a 50 Hz
flight control system (FCS). The engine is a continuous component, and the FCS
is a discrete component that observes it. The transition fires in the iteration
segment. The re-sweep re-runs the FCS's stages against `running`-mode ports, and
its `s_update` then runs from post-transition values.
