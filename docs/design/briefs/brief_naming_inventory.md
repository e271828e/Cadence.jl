# Brief: the naming inventory (Step 2 of the naming sweep)

Tip at drafting: `4a3b725`. Ruled with the user on 2026-09-23. The rules
are `implementation.md`'s "Naming" section (lines 125–155); this brief
never restates them. Read that section first, then this brief, then the file.

## Purpose

Local and parameter names across `src/` are too terse: type-initial letters
that mean several things (`d`, `c`, `t`, `e`), abbreviation clusters inside
one scope (`fs`, `qs`, `tf`, `tq`, `bn`, `ws`), parameter names that differ
across methods of one function, and locals that shadow package functions.
Step 2 produces the inventory: every binding the rules touch, what it holds,
and the name it should take. No file under `src/` or `test/` changes in this
step. Step 3 applies the tables, one commit per file, after the user has
ruled on them.

The report is what the user reviews. A wrong proposal costs one table cell;
a missed site costs a second pass. Err towards listing.

## What counts as a site

Every binding in the file that is one of:

- a function or method parameter, positional or keyword, including closure
  and `do`-block parameters;
- a local bound by `=`, by destructuring (`a, b = …`, `(k, v) = …`), by
  `for`, by a comprehension or generator, by `catch`, or by `let`;
- a local function defined inside a function body (`gate(ci) = …`).

Out of scope: struct field names, keyword names at a call site
(`Deployment(build; h = 1//100)` binds nothing), the API's exported
functions, and global constants.

A site is **flagged** when its name is one or two characters, or an
abbreviation not on the roster, or a name shared with a function defined in
the package (grep `^(function )?name\(` across `src/`) or a Base function
the file calls. A flagged site that the rules permit is still listed, with
its permitting rule, so the user sees the judgment and not only the renames.

Read every site in its scope before classifying it. The regex sweep that
found the problem over-counts keyword arguments and misses destructuring
and loops; it is a map, never the list.

## Classification

One code per row:

| code | meaning |
| --- | --- |
| `keep:index` | a loop or comprehension index, or `ci` |
| `keep:typeparam` | a type parameter |
| `keep:spec` | a spec symbol or a derivative (`t_seg`, `h′`, `x_offs`, `nx`) |
| `keep:glance` | one-glance binding: lambda or comprehension variable, destructuring consumed on the next line, any local of a method under about five lines |
| `keep:family` | the sole parameter of a method family dispatching on one type family, the letter fixed once per file |
| `keep:roster` | an abbreviation on the roster |
| `rename` | takes the proposed name |
| `collision` | shares a name with a function; proposal renames the local, or says "rename the function" with the reason when the local is the better owner of the word |
| `roster?` | an abbreviation the agent proposes adding to the roster, with its count |

`keep:glance` is the code most likely to be abused. It does not cover a
binding that a long method reads twenty lines below its definition, nor one
that sits beside three other short names in a scope. When in doubt, `rename`.

`keep:family` applies to `d` in `diagnostics.jl` only unless the file has a
second family of the same shape; propose it as `roster?` in that case rather
than applying it.

A proposed name is the noun the spec and the file's own docstrings use for
the concept. Two values of one type in one scope are named by role. A name
already in use in the same scope for another value is not a proposal.

## The report

One file per source file, `docs/reports/20260923_naming_inventory/<name>.md`
(`build.md` for `src/build.jl`). Write it in parts: the header first, then
one append per function, never one response for the whole file — a response
over the 64k output limit kills the agent and loses the report.

Header:

```
# Naming inventory: src/<file>.jl

Tip: 4a3b725. Sites flagged: N. Renames: N. Collisions: N. Roster proposals: N.

## Letters with more than one meaning in this file

- `t`: time (`_run_body!`), tier (`compile`) → tier sites renamed below
```

Then one table per function that has flagged sites, in file order, headed
by the signature's first line and its line number:

```
## `compile(build::Build, act::Activation{T}, sch; …)` — line 1376

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1376 | `act` | param | the activation being compiled | rename | `activation` |
| 1376 | `sch` | param | the schedule | rename | `schedule` |
| 1379 | `D_c`, `Φ_c`, `Δt_c` | destructure | the per-component gates | keep:spec | — |
| 1448 | `c` | destructure | the component instance | rename | `comp` |
| 1448 | `t` | destructure | the tier | rename | `tier` |
| 1452 | `bn` | local | the bundle names | rename | `bundle` |
```

After the tables, three closing sections:

- **Collisions**: every `collision` row again, with the function's definition
  site and whether the function is called inside the scope that binds the
  local.
- **Roster proposals**: each `roster?` name, the count of sites it would
  cover across the file, and the word it abbreviates.
- **Questions**: anything the rules do not settle, one line each. A brief
  can be wrong; say so here rather than working around it.

## Stages

Seven agents, each over one group, all Opus; the proposals are judgment. No
agent edits the tree. Each reads the group's rows of `implementation.md`'s
file table (lines 18–39) for the vocabulary the docstrings use, and the
"Naming" section. Groups, by damage:

| group | files |
| --- | --- |
| A | `build.jl` |
| B | `sim.jl` |
| C | `diagnostics.jl` (the `d` family is `keep:family`; the flagged rest is small) |
| D | `assembly.jl`, `conditions.jl` |
| E | `tracer.jl`, `trim.jl`, `localization.jl`, `stepper.jl` |
| F | `dataplane.jl`, `deployment.jl`, `devices.jl`, `executor.jl` |
| G | `bindings.jl`, `declare.jl`, `leaves.jl`, `readers.jl`, `roster.jl`, `show.jl`, `store.jl`, `trace.jl`, `Cadence.jl` |

A group with several files writes one report per file. `test/` is a later
wave with its own brief, after Step 3 lands and the roster has settled.

Each agent's final message is the report's path and its header line, nothing
else; the report carries the content.

## After the reports

I merge the roster proposals and the collisions across the seven reports
into one page, `docs/reports/20260923_naming_inventory/README.md`, for the
user's rulings. Step 3's brief is written off the ruled tables.
