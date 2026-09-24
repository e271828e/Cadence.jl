# Brief: the naming sweep of `test/`

Tip at drafting: `0c0a899`. Ruled by the coordinator on 2026-09-24 under
the user's delegation. The rules are `implementation.md`'s "Naming"
section; the rulings are `docs/reports/20260924_naming_inventory_test/README.md`
(T1–T13, the collisions, the errata), on top of the `src/` inventory's
`docs/reports/20260923_naming_inventory/README.md` §1–§3; the tables are
the test directory's one report per file. This brief never restates the
rules; read the section first, then both READMEs, then this brief, then
the report of each file before touching it.

## Purpose

Apply the inventory's tables to `test/`: every row coded `rename` or
`collision` takes its proposed name, as amended by the rulings. Nothing
else changes. A commit is a pure rename: the same tests, the same
assertion total (3175), new names.

## The rulings that override a table row

The reports were written before the README's rulings. The concrete cases:

- a row renaming a local to `build` in a scope with a bare `build(…)` call
  reverts to a qualifier by the model built (T1: `discrete.md`'s five);
  a row proposing `Cadence.build(…)` or any restructuring is refused;
- a `keep:glance` row, or an untabled glance site, that binds a spec
  letter to a non-spec value renames (T2: `localization.md`'s and
  `events.md`'s glance `m`s become `model`; a `Task` is `task`; a
  termination record is `record`);
- every contract method's `d`, `h` become `dev`, `handle`, tabled or not,
  one-liners included (T3);
- a row naming a second diagnostic or exception by number or by a role
  when the first is dead before the second binds reverts to `d` or `err`
  reused (T4: `d1`–`d4`, `diag`/`diag2`, `paths`, `e2`/`en`/`ep`,
  `trim.md`'s bespoke `…_err`/`…_diag` pairs, `fb`/`cb`); a role name
  stands only where two are alive together;
- a row proposing `cond` or `plan` for an authored condition takes
  `authored`; `captured` for a captured one; `plan` only for a
  `ConditionPlan` (T5; `test_assembly.jl`'s existing `cond` renames too);
- a row proposing `ref` takes `reference` (T6);
- a letter suffix as a role takes a word (T7); `sim2` and `batch1`–`batch4`
  stand;
- `acc` destructured from a NamedTuple keeps (T9); `A`, `B`, `Ad`, `Bd`,
  `tprev`, `no` keep, `N` → `n_steps`, `s_next` → `snext`, `L` →
  `hyperperiod` (T10); `whatif` → `what_if` (T11);
- the pairs of T12 rename together; the label-mirroring destructure in
  `test_readers.jl` keeps;
- T13's list as ruled;
- every proposal is respelled to the rules' underscore bullet before it is
  applied (`n_steps`, `loop_status`, `heun_sim`; `snext`, `xnext` fused as
  spec derivatives).

## Shared concepts, one spelling

The `src/` sweep's table holds (`comp`, `entry`, `decl`, `tier`, `exec`,
`act`, `cursor`, `policy`, `control`, `err`, `build`, `deployment`, `sim`,
`trc`, `dev`, `handle`, `snapshot`, `addr`, `segment`, `bundle`), and the
suite adds:

| holds | name |
| --- | --- |
| a `Group` or component model under build | `model` |
| a comparison simulation beside the one under test | `reference` |
| a spawned `Task` | `task` |
| a termination record | `record` |
| an authored condition; a captured one; a resolved plan | `authored`; `captured`; `plan` |
| a drained `TraceBatch` | `batch` |
| a trace header | `header` |
| a compiled reader | `reader` |
| a `Deployment` | `deployment`, `deployment2` |
| a device writer or its status | `writer`, `loop_status` |
| a test-local diagnostic list | `diags` |

## What a commit changes

- the names in the rows, at every use in their scope, including a comment
  or testset title that spells the old local name (a title naming the
  spec's symbol or an API keyword is not a local and stays);
- a line the rename pushes past 92 columns, rewrapped as the neighbouring
  lines are; nothing else reflowed; continuation lines under a lengthened
  opening realigned with it (the `src/` review's finding 4);
- nothing else: no reordering, no helper extraction, no assertion added or
  removed, no comment rewording beyond the name, no formatting drift.
  `git diff --stat` per commit shows the one file and no other.

A rename is done by reading the scope, never by a file-wide substitution:
a fixture's port or store field (`u.e`, `s.acc`, `(; acc)`), an API keyword
at a call site (`condition = decide_u`, `h = 1//100`), a string, a symbol
(`:d`, `"da"`) and another scope's binding do not change. `\b` does not
close after `!`. After each file, `rg -w` the old spellings the rows list
and read every remaining hit.

## Waves

Four agents, sequential, each over one wave, each commit one file. Each
agent's prompt carries this brief's path, the tip it starts from and the
previous wave's handoff. The commit message is `Rename test_<name>.jl's
locals per the naming inventory` (`fixtures.jl's`, `utils.jl's`,
`CadenceTests.jl's` for the three).

| wave | files |
| --- | --- |
| 1 | `test_build.jl`, `test_declare.jl`, `test_executor.jl`, `test_assembly.jl`, `test_show.jl`, `test_continuous.jl` |
| 2 | `test_trace.jl`, `test_log.jl`, `test_stepper.jl`, `test_diagnostics.jl`, `test_failures.jl` |
| 3 | `test_conditions.jl`, `test_readers.jl`, `test_trim.jl`, `test_discrete.jl`, `test_events.jl`, `test_localization.jl` |
| 4 | `test_devices.jl`, `test_lifecycle.jl`, `test_roster.jl`, `test_bindings.jl`, `test_dataplane.jl`, `test_store.jl`, `test_leaves.jl`, `fixtures.jl`, `utils.jl`, `CadenceTests.jl` |

Model: Sonnet for the waves, the judgment being in the tables and the
rulings; Opus for the cold review.

## Verification

A commit touching one `test_<name>.jl` runs that file alone under the
sandbox flags (`implementation.md`, "Running the suite", the one home of
test policy): `JULIA_LOAD_PATH="@" julia --startup-file=no
--check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test
test/runtests.jl <name>`. A commit touching `fixtures.jl`, `utils.jl` or
`CadenceTests.jl` runs the gate. Every run in the foreground with a
600000 ms timeout, never in the background; never stash, reset or check
out the working tree. The per-file pass count must not move between the
file's run before and after its commit (read it off the run before
editing), and the wave's last agent runs the gate once: 3175, unchanged.

After wave 4, one Opus cold reviewer over the whole sweep, as the `src/`
sweep's: every ruled row applied and nothing else changed, the shared
spellings held, the old spellings gone, the gate green, the total
unchanged. A fixer lands one `Fix the test naming sweep's review findings`
commit.

## Handoff

Each agent's final message: per file, the commit hash, the rows it
deviated from with the reason (a ruling, the shared-spellings table, a
name already taken in the scope), the comments and titles it restated, the
file's pass count before and after. Nothing else; the diff is the report.

## Bookkeeping

After the review, `pending.md`'s "Naming, the `test/` wave" bullet retires
to its three loose ends (the unnamed short fields, `trim.jl`'s `off`, the
prefixed twins), which are a ruling and a loose fix, not a sweep. The
reports and this brief stay frozen.
