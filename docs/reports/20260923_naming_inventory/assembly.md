# Naming inventory: src/assembly.jl

Tip: f64b9f3. Sites flagged: 155. Renames: 94. Collisions: 8. Roster proposals: 1 (3 sites).

## Letters with more than one meaning in this file

- `t`: a producer terminal tuple (`_terminal`), a connection collection (`_entries`), a tier (`_walk!`) → all renamed below
- `p`: a pair (`_entries`, comprehensions in `_one_level`, `_check_sample_times`), a declaration label string (`_children`), an endpoint path (`_endpoints`, `_fanout`) → the non-glance sites renamed below
- `n`: a count of component elements (`_children`), a field name (`_container_fields`), a face name (`_labelled`, the passthroughs, `_check_face_names`, `_check_root_faces`) → the count renamed below
- `v`: a field's value (`_holds_components`, `_children`, `_is_container`, `_bears_component`), a `sample_times` wrapper value (`_check_sample_times`, `_rate_entry`, `_child_scope`) → the long-lived sites renamed below
- `k`: a container element's key (`_children`), a `sample_times` key (`_check_sample_times`, `_rate_entry`, `_child_scope`) → the long-lived sites renamed below
- `i`: a segment cursor (`resolve_authored`, `authored_chain`), a row found by `findfirst` (`resolve_source`, `resolve_dest`) → the row sites renamed below
- `j`: a pair index (`_check_child_names`), a child found by `findfirst` (`_one_level`, `resolve_authored`, `authored_chain`) → the `findfirst` sites renamed below
- `c`: every component parameter; the `Timing` field `c` (the phase) is a field, out of scope, but reads beside `scope.c` → parameter sites renamed to `comp` below

## `function leaf_declarations(c)` — line 27

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 27 | `c` | param | the component whose declarations are read | rename | `comp` |
| 29 | `fn` | for (destructure) | the leaf declaration function paired with `name` | rename | `declaration` |
| 34 | `fn` | for (destructure) | the contract declaration function | rename | `declaration` |
| 39 | `fn` | for (destructure) | the stage declaration function | rename | `declaration` |

## `function declarations_found(c)` — line 48

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 48 | `c` | param | the component | rename | `comp` |
| 50 | `fn` | for (destructure) | the declaration function from `_OTHER_FAMILY` | rename | `declaration` |
| 53 | `n` | comprehension | a `DECLARATION_FAMILY` name | keep:glance | — |

## `function classify(path::String, c)` — line 57

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 57 | `c` | param | the component being classified | rename | `comp` |

## `_terminal(t::Tuple{String,Symbol})` — line 74

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 74 | `t` | param | a producer terminal `(path, port)`; `t` is time by the rules | rename | `terminal` |

## `_join(path::String, seg::String)` — line 76

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 76 | `seg` | param | the path segment appended | rename | `segment` |

## `_holds_components(c) = any(fieldnames(typeof(c))) do name` — line 78

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 78 | `c` | param | the component | rename | `comp` |
| 79 | `v` | local (in `do` block) | the field's value | keep:glance | — |
| 81 | `e` | lambda param | a container element | keep:glance | — |

## `children(path::String, c)` — line 105

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 105 | `c` | param | the component whose children are listed | rename | `comp` |

## `function _children(path::String, c)` — line 114

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 114 | `c` | param | the component whose children are collected | rename | `comp` |
| 115 | `tf` | local | the symbol of the name-transparent container field, or `nothing` | rename | `transparent_field` |
| 118 | `declarations` | local | per child, the label of the field or element that contributed it | collision | `contributors` |
| 138 | `v` | local | the field's value, read down to line 182 | rename | `value` |
| 144 | `n` | local | how many of the field's elements are components | rename | `component_count` |
| 144 | `e` | lambda param | a container element | keep:glance | — |
| 149 | `k` | comprehension | an element key | keep:glance | — |
| 152 | `k` | comprehension | a nested element key | keep:glance | — |
| 156 | `k` | comprehension | a mixed element key | keep:glance | — |
| 158 | `k` | comprehension | a mixed element key | keep:glance | — |
| 162 | `k` | for | the container element's key, read over 20 lines | rename | `key` |
| 163 | `p` | local | the element's contributor label, pushed into `declarations` | rename | `contributor` |

## `_is_container(v)` — line 194

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 194 | `v` | param | a field value | keep:glance | — |
| 194 | `e` | lambda param | an element | keep:glance | — |

## `_container_fields(c)` — line 197

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 197 | `c` | param | the component | rename | `comp` |
| 197 | `n` | comprehension | a field name | keep:glance | — |

## `_bears_component(v)` — line 200

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 200 | `v` | param | a value that may nest components | keep:glance | — |
| 201 | `e` | lambda param | an element | keep:glance | — |

## `function _check_transparent(path::String, c, tf, diags::Vector{Diagnostic})` — line 205

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 205 | `c` | param | the component | rename | `comp` |
| 205 | `tf` | param | the declared name-transparent field symbol | rename | `transparent_field` |
| 207 | `ok` | local | whether the declaration names a container field; read on the next line | keep:glance | — |

## `function _check_child_names(path::String, kids, declarations, diags::Vector{Diagnostic})` — line 218

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 218 | `declarations` | param | per child, its contributor label | collision | `contributors` |
| 219 | `i`, `j` | for | pair indices | keep:index | — |

## `Group(children; wires = (), inputs = (), outputs = (), rates = (;))` — line 264

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 264 | `children` | param | the named tuple of child components; shares its name with `children` (line 105) | collision | `members` (see Questions) |

## `_entries(p::Pair)` / `_entries(t)` — lines 267–268

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 267 | `p` | param | a single connection pair | rename | `connections` |
| 268 | `t` | param | a tuple of connection pairs; the two methods name the parameter differently | rename | `connections` |

## `child_connections(g::Group)` and its three siblings — lines 270–273

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 270 | `g` | param | the `Group` | keep:glance | — |
| 271 | `g` | param | the `Group` | keep:glance | — |
| 272 | `g` | param | the `Group` | keep:glance | — |
| 273 | `g` | param | the `Group` | keep:glance | — |

## `function resolve_terminal(entry::String, base::String, asm, path::AbstractString,` — line 298

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 298 | `asm` | param | the assembly the path is resolved against | rename | `assembly` |
| 300 | `segs` | local | the path's segments | rename | `segments` |
| 306 | `r` | local | `_one_level`'s result, tested then destructured two lines below | rename | `resolved` |
| 308 | `seg` | destructure | the child's segment | rename | `segment` |

## `function _one_level(entry::String, base::String, asm, path::AbstractString,` — line 318

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 318 | `asm` | param | the assembly | rename | `assembly` |
| 319 | `segs` | param | the path's segments | rename | `segments` |
| 322 | `j` | local | the matched child's position in `kids`, from `findfirst`, read to line 332 | rename | `child_index` |
| 329 | `k` | comprehension | a `segment => instance` pair | keep:glance | — |
| 332 | `seg` | destructure | the matched child's segment | rename | `segment` |

## `_declared_holding(c, field::Symbol)` — line 346

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 346 | `c` | param | the component | rename | `comp` |

## `_held_concretely(c, field::Symbol)` — line 348

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 348 | `c` | param | the component | rename | `comp` |
| 349 | `ft` | local | the field's declared type | keep:glance | — |

## `function resolve_authored(entry::String, base::String, level, path::AbstractString,` — line 362

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 365 | `segs` | local | the path's segments | rename | `segments` |
| 366 | `at` | destructure | the absolute path of `here`; shares its name with `at` (conditions.jl:92) | collision | `here_path` |
| 366 | `i` | destructure | the segment cursor of the `while` loop | keep:index | — |
| 385 | `j` | local | the matched child's position in `kids`, read to line 401 | rename | `child_index` |
| 392 | `k` | comprehension | a `segment => instance` pair | keep:glance | — |
| 395 | `seg` | destructure | the matched child's segment | rename | `segment` |

## `function authored_chain(root, path::AbstractString)` — line 417

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 419 | `segs` | local | the path's segments | rename | `segments` |
| 420 | `at` | destructure | the absolute path of `here`; shares its name with `at` (conditions.jl:92) | collision | `here_path` |
| 420 | `i` | destructure | the segment cursor of the `while` loop | keep:index | — |
| 423 | `j` | local | the matched child's position in `kids` | rename | `child_index` |
| 427 | `seg` | destructure | the matched child's name | rename | `segment` |

## `function resolve(asm, path::AbstractString)` — line 452

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 452 | `asm` | param | the assembly in hand | rename | `assembly` |
| 460 | `r` | local | `_one_level`'s result, read over three lines | rename | `resolved` |

## `function resolve_terminal(asm, path::AbstractString)` — line 473

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 473 | `asm` | param | the assembly in hand; the other method's parameter takes the same name | rename | `assembly` |
| 475 | `r` | local | the entry-ful method's result | rename | `resolved` |

## `_contract(fn, c)` — line 484

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 484 | `fn` | param | the contract declaration function (`input_types` or `output_types`) | rename | `declaration` |
| 484 | `c` | param | the component | rename | `comp` |

## `input_faces(c)` — line 497

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 497 | `c` | param | the component | rename | `comp` |
| 498 | `k` | comprehension | a contract key | keep:glance | — |

## `output_faces(c)` — line 510

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 510 | `c` | param | the component | rename | `comp` |
| 511 | `k` | comprehension | a contract key | keep:glance | — |

## `function _walked_faces(c, side::Int, fn, face_of)` — line 522

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 522 | `c` | param | the assembly instance | rename | `comp` |
| 522 | `fn` | param | the boundary declaration function | rename | `declaration` |

## `function input_passthrough(asm, child_path::AbstractString;` — line 558

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 558 | `asm` | param | the declaring assembly | rename | `assembly` |
| 559 | `sep` | keyword param | the separator between prefix and face name; a public keyword (§8.8) | roster? | — |
| 561 | `only` | keyword param | the kept face names; shares its name with `Base.only`, which the file calls at lines 462 and 477 | collision | none: a public keyword (§8.8, D-251); see Questions |
| 564 | `n` | generator | a kept face name | keep:glance | — |

## `function output_passthrough(asm, child_path::AbstractString;` — line 582

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 582 | `asm` | param | the declaring assembly | rename | `assembly` |
| 583 | `sep` | keyword param | the separator; a public keyword (§8.8) | roster? | — |
| 585 | `only` | keyword param | the kept face names; shares its name with `Base.only` | collision | none: a public keyword (§8.8, D-251); see Questions |
| 588 | `n` | generator | a kept face name | keep:glance | — |

## `_labelled(prefix, sep, n)` — line 591

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 591 | `sep` | param | the separator | roster? | — |
| 591 | `n` | param | the face name | keep:glance | — |

## `function _passthrough_faces(who::String, child_path::AbstractString,` — line 598

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 599 | `only` | param | the `only` selector's face names; shares its name with `Base.only`, not called in this scope | collision | `only_faces` |
| 607 | `g` | comprehension | a given selector's symbol | keep:glance | — |
| 608 | `n` | comprehension | a face name from `except` or `only` | keep:glance | — |
| 613 | `n` | comprehension | a face name from `only` | keep:glance | — |
| 615 | `n` | comprehension | a face name from `except` | keep:glance | — |
| 621 | `sel` | local | the one selector given, read over four lines | rename | `selector` |
| 623 | `n` | comprehension | a face name from `except` | keep:glance | — |

## `function resolve_source(draft, entry::String, base::String, asm, path::AbstractString,` — line 641

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 641 | `asm` | param | the declaring assembly | rename | `assembly` |
| 643 | `r` | local | `resolve_terminal`'s result, tested then destructured | rename | `resolved` |
| 645 | `cpath` | destructure | the resolved child's absolute path | rename | `comp_path` |
| 652 | `i` | local | the row of `draft.out_faces` naming the face, from `findfirst` | rename | `row` |
| 652 | `pr` | lambda param | an `out_faces` pair | keep:glance | — |

## `function resolve_dest(draft, entry::String, base::String, asm, path::AbstractString,` — line 664

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 664 | `asm` | param | the declaring assembly | rename | `assembly` |
| 666 | `r` | local | `resolve_terminal`'s result | rename | `resolved` |
| 668 | `cpath` | destructure | the resolved child's absolute path | rename | `comp_path` |
| 675 | `i` | local | the row of `draft.routes` naming the face, from `findfirst` | rename | `row` |
| 675 | `rt` | lambda param | a route row | keep:glance | — |

## `_endpoints(p::AbstractString)` / `_endpoints(ps::Tuple)` — lines 683–684

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 683 | `p` | param | one endpoint path; the two methods name the parameter differently | rename | `inner` |
| 684 | `ps` | param | a tuple of endpoint paths | rename | `inner` |

## `_fanout(draft, entry, base, comp, inner, diags)` — line 688

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 689 | `p` | generator | one endpoint path | keep:glance | — |

## `function _wrong_direction(entry, path, cpath, name, comp, wanted, diags)` — line 694

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 694 | `cpath` | param | the resolved child's absolute path | rename | `comp_path` |
| 695 | `ins` | destructure | the child's input face names | rename | `input_names` |
| 695 | `outs` | destructure | the child's output face names | rename | `output_names` |

## `function index_of(structure::Structure, path::String)` / `function index_of(draft::StructureDraft, path::String)` — lines 819, 824

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 820 | `ci` | local | the component index | keep:roster | — |
| 825 | `ci` | local | the component index | keep:roster | — |

## `function _check_sample_times(path::String, st, kids, fields, diags::Vector{Diagnostic})` — line 857

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 857 | `st` | param | the scope's `sample_times` value | rename | `rate_decl` |
| 858 | `_rv` | local function | records one `RatesViolation` against `path` | rename | `record_violation` |
| 858 | `kw` | param (of `_rv`) | the violation's payload keywords | rename | `payload` |
| 863 | `k` | for (destructure) | a `sample_times` key, read to line 880 | rename | `key` |
| 863 | `v` | for (destructure) | the `Relative` or `Absolute` value under it, read to line 876 | rename | `rate` |
| 878 | `seg` | generator (destructure) | a child's segment | keep:glance | — |
| 879 | `fld` | generator | a contributing field name | keep:glance | — |
| 880 | `p` | comprehension | a `segment => instance` pair | keep:glance | — |

## `function _rate_entry(st, seg::String, fld::Symbol)` — line 890

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 890 | `st` | param | the scope's `sample_times` value | rename | `rate_decl` |
| 890 | `seg` | param | the child's segment | rename | `segment` |
| 890 | `fld` | param | the field that contributed the child | rename | `field` |
| 892 | `k`, `v` | for (destructure) | a key and its wrapper value, consumed on the next line | keep:glance | — |
| 895 | `k`, `v` | for (destructure) | a key and its wrapper value, consumed on the next line | keep:glance | — |

## `function _child_scope(draft::StructureDraft, path::String, st, seg::String, fld::Symbol,` — line 912

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 912 | `st` | param | the scope's `sample_times` value | rename | `rate_decl` |
| 912 | `seg` | param | the child's segment | rename | `segment` |
| 912 | `fld` | param | the child's contributing field | rename | `field` |
| 916 | `k` | destructure | the key the entry was found under, read to line 931 | rename | `key` |
| 916 | `v` | destructure | the wrapper value, read to line 931 | rename | `rate` |
| 929 | `a` | local | the anchor's index in `draft.anchors`; `a` is also the fold comment's symbol for an anchor (line 845) | rename | `anchor_index` |

## `function _last_level(draft::StructureDraft, path::String, face::Symbol)` — line 981

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 983 | `rpath` | for (destructure) | the route's assembly path | rename | `route_path` |

## `function wire!(draft::StructureDraft)` — line 998

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1008 | `cs` | for (destructure) | one component's resolved connections | rename | `comp_conns` |

## `Structure(draft::StructureDraft, conns::Vector{Vector{Pair{Symbol,Tuple{String,Symbol}}}},` — line 1019

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1024 | `cs` | comprehension (destructure) | one component's connections | keep:glance | — |

## `function _walk!(draft::StructureDraft, path::String, comp, scope::Timing,` — line 1032

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1060 | `t` | local (in `do` block) | the primitive's tier, or `nothing`, returned at line 1078; `t` is time by the rules | rename | `tier` |
| 1087 | `st` | local | the assembly's `sample_times` value | rename | `rate_decl` |
| 1090 | `seg` | for (destructure) | the child's segment, read to line 1099 | rename | `segment` |
| 1090 | `fld` | for (destructure) | the child's contributing field | rename | `field` |
| 1092 | `kscope` | destructure | the child's scope timing | rename | `kid_scope` |
| 1092 | `klink` | destructure | the child's own rate link, or `nothing` | rename | `kid_link` |
| 1094 | `t` | local | the child's tier, `nothing` for an assembly | rename | `tier` |
| 1108 | `ins` | local | the evaluated `input_connections` entries, read to line 1129 | rename | `input_entries` |
| 1109 | `outs` | local | the evaluated `output_connections` entries, read to line 1151 | rename | `output_entries` |
| 1113 | `f` | comprehension (destructure) | an input face name | keep:glance | — |
| 1114 | `f` | comprehension (destructure) | an output face name | keep:glance | — |
| 1151 | `src` | for (destructure) | the output entry's internal source endpoint | rename | `source` |

## `function _check_face_names(path::String, ins, outs, diags::Vector{Diagnostic})` — line 1183

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1183 | `ins` | param | the evaluated `input_connections` entries | rename | `input_entries` |
| 1183 | `outs` | param | the evaluated `output_connections` entries | rename | `output_entries` |
| 1186 | `n` | for | a face name; one-line body | keep:glance | — |
| 1192 | `n` | generator | a face name | keep:glance | — |

## `function _check_root_faces(comp, diags::Vector{Diagnostic})` — line 1204

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1205 | `outs` | local | the primitive root's output face names | rename | `output_names` |
| 1206 | `dup` | local | the face names both contracts declare | rename | `duplicates` |
| 1206 | `n` | comprehension | an input face name | keep:glance | — |

## Collisions

| line | local | function | defined at | called in the binding scope? |
| --- | --- | --- | --- | --- |
| 118 | `declarations` (`_children`) | `declarations` | `src/build.jl:110` | no |
| 218 | `declarations` (`_check_child_names`) | `declarations` | `src/build.jl:110` | no |
| 264 | `children` (`Group`'s convenience constructor) | `children` | `src/assembly.jl:105` | no |
| 366 | `at` (`resolve_authored`) | `at` | `src/conditions.jl:92`, `:93` | no |
| 420 | `at` (`authored_chain`) | `at` | `src/conditions.jl:92`, `:93` | no |
| 561 | `only` (`input_passthrough` keyword) | `Base.only` | Base; the file calls it at lines 462 and 477 | no |
| 585 | `only` (`output_passthrough` keyword) | `Base.only` | Base; the file calls it at lines 462 and 477 | no |
| 599 | `only` (`_passthrough_faces` param) | `Base.only` | Base; the file calls it at lines 462 and 477 | no |

## Roster proposals

- `sep` (separator): 3 sites (lines 559, 583, 591), each read once or twice. Two are public keywords of `input_passthrough`/`output_passthrough` (§8.8) and cannot change without an API change; `_labelled`'s parameter follows them.

## Questions

- The brief gives tip `4a3b725`; the tree was at `f64b9f3`, which adds only this brief. The header uses `f64b9f3`.
- `kids`/`kid` (about 30 sites) are plain words, so the brief's tests do not flag them, but they exist to dodge the function `children`. Should they become `child_pairs`/`child`? `child` is free.
- `Group(children; …)`: the positional parameter mirrors the field and the docstring's signature line. Renaming it to `members` changes that line. The alternative is a second named exception beside `path`.
- Public keyword parameters (`sep`, `only`, `except`, `select`, `prefix`): the rules exempt keyword names at call sites but say nothing about the parameter that defines them. I read them as API and proposed no renames; the rules could say so.
- If `_passthrough_faces`' `only` becomes `only_faces`, its `except` should become `except_faces` for symmetry, though `except` is not flagged.
- `index_of(structure::Structure, …)` and `index_of(draft::StructureDraft, …)` name their first parameter differently, each after its type's noun. "Every method alike" would force one name. I did not flag them; a ruling is needed on whether the rule covers parameters that dispatch on different types.
- `seg`/`segs` cover about 14 sites; I proposed `segment`/`segments` over a roster entry.
- `ins`/`outs` hold two things in this file, face-name lists (`_wrong_direction`, `_check_root_faces`) and evaluated connection entries (`_walk!`, `_check_face_names`). The proposals split them into `input_names`/`output_names` and `input_entries`/`output_entries`.
- `rates` already names a `Vector{RateLink}` in `Structure(draft, …)` (line 1024) and the `Group` field holding a `sample_times` value. I proposed `rate_decl` for `st` to keep `rates` to one meaning among locals.
- `tail` (`_one_level`) shares its name with the unexported `Base.tail`, which the file never calls. Not flagged.
- `Group`'s type parameters `C, W, I, O, R` and `Anchor`'s field `T` fall outside the brief's site list and are not listed.
