# Naming inventory: src/diagnostics.jl

Tip: f64b9f3. Sites flagged: 131. Renames: 81. Collisions: 1. Roster proposals: 1.

## Letters with more than one meaning in this file

- `d`: a diagnostic throughout (the file's family letter) → kept; the three `diagnostic::` parameters and their two helpers take it
- `e`: an exception carrier (`showerror`, `diagnostic`, `diagnostics`, `kinds`), a grid entry (`_grid_block`) → carrier sites renamed `carrier`, the grid loop `entry`
- `t`: time (`_seconds`), a member's tracing mode (`_modes`), a residual's tolerance (`TrimCommitResiduals`) → the non-time sites renamed
- `s`: the message under construction (`AlgebraicCycle`), a return shape (`_cf_expect`, `_cf_section`), a stop site (`_stop_site`), a declared noun (`_tap_noun`), a position segment (`_drift_position`); the spec's `s` is discrete state → all renamed
- `m`: a cycle member (`_hop`, `_modes`, `_cycle_hint`); the spec's `m` is mode → renamed `member`
- `h`: a dead hop (`AlgebraicCycle`); the spec's `h` is the step → renamed `hop`
- `f`: a face (`_hop`, `_cycle_hint`), a bundle field (`_bundle_declaration`), a `TrimProblem` field (`_trim_*`) → renamed `face` / `field`
- `p`: a component path (`_at_path`, generators), a type parameter value (`_typespell`), a producer terminal (`_wirelist`), a port (`ProducedByTwoStages`), a deployment parameter (`_dep_constraint`, `_dep_section`), a prime's attribution row (`_grid_block`) → the parameter and loop sites renamed; comprehension variables kept
- `T`: a diagnostic kind (`_groups`), any type (`_typename`, `_typespell`); the rules fix `T` as the numeric type → renamed
- `P`: the carrier's policy parameter (`DiagnosticError{P}`), a declared entry type (generators), a position tuple (`_drift_position`) → the tuple renamed
- `ws`: the warnings list (`DiagnosticError`, `_show_warnings`, `showerror`, `_warn!`), a cycle's wires (`_wirelist`); `:ws` is also the workspace bundle field (`_bundle_declaration`) → both renamed
- `v`: a `TypeVar` (`_typename`), an observed field type (`_trim_bad`), a residual's committed value (`TrimCommitResiduals`) → the `TypeVar` renamed
- `k`: a `TrimProblem` field key (`_trim_bad`), a residual name (`TrimCommitResiduals`) → comprehension variables, kept
- `n`: a name (list helpers), an event name (`TrimCommitEvents`), a superscript power (`_sup`) → the `_sup` parameter renamed
- `c`: a consumer terminal (`_wirelist`), a digit character (`_sup`) → comprehension variables, kept
- `g`: a kind group (`showerror`), the grid report (`_grid_block`) → both renamed
- `r`: a role (`_role_word`), a roster id (`NotAttached`) → the `_role_word` parameter renamed
- `i`: a loop index, and the ordinal parameter of `_declaration` and `_origin` → the parameters renamed

## The `d` families — summary rows

One row per method family whose sole parameter is `d`, a diagnostic kind. Every method listed here names it `d`; the methods that break the letter are listed as `rename` in their own tables below. `severity` methods bind no parameter (`severity(::K)`), and three `path` methods bind none either (lines 59, 391, 726).

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 282–2000 | `d` | param, 67 `message` methods | the diagnostic being rendered | keep:family | — (3 methods break it: 744, 1530, 1587) |
| 281–1916 | `d` | param, 44 `path` methods | the diagnostic whose path is read | keep:family | — |
| 150 | `d` | param, `logline` | the warning being rendered | keep:family | — |
| 165 | `d` | param, `_warn!` | the warning being raised | keep:family | — |
| 694 | `d` | param, `_rates_entry` | the `RatesViolation` | keep:family | — |
| 1000 | `d` | param, `_cf_what` | the `ConformanceFailure` | keep:family | — |
| 1015 | `d` | param, `_pin` | the `ConformanceFailure` | keep:family | — |
| 1523 | `d` | param, `_cleaf` | a `ConditionResolution` or `DuplicateConditionLeaf` | keep:family | — |
| 1698 | `d` | param, `_trim_bad` | the `TrimProblemInvalid` | keep:family | — |
| 1918 | `d` | param, `_replay_subject` | the `ReplayHeaderMismatch` | keep:family | — |

## `_typename(x)` — line 30

The three methods of `_typename` name their parameter three ways (`x`, `T`, `v`); the rules want one name. `value` covers all three (a type is a value); `ForwardDiff.value` is called qualified in this file, never bare.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 30 | `x` | param | the user value whose type is named; not the spec's state `x` | rename | `value` |
| 32 | `T` | param | the type to name, possibly a `Union`; not a type parameter and not the numeric type | rename | `value` |
| 37 | `v` | param | a declared generic holding, a `TypeVar` | rename | `value` |

## `_typespell(T::Type)` — line 42

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 42 | `T` | param | the plain-data type to spell with its shape; not the numeric type | rename | `type` |
| 45 | `p` | generator | one type parameter of it | keep:glance | — |

## The shared renderings — lines 68–72

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 68 | `p` | param, `_at_path` | a component path | rename | `path` (the rules' one permitted shadow) |
| 69 | `ns` | param, `_namelist` | the names to list | rename | `list` (`names` is a Base function) |
| 69 | `n` | generator | one name | keep:glance | — |
| 70 | `ns` | param, `_faceset` | the names to set | rename | `list` |
| 71 | `ns` | param, `_plainlist` | the names to list | rename | `list` |
| 72 | `ns` | param, `_symtuple` | the names to spell as a symbol tuple | rename | `list` |
| 72 | `n` | generator | one name | keep:glance | — |

## `DiagnosticError(d::Diagnostic, ws::Vector{Diagnostic} = Diagnostic[])` — line 93

Two methods; the rules want their parameters named alike. `d` is not a sole parameter here, and `diagnostic` and `warnings` are package functions (lines 99, `build.jl`/`deployment.jl`), so the proposals take the carrier's field name and a qualified noun.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 93 | `d` | param | the one diagnostic a fail-fast throw carries | rename | `carried` |
| 93 | `ws` | param | the build's warnings so far | rename | `warning_list` |
| 95 | `ds` | param | the collection a barrier throws | rename | `carried` |
| 95 | `ws` | param | the build's warnings so far | rename | `warning_list` |

## `diagnostic(e::DiagnosticError{<:Diagnostic})` — line 99

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 99 | `e` | param | the fail-fast carrier | rename | `carrier` |

## `diagnostics(e::DiagnosticError{Vector{Diagnostic}})` — line 102

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 102 | `e` | param | the barrier's carrier | rename | `carrier` |

## `kinds(e::DiagnosticError{Vector{Diagnostic}})` — line 105

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 105 | `e` | param | the barrier's carrier | rename | `carrier` |

## `_groups(ds::Vector{Diagnostic})` — line 109

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 109 | `ds` | param | the carried collection | rename | `diags` |
| 111 | `d` | `for` | one diagnostic of it, read on the next two lines | keep:glance | — |
| 112 | `T` | local | that diagnostic's kind; not the numeric type | rename | `kind` |
| 115 | `T` | comprehension | one kind of `order` | rename | `kind` |
| 115 | `d` | lambda | one diagnostic, filtered by kind | keep:glance | — |

## `_show_warnings(io::IO, ws::Vector{Diagnostic})` — line 120

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 120 | `io` | param | the output stream | roster? | `io` |
| 120 | `ws` | param | the warnings to render | rename | `warning_list` |
| 121 | `d` | `for` | one warning, read on the next line | keep:glance | — |

## `Base.showerror(io::IO, e::DiagnosticError{<:Diagnostic})` — line 127

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 127 | `io` | param | the output stream | roster? | `io` |
| 127 | `e` | param | the fail-fast carrier | rename | `carrier` |

## `Base.showerror(io::IO, e::DiagnosticError{Vector{Diagnostic}})` — line 132

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 132 | `io` | param | the output stream | roster? | `io` |
| 132 | `e` | param | the barrier's carrier | rename | `carrier` |
| 133 | `ds` | destructure | the carried collection, read three lines down | rename | `diags` |
| 133 | `ws` | destructure | the carried warnings, read on three lines | rename | `warning_list` |
| 136 | `g` | `for` | one kind group | rename | `group` |
| 136 | `d` | `for` | one diagnostic of that group, read on the next line | keep:glance | — |

## `_warn!(d::Diagnostic)` — line 165

`d` is in the family summary.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 169 | `ws` | local | the bound build's warning list, or `nothing` outside a build | rename | `warning_list` |

## `_seconds(t::Real)` — lines 181–182

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 181 | `t` | param | a time | keep:spec | — |
| 182 | `t` | param | a time, a `Dual` | keep:spec | — |

## `Base.:(==)(a::CursorFrame, b::CursorFrame)` — line 199

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 199 | `a`, `b` | param | the two frames compared, by role left and right | rename | `left`, `right` |

## `_phase_text(fr::CursorFrame)` — line 225

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 225 | `fr` | param | the cursor frame, read on ten lines | rename | `frame` (`frame!` is a distinct name) |

## `Base.showerror(io::IO, e::StepError)` — line 242

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 242 | `io` | param | the output stream | roster? | `io` |
| 242 | `e` | param | the runtime carrier, read twenty lines down | rename | `carrier` |
| 243 | `fr` | local | the carrier's cursor frame | rename | `frame` |

## `Base.showerror(io::IO, e::InternalInvariant)` — line 296

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 296 | `io` | param | the output stream | roster? | `io` |
| 296 | `e` | param | the invariant exception | rename | `invariant` |

## `message(d::AbstractAtRoot)` — line 395

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 397 | `p`, `P` | generator | one consuming leaf's path and its declared entry type | keep:glance | — |

## `message(d::RootInputTypeConflict)` — line 418

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 420 | `p`, `P` | generator | one consumer's path and its declared entry type | keep:glance | — |

## `_declaration(diagnostic, i)` — line 742

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 742 | `diagnostic` | param | the `ChildNameCollision`; breaks the file's letter and shares a name with `diagnostic` (line 99) | rename | `d` |
| 742 | `i` | param | which declaration to name, 1 or 2; not a loop index | rename | `ordinal` |

## `message(diagnostic::ChildNameCollision)` — line 744

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 744 | `diagnostic` | param | the diagnostic being rendered; breaks the `message` family's letter and shares a name with `diagnostic` (line 99) | rename | `d` |

## `_wirelist(ws)` — line 891

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 891 | `ws` | param | the cluster's wires; `ws` is the warnings list elsewhere in the file | rename | `wires` |
| 891 | `p`, `c` | generator | one wire's producer and consumer | keep:glance | — |

## `_hop((m, f, q))` — line 892

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 892 | `m` | destructured param | the hop's member path; the spec's `m` is mode | rename | `member` |
| 892 | `f` | destructured param | the input face the member does not route | rename | `face` |
| 892 | `q` | destructured param | the member's output port | rename | `output_port` (`port` is a package function, `sim.jl:1806`) |

## `_modes(traced)` — line 894

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 896 | `m` | generator | a member path; the spec's `m` is mode | rename | `member` |
| 896 | `t` | generator | that member's tracing mode; `t` is time elsewhere | rename | `tracing` (`mode` is a package function, `sim.jl:345`) |
| 898 | `t` | generator | a member's tracing mode | rename | `tracing` |

## `_cycle_hint(dead)` — line 902

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 903 | `fs` | `let` | the dead faces of one member, read on two lines | rename | `dead_faces` |
| 903 | `mm` | generator | the member of one dead hop, compared against the outer member | rename | `hop_member` |
| 903 | `f` | generator | that hop's input face | rename | `face` |
| 906 | `m` | generator | one dead member, read inside the `let` body three lines up; the spec's `m` is mode | rename | `member` |

## `message(d::AlgebraicCycle)` — line 910

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 914 | `s` | local | the `:real` arm's sentence, grown in a loop; the spec's `s` is discrete state | rename | `sentence` |
| 915 | `h` | `for` | one dead hop; the spec's `h` is the step | rename | `hop` |
| 920 | `modes` | local | each member's tracing mode, by member path | collision | `member_tracing` (`modes`, `sim.jl:1826`) |
| 921 | `h` | generator | one dead hop, read on two lines | rename | `hop` |

## `message(d::ProducedByTwoStages)` — line 933

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 935 | `p` | generator | one doubly produced port | keep:glance | — |

## `_cf_expect(s::Symbol)` — line 1003

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1003 | `s` | param | the return shape, read on seven lines; the spec's `s` is discrete state | rename | `shape` |

## `_cf_section(s::Symbol)` — line 1011

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1011 | `s` | param | the return shape | rename | `shape` |

## `_bundle_declaration(f::Symbol)` — line 1081

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1081 | `f` | param | the requested bundle field, read on six arms | rename | `field` |

## `message(d::BundleFieldError)` — line 1086

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1090 | `decl` | local | the declaration that would put the field in the bundle | keep:roster | — |

## `_advance_entry(op::Symbol)` — line 1167

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1167 | `op` | param | the refused operation's name; the payload field is also `op` | rename | `operation` |

## `_stop_site(s::Symbol)` — line 1197

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1197 | `s` | param | the advance that declared `stop_on`; the spec's `s` is discrete state | rename | `site` |

## `_dep_constraint(p::Symbol)` — line 1263

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1263 | `p` | param | the deployment parameter, read on six arms | rename | `parameter` |

## `_dep_section(p::Symbol)` — line 1271

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1271 | `p` | param | the deployment parameter, read on five arms | rename | `parameter` |

## `_sup(n::Int)` — line 1286

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1286 | `n` | param | the prime's power to superscript; `n` is a name elsewhere | rename | `power` |
| 1286 | `c` | generator | one digit character | keep:glance | — |

## `_grid_block(g::Union{Nothing,GridReport})` — line 1291

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1291 | `g` | param | the grid report, read on twelve lines | rename | `grid` (the payload fields' own name) |
| 1293 | `e` | comprehension | one pool entry | keep:glance | — |
| 1294 | `kv` | local | each entry's kind and value, spelled | rename | `kind_values` |
| 1294 | `e` | comprehension | one pool entry | keep:glance | — |
| 1295 | `fac` | local | each entry's refinement factor, spelled | rename | `factors` |
| 1295 | `e` | comprehension | one pool entry | keep:glance | — |
| 1296 | `wp` | destructure | the label column's width, read four lines down | rename | `label_width` |
| 1296 | `wk` | destructure | the kind-value column's width | rename | `kind_value_width` |
| 1296 | `wf` | destructure | the factor column's width | rename | `factor_width` |
| 1298 | `i` | `for` | the entry's index | keep:index | — |
| 1298 | `e` | `for` | one pool entry, read on three lines; `e` is an exception elsewhere | rename | `entry` |
| 1305 | `pw` | local | each prime power, spelled, read on three lines | rename | `prime_powers` |
| 1305 | `p` | comprehension | one prime attribution | keep:glance | — |
| 1307 | `i` | `for` | the attribution's index | keep:index | — |
| 1307 | `p` | `for` | one prime attribution (prime, power, suppliers), read two lines down | rename | `attribution` |
| 1309 | `j` | generator | a supplier's index into the pool | keep:index | — |

## `_ctail(diagnostic)` — line 1526

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1526 | `diagnostic` | param | a `ConditionResolution`; breaks the file's letter and shares a name with `diagnostic` (line 99) | rename | `d` |

## `_role_word(r)` — line 1527

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1527 | `r` | param | the leaf's role, read on two lines | rename | `role` |

## `message(diagnostic::ConditionResolution)` — line 1530

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1530 | `diagnostic` | param | the diagnostic being rendered; breaks the `message` family's letter and shares a name with `diagnostic` (line 99) | rename | `d` |

## `_origin(diagnostic, i)` — line 1585

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1585 | `diagnostic` | param | the `DuplicateConditionLeaf`; breaks the file's letter and shares a name with `diagnostic` (line 99) | rename | `d` |
| 1585 | `i` | param | which origin to name, 1 or 2; not a loop index | rename | `ordinal` |

## `message(diagnostic::DuplicateConditionLeaf)` — line 1587

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1587 | `diagnostic` | param | the diagnostic being rendered; breaks the `message` family's letter and shares a name with `diagnostic` (line 99) | rename | `d` |

## `_tap_noun(s)` — line 1636

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1636 | `s` | param | what the leaf is declared as, `:output_port` or `:state_field` (the payload's `declares`); the spec's `s` is discrete state | rename | `declares` |

## `_tapviol(d, what)` — line 1641

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1641 | `d` | param | the `TapResolution`; the file's letter, though not a sole parameter (see Questions) | keep:family | — |

## `_trim_shape(f::Symbol)` — line 1688

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1688 | `f` | param | the offending `TrimProblem` field | rename | `field` |

## `_trim_floats(f::Symbol)` — line 1694

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1694 | `f` | param | the offending `TrimProblem` field | rename | `field` |

## `_trim_verb(f::Symbol)` — line 1697

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1697 | `f` | param | the offending `TrimProblem` field | rename | `field` |

## `_trim_bad(d)` — line 1698

`d` is in the family summary.

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1698 | `k`, `v` | generator | one bad key and its observed type | keep:glance | — |

## `message(d::TrimCommitEvents)` — line 1733

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1735 | `p`, `n` | generator | one fired event's component path and event name | keep:glance | — |

## `message(d::TrimCommitResiduals)` — line 1744

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1746 | `k`, `v` | generator | one residual's name and committed value | keep:glance | — |
| 1746 | `t` | generator | that residual's tolerance; `t` is time in this file and the spec | rename | `tolerance` |

## `_drift_position(P::Tuple)` — line 1758

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1758 | `P` | param | the node's position in the tree, a tuple; reads as a type parameter | rename | `node_position` (`position` is a Base function) |
| 1758 | `s` | generator | one position segment, a field name or an index; the spec's `s` is discrete state | rename | `segment` |

## `message(d::NotAttached)` — line 1892

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1895 | `r` | generator | one roster device id | keep:glance | — |

## `_replay_paths(ps)` — line 1923

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1923 | `ps` | param | the component paths to list | rename | `paths` |
| 1923 | `p` | generator | one component path | keep:glance | — |

## `_replay_deployment(diagnostic::ReplayHeaderMismatch)` — line 1928

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1928 | `diagnostic` | param | the `:deployment` arm's diagnostic, read on twenty lines; breaks the file's letter and shares a name with `diagnostic` (line 99) | rename | `d` |

## Collisions

- `modes` (line 920, `message(d::AlgebraicCycle)`): shares its name with `modes(sim, path)`, defined at `src/sim.jl:1826`. `modes` is not called inside the method; the method calls `_modes` (line 894), a different name. Proposal `member_tracing`.

Coded `rename` per the family rule, but each also shares a name with a package function: the seven `diagnostic` parameters (lines 742, 744, 1526, 1530, 1585, 1587, 1928) share it with `diagnostic(carrier)`, defined at `src/diagnostics.jl:99` and `:219`. None of the seven scopes calls `diagnostic`. The family letter `d` resolves both.

Proposals chosen to dodge a collision: `output_port` rather than `port` (`src/sim.jl:1806`, `src/dataplane.jl:598`), `tracing` rather than `mode` (`src/sim.jl:345`), `warning_list` rather than `warnings` (`src/build.jl`, `src/deployment.jl:395`), `list` rather than Base's `names`, `node_position` rather than Base's `position`, `carried` rather than `diagnostic` in the `DiagnosticError` constructors.

## Roster proposals

- `io`: 5 sites (lines 120, 127, 132, 242, 296), the output stream. It is Julia's own convention for `show`/`showerror`/`print` methods, and every other `src/` file with a `show` method (`show.jl` above all) would take it too.

## Questions

- The rules' `keep:family` requires the *sole* parameter. `_tapviol(d, what)` (line 1641) passes a diagnostic beside a second argument; I coded it `keep:family` since "one name, one meaning per file" fixes `d` as a diagnostic here and any other name breaks that. The proposed `_declaration(d, ordinal)` and `_origin(d, ordinal)` sit on the same ground. Should the family clause read "a diagnostic parameter" rather than "the sole parameter"?
- The `DiagnosticError` constructors (line 93) take a diagnostic beside the warnings list. I proposed `carried` rather than `d` because the parameter is not sole and `diagnostic` is taken; the same letter argument as above would keep `d` there. Which?
- "Every method of a function names its parameters alike": does it cover Base generics extended across unrelated types? I proposed `carrier` for the three carrier `showerror` methods and `invariant` for `InternalInvariant`'s (line 296), which differ.
- `_typename`'s three methods take a value, a type and a `TypeVar`. One name for all three (`value`) follows the "alike" rule but reads oddly on a `Type`; `instance`/`type`/`typevar` would read better and break it.
- A `Type`-valued argument named `T` (lines 32, 42, 112) is neither a type parameter nor the numeric type. I coded it `rename`; the rules do not say whether `keep:typeparam` reaches it.
- Parameters of one-line helpers (`_at_path(p)`, `_namelist(ns)`, `_cf_expect(s)`, `_sup(n)`): the glance clause names "any local of a method under about five lines". I read parameters as outside it and coded them `rename`; if parameters count, about fifteen rows here become `keep:glance`, though several would still fall to the one-meaning rule (`s`, `t`, `m`, `h`).
- The `_cf_`, `_dep_`, `_tapviol` and `_sup` helper names are themselves abbreviations off the roster. Function names are out of this inventory's scope; flagging them for a later pass.
- The brief's header template gives tip `4a3b725`; the caller named `f64b9f3`, which the header uses. `src/diagnostics.jl` is unchanged between the two.
