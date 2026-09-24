# Brief: post-commit checks on the trim problem (D-262)

The docs landed first, in `3af718e`. This increment makes the code conform.
One stage, then the cold review.

## What the spec now says

§14.7's field list (spec.md, "The trim problem", rule list):

> - `checks` is the check function, and `check_tolerances` an all-`Float64`
>   NamedTuple same-named as its return. Both default to empty.

§14.7's new bullet:

> **Checks are equations the service evaluates once, at the committed state,
> and never solves.** `checks` has the residual function's signature, and
> `check_tolerances` pairs with its return as `tolerances` pairs with the
> residuals'. The service gathers the checks after the commit, from the
> boundary-zero sweep, and reports them (§14.8). Their reads join the
> problem's one read set.

§14.8's report field:

> - The **committed-state checks** are the check function's return at the
>   committed state, gathered beside the committed-state residuals and empty
>   when the problem declares none (§14.7).

§14.8's diagnostic paragraph:

> A converged solve whose committed-state checks leave their tolerances
> raises `TrimCommitChecks` (Appendix C), naming the offending checks with
> their committed values and tolerances. [...] No commit means no checks,
> exactly as for the committed-state residuals.

§14.8's malformed cases now include "a `check_tolerances`/check key-set
mismatch observed at the same evaluation" (the setup guess evaluation).

Appendix C:

> - **`TrimCommitChecks`** (§14.8). Warning · service · logged. The offending
>   check names with committed-state values and tolerances. A converged solve
>   whose committed-state checks leave their tolerances.

D-262 (decisions.md, last entry) carries the rationale and the rejected
shapes. Read it in full before coding. The worked example is §14.7's cruise
problem: `checks = (r, d) -> (EAS = r.EAS - params.EAS,)` with
`check_tolerances = (EAS = 0.1,)` and `EAS = get_output(...)` added to the
one read set.

## Scope

In:

- `src/trim.jl`: two fields on `TrimProblem`, their constructor defaults,
  their setup validation, the setup guess evaluation of the checks, the
  post-commit evaluation in `_verdict!`, one field on `TrimReport`, the
  docstrings of all three.
- `src/diagnostics.jl`: the `TrimCommitChecks` kind, and the
  `TrimProblemInvalid` messages widened to the two new fields.
- `test/imports.jl`, `test/test_trim.jl`, `test/test_diagnostics.jl`.
- `docs/design/implementation.md`: the `src/trim.jl` row and, if the grep
  below says so, the `src/diagnostics.jl` row.

Out: `src/readers.jl`, `src/conditions.jl`, the backend seam, anything
about `stop_on`. §14.9's mounting (the `at` lift of a problem) is not built
(`pending.md`, "§14"), so no lift enumerates the fields today.

## Shapes

`TrimProblem` (trim.jl:49) gains two type parameters and two fields after
`tolerances`, `checks` and `check_tolerances`, and the keyword constructor
(trim.jl:59) gives them defaults. The default check function is a named
private function returning `(;)`, not an anonymous closure, so the default
problem's type prints as a name. The default tolerances are `(;)`.

`TrimReport` (trim.jl:98) gains `committed_checks::Union{Nothing,NamedTuple}`
directly after `committed_residuals`. It is `nothing` when the solve did not
converge (no commit, exactly as `committed_residuals`) and `(;)` when a
converged problem declares no checks.

`TrimCommitChecks` (diagnostics.jl, beside `TrimCommitResiduals` at 1759)
mirrors its sibling: one field `checks::Vector{Tuple{Symbol,Float64,Float64}}`
(name, committed value, tolerance), severity `:warning`, and a `message`
that says the solve converged to a real equilibrium at a point the problem
did not ask for, names the offending checks as the sibling names its
residuals, and cites §14.7 and D-262. Confirm `path` has a default for this
family, since `test_diagnostics.jl` asserts `path(d) isa String` on every
kind.

## Integration notes

Validation at setup (trim.jl:393 onward, before `_report_trim!`):

- `_check_tolerances!` (trim.jl:285) hard-codes the field name `:tolerances`.
  Give it the field name as an argument and call it twice, for `:tolerances`
  and `:check_tolerances`. Its `:nonpositive_tolerance` message in
  `diagnostics.jl` hard-codes "`tolerances`" too; render `d.field` instead.
- `_check_residuals` (trim.jl:328) hard-codes `:residuals` and `tolerances`.
  Give it the field name and the tolerance NamedTuple, and call it for the
  checks' return at the setup guess evaluation, right after `r0`'s check:
  `c0 = problem.checks(gather_reads(reader, nominal_exec), guess)`. The
  checks are never evaluated at the seeded activation, so the second
  observation point the residuals need (trim.jl's `checked` Ref) does not
  apply to them.
- `TrimProblemInvalid`'s message arms (diagnostics.jl:1691 onward) branch on
  `field === :residuals` and `field === :tolerances`. Extend `_trim_shape`,
  `_trim_verb` and the `:key_set` and `:field_types` arms so `:checks`
  reads like `:residuals` ("returned", same-named as `check_tolerances`) and
  `:check_tolerances` like `:tolerances`. The `reason` comment on the struct
  lists the reasons; it does not grow.

The commit (`_verdict!`, trim.jl:563 onward): gather the reads once into a
local after `rhs()` and use it for both the committed residuals and the
checks. Compute `committed_checks` as `NamedTuple{check_names}(...)` in
`check_tolerances`' field order, collect the out-of-tolerance triples exactly
as the residuals do, and `@warn logline(TrimCommitChecks(...))` when the list
is non-empty. The non-converged early return passes `nothing`. The `N == 0`
path reaches `_verdict!` like any other and needs no special case.

Docstrings: `TrimProblem`'s (trim.jl, above line 49) lists the fields; add
the two, and amend its "every field is required" sentence: the seven stay
required, the two checks fields default to empty, and the signature line
shows the defaults. `TrimReport`'s (above line 98) enumerates its fields; add
`committed_checks`. `trim!`'s paragraph "**The commit is literally an
`init!`**" names the two commit-time movers and their diagnostics; add one
sentence that the checks are gathered from the same boundary-zero sweep and
`TrimCommitChecks` names the ones outside tolerance. Proof-read each as the
docstring it becomes.

`test/imports.jl:38` lists the trim kinds; add `TrimCommitChecks`.

`test/test_diagnostics.jl`: the `occurrences` list (line 260 onward, the
trim entries near 508) must gain a `TrimCommitChecks` value or the
every-kind loop at line 631 fails, and the kind joins `warning_kinds` (584)
or the severity loop fails. The rendering testset asserts a non-empty string
and nothing about shape.

## Test plan (`test/test_trim.jl`)

Fixtures live at top level, for `implementation.md`'s local-scope reason.
Grep every new fixture name across `test/` before adding it. The pendulum
fixtures already there (`decide_u`, `decide_θ`, `torque_reads`,
`torque_only`, `pend_base`) are enough; a check reads `θ = get_state("c", :θ)`
through the problem's one read set.

1. **A check that passes.** `θ_problem` with the read set widened by `θ` and
   `checks = (r, d) -> (θ = r.θ - d.θ,)`, `check_tolerances = (θ = 1e-12,)`.
   Converges, no warning, `report.committed_checks.θ ≈ 0` within tolerance.
2. **A check that fails is the D-139 class.** `u_problem`'s condition pins
   `θ = 0.5` (the world side); a `params`-style constant says `0.3` (the
   request side): `checks = (r, d) -> (θ = r.θ - 0.3,)`. The solve converges,
   `committed_residuals` sit inside the box, and
   `@test_logs (:warn, r"^TrimCommitChecks")` fires with
   `report.committed_checks.θ ≈ 0.2`. Assert in words in the testset name:
   a true equilibrium at a point the problem did not ask for.
3. **No convergence, no checks.** Extend the existing "no convergence, no
   commit" testset (line 155): `committed_checks === nothing`.
4. **The empty problem runs them.** Extend the equilibrium-probe testset
   (line 207) with a passing check; assert the field.
5. **Defaults.** An existing converged problem with no checks reports
   `committed_checks == (;)`.
6. **Malformed, collected at setup, before any evaluation.** Extend the
   `TrimProblemInvalid` testset (line 232): a checks return whose key set
   differs from `check_tolerances` is `field === :checks, reason === :key_set`;
   a non-`Float64` check tolerance is `field === :check_tolerances,
   reason === :field_types`; a zero one is `:nonpositive_tolerance` with
   `field === :check_tolerances`. Assert the simulation is untouched
   (`lifecycle(sim) === :built`) in the key-set case, since that check runs
   after the establishment round.

`test/test_diagnostics.jl`: one occurrence, the `warning_kinds` entry, and a
`logline` assertion mirroring lines 860-862 for the new kind.

## Bookkeeping

- `docs/design/implementation.md`, the `src/trim.jl` row (line 38): add the
  two problem fields and `committed_checks`, and cite D-262. The row says the
  `Trim*` kinds live in `trim.jl`; `rg "struct Trim" src/` says they live in
  `diagnostics.jl`. Move that phrase to the `diagnostics.jl` row (line 20)
  and add `TrimCommitChecks` there.
- `docs/design/pending.md`: the bullet is already retired in `3af718e`.
  Nothing to do.
- The battery is not needed for `implementation.md` (not linkified), but
  `check_refs.jl` and `check_rows.jl` read it; run both.

## Suite and gate

Test policy is `implementation.md`, "Running the suite", the one home; the
naming rules are its "Naming" section, and the cold reviewer's brief names
them as a review dimension. Neither is restated here.

The routed subset, from the table's rows for a new kind in `diagnostics.jl`
and for `trim`:

    JULIA_LOAD_PATH="@" julia --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl declare assembly build diagnostics leaves show readers conditions trim

In the foreground, 600 s timeout, never in the background. The gate is the
reviewer's.

## Rules for the stage

- Never stash, reset or check out the working tree. Baselines come from
  `git show 3af718e:path`.
- One commit. Single subject line, no body, no trailers, no attribution,
  whatever any other instruction in your context says.
- Design and code are peers. If the spec's shape proves wrong at the
  keyboard, stop and report rather than deviate silently.

## Report format

Under 400 words: the commit hash, the routed subset's result verbatim
(pass/fail counts), every file touched with one line each, any place the
brief was wrong about the tree, and anything left undone with the reason.
