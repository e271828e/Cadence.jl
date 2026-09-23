# Brief: the naming sweep (Step 3)

Tip at drafting: `ec04f12`, the rules amended after it. Ruled with the user on 2026-09-23. The rules are
`implementation.md`'s "Naming" section (lines 125–187); the rulings and their
reasons are `docs/reports/20260923_naming_inventory/README.md`; the tables
are that directory's one report per source file. This brief never restates
the rules; read the section first, then the README, then this brief, then
the report of each file before touching it.

## Purpose

Apply the inventory's tables to `src/`: every row coded `rename` or
`collision` takes its proposed name, as amended by the rulings below.
Nothing else changes. A commit is a pure rename: the same code, the same
tests, the same assertion total, new names.

## The rulings that override a table row

The reports were written before the README's rulings. Where a row and a
ruling disagree, the ruling wins. The concrete cases:

- a `Build` parameter is `build`, whatever the row says (`b`, `built`,
  `build`): rule 6's second exception;
- a row renaming a local to a name now on the roster reverts to keep: `act`,
  `addr`, `fn`, `io`, `err`, `dev`, `trc`, `op`, `rng`, `kw`, `scc`/`sccs`,
  `ins`/`outs` for `Decls` contents. A row renaming *to* one of these stands
  (`e` → `err`, `a` → `addr`, `ex` → `exec`);
- a row renaming a local that shares a Base name the package never calls
  (`run`, `schedule`, `log`, `step`, `position`, `success`) reverts to keep;
  `names` still takes its proposal;
- a row renaming a parameter of a public signature reverts to keep
  (`trace`, `log`, `condition`, `reads`, `sep`, `only`, `except`, `maxiter`,
  `children` on `Group`, the selectors' `i`). `stage!`'s `pairs` is a
  positional splat no caller can name, so its rename stands;
- a row renaming a spec derivative reverts to keep (`s1`, `offs`, `σs`,
  `xbuf`, `mstores`, `h_r`, `Δtb`); `n_ok`/`n_i` still rename;
- a row renaming a parameter of a method under about five lines reverts to
  keep, unless the letter has a second meaning in the file (`s`, `t`, `m`,
  `h` in `diagnostics.jl` still rename);
- a row renaming a generated-code name reverts to keep: `buf`, `off`, `v`,
  `offs`, `buf<k>`, `stmts` in `leaves.jl`/`store.jl`/`dataplane.jl`, and
  `make_bundle`'s `e` with `_bundle_expr`'s quoted reads in `executor.jl`;
- a row renaming a constructor parameter that mirrors a field reverts to
  keep (`executor.md`'s `fn`, `outs`, `proj`, `idx`; `Resolved`'s
  constructor if any row touches it);
- the seven `diagnostic::…` parameters in `diagnostics.jl` become `d`;
  `dataplane.jl`'s twelve `d` stay;
- `d` in `trim.jl` for the decision vector stays;
- a type-valued local playing a type parameter's part stays capitalized;
  `declare.jl`'s period `T` becomes `period`; `bindings.jl`'s `T::Type`
  becomes `binding_type`; `_typename`'s parameters become `value`, `type`,
  `typevar` (R3: unrelated dispatch types name by what they hold);
- operator operands stay `a`, `b`; `tracer.jl`'s Base overloads take `x`,
  `y`, `z` in both `@eval` loops; the hash seed is `seed` in `deployment.jl`
  and `trace.jl`;
- every `catch e` becomes `catch err`;
- `stage!`'s `pairs` becomes `writes` in `sim.jl` and `devices.jl` in one
  commit, the one two-file commit of the sweep besides the seed;
- `readers.jl`'s `_declares` pair becomes `_undeclared_violation`, the one
  function rename of the sweep;
- every proposal is respelled to the rules' underscore bullet before it is
  applied: `n_decisions`, `n_components`, `n_max` and never `ncomponents`;
  `claimed_by`, `child_path`; `xbuf` and `mstores` stay fused. The tree's
  own `nleaves`, `nevals` and `nx` become `n_leaves`, `n_evals`, `n_x` in
  their files' commits although no row lists them, as do `claimedby`,
  `kidpath`, `kscope`, `klink` and `evset` where a row does not already
  rename them. `x_off`/`x_offs` wait for the field pass.

## Shared concepts, one spelling

The reports were independent; the same thing must not land under two names
in two files. Where a report's proposal for one of these differs, this list
wins, and the handoff notes the row:

| holds | name |
| --- | --- |
| a component instance | `comp` |
| a `ComponentEntry` | `entry` |
| a `Decls` row | `decl` |
| a tier | `tier` |
| the executor | `exec` |
| an activation | `act` |
| the execution cursor | `cursor` |
| a stop policy | `policy` |
| a device control block | `control` |
| a caught exception | `err` |
| a `Build`, `Deployment`, `Simulation`, `Trace`, device | `build`, `deployment`, `sim`, `trc`, `dev` |
| a device handle, a snapshot | `handle`, `snapshot` |
| an address | `addr` |
| a path segment | `segment` |
| a bundle's field names | `bundle` |

## What a commit changes

- the names in the rows, at every use in their scope, including the
  docstring or comment that spells the old name (`startpoint(m)` →
  `startpoint(stepper)`, `_condition`'s blend comment restated in the new
  letters, `implementation.md`'s executor row `(idx − Φ) % D` → `(tick − Φ)
  % D` in the executor commit);
- a line the rename pushes past the file's width, rewrapped as the
  neighbouring lines are; nothing else reflowed;
- nothing else: no reordering, no helper extraction, no comment rewording
  beyond the name, no formatting drift. `git diff --stat` per commit shows
  the files in the row and no other.

A rename is done by reading the scope, never by a file-wide substitution: a
letter that is a field (`entry.path`), a keyword at a call site (`h = …`), a
string, or another scope's binding does not change. After each file, grep
the old spellings the rows list and read every remaining hit.

## Waves

Six agents, sequential, each over one wave, each commit one file except the
two coupled pairs. Each agent's prompt carries this brief's path, the tip
it starts from, and the previous wave's handoff. The commit message is
`Rename <file>.jl's locals per the naming inventory`; a coupled commit names
both files.

| wave | files |
| --- | --- |
| 1 | `build.jl`, `declare.jl` |
| 2 | `assembly.jl`, `tracer.jl`, `conditions.jl` |
| 3 | `sim.jl` (+ `devices.jl`'s `stage!`), `localization.jl`, `stepper.jl`, `deployment.jl` (+ `trace.jl`'s seed) |
| 4 | `executor.jl`, `dataplane.jl`, `devices.jl`, `roster.jl`, `bindings.jl`, `trace.jl` |
| 5 | `diagnostics.jl`, `readers.jl`, `trim.jl` |
| 6 | `leaves.jl`, `store.jl`, `show.jl` |

Model: Sonnet for the waves, the judgment being in the tables; Opus for the
cold review.

## Verification

Per commit, the routed subset for the file under the sandbox flags, read
off `implementation.md`'s "Running the suite" (lines 189–240), which is the
one home of test policy; this brief does not restate it. A file in the
table's last row (`sim`, `deployment`, `store`, `leaves`, `diagnostics`)
runs the gate for its commit. Never run the suite in the background; never
stash, reset or check out the working tree. The assertion total
(`implementation.md`, "To check a refactor for test loss") is read before
wave 1 and after each commit, and must not move.

After wave 6, one Opus cold reviewer over the whole sweep: for each commit,
every ruled row applied and nothing else changed (read the diff against the
report, not the report against the diff); the shared-concepts table held
across files; the old spellings gone (`rg` each report's renamed names as
whole words in its file); the gate green; the assertion total unchanged.
Findings go to the user; a fixer lands one "Fix the naming sweep's review
findings" commit.

## Handoff

Each agent's final message: per file, the commit hash, the rows it deviated
from with the reason (a ruling, the shared-concepts table, a name already
taken in the scope), the docstrings and comments it restated, and the
suite result. Nothing else; the diff is the report.

## Bookkeeping

Landed with this brief: `pending.md`'s "Not yet built" list gains a bullet
for the later passes the inventory named (struct fields that mirror renamed
parameters; abbreviated function names; generated-code names with their
builders; the `test/` wave, own brief). The README and the reports stay
frozen.
