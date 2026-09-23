# Naming inventory: the merge and the rulings

Tip `f64b9f3`. Twenty reports, one per source file, from the brief
`docs/design/briefs/brief_naming_inventory.md`. This page merges their
closing sections into the rulings Step 3 needs. Each item states the
question and a recommendation; the user's ruling replaces the
recommendation in place.

| file | flagged | renames | collisions |
| --- | --- | --- | --- |
| build | 325 | 174 | 4 |
| sim | 210 | 119 | 14 |
| tracer | 164 | 69 | 2 |
| assembly | 155 | 94 | 8 |
| conditions | 153 | 77 | 4 |
| executor | 151 | 56 | 1 |
| diagnostics | 131 | 81 | 1 |
| trim | 118 | 44 | 3 |
| leaves | 106 | 56 | 0 |
| readers | 100 | 60 | 2 |
| deployment | 79 | 30 | 8 |
| trace | 72 | 39 | 0 |
| dataplane | 71 | 35 | 4 |
| localization | 52 | 13 | 1 |
| stepper | 50 | 14 | 0 |
| devices | 46 | 32 | 1 |
| declare | 45 | 20 | 2 |
| bindings | 41 | 30 | 0 |
| store | 36 | 15 | 0 |
| roster | 29 | 17 | 0 |
| show | 20 | 4 | 1 |
| Cadence | 0 | 0 | 0 |
| **total** | **2154** | **1079** | **56** |

## 1. Rule clarifications

The reports hit the same gaps in the Naming section from several sides.
Each ruling here amends the section's text before Step 3 launches.

**R0. Rule 6's exceptions.** `path` and `build`; see C1 for the ruling and
the principle.

**R1. Which Base names count as collisions.** The rules say "reached from
Base", the brief said "a Base function the file calls"; the reports split.
Call sites across `src/`: `pairs` 15, `count` 7, `max` 7, `values` 6,
`only` 3, `bind` 3; `schedule`, `run`, `log`, `names`, `step`, `position`,
`success` 0. *Recommendation:* a Base name is a collision when the package
calls it anywhere in `src/`. `run` stays `run` for a `Run`, `schedule`
stays for a `Schedule`; `names` still takes the reports' proposals
(`fields`, `name_list`, `list`), which read better regardless.

**R2. API parameter names are out of scope.** Public keywords and
positional names the spec fixes (`trace`, `log` on `init!`/`replay!`;
`condition`, `reads` on `TrimProblem`; `sep`, `only`, `except` on the
passthroughs; `maxiter`; `children` on `Group`; `i` on the selectors;
`init!`'s `condition`) collide or abbreviate under the rules and cannot
change without a spec change. *Recommendation:* a parameter of a public
signature keeps the spec's spelling; the sweep never touches it, and the
rules say so beside the `path` exception.

**R3. "Every method alike" across unrelated dispatch types.** `warnings`
takes a build, a deployment or a simulation; `port` a snapshot or a
simulation; the three `Simulation` constructors, `stop!`, `latest`,
`run!`, `step!`, `_typename`, `showerror`, `index_of` likewise.
*Recommendation:* the rule binds the positions that hold the same thing; a
method dispatching on a different type names its parameter by what it
holds. A deliberate contrast (`other` in the condition misuse methods)
stands. `combine(nodes...)` beside `combine(left, right)` is compliant.

**R4. The family letter, restated.** `keep:family` says "sole parameter,
fixed once per file"; `dataplane.jl` extends `message`/`path` with twelve
kinds, `_tapviol(d, what)` and `DiagnosticError(d, ws)` carry the
diagnostic beside another argument, and the binding family (`claims`,
`reads`, `is_input`, `check_binding`, `map_input`) has the same shape with
`b`, `binding` being a function. *Recommendation:* the clause reads "a
parameter holding the family's dispatch value, in a per-kind method
family, the letter fixed once per family across every file extending it":
`d` for a diagnostic kind, `b` for a binding. The seven `diagnostic::…`
parameters in `diagnostics.jl` become `d`.

**R5. What a spec derivative is.** The rules list examples; the reports
guessed differently at `mstores`, `xbuf`, `offs`, `y1`, `s1`, `σs`, `h_r`,
`Δtb`. *Recommendation:* a spec symbol followed by a digit, a plural `s`,
or a suffix or word (`buf`, `store(s)`, `next`, `_off(s)`, `_r`, `b` for
base) is a derivative and keeps. `s1` in `build.md` reverts to keep beside
`y1`/`y2`. `n_ok`, `n_i` rename as proposed: `n` spells no spec symbol.

**R6. `d` in `trim.jl`.** §14.7 and §14.8 name the decision vector `d`.
*Recommendation:* `keep:spec` there; rule 4's wording becomes "`d` is a
diagnostic in the diagnostic families and the trim decision vector in
`trim.jl`, nothing else".

**R7. Parameters of tiny methods.** The glance clause names "any local of
a method under about five lines"; `diagnostics.md` read parameters as
outside it (about fifteen rows). *Recommendation:* parameters count, so
`_at_path(p)` and `_sup(n)` keep, unless the letter breaks one meaning in
the file (`s`, `t`, `m`, `h` in `diagnostics.jl` still rename).

**R8. Generated-code names.** `buf`, `off`, `v`, `offs`, `buf<k>` and
`stmts` are read by expressions the builders in `leaves.jl`, `store.jl`
and `dataplane.jl` emit; `_bundle_expr` in `executor.jl` quotes `e.`,
`store` and `xbuf`. *Recommendation:* out of Step 3. The rows take a new
code, `keep:generated`, and a later pass renames a builder and its emitted
names together.

**R9. Type-valued bindings.** `T = Tracer{true}`, `T = eltype(ex.xbuf)`,
`N` as a `Dual` width, `S::Bool` mirroring a type parameter, the `@eval`
loop's artifact type; `T::Type` for a binding's type in `bindings.jl`;
`T` for a period in `declare.jl`. *Recommendation:* a binding that plays a
type parameter's part is spelled like one (`T`, `N`, `S`, `Artifact`); a
`Type`-valued parameter that is not the numeric type takes a noun
(`binding_type`, `_typename(type)`); the period local becomes `period`,
rule 4 winning in a file whose `T` is also the numeric type.

**R10. Operator methods.** `Base.:(==)`, `Base.:+`, `Base.hash` and the
tracer's `@eval`'d Base overloads. *Recommendation:* operands stay `a`,
`b`; the tracer's overloads align on Base's `x`, `y`, `z`; the hash seed
is `seed` in both `deployment.jl` and `trace.jl`.

## 2. Roster proposals

| name | abbreviates | raised by | sites | recommendation |
| --- | --- | --- | --- | --- |
| `act` | activation; `activation` is a function called beside most sites | build, conditions, readers, trim, sim | ~75 | **add** |
| `addr` | address, the singular of `addrs` | build, conditions, readers, store | ~52 | **add** |
| `fn` | a declaration, stage, guard or handler passed by value; `UserCodeFraming.fn` | build, declare | ~76 | **add** |
| `io` | the output stream, Base's own name | diagnostics, show | 12 | **add** |
| `err` | a caught exception; `error` is Base | sim, devices | ~30 | **add**, and `catch err` everywhere (9 `catch e` remain) |
| `dev` | a device; `device` is the id string in payloads and keywords | devices, roster | ~37 | **add** |
| `trc` | a trace; `trace` is a function | roster, trace | ~54 | **add** |
| `op` | the operation a lifecycle payload names; the payloads' own field | devices, sim, conditions | ~10 | **add** |
| `rng` | random number generator, `Random`'s own name | tracer | 4 | **add** |
| `kw` | a keyword splat, Julia's idiom | trim, conditions | ~5 | **add** |
| `scc`/`sccs` | strongly connected component, Tarjan's term | build | 4 | **add** |
| `ins`/`outs` | the `Decls` fields: declared face and port types | build | 6 | **add**, for the `Decls` contents only; `assembly.jl`'s other two meanings take `input_names`/`output_names` and `input_entries`/`output_entries` as proposed |
| `sep`, `maxiter` | public keywords | assembly, trim | — | not needed: R2 |
| `b` | a binding | bindings, roster | 7 | not needed: R4's family letter |
| `mstores`, `sstores` | store vectors | tracer, executor | — | not needed: R5's derivatives |
| `buf`, `stmts` | emitted names | leaves, store | ~44 | not needed: R8 |
| `ctl`, `cur`, `pol`, `ex`, `pos`, `snap`, `seg` | control, cursor, policy, executor, position, snapshot, segment | sim, trace, conditions, devices, assembly | — | **rename** as the reports propose (`exec` is the roster's spelling for `ex`) |

## 3. Collisions

Fifty-six rows, in five kinds.

**C1. `Build` parameters.** Across `src/`: 15 `b`, 11 `build`, 3 `built`
(`show.jl`). `readers.md` and `deployment.md` ask for a `path`-style
exception; `build.md`, `conditions.md`, `trim.md` propose `built`.
*Ruled (2026-09-23):* `build` everywhere, joining `path` as rule 6's
second exception. The principle, stated once in the rules: a spec noun
whose function produces the thing the local holds, where no scope holding
one calls the function. `built` is a participle, not a noun; `bld` would
be a roster entry existing only to dodge the function. `trace` does not
get the exception: the word is also the API's boolean keyword on `init!`
and `replay!`, and `trc` keeps the flag and the recording apart.

**C2. Base names.** Settled by R1. Rename: `pairs` → `writes` in both
`stage!` methods together, `values`, `count` → `localizations`, `max`,
`only` → `only_faces` with `except_faces`, `bind`. Keep: `run`,
`schedule`, `log` (API anyway), `step`, `position`, `success`. `names`
renames on merit.

**C3. API names.** Settled by R2: `trace`, `log`, `condition`, `reads`,
`children`, `sep`, `only`, `except`, `maxiter`, the selectors' `i`.
`attach!`'s `new_binding` is the one public signature whose spec name
cannot be used: the spec's `binding` would shadow the `binding` function
called in that scope.

**C4. Package functions, plain renames.** Accept the reports: `state` →
`state_store`; `port` → `port_name`/`output_port` (no `path`-style
exception, three sites in all); `at` → `contracts_at`; `kinds`; `modes` →
`member_tracing`/`trace_modes`; `mode` → `tracing`/`trace_mode`; `trace`
→ `trc`; `declarations` in `assembly.jl` (`Group`'s `children` parameter
mirrors the field and stays, R2 and the field rule); `warnings` →
`raised`/`warning_list`; `diagnostic` → `d` (R4); `diag` in `attach!`.

**C5. A generic clash, function level.** `_declares` has methods in
`declare.jl` (does a declaration have a method?) and `readers.jl` (build
an `:undeclared` violation) with nothing in common. *Recommendation:*
rename the `readers.jl` pair to `_undeclared_violation` in Step 3, the one
function rename the sweep makes, because two meanings under one generic is
a dispatch accident waiting to happen.

## 4. Brief errata

- The brief's example table renamed `act` → `activation` and `sch` →
  `schedule`: the first shadows a package function called in the same
  file, the second `Base.schedule`. `act` joins the roster (§2);
  `schedule` stands under R1.
- The header template named tip `4a3b725`; the dispatch and the tree were
  at `f64b9f3`. `src/` is identical between them.
- The collision grep `^(function )?name\(` misses zero-method
  declarations (`function condition end`). Step 3's brief adds
  `^function \w+ end`.

## 5. Out of scope, noted for later passes

- **Fields.** `Resolved.e/L/v`, `CEntry.pos`, the entry structs' `fn`,
  `outs`, `proj`, `idx`, `sstore`, `mstore`, `ws`, `y1`, `fname`,
  `RosterEntry.dev`, `DeviceHandle.ctl`, the selectors' `i`. Step 3 keeps
  a parameter that mirrors a field at the field's spelling
  (`executor.md`'s four); a field sweep is a `pending.md` bullet.
- **Function names.** `_cviol`, `_tviol`, `_tapviol`, `_rviol`, `_cf_*`,
  `_dep_*`, `_sup`; `gather` with three meanings; `capture(::StoreBundle)`
  beside the API's `capture(sim)`; `run!(::StageEntry)` beside
  `run!(sim)`. A function-naming pass, also a `pending.md` bullet.
- **Docstrings that spell a renamed parameter.** `startpoint(m)`,
  `dense!(m, …)`, `gather(handle, snap)`, `_condition`'s blend comment,
  `implementation.md`'s `(idx − Φ) % D`. Step 3 renames these with the
  code.
- **Unflagged words the reports would rename.** `kid` → `child` (about 30
  sites), `t_to` → `t_top`, `claimedby` → `claimed_by`, `old` →
  `old_harness`. Not in Step 3 unless ruled in.
- **A duplication.** `build.jl` builds the input `NamedTuple` from the
  same generator three times (`_probe_direct!`, `probe_events`); one helper
  would serve. Noted only.
