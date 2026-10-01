# Survey of spec chapter 9 before its readability rewrite — 2026-10-01

Scope: `docs/design/spec.md` lines 3391–4338, "## 9. The build pipeline", at
the working tree of 2026-10-01 (tip `d598755`). The convention and method are
those of `docs/reports/20261001_spec_rewrite_sample/report.md`, "Conclusions".
§9.4's future text is that report's `versions/v4_flat.md`.

Line numbers are `spec.md` lines unless marked `log` (`decisions.md`). Entry
claims rest on the entry's Position as read, with its line given where the
point sits outside the first sentence.

Classification codes used in part A:

- **C** cited, and ruled by the cited entry's Position.
- **U** ruled by an entry's Position that the section does not cite at that
  spot.
- **S** cited to a superseded entry.
- **R** ruled only in an entry's Rationale, Rejected list or annotation.
- **N** no entry found.
- **B** borderline; both readings are given.

"Marking" is how the spec marks the rule now: **Rule.**/**Why.**/**Example.**
label, bold sentence, bold lead-in (a bold phrase opening a paragraph, used as
a heading), or plain.

## A. Per section

### Chapter intro (3391–3401, 101 words)

Purpose: says the chapter fixes when each declared fact is checked, against
what, with which failure.

No rule of its own. 3398–3401 restates §13.1's reporting policy (collect the
checks, fail evaluations fast, steps are barriers). That is a description of
§13.1 and D-057/D-229. It has no roadmap sentence naming §9.1–§9.7.

### §9.1 The build's three steps (3403–3655, 1974 words)

Purpose: defines the three steps of `build` (structure step, nominal
evaluation, activation), what each consumes and produces, and what each
checks. It also hosts the `Deployment` constructor and the warning policy,
which are not build steps.

Subheadings (`####`): "The structure step" (3430, topic), "The nominal
evaluation" (3517, topic), "Activation, parametric in `T`" (3554, topic with a
claim qualifier), "The `Deployment` constructor" (3573, topic), "Where a build
warning lives" (3644, an indirect question). Three tables: steps (3417), fold
(3492), constraint pool (3611). Labels: two **Rule.** (3605, 3646), one
**Why.** (3600).

Rules:

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 1 | 3405–3411 | "Face derivation is **bottom-up** … **global** … **derived by probing**" | bold words | D-048 Position (A: "bottom-up faces, global wiring + obligations"; B: "`h_x` probe →") | B: U by D-048; or a description, since 3405 calls the three "forced by settled decisions" and cites §8.8, §6.1, §8.2 |
| 2 | 3413–3415 | "each a barrier … a step that produced any error throws before the next begins" | plain | D-259 Position bullet 2 ("Each step is a barrier"); D-057 Position | U |
| 3 | 3425 | "The first three are the build, and `build(world)` runs them" | plain | D-259 Position bullet 1 | U |
| 4 | 3432–3433 | "pure declaration reading. No user stage code executes in it" | plain | D-048 Position (A); D-259 bullet 2 | U |
| 5 | 3436–3446 | the five-step walk order | plain list | D-048 Position (A) | U |
| 6 | 3448–3454 | resolution runs one-writer, did-you-mean, the two type clauses, the obligation check | plain bullets | D-048 Position (A: "global wiring + obligations"); collection by D-229 | U |
| 7 | 3455–3458 | store form: every `x_init`, `s_init`, `m_init` is a `NamedTuple`, checked before the classifier | plain | D-247 Position | U |
| 8 | 3459–3461 | closed leaf vocabulary on every `x_init`; `s_init` isbits, `m_init` field by field | plain | D-094 Position; D-231 Position | U |
| 9 | 3463–3464 | "Root inputs fall out here too, as the root component's input faces" | plain | D-208 Position | U |
| 10 | 3466–3468 | bound check: producer at `Float64` `<:` entry at `Float64`; abstract-at-root detected here | bold lead-in | D-078 Position; D-236 Position (`AbstractAtRoot`) | U |
| 11 | 3470–3475 | walk-compatibility clause, continuous consumers only, decided by retyping at a marker scalar; `WalkingFaceAtFrozenEntry` | bold lead-in | D-263 Position bullet 2 ("decided at the marker scalar by retyping"); D-236 Position. The kind name appears only in D-167 (superseded) Rationale log 5752 and D-264 Rationale log 10248 | B: U for the rule; R for the kind name |
| 12 | 3477–3480 | declaration-completeness rules checked in this step | plain | D-263 Position (`StoreWithoutUpdate`, `TierUnreadable`, `StatelessWithoutOutputs`); the rest rest on §8.2's entries | U |
| 13 | 3482–3486 | `sample_times` validation is the structure step's, collected with path attribution | plain | D-185 Position ("validation Stratum A's with path attribution") | U |
| 14 | 3490–3500 | the fold: root `(A₀,1,0)`; `Relative` `(a, K·mₛ, cₛ + φ·mₛ)`; `Absolute` "severs and re-seeds" | table, bold cell | D-186 Rationale log 6523–6526 | R |
| 15 | 3502–3504 | "Everything except binding `Δt_base` … happens in the structure step" | plain | D-048 Position ("rate compilation" in A); D-186 Rationale (divisors deferred to binding) | B: U by D-048, or R by D-186 |
| 16 | 3506–3508 | "**The structure step returns `Structure`** … its whole product" | bold sentence | D-253 (cited) | C |
| 17 | 3509–3515 | what `Structure` carries; "Nothing in it depends on a scalar type" | plain | D-253 bullet 1 (cited above); D-261 amendment (rows); D-257 amendment (routing chain) | C |
| 18 | 3519–3520 | "**The nominal evaluation is a function of the `Structure`**", three artifacts | bold sentence | D-253, D-259 (cited) | C |
| 19 | 3524–3526 | feedthrough graph not carried, derived where shown | plain | D-261 (cited; the ruling is in the Position's amendment parenthetical) | C |
| 20 | 3530–3533 | workspace allocated at the probing scalar, sound because the allocator reads only instance and scalar | plain | D-115 Position. The cited D-077 Position says only "called per activation and per scratch-store set" | U |
| 21 | 3534–3536 | stage-1 probes run at `Float64` on the init values | plain | D-048 Position (B); D-033 Position ("inputless `h_x` probes first") | U |
| 22 | 3537–3538 | ports classified over `y_types` alone into two classes | plain | D-252 (cited) | C |
| 23 | 3539–3540 | feedthrough graph, topological order, §5.5 cycle rejection | plain | D-048 Position (B) | U |
| 24 | 3541–3543 | event declarations read last; an execution-order consumer never carries the event tables | plain | D-253 (cited) | C |
| 25 | 3545–3546 | "Both products are structural … names only, `T`-independent" | plain | D-259 bullet 2 ("products are names only") | U |
| 26 | 3548–3552 | "**The nominal evaluation fixes the structure and the `Float64` typing at once.**" | bold sentence, citation in the next sentence | D-253 bullet 4 as amended; D-259 bullet 1 (cited) | C |
| 27 | 3556–3558 | "**Activation at a scalar `T` takes the `Structure`, the `Outputs` and the nominal activation …**" | bold sentence | D-253, D-259 (cited) | C |
| 28 | 3560–3568 | producers' declarations "**retyped**"; state type walked; probe chain; layout | bold word, plain list | D-263 Position bullet 1; D-079 Position | U |
| 29 | 3570–3571 | "Other activations re-run *only this step*" | plain | D-259 bullet 2 ("Only activation re-runs per scalar") | U |
| 30 | 3575–3580 | "**The `Deployment` constructor sits after the build's three steps.**" and what it binds and builds | bold sentence | D-254 (cited) | C |
| 31 | 3582–3585 | `Deployment` is scalar-free; what it holds | plain | D-254 bullet 1 (cited in the paragraph above) | C |
| 32 | 3586–3587 | "Two deployments compare as values" | plain | D-254 bullet 1 | C (adjacent citation) |
| 33 | 3589–3594 | `Δt_base` has exactly one of three sources, cross-validated; keyword; `N_base·h` | plain bullets | D-186 Rationale log 6534–6537; D-234 for the name | R |
| 34 | 3595–3598 | "**derivation**, requested explicitly as `Δt_base = :derive`. It is never entered by default" | bold word | all-anchored condition: D-186 Rationale log 6531. Explicit `:derive` request: no entry | B: R for the condition; N for the explicit request |
| 35 | 3605–3607 | "**Rule.** If any unanchored component exists, deployment must declare `Δt_base`" | **Rule.** label, no citation | D-186 Rationale log 6531–6534; D-186 Rejected log 6546 | R |
| 36 | 3609–3618 | admissibility by exact GCD over the constraint pool (table) | bold term, table | D-186 Rationale log 6529–6531 | R |
| 37 | 3620–3625 | `Dₖ`, `Φₖ` must be exact integers, else `DeploymentInvalid` naming anchor, scope, key | plain | D-186 Rationale log 6537–6540; D-187 Rationale log 6582 | R |
| 38 | 3627–3629 | deployment validation collected into `DeploymentInvalid` with parameter, value, constraint | plain | D-229 Position last bullet; D-113 Position | U |
| 39 | 3631–3638 | the violation list | plain bullets | D-133 Position; D-181 Position (`firing_budget`); D-227; D-234 | U |
| 40 | 3640–3642 | event parameters are grid-independent, outside the harmonic-grid check | plain | D-133 Position | U |
| 41 | 3646–3649 | "**Rule.** A step that throws renders its warnings with the collection …" | **Rule.** label | D-250 (cited) | C |
| 42 | 3651–3655 | scoped channel bound around the three steps; standalone call logs directly | plain | D-250 bullet 2 and its amendment (cited in the paragraph above) | C (adjacent citation) |

Descriptions that read like rules: 3405–3411 (see row 1); 3502–3504 is also
partly a consequence of the fold; 3570 "The nominal `Float64` activation runs
at build" restates the table and conflicts with row 26 (part F).

Code the convention would move to display blocks: none is a call or
definition the reader would type, except the `Δt_base = :derive` keyword
(3595). The constructor's signature is never shown here; Appendix B
10820–10838 has its keywords.

Mechanisms and examples: the steps table, the walk order, the fold table and
its residue remark (3498–3500), the constraint-pool table, the violation list.

### §9.2 The `Build` artifact (3657–3810, 1379 words)

Purpose: what `Build`, `Structure`, `Outputs`, `Schedule` and `Deployment`
hold, how they print, and the grid diagnostics. More than half of it is about
the `Deployment` and its `Schedule`, not the `Build`.

Subheadings: none. Bold lead-ins act as headings (3665, 3679, 3694, 3706,
3720, 3738, 3775, 3781, 3786, 3807). Labels: **Why.** 3675, **Rule.** 3732
and 3752, **Example.** 3757. One table (3764).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 43 | 3659 | "`build(world) → Build` is a standalone entry point" | plain | D-049 Position (cited only at 3704) | U |
| 44 | 3659–3660 | "**A `Build` is structure, outputs, events, the activations and `warnings`**" | bold sentence | D-253 (cited); `Outputs` per D-261; `warnings` per D-250 | C |
| 45 | 3661–3663 | activations are one dictionary keyed by scalar type, "under the lock" | plain | D-253 bullet 5 ("under the existing lock") | U; conflicts with D-135's "mechanism unspecified" (part F) |
| 46 | 3665–3670 | "**Deploying and materializing are two steps, with two sugar forms over them.**" | bold lead-in sentence | D-254 (cited); D-119 Position | C |
| 47 | 3670–3673 | "The artifact deployed is the very build that CI checked … never an assumed-equal reconstruction" | plain | D-119 Rationale log 3486–3489 | R |
| 48 | 3675–3677 | **Why.** computed bodies are re-evaluated per build | **Why.** label | D-119 Rationale | reason, not a rule |
| 49 | 3679–3680 | "**The `Build` is immutable and may back any number of deployments and `Simulation`s, concurrently.**" | bold sentence, no citation | D-135 Rationale log 4114–4117 | R |
| 50 | 3683–3684 | the activation dictionary is the one mutable thing; insertion torn-state-free | plain | D-135 Rationale log 4117–4121 (v4 cites draft D-281) | R |
| 51 | 3684–3689 | the `Build` is the inspectable derived contract; wire list, face table, root inputs on `Structure`, order on `Outputs` | plain | D-049 Position; D-253 bullets 1–2 | U |
| 52 | 3694–3701 | "**The face table on `Structure` is two-sided.**" input faces resolved producer-ward; total | bold sentence | D-207 (cited) | C |
| 53 | 3701–3704 | CI calls `build`; acceptance tests target it; `attach!` validates against it; build-only-inside-`Simulation` rejected | plain | D-049 (cited) Position and Rejected | C |
| 54 | 3706–3718 | "**`Structure`'s timing tables are anchor-relative, and the `Deployment` binds them.**" anchor table, component table, `A₀` row | bold sentence, no citation | D-186 Rationale (tables, deferral); D-253 bullet 1 (rate chain, scope triples); D-257 bullet 1 (`A₀` row) | B: U by D-253/D-257 for what `Structure` holds; R by D-186 for anchor-relativity |
| 55 | 3720–3722 | "**The `Schedule` … lives on the `Deployment`**" | bold sentence | D-254 (cited) | C |
| 56 | 3723–3726 | the `Schedule`'s rows | plain | D-254 bullet 2; D-261 bullet 4 | C |
| 57 | 3726–3728 | per-component `(D, Φ, Δt)` derived at `compile`, never stored beside the rows | plain | D-261 (cited) | C |
| 58 | 3728–3730 | the schedule is the single source of truth for `Δt` and the diagnostics' substrate | plain | D-187 Position | U |
| 59 | 3732–3736 | "**Rule.** An artifact holds declared facts …" | **Rule.** label | D-261 (cited) | C |
| 60 | 3738–3743 | "**Each artifact renders itself through `show`, with no accessors**" and what each prints | bold sentence | D-257 (cited) | C; omits D-257's `Events` amendment (part F) |
| 61 | 3744–3747 | routing chain recorded at every level; `show(::Structure)` prints root routes one line per chain | plain | D-257 bullet 3 amendment (cited at 3739) | C |
| 62 | 3749–3750 | one hyperperiod is the complete truth, not a sample | plain | D-187 Position | U |
| 63 | 3752–3755 | "**Rule.** The chart guard is binary … at most 100 base ticks" | **Rule.** label | D-257 (cited) | C |
| 64 | 3775–3779 | "**The grid diagnostics live on the `Deployment` and print from the pool, exactly**" | bold sentence | D-254 (cited) bullet 3 | C |
| 65 | 3781–3784 | leave-one-out factors; "Every `r_p > 1` is listed rather than one culprit crowned" | bold lead-in | D-254 bullet 3 names the factors; the listing rule is D-187 Rationale log 6570–6571 and Rejected log 6592 | B: C for the factors; R for "every `r_p > 1`" |
| 66 | 3786–3788 | prime attribution | bold lead-in | D-254 bullet 3 | C |
| 67 | 3790–3792 | nearest non-refining alternatives when an offset drives | plain | D-254 bullet 3 | U |
| 68 | 3794–3795 | blame against the actual pool; simple-fraction test stays authoring guidance | plain | D-187 (cited) Rejected log 6585–6588 | R |
| 69 | 3797–3803 | derivation path always prints the derived value; `GridUtilization` advisory | plain | D-254 bullet 3 (names "the derivation line and `GridUtilization`"); detail in D-187 Rationale | U |
| 70 | 3804–3805 | `GridUtilization` is a deployment warning, on the `Deployment`'s list, logged once | plain | D-250 (cited); D-254 bullet 3 | C |
| 71 | 3807–3810 | "**`warnings(x)` reads the list.**" on `Build`, `Deployment`, `Simulation` | bold sentence | D-250 (cited) | C |

Descriptions that read like rules: 3684–3692 ("'Printable' names the
representation …") explains a term. 3714–3718 ("final divisors cannot live
here") is a consequence of row 54, reasoned.

Display-block candidates: the four entry points `build(world)`,
`Simulation(deployment, T)`, `Simulation(build; kw...)`, `Simulation(world;
kw...)` (3659, 3668–3670); the five `show` methods (3739–3743), better as a
list; the factor `r_p = gcd(pool ∖ p)/gcd(pool)` (3782) as a display formula.

Mechanisms and examples: the worked binding example (3757–3773) and its table,
the hyperperiod period, the prime-attribution procedure.

### §9.3 Probing and input synthesis (3812–3907, 969 words)

Purpose: what the build probes, where each probe argument comes from, how root
inputs get values, and the author's totality obligation.

Subheadings: none. Bold lead-ins as headings: "Probe-everything scope."
(3814), "Probe argument sourcing." (3825), "The author's side of that
bargain." (3877). The middle paragraph (3825–3863) runs about 500 words.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 72 | 3814–3817 | "The nominal activation probes every user function once, at the initial state, with real values" | bold lead-in | D-050 Position | U |
| 74 | 3825–3832 | `x`/`s`/`m` from init; hand-down from stage-1 returns; wired inputs from upstream; stage-2 chain probed in topological order | bold lead-in | order: D-048 Position (B). Hand-down sourcing: D-169 Position (superseded → D-252); D-252 Position does not state it | B: U by D-048 for the order; N for the hand-down |
| 75 | 3832–3833 | "A stage returning something other than a `NamedTuple` fails here" | plain | none current. D-165 Position (superseded → D-194) said "a `nothing` in either slot is a probe error" | N |
| 76 | 3833–3835 | a stage returning `(;)` is `DeadStage`, fail-fast | plain | D-194 Position bullet 5 | U |
| 77 | 3836–3838 | "`t` is probe-scoped `0.0`" | plain | D-115 Position | U |
| 78 | 3838–3841 | "`ws` comes from invoking the component's `ws_init` allocator at the probing scalar" | plain, cites D-077 | D-115 Position | U (D-077 is cited for the reason, not the ruling) |
| 79 | 3841–3847 | root inputs synthesized via `probe_value(::Type)`; `zero(T)`, `false`, first enum, `T()` | bold "root inputs" | D-051 (cited at 3862) | C |
| 80 | 3847–3849 | "`probe_value` is **overridable**" | bold word | D-051 Position | C |
| 81 | 3849–3854 | no method is a build error naming face and type | plain | D-051 Position | C |
| 85 | 3865–3868 | "**Probe values are strictly probe-scoped.**" never initial root-input values | bold sentence | D-051 Position (cited in the previous paragraph) | C (adjacent) |
| 86 | 3868–3871 | discrete probes supply a placeholder period `1.0` | plain | D-115 Position calls it "the settled `Δt = 1.0` placeholder"; the settling entry was not found | U |
| 87 | 3872–3875 | `Simulation` must not reach its first boundary with uninitialized root inputs; `UninitializedInputs` at `init!`, trim setup, trim commit | plain | D-149 Position; D-206 (rename) | U |
| 88 | 3878–3882 | "**Stage code must be total over type-valid inputs.**" | bold sentence | D-142 (cited) | C |
| 89 | 3882–3885 | domain is type-validity; the probe is the enforcement moment | plain | D-142 Position | C |
| 90 | 3885–3889 | two consequence sites, same throw | plain | D-142 Position | C |
| 91 | 3889–3890 | "Exceptions from model code are always abnormal" | plain | D-060 Position (a §13.5 rule restated) | U |
| 92 | 3890–3894 | plausibility check → `Bool` output face plus `stop_on` | plain | D-142 Rationale log 4618–4620 | R |
| 93 | 3894–3898 | self-consistency assert → the test suite | plain | D-142 Rationale log 4621–4626 | R |
| 94 | 3899–3907 | defensive exhaustiveness is "**mislocated**" validation; parameter validation in pre-build constructors | bold word | D-142 Position log 4609–4612 | C |

(Numbers 73, 82, 83 and 84 are not rules; see below.)

Descriptions that read like rules: 3817 "checks shape and type conformance and
discards the results" (73, mechanism); 3854–3857 "Synthesis never meets an
abstract type" (82, a consequence of D-208/D-236's `AbstractAtRoot`, with its
reason given); 3858–3862 "Physically silly values are acceptable by
construction" (83, a consequence, argued). 3862–3863 lists the three rejected
alternatives of D-051 (84); that is adversarial rationale, which
`spec_style.md` "Rationale" sends to the log, and D-051's Rejected list holds
all three.

Display-block candidates: the `probe_value` fallback methods (3843–3846); the
missing-method message (3851–3854); the override `probe_value(::Type{Ranged{
Float64, -1, 1}})`.

### §9.4 Activations (3908–4000, 873 words) — brief

Purpose: what an activation re-runs, which functions it probes, when it runs,
and what the `Build` caches. Its future text is `v4_flat.md` (1046 words).

The trial report settles its rules. In the current text: cited and ruled,
4 (D-253 at 3930 and at 3975, D-275 at 3960, D-012 at 3942–3943); uncited, 6
(D-259, D-052 three times, D-099, D-135); superseded, 1 (D-166 at 3956); in a
Rationale only, 2 (buffer ownership and torn-state freedom, both D-135
Rationale log 4101–4121). One factual error (workspace scalar, D-263).

What matters here is overlap with other sections, given in part B: §9.1's
activation list (3559–3571), §9.1's workspace sentence (3530–3533), and §9.2's
immutability and lock sentences (3661–3663, 3679–3684).

### §9.5 The always-on conformance check (4001–4140, 1501 words)

Purpose: the check at every table write that holds a return to the type the
probe fixed, the acceptance relation at each activation, the per-function
predicates and the failure payload.

Subheadings: none. Bold lead-ins as headings: 4027, 4049, 4094, 4107, 4121,
4129. The paragraph at 4049–4092 runs about 600 words; 4003–4025 about 350.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 95 | 4006–4014 | at the write the executor holds the cells' type at this activation; the test is decided when the write's method is specialized; no per-field instruction on the conformant path | plain | D-235 (cited) | C |
| 96 | 4017–4019 | conformant → straight stores; non-conformant → a throw at that branch's first execution | plain | D-235 Position bullet 2 | C |
| 97 | 4027 | "**The names are the pairing, and field order carries no semantics.**" | bold sentence, no citation | D-151 Position | U |
| 98 | 4033–4035 | the general rule at every `NamedTuple` seam | plain | D-151 Position | U |
| 99 | 4044–4047 | an error is a key-set or per-field type mismatch; a permutation is not an error | plain | D-151 Position | U |
| 100 | 4050–4052 | at nominal, exact type match, no convert-on-write | bold lead-in | D-053, D-235 (cited) | C |
| 101 | 4056–4059 | a **walking leaf** accepts exactly the activation scalar or `Float64`; `Float64` is embedded | bold term | D-053 Position last sentence (cited at 4052) | C |
| 102 | 4060–4061 | struct-valued ports use the standard cross-eltype constructor; a missing one fails loudly | plain | none found | N |
| 103 | 4061–4064 | opaque leaf accepted by identity; a frozen opaque arrival admitted at a wire | plain | D-237, D-264 (cited) | C |
| 104 | 4065–4069 | nothing else accepted; decided on the type; lifted arrival must be the declaration itself | plain | D-238 (cited) | C |
| 105 | 4069–4072 | a **pinned leaf** takes "the nominal-style exact check at *every* activation" | bold term | D-263 Position bullet 1 (pinned at every activation) and D-079 Position (`Int`/`Bool`/enum pin); the conformance consequence is in D-079 Rationale log 2262–2264 | B: U as a consequence of D-263; R in D-079 |
| 106 | 4072–4074 | an observed `Dual` there is the misplaced-pin error, with the hint "remove its `Pinned`" | plain | no current entry; the old hint ("declare it `T`") is in D-166 Rationale log 5654, superseded | B: N, or S-by-history |
| 107 | 4075–4079 | the embedding is exact; this scopes the convert-on-write rejection to the nominal check | plain | D-053 (cited) Position; the exactness argument is D-079 Rationale log 2263–2266 | C |
| 108 | 4083–4092 | stripping is the stop-gradient idiom; "**The pinned leaf is the schema-visible freeze.**"; stripping at an unpinned leaf "remains legal" | bold sentence | D-079 Rationale log 2266–2268; D-266 Position bullet 2 (the `Freeze` block strips) | B: R by D-079; or U by D-266 for the pinned-output case |
| 109 | 4094–4098 | `x_deriv` checks against `X`'s shape at `T` | bold lead-in | D-053 Position (uniform across `f`); D-190 Position | U |
| 110 | 4098–4101 | guards against predicate form, `s_update` against `s` shape, handlers against the return law | plain | D-053 Position | U |
| 111 | 4101–4105 | `x_projection` checks **complete** against `X` at `T` | bold word | D-111 Position | U |
| 112 | 4107–4110 | handler key set checked first; unknown key a build error with did-you-mean against `{x, m}` | bold lead-in | D-090 Position; did-you-mean in D-090 Rationale log 2570 | U |
| 113 | 4111–4114 | `x` **complete**, `m` **partial** | bold words | D-053 Position | U |
| 114 | 4114–4116 | an absent key is not an error | plain | D-090 Position | U |
| 115 | 4121–4123 | "**Guards have two admissible forms**", form-aware check | bold sentence | D-053 Position | U |
| 116 | 4123–4124 | guards run only at the nominal activation | plain | D-052 (cited) | C |
| 117 | 4124–4125 | any other probed return type is a build error naming both forms | plain | D-053 Position | U |
| 118 | 4126–4127 | the probed form *is* the detection policy | plain | D-179 (cited) | C |
| 119 | 4129–4131 | payload: path, function, event name on a handler, field diff | bold lead-in | D-053 Position; D-249 bullet 2 (cited) | C |
| 120 | 4131–4135 | simulation time is the carrier's; runtime failure is a `StepError` species | plain | D-249 (cited); D-059 Position (species) uncited | C |
| 121 | 4135–4137 | "Deliberately absent is the source branch" | plain | none found | N |
| 122 | 4137–4139 | "**reproducible by replay**"; the error names the boundary to replay to | bold words | D-053 Position ("reproducible by trace replay") | U |
| 123 | 4139–4140 | the catch site adds the nonfinite-state check | plain | D-059 Position; D-157 Position | U |

Descriptions that read like rules: 4003–4005 (the probe validates once; the
always-on check discharges §8.1's bargain) is framing. 4019–4025 (type-stable,
branch-divergent, unstable code) is mechanism. 4037–4043 ("Pairing by name
costs nothing …") is reasoning. 4080–4087 (why leniency costs nothing) is
reasoning from D-079 Rationale.

Display-block candidates: the two equal returns `(; P = M*ω, M_shaft = M)`
and `(; M_shaft = M, P = M*ω)` (4032); the didactic messages at 4053–4054 and
4074; the strip idiom (declare `Pinned{Float64}`, strip with
`ForwardDiff.value`, 4089–4090) as a short example.

### §9.6 Stopped-sim services as activation clients (4141–4175, 301 words)

Purpose: a sketch of trim, linearization and the generic service loop as
users of activations, pointing to §14.

Subheadings: none. Three bullets, bold lead words "**Trim**",
"**Linearization**".

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 125 | 4159–4163 | the initializer's `atmosphere::Model` argument "becomes a field handle" | plain | D-139 Rationale log 4400 | R |
| 126 | 4173–4175 | "A failed trim leaves the simulation's stores untouched" | plain | D-070 Position bullet 2 | U |

Descriptions: 4148–4150 (trim on the `Dual` activation by default) and
4169–4170 (gradient-based trim is the default) restate §14.7. 4167–4169
(frozen discrete outputs are zero-partial constants) restates §8.2.
4144–4146, 4154–4157 and 4171–4175 compare with Flight.jl (`c172.jl`,
`f_ode!`, NLopt plumbing, `f_init!`) and say "today's" (part F). No display
code.

### §9.7 The compiled executor (4177–4337, 1446 words)

Purpose: the executor's compiled form, its cell storage, its phase bodies and
their arities, compile cost and its mitigation, and the measurement seam.

Subheadings: none. Bold lead-ins as headings: 4196, 4209, 4219, 4247, 4274,
4282, 4290, 4297. One table (4261).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 127 | 4179–4183 | two representations; the executor compiles from `Outputs`' order | plain, cites D-253 | D-253 Position bullet 6 (structural consumers read the products) | B: C by D-253, or a description |
| 128 | 4183–4187 | "**a concretely-typed tuple of entries … compile-time-unrolled walk**" | bold phrase | D-086 (cited) | C |
| 129 | 4187–4190 | a forced move: §7.5, §9.5, §5.1 reachable only under full specialization | plain | D-086 Position | C |
| 130 | 4190–4192 | type parameters carry component type and stage; fields carry divisor, phase, `Δt`, offsets | plain | D-162 Position covers offsets in fields; the rest none found | B: U for offsets; N for the split |
| 131 | 4192–4194 | gating compiles to `(tick − Φ) % D == 0` inside the boundary body | plain | D-147 Position | U |
| 132 | 4196–4203 | "**Cells are stored per element type, not per cell.**" | bold sentence | D-162 (cited) | C |
| 133 | 4209–4217 | "**Phase bodies are the outer decomposition, and they are semantically forced.**" | bold sentence | D-086 Rationale log 2456–2458 | R |
| 134 | 4219–4226 | "**Each sweep block compiles in two arities off one entry list**" | bold sentence | D-147 (cited); names by D-196, uncited | C |
| 135 | 4227 | "`rhs` takes no index" | plain | D-147 (cited) | C |
| 136 | 4227–4228 | one gate serves all three tick-sensitive blocks | plain | D-185 Rationale log 6466–6468 | R |
| 137 | 4229–4231 | "`t*`'s empty due set is **arity selection, not an index trick**" | bold phrase, cites D-147, D-185 | D-147 Position says the due set is empty at `t*`; "arity selection" is D-185 Rationale log 6468 | B: C by D-147; R by D-185 |
| 138 | 4233–4235 | bodies communicate only through stores and table | plain | D-194 (cited) Position bullet 3 | C |
| 139 | 4236–4238 | fusing is an optimization the executor may take or decline | plain | D-194 (cited) | C |
| 140 | 4238–4245 | two doors "recorded, not committed" | plain | D-086 Rationale log 2458 | R |
| 141 | 4247–4254 | "**Chunking bounds the compile cost.**" chunk size the only representation freedom | bold sentence | D-086 Rationale log 2459–2461 | R |
| 143 | 4274–4280 | "**The mitigation ladder**": lazy activations, reduced optimizer level, precompile workloads | bold lead-in | D-086 Rationale log 2461–2462 | R; contradicted by later evidence (part F) |
| 144 | 4282–4288 | "**Views are spelled rebuild-per-call.**" no framework hoisting | bold sentence | D-086 Rationale log 2463 and Rejected log 2474 | R |
| 145 | 4290–4295 | "**Construction is type-opaque, and only the executor specializes.**" | bold sentence | D-086 Rationale log 2464 | R |
| 146 | 4297–4307 | "**The phase bodies are the §7.5 measurement seam.**" `phase_bodies(sim)` and its four blocks | bold sentence | D-116 Position (cited only at 4321); D-147, D-196 | U |
| 147 | 4309–4315 | the four-body roster is fixed and total; empty bodies compile to no-ops | plain | D-156 Position | U |
| 148 | 4317–4322 | "**These are the bodies the loop runs**" | bold phrase | D-116 (cited) | C |
| 149 | 4324–4327 | CI is warm-then-assert at per-body granularity | plain | D-116 Position; D-147 (each arity) | U |
| 150 | 4332–4337 | publication is not a phase body; isolated invocation leaves buffers off-trajectory | plain | D-116 Rationale log 3388–3390 | R |

(142, the measured-anchors table at 4256–4272, is evidence, not a rule.)

Descriptions that read like rules: 4209–4217's per-block properties (order-free,
topologically ordered) follow from §5.3; 4269–4272 interprets the table.

Display-block candidates: the gate `(tick − Φ) % D == 0` (4193); the arities
`sweep_1()`, `sweep_2()`, `sweep_1(tick)`, `sweep_2(tick)`, `ticks(tick)`
(4220–4226); `phase_bodies(sim)` with a short warm-then-assert loop (4298,
4324–4325).

### Tally (§9.1–§9.3, §9.5–§9.7; §9.4 separately)

| section | rules | C | U | R | N | B |
|---|---|---|---|---|---|---|
| §9.1 | 42 | 13 | 20 | 5 | 0 | 4 |
| §9.2 | 28 | 15 | 7 | 4 | 0 | 2 |
| §9.3 | 19 | 8 | 7 | 2 | 1 | 1 |
| §9.5 | 29 | 11 | 13 | 0 | 2 | 3 |
| §9.6 | 2 | 0 | 1 | 1 | 0 | 0 |
| §9.7 | 23 | 8 | 4 | 8 | 0 | 3 |
| total | 143 | 55 | 52 | 20 | 3 | 13 |

§9.4 adds 13 (C 4, U 6, S 1, R 2). Chapter total 156: C 59, U 58, S 1, R 22,
N 3, B 13. Of the bold sentences and lead-ins, about a third are labels
(headings in disguise) rather than rules.

## B. Overlaps

### Inside the chapter

1. **What an activation re-runs.** §9.1 3556–3571 and §9.4 3910–3924. §9.4
   (as v4) states it better: five bullets with reasons and the D-263 fix.
   §9.1's list adds only "observed is compared against declared" (3566–3567),
   which §9.5 owns.
2. **Workspace allocation before the probes.** §9.1 3530–3533, §9.3
   3838–3841, §9.4 3921–3923. §9.3 states it best, in the sourcing context;
   all three cite D-077 for a reason D-115 rules.
3. **Final divisors wait for `Δt_base`.** §9.1 3502–3504, §9.2 3714–3718,
   §9.2 3772–3773. §9.2 3714–3718 is best: it gives the reason (one `Build`
   backs many deployments).
4. **`Build` immutability, concurrency, torn-state freedom, single-owner
   buffers.** §9.2 3661–3663 and 3679–3684; §9.4 3977–4000. §9.4 is the home
   (D-135). §9.2 adds "under the lock", which conflicts with §9.4 (part F).
5. **The probed function set.** §9.1 3420 (table: "the stage functions,
   guards and handlers"), §9.3 3815–3817, §9.3 3879–3881. §9.3 3815–3817 is
   right and complete; the table is short of `x_deriv`, `s_update` and
   `x_projection`.
6. **Warnings.** §9.1 3644–3655 and §9.2 3797–3810. Two halves of one policy
   (D-250) in two sections.
7. **What the `Deployment` holds.** §9.1 3575–3587, §9.2 3665–3670,
   3720–3722, 3775–3779. Four places, each naming part of D-254's list.
8. **The grid-diagnostic refusal.** §9.1 3605–3607 points forward to §9.2's
   suggestion message; §9.2 3775–3805 states it. §9.2 is better.
9. **What `Structure` holds.** §9.1 3509–3515, §9.2 3686–3689, 3694–3718. §9.1
   gives the list; §9.2 the printable view. Both are needed but restate
   members.
10. **`Outputs` and the execution order.** §9.1 3521–3526, §9.2 3688–3689,
    §9.7 4179–4183. §9.1 states it; the others gloss it.
11. **Probe-scoped clock values.** §9.3 3836–3838 (`t`) and 3868–3871 (`Δt`),
    in two paragraphs of one section, with the reason split between them.
12. **Probe earliness versus the always-on backstop.** §9.3 3820–3823 and §9.5
    4003–4005. Each is short; §9.5's framing is better.
13. **Interior and boundary arities.** §9.7 4193–4194, 4219–4231, 4297–4304.
    4219–4231 states it; the other two repeat parts.
14. **Barriers.** Intro 3398–3401, §9.1 3413–3415, §9.1 3646–3647. §13.1
    8301–8303 is the home.
15. **Trim's default.** §9.6 4148–4150 and 4169–4170, in one section.
16. **The nominal evaluation's products are structural.** §9.1 3545–3546 and
    3548–3552, and §9.4 3926–3930. §9.4 (v4, D-253) is the rule's home; §9.1
    3548 the reason.

### Other chapters, prominent cases

| content | chapter 9 | elsewhere | better |
|---|---|---|---|
| the worked binding example (fcs, gnss, inner, outer at `Δt_base = 2 ms`) | §9.2 3757–3773 | §10.5 5051–5070, with the declarations as code | §10.5 for the declarations; §9.2's table for the binding |
| face-route printing | §9.2 3744–3747 | §13.7 8991–9000, nearly verbatim, with an example and a reason | §13.7 |
| every artifact renders itself through `show` | §9.2 3738–3743 | §13.7 8980–8989 | §9.2 |
| `Δt_base`'s three sources | §9.1 3589–3598 | Appendix B 10827–10828, 10833–10838 | §9.1; Appendix B contradicts it (part F) |
| the constraint pool and why attribution is the engine's | §9.1 3609–3618, §9.2 3775–3795 | §10.5 5045–5049 | §10.5 for the "why"; §9 for the arithmetic |
| views rebuild-per-call, hoisting is CSE | §9.7 4282–4288 | §7.1 1541–1546 | §7.1 states the legality condition better |
| pre-materialize for parallel sweeps | §9.4 3961–3963 | §11.1 5546–5552; Appendix B 10796–10799 | §11.1 |
| probe values never initial values | §9.3 3865–3868 | §14.6 9712–9722 (the probe-value barrier) | §14.6 |
| barrier and collection policy | intro 3398–3401, §9.1 3413–3415 | §13.1 8259–8317 | §13.1 |
| names are the pairing | §9.5 4027–4047 | §14.7 9783–9795 defers to §9.5 | §9.5 (no duplication, just a pointer) |

## C. Proposed structure

### The main choice: where the `Deployment` lives

§9.1 is titled "The build's three steps" but hosts the `Deployment`
constructor (3573–3642), which is not one of them. §9.2, titled "The `Build`
artifact", already spends most of its length on the `Deployment`: the
`Schedule`, the chart, the example and the grid diagnostics. Deployment
content is split across two sections (overlaps 3, 7, 8).

Three options:

- **A (recommended).** Move all deployment content into §9.2 and retitle §9.2
  "The `Build` and `Deployment` artifacts". No renumbering. The retitle
  changes the slug `#92-the-build-artifact`. `linkify.jl` regenerates the
  definitions in `spec.md`, `decisions.md`, `extensions.md` and the linkified
  companions, including `sample_time_proposal.md` (802). The Contents entry
  (line 50) changes by hand. Cost: about 30 inbound citations retarget from
  §9.1 to §9.2 (part D). §9.1 drops to about 1100 words, §9.2 rises to about
  2300 and then needs `####` topic labels.
- **B.** A new §9.8 "Deployment" at the chapter's end. Same retargeting cost,
  one more section, and the pipeline order breaks: the executor (§9.7) is
  compiled at materialization, after deployment.
- **C.** Keep the split and only cross-link. No cost, and overlaps 3, 7 and 8
  stay.

Inserting a section before §9.3 to keep pipeline order would renumber §9.3 to
§9.7: 245 inbound citations (§9.3 46, §9.4 41, §9.5 87, §9.6 10, §9.7 61), and
the log's visible "§9.x" text with them. Not worth it.

### Moves (under option A)

| move | content | from | to |
|---|---|---|---|
| M1 | the retyping list of "Activation, parametric in `T`" | §9.1 3559–3568 | merged into §9.4's re-run list (v4 already holds it); §9.1 keeps 3556–3558 and one pointer sentence |
| M2 | "The `Deployment` constructor", whole | §9.1 3573–3642 | §9.2, a `####` "The `Deployment`" block after the `Build` material |
| M3 | "Where a build warning lives" | §9.1 3644–3655 | §9.2, a `####` "Warnings" block, joined with 3804–3810 (optional; see part D) |
| M4 | the lock clause and the immutability argument | §9.2 3661–3663, 3680–3684 | dropped to one pointer to §9.4; §9.2 keeps the bold sentence at 3679–3680, which inbound citations rely on |
| M5 | the standalone-`build` justification (CI, acceptance tests, `attach!`, D-049) | §9.2 3701–3704 | up beside 3659 and 3665–3677, its subject |
| M6 | route printing | §9.2 3744–3747 | §13.7 holds it; §9.2 keeps one sentence with a pointer |
| M7 | the example's declarations in prose | §9.2 3758–3760 | replaced by a pointer to §10.5's code block (5056–5063); the binding table stays |
| M8 | workspace allocation before the probes | §9.1 3530–3533 | §9.3 3838–3841 is the home; §9.1 keeps a pointer |
| M9 | `t` and `Δt` probe values | §9.3 3835–3838 and 3866–3871 | one paragraph in §9.3, after root-input synthesis |
| M10 | D-051's three rejected alternatives | §9.3 3862–3863 | deleted; D-051's Rejected list holds all three (needs the user's ruling) |
| M11 | the chapter intro's §13.1 summary | 3398–3401 | one sentence and a pointer; the intro gains a roadmap sentence |
| M12 | duplicated trim default | §9.6 4169–4170 | deleted; 4148–4150 states it |
| M13 | Flight.jl comparisons | §9.6 4144–4146, 4154–4163, 4171–4175 | `companions/flight_case_studies.md`, per `spec_style.md` "Rationale" (needs the user's ruling; it moves D-139's §9.6 anchor) |

### Order within each section

- **Intro.** What the build consumes and produces; one sentence on §13.1's
  policy; roadmap of §9.1–§9.7.
- **§9.1.** Context: the three ordering constraints (3405–3412). Rule: the
  steps and barriers (D-259), then the table. Then `####` "The structure step"
  (walk order, checks, `sample_times` validation and fold, `Structure`),
  `####` "The nominal evaluation" (products, order of work, the "fixes
  structure and typing at once" rule), `####` "Activation" (inputs, output,
  pointer to §9.4). The table's deployment and materialization rows stay, with
  a pointer to §9.2.
- **§9.2.** `####` "The `Build`": what it is, the factorization and its
  reason, immutability with a §9.4 pointer, the inspectable contract, the
  two-sided face table, the anchor-relative timing tables. `####` "Rendering":
  the artifact rule (D-261), `show` per artifact, the chart and its guard.
  `####` "The `Deployment`": constructor, `Δt_base` sources, the constraint
  pool, validation, the `Schedule`, the worked example. `####` "Grid
  diagnostics". `####` "Warnings".
- **§9.3.** Context. Rule: probe everything once (D-050). Argument sourcing,
  then the shape and dead-stage checks, then root-input synthesis, then probe
  scoping (inputs, `t`, `Δt`), then the totality contract and its three
  dispositions. The 500-word paragraph splits at each of these.
- **§9.4.** Land v4. Absorb nothing more than M1.
- **§9.5.** Context (4003–4005). Rule: the check at the generated write
  (D-235). The acceptance relation: exact at nominal, embed at walking leaves,
  identity at opaque leaves, exact at pinned leaves, then the stop-gradient
  reasoning. The per-function predicates: `x_deriv`, `x_projection`,
  handlers, guards. Names are the pairing (applies to all). Failure payload.
  Topic labels only if the section stays above about 1200 words.
- **§9.6.** One context paragraph and three short bullets, each an activation
  and a pointer to §14.7, §14.8, §14.10.
- **§9.7.** Representation and why it is forced. Cell storage. Phase bodies,
  arities and seams. Views and type-opaque construction. Compile cost
  (chunking, anchors, ladder), held until the pending ruling. The measurement
  seam last, since §7.5 and Appendix B point at it.

## D. Inbound citations

The full list is `inbound.tsv` (beside this file): 389 rows, one per
"§9.x" occurrence outside chapter 9 and outside the Contents block. By file:
`decisions.md` 187 (Spec fields 115, Rationale 39, Position 19, Rejected 14),
`spec.md` 141, `implementation.md` 26, `sample_time_proposal.md` 15,
`handle_walk_walkthrough.md` 4, `extensions.md` 4,
`trim_environment_walkthrough.md` 3, `pending.md` 3, two each in
`frozen_discrete_walkthrough.md`, `linearization_walkthrough.md` and
`migration_outline.md`. By section: §9.1 90, §9.5 87, §9.7 61, §9.2 54, §9.3
46, §9.4 41, §9.6 10. (`spec.md` has 141 against the brief's 139; the script
counts each end of a range and each repeat in one sentence.)

### Citations relying on moved content

M2, the `Deployment` (§9.1 → §9.2):

| file:line | fact relied on | after |
|---|---|---|
| spec 3196 (§8.7) | `Δt_base`'s three sources | §9.2 |
| spec 4798 (§10.4) | event parameters stand beside `h`, `N_base`, the algorithm | §9.2 |
| spec 5046 (§10.5) | the deployment-time constraint pool | §9.2 |
| spec 5054 (§10.5) | a deployment binds `Δt_base` | §9.2 |
| spec 6343 (§12.1) | where the `Deployment` comes from | §9.2 |
| spec 6372 (§12.1) | the `Deployment` constructor | §9.2 |
| spec 7793 (§12.6) | grid and event parameters are the deployment's | §9.2 |
| spec 8304 (§13.1) | deployment validation throws once | §9.2 |
| spec 10827, 10828, 10833 (Appendix B) | `N_base`, `Δt_base`, the three sources | §9.2 |
| spec 11379 (Appendix C) | `DeploymentInvalid` | §9.2 |
| spec 11457 (Appendix C) | `GridUtilization` (cites §9.1, §9.2) | §9.2 alone |
| spec 11868, 11898 (Appendix D) | anchors join the pool; the harmonic grid | §9.2 |
| spec 3668, 3722 (inside §9.2) | "takes a `Build` and the grid parameters (§9.1)", "The `Deployment` constructor (§9.1)" | internal, no citation needed |
| log 8294 (D-229 Position) | "Deployment validation (§9.1) runs every check …" | §9.2 |
| log 8332 (D-229 Rejected) | "§9.1 and §10.4 both spell deployment validation collected" | §9.2 |
| `implementation.md` 495 | "The `Deployment` constructor has one throw per call (§9.1, D-229)" | §9.2 |
| `sample_time_proposal.md` 304, 335 | deployment binding and `DeploymentInvalid` in §9.1 | §9.2, if the adopted proposal is kept current at all |

Unaffected though they cite §9.1 near this content: spec 5043 ("the fold,
§9.1") stays, since the fold stays in the structure step. Spec 10821 and 12069
already cite §9.1 and §9.2 together; after the move §9.1 is redundant but not
wrong, since §9.1's table keeps the deployment row.

M3, warnings (§9.1 → §9.2):

| file:line | fact relied on | after |
|---|---|---|
| spec 3233 (code comment in §8.8) | "`EmptyFaceSelection` … through §9.1's channel" | §9.2 |
| spec 3272 (§8.8) | `EmptyFaceSelection` is a warning on the `Build`'s list | §9.2 |
| spec 8424 (§13.2) | cites §9.1, §9.2 | §9.2 alone |
| `pending.md` 90 | a build warning (§9.1, D-250) | §9.2 |

If M3 is skipped these four stay. M3 buys one home for D-250 at the cost of
three edits.

M1, activation retyping (§9.1 → §9.4):

| file:line | fact relied on | after |
|---|---|---|
| spec 2303 (§8.2) | "Cell types are single-sourced from the producer side per activation (§9.1)" | §9.4 |
| spec 12095 (Appendix D) | the marker is "applied at activation, §9.1" | §9.4 |

M13, Flight.jl content of §9.6 (only if the user rules it out of the spec):

| file:line | fact relied on | after |
|---|---|---|
| log 4400 (D-139 Rationale) | §9.6's `Kinematics.Initializer` claim, corrected | the log keeps it as history (rule 1); no edit |
| `trim_environment_walkthrough.md` 6, 502, 576 | §9.6 as ground truth; per-residual scalings aircraft-side; the `Initializer` correction | `flight_case_studies.md` or §14.7 |

M4–M12 move nothing an inbound citation names, as far as the list shows.
Spec 5548 ("One immutable `Build` … (§9.2)") relies on 3679–3680, which M4
keeps.

### Log entries whose Spec field would change

- Lose §9.1, gain §9.2: D-113, D-133, D-227, D-234 (deployment parameters and
  `DeploymentInvalid`); D-187 and D-254 (lists §9.1 and §9.2; §9.1 drops).
- Keep §9.1, gain §9.2: D-229 (the barrier stays in §9.1; deployment
  validation moves).
- Keep both: D-186 (the fold stays in §9.1; `Δt_base` and the pool move to
  §9.2).
- Under M3: D-250 drops §9.1.
- Under M1: D-263 keeps §9.1 (the walk-compatibility clause and completeness
  rules stay) and already lists §9.4. D-079 lists neither §9.4 nor §9.5 though
  its walk and conformance doctrine sit there.
- Under M13: D-139 drops §9.6.

Whether these Spec-field edits are licensed: `decisions_style.md` rule 2's
citation exception covers renumbering ("every entry … cites the CURRENT §
numbering"). A content move is not a renumbering. The rewrite needs a ruling
that the exception extends to moved content.

## E. Log repairs the rewrite would need

### Entries to cite at the rule

From part A's U rows: D-048 (§9.1 rows 1, 4, 5, 6, 21, 23; its vocabulary is
"Stratum A/B"), D-259 (§9.1 rows 2, 3, 25, 29), D-247, D-094, D-231, D-208,
D-078, D-236, D-263 (§9.1 rows 7–12, 28), D-185 (row 13), D-115 (rows 20, 77,
78, 86), D-033 (row 21), D-229, D-113, D-133, D-181, D-227, D-234 (rows
38–40), D-049 (row 43), D-253 at row 45, D-187 (rows 58, 62), D-254 (rows 67,
69), D-050 (row 72), D-194 (row 76), D-149 and D-206 (row 87), D-060 (row 91),
D-151 (rows 97–99), D-190, D-111, D-090, D-053 (rows 109–117, 122), D-059 and
D-157 (rows 120, 123), D-070 (row 126), D-147 (row 131), D-196 (row 134),
D-116 (rows 146, 149), D-156 (row 147). §9.4's five are in the trial report.

### Superseded citations to replace

- §9.4 3956: D-166 (superseded → D-263), replaced by draft D-280 in v4.
- Outside the chapter but in the same family: `implementation.md` 832 cites
  "(§9.4, D-166)".
- No other superseded citation in chapter 9. Row 11's kind name and row 106's
  hint rest on superseded entries' Rationales (D-167, D-166) without citing
  them.

### Rulings that need an entry stating them in a Position

1. `Δt_base`'s binding: three sources, cross-validated; derivation only in an
   all-anchored model; the constraint pool and exact resolution; the
   unanchored-must-declare rule (rows 33–37). All in D-186 Rationale.
2. Derivation requested explicitly as `Δt_base = :derive`, never by default
   (row 34). No entry at all; Appendix B 10828 also states it.
3. The `sample_times` fold into `(anchor, m, c)` triples (row 14). D-186
   Rationale.
4. The `Build` is immutable and may back many deployments concurrently (row
   49). D-135 Rationale. Draft D-282 (buffer ownership) may absorb it.
5. "The artifact deployed is the very build CI checked" (row 47). D-119
   Rationale. Borderline: it may be read as the factorization's reason, not a
   rule.
6. The grid-diagnostic details: list every `r_p > 1`; blame against the
   actual pool (rows 65, 68). D-187 Rationale and Rejected.
7. Totality's two non-`Position` dispositions: plausibility to a `Bool` face
   plus `stop_on`, self-consistency asserts to the test suite (rows 92, 93).
   D-142 Rationale.
8. A non-`NamedTuple` stage return fails at the probe (row 75). No current
   entry.
9. The pinned-leaf exact check at every activation, with the misplaced-pin
   error and hint (rows 105, 106). D-079 Rationale; D-166 superseded.
10. The stop-gradient doctrine: stripping legal at an unpinned leaf, the
    pinned leaf as the schema-visible freeze (row 108). D-079 Rationale.
11. Struct-valued ports need a cross-eltype constructor (row 102); the
    payload omits the source branch (row 121). No entry.
12. The executor's structural rulings bundled in D-086 Rationale: phase-body
    decomposition, the two doors, chunking, the ladder, views, type-opaque
    construction (rows 133, 140, 141, 143–145). The ladder and the anchors
    wait on the compile-time ruling in `pending.md` 17–24.
13. One gate for the three tick-sensitive blocks; `t*` as arity selection
    (rows 136, 137). D-185 Rationale.
14. Publication is not a phase body; isolated invocation leaves buffers
    off-trajectory (row 150). D-116 Rationale.
15. §9.4's three, drafted as D-280 to D-282.

### Stale or missing Spec fields, and stale entry text

- D-052: lists §9.5; its executable-set, laziness and caching rulings are
  §9.4's. Add §9.4 (§9.5 4123 does cite it).
- D-099: lists only §14.10; `ProbeDual` is stated in §9.4.
- D-050: no Spec field; its content is §9.3.
- D-048: no Spec field; its content is §9.1. Its Position's "deployment
  binding at `Simulation` construction only" is contradicted by D-254, with
  no annotation or supersession.
- D-119 Rationale log 3489–3490: "deployment binding is unchanged, only at
  `Simulation` construction (D-048)". Same staleness.
- D-187 Position: "the bound schedule on the `Simulation`". D-254 lists this
  as a superseded position (Rejected), but D-187 is "ratified" and not
  annotated.
- D-077 Position: discrete `workspace(::C)` takes no scalar; D-263 bullet 4
  gives both tiers the scalar. No annotation on D-077.
- D-253 last bullet (log 9414): "§9.1 says Stratum B is the nominal
  evaluation's structural half, and the nominal activation is B's products
  plus C's typing". D-259 amended bullet 4 in place, but this bullet still
  says what D-259 and §9.1 3548–3552 deny.
- D-253 bullet 5 "under the existing lock" against D-135's "mechanism
  unspecified".
- D-033 lists §9.7; §9.7 holds nothing of D-033 (checked: no stage membership
  or declaration inventory there).
- D-106 lists §9.7; §9.7 has no roster freeze or `attach!`.
- D-163 lists §9.7; §9.7 has no float-comparison rule.
- D-168 lists §9.5; §9.5 has no fan-out meet.
- Borderline: D-066 lists §9.5 for a "§9.5-style" check it only borrows;
  D-256 lists §9.7, which names none of the executor's fields.

## F. Factual problems noticed

In chapter 9:

1. 3420, the steps table: the nominal evaluation runs "the stage functions,
   guards and handlers, at `Float64`". §9.3 3815–3817 and D-050 add
   `x_deriv`, `s_update` and `x_projection`.
2. 3545: "Both products are structural" follows a sentence naming three
   artifacts (3519–3520); "both" means `Outputs` and `Events` only by
   inference.
3. 3570: "The nominal `Float64` activation runs at build. Other activations
   re-run *only this step*." Under the heading "Activation, parametric in
   `T`" this says the activation step runs at `Float64`. 3548–3552 and D-259
   Rationale log 9746 say the nominal activation is the nominal evaluation's
   product, and a `Float64` run of the activation step "would be a second
   pass".
4. 3593: "today's rule", a stale relative date.
5. 3661: "The first three are the products of §9.1's three steps". Structure,
   outputs and events come from the first two steps.
6. 3663: "under the lock that makes insertion torn-state-free (§9.4)". §9.4
   3997 says "The mechanism is unspecified".
7. 3679–3684: "**The `Build` is immutable**" then "The one mutable thing on
   the artifact is the lazily populated activation dictionary".
8. 3701–3703: "`attach!` validates device bindings against it" sits in the
   face-table paragraph; "it" can be the face table or the `Build`.
9. 3723–3726: "one row per discrete component carrying `(D, Φ, Δt)` with the
   anchor and rate-chain columns, the rate-scope rows (…) each with its own
   `(Dₛ, Φₛ)`." The list lacks its conjunction and reads as one row type.
10. 3738–3743: `show` is listed for `Structure`, `Outputs`, `Schedule`,
    `Build`, `Deployment`. D-257's amendments (log 9641–9647) add `show` for
    `Events` and a feedthrough-edges line in `show(::Build)`. Neither appears
    in the spec (no `show(::Events)` anywhere; §13.7 8980–8989 has the same
    gap). 3524–3526 says the graph is derived "wherever it is shown" without
    saying where.
11. 3814: "The nominal activation probes every user function". By §9.1 the
    nominal *evaluation* probes; the activation is its product. Minor.
12. 3868–3869: "`Δt` in seconds does not exist until `Simulation` binds
    `Δt_base`, since deployment post-dates the build". The `Deployment`
    constructor binds `Δt_base` (3577–3579, D-254).
13. 3919: "the walk over `x_init`'s" is truncated (known; v4 fixes it).
14. 3956: D-166 is superseded (known).
15. Missing blank lines before three headings: 3907/3908 (`### 9.4`),
    4000/4001 (`### 9.5`), 4140/4141 (`### 9.6`). The trial report names only
    the second.
16. 4230: cites D-185 for "arity selection, not an index trick"; D-185's
    Position does not state it (Rationale log 6468 does).
17. 4256–4272 and 4274–4280: the anchors table and the mitigation ladder.
    The compile-cost report (`docs/reports/20260930_compile_cost/report.md`
    §4, §7) found the 9 s `Dual` anchor did not reproduce, lazy activation
    saves 2–3 s "not tens", and a reduced optimizer level "buys nothing
    measurable". `pending.md` 17–24 says "§9.7's anchors do not hold" and
    asks for a ruling first. 4272 "Re-measurement … is pending" is half
    stale. D-162 Rationale log 5453 already called the ladder optional.
18. 4144–4175: Flight.jl names (`c172.jl`, `f_ode!`, `f_init!`, NLopt) and
    "today's" in normative text. `spec_style.md` "Rationale" puts Flight.jl
    case studies in `companions/flight_case_studies.md`.
19. 4151–4152: the activation gloss sits on "the nominal `Float64`
    activation", the term's second use in the bullet (first at 4149).

Outside chapter 9, met while checking citations:

20. 3195–3196 (§8.7): "deployment decisions fixed at `Simulation`
    construction". D-254 moved them to the `Deployment` constructor.
21. 4797 (§10.4): "`localization_tol` and `localization_budget` are
    `Simulation` keywords". D-256 bullet 5 makes them `Deployment`
    constructor keywords.
22. 10835–10837 (Appendix B): "The third, in a fully anchored model omitting
    both, is derivation". §9.1 3595–3597 and Appendix B's own table at 10828
    say derivation is requested explicitly with `:derive` and never entered
    by default.
23. 10379 (§14.10): "pre-materialize its activation through `activations`
    (§9.7)". The keyword is §9.4's.
24. 8287–8288 (§13.1): "the stage-1 probes in B and the probe chain in C",
    strata vocabulary D-259 retired.
25. `extensions.md` 191: "Stratum A flattens … absolute divisors", retired
    vocabulary and pre-anchor content.
26. `tools/spec_style.md`, "The battery": "a file checked but not linkified
    keeps plain citations, as `decisions.md` and `implementation.md` do".
    `decisions.md` is first in `linkify.jl`'s `ROSTER` (line 63) and carries
    reference links.

## G. Rewrite difficulty

| section | difficulty | reason |
|---|---|---|
| intro | low | 101 words; add a roadmap sentence, trim the §13.1 summary |
| §9.1 | high | four subjects in one section; 20 uncited rulings, mostly D-048 whose vocabulary is "Stratum"; five rules ruled only in D-186 Rationale; the deployment move |
| §9.2 | high | after M2 and M3 it becomes the chapter's largest section; two internal contradictions (F6, F7); the `show(::Events)` gap; the example shared with §10.5 |
| §9.3 | medium | one 500-word paragraph to split; three display blocks; one stale fact (F12); a deletion needing a ruling (M10) |
| §9.4 | low | v4 exists; land it with D-280 to D-282 and absorb M1 |
| §9.5 | high | the densest type reasoning in the chapter; a 600-word paragraph; 13 uncited rulings; the pinned-leaf and stop-gradient doctrine lives only in D-079 Rationale |
| §9.6 | low, after a ruling | short; the open question is whether its Flight.jl content stays |
| §9.7 | high, and blocked | the anchors table and ladder wait on a ruling; six rulings live only in D-086 Rationale |

Warnings for the rewriter:

- Do not touch §9.7 4247–4280 before the compile-time ruling in `pending.md`.
  Reorder around it.
- §9.5's words "exact", "identity", "embed", "lift" and "accepts exactly two
  types" are terms of art from D-235, D-237, D-238. The v1 round of the trial
  showed how a softened modal ("no path needs" for "with no … on any path")
  slips through. Keep each verbatim or check it against its entry.
- The fold table (3492–3496), the constraint-pool table (3611–3618) and the
  gate formula are mathematics; carry them over unchanged.
- The log speaks of "Stratum A/B/C", `Dataflow`, `h_x`, `f`, `project`,
  `workspace`. Never import those into the spec when quoting an entry.
- Land v4 first, so §9.4's anchors and D-280 to D-282 exist before §9.1 and
  §9.2 point at them.
- Bold lead-ins in §9.2, §9.3, §9.5 and §9.7 are headings, not rules. Under
  the convention they become `####` topic labels or plain text. Count them
  before and after, because the bold check flags any bold span without a
  D-citation.
- Glossary links reset per section. Moving 70 lines from §9.1 to §9.2 changes
  which use is first in each.
- Keep the three missing blank lines in mind (F15); `linkify.jl` and the
  battery do not flag them.
