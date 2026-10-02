# Notes: increment 58, the overnight run of 2026-10-02

The coordinator's rulings while the user was away, each with its reason, and
the open points left for the user. Nothing here is pushed.

## Rulings made

1. **Stage 1's block order stands.** The rewritten "Compile cost" block does
   not follow the ruling's item order. It runs chunking, then what chunking
   buys and costs and the chunk size, then the unroll, the by-reference rule,
   the declaration layer, the figures and the mitigations. Reason: the brief
   fixes the block's content, not its order, and the unroll rule speaks of
   chunk tuples, so chunking has to come first. The cold reviewer checks the
   content claim by claim.
2. **`_walkchunks` becomes `_walk_chunks`** (stage 2, `6033671`). The brief
   names the chunk walk `_walkchunks` and fixes no new name for it. Reason:
   "Naming" applies to touched code and says a package function joins its
   words by underscores, which is the same reasoning the brief gives for
   `_proj_walk` → `_project_walk`. Stage 3's reference patch needs the new
   spelling in two hunks.
3. **The `src/executor.jl` row's Spec line cites D-289** (stage 2). The brief
   did not ask for it. Reason: the row now describes a rule D-289 holds.

4. **Stage 5's closures read the instance through a `Ref`, beyond the
   patch** (`fc63292`). On Julia 1.13 a closure that captures a
   `@nospecialize` argument stores it untyped. On 1.12, the floor
   `Project.toml` declares, the same closure is typed per argument type, and
   the patch alone still grew 25 methods per new component type there. Stage
   5 made every success-path closure in the layer capture-free
   (`unspecialized = Ref{AbstractComponent}(...)`, loops in place of
   comprehensions and of a `get!` closure, `_workspace` taking the entry).
   Reason for accepting: the brief's principle says a per-component closure
   reads the instance from an unspecialized binding, and on the floor version
   only this form does. It changes code the report measured, so the cold
   reviewer re-measures the stack and checks the trajectories' hashes.
5. **`probe_events`' `map` closure became a loop** (stage 5), the brief's
   known remainder, fixed by a local change as the brief allows.
6. **The specialization test passes its models through an inference
   barrier and counts only methods defined in the three layer files.**
   Reason: without the barrier, compiling the test function compiles `build`
   for the fixture types before the first count, so the test is green at the
   tip; and `flatten!` is also the leaf walk's name in `leaves.jl`.
7. **The `Dual` sweep's pinned skipped count goes from 59 to 61** (stage 5),
   for the two new fixtures, which take an argument. That is the mechanism
   the pin's comment describes.

## Open points for the user

- **D-288's Rationale is stale.** It says D-086's chunking and mitigation
  ladder "wait on the compile-time ruling in `pending.md`". D-289 is that
  ruling. A dated annotation would fix it. The brief puts any log edit beyond
  stage 1's out of scope, so it is untouched.
- **Two `Base.tail` recursions remain in `src/conditions.jl`** (lines
  777–787, `_writes!` and `_sweep_prefixes`), over the condition plan's
  tuples. §9.7's rule covers entry and chunk tuples, so it does not reach
  them by its letter, and the brief's scope does not either. Whether a
  condition plan can pass 32 elements, and so whether the rule should widen,
  is a ruling.
- **`_walk` is one generic with two meanings.** `src/tracer.jl:141` defines
  `_walk(::Type{T}, v, f)`, the tracer's leaf walk, and `src/executor.jl`
  defines `_walk(entries, store, xbuf, ẋbuf)`. "Naming" says a generic has
  one meaning across its methods. It predates this increment. Stage 2
  proposes renaming the tracer's to `_walk_leaves` in a later change.

- **The brief's "equal by value" means `===`** in stage 4's cache, which is
  an `IdDict`. Two `==`-equal instances holding distinct mutable fields get
  two keys. That is sound, since each key's list is its own value's, but the
  brief's wording is loose.
- **`Group`'s docstring says "specialization is unchanged".** After stage 5
  that is true of the executor only. The brief forbids touching `Group`'s
  definition, and stage 5 read that as covering its docstring.
- **`flatten!` names two things**: the build walk in `assembly.jl` and the
  generated leaf walk in `leaves.jl`. It predates this increment, as `_walk`
  does.
- **The declaration surface stays specialized**: `declare.jl`'s one-line
  fallbacks and `Group`'s five declaration methods still compile per type.
  Stage 5 left them as the declaration surface itself, costing what any
  user's declaration costs.

## Carried to the cold review

- **Stage 3's third test cannot go red** (`9bc2074`). A body with no gated
  entry already has one type in both tuples at the tip, and `rhs(3)` already
  equals `rhs()` there. Deleting the `PhaseBody{I,I}` method leaves it green.
  The brief asked for exactly this test, so it stands, but the reviewer is
  told not to count it as stage 3's mutant catcher.
- **Stage 3's second test is weak against reordering.** Its 40 loops are
  identical, so equality across chunk sizes catches a dropped partial chunk
  and not a reordered one. Varying the saw rates would strengthen it. Left
  for the fixer if the reviewer agrees.
- **Half of stage 5's tests bite only on Julia 1.12.** Removing the
  `local comp = unspecialized[]` reads is red on 1.12 and green on 1.13, so
  the reviewer runs the two specialization testsets under 1.12 as well.

## The cold review

The reviewer changed nothing and left its evidence in
`/tmp/cadence58_review/`. At `fc63292`: the gate is green, 4317 of 4317, on
Julia 1.13 and, with a fresh manifest in a scratch copy, on 1.12.7. The
three scenarios' first simulations took 0.830, 0.924 and 3.496 s against the
expected 0.85, 0.96 and 3.6 s. Every allocation count is 0, the three
`xhash` values match, and `mechanism.jl` gives the report's row. The landed
diff differs from `recommended.patch` only in names, comments, docstrings and
the deviations the stages reported.

Findings accepted and handed to the fixer:

8. **`_fanout`'s generator captures the assembly**, so on 1.12 a new root
   type that fans an input compiles the resolution chain again (`build` of
   the repeated root 3.62 s against 0.54 s with the fix). A loop replaces
   it, with a third specialization testset that fans an input. The test can
   fail only on 1.12.
9. **The size test's formula changes.** The brief counts the event set's two
   tuples in the executor's size. Event chunks sit behind the `EventSet`
   pointer, so they do not add to it, and `feedback_model` has no events, so
   the brief's test never exercised them. The test now counts phase-body
   chunks only and asserts the event set's own shape: it is mutable, and
   each of its tuples is one pointer per chunk. Reason: `EventSet` immutable
   and `EventChunk` immutable both survived as mutants, and the second
   brings back 40 `memcpy` in `_guards!`.
10. **The event walks' allocation tests run at chunk sizes 1 and 40.** At the
    default size no event walk passes 32 elements, so a `Base.tail`
    recursion there survived.
11. **A specialization assertion guards the `PhaseBody{I,I}` method**, and
    the chunk-border test gets one rate per loop so a reordering shows.
12. **One spec phrase**: the bold "Its projection, guard and handler walks
    chunk the same way" takes "The event set's" as its subject.

Findings left for the user:

- **`apply!` allocates past 32 writes** (`src/conditions.jl` 777–787, the
  two `Base.tail` recursions). Measured: 0 B at 32 writes, 2 176 B at 33,
  19 200 B at 40, 102 336 B at 64, and 145 ns against 64 µs. Each `at(...)`
  adds a prefix and each leaf a write, so a condition over 33 components
  crosses the limit, against §14.4's "no allocation". Trim's Newton loop
  calls `apply!`.
- **`gather_reads` allocates from 32 reads** (`src/readers.jl:368`, a `map`
  over `Reader.entries`): 1 888 B at 32, nothing at 31.
- Both predate the increment. §9.7's rule says "every walk over an entry
  tuple", and a `Reader` has an `entries` tuple, so whether D-289 reaches
  them is a ruling. `_unrolled` is usable in both files.
- **1.12's `build` of the repeated root stays near 0.5 s** with finding 8
  fixed, against 0.065 s on 1.13. No Cadence method grows there; the
  reviewer did not find where the time goes. §9.7's figures are 1.13's.
- **`run!` allocates about 800 B per step** on base and HEAD alike, on every
  model, with all bodies and event walks at 0. Outside the increment and not
  traced.

## The fix and its verification

The fixer landed `6be1f17`, "Fix increment 58's review findings". The
reviewer, resumed with its context, verified the delta and found no defect.
At `6be1f17`:

- The gate is green, 4330 of 4330, on Julia 1.13 on the real tree and on
  1.12.7 in a scratch copy. The 13 assertions over the base's 4317 are the
  added tests.
- The five mutants that survived the review are killed, by the reviewer's
  own runs. The fan-out testset is red on 1.12 with the generator restored
  and green with the loop.
- First simulations took 0.815, 0.925 and 3.515 s against the expected 0.85,
  0.96 and 3.6 s. Every allocation count is 0 and the three `xhash` values
  match.
- The docs battery is green.

Beyond the accepted findings, the fixer:

13. **Made the two error-path closures capture-free** (`_holds_components`,
    `_container_fields`), so no closure in the layer captures the instance,
    apart from the one in `compile` the brief puts out of scope. The
    reviewer checked the three loops return what the originals returned and
    that no diagnostic changed.
14. **Renamed `event_names` to `declared_names` in `probe_events`.** Stage 5
    introduced that local, and `compile` already uses the name for the
    model-wide list.
15. **Added one sentence to the `src/assembly.jl` row**: functions that take
    a connection or its endpoint tuple still compile once per connection
    type.

One more open point for the user, from that sentence:

- **§9.7 and D-289 state the declaration-layer rule without exception**:
  code that runs once per build "does not compile again per component type
  or per root type". Four helpers keyed on a connection (`_fanout`,
  `_endpoints`, `_entry`, `_check_face_names`) still grow by one
  specialization for a root of a new width, on both Julia versions. The
  cost is small: the whole `build` of a new 128-component root is 0.065 s.
  Either the spec names the exception or the four helpers take the
  connection unspecialized. The reviewer tried the second on 1.12: the
  growth list went empty and the time did not move (0.54 to 0.51 s).

The arc is `6dfb50d..6be1f17`, six commits on `00bd81a`.

## How the open points ended

Settled with the user on 2026-10-02, after the run:

- **The connection-keyed helpers stay specialized.** §9.7 and D-289's
  Position now say what still compiles per type: a component's own
  declaration methods, and the helpers that take a declared value such as a
  connection (`a129c51`). The same sentence covers the declaration surface
  that stage 5 left specialized.
- **D-288 takes an annotation** naming D-289 as the ruling it waited on
  (`a129c51`).
- **`Group`'s docstring** says the specialization its type parameters keep
  is the executor's (`8bc49d6`).
- **The polysemic names are renamed.** The tracer's `_walk` is
  `_map_leaves`, the build walk's `flatten!` is `flatten_tree!`, the
  stepper's `_advance!` is `_stage_point!`, and the tracer's `_seed` is
  `_seed_face` (`8bc49d6`). The stepper seam's `step!(sim, h)` and
  `step!(stepper, sim, h)` are `integrate!`, so `step!` names the API's
  frame advance alone (`4eb2d5a`).
- **1.12's slower `build` of the repeated root** is accepted as it stands.

Still open when this file was committed, with a read-only investigation
running on both:

- the walks past 32 elements in `src/conditions.jl` and `src/readers.jl`,
  and whether D-289 reaches them;
- the roughly 800 B that `run!` allocates, on 1.13 as on 1.12.
