# Data survey, slice E — services

| | |
| --- | --- |
| tip | `aa9162a` (the brief names `34f8a39`; `aa9162a` is the commit that added the brief, `src/` unchanged between them) |
| files | `src/readers.jl`, `src/conditions.jl`, `src/trim.jl` |
| structs surveyed | 29 (11 + 14 + 4), 75 fields |
| date | 2026-09-21 |

Method as the brief's: every field grepped as `\.name\b` over all of `src/`,
every struct as `Type(`/`Type{`, constructor sites counted as one writer per
field. The one runtime claim was checked in a REPL
(`julia --project=test`, fixtures loaded); the script is in the scratchpad,
not the repository.

## Findings

### `ConditionPlan.inputs`, its face slot, beside `ConditionPlan.faces` — duplicate
`src/conditions.jl:257` and `:258`. `inputs::Vector{Tuple{Symbol,Any,Any}}`, the
`Symbol` being the root face; `faces::Vector{Symbol}`. Writers: one,
`resolve_condition` (`conditions.jl:290–291`, the same `e.face` pushed into
both lists in the same loop iteration; `:307`, the constructor). Readers of
`faces`: `assert_total` (`conditions.jl:507`), called from `init!`
(`sim.jl:755`) and `trim!` (`trim.jl:407`). Readers of the face slot of
`inputs`: none in `src/`; `apply!` destructures it as `(_, addr, v)`
(`conditions.jl:534`). Read by tests only: `test/test_conditions.jl:83`
(`for (face, _, v) in p.inputs if face === f`).
Evidence: `rg '\.faces\b' src/` returns one `ConditionPlan` reader,
`conditions.jl:507`; `rg 'plan\.inputs' src/` returns `conditions.jl:534` with
the slot discarded. REPL: on `tri()`, `p.faces == first.(p.inputs)` is `true`;
a plan with every face slot replaced by `:bogus` and `faces` intact passes
`assert_total` and `apply!` unchanged (`u` reads back `1.0`); a plan with
`faces = Symbol[]` and `inputs` intact throws `UninitializedInputs`. So the
face slot has no reader in authored code and none at runtime, and `faces` is
exactly `first.(inputs)`.
Proposal: keep one. Either drop the `Symbol` from `inputs`, making it
`Vector{Tuple{Any,Any}}` like `xs`, with `resolve_condition:290` the one
writer to change and the test helper at `test_conditions.jl:83` the one
reader; or drop `faces` and have `assert_total:507` read
`Set(first(t) for t in plan.inputs)`, with `resolve_condition:285, 291, 307`
and the docstring at `:246` changing. The first keeps the docstring's
"`faces` is the plan's root-input coverage" true as written.
Spec: not rostered by name. §14.6 asks that "the resolved plan's root-input
coverage" be a plan-level fact compared before any write; either form keeps
that.

## Clean

One line per struct, field count in brackets, all fields with a reader in
`src/` and no second home found.

`src/readers.jl`
- `GetState` [3]: `path`, `field`, `i` read by `_spell`, `_read_component`, `_resolve_selector`, `bindings.jl:173–180`.
- `GetDeriv` [3]: same readers.
- `GetOutput` [3]: `path`, `name`, `i` read by `_spell`, `_resolve_selector`, `bindings.jl:175–180`.
- `GetInput` [1]: `face` read by `_spell`, `_resolve_selector`, `bindings.jl:184–188`.
- `GetFace` [1]: `name` read by `_spell`, `_resolve_selector`, `bindings.jl:192–199`.
- `Reads` [1]: `sels` read by `_resolve_reads`.
- `StateRead` [2]: `off`, `i` read by `_read`.
- `DerivRead` [2]: `off`, `i` read by `_read`.
- `StoreRead` [2]: `ci`, `i` read by `_read`.
- `CellRead` [2]: `addr`, `i` read by `_read`; `i` is `nothing` by type for the `GetInput`/`GetFace` entries, a zero-size field, not a smell.
- `Reader` [1]: `entries` read by `gather`.

`src/conditions.jl`
- `Fragment` [4]: `x`, `s`, `m`, `inputs` read by `_flat`.
- `Scoped` [2]: `prefix`, `node` read by `_flat`, `_scoped!`.
- `Combined` [1]: `nodes` read by `_flat`, `_scoped!`.
- `Override` [1]: `layers` read by `_flat`, `_scoped!`.
- `CEntry` [7]: `path`, `store`, `field`, `value`, `prov`, `face` read by `_key`, `_flat`, `_check_duplicates!`, `_resolve_entries`, `_cviol`, `_component`, `_root_input`; `pos` read by `compile_plan` only. `field` and `face` on an input entry are two facts, the authored face and the root input it resolves to, and `_key` needs the second while the diagnostics name the first.
- `ConditionPlan` [4]: `xs`, `stores` read by `apply!`; `inputs` and `faces` are the finding above.
- `Resolved` [4]: `e`, `dest` read by both `resolve_condition` and `compile_plan`; `v` by `resolve_condition` only, `L` by `compile_plan` only. See Questions.
- `Getter` [0].
- `Authored` [0].
- `XWrite` [2]: `authored`, `off` read by `_write!`.
- `InputWrite` [2]: `authored`, `addr` read by `_write!`.
- `StoreWrite` [3]: `ci`, `defaults`, `authored` read by `_write!`. `defaults` is a bake of the activation's declared store, which is what §14.4's allocation-free `apply!` is for; the activation is immutable, so the copy cannot drift.
- `Prefix` [1]: `expected` read by `_compare`. A deliberate copy of `Scoped.prefix` with an enforcer, the `===` sweep at every `apply!`.
- `SpecializedPlan` [4]: `xs`, `stores`, `inputs`, `prefixes` read by `apply!`.

`src/trim.jl`
- `TrimProblem` [7]: every field read by `_check_decisions!`, `_check_tolerances!`, `_check_reads!`, `trim!`, `_verdict!`. Spec-rostered, §14.7, "normative and closed".
- `TrimTag` [0].
- `TrimReport` [10]: written at the two constructor sites in `_verdict!` (`trim.jl:560`, `:584`); no reader in `src/`, the value being the caller's return. Spec-rostered, §14.8 "The report, not an exception". See Questions.
- `LevenbergMarquardt` [2]: `maxiter`, `λ₀` read by `solve`.

## Questions

- `TrimReport.converged` is `all(abs.(residuals) .≤ tolerances)` over two other fields of the same report, and `TrimReport.tolerances` is a copy of `TrimProblem.tolerances`. Both are derivable, and both are what §14.8 asks for by name: "the `converged` flag is the service's own box test" and "the solved-point residuals come with their tolerances". The report is an immutable artifact built at one site from one `r`/`tol` pair, so the agreement has an enforcer. I read this as the spec's choice, not a smell; raising it so the ruling is the user's.
- `Resolved.v` is `convert(L, e.value)`, so it is derivable from `Resolved.L` and `Resolved.e`. The conversion is itself the convertibility check `_resolve_entries` runs, and the struct lives only inside one resolution pass, with the dynamic walk reading `v` and the specialized one reading `L`. Compute-once on a transient, not a second home; noted for completeness.

## Coverage

All 29 structs in the three files were reached. None of them is a diagnostic kind; the `Trim*` and `Condition*` kinds live in `src/diagnostics.jl` and were not in scope. `test/` and `docs/` were read only to locate readers and citations.
