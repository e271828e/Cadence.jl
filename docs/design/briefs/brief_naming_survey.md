# The naming survey — single-letter names in `src/`

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip
`2844584`. Read-only: no edits, no commits, no suite run. Never `cd`
elsewhere (`cd` is aliased to zoxide in the user's shell); use absolute
paths. Scratch files go in the scratchpad directory your prompt names,
never in the repository.

**Purpose.** `pending.md`'s naming bullet (lines 43–51) states the rule
since 2026-09-21: a function parameter or a binding that outlives a few
lines carries a descriptive name; single letters stay for the spec's
symbols, for a binding visible in one glance and for the component index
`ci`. Increment 48 applied it to what it touched. The rest of `src/`, about
1,500 single-letter parameters over 20 files plus the body bindings, is one
mechanical sweep, and a mechanical sweep needs a table that fixes every
name before it starts, because the same letter means different things in
neighbouring functions (`d` is a `Diagnostic`, a `Deployment` or a `Decls`;
`s` a `Structure`, a `Simulation`, a store, a `Symbol` or a scope). This
survey builds that table. It proposes; the user decides in the sweep's
brief.

**The rule, made operational.**

- **Survivors.** A single letter stays where it denotes one of the spec's
  quantities under the spec's own letter (§5.2's bundle table at
  `spec.md:578–594` and the schedule's symbols): `x`, `m`, `s` as state,
  `u`, `y`, `y_x`, `y_s`, `t`, `Δt`, `ws`, `σ`, `θ`, `τ`, `T` as the scalar
  type, `D` and `Φ` as the schedule's divisor and phase, `N` as a tuple
  length in a type parameter, `h` as the base step, `ci` as the component
  index, `io` as the stream. A `c` that is a component *instance* is not
  §5.2's `comp` and does not survive; a `t` that is a tier does not
  survive; an `s` that is a `Symbol` does not survive. The survivor test is
  the meaning, not the letter.
- **One glance.** A binding whose last use is within five lines of its
  definition, or a comprehension, `do`-block or anonymous-function argument
  whose body fits in one or two lines, stays whatever its letter. Record the
  span so the threshold can be moved.
- **Everything else** gets a proposed name: a function parameter, a
  destructured tuple element, a loop variable over a body longer than five
  lines, a `let` binding, a closure's captured local.

**Out of scope.** Struct field names, keyword-argument names and every
name that is part of the package's surface (exported or listed in
`test/imports.jl`): those are API and belong to another decision. Type
parameters. `test/` and `docs/`. Names longer than one letter, however
terse (`df`, `bn`, `pol`, `fr` are noted only if you meet them while
reading a function you are already tabulating, in one line under
"Neighbours"). Anything you would fix rather than report.

## Method

For every function definition in your slice, long form and short form,
inner functions and closures included:

1. List every single-letter parameter with its type annotation or "untyped".
   Read the body and give the role in two or three words ("the diagnostic
   rendered", "the component path", "a face name").
2. Walk the body for single-letter bindings that are not parameters:
   assignments, tuple destructurings, `for`/comprehension/`do` variables,
   `let`s. Record each with its definition line and its last use line.
3. Classify each: **survivor** (which spec symbol), **glance** (the span),
   or **rename**, with the proposed name. Propose from the role when the
   type says less than the role does (`n::Int` is `count` or `index`, not
   `int`; `f::Symbol` is `face` or `field`, not `symbol`). A parameter that
   is a diagnostic kind (`d::MissingProbeValue`) is `diagnostic`. Two
   parameters of one function whose proposals collide get distinct names
   from their roles (`decls` and `diagnostic`, `producer` and `consumer`).
4. Check the proposal against what is in scope: a module-level function or
   constant of that name (`build`, `deployment`, `activation`, `trace`,
   `warnings`, `mode` are all functions in `src/`), another local of that
   name in the same function, a field the body accesses as `x.name`. A
   local that shadows a function the body also calls is a collision; flag
   it and propose an alternative (`the_build` is not one; `built` or
   `deployment_of` are not either; pick a role name such as `artifact` or
   qualify: `build_of_sim`).
5. Where a function's parameter names are constrained by a dispatch
   convention the file follows (every `show` method taking `io`, every
   `message(d::Kind)` in `diagnostics.jl`), say so once for the file and
   list the functions under it instead of one row each.

Read `pending.md:43–51` first. Read the rows for your slice's files in
`docs/design/implementation.md`'s file table (lines 16–42) for what each
file is; do not read the rest of that file. Read `spec.md:578–594` for the
bundle letters. Read spec sections beyond that only where a letter's
survivor status turns on the spec's usage; cite them by `§N.N`.

## The slices

| slice | files |
| --- | --- |
| A, diagnostics | `diagnostics.jl` |
| B, build | `build.jl`, `executor.jl`, `store.jl`, `stepper.jl` |
| C, the loop | `sim.jl`, `localization.jl`, `deployment.jl` |
| D, authoring | `assembly.jl`, `declare.jl`, `leaves.jl`, `tracer.jl`, `show.jl` |
| E, data plane and periphery | `dataplane.jl`, `roster.jl`, `bindings.jl`, `devices.jl`, `trace.jl` |
| F, services | `conditions.jl`, `readers.jl`, `trim.jl` |

Slice D also reports the fold `pending.md:50–51` names: `assembly.jl:72`'s
`_at(path)` and `diagnostics.jl:69`'s `_at_path(p)` are the same function.
List every caller of each (`grep -n "_at(\|_at_path(" src/*.jl`, then read
the hits, since `_at(` also matches inside other names) and confirm the two
bodies are identical.

## Report

One file per slice, `docs/reports/20260922_naming_survey/<slice>_<name>.md`
(`a_diagnostics.md`, `b_build.md`, `c_loop.md`, `d_authoring.md`,
`e_periphery.md`, `f_services.md`), written by you, and nothing else
written anywhere. Its shape, in this order:

1. **Header.** Tip `2844584`, the files, the function count examined, the
   date.
2. **Conventions.** The per-file dispatch conventions from method step 5,
   each with its parameter, its proposal and the list of functions it covers.
3. **The table**, one per file, one row per binding not covered by a
   convention, in line order:

       | line | function | name | type or role | span | class | proposal | note |

   `span` is `def–last` line numbers for a body binding and `param` for a
   parameter. `class` is `survivor(x)`, `glance` or `rename`. `note` holds
   a collision, an alternative considered, or nothing.
4. **Collisions.** Every proposal that shadows a module-level name or
   repeats a local, with the alternative chosen.
5. **Neighbours.** Terse multi-letter names met on the way, one line each,
   no proposals.
6. **Questions.** Any letter whose survivor status you could not decide
   from the spec, one or two sentences each.
7. **Coverage.** Functions you did not reach, if any, and why.

The rows are the deliverable; keep prose to the header, the conventions
and the questions. Do not pad, do not fix. When you are done, reply with
the report's path and its row counts by class, in three lines.
