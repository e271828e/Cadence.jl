# Brief: step 1c, retire the strata

The vocabulary sweep D-259 records. Tip: the commit that adds this brief and
D-259 (`git log -1`). Two commits: the docs sweep, then the code's comments.
The decision entry is already in `decisions.md`; read it first.

## What changes

The spec stops calling the build's three steps "Stratum A", "Stratum B" and
"Stratum C" and names each by what it produces. The steps and their
products do not change; only the words do. Three spellings, one per step:

- **the structure step**, today's Stratum A. The step that reads
  declarations and produces `Structure`.
- **the nominal evaluation**, today's Stratum B. The step that runs the
  stage functions once at `Float64` and produces `Dataflow`, `Events` and
  the nominal activation.
- **activation** (the step and its product share the word, as "the build"
  does), today's Stratum C. Activation at a scalar `T` takes the structure,
  the dataflow and the nominal activation and produces `Activation{T}`.

The generic noun for the three, where one is needed, is **step**: "the
build's three steps", "each step is a barrier", "the step barrier". Qualify
it as the build's on first use in a section, since "step" elsewhere is the
integration step. Never coin "stratum" back, and never write "phase",
"stage" or "pass" for a step; each already names something else.

Two glosses change wholesale. The activation gloss "(a re-run of Stratum C
at a given scalar type)" becomes "(the build's typed products at a given
scalar type)". The stratum gloss "(one of the build's three phases:
structure, execution order, activation)" disappears with its headword; the
step's name stands alone, with a gloss on first use per section where the
sentence needs one: "the structure step (the build's first step,
declaration reading only)", "the nominal evaluation (the build's second
step, the one evaluation that feeds structure)".

Renaming only, with the exceptions listed under "Rewritten passages": no
other sentence gains or loses a norm. Where a replacement reads badly in
its sentence, apply the closest spelling and flag the line.

## Reading

- `docs/design/tools/spec_style.md`, whole. No em-dashes, one burden per
  sentence, content preservation, the battery, 80 rendered columns.
- `decisions.md`, D-259 (the last entry) and D-253's fourth bullet.
- Every occurrence: `rg -n -i 'stratum|strata' docs/design/spec.md`, 112
  lines. Read each in its paragraph before deciding.

## The rules, by pattern

| pattern | replacement |
| --- | --- |
| `(a re-run of Stratum C at a given scalar type)`, also split across lines | `(the build's typed products at a given scalar type)` |
| `[Stratum](#g-stratum) A (one of the build's three phases: structure, execution order, activation)` | `the structure step (the build's first step, declaration reading only)` on the section's first use, `the structure step` after |
| `[Stratum](#g-stratum) B (one of the build's three phases: …)` | `the nominal evaluation (the build's second step, the one evaluation that feeds structure)`, then bare |
| `Stratum A's product` | `the structure step's product` |
| `Stratum B's product` / `Stratum B's other product` | `the nominal evaluation's product` / `other product` |
| `Stratum A` (bare, the checks and the charter) | `the structure step` |
| `Stratum B` (bare) | `the nominal evaluation` |
| `Stratum-C re-run`, `Stratum C re-run` | `activation`, respelled to fit the sentence |
| `Stratum-C clients` | `activation clients` |
| `Strata are barriers` / `A stratum that …` / `the stratum barrier` / `within a stratum` | `The build's steps are barriers` / `A step that …` / `the step barrier` / `within a step` |
| `the three strata`, `all three strata` | `the build's three steps` |
| `Outside the strata` | `Outside the build` |
| `the stratum products` | `the three steps' products` |

## The site table

Line numbers are at the tip. "new" is the exact replacement unless the cell
says otherwise; read the sentence and rewrap the paragraph.

| line | current | new |
| --- | --- | --- |
| 981 | `[Stratum](#g-stratum) B (one of the build's three phases: structure, execution order, activation)` | `the nominal evaluation (the build's second step, the one evaluation that feeds structure)` |
| 989 | inside Stratum B's failure path | inside the nominal evaluation's failure path |
| 1008 | No Stratum C machinery is touched. | No activation machinery is touched. |
| 1008–1009 | (a re-run of Stratum C at a given scalar type) | the gloss rule |
| 1012 | run as an ordinary Stratum-C activation | run as an ordinary activation |
| 1132, 1211, 1558, 2005, 3617, 3711, 3744, 8236, 8523, 9109, 9435 | the activation gloss | the gloss rule |
| 1134 | decided in [Stratum](#g-stratum) A | decided in the structure step |
| 1510 | Stratum A checks every | The structure step checks every |
| 1720 | It fixes the three ordering strata, the `Build` artifact they produce | It fixes the build's three steps, the `Build` artifact they produce |
| 1964 | Stratum A reports it as | The structure step reports it as |
| 2068 | in [Stratum](#g-stratum) A (one of …) | in the structure step (the build's first step, declaration reading only) |
| 2202 | in [Stratum](#g-stratum) A, before any user | in the structure step, before any user |
| 2208 | the activation's own lazy Stratum-C compile | the activation's own lazy compile |
| 2215 | An activation is a Stratum-C re-run, cheap enough | An activation is derived from the nominal one, cheap enough |
| 2233 | Stratum A checks both | The structure step checks both |
| 2287 | in [Stratum](#g-stratum) A ([§9.1][s9-1]) | in the structure step ([§9.1][s9-1]) |
| 2556–2557 | so [Stratum](#g-stratum) C specialization is unchanged (the strata are the build's three phases: structure, execution order, activation) | so activation is unchanged |
| 2624 | The check is Stratum A | The check is the structure step's |
| 2991 | and strata are barriers | and the build's steps are barriers |
| 2994 | `### 9.1 Three strata` | `### 9.1 The build's three steps` |
| 3003–3004 | The pipeline is therefore inherently heterogeneous, and it is organized as three [strata](#g-stratum). | the "§9.1's head" passage below |
| 3006 | `#### Stratum A: structure` | `#### The structure step` |
| 3008 | Stratum A is pure declaration reading. | The structure step is pure declaration reading. |
| 3012 | The stratum is a tree walk | The step is a tree walk |
| 3034 | this stratum | this step |
| 3049 | this stratum's charter | this step's charter |
| 3053 | Stratum A also checks | The step also checks |
| 3058 | is Stratum A's too | is the structure step's too |
| 3079 | happens in Stratum A. | happens in the structure step. |
| 3082 | **Stratum A returns [`Structure`](#g-structure)** | **The structure step returns [`Structure`](#g-structure)** |
| 3092 | `#### Stratum B: execution order` | `#### The nominal evaluation` |
| 3094 | **Stratum B is a function of the `Structure`**, and it returns two artifacts, | **The nominal evaluation is a function of the `Structure`**, and it returns three artifacts, (then read on: the sentence lists `Dataflow` and `Events` "with the `Float64` stage-1 products"; it becomes "[`Dataflow`](#g-dataflow), [`Events`](#g-events) and the nominal `Float64` [activation](#g-activation) ([D-253][d-253], [D-259][d-259])") |
| 3102 | B computes them in this order: | It computes them in this order: |
| 3122–3126 | the "structural half" paragraph | the "nominal evaluation's product" passage below |
| 3127 | `#### Stratum C: activation, parametric in `T`` | `#### Activation, parametric in `T`` |
| 3129–3131 | **Stratum C takes the structure, the dataflow and the events, and completes an `Activation`** ([D-253][d-253]). An activation is a re-run of Stratum C at a given scalar type. The stratum holds everything type-shaped: | **Activation at a scalar `T` takes the structure, the dataflow and the nominal activation, and completes an `Activation{T}`** ([D-253][d-253], [D-259][d-259]). The step holds everything type-shaped: |
| 3143–3144 | re-run *only this stratum* | re-run *only this step* |
| 3148 | sits after all three strata | sits after the build's three steps |
| 3219–3220 | A stratum that throws … A stratum that completes | A step that throws … A step that completes |
| 3233 | the stratum products of [§9.1][s9-1] | the products of [§9.1][s9-1]'s three steps |
| 3260–3261, 3490–3491, 3740, 7777, 8156, 8158, 8525, 10681–10683, 11886, 11898, 11972 | Stratum A's / B's product | the product rule |
| 3280 | From [Stratum](#g-stratum) A the artifact gains | From the structure step the artifact gains |
| 3405 | before the [Stratum](#g-stratum) B probes | before the nominal evaluation's probes |
| 3474 | re-runs [Stratum](#g-stratum) C with a different scalar | re-runs the activation step with a different scalar |
| 3486 | precedes the Stratum B [probes](#g-probe) | precedes the nominal evaluation's [probes](#g-probe) |
| 3509 | runs in Stratum B's failure path | runs in the nominal evaluation's failure path |
| 3523 | at the cost of a Stratum-C re-run per component | at the cost of an activation per component |
| 3701 | `### 9.6 Stopped-sim services as Stratum-C clients` | `### 9.6 Stopped-sim services as activation clients` |
| 3703 | it grounds the strata | it grounds the build's steps |
| 4552–4553 | **Validation belongs to [Stratum](#g-stratum) A**, the build's declaration-validation stratum, | **Validation belongs to the structure step**, the build's declaration-reading step, |
| 7466 | in [Stratum](#g-stratum) A (one of the build's three phases: …) | in the structure step (the build's first step, declaration reading only) |
| 7475–7476 | Strata are barriers. A stratum that produced … before the next stratum begins. | The build's steps are barriers. A step that produced … before the next step begins. |
| 7479 | the stratum barrier | the step barrier |
| 7484 | Stratum A's walk | The structure step's walk |
| 7490 | In Stratum C the probe chain | In the two evaluating steps the probe chain |
| 7492 | Outside the strata | Outside the build |
| 7496 | None of the three strata | None of the three steps |
| 7500 | within a stratum | within a step |
| 7532 | The [stratum](#g-stratum) barrier (a stratum is one of the … | The step barrier (each of the build's three steps throws before the next begins) (read the sentence and keep what follows the gloss) |
| 7614 | A stratum that throws | A step that throws |
| 7720 | in [Stratum](#g-stratum) A (one of …) | in the structure step |
| 8307 | as [Stratum](#g-stratum)-C clients | as activation clients |
| 10999 | A stratum that produced one throws | A step that produced one throws |
| 11012 | During one of the three strata | During one of the build's three steps |
| 11022 | the `DiagnosticError` of the stratum | the `DiagnosticError` of the step |
| 11052–11053 | with a stratum's throw … a stratum that throws | with a step's throw … a step that throws |
| 11056 | **Declaration and wiring** (Stratum A): | **Declaration and wiring** (the structure step): |
| 11175 | **Execution order and contract conformance** (Strata B and C): | **Execution order and contract conformance** (the nominal evaluation and activation): |
| 11859–11866 | the `activation` glossary entry | the entry text below |
| 11875 | bundling the stratum products: | bundling the three steps' products: |
| 11922 | applied in Stratum C, [§9.1][s9-1] | applied at activation, [§9.1][s9-1] |
| 11966–11970 | the `stratum` glossary entry | delete the entry and the blank line after it |
| 12330 | at a stratum barrier | at a step barrier |
| 12337 | Strata are barriers | The build's steps are barriers |

Lines 48, 53, 12719 and 12724 are generated (the contents block and the
definitions block); `linkify.jl` regenerates them from the headings. Do not
edit them. After the table, `rg -n -i 'stratum|strata' docs/design/spec.md`
must return nothing.

## Rewritten passages

Exact text. Wrap to 80 rendered columns.

**§9.1's head** (3003–3004). The paragraph's last sentence becomes two, and
the table follows the paragraph:

> The pipeline is therefore inherently heterogeneous. It runs as the steps
> below, each consuming one artifact and producing the next, and each a
> barrier ([§13.1][s13-1]): a step that produced any error throws before the
> next begins.
>
> | step | consumes | produces | user code it runs |
> |---|---|---|---|
> | the structure step | the root instance | [`Structure`](#g-structure) | declaration bodies only |
> | the nominal evaluation | `Structure` | [`Dataflow`](#g-dataflow), [`Events`](#g-events), the nominal `Float64` [activation](#g-activation) | the stage functions, guards and handlers, at `Float64` |
> | activation at `T` | `Structure`, `Dataflow`, the nominal activation, a scalar `T` | `Activation{T}` | the continuous tier's functions at `T` |
> | deployment | the `Build`, the grid parameters | [`Deployment`](#g-deployment) with its [`Schedule`](#g-schedule) | none |
> | materialization | the `Deployment`, a scalar `T` | `Simulation{T}` | none |
>
> The first three are the build, and `build(world)` runs them; the
> [`Build`](#g-build) bundles their products ([§9.2][s9-2]). The last two are
> the `Deployment` constructor below and the `Simulation` constructor
> ([§9.2][s9-2]).

**The nominal evaluation's product** (3122–3126, replacing the "structural
half" paragraph whole):

> **The nominal evaluation fixes the structure and the `Float64` typing at
> once.** The nominal [activation](#g-activation) is its product beside
> `Dataflow` and `Events`, assembled from the same probe chain, never a
> separate pass ([D-253][d-253], [D-259][d-259]). That is why no product of
> this step changes across activations.

**The `activation` entry** (11859–11866), keeping its anchor and headword:

> **activation** — the build's typed products at a given scalar type `T`.
> Cells are re-typed (producer-fed ones by evaluating the producer's output
> declaration at `T`, root inputs by evaluating the consuming `input_types`
> entry at `T`, the state type by the leaf walk), buffers are re-laid-out,
> workspace allocators are re-invoked, and the probe chain is re-run. The
> nominal `Float64` activation is the nominal evaluation's product; any
> other is derived on request from it, the structure and the dataflow
> ([§9.1][s9-1]). `Structure` and `Dataflow` are `T`-independent, so no name
> list and no execution order changes across activations. Non-nominal
> activations are lazy, with an opt-in exhaustive set for CI ([§9.4][s9-4]).

## Other edits

- **`docs/design/tools/gloss_table.md`.** Delete the `stratum` row (121)
  and its section-index row (274). Reword the `activation` (103), `Build`
  (105), `Dataflow` (107), `Events` (109) and `Structure` (120) rows per the
  rules. Leave the `n` counts alone.
- **`docs/design/tools/coinage_inventory.md`**, rows 51–53: "D-253's
  Stratum A artifact" becomes "D-253's structure-step artifact", "Stratum B
  artifact" "nominal-evaluation artifact", "other Stratum B artifact" "other
  nominal-evaluation artifact".
- **`docs/design/pending.md:26`**: "named stratum products" becomes "named
  step products".
- **`docs/design/implementation.md`**, rows 22 and 25: "Stratum A barrier"
  becomes "structure-step barrier", "Stratum A's one throw" becomes "the
  structure step's one throw"; grep the two rows for any other hit.
- **Not in scope.** `decisions.md` keeps its vocabulary (rule 2; D-259 is
  already written). `companions/` and the briefs are untouched
  (`sample_time_proposal.md` has 10 hits, `trim_environment_walkthrough.md`
  one generated definition line); count them for the report.

## Battery, then the docs commit

From the repository root, after the edits and before the commit:

    julia docs/design/tools/linkify.jl
    julia docs/design/tools/check_refs.jl
    julia docs/design/tools/check_rows.jl
    julia docs/design/tools/check_glossary.jl --strict
    julia docs/design/tools/linkify.jl        # must be a no-op

`linkify.jl` regenerates the definitions blocks of every rostered file that
cites §9.1 or §9.6, since their slugs change; those files join the commit.
If `check_glossary.jl` reports a first-use miss for `activation`,
`Structure`, `Dataflow` or `Events` in a section where a `#g-stratum` link
used to stand, add the glossary link at that first use.

Commit with `git add` **by path**, never `-A` or `.`: the uncommitted audit
refresh under `docs/reports` stays out. Single-sentence subject, no body,
no attribution:

    Retire the strata: name the build's steps by their products across the spec

Let the post-commit PDF hook run. Never stash, reset or check out the
working tree.

## The code's comments, then the second commit

The 49 hits of `rg -n -i 'stratum|strata' src/ test/` are comments,
docstrings, section headers, a testset name and two identifiers. Apply the
rules to every comment, docstring, header and testset name. Two identifiers
stay for increment 44 to rename, since it rewrites both functions:
`_stratum_c` (`build.jl:662, 826, 838`) and `build_stratum_a`
(`test_build.jl:1388, 1537`). Sites that need a sentence rather than a
word:

| site | new |
| --- | --- |
| `build.jl:592` | One activation: the typed products at a concrete scalar `T` (§9.1) … |
| `build.jl:606` | everything the build's three steps settle before `Δt_base` exists |
| `build.jl:609` | other activations are derived at first request, cached on the `Build` |
| `build.jl:640` | The structure step, the nominal evaluation and the eager activations (§9.1): … |
| `build.jl:657` | The structure step's barrier (§13.1, D-229): … |
| `build.jl:815` | derived at first request (§9.4) |
| `build.jl:830–832` | Activation at `T`, parametric in the scalar (§9.1): … the nominal evaluation's execution order falls out … |
| `build.jl:1146` | Everything below post-dates the build's three steps: … |
| `sim.jl:64` | `activation(b, T)`'s cached derivation |
| `trim.jl:424` | the cached activation (§9.4) |
| `diagnostics.jl:260` | `# The structure step — declaration and wiring (…)` |
| `diagnostics.jl:797` | `# The nominal evaluation and activation — schedule and contract conformance (…)` |
| `tracer.jl:6` | inside the nominal evaluation's failure path |
| `test/fixtures.jl:129` | (§9.1, the nominal evaluation) |
| `test_build.jl:103` | which is the build's split from deployment |
| `test_build.jl:1273, 1275, 1389` | the structure step's one barrier; one failure from each of the step's passes; "every structure-step pass that ran merges into one throw (§13.1, D-229)" |
| `test_build.jl:1439, 1450, 1466` | the activation's own lazy derivation; a cached activation derived from the nominal one; "a non-nominal activation is derived from the nominal one; frozen products carry (§9.4)" |
| `test_diagnostics.jl:250, 345` | `# the structure step`, `# the nominal evaluation and activation` |

After the edits `rg -n -i 'stratum|strata' src/ test/` must show exactly
the five identifier lines. No behavior changes. `sim.jl` is touched, so the
run is the gate of `implementation.md`'s "Running the suite" (113–164),
under its flags, in the foreground, with a 600 s timeout, never in the
background. Then the commit, by path:

    Rename the strata in the code's comments and testset names to the steps' names

## Report

- Counts: sites per rule, the four rewritten passages applied, glossary
  entry removed, the out-of-scope counts per file.
- Every line where the table's replacement did not fit its sentence and what
  you did instead; anything left ambiguous, with your reading.
- The battery's output and the files `linkify.jl` regenerated.
- The gate's result for the code commit, with the output on failure.
- Both commit hashes.
