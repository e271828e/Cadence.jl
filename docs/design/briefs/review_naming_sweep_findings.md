# Cold review: the naming sweep

Range `da182b2..d0025c4`, 26 commits. Reviewed against the Naming section,
the inventory README's rulings, the brief, the per-file reports and the
rulings the waves added.

**Gate:** green. Full suite under the sandbox flags, 3175 of 3175 passed,
equal to the baseline. `git diff --stat da182b2..d0025c4 -- test/` is
empty.

No non-rename change was found. The word diffs show renames and rewraps
only. No keyword at a call site, field access, string or literal changed.
The one function rename, `_undeclared_violation`, is complete. Every
`catch` in `src/` is `catch err` or the inner `catch lookup_err`.

## Findings

### Wrong renames: a ruling overrides the row, and the row was applied

1. `src/trace.jl:70–71`, 8178617. `Base.:(==)(record::TraceBatch, other::TraceBatch)`.
   R10 keeps operator operands `a`, `b`. Every other `==` in `src/` keeps
   them. Fix: `a`, `b` in this method; `Base.hash(record, seed)` on line 72
   stays.
2. `src/conditions.jl:562–564`, 5e45aca. `Getter`'s generated body loops
   over `path_step`. `step` is a Base name the package never calls, so it
   keeps. Fix: `step` again; `access` stays.
3. `src/conditions.jl:500, 504`, 5e45aca. `assert_total(…, operation::Symbol)`.
   `op` is on the roster for a lifecycle payload's operation. Fix:
   `op::Symbol` and `UninitializedInputs(op = op, …)`.
4. `src/sim.jl:659, 663, 682, 684`, 129e4a7. `log` became `log_switch` in
   `_check_recording` and `_open_run!`. `log` is a Base name the package
   never calls, so it keeps. Fix: `log`. `trace_switch` stays, since `trace`
   is a package function. See the user list, item a.
5. `src/build.jl:1140, 1144, 1149, 1161, 1165`, 303be16. `_probe_direct!`'s
   `s1` became `stage1_product`. R5 keeps `s1` beside `y1`/`y2`, and
   `probe_stage2` kept it at line 1042. Fix: `s1`.
6. `src/build.jl:1209–1210`, 303be16. `probe_events(structure, nominal::Activation{Float64})`.
   `act` is a roster word, and there is only one activation in scope. Fix:
   `act`.
7. `src/diagnostics.jl:68`, 423779a. `_at_path(path)`. R7 names
   `_at_path(p)` as a keep. Fix: `p`.
8. `src/diagnostics.jl:1288`, 423779a. `_sup(power)`. R7 names `_sup(n)` as
   a keep. Fix: `n`.
9. `src/diagnostics.jl:1169`, 423779a. `_advance_entry(operation::Symbol)`, a
   one-line method called with `d.op`. `op` is a roster word. Fix: `op`.
10. `src/readers.jl:269–272`, f01e1d8. `_rviol(…; payload...)`. `kw` is on
    the roster. Fix: `kw...` in the signature and the splat.
11. `src/trim.jl:496–498`, 41d103d. The misuse method
    `trim!(::Simulation, problem; kw...)`. The rule keeps `other` in a
    misuse method as a deliberate contrast, and `readers.jl:233` kept it.
    Fix: `other` in the signature and in `string(typeof(other))`.
12. `src/show.jl:18–19`, d0025c4. `_count(number::Int, noun)`, a one-line
    method split over two lines. `n` has no other meaning in `show.jl`, so
    the five-line rule keeps it. Fix: `n`, back on one line.

### Missed rows

13. `src/assembly.jl:861, 863, 868, 875, 876, 878, 879, 883`, faa9f98.
    `_check_sample_times`'s local function `_rv` keeps its old name. The
    row renames it to `record_violation`, and no ruling overrides that.
    Its `kw...` stays because `kw` is a roster word.
14. `src/leaves.jl:334, 335, 338, 340`, 31d8564. The row renames
    `flatten_state!`'s local `Xs` to `state_fields`. `Xs` is a spliced
    value, not an emitted name or a type parameter. Fix: `state_fields`.
    See the user list, item h.
15. `src/build.jl:366–385`, 303be16. The row was applied as `ncomponents`,
    8 sites. The brief's underscore bullet requires `n_components`.
16. `src/declare.jl:309–329, 341–349`, fd71539. `bundle_names` and
    `event_bundle_names` hold the bundle's field names as `fields`. The
    ruling spells them `bundle_fields`, as `build.jl` and `tracer.jl` do.
    Fix: `bundle_fields` in both functions.
17. `src/readers.jl:310, 326, 345` and their uses (`decls.x`, `decls.s`,
    `decls.outs`), f01e1d8. `decls = act.decls[ci]` holds one `Decls` row.
    The shared-concepts table spells it `decl`, as `build.jl`,
    `conditions.jl` and `tracer.jl` do. Fix: `decl`.
18. `src/diagnostics.jl:95–96`, 423779a. `DiagnosticError(ds::AbstractVector{<:Diagnostic}, …)`
    keeps `ds`. The row renames it to `carried`, and no ruling overrides
    that. `_groups` renamed its own `ds` to `diags`. Fix: `diags`, or
    `carried` as the row says.
19. `src/trim.jl:186, 189, 209, 219, 221`, 41d103d. `solve`'s local `nevals`
    was not renamed. The brief renames the tree's `nevals` to `n_evals`
    whether or not a row lists it. Fix: `n_evals`, returning
    `nevals = n_evals` in the three NamedTuples. `_verdict!`'s
    `nevals`/`niters` parameters mirror `TrimReport`'s fields and stay.
20. `src/sim.jl:281, 282, 284`, 129e4a7. `_stop_faces` holds a compiled
    root-cell address as `address`. The report proposed `address`, but the
    shared-concepts table wins, and every other site spells it `addr`. Fix:
    `addr`.

### Rules violations

21. `src/store.jl:93, 95, 99, 101`, 8b6ba4a. `scatter_group!`'s loop
    variable became `port`, which is a package function (`port(snapshot, …)`,
    `port(sim, …)`). C4 renames `port` locals to `port_name`/`output_port`,
    and `path`/`build` are rule 6's only exceptions. The report's proposal
    predates C4. Fix: `port_name`.
22. `src/show.jl:204, 206, 207`. `_feedthrough` destructures
    `(producer, port)`, which shadows the package function `port`. The line
    predates the sweep and the report missed it. Fix: `port_name`.
23. `src/show.jl:50–52`. `_warning_lines(warnings::Vector{Diagnostic})`
    shadows the package function `warnings`. The line predates the sweep and
    the report missed it. Fix: `warning_list`, as C4 names it elsewhere.
24. `src/roster.jl:224, 225, 230, 231`. `_claim`'s local `faceset` fuses
    two words. The line predates the sweep and has no row. Fix: `face_set`.
25. `src/build.jl:455` and the rest of `_tarjan`. `onstack` fuses two
    words. The line predates the sweep and has no row. Fix: `on_stack`.
26. The brief requires a line that the rename pushes past the file's width
    to be rewrapped. These lines were at or under their file's usual width
    before the sweep and are now past it, most past 100 columns. Other lines
    in the same commits were rewrapped, so the practice is uneven. Fix:
    rewrap each line as its neighbours are wrapped.
    - `build.jl` (303be16, af318de): 85, 204, 280, 371, 377, 603, 812, 1144,
      1226, 1270, 1286, 1389, 1477, 1537, 1546, 1573, 1604.
    - `leaves.jl` (31d8564): 84, 104, 177, 194, 252, 283, 346.
    - `conditions.jl` (5e45aca): 110, 111, 164, 189, 214, 215, 309, 442,
      455, 788, 838, 839, 840, 850.
    - `deployment.jl` (7e588a3): 17, 60, 74, 87, 90, 186, 218, 228, 265,
      361, 385.
    - `trace.jl` (8178617): 71, 198, 201, 266, 299, 320, 326, 363, 403, 414.
    - `readers.jl` (f01e1d8): 99, 100, 101, 131, 176, 257, 259, 271, 287,
      313, 332, 338, 341, 348.
    - `trim.jl` (41d103d): 221, 269, 291, 517, 534, 581, 587.
    - `diagnostics.jl` (423779a): 95, 115, 128, 136, 262, 905–907, 1312,
      1314, 1695, 1701.
    - Comment and docstring lines past the 80–82 columns their paragraphs
      keep: `sim.jl` 147, 1098, 1449, 1724 (129e4a7) and 1450 (e302bbd);
      `stepper.jl` 7 (a007cb5).

### Docstrings and comments

27. `src/build.jl:556`, 303be16. The comment "A mutable `P` is left to
    `place!`'s own arm" names the local that became `cell_type`. Fix:
    "A mutable `cell_type`". The `P()` at line 565 names the synthesis chain
    and stays.
28. `src/sim.jl:611`, 129e4a7. The comment above `_nonfinite` reads "The
    owner of flat index `i`", but the parameter is now `flat_index`. Fix:
    "The owner of `flat_index`".
29. `src/dataplane.jl:587`, cca7cad. `Snapshot`'s docstring reads
    `port(snap, path, name)`, but the parameter is now `snapshot`. e302bbd
    fixed the matching `gather(handle, snap)` lines. Fix:
    `port(snapshot, path, name)`.

## For the user

a. **`log_switch`** (finding 4). It pairs with `trace_switch`, but the
   ruling keeps `log`. If you accept it, drop finding 4.
b. **`asm` on public signatures.** faa9f98 renamed `asm` to `assembly` in
   `resolve`, `resolve_terminal`, `input_passthrough` and
   `output_passthrough`, docstrings included. The spec spells it `asm`
   (`spec.md` 3138, 8152, 8159, 10262, 10267; `decisions.md:1681`). R2 says
   a public signature keeps the spec's spelling. The options are to revert,
   or to update the spec.
c. **`attach!`'s binding parameter.** `sim.jl:1467` spells it `new_binding`.
   The spec (`spec.md:10334`) spells it `binding`, which is also a package
   function called in that scope. The base code used `b`.
d. **`Period(period)`** (`declare.jl:128–130`). The brief ordered it. But
   `period` is a package function, and the parameter mirrors the field
   `Period.T`.
e. **`build()` holds its `Build` as `built`** (`build.jl` 730–768). The
   shared-concepts table says `build`, and the local would shadow the
   function it sits in, which does not call itself. No row covers it.
f. **`activation(build, T)`** (`build.jl:935–940`). The rename `act` →
   `derived` beside `nominal` is naming by role. It still renames away from a
   roster word.
g. **Field-mirroring parameters renamed for a collision.**
   `EventSet(…, event_names, …)` (`executor.jl:278`, field `names`, and
   `Base.names` is never called); `SnapshotLog(…, log_max)` (`dataplane.jl:655`,
   field `max`, and `Base.max` is called); `DiagnosticError`'s
   `warning_list` (field `warnings`, a package function). Here the collision
   rule won over the field rule.
h. **`Xs`** (finding 14). If `X` counts as a spec symbol, R5 keeps `Xs` and
   the finding drops.
i. **Tiny-method renames R7 might revert.** `readers.jl` 83–85, 98, 163–176
   (`_index_arg(i)`, `_ipart(i)`, `_take(v, i)`, `_read`'s `r`);
   `diagnostics.jl:892` (`_hop`'s `q` → `output_port`); `leaves.jl` 140, 185
   (`_flatten_expr`'s and `_mflatten_expr`'s `v` kept, though it is spliced,
   not emitted).
j. **`entry` with two meanings.** In `readers.jl:258`, `entry` holds the
   description string passed to `resolve_authored`, while the file's other
   `entry` locals hold read entries. In `build.jl` 1538–1539 (`compile`),
   `entry` holds a `ProjectEntry` beside `ComponentEntry` elsewhere.
k. **Other unrostered or fused names without a row.** `kid_path`
   (`assembly.jl:1094`, against the brief's `child_path` example), `kid`
   (`conditions.jl` 187–189), `upto` (`sim.jl`), `t_to` (`localization.jl`),
   `lo`/`hi` (`localization.jl:200`, kept as the paper's symbols),
   `component_count`/`event_count` in place of `n_<word>` (`executor.jl`,
   `sim.jl`, `localization.jl`, `assembly.jl`), `N_base_sound` and
   `N_base_resolved` (`deployment.jl`).
l. **`_passes_frame(e)`** (`build.jl:22`) keeps `e` for a caught exception
   under the short-method clause. The `err` convention argues for `err`.
m. **`offs`/`off` in `cell_layout`/`establish_defaults!`** (`build.jl`
   533 onward) became `offsets`/`offset`. These are neither generated names
   nor spec derivatives, so the rename looks right. The brief's keep list
   names `offs`.
n. **Layout drift.** Continuation lines were not realigned after a rename
   moved their opening bracket. Examples: `build.jl` 197, 201, 290, 441–443,
   604, 1092, 1150, 1224, 1547; `readers.jl` 307, 323, 342, 356, 367; `sim.jl` 268,
   661; `executor.jl` 333–334; `dataplane.jl:528`; `devices.jl` 99, 101;
   `roster.jl:271`; `trim.jl` 390–393; `diagnostics.jl` 33–34. Some rewraps
   also restructured code more than a plain wrap would: `_species`'
   ternary chain (`sim.jl` 1289–1297), two trailing comments moved above
   their lines in `_crossing` (`localization.jl` 214, 217), and
   `tracer.jl`'s `_trace_direct`/`_trace_sampled` signatures.
o. **The frozen README.** The brief says the README stays frozen. e55c249
   edited its C4 line to record the `Group(children)` ruling.

## Adjudication (2026-09-23, ruled with the user)

The fixer applies exactly this list, in one commit, and nothing else.

**Fix as found:** findings 1, 2, 3, 5, 6, 9, 10, 11, 13 to 25, 27, 28, 29.
Finding 18 takes `diags`. Finding 16 covers both functions.

**Drop:** findings 4 (`log_switch` stays beside `trace_switch`: role naming
of a pair), 7, 8 and 12 (the tiny-method clause permits a letter, it never
forbids a word), and item i for the same reason.

**Finding 26 and item n:** rewrap every line the sweep pushed past its
file's width, and realign every continuation line whose opening bracket a
rename moved, as their neighbours are wrapped. Items n's restructured
rewraps (`_species`' ternary chain, `_crossing`'s moved comments, the
`tracer.jl` signatures) stay as they are.

**From the user list:**

- b. `asm` → `assembly` stands. The spec now spells it so (a423f9e).
- c. `attach!`'s `new_binding` stands: the spec's `binding` would shadow
  the `binding` function called in that scope. Record it in the README's
  C3 as the one public signature whose spec name cannot be used.
- d. `Period(period)` reverts to `Period(T)` in both constructors, and
  `Hz`'s derived value too if it feeds the field: the parameter mirrors the
  field `Period.T`, and `period` is a package function.
- e. `build()`'s own result stays `built`: `build` would shadow the
  enclosing function.
- f. `activation(build, T)`'s `nominal`/`derived` stand: two activations in
  one scope, named by role.
- g. `EventSet`'s `event_names` reverts to `names` (field mirror; `Base.names`
  is never called). `SnapshotLog`'s `log_max` and `DiagnosticError`'s
  `warning_list` stand: their fields' names are a called Base function and
  a package function.
- h. `Xs` → `state_fields` (finding 14).
- j. `readers.jl:258`'s `entry` → `description`; `build.jl`'s
  `ProjectEntry` local in `compile` → `projection_entry`.
- k. `kid_path` → `child_path`, `kid` → `child` in `conditions.jl`;
  `component_count` → `n_components`, `event_count` → `n_events` wherever
  they hold a count. `upto`, `t_to`, `lo`/`hi`, `N_base_sound`,
  `N_base_resolved` stay.
- l. `_passes_frame(e)` → `_passes_frame(err)`.
- m. `offsets`/`offset` in `cell_layout`/`establish_defaults!` stand.
- o. The README edit stands; the brief's "frozen" meant the reports.
