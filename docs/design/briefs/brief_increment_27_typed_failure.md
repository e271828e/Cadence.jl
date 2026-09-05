# Increment 27 — the typed throw idiom in the suite: `carried(@test_throws DiagnosticError{K} …)`

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `ac554e8`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A test-only cleanup following increment 26, which made the
carrier's type parameter the diagnostic's kind (D-222). No `src/` file
changes. No design document changes. One stage, one commit.

**Read:** `docs/design/decisions.md` D-222 (7902–7939) for what the type
parameter means. In `docs/design/implementation.md`, "Running the suite"
(108–140) and **"Authoring caveats" in full (58–107)**. Nothing else.

**Stance: mechanical.** Every conversion below is syntactic. Where a site
does not match a pattern, leave it and list it in the report. Do not
redesign tests, reorder assertions or change what a test asserts.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository root.
While iterating, name files: `julia --project=test test/runtests.jl
lifecycle conditions`. Gate the commit on the full suite and then on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push.

---

## The problem

A fail-fast throw is asserted in three lines today:

```julia
e = failure(() -> run!(sim))
diag = diagnostic(e)
@test e isa DiagnosticError && diag isa MissingInit && diag.op === :run! && diag.status === :built
```

Since D-222 the kind is in the carrier's type, so `@test_throws
DiagnosticError{MissingInit} run!(sim)` states the first two conjuncts as
one assertion with the right source line. What the site still needs is the
diagnostic in hand for the payload conjuncts. `Test.Pass`, which
`@test_throws` returns, keeps the thrown exception in its `value` field
(Julia 1.12.7, verified).

## The helper

Add to `test/utils.jl`, directly after `failure`:

```julia
# The diagnostic a passed `@test_throws DiagnosticError{K}` carried: `Test.Pass`
# keeps the throw in `value`. Defined on `Pass` alone, so a failed `@test_throws`
# — already recorded by the testset — stops the body at a `MethodError` rather
# than asserting fields of nothing.
carried(p::Test.Pass) = diagnostic(p.value)
```

`failure` stays: the collected throws, the `StepError` sites and the raw
exceptions still use it.

## The conversions

Every call of `diagnostic(…)` in `test/` marks a fail-fast site, because the
accessor is defined on the fail-fast carrier only. There are 92 at the tip.
Convert each that matches one of these shapes; `K` is the kind the site
asserts, `REST` the payload conjuncts, which stay exactly as written.

**Shape 1**, the captured error:

```julia
e = failure(() -> EXPR)
diag = diagnostic(e)
@test e isa DiagnosticError && diag isa K && REST
```
becomes
```julia
diag = carried(@test_throws DiagnosticError{K} EXPR)
@test REST
```

**Shape 2**, the inline capture:

```julia
d = diagnostic(failure(() -> EXPR))
@test d isa K && REST
```
becomes
```julia
d = carried(@test_throws DiagnosticError{K} EXPR)
@test REST
```

**Shape 3**, the one-line field read, where the kind is never named:

```julia
@test diagnostic(failure(() -> EXPR)).field === v
```
becomes two lines, with `K` found at the `src/` throw the call reaches:
```julia
d = carried(@test_throws DiagnosticError{K} EXPR)
@test d.field === v
```

Rules that apply across shapes:

- If `REST` is empty, the site is just `@test_throws DiagnosticError{K} EXPR`.
- Drop only the `e isa DiagnosticError` and `diag isa K` conjuncts. Every
  other conjunct stays, in order.
- Keep the variable name the site used (`diag`, `d`, `d2`, `dr`, …).
- `EXPR` is the closure body, verbatim. Keyword arguments stay inside it.
- A site that reads two throws where one is collected (`only(diagnostics(…))`)
  and one fail-fast converts the fail-fast half only.
- Comments beside a converted line move with it.

**Do not convert:**

- `test/test_roster.jl` ~213–218: the two throws are captured with an
  inline `try`/`catch` before a `wait(t)` and asserted after it, and the
  comment there says why. `@test_throws` would move the call past the join.
- `test/test_diagnostics.jl`: the accessor shape tests construct carriers
  directly and stay.
- Any `only(diagnostics(…))`, `kinds(…)`, `StepError` or raw-exception site.
- Any site whose shape you cannot match to the three above. List it.

After the sweep, `grep -n "diagnostic(" test/*.jl` shows only the roster
pair, the diagnostics shape tests, and the helper itself.

## Register edits (`implementation.md`)

If the file table has a row for `test/utils.jl`, add `carried` beside
`failure` in it. If it has none, add nothing.

## Verification

- Full suite green in the foreground, then `Pkg.test()` green.
- The suite's recorded assertion total does not drop: each conversion trades
  one `@test` with two `isa` conjuncts for one `@test_throws` plus one
  `@test`, so the total rises by about one per site; an empty-`REST` site
  trades one for one.
- `julia --project=@. docs/design/tools/check_refs.jl` still passes if you
  touched the register.

## Report format

Under 300 words: the commit hash; sites converted per shape; sites left and
why, each with file:line; the kinds you had to look up at a `src/` throw for
shape 3; the assertion totals before and after; friction with this brief.
