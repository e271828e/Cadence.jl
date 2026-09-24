# Naming inventory of `test/`: the merge and the rulings

Tip `0c0a899`. Twenty-seven reports, one per test file, from the brief
`docs/design/briefs/brief_naming_test_inventory.md`, eight Sonnet agents in
parallel. This page merges their closing sections into the rulings the
sweep needs. The coordinator ruled alone on 2026-09-24 under the user's
delegation; each ruling states its reason so the user can overturn it.

| file | flagged | renames | collisions |
| --- | --- | --- | --- |
| build | 388 | 65 | 2 |
| fixtures | 338 | 2 | 0 |
| trace | 163 | 27 | 1 |
| assembly | 124 | 24 | 0 |
| discrete | 122 | 36 | 0 |
| failures | 87 | 37 | 0 |
| conditions | 81 | 30 | 2 |
| diagnostics | 74 | 26 | 1 |
| events | 70 | 9 | 0 |
| devices | 63 | 44 | 0 |
| trim | 56 | 25 | 0 |
| lifecycle | 46 | 34 | 0 |
| log | 46 | 15 | 0 |
| roster | 40 | 34 | 0 |
| bindings | 39 | 27 | 0 |
| readers | 39 | 19 | 3 |
| localization | 35 | 12 | 1 |
| stepper | 32 | 9 | 0 |
| leaves | 29 | 19 | 0 |
| utils | 15 | 2 | 0 |
| dataplane | 14 | 4 | 0 |
| continuous | 13 | 3 | 0 |
| executor | 13 | 5 | 0 |
| store | 12 | 5 | 0 |
| CadenceTests | 7 | 1 | 0 |
| show | 7 | 1 | 0 |
| declare | 4 | 4 | 0 |
| **total** | **2157** | **519** | **10** |

## 1. Rulings

Where a report and a ruling disagree, the ruling wins; the sweep's brief
lists the concrete rows each ruling overturns.

**T1. A build in a scope that calls `build`.** Rule 6's `build` exception
reads "where no scope holding one calls the function", and Julia enforces
it: `build = build(model)` makes `build` local to the whole scope, so the
call resolves to the unassigned local (`discrete.md` confirmed the
`UndefVarError`). *Ruled:* a local holding a build takes `build` only in a
scope with no bare `build(…)` call; otherwise a qualifier by the model it
builds (`tri_build`, `feedback_build`), never a number and never a
restructured call (`Cadence.build(…)`), which a rename does not make.
`discrete.md`'s five `build` proposals become qualified names; `build.md`'s
and `conditions.md`'s qualified names stand. `path` is the same.
*Amended after wave 1:* the shadow bites with a single call too, since the
assignment alone makes the name local for the whole scope; so a local
assigned from `build(…)` never takes `build`, only a parameter or a field
read (`deployment.build`) does. `build.md`'s nine bare-`build` rows took
qualifiers.

**T2. Spec letters are never borrowed.** `m` for a model, `t` for a `Task`
or a termination record, `s` for a simulation, a string or a snapshot, `d`
for a deployment, `h` for a header, `r` for a schedule row, `q` for a plan.
*Ruled:* a letter the spec reserves is bound to nothing else, glance or
not. `localization.md`'s five glance `m`s become `model` with the sixth;
`events.md`'s five likewise. A `Task` is `task`; a termination record is
`record`, since `termination` is the accessor and a collision.

**T3. The device contract's parameters.** Every fixture's `loop`, `init!`,
`shutdown!`, `unblock!` spells them `d`, `h`; the spec's own example
(§11.6) and `src/devices.jl` spell `dev`, `handle`, and `keep:api` means
the spec's spelling. *Ruled:* `dev`, `handle` in every contract method of
the suite, one-line methods included, since `d` is the diagnostic letter in
the same files and `h` the grid step.

**T4. A second diagnostic, a second exception.** *Ruled:* `lifecycle.md`'s
reading. A diagnostic bound, asserted and discarded before the next binds
reuses `d`; `d1`–`d4`, `diag`/`diag2`, `paths` (`trace.md`'s collision)
all collapse to `d`. A role name is needed only when two are alive
together (bound before either is asserted, or compared). The same for
`err`: `e`, `e2`, `en`, `ep` from `failure(() -> …)` are caught exceptions
and take `err`, sequentially; `nonfinite_err`-style roles only for two
alive together. `diag`, `diag2` in any file become `d` (the singular never
joins the roster: `LinearAlgebra.diag` is live in both `src/` and the
suite).

**T5. A condition value.** The brief's "fifteen `condition` locals" were
`TrimProblem`'s keyword arguments, not locals: erratum, no collision, and
likewise the six `reads`. The real question is `log.md`'s: what a local
holding a condition is called when `condition` is the imported function.
`cond` cannot join the roster: `LinearAlgebra.cond` is live, the `diag`
objection exactly. *Ruled:* by role, `authored` for a condition the test
wrote, `captured` for one `capture` returned (`trim.md`'s spelling,
`readers.md`'s `c` takes it), `plan` only for a resolved `ConditionPlan`
(`conditions.md`'s line 225). `test_assembly.jl`'s existing `cond` renames
with the rest.

**T6. `ref`.** Six sites across five files. *Ruled:* not a roster entry;
the comparison simulation is `reference`, the role word `trace.md` already
uses, and `r` stays the spec's reference-signal symbol untouched.

**T7. Role suffixes.** *Ruled:* a role is a word. `sim2` stands as the one
ordinal idiom; `simh`/`siml`/`simr`/`simf` take full words (`heun_sim`,
…); `err_a`/`err_d` take `attach_err`/`detach_err`; `motor_sim`,
`dev_a`/`handle_a` (a pair named by the fixtures' own strings) stand;
`b1`–`b4` batches are `batch1`–`batch4`, ordinal like `sim2`.

**T8. The one-glance clause.** *Ruled:* `bindings.md`'s reading. A binding
read once but nine lines and several statements later is not a glance;
one read on the next line is. `utils.md`'s `failure(f)` and
`CadenceTests.md`'s do-block `s` keep; `leaves.md`'s `roundtrip` `v`/`n`
keep at the boundary.

**T9. Destructured field names.** `(; acc) = state(…)` binds the field's
own name by syntax. *Ruled:* out of reach, like a parameter mirroring a
field; `conditions.md`'s `roster?` row for `acc` is withdrawn.

**T10. Spec symbols the reports asked about.** `A`, `B` are §14.10's
linearization matrices: keep, with `Ad`, `Bd`. `N` as a step count is not
a type parameter: `n_steps`. `s_next` fuses to `snext` beside the rules'
`xnext`; `tprev` keeps by the same parallel. `L` for the hyperperiod is
`hyperperiod`. A real word is not an abbreviation: `no` beside `yes` keeps.

**T11. `whatif`.** Not flagged by the brief's three tests, but the
underscore rule reaches it: `what_if`, in the trace commit.

**T12. Matched pairs.** Two values of one type coexisting are both named
by role: `conditions.md`'s `p`/`q` pair at line 224 becomes
`direct_plan`/`nested_plan` (or the roles the testset's title gives), and
`trace.md`'s `a`/`b` in `same_trajectory` becomes `candidate`/`reference`.
`readers.md`'s `(a, b_, c, d)` destructure mirrors the read set's own
labels and keeps.

**T13. The rest of the questions.** `ProjectOnDiscrete`'s `s` becomes `x`
(rule 3; the tier is what the test exercises). `fb`/`cb` hold a diagnostic
and follow T4; `lw` is `loop_status` in both files. `mw`/`tw`/`dw`
consolidate to `writer`. `val` the helper becomes `value` (the function
bullet reaches test-local helpers). `ds` is `diags`; `sm` is `sum_ci`; the
undestructured bundle parameter is `bundle`. `veh` is `vehicle`; `sel` is
`kw`; `Pendulum(; c)` keeps as a field mirror. `f1`/`f2` in `leaves` take
the generated signature's `buffer1`/`buffer2`. `simd`/`sima`/`absm` take
underscored role names. `trim.md`'s bespoke `…_err`/`…_diag` pairs
collapse under T4 to sequential `err`/`d` where nothing is alive together.
`trim.jl`'s `d` carrying two settled meanings is rule 4's own text and no
finding.

## 2. Collisions

Ten rows: `paths` in `build`, `conditions`, `trace` (a `utils.jl` helper);
`loop` in `build` (the import list); `state` in `conditions` (a parameter
shadowing the accessor the file calls); `gated` in `localization` (a local
function over a `utils.jl` helper); `carried` in `diagnostics`; `diag` ×3
in `readers`. All rename as proposed, `paths` and `diag` to `d` under T4.

## 3. Brief errata

- `condition`, `reads`, `declarations`, `structure` were listed as locals
  shadowing imports from a count of `name = ` lines that were keyword
  arguments; no lowercase `structure` function is imported at all. T5.
- The classification table has no code for rule 6's `path`/`build`
  exception; `keep:spec` served, and the sweep needs none.
- The "`catch e`" line undercounted the caught-exception idiom, which in
  the suite is mostly `failure(() -> …)`; T4 covers both.
