# Increment 26 — replace `BuildError` with the policy-parametric `DiagnosticError` carrier

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `98a2374`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** This is a conformance increment. The design change already
landed docs-first at `98a2374` as D-221 (the species rule) and D-222 (the
carrier). The code owes the spec exactly what those two entries say, and
nothing else. One stage, one commit.

**Read, all in `docs/design/spec.md`:** §13.2 from its heading to the end of
the carrier sketch (6991–7042) — the carrier's definition and the type
parameter's meaning; §13.4 "How handled" through the species-rule paragraph
(7234–7270); Appendix C's *raised* and *policy* preamble (10165–10200); the
D.9 glossary entries *carrier exception* and *species* (11148–11191). In
`docs/design/decisions.md`: D-221 and D-222 in full (7862–7939) — D-222 is
the ruling this increment implements; its Position is the shape, its
Rejected list is what you must not build instead.

**Routed reading in `docs/design/implementation.md`** — do not read the whole
file:

- "Running the suite" (108–140).
- The file-table rows for `src/diagnostics.jl` (20) and `src/sim.jl` (27).
  Every other `src/` file is touched by a one-word swap only and needs no row.
- **"Authoring caveats" in full (58–107)** — always. The third bullet (the
  suite's `import Cadence:` list) bites this increment directly.

**Stance: conservative reading.** Build what the tables below say. Where the
spec and this brief disagree, stop and say so in the report rather than
improvising. Where a test's conversion is ambiguous between the two accessors,
the rule in "Tests" below decides; where it does not, the suite does — a
`MethodError` on an accessor is the test telling you which policy the throw
has.

**The design documents and the implementation are peers, neither subservient
to the other.** The spec is written before the code, not instead of it, and
the two are kept mutually consistent. A deviation that improves the design is
raised in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository root
(the first run after an `src/` edit pays a ~15 s precompile). While
iterating, `julia --project=test test/runtests.jl diagnostics failures` runs
those files alone; this change reaches every file, so gate the commit on the
full suite and then on `julia --project=. -e 'using Pkg; Pkg.test()'`. Commit
subject: one sentence, no body, no attribution. Do not push.

---

## The problem

`BuildError` is the one exception diagnostics travel in when thrown. It is
thrown at three kinds of site: a stratum barrier with the whole violation
list, a stopped-sim service refusing a call with one diagnostic, and a
runtime check inside the frame with one diagnostic. Two of the three are not
build failures, so the name claims a tier the job does not have. The carrier
also erases the reporting policy at the throw, so two functions re-derive it
from the vector's length: `_species` at the frame loop's catch site
(`src/sim.jl:1082`) and the carrier's `showerror` (`src/diagnostics.jl:90`).

D-222 replaces it with `DiagnosticError{P}`, where `P` is the diagnostic's
kind for a fail-fast throw and `Vector{Diagnostic}` for a collected one. The
policy is then in the type, every branch that read a count becomes a method,
and a test can assert policy and kind together as
`@test_throws DiagnosticError{Kind}`.

## The design core

Replace the carrier block in `src/diagnostics.jl` (lines 62–100: the
docstring, the struct, the two constructors, `kinds`, `_groups`, `showerror`)
with:

```julia
"""
The one carrier: a fail-fast site throws it holding a single diagnostic, a
stratum barrier holding the whole collection its passes returned (§13.1). The
type parameter is the policy (§13.2, D-222): the diagnostic's kind for a
fail-fast throw, `Vector{Diagnostic}` for a collected one. Rendering, `kinds`
and the catch site's species rule dispatch on it.
"""
struct DiagnosticError{P <: Union{Diagnostic, Vector{Diagnostic}}} <: Exception
    carried::P
end

DiagnosticError(d::Diagnostic) = DiagnosticError{typeof(d)}(d)
DiagnosticError(ds::AbstractVector{<:Diagnostic}) =
    DiagnosticError{Vector{Diagnostic}}(Vector{Diagnostic}(ds))

"The one diagnostic a fail-fast throw carries."
diagnostic(e::DiagnosticError{<:Diagnostic}) = e.carried

"The collection a barrier's throw carries."
diagnostics(e::DiagnosticError{Vector{Diagnostic}}) = e.carried

"The kinds present in a collection, in first-appearance order — what a test asks first."
kinds(e::DiagnosticError{Vector{Diagnostic}}) = unique(typeof.(e.carried))
```

`_groups` stays as it is. `showerror` becomes two methods, one per policy,
with the rendered prefix `DiagnosticError:` in place of `BuildError:`:

```julia
Base.showerror(io::IO, e::DiagnosticError{<:Diagnostic}) =
    print(io, "DiagnosticError: ", nameof(typeof(e.carried)), ": ", message(e.carried))

function Base.showerror(io::IO, e::DiagnosticError{Vector{Diagnostic}})
    ds = e.carried
    print(io, "DiagnosticError: ", length(ds), " diagnostics")
    for g in _groups(ds), d in g
        print(io, "\n  ", nameof(typeof(d)), ": ", message(d))
    end
end
```

Each accessor is defined on one parameter only. That is deliberate (D-222):
`diagnostics` on a fail-fast throw, or `diagnostic` on a collection, is a
`MethodError`, which is how a test states which policy a throw has. Do not
add a fallback method to either.

The species rule at the catch site (`src/sim.jl:1077–1082`) becomes one
method, and the comment above it drops the cardinality wording:

```julia
# The species rule (§13.4, D-221): a fail-fast carrier thrown inside the
# sequence arrives as its diagnostic unwrapped — which is what lets a runtime
# check (§9.5's conformance failure, the nonfinite sweep) be a plain thrower
# of its kind while the catch site stays the only wrap. A collected carrier has
# no single kind and rides as the cause it is.
_species(err) = err
_species(err::DiagnosticError{<:Diagnostic}) = err.carried
```

## Code edits (`src/`)

- **`src/diagnostics.jl`.** The carrier block as above. Then the prose that
  names the old mechanism: the `StepError` docstring ("`BuildError`'s
  counterpart", ~143–147) and the `NonfiniteState` docstring ("Thrown as a
  `BuildError` holding it alone", ~194–199) say `DiagnosticError` and drop
  "holding it alone" — the fail-fast constructor already says it.
- **`src/sim.jl`.** `_species` as above. The comment at the nonfinite throw
  (509–510, "Thrown as a lone-diagnostic `BuildError`, which the catch site's
  species rule unwraps") becomes "Thrown as a fail-fast `DiagnosticError`,
  which the catch site's species rule unwraps". The `_wrap_step` comment
  (1063–1066) is unchanged in substance; sweep the name if it appears.
- **Every other `throw(BuildError(` in `src/`** becomes
  `throw(DiagnosticError(`. This is a pure textual rename: the outer
  constructors pick the parameter from the argument, a kind constructor call
  giving the fail-fast carrier and a vector the collected one. No site's
  argument changes. The `isempty(…) ||` guards before the collected throws
  stay: an empty collection is never thrown.
- After the sweep, `grep -rn BuildError src/` is empty, and
  `grep -n "length(.*diagnostics)" src/` is empty.

For orientation, the collected throw sites — the ones whose argument is a
vector — are: `bindings.jl:67`; `assembly.jl:156, 658`; `build.jl:96, 166,
298, 416, 536, 552, 573, 689, 774`; `conditions.jl:475`; `readers.jl:227`;
`sim.jl:159, 223, 649, 651, 1234`; `trim.jl:233`. Every other carrier throw
is fail-fast. This list is for the test conversion below; the `src/` edit
does not need it.

## Tests

- **`test/CadenceTests.jl`.** In the `import Cadence:` list, `BuildError`
  becomes `DiagnosticError`; add `diagnostic` and `diagnostics` (the list is
  alphabetical). `kinds` is already there.
- **`err isa BuildError`** becomes `err isa DiagnosticError` everywhere. The
  catch-all matches both policies, so this is a rename.
- **Accessor conversion.** Every `.diagnostics` access on a carrier changes
  by the policy of the throw the test provokes:
  - a fail-fast throw: `only(err.diagnostics)` becomes `diagnostic(err)`;
  - a collected throw: `err.diagnostics` becomes `diagnostics(err)`, so
    `only(err.diagnostics)` on a barrier that found one violation becomes
    `only(diagnostics(err))`, and `filter`, `any`, `length` and
    comprehensions over it take `diagnostics(err)`.

  The rule for deciding: find the `src/` throw the test reaches. `build(…)`,
  `Simulation(…)`'s keyword validation, `init!`'s uninitialized-inputs check,
  `attach!`'s claim check, `replay!`'s header checks, `compile_reads`, the
  condition register and the trim setup are collected (the list above); a
  constructor check, a lifecycle refusal, an argument check, a selector or
  binding refusal, `claims`/`reads` on an abstract binding, a shape drift and
  the nonfinite sweep are fail-fast. When unsure, convert to the reading the
  site suggests and let the suite's `MethodError` correct it; do not add
  fallbacks to make both accessors work.
- **`test/test_diagnostics.jl`, the rendering testset (~505–522).** The
  carrier is constructed directly there. The four-diagnostic case constructs
  `DiagnosticError(Diagnostic[…])` and expects the first line
  `"DiagnosticError: 4 diagnostics"`; the single case expects
  `"DiagnosticError: UnconnectedInput: " * message(…)`. Add, in the same
  testset, the shape D-222 fixes:
  - `DiagnosticError(d) isa DiagnosticError{typeof(d)}` for one kind, and
    `DiagnosticError([d]) isa DiagnosticError{Vector{Diagnostic}}` — the
    outer constructors choose the parameter;
  - `diagnostic(DiagnosticError(d)) === d` and
    `diagnostics(DiagnosticError([d])) == [d]`;
  - `@test_throws MethodError diagnostics(DiagnosticError(d))` and
    `@test_throws MethodError diagnostic(DiagnosticError([d]))`;
  - `@test_throws MethodError DiagnosticError{Int}(1)` — the parameter bound
    is closed. (If the error Julia raises for a violated bound is a
    `TypeError` rather than a `MethodError`, assert that one and say so in
    the report.)
- **`test/test_failures.jl`.** The species tests already assert
  `e.cause isa NonfiniteState`, which the rule keeps true; they need no
  change beyond the rename. Add one assertion where the nonfinite sweep is
  first exercised (~183): that the cause is the bare diagnostic and not a
  carrier, `!(e.cause isa DiagnosticError)`.
- **The kind-only sites take the new spelling.** Where a test asserts a
  fail-fast throw's kind and reads no payload field, write
  `@test_throws DiagnosticError{Kind} expr` in place of the `failure` call
  and the `isa`. The candidates, at the launch tip: `test_assembly.jl:466`,
  `test_build.jl:168`, `test_roster.jl:216–217`, `test_lifecycle.jl:49, 60,
  85`, and `test_assembly.jl:82` — check each against the policy rule above
  first, because a barrier throw (`test_assembly.jl:82` is `init!`'s
  collected check, `test_build.jl:168` a stratum barrier) carries no kind in
  its type and keeps the accessor form. Expect about six conversions. Every
  other site keeps the accessor form: a test that reads payload fields needs
  the diagnostic in hand, and `@test_throws` does not return it. Do not
  sweep further; a typed `failure` helper is a separate cleanup, not
  conformance.
- Nothing outside the rendering testset may `occursin` on a rendered
  carrier; if a test elsewhere matched `"BuildError:"` in a string, move the
  assertion or drop the prefix from the match and say which in the report.

## Register edits (`implementation.md`)

Row 20 (`src/diagnostics.jl`): "the `BuildError` carrier and its
compiler-style rendering" becomes "the `DiagnosticError` carrier, parametric
on policy, with `diagnostic`/`diagnostics`/`kinds` and its two renderings",
and the row's citation list gains D-222. Row 27 (`src/sim.jl`): "the frame
loop's one catch site with the species rule" stays; its citation list gains
D-221. No caveat changes. `pending.md` needs nothing: the species bullet
retired at `98a2374`, and no bullet there names the carrier.

## Verification

- `grep -rn BuildError src/ test/ docs/design/implementation.md` is empty.
  The design docs are not yours to sweep: `decisions.md` and the historical
  briefs keep the old name by the log's own style rule.
- `grep -rn "length(.*diagnostics)" src/` is empty.
- Full suite green in the foreground, then `Pkg.test()` green.
- The suite's assertion total does not drop: compare `grep -c '@test ' test/*.jl`
  totals before and after, allowing for the assertions this brief adds.
- `julia --project=@. docs/design/tools/check_refs.jl` and `check_rows.jl`
  still pass after the register edit (they read `implementation.md`).

## Report format

Under 400 words, in this order: the commit hash; the number of `src/` sites
swapped, split fail-fast / collected; the number of test accessor conversions,
and how many the suite corrected after your first reading; anything the spec
or this brief left ambiguous and how you resolved it; any test whose
conversion changed what it asserts, with the reason; friction — anything in
the brief that was wrong, missing or cost time.
