# Increment 38 — the store-form check: `StoreNotNamedTuple` (§8.2, §9.1, Appendix C, D-247)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `d381a97` (the docs-first commit) plus the register commit that adds
this brief. Never `cd` elsewhere (`cd` is
aliased to zoxide in the user's shell; use absolute paths).

**Standing.** `init_x`, `init_s` and `init_m` declare a store by initial
value, and the value is a `NamedTuple`, one named field per leaf. Nothing
checks that form. Every reader of a store value assumes it: the tier
classifier (`isempty`), the two Stratum A field checks (`pairs`), `Decls`'
field types, the leaf walk and the bundle. A bare value therefore slips
through Stratum A and dies later, or does not die. Measured on Julia 1.13.0
before this brief was written, each on a leaf sound otherwise:

| declaration | today |
|---|---|
| `init_x(::C) = 1.0`, `= SVector(1.0, 2.0)` | `MethodError` converting to `NamedTuple` at `Decls` (Stratum C) |
| `init_x(::C) = (1.0, 2.0)` | `MethodError` inside the generated `reconstruct` (Stratum C) |
| `init_x(::C) = [1.0]` | **segfault** in the generated `reconstruct` |
| `init_s(::C) = 1` | `MethodError` at `Decls` |
| `init_s(::C) = (1, 2)` | `BoundsError` from `convert(NamedTuple, ::Tuple)` at `Decls` |
| `init_m(::C) = :a` | `MethodError` from `isempty(::Symbol)` in `classify_tier` (Stratum A) |
| `init_m(::C) = 1` | **builds silently**, an `Int` as the mode store |

§8.2 and D-247 rule the fix: a **collected** Stratum A kind,
`StoreNotNamedTuple`, checked on every primitive **before the classifier and
the two field checks read the value**; a primitive that fails it records
`nothing` for its tier and is read no further in the stratum. **One stage,
one commit**, the routed subset green.

**Read, all in `docs/design/spec.md`:** §8.2's "State, modes, discrete
state" (1961–1985): the rule with its new sentences and the *Why*
(1963–1975). §9.1's Stratum A check list (2974–3010; the new bullet is
2999–3002). §13.1's collected rule (7263–7273). Appendix C's row
(10814–10817) and the two rows after it (10818–10820, 10889–10892). In
`docs/design/decisions.md`: **D-247 (8970–9030)**, D-231 (8309–8360, the
sibling field check), D-229's Position (8215–8235, the barrier the check
collects to).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (112–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/assembly.jl`
  (22), `src/build.jl` (25), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–110)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–23) is
the one this increment retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, D-247 and this brief disagree, stop and say so in the report
rather than improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

This change reaches `declare assembly build diagnostics leaves`. Run that
subset as "Running the suite" says, under the sandbox flags, and gate the
commit on it; the full suite is the reviewer's, once per increment. Commit
subject: one sentence, no body, no attribution. Do not push. Never stash,
reset or check out the working tree; a baseline is read with
`git show <tip>:path`.

---

## The construct

### The kind, in `src/diagnostics.jl`

Placed directly before `IllegalStateLeaf` (line 691), Appendix C's order:

```julia
"§8.2, D-247: a store declaration returning something other than a `NamedTuple`, the one admitted form."
Base.@kwdef struct StoreNotNamedTuple <: Diagnostic
    path::String
    store::Symbol                            # :init_x | :init_s | :init_m
    declared::Any                            # the observed type
end
path(d::StoreNotNamedTuple) = d.path
```

Severity error (the default); no `severity` method. The message, in the
didactic style, spells the wrap for the store at fault:

```
`a/b`: `init_x` returns a `Float64`, not a NamedTuple — a store is declared by
initial value as named fields, one leaf per field, `init_x(::C) = (; ω = 0.0)`
(§8.2)
```

The wrap is `init_x(::C) = (; ω = 0.0)`, `init_s(::C) = (; n = 0)` and
`init_m(::C) = (; phase = :idle)` for the three stores. Use `_at_path` for
the path (the root component reads "the root component"). Interpolate
`d.declared` directly, as `IllegalStateLeaf` and `IllegalStoreField` do
(`_typename` would print `Vector{Float64}` as `Array`).

### The check, in `src/build.jl`

Beside `check_stores` (line 72), before it:

```julia
# §8.2, D-247: every by-value store is a `NamedTuple`, and the classifier and
# the two field checks below read it as one. Returns whether this primitive
# can be read further; the fallbacks return `NamedTuple()` and pass.
function check_store_form(path::String, c, diags::Vector{Diagnostic})
    ok = true
    for (name, fn) in ((:init_x, init_x), (:init_s, init_s), (:init_m, init_m))
        v = fn(c)
        v isa NamedTuple && continue
        push!(diags, StoreNotNamedTuple(path = path, store = name, declared = typeof(v)))
        ok = false
    end
    ok
end
```

One store's failure does not stop the loop: a component with two bare stores
names both (§13.1).

### The gate, in `src/assembly.jl`

In `_walk!`'s primitive branch (840–849), the classifier and the two field
checks run only on a primitive whose stores are readable. Today:

```julia
        t = classify_tier(path, comp, diags)
        push!(w.tiers, t)
        check_stores(path, comp, diags)
        check_state_leaves(path, comp, diags)
```

becomes

```julia
        if check_store_form(path, comp, diags)
            t = classify_tier(path, comp, diags)
            check_stores(path, comp, diags)
            check_state_leaves(path, comp, diags)
        else
            t = nothing                      # D-247: read no further
        end
        push!(w.tiers, t)
```

with the existing comment on the tier classification adjusted to say the
form check gates it. The root-faces block after it (`_check_root_faces` and
the claims) reads `input_types`, not the stores, and keeps running. Nothing
downstream of Stratum A changes: `build` (572) throws at the barrier on a
non-empty `diags`, so `Decls` never sees a bare value. `classify` and
`classify_tier` stay as they are. An empty `(;)` is the fallback's own value
and keeps reading as "declares nothing".

### Fixtures, in `test/test_build.jl`

Beside `LabelInStore`/`LabelInModes` (924–935), at top level, four leaves
sound otherwise, one per store plus the two notable rows of the table
above:

```julia
# A store that is not a `NamedTuple` (§8.2, D-247), one per store. `BareVector`
# is the value that segfaulted the generated `reconstruct` before the check;
# `BareModes` is the one that built silently. Each carries its update law and
# a vocabulary fault in another store, so the only finding is the form: the
# field checks do not read a primitive the form check refused.
struct BareState <: AbstractComponent end
init_x(::BareState) = zeros(SVector{3})
state_derivative(::BareState, (; x)) = zeros(SVector{3})

struct BareVector <: AbstractComponent end
init_x(::BareVector) = [1.0]
state_derivative(::BareVector, (; x)) = [0.0]

struct BareDiscrete <: AbstractComponent end
init_s(::BareDiscrete) = 0.0
output_types(::BareDiscrete) = (a = Float64,)
output_state(::BareDiscrete, (; s)) = (a = s,)
state_update(::BareDiscrete, (; s)) = s

struct BareModes <: AbstractComponent end
init_x(::BareModes) = (gear_count = 3,)      # `IllegalStateLeaf`, were it read
init_m(::BareModes) = 1
state_derivative(::BareModes, (; x)) = (gear_count = 0,)
```

Grep each name across `test/` first: a same-named type silently rebinds a
fixture module on 1.13. The shapes are the contract, not the exact text.

`test/imports.jl`: add `StoreNotNamedTuple` to the kind list (alphabetical
place, beside `StoreWithoutUpdate` on line 29). `check_store_form` is
reached through `build` and needs no import.

### Tests

The build tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset.

- `test/test_build.jl`, a new function `build_store_form()` after
  `build_store_values` (974–984), called from `test_build()` right after
  `build_store_values()` (1119), testset "a store declaration is a
  NamedTuple, checked before the stores are read (§8.2, §9.1, D-247)":
  `build(Group((; a = BareState(), b = BareVector(), c = BareDiscrete(),
  d = BareModes())))` fails once; every diagnostic is a
  `StoreNotNamedTuple`; `Set((d.path, d.store, d.declared) for d in ds)` is
  `{("a", :init_x, SVector{3,Float64}), ("b", :init_x, Vector{Float64}),
  ("c", :init_s, Float64), ("d", :init_m, Int)}`. Assert the kind set is
  exactly `{StoreNotNamedTuple}`: `BareModes`' `gear_count` raises no
  `IllegalStateLeaf`, which is the "read no further" clause.
- `test/test_build.jl`, `merged_failures()` (919–921) gains a fifth child
  `f = BareState()`, and `build_stratum_a` (986–995) adds
  `StoreNotNamedTuple` to its expected kind set: the form check merges into
  the stratum's one throw beside the others (D-229).
- `test/test_diagnostics.jl`: one occurrence in `diagnostics_kind_set`'s
  list, before `IllegalStoreField` at 324 (the coverage check at 549 fails
  otherwise): `StoreNotNamedTuple(path = "a/b", store = :init_x, declared =
  Float64)`. In the rendering testset (560) one assertion that the message
  carries the wrap: `occursin("init_x(::C) = (; ω = 0.0)", m)` on a payload
  with `store = :init_x`.

### Register edits, in the same commit

- `docs/design/pending.md`: delete the first "Not yet built" bullet (21–23).
- `docs/design/implementation.md`: the `src/build.jl` row (25) gains "the
  store-form check `check_store_form` (§8.2, D-247)" before "the store isbits
  check"; the `src/assembly.jl` row (22) gains "the store-form gate ahead of
  the classifier in the walk (D-247)" after the shadowing-check clause. Add
  "D-247" to both rows' spec column. `src/diagnostics.jl` (20) needs nothing
  (kinds are not enumerated there).
- Run `julia docs/design/tools/check_refs.jl` and `check_rows.jl` after
  editing either register: both must print `OK`.

## Verification

- The routed subset green under the sandbox flags at the commit.
- `rg -n "declaration side of the bundle law" docs/design/pending.md`
  returns nothing.
- `rg -n "check_store_form" src/` lists the definition and one call site,
  in `_walk!`.
- The four fixtures, built one at a time under `single(...)`
  (`test/utils.jl` 16), each fail as `StoreNotNamedTuple` at path `"c"`, and
  the `BareVector` build returns instead of crashing the process.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the per-fixture check
above; any test you could not write as specified and why, with file:line;
any place the spec, D-247 and this brief disagreed; the assertion totals;
friction with this brief, especially any line number that had drifted.
