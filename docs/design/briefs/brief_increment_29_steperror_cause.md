# Increment 29 — parametrize `StepError` on its cause's type

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `436dda3`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A conformance increment. The design change landed docs-first
at `436dda3` as D-225. The code owes the spec exactly what that entry says,
and nothing else. One stage, one commit.

**Read, all in `docs/design/spec.md`:** §13.2's carrier passage (7019–7028)
for the build carrier's rule; §13.4 from the species rule through the new
sketch (7248–7281), the ruling's mechanism; Appendix C's `StepError` row
(10345); the D.9 glossary entries *carrier exception* (11207–11211) and
*species* (11249–11251). In `docs/design/decisions.md`: D-225 in full
(8008–8052) — its Position is the shape, its Rejected list is what you must
not build instead; D-221 and D-222 (7865–7942) for the species rule and the
build carrier it mirrors.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (108–140).
- The file-table rows for `src/diagnostics.jl` (20) and `src/sim.jl` (27).
- **"Authoring caveats" in full (58–107)** — always. The `import Cadence:`
  bullet does not bite here: `StepError` is already imported and no new
  name is exported.

In `docs/design/pending.md`, the deviation bullet **"`StepError` keeps
`cause::Any`"** (227–231) is the one this increment retires. Nothing else
in that file bears on the work.

**Stance: conservative reading.** Build what the tables below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** The spec is written before the code, not instead
of it, and the two are kept mutually consistent. A deviation that improves
the design is raised in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root (the first run after an `src/` edit pays a ~15 s precompile). While
iterating, `julia --project=test test/runtests.jl failures diagnostics
lifecycle trace` runs the files this change reaches. Gate the commit on the
full suite and then on `julia --project=. -e 'using Pkg; Pkg.test()'`.
Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show 436dda3:path`.

---

## The problem

`StepError` (`src/diagnostics.jl:155–161`) keeps `cause::Any`. Since D-222
the build carrier's type parameter is the diagnostic's kind, so a test
asserts policy and kind at once as `@test_throws DiagnosticError{Kind}`. The
runtime carrier did not follow, so a species is recognizable only by reading
the field, and every species site in the suite spells two conjuncts,
`e isa StepError && e.cause isa NonfiniteState`. D-225 puts the cause's type
in the parameter, bounded to a diagnostic or an exception, and extends
`diagnostic(e)` to the species.

## The design core

Replace the `StepError` docstring and struct (`src/diagnostics.jl:148–161`)
with:

```julia
"""
§13.4's runtime carrier, `DiagnosticError`'s counterpart: the cursor's frame, the
clock at the failure, the frame-entry boundary index — the replay pointer — and
the cause. The parameter is the cause's type (D-225): a diagnostic's kind for a
*species*, a `StepError` whose `cause` is a typed diagnostic, and the exception
model code threw otherwise. The species is what lets a runtime check throw its
kind and reach the one catch site as a plain thrower.
"""
struct StepError{C <: Union{Diagnostic, Exception}} <: Exception
    frame::CursorFrame
    t::Float64       # `_seconds(clock.t)` at the catch: the boundary time in a boundary
                     # phase, the stage or trial time mid-integration
    boundary::Int    # the frame-entry boundary index: replay!(…; to_boundary = boundary)
    cause::C
end

# The species' payload, read as a fail-fast `DiagnosticError`'s is (D-225).
diagnostic(e::StepError{<:Diagnostic}) = e.cause
```

The default constructor infers `C` from the cause, so the one constructor
call at the catch site, `StepError(frame, _seconds(…), entry, _species(err))`
in `src/sim.jl:1085`, is unchanged, and so are `_species` and
`_host_boundary_zero!`. A collected carrier riding as `cause` is a
`DiagnosticError{Vector{Diagnostic}}`, an `Exception`, and falls under that
arm. Do not add a constructor, a fallback method or a branch for a bare
non-exception cause: D-225 accepts that the constructor fails with a
`TypeError` in that case and does not handle it.

`Base.showerror(io, e::StepError)` (`src/diagnostics.jl:184`) matches the
`UnionAll` and stays as it is, its `e.cause isa Diagnostic` branch included.
Do not split it into methods.

## Code edits (`src/`)

- **`src/diagnostics.jl`.** The block above. The one-line docstring on
  `diagnostic` (78) gains the species:

  ```julia
  "The one diagnostic a fail-fast throw, or a `StepError` species, carries."
  ```

  Keep the new method next to the struct, after it, since `StepError` is
  defined below `diagnostic`.
- **`src/sim.jl`.** No code change. Read the `_wrap_step` comment
  (1072–1077) and the `_species` comment (1088–1092); if either says
  anything the parametrization falsifies, amend that sentence only. I read
  them as still true.
- Nothing else in `src/` names the field's type.

## Tests

The rule: the conjunct pair `x isa StepError && x.cause isa K` becomes the
one conjunct `x isa StepError{K}`, species and raw causes alike; every other
conjunct stays in place. `failure` stays at every site that goes on to read
the frame, the time or the pointer off the error. A site that asserts only
the wrap and names no cause (`@test_throws StepError run!(sim)`,
`e isa StepError` alone) is unchanged.

The sites, at the tip:

- `test/test_failures.jl`: 51, 61, 102, 119, 134, 144, 150 and 225 (raw
  causes, `Detonated`/`Tripped`); 235, 247 and 267 (the species,
  `NonfiniteState`). Line 236, `@test !(en.cause isa DiagnosticError)`,
  stays: it still states the unwrap.
- `test/test_lifecycle.jl` 224, 229, 257 and `test/test_trace.jl` 693, 827
  name no cause and stay.
- The two direct constructions at `test/test_failures.jl:206` and `214`
  keep their spelling; the parameter is inferred.

Two additions, both in `test/test_failures.jl`:

- At the first species site (~235, the `dv` simulation), after the existing
  assertions, one line stating the accessor:
  `@test diagnostic(en) === en.cause`.
- In the rendering testset beside the direct constructions (~206–215), the
  bound, pinned as the type-level fact it is:
  `@test_throws TypeError StepError(CursorFrame(nothing, :none, :drain, 0), 0.3, 3, "oops")`.
  The comment above it: `# D-225's bound: a bare value is no cause the
  carrier admits.`

The `carried` helper in `test/utils.jl` needs no change; with the accessor
extended it works on a species too. Do not convert any site to it: the
species sites all read the frame or the time as well, and `carried` hands
back the payload only.

## Register edits

- `docs/design/implementation.md`, the `src/diagnostics.jl` row (20): in
  "§13.4's runtime trio — `CursorFrame`, `StepError` and `NonfiniteState`",
  make it "`CursorFrame`, `StepError` (parametric on its cause, `diagnostic`
  defined on the species) and `NonfiniteState`", and append `D-225` to the
  row's citation column.
- `docs/design/pending.md`: delete the deviation bullet "`StepError` keeps
  `cause::Any`" (~229–233) and change the section intro's "All but the last
  three were found by the audit" (145) to "last two". Nothing else.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl` after the register
  edits; both must pass.

## Verification

- Full suite green in the foreground, then `Pkg.test()` green.
- `grep -n "cause isa" test/*.jl` shows no line that also reads
  `isa StepError &&`.
- `grep -n "cause::Any" src/` is empty.
- The suite's recorded assertion total rises by exactly two.

## Report format

Under 250 words: the commit hash; the sites converted, by file; any site
left and why, with file:line; whether either `sim.jl` comment needed a
change and what; the assertion totals before and after; friction with this
brief.
