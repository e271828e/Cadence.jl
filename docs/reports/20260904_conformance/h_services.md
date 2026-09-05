# Agent H — §14 stopped-sim services

## 1. Header

- **Agent**: H
- **Slice**: §14, stopped-sim services (§14 header through §14.10)
- **Spec lines**: 7645–8851 of `docs/design/spec.md`
- **Tip**: `70672d1`, Julia 1.12.7
- **Probes run**: one. `scratchpad/p1.jl` under `julia --project=.`, listing
  which §14 names are defined in `Cadence` and exercising `at` over a
  `TrimProblem` and over a `reads(…)` value.
- **Forbidden reads**: none. I read `docs/design/spec.md` 7645–8851, the cited
  passages in §9.4, §10.6, §11.2, §11.5, §12.6 and §13.1 for meaning only, the
  "What is real here" file table in `docs/design/implementation.md`, and all of
  `src/` and `test/`. I did not open `pending.md`, `reports/`,
  `docs/design/briefs/`, the rest of `implementation.md`, or any other agent's
  report.

## 2. Summary

Three of the four services are built, and built close to the spec. The
condition algebra (§14.1–§14.6) is the strongest part of the slice: the four
node kinds have the shapes §14.2 gives them, composition performs no path
arithmetic, resolution is one collecting pass shared by both application
registers, the lens/converter bake is where §14.3 puts it, the specialized
register proves shape by dispatch and closes the remainder with a `===` prefix
sweep, and root-input totality is a pre-write plan-level comparison at all
three sites §14.6 names. `init!` runs boundary zero as §14.5 describes it,
including the `ESTABLISH` amendment (every discrete output stage publishes, due
or not) and the not-holding guard priors. `trim!` implements §14.7 and §14.8
almost row for row, D-213's two-half scratch world included, and the report
carries every field the spec enumerates.

The gaps cluster in two places, and both are whole subsections.

**Linearization (§14.10) is not built at all.** There is no `linearize`, no tap
declaration, no `about` keyword, no `A`/`B`/`C`/`D` gather, no `LinearizedSS`,
no `subsystem`/`delete_vars`, and no `design_world`. The probe confirms none of
those names is defined. Everything §14.10 needs *underneath* exists — the five
selectors carry the optional index, the compiled reader is the gather twin, the
zero-partial embedding is baked per leaf, the discrete tier is frozen at a
seeded activation, `capture` produces the default operating point — so the
missing piece is the service itself and its tap-resolution rejections, not its
substrate. That absence also drags §14's lifecycle table (two of five rows) and
§14.4's "load-bearing services" claim down with it.

**Mounting (§14.9) is not built.** `at` has exactly two methods, one taking a
condition node and one throwing `ConditionNodeMisuse` at everything else. There
is no `at(::String, ::TrimProblem)` and no `at(::String, ::Reads)`; the probe
shows both spellings raising the misuse error. The flattening half of §14.9 —
the accumulator entering a `Scoped` wrapper, an input face resolving through
the export chain from the mount point — is real and tested, so a *hand-scoped*
condition mounts correctly. What is missing is the five-line lift that makes a
whole problem relocatable, which is the section's entire point.

Smaller deviations: the derivative-free fallback register (`NLoptBackend`, the
normalized $\sum(r_i/tol_i)^2$ objective at `stopval = 1`) is absent, so §14.8's
per-register tolerance translation exists on one register only; §14.3's
did-you-mean over children is missing on the path arm of condition resolution
(fields and faces do carry candidate lists, paths do not); `ServiceLifecycle`'s
`legal` payload column is filled at `capture` and left empty at `init!` and
`trim!`; and `capture` reads the stores back with its own walk rather than
through the compiled reader, so §14.4's "one machinery, both directions" is one
machinery in the write direction and two in the read direction.

What surprised me: `trim!` refuses a non-nominal `Simulation` outright with
`ArgumentInvalid(:non_nominal)`, a refusal the spec never asks for and which
looks right — the commit runs on the sim's own nominal stores. And the LM
backend's descent test is measured in tolerance units (`_scaled_norm`), which
is not stated in §14.8 for the LM register but follows from its reasoning about
the fallback; it is a strictly better reading of the spec than the literal one.

## 3. Findings table

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| §14 (7658) | every service requires a non-running sim; pause is inside a run, so the prohibition holds while paused | accurate | `sim.jl:611`, `trim.jl:386`, `conditions.jl:815` | `test_trim.jl:502`, `test_readers.jl:183` | pause never leaves `:running` |
| §14 (7669) | `capture`: error in `built`, legal in `initialized`/`stopped` | accurate | `conditions.jl:815` | `test_readers.jl:183` | |
| §14 (7670) | `init!`: legal in `built`/`initialized`/`stopped` | accurate | `sim.jl:608-612` | `test_lifecycle.jl` | only `:running`/`:errored` refused |
| §14 (7671) | `trim!`: legal in all three stopped states; the scratch world is `override(baseline, condition(guess))`, never the sim's stores | accurate | `trim.jl:383-405`, `trim.jl:499-501` | `test_trim.jl:502`, `test_trim.jl:152` | |
| §14 (7672) | `linearize` defaulted to `capture(sim)`: error in `built`, legal elsewhere | absent | — | — | see 4.1 |
| §14 (7673) | `linearize` with explicit `about`: legal wherever `init!` is | absent | — | — | see 4.1 |
| §14 (7675) | `errored` is terminal for all four services | short | `sim.jl:612`, `trim.jl:387`, `conditions.jl:815` | `test_readers.jl:183`, `test_trim.jl:502` | three of four; the fourth does not exist |
| §14 (7676) | post-mortem read of an errored sim's stores, log and trace stays available, but may not become a condition | accurate | `conditions.jl:815`, `trace.jl:236` | no test | `capture` is the only gated reader |
| §14 (7681) | a violation is `ServiceLifecycle` carrying operation, current status and legal statuses | short | `diagnostics.jl:721-747` | `test_readers.jl:183` | see 4.2 |
| §14 (7684) | `ServiceLifecycle` is distinct from `MissingInit` | accurate | `diagnostics.jl:706-718`, `721-725` | `test_lifecycle.jl` | |
| §14.1 (7692) | a condition specifies `x` (continuous), `s` (discrete) and `m` (continuous only), addressed by slash path plus field name | accurate | `conditions.jl:333`, `442-443` | `test_conditions.jl:134` | `init_m` defaults empty (`declare.jl:37`), so `m` on a discrete component is `:no_store` |
| §14.1 (7696) | it may also specify root inputs, addressed by face | accurate | `conditions.jl:412-430` | `test_conditions.jl:172` | |
| §14.1 (7697) | never outputs, never workspace | accurate | `conditions.jl:448-457` | `test_conditions.jl:163` | the refusal names which family the field belongs to |
| §14.1 (7698) | entries validated in the §13.1 collecting register: full list, violations collected, one `BuildError` | accurate | `conditions.jl:310-347`, `473-476` | `test_conditions.jl:134` | |
| §14.1 (7702) | the overlay base is always the declared defaults; applying means "fresh run from the `init_*` defaults with these overrides" (D-063) | accurate | `sim.jl:615-617`, `build.jl:811` | `test_conditions.jl:256`, `test_conditions.jl:269` | scratch executors get the same reset via `compile` (`build.jl:898`) |
| §14.1 (7708) | `capture` reads the current stores **and root inputs** back as a condition value | accurate | `conditions.jl:813-835` | `test_readers.jl:154` | |
| §14.1 (7710) | root-input coverage is what makes the captured condition total, hence re-applicable | accurate | `conditions.jl:831-833` | `test_readers.jl:154` | |
| §14.1 (7712) | that gather is the one the trace header already needs: one mechanism, two uses | short | `conditions.jl:813` vs `trace.jl:277` | no test | see 4.3 |
| §14.1 (7714) | doctrine: path addressing does not reopen the observation-by-path rejection | n/a | — | — | rationale |
| §14.1 (7723) | pre-sweep doctrine and the two escapes | n/a | — | — | rationale |
| §14.2 (7747) | fragment functions are ordinary functions shipped beside the component and dispatched on it | accurate | `conditions.jl:60-66` | `test_conditions.jl:329` | the idiom lives in `test/fixtures.jl`; the framework ships `fragment` |
| §14.2 (7767) | the three combinators are constructors of an inert, lazy tree; no path arithmetic at composition | accurate | `conditions.jl:75`, `87`, `110` | `test_conditions.jl:35` | |
| §14.2 (7770) | `Fragment{X,S,M,L}`, `Scoped{N}`, `Combined{T<:Tuple}` with those fields | accurate | `conditions.jl:20-39` | `test_conditions.jl:35` | |
| §14.2 (7775) | every node is isbits except the prefix strings | accurate | `conditions.jl:20-48` | `test_conditions.jl:48-49` | |
| §14.2 (7783) | `fragment`'s payloads speak only about the authoring level; addressing children is exclusively `at`'s job | accurate | `conditions.jl:150-165` | `test_conditions.jl:329` | |
| §14.2 (7785) | an `inputs` payload names faces of the authoring level's contract; resolution walks the export chain to the root input and errors if the face never surfaces | accurate | `conditions.jl:412-430` | `test_conditions.jl:172` | |
| §14.2 (7791) | an internally-wired input has no root input behind it and writing it is refused | accurate | `conditions.jl:426-429`, `diagnostics.jl:1014` | `test_conditions.jl:172` | |
| §14.2 (7801) | an `at` prefix may stop at any child's faces, owned or generically held (D-207) | accurate | `conditions.jl:418-427` | `test_conditions.jl:198` | |
| §14.2 (7807) | the locality law is convention, not machine-checked | n/a | — | — | stated as unenforceable |
| §14.2 (7813) | a `combine` collision is an error at resolution reporting both provenance chains, with a message naming `override` | accurate | `conditions.jl:200-213`, `diagnostics.jl:1051` | `test_conditions.jl:54` | |
| §14.2 (7820) | `combine` is not `Base.merge` and does not extend it (D-204) | accurate | `conditions.jl:87` | no test | |
| §14.2 (7823) | blending a node with a bare NamedTuple is an error method with a directive message | accurate | `conditions.jl:93-95`, `diagnostics.jl:1062-1070` | `test_conditions.jl:113` | both argument orders plus a variadic fallback |
| §14.2 (7827) | the kind is `ConditionNodeMisuse`, carrying the offending argument's type and the node kinds in hand | accurate | `diagnostics.jl:1056-1060` | `test_conditions.jl:113` | |
| §14.2 (7829) | it is raised at composition time, before any resolution pass | accurate | `conditions.jl:116-117` | `test_conditions.jl:113` | |
| §14.3 (7834) | flattening is the only place path strings are concatenated; the recursion carries a path accumulator and records each entry's tree position | accurate | `conditions.jl:150-196` | `test_conditions.jl:35` | |
| §14.3 (7841) | check: the path resolves, with did-you-mean over children | short | `conditions.jl:397-403` | `test_conditions.jl:134` | see 4.4 |
| §14.3 (7843) | check: the field is declared in `init_x`/`init_s`/`init_m` | accurate | `conditions.jl:338-339`, `448-454` | `test_conditions.jl:134` | candidate list carried |
| §14.3 (7844) | check: the value type converts to the declared leaf type | accurate | `conditions.jl:341-342`, `381-386` | `test_conditions.jl:483` | |
| §14.3 (7845) | check: input faces reach root inputs | accurate | `conditions.jl:412-430` | `test_conditions.jl:172` | |
| §14.3 (7846) | check: no `(path, store, field)` is duplicated | accurate | `conditions.jl:200-213`, `316` | `test_conditions.jl:54` | an input entry's leaf is the resolved root input (`conditions.jl:147`) |
| §14.3 (7848) | Schema is the authority (may you write, at what type); Layout is the destination | accurate | `conditions.jl:310-347` | no test | |
| §14.3 (7857) | a valid list compiles to a plan holding, per leaf, a `Getter{P}` lens, a destination offset and a converter | accurate | `conditions.jl:551-577`, `649-700` | `test_conditions.jl:384` | |
| §14.3 (7862) | **Rule**: the converter is baked now, selected per leaf from that leaf's type in the resolved shape | accurate | `conditions.jl:575-577`, `341` | `test_conditions.jl:483` | |
| §14.3 (7873) | a leaf already at the activation's scalar takes the type's ordinary `convert`, partials flowing through | accurate | `conditions.jl:577` | `test_conditions.jl:483`, `test_trim.jl:475` | |
| §14.3 (7883) | a plain `Float64` leaf against a non-nominal activation takes the zero-partial embedding | accurate | `conditions.jl:577` | `test_conditions.jl:483` | `convert(Dual, ::Float64)` is that embedding |
| §14.3 (7891) | a decision value authored into a frozen or pinned leaf is refused | accurate | `conditions.jl:464-470`, `diagnostics.jl:1036-1039` | `test_conditions.jl:483` | |
| §14.3 (7893) | converters run on the write paths and in `capture`'s gather, never on state views | accurate | `conditions.jl:840-847` | no test | `_capture_x` reconstructs, converts nothing |
| §14.3 (7895) | overlay partiality for `s`/`m` is baked as `merge(defaults, overlay)` with the base resolved at compile time | accurate | `conditions.jl:280-285`, `598-618` | `test_conditions.jl:419` | |
| §14.4 (7907) | resolve-once/execute-many, two registers over one plan | accurate | `conditions.jl:514-525`, `744-750` | `test_conditions.jl:384` | |
| §14.4 (7918) | specialized `apply!` unrolls stores through the baked lenses and converters: zero-alloc, no strings, no dispatch | accurate | `conditions.jl:744-762` | `test_conditions.jl:408`, `test_trim.jl:492` | `@ballocated == 0` |
| §14.4 (7922) | the tree type is proven by dispatch, carrying nesting, field names and leaf types | accurate | `conditions.jl:744`, `752-753` | `test_conditions.jl:431` | |
| §14.4 (7924) | a `===` sweep over the prefix strings closes the remainder; `===` on strings compares content | accurate | `conditions.jl:764-774` | `test_conditions.jl:459` | |
| §14.4 (7929) | shape drift is `ConditionShapeDrift`, a structured error rather than silent corruption | accurate | `conditions.jl:776-781`, `diagnostics.jl:1216-1236` | `test_conditions.jl:431` | both arms: `:tree_type` and `:prefix` |
| §14.4 (7937) | the dynamic walk executes the same validated entry list by runtime dispatch, allocation permitted, no per-shape codegen | accurate | `conditions.jl:514-525` | `test_conditions.jl:384` | |
| §14.4 (7943) | **Rule**: which register a service uses is internal, never user-facing API | accurate | `trim.jl:405` vs `trim.jl:443` | no test | |
| §14.4 (7945) | a compiled plan or reader carries its activation and applies only to a store set of that activation, as a framework invariant | accurate | `conditions.jl:527-528`, `755-756`, `readers.jl:202`, `build.jl:865` | `test_readers.jl:126` | |
| §14.4 (7953) | the read-selector family is closed: `get_state`, `get_deriv`, `get_output`, `get_input`, `get_face` with those signatures | accurate | `readers.jl:53-94` | `test_readers.jl:41` | |
| §14.4 (7958) | the `get_` prefix rationale | n/a | — | — | rationale |
| §14.4 (7963) | there is no selector for a value a component computes without declaring it | accurate | `readers.jl:300-367` | `test_readers.jl:77` | only cells and stores are addressable |
| §14.4 (7967) | `get_face` addresses a root-exported output face — the integration register | accurate | `readers.jl:356-367` | `test_readers.jl:41`, `test_readers.jl:77` | `:root_input_not_face` discriminates the near miss |
| §14.4 (7971) | **Rule**: a selector resolves against a source, before any client policy applies | accurate | `readers.jl:241-251`, `bindings.jl:157-186` | `test_readers.jl:114` | |
| §14.4 (7973) | the table selectors resolve against a table source; the store selectors only against live stores | accurate | `readers.jl:79-80`, `166-176`, `bindings.jl:157` | `test_readers.jl:114` | |
| §14.4 (7984) | a snapshot-bound reader naming a store selector is a resolution error at attach, `ReadBindingUnresolved`, in the didactic register | accurate | `bindings.jl:157-159`, `diagnostics.jl:940-970` | `test_readers.jl:114` | |
| §14.4 (7993) | load-bearing services speak the contract: trim's `reads` and linearization's taps name the five selectors within the locality scopes | short | `readers.jl:113-134`, `trim.jl:304-312` | `test_trim.jl:229` | trim's half is built; linearization's taps do not exist |
| §14.4 (8007) | diagnostic readers admit the whole family within the source rule | accurate | `bindings.jl:157-186` | `test_readers.jl:114`, `test_bindings.jl` | |
| §14.4 (8013) | `stop_on` is not a family client: root-exported `Bool` output faces only | accurate | `diagnostics.jl:749-760`, `sim.jl:280-291` | `test_failures.jl` | §13.5's obligation, restated here |
| §14.4 (8018) | the five-row selector/source table | accurate | `readers.jl:300-367` | `test_readers.jl:41` | folded into the two source rows above |
| §14.4 (8028) | compiled readers are the gather twin: trim's cost read, linearization's Jacobian gather and `capture`'s readback are one primitive | short | `readers.jl:193-202` vs `conditions.jl:813-847` | `test_readers.jl:66` | see 4.3 |
| §14.4 (8034) | the per-iteration ledger, sweep-dominated | n/a | — | — | cost argument |
| §14.5 (8040) | `apply!` establishes the stores at `t₀` | accurate | `sim.jl:617-618` | `test_conditions.jl:256` | |
| §14.5 (8041) | the trace header captures those stores together with the root-input values before anything below runs | accurate | `sim.jl:619-621`, `trace.jl:277-296` | `test_trace.jl` | placement: after `apply!`, before `boundary_zero!` |
| §14.5 (8045) | the init service completes the §10.6 macro-sequence with an empty integrate: project → [sweep → guards → handlers]\* → due `state_update` → first snapshot | accurate | `sim.jl:392-400`, `621-622` | `test_conditions.jl:286` | |
| §14.5 (8050) | project runs, after condition writes as after any other `x` mutation | accurate | `sim.jl:394-395` | `test_conditions.jl:286` | |
| §14.5 (8057) | the sweep runs and **every** discrete output stage publishes, due or not (D-205) | accurate | `sim.jl:396`, `executor.jl:351-352`, `sim.jl:409-410` | `test_conditions.jl:286` | |
| §14.5 (8060) | an offset component is not due but its output stages run at boundary zero all the same; its first consumed sample stays its `Φ·Δt_base` tick's | accurate | `sim.jl:397-398` | `test_conditions.jl:286` | `ticks(0)` gate admits exactly `Φ = 0` |
| §14.5 (8071) | events run; boundary zero establishes every guard prior as not-holding, so a predicate already holding fires at `t₀` | accurate | `sim.jl:540`, `396` | `test_conditions.jl:316` | |
| §14.5 (8079) | suppressing those firings was rejected (D-067) | accurate | `sim.jl:392-400` | `test_conditions.jl:316` | nothing suppresses |
| §14.5 (8084) | the firings are recomputed under replay, never recorded | accurate | `sim.jl:782` | `test_trace.jl` | replay re-runs `boundary_zero!` |
| §14.5 (8089) | due `state_update` calls run, `s(1)` sitting in the store before `t₁` | accurate | `sim.jl:397-398` | `test_discrete.jl` | |
| §14.5 (8092) | the boundary-transition table (incoming transitions replaced by authorship) | n/a | — | — | taught contract, no new obligation |
| §14.5 (8104) | `t₀` is an init-service argument with default `0.0`, never a condition entry; both entry points carry it with the same default | accurate | `sim.jl:608`, `trim.jl:384` | `test_trim.jl:457` | |
| §14.5 (8110) | conditions are time-free; `capture` returns condition and time separately for resume-at-time | accurate | `conditions.jl:834` | `test_readers.jl:154`, `test_trim.jl:457` | |
| §14.5 (8113) | trim is untouched: iterations are raw write → sweep → read, no boundaries, no events, no `state_update` | accurate | `trim.jl:441-460`, `sim.jl:326-332` | `test_trim.jl:475` | |
| §14.5 (8117) | a guard firing at commit is a wanted failure signal, and the channel that says so is the trim report | accurate | `trim.jl:563-565` | `test_trim.jl:408` | |
| §14.5 (8123) | boundary zero's first act is `state_projection`, so the committed `x` is `state_projection(x*)` | accurate | `sim.jl:394-395` | `test_trim.jl:422` | |
| §14.6 (8135) | totality is a precondition of starting, checked by the service at `init!`, trim setup and trim commit — one class, one mechanism, one kind | accurate | `conditions.jl:493-498`, `sim.jl:614`, `trim.jl:404` | `test_conditions.jl:225`, `test_trim.jl:352` | commit's check rides `init!` |
| §14.6 (8142) | each compares the resolved plan's root-input coverage against the `Build`'s `input_faces` before writing anything | accurate | `conditions.jl:493-497` | `test_conditions.jl:225` | |
| §14.6 (8145) | a shortfall is one collected, declaration-ordered `UninitializedInputs` naming every uncovered face | accurate | `conditions.jl:495-497`, `diagnostics.jl:1073-1081` | `test_trim.jl:352` | order is `flat.root_inputs`, the declaration walk |
| §14.6 (8146) | coverage is a plan-level fact, so the check runs before any evaluation, not merely before any write | accurate | `trim.jl:403-405` | `test_trim.jl:352` | checked before the establishment round |
| §14.6 (8149) | pre-write means all-or-nothing: a rejected init leaves the sim exactly as it was | accurate | `sim.jl:613-617` | `test_conditions.jl:225` | |
| §14.6 (8152) | the probe-value barrier: the services path contains no call to `probe_value` | accurate | `conditions.jl:489-491` | no test | `probe_value` appears only at `build.jl:296`, and totality guarantees an overwrite before any read |
| §14.6 (8158) | replay never synthesizes; with totality enforced the header's root-input capture is complete by construction | accurate | `trace.jl:283-285` | `test_trace.jl` | §11.3's requirement discharged |
| §14.6 (8161) | baselines are aircraft-shipped condition functions (`ready_for_taxi`, `cold_and_dark`) | n/a | — | — | user material |
| §14.6 (8166) | `override(base, patch)` is the fourth node kind, ordered and asymmetric | accurate | `conditions.jl:46-48`, `110-111` | `test_conditions.jl:66` | |
| §14.6 (8169) | at resolution a leaf present in both takes the patch's value, provenance recording both sources | accurate | `conditions.jl:181-196` | `test_conditions.jl:66` | provenance reads `"… (overrode …)"` |
| §14.6 (8171) | collisions *within* one layer remain errors | accurate | `conditions.jl:187` | `test_conditions.jl:66` | |
| §14.6 (8172) | variadic layering composes | accurate | `conditions.jl:110` | `test_conditions.jl:66` | |
| §14.6 (8174) | trim's committed condition is `override(baseline, solution)` | accurate | `trim.jl:558` | `test_trim.jl:444` | |
| §14.7 (8180) | **Rule**: the `TrimProblem` field set is normative and closed — those seven fields | accurate | `trim.jl:48-59` | `test_trim.jl:229` | all seven required keywords |
| §14.7 (8182) | `guess`, `lower`, `upper` are same-named all-`Float64` NamedTuples | accurate | `trim.jl:242-270` | `test_trim.jl:229` | |
| §14.7 (8187) | `tolerances` is an all-`Float64` NamedTuple, same-named as the residual return | accurate | `trim.jl:278-291`, `318-330` | `test_trim.jl:229` | also refuses non-positive tolerances, beyond the spec |
| §14.7 (8190) | `tolerances` is carried in the problem so a relocated problem carries its own convergence test; `at` passes it through untouched | short | `trim.jl:55` | no test | the field is in the problem; there is no `at` over problems (4.1) |
| §14.7 (8194) | the worked C172 cruise example | n/a | — | — | example |
| §14.7 (8213) | the service packs and unpacks by `guess`'s field order | accurate | `trim.jl:462-463`, `471`, `478` | `test_trim.jl:132` | |
| §14.7 (8218) | `lower`/`upper` checked at setup for key-set equality and `Float64` fields, then canonicalized to `guess`'s order | accurate | `trim.jl:250-257`, `462-463` | `test_trim.jl:132` | canonicalized by named indexing rather than `NamedTuple{keys(guess)}`; same law |
| §14.7 (8221) | a permuted bound spelling is a non-event | accurate | `trim.jl:462-463` | `test_trim.jl:132` | |
| §14.7 (8222) | a key-set or field-type mismatch is `TrimProblemInvalid` | accurate | `trim.jl:250-257`, `293-297` | `test_trim.jl:229` | |
| §14.7 (8224) | guess, bounds and the returned solution share one spelling, so `Base.merge` warm-starts | accurate | `trim.jl:478` | `test_trim.jl:457` | solution is `NamedTuple{K}` |
| §14.7 (8228) | `TrimParameters` stays a plain user struct the framework never sees | n/a | — | — | user material; `condition` is a closure |
| §14.7 (8231) | the read side is declared then compiled: `reads(name = selector, …)` | accurate | `readers.jl:117-134` | `test_readers.jl:41` | |
| §14.7 (8234) | `get_state`/`get_deriv` validated against `init_x`/`init_s`, `get_output` against `output_types`, `get_input`/`get_face` against the root face lists | accurate | `readers.jl:300-367` | `test_readers.jl:77` | |
| §14.7 (8244) | a derivative wanted across a contract boundary publishes an output port instead; `get_deriv` stays scoped to owned concrete subtrees | accurate | `readers.jl:320-322` | `test_readers.jl:77` | `:discrete_deriv` refuses the discrete tier; the scoping itself is convention |
| §14.7 (8246) | the compiled reader fills a stack-only NamedTuple per evaluation | accurate | `readers.jl:199-200` | `test_readers.jl:66`, `test_trim.jl:493` | `@ballocated == 0` |
| §14.7 (8248) | the user supplies a residual *system*, packed to the solver's vector in `tolerances`' field order, the return canonicalized to it | accurate | `trim.jl:450-458`, `414` | `test_trim.jl:92` | |
| §14.7 (8253) | the FlightCore formulation survives verbatim as user math | n/a | — | — | history |
| §14.7 (8259) | nonlinear least squares with exact AD Jacobians is the default; the `Dual` activation seeds the decisions through the assignment, sweep and `state_derivative` | accurate | `trim.jl:420-426`, `526-529` | `test_trim.jl:475` | |
| §14.7 (8262) | the seeds survive the condition write boundary | accurate | `conditions.jl:575-577` | `test_trim.jl:475` | |
| §14.7 (8271) | non-squareness degrades gracefully; at the solution $\partial r/\partial d$ is free | n/a | — | — | property of LS, not a checkable obligation |
| §14.7 (8276) | the derivative-free scalar path survives as the fallback, the service squaring and normalizing at `stopval = 1` | absent | — | — | see 4.5 |
| §14.7 (8282) | closed-loop trim and on-ground equilibrium are recorded, not built | n/a | — | — | explicitly unbuilt |
| §14.7 (8292) | the residual signature is `residuals(reads::NamedTuple, d::NamedTuple) → NamedTuple` | accurate | `trim.jl:408`, `445` | `test_trim.jl:92` | |
| §14.7 (8295) | **Rule**: what the solver varies is passed; what is fixed per problem is closed over | accurate | `trim.jl:445` | `test_trim.jl:92` | |
| §14.7 (8309) | names and types are checked at setup, the guess evaluation observing the residual key set | accurate | `trim.jl:408-409`, `318-330` | `test_trim.jl:229` | re-checked at the first seeded point (`trim.jl:440-449`), beyond the spec |
| §14.7 (8313) | a `tolerances` key-set mismatch or any field-type disagreement is `TrimProblemInvalid` with the offending field and the names or types in hand | accurate | `trim.jl:318-330`, `diagnostics.jl:1140-1191` | `test_trim.jl:229`, `test_trim.jl:335` | |
| §14.7 (8316) | order is never a mismatch | accurate | `trim.jl:251`, `323` | `test_trim.jl:132` | set comparison on both seams |
| §14.8 (8325) | `trim!(sim, problem; baseline, t0 = 0.0, backend = LevenbergMarquardt())` | accurate | `trim.jl:383-384` | `test_trim.jl:92` | |
| §14.8 (8326) | the default backend is an in-house dense Levenberg–Marquardt | accurate | `trim.jl:158-221` | `test_trim.jl:117` | |
| §14.8 (8336) | the backend contract is a pinned signature: `solve(backend, eval!, d0, lower, upper, tol) -> (; d, status, nevals, niters)` | accurate | `trim.jl:134`, `179-221` | `test_trim.jl:305` | |
| §14.8 (8338) | `eval!(r, J, d)` is in-place, always fills `r`, fills `J` iff `J !== nothing` | accurate | `trim.jl:441-460` | `test_trim.jl:92` | |
| §14.8 (8343) | `d0`, `lower`, `upper` are packed `Vector{Float64}` in `guess`'s order, `±Inf` unbounded | accurate | `trim.jl:462-471` | `test_trim.jl:305` | |
| §14.8 (8349) | `tol` is a `Vector{Float64}` in `tolerances`' order, data the backend *may* stop on, decisive of nothing | accurate | `trim.jl:399`, `476-478` | `test_trim.jl:92` | |
| §14.8 (8353) | `status::Symbol` from an open set, recorded verbatim (D-158); `nevals`/`niters` diagnostic | accurate | `trim.jl:97-108`, `578` | `test_trim.jl:152` | |
| §14.8 (8361) | `converged` means `all(abs.(rᵢ) .≤ tolᵢ)`, evaluated by the service at the backend's returned point | accurate | `trim.jl:172`, `476-478`, `553` | `test_trim.jl:92`, `test_trim.jl:152` | |
| §14.8 (8364) | that verdict, and nothing else, gates the commit and fills `TrimReport.converged` | accurate | `trim.jl:553-558` | `test_trim.jl:152` | |
| §14.8 (8372) | in the least-squares register the tolerances feed the per-residual test directly | accurate | `trim.jl:188`, `220` | `test_trim.jl:117` | LM's descent test uses the same units (`_scaled_norm`) |
| §14.8 (8376) | the fallback is `NLoptBackend(:LN_BOBYQA)` in a package extension, keeping the core dependency-free | absent | — | — | see 4.5 |
| §14.8 (8380) | for the fallback the service minimizes $\sum(r_i/tol_i)^2$ with `stopval = 1` | absent | — | — | see 4.5 |
| §14.8 (8386) | the `stopval` sphere is inscribed in the tolerance box, so the re-check remains the single authority | accurate | `trim.jl:476-478` | `test_trim.jl:152` | the re-check exists; the inscription claim is a lemma |
| §14.8 (8397) | box bounds are honored by step projection | accurate | `trim.jl:202`, `471` | `test_trim.jl:305` | the guess is clamped into the box before the solve |
| §14.8 (8398) | a decision saturated at the solution is flagged in the report | accurate | `trim.jl:534-542` | `test_trim.jl:182` | |
| §14.8 (8404) | every `trim!` instantiates a fresh working store set (x backing, s/m stores, input and signal tables, derivative buffer) from the activation's layout | accurate | `trim.jl:499-501`, `build.jl:873-898` | `test_trim.jl:152` | |
| §14.8 (8412) | the invariant: the simulation's authoritative stores have exactly one writer, the commit through boundary zero | accurate | `trim.jl:558` | `test_trim.jl:152` | |
| §14.8 (8416) | setup applies `override(baseline, condition(guess))` to the scratch set once, coverage checked there before the first evaluation | accurate | `trim.jl:403-405` | `test_trim.jl:352` | |
| §14.8 (8422) | an incomplete `baseline` is one declaration-ordered `UninitializedInputs` at setup | accurate | `trim.jl:404` | `test_trim.jl:352` | |
| §14.8 (8425) | D-213: the scratch set is instantiated in two halves; the nominal half takes the composite by the dynamic walk and runs one establishment round with no projection, no guards and no `state_update` | accurate | `trim.jl:402-407`, `sim.jl:409-410` | `test_trim.jl:369` | |
| §14.8 (8430) | the seeded set is written by the specialized register and its frozen cells copied from the nominal set as zero-partial constants | accurate | `trim.jl:420-425`, `509-520` | `test_trim.jl:369` | |
| §14.8 (8436) | no scratch cell holds the probe's synthesized values | accurate | `trim.jl:509-520` | `test_trim.jl:369` | |
| §14.8 (8437) | the iterations are raw write → sweep → read at the seeded activation | accurate | `trim.jl:441-460` | `test_trim.jl:475` | |
| §14.8 (8439) | the zero-decision problem is the nominal half alone; its one evaluation is the establishment round | accurate | `trim.jl:411-417` | `test_trim.jl:204` | |
| §14.8 (8441) | the commit applies the same composite over the same baseline, so its coverage is setup's and the check is structurally unfailable | accurate | `trim.jl:558` | `test_trim.jl:444` | |
| §14.8 (8445) | `TrimReport` carries no committed flag | accurate | `trim.jl:97-108` | `test_trim.jl:152` | absence of `committed_residuals` is the absence of the commit |
| §14.8 (8447) | iterations rewrite the composite's write-set via the compiled plan; an LM evaluation is one Dual-seeded sweep yielding `r` and `J` together | accurate | `trim.jl:443-458` | `test_trim.jl:475` | |
| §14.8 (8452) | no convergence means no commit, and no commit means the sim is bit-for-bit untouched, "never initialized" included | accurate | `trim.jl:554-556` | `test_trim.jl:152` | |
| §14.8 (8457) | an interrupt during a long solve leaves the simulation untouched, needing no counterpart to the loop's boundary masking | accurate | `trim.jl:402-481` | no test | structural: all work is on per-invocation scratch |
| §14.8 (8465) | the commit is an `init!` in every respect: `override(baseline, solution)` through boundary zero, with the pre-write totality check, the sequence and guards | accurate | `trim.jl:558` | `test_trim.jl:444`, `test_trim.jl:408` | |
| §14.8 (8469) | the `t0` argument and its default are the same for both init-service entry points | accurate | `trim.jl:384`, `558`, `sim.jl:608` | `test_trim.jl:457` | |
| §14.8 (8470) | the recorders are cleared as §12.6 states for `init!`: trace, log and staged batches | accurate | `sim.jl:535-550`, `619` | `test_trace.jl`, `test_log.jl` | inherited from `init!` |
| §14.8 (8476) | fly-then-retrim keeps continuity as `trim!(sim, problem; baseline = c, t0 = t)` from a `capture` | accurate | `trim.jl:384` | `test_trim.jl:457` | |
| §14.8 (8481) | `trim!` returns a structured `TrimReport` | accurate | `trim.jl:97-108` | `test_trim.jl:92` | |
| §14.8 (8491) | report field: the `converged` flag, the service's own box test | accurate | `trim.jl:98`, `553` | `test_trim.jl:92` | |
| §14.8 (8493) | report field: the solution NamedTuple, guess-shaped | accurate | `trim.jl:99`, `478` | `test_trim.jl:457` | |
| §14.8 (8494) | report field: the solved-point residuals with their tolerances | accurate | `trim.jl:100-101`, `552` | `test_trim.jl:92` | |
| §14.8 (8497) | report field: the committed-state residuals, re-gathered from the boundary-zero world | accurate | `trim.jl:102`, `571-572` | `test_trim.jl:422` | |
| §14.8 (8499) | report field: the backend's status with its iteration/evaluation counts | accurate | `trim.jl:103-105`, `578` | `test_trim.jl:152` | |
| §14.8 (8502) | report field: the saturated-bounds list | accurate | `trim.jl:106`, `534-542` | `test_trim.jl:182` | |
| §14.8 (8503) | report field: the commit's fired events as component paths and event names, empty when boundary zero ran quiet | accurate | `trim.jl:107`, `563-564` | `test_trim.jl:408` | |
| §14.8 (8506) | the committed-state residuals are nearly free and carry no offset caveat | accurate | `trim.jl:571-572` | `test_trim.jl:422` | one `rhs()` for the derivative reads |
| §14.8 (8514) | a non-empty fired-event set raises `TrimCommitEvents` | accurate | `trim.jl:565`, `diagnostics.jl:1194-1202` | `test_trim.jl:408` | severity `:warning` |
| §14.8 (8519) | a converged solve whose committed-state residuals violate the box raises `TrimCommitResiduals`, naming the offending residuals with committed values and tolerances | accurate | `trim.jl:573-576`, `diagnostics.jl:1205-1213` | `test_trim.jl:422` | |
| §14.8 (8523) | the verdict is not re-litigated | accurate | `trim.jl:553`, `578` | `test_trim.jl:422` | |
| §14.8 (8527) | non-convergence never throws | accurate | `trim.jl:554-556` | `test_trim.jl:152` | |
| §14.8 (8530) | a malformed problem is a `BuildError`-class failure at setup, `TrimProblemInvalid`, collected | accurate | `trim.jl:390-394`, `231-234` | `test_trim.jl:229` | |
| §14.8 (8532) | the malformed cases: guess/bounds key-set or field-type disagreement, an unknown `reads` selector, a `tolerances`/residual key-set mismatch at the guess evaluation | accurate | `trim.jl:242-330` | `test_trim.jl:229` | `TapResolution` values spliced in beside |
| §14.8 (8539) | an *empty* problem is legal: the solver is bypassed, the residuals evaluated once at the baseline, the box test decides and the commit runs as usual | accurate | `trim.jl:411-417` | `test_trim.jl:204` | status `:bypassed` |
| §14.8 (8557) | the AD obligation is exactly the continuous chains, `state_derivative`, and the user's assignment and residual math; the discrete tier and the event system never see a `Dual` | accurate | `build.jl:471`, `trim.jl:420-425` | `test_trim.jl:369` | §9.4's activation, restated |
| §14.8 (8563) | AD-readiness is a build-checked property, the `Dual` probe naming the culprit | accurate | `build.jl` activation probe | `test_build.jl` | §9.4's obligation, cross-referenced |
| §14.8 (8568) | the C172 migration audit | n/a | — | — | migration notes |
| §14.8 (8580) | fallback per problem: one `backend =` keyword | short | `trim.jl:384` | no test | the keyword exists; no second backend ships (4.5) |
| §14.9 (8584) | a `TrimProblem` is an implicitly specified condition; the commit is literally an init | accurate | `trim.jl:558` | `test_trim.jl:444` | |
| §14.9 (8593) | `at` lifts to problems field by field: path-free fields pass through, `condition` post-composes, `reads` takes the same `Scoped` node | absent | — | — | see 4.1 |
| §14.9 (8607) | resolution needs nothing new: the flattening accumulator enters the `Scoped` wrapper and prefixes every entry | accurate | `conditions.jl:167-170` | `test_conditions.jl:35` | the mechanism exists; no problem can reach it |
| §14.9 (8610) | root-input entries authored in the aircraft's face vocabulary resolve through the export chain from the mount point | accurate | `conditions.jl:412-430` | `test_conditions.jl:172` | |
| §14.9 (8613) | an unexported face fails resolution by name | accurate | `conditions.jl:415`, `421-423` | `test_conditions.jl:172` | |
| §14.9 (8614) | an internally wired input is untrimmable from outside and the build says so | accurate | `conditions.jl:426-429` | `test_conditions.jl:172` | |
| §14.9 (8620) | a problem never authors the environment; it receives handles through the user parameter record | n/a | — | — | convention on user code |
| §14.9 (8631) | the world wrapper dissolves: `f_init!(::Model{<:SimpleWorld})` has no successor | n/a | — | — | migration statement |
| §14.9 (8637) | "aircraft as root" is a thin world; `design_world(ac)` is the shipped rig | absent | — | — | library material; no such artifact in `src/` |
| §14.9 (8645) | leaving an environment face unconnected is legal: it becomes an ordinary root input holding the handle value | accurate | `assembly.jl:688`, `build.jl:296` | no test | follows from §11.3's bare-typed root inputs; see 6 |
| §14.9 (8655) | swarm doctrine: the service solves one problem at a time; `product(…)` is recorded, not built | accurate | `trim.jl:383` | `test_trim.jl:92` | one problem per call |
| §14.10 (8666) | the tap declaration replaces the shuttle structs with three selector lists | absent | — | — | see 4.1 |
| §14.10 (8671) | the lists carry the optional component index, so a vector leaf yields named scalars | accurate | `readers.jl:56`, `82-92`, `163-164` | `test_readers.jl:41` | the index exists in the family; no tap list consumes it |
| §14.10 (8684) | the three lists are validated at resolution against `init_x`, faces and `output_types`, with did-you-mean | absent | — | — | the `reads` analogue exists (`readers.jl:300-367`); no tap lists |
| §14.10 (8687) | an `x` entry naming a discrete store is rejected with the entry and its tier in hand (D-167, D-197) | absent | — | — | `get_state` on a discrete store resolves fine, correctly, for `reads` |
| §14.10 (8692) | taps compile to offsets once and relocate whole via `at(prefix, taps)` | absent | — | — | see 4.1 |
| §14.10 (8697) | each `linearize` invocation instantiates its own scratch store set and applies the operating-point condition | absent | — | — | see 4.1 |
| §14.10 (8699) | one `Dual` evaluation seeded one direction per `x`- and `u`-tap, chunked internally | absent | — | — | see 4.1 |
| §14.10 (8701) | value parts give `ẋ₀`, `y₀`; partials give `A`, `B`, `C`, `D` simultaneously | absent | — | — | see 4.1 |
| §14.10 (8716) | unseeded states and root inputs sit constant, their `Float64` values embedded as zero-partial constants | accurate | `conditions.jl:575-577` | `test_conditions.jl:483` | the embedding is built; nothing consumes it for linearization |
| §14.10 (8721) | the discrete tier is frozen with zero partials | accurate | `build.jl:471`, `496` | `test_trim.jl:369` | §9.4's activation |
| §14.10 (8725) | a root input declared `Float64` is declaredly unseedable, and selecting it as a `B`-matrix tap is rejected at tap resolution | absent | — | — | the declaration half is §8.2's; the tap rejection has no site |
| §14.10 (8730) | under fan-out the rejection names the pinning consumer, not the face alone (D-168) | absent | — | — | no tap resolution |
| §14.10 (8737) | the seeded/frozen leaf table (six rows) | absent | — | — | folded into the rows above |
| §14.10 (8747) | linearization is a pure query with no commit and no boundary zero, working on scratch buffers only | absent | — | — | see 4.1 |
| §14.10 (8753) | the default operating point is `capture(sim) → (condition, t)` | absent | — | — | `capture` exists (`conditions.jl:813`); no caller |
| §14.10 (8757) | an `about = <condition>` keyword linearizes elsewhere without touching the sim | absent | — | — | see 4.1 |
| §14.10 (8760) | `linearize` returns `(ẋ₀, x₀, u₀, y₀, A, B, C, D)` carrying the taps' label sets | absent | — | — | see 4.1 |
| §14.10 (8763) | `subsystem`/`delete_vars` survive as label-indexed matrix slicing | absent | — | — | see 4.1 |
| §14.10 (8765) | `LinearizedSS` survives as an ordinary continuous component in the migrated library | absent | — | — | library material |
| §14.10 (8772) | recorded guidance on minimal-coordinate tap mechanizations | n/a | — | — | guidance |
| §14.10 (8779) | the sampled-data `Dual` activation is recorded, not built | n/a | — | — | explicitly unbuilt |
| §14.10 (8823) | the output half of declarative non-participation: declare the leaf `Float64` and strip with `ForwardDiff.value` (D-166) | accurate | `build.jl:496`, `505` | `test_build.jl` | §8.2/§9.5's obligation, cross-referenced |
| §14.10 (8833) | the input half: a `Float64` entry declares "never hand me partials", enforced at the wire (D-167) | accurate | `build.jl:471` | `test_build.jl` | §6.1/§8.2's obligation, cross-referenced |
| §14.10 (8845) | pinned-face validation and the feedthrough lint stay recorded | n/a | — | — | explicitly unbuilt |

## 4. Deviations in detail

### 4.1 Linearization (§14.10) and mounting (§14.9) are not built

§14.10 opens: "Today's per-aircraft `XStateSpace`/`UStateSpace`/`YStateSpace`
structs … All of it becomes three selector lists" (8666–8671), and closes on
"`linearize` returns labeled data: `(ẋ₀, x₀, u₀, y₀, A, B, C, D)`" (8760).
§14.9 states "`at` lifts to problems in five lines" (8593) and gives the seven
field assignments.

Neither exists. A grep over `src/` finds `linearize`, `LinearizedSS`,
`design_world`, `subsystem` and `delete_vars` nowhere but the spec. `at` has
exactly two methods, `conditions.jl:75-76`, the second of which throws
`ConditionNodeMisuse` on anything that is not a condition node. The probe
confirms:

```
linearize false   taps false   LinearizedSS false   design_world false
subsystem false   delete_vars false
at(problem) -> BuildError: ConditionNodeMisuse: Cadence.TrimProblem{…}
at(reads)   -> BuildError: ConditionNodeMisuse: Cadence.Reads{…} is not a condition node
```

Why it matters. §14 sells the four services as clients of one condition
algebra, and two of the four are missing. The consequences reach outside
§14.10: §14's lifecycle table has two rows with no code (7672–7673); §14.4's
"load-bearing services speak the contract" is one service; §14.10's two
tap-resolution rejections (an `x` entry naming a discrete store, a
`Float64`-declared root input as a `B` tap) have no site, so D-167's
no-silent-zeros guarantee is unenforced on the tap side even though the
declaration half is built; and §14.9's relocatability guarantee is unavailable
even though its resolution half — `Scoped` flattening, face chains from a mount
point — is built and tested.

### 4.2 `ServiceLifecycle`'s `legal` column is filled at one site of three

§14 (7681): "A violation is `ServiceLifecycle` (Appendix C — the operation, the
current status, the legal statuses)."

`diagnostics.jl:721-725` declares all three fields, with `legal` defaulting to
an empty `Symbol[]`. Only `capture` fills it (`conditions.jl:815-816`).
`init!` (`sim.jl:611-612`), `trim!` (`trim.jl:386-387`) and `replay!`
(`sim.jl:724-725`) all construct the kind with `op` and `status` only.

In practice the rendered message does not suffer: `message` has dedicated
sentences for `:running`, `:errored` and `:stopped`, and only the fallback
branch (`diagnostics.jl:746`) prints `_namelist(d.legal)` — which is exactly the
`capture`-in-`built` case that does carry it. So the gap is in the structured
payload a programmatic reader sees, not the text. Still short against the
column the spec states.

### 4.3 `capture` and the trace header are separate gathers, and neither is the compiled reader

Two claims are involved. §14.1 (7712): "That gather is the one the trace header
already needs: one mechanism, two uses." §14.4 (8028): "Trim's cost read …,
linearization's Jacobian gather, and `capture`'s full-store readback are one
primitive run in reverse: one machinery, both directions."

`capture` (`conditions.jl:813-847`) walks `ex.xbuf` through `reconstruct`,
dereferences `ex.sstores`/`ex.mstores` directly, and builds condition nodes.
`_capture_header` (`trace.jl:277-296`) walks the same three homes again with
`copy`/`deepcopy` and builds a `TraceHeader`. The compiled `Reader`
(`readers.jl:193-202`) is a third path, and neither of the first two uses it.
The only shared primitive is `gather(ex.store, addr)` for the root inputs,
which both do call.

The claim is not fully reachable as stated: the read-selector family has no
member addressing a whole `s` or `m` store, so a full-store readback cannot go
through a `Reader` without a sixth selector. What is real is one *layout*, read
three ways. Why it matters is modest — the three walks must stay in step by
hand, which is exactly the coupling the "one mechanism" line was meant to
remove.

### 4.4 Condition path resolution carries no did-you-mean over children

§14.3 (7841): "the path resolves, with did-you-mean (the offending name plus
the list-in-hand it should have matched) over children."

`_component` (`conditions.jl:397-403`) pushes `ConditionResolution` with reason
`:assembly_path` or `:unknown_path` and no `candidates`. The rendered message
is "the condition addresses `"pwp/engnie"`, which is no component of this
build" — the offending name, and nothing to compare it against. Contrast the
same file's `_undeclared` (`conditions.jl:448-454`), which carries
`collect(keys(declared))`, and `_root_input` (`conditions.jl:415`, `423`),
which carries the face list. The same hole is in `_read_component`
(`readers.jl:257-265`), whose comment says as much.

Why it matters: a mistyped path is the most likely condition authoring error
and the one the caller can least easily debug, because the correct spelling
lives in the assembly tree rather than in the fragment function they are
looking at. The `Build`'s `flat.paths` is right there.

### 4.5 The derivative-free fallback register is absent

§14.7 (8276): "The derivative-free scalar path survives as the fallback. The
service squares *and normalizes* the residuals against the tolerances —
$\sum(r_i/tol_i)^2$ at `stopval = 1`." §14.8 (8376): "The derivative-free
scalar fallback is `NLoptBackend(:LN_BOBYQA)` in a package extension … and
leaves the framework core carrying zero optimizer dependencies."

There is no `ext/` directory, `Project.toml` declares no `[extensions]` or
`[weakdeps]`, and `NLoptBackend` is undefined (probe). Nothing anywhere squares
and normalizes the residual vector for a scalar objective.

The core is dependency-free, so half the sentence holds by omission. But the
"per register" tolerance translation §14.8 makes a section heading of has one
register. The `backend =` keyword accepts any value with a `solve` method
(`trim.jl:384`, `134`), so the seam is open and a user could supply one; the
spec asks the framework to ship it. Notably, the in-house LM already computes
the fallback's objective internally — `_scaled_norm` at `trim.jl:177` is
$\sqrt{\sum(r_i/tol_i)^2}$ — so the normalization the fallback needs exists but
is private to the LM backend.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 164 |
| short | 8 |
| stand-in | 0 |
| absent | 23 |
| n/a | 18 |
| **total** | **213** |

## 6. Friction

- §14.9's "leaving an environment face *unconnected* is legal by construction.
  The face becomes an ordinary root input holding the handle **value**"
  (8645–8649) makes a claim I could not settle inside my slice. Whether a
  function-valued root input is representable depends on the per-eltype cell
  stores (`store.jl`, `_cell_key`) and on §8.2's bare-types rule, both outside
  §14. I marked it accurate on the reasoning that root inputs are bare-typed
  cells with no declared default and nothing in `assembly.jl:688` or
  `build.jl:296` restricts the leaf type beyond `probe_value(P)` needing a
  method, but I did not probe it. A reader auditing §8.2 or §11.3 should
  double-check.
- §14.4's "one machinery, both directions" (8028) and §14.1's "one mechanism,
  two uses" (7712) are design assertions about code sharing rather than
  observable laws. Two readings fit: the sharing is of the *layout tables*
  (true), or of the *gather primitive* (false — three walks). I reported the
  stricter reading, since the sentences name the primitive.
- §14.7 (8271) "Non-squareness degrades gracefully. Redundant actuation becomes
  weighted or minimum-norm least squares" reads as an obligation on the backend
  but names no spelling for a weight. The in-house LM's damped normal equations
  handle rank deficiency, which is the closest checkable reading; I marked it
  n/a rather than invent the missing spelling.
- The spec's §14.8 report field list (8491–8504) is prose bullets whose field
  *names* are deliberately withheld from the struct sketch at 8481. The code
  names them, and the names match the bullets one for one, but a strict reader
  could argue the spec places no naming obligation at all. I audited the bullets
  as seven separate claims about what the report carries, not about what the
  fields are called.
- `test/test_trim.jl:335` and `trim.jl:432-449` implement a residual-return
  re-check at the first seeded evaluation that §14.7 does not ask for. It is
  strictly better than the spec (it turns a bare `ErrorException` from
  `NamedTuple{RK}` into a collected `TrimProblemInvalid`), so I recorded it as a
  note on the §14.7 row rather than as a deviation.
