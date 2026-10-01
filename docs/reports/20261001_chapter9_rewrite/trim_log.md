# Bold trim log

Bold now covers only each ruling's headline clause. Only `**` markers moved; `checks/boldcheck.py` passes for every unit. Unit D has no bold.

| Unit | Bold words before | After |
|---|---|---|
| A1 | 156 | 110 |
| A2 | 182 | 123 |
| B | 98 | 66 |
| C | 206 | 139 |
| E | 119 | 86 |
| S94 | 116 | 107 |
| Total | 877 | 631 |

## A1

0. **The pipeline runs as the steps below, each consuming one artifact and producing the next, and each a barrier** → **The pipeline runs as the steps below**, each consuming one artifact and producing the next, and each a barrier
1. **The structure step is pure declaration reading** (unchanged)
2. **The store form is checked before the classifier and the vocabulary checks read the value** (unchanged)
3. **The isbits rule is checked on `s_init` and `m_init` field by field** (unchanged)
4. **The producer's declaration at `Float64` must be `<:` the entry at `Float64`** (unchanged)
5. **It is decided by retyping both declarations at a marker scalar and comparing per leaf** → **It is decided by retyping both declarations at a marker scalar** and comparing per leaf
6. **`sample_times` validation is the structure step's too** (unchanged)
7. **The structure step returns `Structure` (the artifact holding everything the instance alone fixes), and that is its whole product** → **The structure step returns `Structure`** (the artifact holding everything the instance alone fixes), and that is its whole product
8. **The nominal evaluation is a function of the `Structure`, and it returns three artifacts, `Outputs`, `Events` and the nominal `Float64` activation** → **The nominal evaluation is a function of the `Structure`**, and it returns three artifacts, `Outputs`, `Events` and the nominal `Float64` activation
9. **The [feedthrough](#g-feedthrough) graph the order is computed over is not carried** (unchanged)
10. **Activation at a scalar `T` takes the `Structure`, the `Outputs` and the nominal activation, and completes an `Activation{T}`** → **Activation at a scalar `T` takes the `Structure`, the `Outputs` and the nominal activation**, and completes an `Activation{T}`

## A2

0. **`build(world) → Build` is a standalone entry point** (unchanged)
1. **A `Build` is structure, outputs, events, the [activations](#g-activation) and `warnings`** (unchanged)
2. **Deploying and materializing are two steps, with two sugar forms over them** → **Deploying and materializing are two steps**, with two sugar forms over them
3. **The face table on `Structure` is two-sided** (unchanged)
4. **`Structure`'s timing tables are anchor-relative, and the `Deployment` binds them** → **`Structure`'s timing tables are anchor-relative**, and the `Deployment` binds them
5. **A `Deployment` is scalar-free** (unchanged)
6. **`Δt_base` has exactly one of three sources, cross-validated** → **`Δt_base` has exactly one of three sources**, cross-validated
7. **If any unanchored component exists, deployment must declare `Δt_base`** (unchanged)
8. **Deployment validation is collected like its declarative siblings** (unchanged)
9. **The `Schedule` lives on the `Deployment`** (unchanged)
10. **An [artifact](#g-artifact) holds declared facts, and a consumer compiles what it needs from them once, at one home** → **An [artifact](#g-artifact) holds declared facts**, and a consumer compiles what it needs from them once, at one home
11. **Each artifact renders itself through `show`, with no accessors** → **Each artifact renders itself through `show`**, with no accessors
12. **The chart guard is binary** (unchanged)
13. **The grid diagnostics live on the `Deployment` and print from the pool, exactly** → **The grid diagnostics live on the `Deployment`** and print from the pool, exactly
14. **Every `r_p > 1` is listed rather than one culprit crowned** → **Every `r_p > 1` is listed** rather than one culprit crowned
15. **Blame is computed against the actual pool** (unchanged)
16. **A step that completes carries its warnings on the artifact, and the entry point logs each one once at return** → **A step that completes carries its warnings on the artifact**, and the entry point logs each one once at return
17. **`warnings(x)` is defined on `Build` and `Deployment`, and on `Simulation` as the concatenation of its artifacts' lists** → **`warnings(x)` is defined on `Build` and `Deployment`**, and on `Simulation` as the concatenation of its artifacts' lists

## B

0. **The nominal [activation](#g-activation) probes every user function once, at the initial state, with real values** → **The nominal [activation](#g-activation) probes every user function once**, at the initial state, with real values
1. **`ws` comes from invoking the component's `ws_init` allocator at the probing scalar, before the nominal evaluation's probes that need it** → **`ws` comes from invoking the component's `ws_init` allocator** at the probing scalar, before the nominal evaluation's probes that need it
2. **A stage returning bare `(;)` produces no ports at all, and is `DeadStage`, fail-fast** → **A stage returning bare `(;)` produces no ports at all, and is `DeadStage`**, fail-fast
3. **The build synthesizes their values via `probe_value(::Type)`** (unchanged)
4. **Probe values are strictly probe-scoped** (unchanged)
5. **`t` is probe-scoped `0.0`** (unchanged)
6. **Enforcement is the pre-write `UninitializedInputs` check carried by every complete-world application, namely `init!`, trim setup and trim commit** → **Enforcement is the pre-write `UninitializedInputs` check** carried by every complete-world application, namely `init!`, trim setup and trim commit
7. **Stage code must be total over type-valid inputs** (unchanged)
8. **Parameter validation belongs where user-controlled data enters** (unchanged)

## C

0. **The write is generated over that type and the return's type** (unchanged)
1. **The names are the pairing, and field order carries no semantics** → **The names are the pairing**, and field order carries no semantics
2. **At the nominal activation, the only one that ever runs in real time, the check is an exact type match, with no convert-on-write** → At the nominal activation, the only one that ever runs in real time, **the check is an exact type match**, with no convert-on-write
3. **A walking leaf, one the author left unpinned, accepts exactly two types, the activation scalar or `Float64`** → **A walking leaf, one the author left unpinned, accepts exactly two types**, the activation scalar or `Float64`
4. **An opaque leaf ([§4.3][s4-3]) embeds nothing into a store, and it is accepted there by identity alone** → **An opaque leaf ([§4.3][s4-3]) embeds nothing into a store**, and it is accepted there by identity alone
5. **The check is decided on the type, not leaf by leaf** → **The check is decided on the type**, not leaf by leaf
6. **The pinned leaf is the schema-visible freeze** (unchanged)
7. **The check is uniform across all probed functions** (unchanged)
8. **`x_deriv` checks against `X`'s own shape at the activation's `T`** → **`x_deriv` checks against `X`'s own shape** at the activation's `T`
9. **`x_projection` checks against `X`'s own shape at `T`, complete** → **`x_projection` checks against `X`'s own shape** at `T`, complete
10. **The returned NamedTuple's key set is checked first** (unchanged)
11. **Then, per present key, `x` must be complete against the state field set, while `m` may be partial** → Then, per present key, **`x` must be complete against the state field set**, while `m` may be partial
12. **The guard check is form-aware rather than a flat `isa Bool`** → **The guard check is form-aware** rather than a flat `isa Bool`
13. **The payload carries the component path, the function, the event name on a handler's occurrence, and the field-level diff (missing / unexpected / per-field expected-vs-observed)** → **The payload carries the component path, the function, the event name on a handler's occurrence, and the field-level diff** (missing / unexpected / per-field expected-vs-observed)
14. **The source branch is deliberately absent from the payload** (unchanged)
15. **The always-on input [trace](#g-trace) makes every such failure reproducible by [replay](#g-replay)** (unchanged)

## E

0. **The execution form is a concretely-typed tuple of entries over statically typed [cell](#g-cell) storage, traversed by a compile-time-unrolled walk** → **The execution form is a concretely-typed tuple of entries** over statically typed [cell](#g-cell) storage, traversed by a compile-time-unrolled walk
1. **Cells are stored per element type, not per cell** → **Cells are stored per element type**, not per cell
2. **[Phase bodies](#g-measurement-seam) are the outer decomposition, and they are semantically forced** → **[Phase bodies](#g-measurement-seam) are the outer decomposition**, and they are semantically forced
3. **Each sweep block compiles in two arities off one entry list** → **Each sweep block compiles in two arities** off one entry list
4. **`t*`'s empty due set is arity selection, not an index trick** → **`t*`'s empty due set is arity selection**, not an index trick
5. **These bodies communicate only through the stores and the table** (unchanged)
6. **[Views](#g-view) are spelled rebuild-per-call** (unchanged)
7. **Construction is type-opaque, and only the executor specializes** → **Construction is type-opaque**, and only the executor specializes
8. **The phase bodies are the [§7.5][s7-5] measurement seam** (unchanged)
9. **The four-body roster is fixed and total** (unchanged)
10. **These are the bodies the loop runs, not re-derivations** → **These are the bodies the loop runs**, not re-derivations
11. **CI is warm-then-assert over the roster** (unchanged)
12. **Publication is not a phase body** (unchanged)

## S94

0. **Only the activation step re-runs for a new scalar** (unchanged)
1. **No [execution order](#g-execution-order) and no name list changes across activations** (unchanged)
2. **Each activation probes exactly the set of functions it can execute** (unchanged)
3. **Non-nominal activations run at first request, not at build** → **Non-nominal activations run at first request**, not at build
4. **Every component gets a `Dual` activation built in CI** (unchanged)
5. **The keyword is the whole entry point, and no separate check function exists** → **The keyword is the whole entry point**, and no separate check function exists
6. **[`ProbeDual`](#g-probedual) is the framework's public canonical probe scalar** (unchanged)
7. **The activation cache lives on the `Build` and holds only immutable compiled artifacts** (unchanged)
8. **The nominal `Float64` entry is one key in the activation dictionary like any other** (unchanged)
9. **Whether an activation is cached never changes a result** (unchanged)
10. **Every buffer set has exactly one owner** (unchanged)
11. **Lazy materialization is torn-state-free** (unchanged)

## Spans kept longer than the headline rule suggests

- A1 2: the `before` clause is the ordering being ruled; cutting it leaves no rule.
- A1 3: `field by field` is what distinguishes this check from the `x_init` vocabulary check.
- A1 10, A2 1: the listed inputs or members are the content of the rule.
- B 2: the span ends after `DeadStage`, since the classification is the ruling.
- C 13: the payload's column list is the rule; only the parenthetical moved out.
- S94 7: one clause with a compound predicate; both halves are D-135's title.
