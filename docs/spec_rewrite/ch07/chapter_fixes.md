# Chapter 7: editorial fixes applied

The fixer's log of `chapter_pass.md` items as ruled in `chapter_rulings.md`.
Each entry gives the item, the unit file, the old text and the new text, in
single-spaced source form. Every edited claim carries the item in its
inventory `ruling` field; new words are listed in `added`.

## Notes on how items were applied

- **E3.** "Its type" became "The value's type": after "for a component",
  "Its" could read as the component's. The next sentence's "It passes"
  became "The framework passes", since "It" now followed a sentence about
  the type.
- **E14, E16, E17 at §7.5's scope paragraph.** E14's phase-body gloss and
  E17's snapshot gloss would give one sentence two parentheticals, so the
  sentence splits after its first citation. The second sentence opens with
  "Publication's" rather than "Its", which would read as the phase body's.
  E16's boundary gloss there drops, as ruled.
- **E16 at §7.4.** "It copied the buffer (gloss) into cells (gloss)" would
  carry two parentheticals. The buffer keeps E7's gloss; the cells gloss
  drops.
- **E17, view.** The gloss is the glossary's *view* entry's words: "(zero-copy
  reconstructions of a store)". The glossary's *store* entry makes an `x`
  store a range of the buffer, so "store" fits state views.
- **E10.** No word changes. The reason paragraph now follows the `ws_init`
  rule, and "Nothing in the workspace contract ... They don't run marathons."
  follows the reason as its own paragraph.
- **E18.** Every edited paragraph and every paragraph E18 names is rewrapped
  greedily at 80 rendered columns, link markup collapsed, with no word changes.
  The bullet continuation paragraph in §7.5 keeps its two-space indent.
- **K1, companion.** "the walked tier of §7.2" maps to no inventory claim
  (the claim there maps only "about 25 structs"); the pinned-class change
  updates claim C-031 of unit B.

## Edits

**E1** · `A/new.md`

- Old: This chapter fixes where data lives, on both tiers and outside them. It fixes the homes the declared state occupies and how each home holds its values.
- New: This chapter fixes where data lives and how each home holds its values.

**E1** · `A/new.md`

- Old:  The allocation policy closes the chapter.
- New: (deleted)

**E2** · `A/new.md`

- Old: against FlightCore's mutable-view pattern.
- New: against FlightCore's mutable-views pattern.

**E17** · `A/new.md`

- Old: structure comes from the component tree
- New: structure comes from the [component](#g-component) tree

**E3, E17** · `A/new.md`

- Old: It reconstructs the typed immutable state value for a [component](#g-component) at each evaluation. It passes that value to every function receiving state views, under
- New: It reconstructs the typed immutable state value for a component at each evaluation. The value's type, `X`, is derived from `x_init`. The framework passes that value to every function receiving state [views](#g-view) (zero-copy reconstructions of a store), under

**E16** · `A/new.md`

- Old: in `x_projection` at [boundaries](#g-boundary) and in writers
- New: in `x_projection` at [boundaries](#g-boundary) (published consistency points) and in writers

**E5** · `A/new.md`

- Old: FlightCore's in-place derivative function, performs on its raw views.
- New: FlightCore's in-place derivative function, performed on its raw views.

**E4** · `A/new.md`

- Old: (the scalar type `T` an activation is built at)
- New: (the scalar type `T` at which the build types the model)

**K6** · `A/new.md`

- Old: Against that pattern, this design buys five things.
- New: Against that pattern and the Flight.jl code around it, this design buys five things.

**E7** · `B/new.md`

- Old: (the framework-owned flat vector backing continuous state)
- New: (the framework-owned contiguous vector backing all continuous state)

**K1** · `B/new.md`

- Old: states the three tiers that scope this genericity
- New: states the three classes that scope this genericity

**K1** · `B/new.md`

- Old: has three tiers ([D-011][d-011])
- New: has three classes ([D-011][d-011])

**K1** · `B/new.md`

- Old: On the continuous tier a `Float64` leaf
- New: On the continuous [tier](#g-tier) (the continuous or discrete side) a `Float64` leaf

**K1** · `B/companion_addition.md`

- Old: the walked tier of [§7.2][s7-2]
- New: the walked class of [§7.2][s7-2]

**K1** · `B/companion_addition.md`

- Old: the pinned tier of [§7.2][s7-2]
- New: the pinned class of [§7.2][s7-2]

**E7** · `C/new.md`

- Old: (the contiguous vector backing all continuous state)
- New: (the framework-owned contiguous vector backing all continuous state)

**E17** · `C/new.md`

- Old: discipline as the table's [cells](#g-cell)
- New: discipline as the [signal table](#g-signal-table)'s [cells](#g-cell)

**K5** · `C/new.md`

- Old: never touch the integrator buffer
- New: never touch the buffer

**E8** · `C/new.md`

- Old: Isbits is an immutable value that holds no references, transitively.
- New: An isbits value is immutable and holds no references, transitively.

**K4, E17** · `C/new.md`

- Old: Bulk data and labels do not, and their home is the component instance.
- New: Bulk data and text do not, and their home is the [component](#g-component) instance.

**E17** · `C/new.md`

- Old: workspace is [component](#g-component)-declared mutable scratch
- New: workspace is component-declared mutable scratch

**E11** · `C/new.md`

- Old: **A workspace is declared by allocation** ([D-077][d-077]).
- New: **A workspace is declared by allocation**, never by initial value ([D-077][d-077]).

**E11** · `C/new.md`

- Old: It puts that fact in the declaration. That is the by-allocation convention this declaration actually lives in. Declaration is by allocation, never by initial value ([D-077][d-077]).
- New: It puts that fact in the by-allocation declaration itself.

**E9** · `C/new.md`

- Old: The [blessed](#g-blessed) (explicitly sanctioned) idiom for zero-allocation ticks with immutable `s` does the in-place math (`mul!`, `cholesky!`, BLAS) on the workspace ([D-013][d-013]).
- New: The [blessed](#g-blessed) (explicitly sanctioned) workspace-plus-snapshot idiom for zero-allocation ticks with immutable `s` does the in-place math on the workspace, with `mul!`, `cholesky!` or BLAS ([D-013][d-013]).

**E9** · `C/new.md`

- Old: in the same shape as the Kalman idiom above.
- New: in the same shape as the workspace-plus-snapshot idiom above.

**E16** · `D/new.md`

- Old: It copied the [buffer](#g-buffer) into [cells](#g-cell) so that
- New: It copied the [buffer](#g-buffer) (the framework-owned contiguous vector backing all continuous state) into [cells](#g-cell) so that

**E12** · `D/new.md`

- Old: Every causal framework meets the shared-computation problem and resolves
- New: Every causal framework meets this overlap and resolves

**E6** · `D/new.md`

- Old: It is also what FlightCore's fused `f_ode!` (its in-place derivative function) did economically
- New: It is also what `f_ode!`, FlightCore's fused in-place derivative function, did economically

**E13** · `D/new.md`

- Old: the policy's three tiers,
- New: the policy's three budgets,

**E14, E17, E16 dropped** · `D/new.md`

- Old: Publication is not a phase body ([D-288][d-288], [§9.7][s9-7]), and its one snapshot allocation per [boundary](#g-boundary) sits
- New: Publication is not a [phase body](#g-measurement-seam) (one of the compiled bodies the loop runs) ([D-288][d-288], [§9.7][s9-7]). Publication's one [snapshot](#g-snapshot) (the immutable per-boundary publication) allocation per [boundary](#g-boundary) sits

**E13** · `D/new.md`

- Old: The policy has three tiers.
- New: The policy sets three budgets.

**E14** · `D/new.md`

- Old: at the phase-body [seam](#g-seam) that
- New: at the measurement [seam](#g-seam) that

**E16** · `D/new.md`

- Old: Periodic [ticks](#g-tick) and event handlers
- New: Periodic [ticks](#g-tick) (the instants a discrete component runs) and event handlers

**E9** · `D/new.md`

- Old: Their allocation is zero by idiom. The idiom is the [workspace](#g-workspace) (component-declared mutable scratch arriving as the `ws` bundle field) and snapshot pattern, plus immutable-value returns.
- New: Their allocation is zero by the [workspace](#g-workspace)-plus-snapshot idiom ([§7.3][s7-3]) and immutable-value returns. A workspace is component-declared mutable scratch arriving as the `ws` bundle field.

**K3** · `D/new.md`

- Old: The per-boundary allocation cost is zero either way.
- New: The reference fields add no per-boundary allocation either way.

**E16** · `D/new.md`

- Old: [Replay](#g-replay) plus the published
- New: [Replay](#g-replay) (the ordinary loop re-driven from the trace) plus the published

**E15** · `D/new.md`

- Old: Arena allocation (Bumper.jl-style) serves
- New: Arena allocation, in the style of the Julia package Bumper.jl, serves

**E10** · `C/new.md`

- Old: (paragraph order) ws_init rule + 'Nothing in the workspace contract ... marathons.' | 'State and cells re-scalar ... allocator's own argument (D-077, D-263).'
- New: ws_init rule | 'State and cells re-scalar ... (D-077, D-263).' | 'Nothing in the workspace contract ... They don't run marathons.' (no word changes)

## Orchestrator touch

- **E12 revised, unit D.** "Every causal framework meets this overlap and
  resolves it per its architecture." became "Every causal framework meets the
  overlap between derivatives and outputs and resolves it per its
  architecture." "this overlap" pointed at the section's first sentence,
  about 25 lines back, across the four steps.
