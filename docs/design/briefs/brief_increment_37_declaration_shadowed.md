# Increment 37 — the shadowing check: `DeclarationShadowed` (§8.1, Appendix C, D-117, D-220, D-246)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `0ed642f` plus the docs-first commit below. Never `cd` elsewhere
(`cd` is aliased to zoxide in the user's shell; use absolute paths).

**Standing.** After `using Cadence`, a bare `state_derivative(::Eng, …) = …`
in the author's module defines a new, unrelated `MyModule.state_derivative`.
No error, no warning, on Julia 1.12 and later. Every declaration read by the
build goes through `Cadence`'s own function objects (`_declares`,
`has_stage`), and Julia never dispatches across generic functions, so from
the framework's side the author's method does not exist. The build then
reports a modeling diagnostic far from the namespace mistake, or nothing at
all when the shadowed name is optional (`state_events`, `sample_times`, …).
§8.1 and D-246 rule the fix: a **fail-fast** kind, `DeclarationShadowed`,
raised by Stratum A's walk on every component **before its class is read**,
whenever the component's parent module binds a family name to something
other than the framework's function. **One stage, one commit**, after the
docs-first commit the coordinator lands; suite green, `Pkg.test()` green.

**Read, all in `docs/design/spec.md`:** §8.1's namespace subsection in full
(1780–1865): the trap (1795–1812), **the two mitigations (1813–1834, this
increment's contract, the message wording at 1817–1820)**, and the
local-scope sibling (1836–1865, read for the distinction only: it is D-164's
case, already built, and the check cannot reach it). §13.1's fail-fast
paragraph (search "fail-fast" from 7242). Appendix C's row (10809–10812)
and the two rows beside it (10802–10808, 10813–10815). In
`docs/design/decisions.md`: **D-246 (8908–8962)**, D-117 (3367–3400, with
its annotation), D-220's first Rationale paragraph (7805–7860, why the names
make the check decidable), D-229's second Position bullet (8214–8230, what a
structural failure is).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (112–146).
- The file-table rows for `src/diagnostics.jl` (20), `src/declare.jl` (21),
  `src/assembly.jl` (22), `test/fixtures.jl` (38), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–110)** — always. The second caveat
  (74–83) is this increment's mechanism. Fixtures live at top level; every
  framework name a test calls or extends is on `test/imports.jl`'s list; a
  type's printed form depends on the printing module, so payload fields
  naming a user type go through `_typename`.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–23) is
the one this increment retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, D-246 and this brief disagree, stop and say so in the report
rather than improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl declare
assembly build diagnostics` covers the files this change reaches; gate the
commit on the full suite and on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show <tip>:path`.

---

## The mechanism, verified

Checked on the installed Julia 1.13.0 with the real package before this
brief was written (the coordinator's probe, `shadow_probe.jl`):

```julia
M = parentmodule(typeof(c))
foreign(n) = isdefined(M, n) && getfield(M, n) !== getfield(Cadence, n)
```

- A bare definition after `using Cadence` reads as foreign.
- A proper `import Cadence: n` reads as not foreign (`isdefined` true,
  identical object).
- An untouched name is not defined (the family is unexported, D-117, so
  `using` brings none of it in).
- A definition in `Main` at the REPL behaves like one in a package module.
- `isdefined` does not resolve or perturb the binding: a name probed before
  a later bare definition still reads as foreign afterwards.
- A framework-owned type (`Group`) has `Cadence` as its parent module and
  can never read as foreign.

## The construct

### The family, in `src/declare.jl`

After the last stage generic (line 228, `function state_update end`), one
constant naming §8.1's import list in its order, seventeen names:

```julia
const DECLARATION_FAMILY = (:init_x, :init_s, :init_m, :init_workspace,
    :input_types, :output_types, :state_events, :output_state, :output_direct,
    :state_derivative, :state_update, :state_projection, :child_connections,
    :input_connections, :output_connections, :sample_times,
    :transparent_container)
```

and beside it

```julia
"""
The family names `c`'s parent module binds to something other than the
framework's function, in family order — the forgotten-import evidence of
§8.1 (D-246). Empty for a module that imported what it extends.
"""
function foreign_declarations(c)
    M = parentmodule(typeof(c))
    Symbol[n for n in DECLARATION_FAMILY
           if isdefined(M, n) && getfield(M, n) !== getfield(@__MODULE__, n)]
end
```

Every name in the constant must be a generic function `Cadence` defines
(all seventeen are, lines 22–228). Do not add a name the framework does not
own.

### The kind, in `src/diagnostics.jl`

Placed directly before `ClassUnreadable` (line 431), Appendix C's order:

```julia
"§8.1, D-246: a family name the component's module binds to a function of its own — the forgotten import."
Base.@kwdef struct DeclarationShadowed <: Diagnostic
    path::String
    mod::String                              # the parent module, `string(M)`
    names::Vector{Symbol}                    # the foreign names, family order
end
path(d::DeclarationShadowed) = d.path
```

Severity error (the default); no `severity` method. The message, in the
didactic style, on §8.1's wording (1817–1820), with the import line spelled
for exactly the foreign names:

```
`a/b`: its module `Main.MyModel` defines its own `state_derivative`, distinct
from `Cadence.state_derivative`; add `import Cadence: state_derivative` (§8.1)
```

With several names: "defines its own `init_x`, `output_types`, distinct from
`Cadence`'s; add `import Cadence: init_x, output_types` (§8.1)". Use
`_at_path` for the path (the root component reads "the root component") and
`_namelist` for the names. `mod` is `string(M)`: a module always prints
fully qualified, from any printing module, so no `_typename` detour applies.

### The check, in `src/assembly.jl`

One site. In `_walk!` (828–909), as the first statement, before
`classify(path, comp)`:

```julia
    foreign = foreign_declarations(comp)
    isempty(foreign) ||
        throw(DiagnosticError(DeclarationShadowed(path = path, mod = string(parentmodule(typeof(comp))),
                                                  names = foreign)))
```

with a comment stating why it is first and why it throws alone (D-246: a
shadowed module's declaration set cannot be trusted, and `ClassUnreadable`
would otherwise throw alone with a message that is false from the author's
chair). The root component is walked at path `""` and is checked like every
other. **No other `classify` call site changes**: `input_faces`,
`output_faces`, `resolve_source`, `resolve_dest` and `resolve_authored`
read back classes the walk already proved, and `classify` itself stays as
it is. `ClassUnreadable`, `StoreWithoutUpdate` and `TierUnreadable` gain no
field.

### Fixtures, in `test/fixtures.jl`

**The check reads the module, not the component.** Every component a
module defines reads the same foreign list, so four cases need four
modules, one bare name each; the coordinator's probe put them in one and
read the union four times. The fixture set's rule is that no declaration
lives in a local scope; a nested module at fixtures.jl's **top level** is
top level. Add, at the end of the file, one outer module holding four
inner ones. Each inner module does its own `using Cadence` (a `using` in
the outer module does not reach it) and imports nothing, so that a bare
definition inside it is exactly the author's mistake:

```julia
"""
The forgotten-import fixtures (§8.1, D-246), one module per case because
the check reads the module: every bare definition below lands on a function
of its own module, which is the mistake `DeclarationShadowed` names.
Qualified `Cadence.f(…)` definitions are the ones that reach the framework.
"""
module Shadowed

"Every declaration bare: the whole inventory shadowed."
module Inventory
using Cadence
struct Leaf <: Cadence.AbstractComponent end
init_x(::Leaf) = (q = 0.0,)
output_types(::Leaf, ::Type{T}) where {T <: Real} = (y = T,)
output_state(::Leaf, (; x)) = (y = x.q,)
state_derivative(::Leaf, (; x)) = (q = -x.q,)
end

"A sound leaf whose update alone is bare: would have read as `StoreWithoutUpdate`."
module Update
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 0.0,)
Cadence.output_types(::Leaf, ::Type{T}) where {T <: Real} = (y = T,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
state_derivative(::Leaf, (; x)) = (q = -x.q,)
end

"A sound leaf whose events alone are bare: builds today with no events."
module Events
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 1.0,)
Cadence.output_types(::Leaf, ::Type{T}) where {T <: Real} = (y = T,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
Cadence.state_derivative(::Leaf, (; x)) = (q = -x.q,)
state_events(::Leaf) = (;)
end

"A sound assembly whose rate declaration alone is bare: builds today on the parent's grid."
module Rates
using Cadence
struct Leaf <: Cadence.AbstractComponent end
Cadence.init_x(::Leaf) = (q = 1.0,)
Cadence.output_types(::Leaf, ::Type{T}) where {T <: Real} = (y = T,)
Cadence.output_state(::Leaf, (; x)) = (y = x.q,)
Cadence.state_derivative(::Leaf, (; x)) = (q = -x.q,)
struct Assembly <: Cadence.AbstractComponent
    kid::Leaf
end
Cadence.child_connections(::Assembly) = ()
sample_times(::Assembly) = (kid = Cadence.Relative(2),)
end

end
```

The shapes are the contract, not the exact text. The coordinator's probe
(one module, so read with the caveat above) confirmed at the baseline that
the `Events` and `Rates` shapes **build today** with no diagnostic, that
the `Inventory` shape throws `ClassUnreadable` and the `Update` shape
`StoreWithoutUpdate`, and that `string(parentmodule(T))` prints the fully
qualified module. Verify in a REPL before writing the tests that
`foreign_declarations` returns `[:init_x, :output_types, :output_state,
:state_derivative]`, `[:state_derivative]`, `[:state_events]` and
`[:sample_times]` for `Inventory.Leaf()`, `Update.Leaf()`, `Events.Leaf()`
and `Rates.Assembly(Rates.Leaf())`, in family order.

`test/imports.jl`: add `DeclarationShadowed` (kind list, alphabetical
place) and `foreign_declarations` (function list). The fixture modules are
reached as `Shadowed.Inventory.Leaf()` and so on from the tests, no import.

### Tests

The build tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset.

- `test/test_declare.jl`, a new testset "a foreign binding of a family name
  is the forgotten import (§8.1, D-246)": `foreign_declarations` on the four
  fixtures returns the lists above, in family order; on `Plant()` and on a
  `Group` it returns empty (the suite's own module imports the whole family;
  `Group`'s module is `Cadence`); on `Rates.Leaf()` it returns
  `[:sample_times]` too, the module being the unit.
- `test/test_assembly.jl`, in `assembly_class` (36–68) or a sibling testset:
  `build(Shadowed.Inventory.Leaf())` throws
  `DiagnosticError{DeclarationShadowed}` (fail-fast, so `carried`) with
  `path == ""`, `names == [:init_x, :output_types, :output_state,
  :state_derivative]`, `mod == string(Shadowed.Inventory)`;
  `build(single(Shadowed.Update.Leaf()))` throws the same kind, not
  `StoreWithoutUpdate`, at path `"c"` (`single` is `Group((; c = c))`,
  `test/utils.jl` 16); `Events.Leaf` likewise; `Rates.Assembly` at the root
  path, before its child is walked.
- `test/test_diagnostics.jl`: one occurrence in `diagnostics_kind_set`'s
  list (the coverage check at ~555 fails otherwise), and in the rendering
  testset (558) one assertion that the message carries the import line for
  a two-name payload: `occursin("import Cadence: init_x, output_types", m)`.

### Register edits, in the same commit

- `docs/design/pending.md`: delete the first "Not yet built" bullet (21–23).
- `docs/design/implementation.md`: the second authoring caveat's closing
  sentence (81–83) becomes: "The diagnostic that catches it is D-246's
  fail-fast `DeclarationShadowed`, raised by the walk before the class is
  read, off a foreign binding of a D-220 name in `parentmodule(typeof(c))`;
  the local-scope case above is the one it cannot reach;". The file-table
  rows: `src/declare.jl` (21) gains "the declaration family
  `DECLARATION_FAMILY` and `foreign_declarations`"; `src/assembly.jl` (22)
  gains "the shadowing check ahead of `classify` in the walk (D-246)";
  `src/diagnostics.jl` (20) needs nothing (kinds are not enumerated there);
  `test/fixtures.jl` (38) gains "the `Shadowed` module, the forgotten-import
  fixtures, importing nothing". Add "§8.1" and "D-246" to the spec column
  of the two changed source rows.
- Run `julia docs/design/tools/check_refs.jl` and `check_rows.jl` after
  editing either register: both must print `OK`.

## Verification

- Full suite green and `Pkg.test()` green at the commit.
- `rg -n "proposed and not designed|not yet built" docs/design/implementation.md`
  returns nothing.
- `rg -n "shadowing check" docs/design/pending.md` returns nothing.
- `rg -n "foreign_declarations" src/` lists the definition and one call
  site, in `_walk!`.
- `rg -n "^import\b|^using\b" test/fixtures.jl` shows the four inner
  modules' `using Cadence` lines and nothing else new: no `import Cadence:`
  inside any of them.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the REPL check of the
four fixtures' lists; any test
you could not write as specified and why, with file:line; any place the
spec, D-246 and this brief disagreed; the assertion totals; friction with
this brief, especially any line number that had drifted.
