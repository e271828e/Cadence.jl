# Brief: the naming inventory of `test/`

Tip at drafting: `b490c5e`; the tip at launch is in each agent's prompt and
in every report's header. The rules are `implementation.md`'s "Naming"
section; the rulings behind them are
`docs/reports/20260923_naming_inventory/README.md`, §1–§3. This brief never
restates either. Read the section first, then the README's §1–§3, then this
brief, then the file.

## Purpose

The `src/` inventory and its sweep have landed; the rules and the roster are
settled. The suite follows the same rules (the section's last bullet), and
this step produces its inventory: every binding the rules touch, what it
holds, and the name it should take. No file changes in this step. The sweep
applies the tables after the coordinator has adjudicated them.

The reports are what the coordinator adjudicates. A wrong proposal costs one
table cell; a missed site costs a second pass. Err towards listing.

## What counts as a site

Every binding in the file that is one of:

- a function or method parameter, positional or keyword, including closure,
  `do`-block and `->` parameters (`failure(() -> …)`, `map(e -> …)`);
- a local bound by `=`, by destructuring, by `for`, by a comprehension or
  generator, by `catch`, or by `let`; a `@testset` body is one scope, and a
  local bound in it lives to the testset's end;
- a local function defined inside a function or testset body.

Out of scope: struct field names, the API's keyword names at a call site
(`Deployment(build; h = 1//100)`, `condition(l.plant; y, v)` bind nothing),
the names of fixture types, ports, faces, stores and store fields (`u.e`,
`s.acc`, `(out = …,)`), which are the fixture author's domain names in the
spec's style and not locals, and global constants.

A site is **flagged** when its name is one or two characters, or an
abbreviation not on the roster, or a name shared with a function the file
can reach: the `import Cadence:` list in `test/imports.jl`, the helpers of
`test/utils.jl` (`walked`, `gated`, `single`, `fed`, `prefixes`, `poke!`,
`paths`, `failure`, `carried`, `accounted`, `crash_accounted`,
`writer_status`), the fixture functions of `test/fixtures.jl`, and a Base
function the file calls. A flagged site the rules permit is counted, not
tabled (see "The report"), unless its permission is arguable.

Read every site in its scope before classifying it. A regex sweep is a
map, never the list.

## Classification

One code per row, the `src/` inventory's codes:

| code | meaning |
| --- | --- |
| `keep:index` | a loop or comprehension index, or `ci` |
| `keep:typeparam` | a type parameter, or a binding playing one's part |
| `keep:spec` | a spec symbol or a derivative (rule 2's list; R5) |
| `keep:glance` | a one-glance binding (rule 2's clause; R7 counts parameters) |
| `keep:family` | the family letter: `d` for a diagnostic, `b` for a binding (R4) |
| `keep:roster` | an abbreviation on the roster |
| `keep:api` | a parameter of a public signature the fixture extends (`loop(dev, handle)`, `map_input(b, datum)`) at the spec's spelling (R2) |
| `rename` | takes the proposed name |
| `collision` | shares a name with a reachable function; the proposal renames the local |
| `roster?` | an abbreviation the agent proposes adding to the roster, with its count |

What the suite adds to the `src/` picture, settled here so the reports do
not split:

- **Fixture stage methods.** `output_direct(c::Gain, (; u)) = (out = c.k * u.e,)`
  is a one-line method: `c` is `keep:glance` under R7, and the destructured
  bundle fields (`x`, `s`, `u`, `y`, `t`, `Δt`, `ws`) are `keep:spec`. A
  fixture method long enough to read twice names its component `comp`.
- **The device and binding contracts.** A fixture's `loop`, `init!`,
  `shutdown!`, `unblock!`, `claims`, `reads`, `map_input`, `map_output`
  method extends a public signature; its parameters are `keep:api` at the
  spec's spelling, and `b` for the binding is the family letter.
- **The diagnostic in an assertion.** `d = carried(@test_throws …)` and
  `d = diagnostic(failure(…))` bind the diagnostic under test: `keep:family`.
  A second diagnostic in the same testset is named by role (`first`,
  `repeat`, `d2` is not a role).
- **`sim`, `build`, `path`, `h`, `r`** and the rest of the roster and the
  spec's symbols keep as in `src/`; `build` and `path` carry rule 6's
  exception. A local `condition` (fifteen sites), `reads` (six),
  `declarations` (four) or `structure` shadows an imported function the
  file calls: `collision`, with a proposal (`plan`, `read_set`, `decls`).
- **Throwaways in a one-line `@test`.** A binding consumed by the next line
  and nothing else is `keep:glance`; one read by three assertions further
  down is not. `sim` for a `Simulation` and `sim2` for a second one are
  roster and role; `s`, `s1` for a simulation are `rename`.
- **`catch e`** is `rename` to `err` (five sites remain).
- **Test-local helper functions** (`walked`, `gated`, `poke!` and the ones
  defined inside a file) follow the package-function bullet: words in full,
  no API name shared. Table their parameters like any method's.

A proposed name is the noun the spec and the file's own testset titles use
for the concept. Two values of one type in one scope are named by role. A
name already in use in the same scope for another value is not a proposal.

## The report

One file per test file, `docs/reports/20260924_naming_inventory_test/<name>.md`
(`build.md` for `test/test_build.jl`, `fixtures.md`, `utils.md`,
`CadenceTests.md`). Write it in parts: the header first, then one append
per testset or function, never one response for the whole file; a response
over the 64k output limit kills the agent and loses the report.

Header:

```
# Naming inventory: test/test_<name>.jl

Tip: <hash>. Sites flagged: N. Renames: N. Collisions: N. Roster proposals: N.
Kept without a row: keep:index N, keep:typeparam N, keep:spec N, keep:glance N, keep:family N, keep:roster N, keep:api N.

## Letters with more than one meaning in this file

- `s`: a simulation (three testsets), the discrete state in fixtures' destructures → the simulation sites renamed below
```

Then one table per testset or function with tabled rows, in file order,
headed by the testset's title or the signature's first line and its line
number. Tabled rows are every `rename`, `collision` and `roster?` row, and
a `keep:*` row only where the permission is arguable (a glance binding
read more than once, a parameter under R7 in a method near five lines):

```
## "the reader is the gather twin: allocation-free over an executor (§14.4, §7.5)" — line 66

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 68 | `r` | local | the compiled reader, read by four assertions | rename | `reader` |
| 70 | `ex` | local | the executor | rename | `exec` |
| 47 | `v` | local | the gathered NamedTuple, read on the next line | keep:glance | — |
```

After the tables, three closing sections, as in the `src/` reports:

- **Collisions**: every `collision` row again, with the function's origin
  (the import list, `utils.jl`, `fixtures.jl`, Base) and whether the file
  calls it.
- **Roster proposals**: each `roster?` name, the count of sites it would
  cover across the file, and the word it abbreviates.
- **Questions**: anything the rules do not settle, one line each. A brief
  can be wrong; say so here rather than working around it.

## Stages

Eight agents, each over one group, Sonnet: the rules and rulings are
settled, and the judgment left is classification against them. No agent
edits the tree. Each reads the "Naming" section, the README's §1–§3, this
brief, and `implementation.md`'s file-table rows for `test/fixtures.jl`,
`test/imports.jl` and `test/repl.jl` (lines 40–42). Groups, by size:

| group | files |
| --- | --- |
| A | `test_build.jl`, `test_declare.jl`, `test_executor.jl` |
| B | `fixtures.jl`, `utils.jl`, `CadenceTests.jl` |
| C | `test_assembly.jl`, `test_show.jl`, `test_continuous.jl` |
| D | `test_trace.jl`, `test_log.jl`, `test_stepper.jl` |
| E | `test_diagnostics.jl`, `test_failures.jl` |
| F | `test_conditions.jl`, `test_readers.jl`, `test_trim.jl` |
| G | `test_discrete.jl`, `test_events.jl`, `test_localization.jl` |
| H | `test_devices.jl`, `test_lifecycle.jl`, `test_roster.jl`, `test_bindings.jl`, `test_dataplane.jl`, `test_store.jl`, `test_leaves.jl` |

`imports.jl` and `repl.jl` bind nothing and get no report.

Each agent's final message is each report's path and header lines, nothing
else; the report carries the content.

## After the reports

The coordinator merges the collisions, the roster proposals and the
questions into `docs/reports/20260924_naming_inventory_test/README.md`,
adjudicates them under the existing rulings, and writes the sweep's brief
off the adjudicated tables. Where a report and a ruling disagree, the
ruling wins.
