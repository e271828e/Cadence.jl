# Increment 40 — three specified checks: `DeadStage`, `MissingProbeValue` and the read-miss candidates (§5.2, §9.3, §11.2, §14.4, Appendix C, D-051)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `8b5b23a` plus the register commit that adds this brief. Never `cd`
elsewhere (`cd` is aliased to zoxide in the user's shell; use absolute
paths).

**Standing.** Three checks Appendix C specifies in full have no code. Each
is a small, local addition whose row fixes payload and policy, so this
increment needs no ruling. Measured on Julia 1.13.0 before this brief was
written, with the fixtures loaded through `test/repl.jl`:

| case | today |
|---|---|
| `output_state(::C, (; x)) = (;)` while `output_direct` produces every declared port | **builds silently** |
| `output_direct(::C, (; x)) = (;)` while `output_state` produces every declared port | **builds silently** |
| a root input typed `Pair2{Float64}` (two `Real` leaves, no zero-argument constructor) | raw `MethodError: no method matching Pair2{Float64}()` escapes `build` |
| `get_output("p", :nope)` in a binding's `reads` | `ReadBindingUnresolved`, `candidates` empty |
| `get_face(:nope)` in a binding's `reads` | `ReadBindingUnresolved`, `candidates` empty |

No fixture in the suite returns a bare `(;)` from a stage today
(`rg -n '(output_state|output_direct)\(.*=\s*\(;\)' test/` is empty), so
the new check trips nothing existing. **One stage, one commit**, the routed
subset green.

**Read, all in `docs/design/spec.md`:** §9.3's probe passage (3284–3287:
"Two checks ride the same pass", the dead-stage rule) and its `probe_value`
paragraph (3294–3315: the fallback chain, "No method is a build error, in
the didactic style", the example message). §5.2's two `DeadStage` sentences
(684–686, 772–776). §14.4 and §11.2 only through Appendix C's row. Appendix
C's three rows: `MissingProbeValue` (10877–10878), `DeadStage`
(10918–10920), `ReadBindingUnresolved` (10985–10989). §13.1's collected
rule (7263–7273) and the didactic style (§13.2). In
`docs/design/decisions.md`: D-051 (1396–1418, the synthesis chain and the
missing-method error), D-216 (7598–7640, the column is the design).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (112–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/build.jl` (25),
  `src/bindings.jl` (34), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–110)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–24) is
the one this increment retires. It says "the `get_output` arm"; the
increment fills both name-shaped misses (see below), and the bullet retires
whole.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the cited rows and this brief disagree, stop and say so in the
report rather than improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

This change reaches rows one and three of the routing table plus `readers`,
whose tests assert `ReadBindingUnresolved` too: `declare assembly build
diagnostics leaves dataplane roster bindings devices trace lifecycle log
readers`. Run that subset as "Running the suite" says, under the sandbox
flags, and gate the commit on it; the full suite is the reviewer's, once
per increment. Commit subject: one sentence, no body, no attribution. Do
not push. Never stash, reset or check out the working tree; a baseline is
read with `git show <tip>:path`.

---

## The constructs

### The two kinds, in `src/diagnostics.jl`

Appendix C's order. `MissingProbeValue` directly before `ChildNameCollision`
(line 618); `DeadStage` directly before `ConformanceFailure` (line 842).
Severity error (the default), no `severity` method.

```julia
"§9.3, D-051: a root input whose type the synthesis chain cannot produce a probe value for."
Base.@kwdef struct MissingProbeValue <: Diagnostic
    face::Symbol                             # the root input face
    declared::Any                            # the face's type at this activation
end
path(::MissingProbeValue) = ""               # a root input's path is the root's
```

Message, the spec's own example (3303–3306) with the citation:

```
no `probe_value` for `Pair2{Float64}` at face `in` — define
`probe_value(::Type{Pair2{Float64}})` or a zero-argument constructor (§9.3)
```

Interpolate `d.declared` directly, as `IllegalPortType` does: the remedy
spells the type with its parameters, and `_typename` would strip them.

```julia
"§5.2, §9.3: a stage method that returned bare `(;)`, producing no ports."
Base.@kwdef struct DeadStage <: Diagnostic
    path::String
    stage::String                            # "output_state" | "output_direct"
end
path(d::DeadStage) = d.path
```

Message, in the didactic style, with `_at_path` for the path:

```
`c`: `output_state` returns bare `(;)`, producing no ports — a stage that
produces nothing computes nothing any consumer can read; return the ports
the stage owns, or drop the method so the stage is absent (§5.2, §9.3)
```

### `DeadStage`, in `src/build.jl`

Two sites, one per stage, each directly after the existing return-shape
check and before `_check_ports`, so the pass reads shape, then dead stage,
then ports (§9.3's order). Fail-fast, thrown alone, exactly as the shape
check beside it throws.

In `probe_stage1` (after line 173):

```julia
        isempty(y) && throw(DiagnosticError(DeadStage(path = path, stage = stage)))
```

In `_probe_direct!` (after line 950), the same line on `y2`. Both sites sit
behind their `has_stage` guard (165, 939), so an absent method never reaches
them: `(;)` here is a method the author wrote. `_probe_direct!` is also the
cycle classifier's prefix probe, which is right: the same stage is dead
there too.

### `MissingProbeValue`, in `src/build.jl`

In `cell_layout`'s root-input loop (509–513), the one call to `probe_value`
on a root input. It collects into the loop's own `diags`, whose barrier is
the line after the loop (514), beside `IllegalPortType`'s two root-input
arms. Today:

```julia
        place!("", :root_input, face, P) || continue
        push!(root_inputs, (face, probe_value(P)))
```

becomes

```julia
        place!("", :root_input, face, P) || continue
        # §9.3, D-051: the synthesis chain ends at `P()`, and a type reaching
        # it with no zero-argument constructor has no probe value. Collected,
        # beside the placement refusals above.
        v = try
            probe_value(P)
        catch e
            e isa MethodError || rethrow()
            push!(diags, MissingProbeValue(face = face, declared = P))
            continue
        end
        push!(root_inputs, (face, v))
```

Catch `MethodError` only; anything else propagates as today. A
`MethodError` thrown inside an author's own `probe_value` override is
reported as this kind too. That is the conservative reading of "No method
is a build error" and the docstring says so. The site runs once per
activation, so a `Dual` activation reports the retyped `P`. The two other
`probe_value` calls in `src/tracer.jl` (245, 248) run after the layout has
succeeded and need nothing.

### The candidates, in `src/bindings.jl`

`ReadBindingUnresolved` already carries `candidates::Vector{Symbol}`,
filled on the `get_input` miss alone (`_resolve_read(::Layout, ::GetInput,
…)`, 170–175). The two other **name-shaped** misses gain the list in hand;
the three that are not name-shaped (`:store_selector`, `:indexed`,
`:root_input_not_output`) have no list to offer and stay as they are.

- `:unknown_cell` (`GetOutput`, 165–167): the cells at the selector's path,
  `sort!(Symbol[n for (p, n) in keys(layout.addr) if p == s.path])`. An
  assembly path lists its faces, since the alias pass enters them into
  `addr`. An unknown path yields the empty list.
- `:unknown_output_face` (`GetFace`, 184–186): the root-exported output
  faces, `sort!(Symbol[n for (p, n) in keys(layout.addr) if p == "" && n ∉
  _root_input_names(layout)])`.

Two helper functions beside `_root_input_names` (151) keep the two
comprehensions out of the throw sites.

In `src/diagnostics.jl`, the two message arms (1195–1197, 1203–1204) spell
the list through `_faceset`:

- `:unknown_cell`: "… which names no cell — the cells at `p` are {power, y}
  (§14.4)"; with an empty list, "… which names no cell — `q` has no cells
  (§14.4)".
- `:unknown_output_face`: "… `nope` is no root-exported output face — the
  output faces are {y} (§14.4, §11.2)".

### Fixtures

Grep every name below across `test/` before defining it: a same-named type
silently rebinds a fixture module on 1.13. At this tip `rg -n
'DeadStateStage|DeadDirectStage|NoDefault|Unsynthesized|WithProbe|Synthesized'
test/` returns nothing. The shapes are the contract, not the exact text.

`test/test_build.jl`, at top level beside `NoFlow` (36):

```julia
# A stage that returns bare `(;)` (§5.2, §9.3), one per position. Each
# produces every declared port from the *other* stage, so nothing else is
# wrong: `DeclaredNotProduced` stays silent, and only the dead-stage rule
# sees it.
struct DeadStateStage <: AbstractComponent end
init_x(::DeadStateStage) = (; a = 0.0)
output_types(::DeadStateStage, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::DeadStateStage, (; x)) = (;)
output_direct(::DeadStateStage, (; x)) = (p = x.a,)
state_derivative(::DeadStateStage, (; x)) = (; a = 0.0)

struct DeadDirectStage <: AbstractComponent end
init_x(::DeadDirectStage) = (; a = 0.0)
output_types(::DeadDirectStage, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::DeadDirectStage, (; x)) = (p = x.a,)
output_direct(::DeadDirectStage, (; x)) = (;)
state_derivative(::DeadDirectStage, (; x)) = (; a = 0.0)
```

`test/test_build.jl`, at top level beside `Query`/`MatrixEntry` (the
fixtures `build_port_type_refusals` uses, above 668):

```julia
# A product-type root input with `Real` leaves and no zero-argument
# constructor (§9.3, D-051): it passes the handle check and reaches the
# synthesis chain's last arm, `P()`. `WithProbe` is the same shape with the
# remedy the message names.
struct NoDefault{T}
    a::T
    b::T
end
struct Unsynthesized <: AbstractComponent end
input_types(::Unsynthesized, ::Type{T}) where {T <: Real} = (q = NoDefault{T},)
output_types(::Unsynthesized, ::Type{T}) where {T <: Real} = (s = T,)
output_direct(::Unsynthesized, (; u)) = (s = u.q.a + u.q.b,)

struct WithProbe{T}
    a::T
    b::T
end
probe_value(::Type{WithProbe{T}}) where {T} = WithProbe(zero(T), one(T))
struct Synthesized <: AbstractComponent end
input_types(::Synthesized, ::Type{T}) where {T <: Real} = (q = WithProbe{T},)
output_types(::Synthesized, ::Type{T}) where {T <: Real} = (s = T,)
output_direct(::Synthesized, (; u)) = (s = u.q.a + u.q.b,)
```

`probe_value` is on `test/imports.jl` (52) already, so the override
extends the framework's function.

### Tests

The build tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset.

- `test/test_build.jl`, `build_probe_refusals()` (38), a new testset after
  the first, "a stage returning bare `(;)` is dead, whichever position
  (§5.2, §9.3)": `build(single(DeadStateStage()))` fails as one `DeadStage`
  with `path(d) == "c"` and `d.stage == "output_state"`;
  `build(single(DeadDirectStage()))` likewise with `"output_direct"`. Assert
  `only(diagnostics(err))`: the refusal throws alone.
- `test/test_build.jl`, `build_port_type_refusals()` (668), after the
  handle-at-root block (~684), a new testset "a root input the synthesis
  chain cannot value is `MissingProbeValue`, collected (§9.3, D-051)":
  `build(Group((; c = Unsynthesized()); inputs = ("in" => "c/q",)))` fails;
  `only(diagnostics(err))` is a `MissingProbeValue` with `d.face === :in`,
  `d.declared === NoDefault{Float64}` and `path(d) == ""`. Then the remedy:
  `b = build(Group((; c = Synthesized()); inputs = ("in" => "c/q",)))`
  builds, and `b.nominal.layout.root_inputs` holds `(:in, WithProbe(0.0,
  1.0))`. Then collection: a two-root-input model with both faces typed
  `NoDefault{T}` (a second `Group` over two `Unsynthesized` children,
  `inputs = ("in1" => "a/q", "in2" => "b/q")`) fails once with two
  `MissingProbeValue`s, faces `{:in1, :in2}`.
- `test/test_bindings.jl`, the reads testset (190–199): on the existing
  `get_output("q", "y")` line assert `diag.candidates == Symbol[]` (unknown
  path); add `get_output("p", "nope")` → `reason === :unknown_cell` and
  `candidates == [:power, :y]` (`Plant`'s two ports, `fixtures.jl` 25); on
  the existing `get_face("nope")` line assert `candidates == [:y]`
  (`outfaced()`'s one exported face, line 8).
- `test/test_diagnostics.jl`: two occurrences in the kind list, in
  Appendix C's order: `MissingProbeValue(face = :in, declared = Float64)`
  before `ChildNameCollision(…)` (309), and `DeadStage(path = "a/b", stage
  = "output_state")` before `ConformanceFailure(…)` (345). The coverage
  check (~548–550) fails otherwise. In the rendering testset (561), one
  assertion each: `MissingProbeValue`'s message carries
  `"probe_value(::Type{"` and `"zero-argument constructor"`; `DeadStage`'s
  carries "`(;)`" and the stage name; a `ReadBindingUnresolved` with
  `reason = :unknown_cell` and `candidates = [:power, :y]` renders
  `"{power, y}"`.

`test/imports.jl`: add `DeadStage` and `MissingProbeValue` to the kind list
at their alphabetical places (`DeadStage` after `CursorFrame` on line 13,
`MissingProbeValue` after `MissingInit` on line 21).

### Register edits, in the same commit

- `docs/design/pending.md`: delete the first "Not yet built" bullet
  (21–24).
- `docs/design/implementation.md`: the `src/build.jl` row (25) gains "the
  dead-stage rule at both stage probes and `MissingProbeValue` in
  `cell_layout` (§9.3)" after "the probe and the event probe"; the
  `src/bindings.jl` row (34) gains "the candidates on the two name-shaped
  read misses (§14.4)" at its end. Add "D-051" to the `build.jl` row's spec
  column. `src/diagnostics.jl` (20) needs nothing (kinds are not enumerated
  there).
- Run `julia docs/design/tools/check_refs.jl` and `check_rows.jl` after
  editing either register: both must print `OK`.

## Verification

- The routed subset green under the sandbox flags at the commit.
- `rg -n "Three specified checks" docs/design/pending.md` returns nothing.
- `rg -n "DeadStage\(" src/` lists the struct's docstring line and exactly
  two construction sites, both in `build.jl`; `rg -n "MissingProbeValue\("
  src/` lists one construction site, in `cell_layout`.
- In a `julia --project=test -L test/repl.jl` session, the four fixture
  builds above fail as their kinds, and the `Synthesized` build returns.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the REPL check above;
any test you could not write as specified and why, with file:line; any
place the spec, the cited rows and this brief disagreed; the assertion
totals; friction with this brief, especially any line number that had
drifted.
