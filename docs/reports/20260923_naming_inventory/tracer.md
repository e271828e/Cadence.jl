# Naming inventory: src/tracer.jl

Tip: f64b9f3. Sites flagged: 164. Renames: 69. Collisions: 2. Roster proposals: 1.

## Letters with more than one meaning in this file

- `d`: a member's `Decls` for one evaluation (`_trace_direct`, line 194), the `AlgebraicCycle` diagnostic (`_classify`) → both renamed below; `d` belongs to `diagnostics.jl`
- `e`: the caught exception (`_classify`, lines 325, 364), an edge tuple (`_classify`'s lambdas, lines 297, 299) → edges renamed `edge`, exceptions `exception`
- `f`: the generated function's symbol (the `@eval` loops, lines 53–117), the leaf function (`_walk`), a face name (`_classify`, lines 296, 314, 333, 351) → face sites renamed `face`
- `a`, `b`: the operands (lines 54, 58, 106), the `ifelse` condition (`b`, line 62), a face's and a port's position (line 333) → operands become `x`, `y`, `z`, positions `j`, `k`
- `v`: a leaf-bearing value (`_walk`, `_lift`, `_tag`, `_sample`, `_depset`), an array (`_norm`, `norm`), an operand in `hypot`'s lambdas, a graph vertex (`_has_cycle`) → the vertex renamed `vertex`
- `t`: the tuple of `hypot`'s operands (line 85), a member's trace mode (line 363); the rules reserve `t` for time → both renamed
- `m`: a member path (line 363); the spec's `m` is the mode store (`mstores`) → renamed `member`
- `s`: the dependency bitmask (`_depset`); the spec's `s` is the discrete state → renamed `deps`
- `k`: an index into `root_inputs` (`_seed`), a port-graph endpoint key (`id!`) → the key renamed `endpoint`
- `p`: the norm's order (`_norm`, `norm`), a connection pair (`_seed`'s lambda) → both one-glance, kept; see Questions
- `S`: the tracer mode in `Tracer{S}` and `_decide`'s `S::Bool`, the `StaticArray` size tuple (line 95) → kept as a type parameter; see Questions
- `x`, `y`: a scalar operand in the `Base` overloads; the spec's `x` and `y` are the state and the outputs, which this file reaches only as fields (`dc.x`) and as `y2` → see Questions

## `Tracer{S}(x::Real) where {S}` — line 35

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 35 | `S` | type param | the tracer mode | keep:typeparam | — |
| 35 | `x` | param | the real being lifted | keep:glance | — |
| 36 | `x` | param | the tracer passed through (second method, same name) | keep:glance | — |

## `Base.promote_rule(::Type{Tracer{S}}, …)` — lines 38, 41

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 41 | `S`, `T`, `V`, `N` | type params | the tracer mode, the dual's tag, value type and width | keep:typeparam | — |

## `Base.float(x::Tracer)`, `Base.Float64(x::Tracer{false})` — lines 44, 48

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 44 | `x` | param | the operand | keep:glance | — |
| 48 | `x` | param | the operand | keep:glance | — |

## top-level `for f in (:+, :-, …)` and its `@eval Base.$f(a, b)` — line 53

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 53 | `f` | for (top level) | the generated function's symbol | keep:glance | — |
| 54 | `a` | param | the first operand | rename | `x` (every method of `^`, `-`, `atan` names its first operand `x` elsewhere: lines 57, 70) |
| 54 | `b` | param | the second operand | rename | `y` (matches `hypot(x, y, z...)`, line 84, and `ifelse(b, x, y)`) |

## `Base.:^(x::Tracer{S}, n::Integer)` — line 57

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 57 | `x` | param | the base | keep:glance | — |
| 57 | `n` | param | the integer exponent (Base's own name) | keep:glance | — |

## `Base.muladd(a, b, c)` — line 58

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 58 | `a`, `b` | param | the multiplied operands | rename | `x`, `y` (with line 54) |
| 58 | `c` | param | the added operand; `c` is the component instance elsewhere in `src/` | rename | `z` |

## `Base.clamp(x::Tracer{S}, lo::Real, hi::Real)` — line 60

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 60 | `x` | param | the clamped operand | keep:glance | — |
| 60 | `lo`, `hi` | param | the bounds (Base's own names) | keep:glance | — |

## `Base.ifelse(b::Bool, x, y)` — line 62

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 62 | `b` | param | the condition; `b` also names an operand (line 54) and a port position (line 333) | rename | `test` (`condition` is a package function, `conditions.jl:53`) |
| 62 | `x`, `y` | param | the two arms | keep:glance | — |

## top-level `for f in (:-, :abs, …)` and its `@eval Base.$f(x)` — line 65

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 65 | `f` | for (top level) | the generated function's symbol | keep:glance | — |
| 70 | `x` | param | the operand | keep:glance | — |

## `Base.hypot(x, y, z...)` — line 84

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 84 | `x`, `y`, `z` | param | the operands | keep:glance | — (the binary method's `a, b` move to these, line 54) |
| 85 | `t` | local | the operands as one tuple; `t` is time by rule | rename | `operands` |
| 86 | `v` | lambda | one operand | keep:glance | — |

## `_norm(v, p::Real)` — line 89

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 89 | `v` | param | the array | keep:glance | — |
| 89 | `p` | param | the norm's order (Base's own name) | keep:glance | — |
| 89 | `x` | lambda | one element | keep:glance | — |

## `LinearAlgebra.norm(v, p::Real = 2)` — lines 91, 95

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 91 | `v`, `p` | param | the array, the order | keep:glance | — |
| 95 | `v`, `p` | param | the array, the order (same names as line 91) | keep:glance | — |
| 95 | `S` | type param | the `StaticArray`'s size tuple; `S` is the tracer mode everywhere else in the file | keep:typeparam | — (see Questions) |

## `_decide(S::Bool, deps::UInt64)` — line 103

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 103 | `S` | param | the tracer mode as a value, the type parameter each caller passes | keep:typeparam | — |

## top-level deciders: `for f in (:<, :<=, :(==), :isless)`, `(:iszero, …)`, `(:round, :floor, :trunc)` — lines 105, 111, 117

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 105 | `f` | for (top level) | the generated function's symbol | keep:glance | — |
| 106 | `a`, `b` | param | the compared operands | rename | `x`, `y` (with line 54) |
| 111 | `f` | for (top level) | the generated function's symbol | keep:glance | — |
| 112 | `x` | param | the operand | keep:glance | — |
| 117 | `f` | for (top level) | the generated function's symbol | keep:glance | — |
| 118 | `I` | type param | the target integer type | keep:typeparam | — |
| 118 | `x` | param | the operand | keep:glance | — |

## `Base.Int(x)`, `Base.Bool(x)` — lines 123, 127

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 123 | `x` | param | the operand | keep:glance | — |
| 127 | `x` | param | the operand | keep:glance | — |

## `_walk(::Type{T}, v, f) where {T}` — line 139

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 139 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 139 | `v` | param | the value whose leaves are walked | keep:glance | — |
| 139 | `f` | param | the per-leaf function | keep:glance | — |
| 140 | `l` | comprehension | one leaf | keep:glance | — |

## `_lift(::Type{T}, v) where {T}` — line 143

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 143 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 143 | `v` | param | the probed prefix value | keep:glance | — |
| 143 | `l` | lambda | one leaf | keep:glance | — |

## `_tag(::Type{T}, v, bit::UInt64) where {T}` — line 150

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 150 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 150 | `v` | param | the face value to seed | keep:glance | — |
| 151 | `l` | lambda | one leaf | keep:glance | — |

## `_sample(rng, ::Type{T}, v, bit::UInt64) where {T}` — line 159

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 159 | `rng` | param | the sampled fallback's generator | roster? | `rng` (see Roster proposals) |
| 159 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 159 | `v` | param | the value to redraw | keep:glance | — |
| 160 | `l` | lambda | one leaf | keep:glance | — |

## `_depset(v)` — line 163

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 163 | `v` | param | the port value | keep:glance | — |
| 164 | `s` | local | the accumulated tag bitmask; the spec's `s` is the discrete state | rename | `deps` (the `Tracer` field it unions) |
| 165 | `l` | for | one leaf; a loop variable, not an index, read in the body | rename | `leaf` |

## `_trace_direct(ci::Int, dT::Decls, fs::Vector{Symbol}, tf::Vector{Bool}, …)` — line 183

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 183 | `ci` | param | the member's component index | keep:index | — |
| 183 | `dT` | param | the member's declarations at the tracer scalar | rename | `traced_decl` (role beside `decl`, the nominal one, line 188) |
| 183 | `fs` | param | the member's in-cycle entering faces (the docstring's "faces of `fs`") | rename | `faces` |
| 183 | `tf` | param | per face, whether it has a walking leaf at the tracer scalar | rename | `face_traceable` |
| 184 | `qs` | param | the member's in-cycle leaving ports | rename | `ports` |
| 185 | `decls` | param | every component's declarations | keep:roster | — |
| 185 | `mstores` | param | the per-component mode stores (`m`'s derivative) | keep:spec | — |
| 186 | `inscc` | param | the cluster's component indices as a set | rename | `cluster_set` |
| 186 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 187 | `rng` | keyword | the sampled fallback's generator, `nothing` for the exact trace | roster? | `rng` |
| 188 | `c` | destructure | the member's component instance | rename | `comp` |
| 188 | `dc` | destructure | the member's nominal declarations | rename | `decl` |
| 189 | `u` | local | the member's input bundle | keep:spec | — |
| 194 | `d` | local | the declarations this evaluation reads: `dT`, or `dT` with a redrawn `x`; `d` is a diagnostic by rule | rename | `evaluation_decl` |
| 196 | `bn` | local | the stage's bundle field names | rename | `bundle_fields` (`bundle_names` is the function it calls) |
| 197 | `ws` | local | the member's workspace, or `nothing` | rename | `workspace` |
| 198 | `y2` | local | the member's stage-2 outputs (`y`'s derivative) | keep:spec | — |
| 200 | `q` | comprehension | one port | keep:glance | — |

## `_trace_sampled(ci::Int, fs::Vector{Symbol}, tf::Vector{Bool}, qs::Vector{Symbol}, …)` — line 211

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 211 | `ci` | param | the member's component index | keep:index | — |
| 211 | `fs` | param | the member's in-cycle entering faces | rename | `faces` (as in `_trace_direct`) |
| 211 | `tf` | param | per face, whether it is traceable | rename | `face_traceable` |
| 211 | `qs` | param | the member's in-cycle leaving ports | rename | `ports` |
| 212 | `decls` | param | every component's declarations | keep:roster | — |
| 213 | `mstores` | param | the mode stores | keep:spec | — |
| 214 | `inscc` | param | the cluster as a set | rename | `cluster_set` |
| 215 | `T` | local | the local tracer's scalar type, bound as a local; `T` is the numeric type file-wide | keep:typeparam | — |
| 216 | `dT` | local | the member's declarations at `T` | rename | `traced_decl` |
| 217 | `rng` | local | the fixed-seed generator | roster? | `rng` |
| 218 | `q` | comprehension | one port | keep:glance | — |
| 220 | `r` | local | one sampled evaluation's port-to-tags map; read three lines below | rename | `sample_routes` |
| 222 | `q` | for | one port; one-line body | keep:glance | — |

## `_seed(ci::Int, face::Symbol, fs::Vector{Symbol}, tf::Vector{Bool}, structure::Structure, …)` — line 238

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 238 | `ci` | param | the member's component index | keep:index | — |
| 238 | `fs` | param | the member's in-cycle entering faces | rename | `faces` |
| 238 | `tf` | param | per face, whether it is traceable | rename | `face_traceable` |
| 239 | `inscc` | param | the cluster as a set | rename | `cluster_set` |
| 240 | `T` | type param | the tracer scalar | keep:typeparam | — |
| 240 | `rng` | param | the generator, or `nothing` | roster? | `rng` |
| 241 | `conns` | local | the member's connections | keep:roster | — |
| 242 | `ppath` | destructure | the producer's path | rename | `producer_path` |
| 242 | `pport` | destructure | the producer's port name | rename | `producer_port` |
| 242 | `p` | lambda | one connection pair | keep:glance | — |
| 244 | `k` | local | the root input's position in `root_inputs` | keep:index | — |
| 247 | `pi` | local | the producer's component index; shadows `Base.pi` | rename | `producer_ci` |
| 250 | `j` | local | the face's position in `fs`, or `nothing` | keep:index | — |

## `_classify(d::AlgebraicCycle, scc::Vector{Int}, edges, placed::Vector{Int}, …)` — line 272

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 272 | `d` | param | the cycle diagnostic being classified; `d` is a diagnostic in `diagnostics.jl` alone | rename | `cycle` |
| 272 | `scc` | param | the cluster's component indices, in `d.members` order (the docstring: "`scc` is the cluster") | rename | `cluster` |
| 273 | `decls` | param | every component's declarations | keep:roster | — |
| 274 | `mstores` | param | the mode stores | keep:spec | — |
| 275 | `T` | local | the global tracer's scalar type | keep:typeparam | — |
| 280 | `wss` | local | the per-component workspaces at the nominal scalar | rename | `workspaces` (`_workspaces` is the function it calls; the bare noun is free) |
| 281 | `s1` | comprehension | one component's stage-1 products | keep:glance | — |
| 282 | `ci` | for | a placed component's index | keep:index | — |
| 287 | `inscc` | local | the cluster as a set | rename | `cluster_set` |
| 288 | `faces` | local | per member, its entering faces; unflagged, renamed to free `faces` for `fs` | rename | `member_faces` |
| 289 | `ports` | local | per member, its leaving ports; unflagged, renamed to free `ports` for `qs` | rename | `member_ports` |
| 288 | `_` | comprehension | discarded | keep:glance | — |
| 291 | `modes` | local | per member, the trace mode taken; shares its name with `modes(sim, path)` | collision | `trace_modes` |
| 294 | `i`, `ci` | for | the member's position and component index | keep:index | — |
| 295 | `dc` | local | the member's nominal declarations | rename | `decl` |
| 296 | `fs` | local | the member's in-cycle entering faces | rename | `faces` (after line 288's rename) |
| 296 | `f` | comprehension | one input face; `f` is a function symbol elsewhere in the file | rename | `face` |
| 297 | `e` | lambda | one edge tuple `(producer ci, port, face)`; `e` is the exception at lines 325, 364 | rename | `edge` |
| 298 | `qs` | local | the member's in-cycle leaving ports | rename | `ports` (after line 289's rename) |
| 298 | `q` | comprehension | one output port | keep:glance | — |
| 299 | `cj` | lambda | another member's component index | keep:index | — |
| 299 | `e` | lambda | one edge tuple | rename | `edge` |
| 305 | `dT` | local | the member's declarations at the tracer scalar, or `nothing` | rename | `traced_decl` |
| 307 | `tf` | local | per face, whether it has a walking leaf at `T` | rename | `face_traceable` |
| 308 | `f` | comprehension | one face | rename | `face` |
| 309 | `tq` | local | per port, whether it has a walking leaf at `T` | rename | `port_traceable` |
| 310 | `q` | comprehension | one port | keep:glance | — |
| 314 | `f`, `q` | for | a face and a port of a structural hop | rename | `face`, `port_name` (`port` is a package function, `sim.jl:1806`) |
| 322 | `mode` | destructure | the trace mode, `:global` or `:sampled`; shares its name with `mode(sim)` | collision | `trace_mode` |
| 325 | `e` | catch | the exception out of the global trace; `e` is an edge in the lambdas above | rename | `exception` |
| 333 | `a` | for (enumerate) | the face's position, the bit it tags | rename | `j` |
| 333 | `f` | for (enumerate) | the face | rename | `face` |
| 333 | `b` | for (enumerate) | the port's position | rename | `k` |
| 333 | `q` | for (enumerate) | the port | rename | `port_name` |
| 346 | `adj` | local | the port graph's adjacency lists | rename | `adjacency` |
| 347 | `id!` | local function | the node id of an endpoint, allocated on first sight | rename | `node_id!` |
| 347 | `k` | param | an endpoint key `(member position, is-face, name)`; `k` is an index elsewhere | rename | `endpoint` |
| 351 | `i` | for | the member's position | keep:index | — |
| 351 | `f`, `q` | for | a face and a port of one member | rename | `face`, `port_name` |
| 354 | `i`, `ci` | for | the member's position and component index | keep:index | — |
| 354 | `pi` | destructure (for) | the producer's component index; shadows `Base.pi` | rename | `producer_ci` |
| 354 | `pport` | destructure (for) | the producer's port | rename | `producer_port` |
| 356 | `j` | local | the producer's position in the cluster | keep:index | — |
| 363 | `m` | comprehension | a member's path; `m` is the mode store by the spec | rename | `member` |
| 363 | `t` | comprehension | the member's trace mode; `t` is time by rule | rename | `trace_mode` |
| 364 | `e` | catch | the exception out of the whole classification | rename | `exception` |

## `_has_cycle(adj::Vector{Vector{Int}})` — line 371

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 371 | `adj` | param | the port graph's adjacency lists | rename | `adjacency` |
| 373 | `v` | param (local function `grey!`) | the vertex being entered; read four times over eight lines | rename | `vertex` |
| 375 | `w` | for | a successor of `v` | rename | `successor` |
| 382 | `v` | lambda | one vertex | keep:glance | — |

## Collisions

- `modes` (line 291, `_classify`): `modes(sim::Simulation, path::String)` at `src/sim.jl:1826`. Not called inside `_classify`. Proposal `trace_modes`.
- `mode` (line 322, `_classify`): `mode(sim::Simulation)` at `src/sim.jl:345`. Not called inside `_classify`. Proposal `trace_mode`.

Near-collisions avoided in the proposals: `port` (`src/sim.jl:1806`, `src/dataplane.jl:598`), hence `port_name`; `condition` (`src/conditions.jl:53`), hence `test`; `bundle_names` and `_workspaces` are functions, the proposals `bundle_fields` and `workspaces` are not. `pi` (lines 247, 354) shadows `Base.pi`, a constant rather than a function; it is renamed as an abbreviation.

## Roster proposals

- `rng`: 4 sites (lines 159, 187, 217, 240); abbreviates "random number generator", Julia's own idiom (`Random`'s keyword and parameter name).

## Questions

- The binary `@eval` loop names its operands `a, b` while `hypot`, `^`, `ifelse`, `clamp` and the unary loop use `x` (and `y`, `z`). "Every method of a function names its parameters alike" binds `^`, `-`, `atan`, `hypot`, `min`/`max` across the two loops; the proposal aligns on Base's `x, y, z`. The alternative, `a, b, c` everywhere, would free `x` and `y` from the spec's state and outputs, at twice the churn. The rules do not say whether a `Base` overload's operand counts as the spec's `x`.
- `S` names the tracer mode throughout, and the size tuple of `StaticArray{S,<:Tracer}` on line 95. Kept as a type parameter; `Size` would make the file's `S` single-meaning if the user wants that.
- `_decide(S::Bool, …)` binds a value parameter with the type parameter's letter on purpose (callers pass their `S`). Classified `keep:typeparam`; the rules have no code for a value mirroring a type parameter.
- `mstores` is classified `keep:spec` as `m`'s derivative, like `x_offs`. If the user reads it as an abbreviation, it is a `roster?` candidate (it is also the executor's field name).
- `T` bound as a local (`T = Tracer{true}`, lines 215, 275) is classified `keep:typeparam`; it plays the type parameter's part for the calls below it.
- `p` names both the norm's order and a connection pair (`_seed`'s lambda). Both are one-glance; the rules' "one name, one meaning per file" would rename the lambda's to `conn`, which reads as a roster abbreviation's singular. Left as kept.
