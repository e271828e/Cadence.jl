# The audit against the register

Coordinator's merge of the seven agent reports in this directory, diffed
against `docs/design/implementation.md`'s absence list and stand-in table —
the two sections no agent was allowed to read.

Aggregate: **588 accurate, 87 partial, 36 deviation, 84 pending** (Agent C's
table spells its verdicts differently and is not in that tally). Tip `2c02afb`.

The rule under test is "nothing deviates silently". Sections A and B below are
where it did not hold.

## A. Contradicts something the register explicitly asserts

**A1. The `_typename` universality claim is false.** The authoring caveat
states that every payload field naming a *user* type goes through `_typename`,
and that the only `string(typeof(...))` left are two in `trim.jl` naming
framework types on purpose. There are 13 further sites naming a
user-authored binding type: `bindings.jl:140,144,158,163,166,173,181,184`
and `roster.jl:80,82,84,86,88`. `roster.jl:51,62` fill the *same* `binding`
field of the *same* kind with `_typename(b)`, so `BindingContractMismatch`
renders its subject two different ways depending on which arm raised it.
Module-dependent, which is the exact fragility the caveat exists to prevent.
*Verified.*

**A2. The first-violation refusal list is incomplete in both directions.**
The register names six kinds reached from named sites. Agent F found eleven
kinds that throw fail-fast where Appendix C's column reads `collected`, adding
`UnknownFaceSelection`, `ClassMixed`, `WireTypeMismatch`, `AlgebraicCycle` and
`ProducedByTwoStages`. Two go the other way and collect where the column says
fail-fast (`UndeclaredReturnField`, `HandlerReturnKey`); neither direction is
recorded.

**A3. Did-you-mean candidate lists are carried inconsistently, per arm.**
The register says candidate lists "are carried and rendered, never ordered".
Agent D reported them carried by `GetInput` alone; **that overstates it** —
`GetInput` (`readers.jl:349`), `GetFace`'s `:unknown_output_face` arm (`:363`),
`_declares` (`:295`) and `AttachUnknownFace` (`roster.jl:206`) all carry one.
The real finding is narrower and still real: `GetFace`'s `:root_input_not_face`
arm carries none, and of the eight `ReadBindingUnresolved` arms in
`bindings.jl` only the one at `:173` does. So the register's claim holds for
most arms and fails for a handful. *Verified; agent claim corrected.*

## B. Undocumented deviations — in neither the absence list nor the stand-ins

**B1. `t_end` lands on the wrong grid boundary.** `sim.jl:790`, `:883` and
`:1131` compute the target frame as `round(Int, t_end / h)`. §12.4 and D-133
require the first boundary reaching or exceeding `t_end`; D-133
(`decisions.md:3891`) explicitly *rejects* ending at the last boundary before
it, which is what `round` yields whenever the fraction is under ½. `step!`'s
`t_plus` uses `ceil` correctly at `:1127`, so two spellings of one rule
disagree inside one file. No test catches it — every test uses an exact
multiple. Found independently by Agents C and D. *Verified.*

**B2. `t_end` ignores `clock.t₀`.** The same three expressions compare a step
count against `t_end / h`, so `init!(sim; t0 = 10.0)` with `t_end = 12.0` runs
to t = 22. §12.4 says the boundary *time* is what reaches `t_end`. *Verified.*

**B3. `ConformanceFailure`'s field-set check is order-sensitive.**
`keys(x⁺) === keys(x)` at `build.jl:594` and `keys(ẋ) === keys(x)` at
`build.jl:1050`. D-151 is ratified and says field order carries no semantics at
any author↔framework seam, the framework canonicalizing by a type-level
reorder. `trim.jl` canonicalizes; the stage/state seam does not, so a correctly
named return in a different order is refused as a `:field_set` mismatch.
*Verified.*

**B4. `_root_input_type` takes `first(declared)`, not D-168's meet**
(`build.jl:331`), with any disagreement raised as `RootInputTypeConflict`. The
spec's own legitimate model — a `T`-entry consumer beside a `Float64`-entry
consumer on one root input — builds at nominal and then throws
`WireTypeMismatch` on its `Dual` activation, carrying a hint that is wrong
there. *Verified.*

**B5. `AlgebraicCycle.members` is the raw topological-sort residue**
(`build.jl:219–252`), a list of component paths. D-012's Rejected list names
that exact alternative and says why: the residue holds the innocent downstream
cone. `diagnostics.jl:580–582` documents SCC semantics the code does not
implement. The register records only the payload gap, not that the payload it
does carry is the wrong set.

**B6. `localization_tol` is measured over the segment, not the frame**
(`localization.jl:195`). `hi − lo > tol` is in θ over `h′`, so after a `t*` the
effective width is `tol·h′` where §10.4 and D-133 both state `tol·h`. Tighter,
never looser; the docstring says deliberate; nothing ratifies it.

**B7. A spurious `ChatteringBudget`** (`localization.jl:72–82`): the budget gate
sits ahead of the θ = 0 validation, so past exhaustion an epoch-caused edge is
reported as chattering, where §10.4 says it warns nothing and consumes no
budget. Trajectory unaffected, diagnostic wrong.

**B8. The join cap is one shared deadline, not a per-device cap**
(`devices.jl:440`). With n devices the last can get zero patience and be
abandoned under `DeviceJoinTimeout` though it would have joined. D-198's "one
patience" plausibly ratifies one *value*, not one *deadline*.

**B9. The nominal bound check is a structural `_accepts` match, not `<:`.**
This closes §4.4's abstract input entry (`terrain = AbstractTerrainField`) and
moves the input-side forgotten-`T` failure from the first nominal build to the
first `Dual` activation. Found by Agents A and B independently.

**B10. Containers of containers are silently inert**, where §8.5 says they are
rejected in the first cut.

**B11. `Simulation`'s constructor has drifted from Appendix B**
(`sim.jl:130`): `algorithm` → `method`, defaulting to the type `RK4` rather
than an instance `RK4()`; an extra positional `::Type{T}`; an extra keyword
`chunk_size = 16`; `nothing` sentinels for `h`/`n`/`t_end` in place of the
appendix's literal defaults. Documented in the docstring, not in the spec.

**B12. `phase_bodies` returns only the four aggregate phase blocks**, not the
per-event guard/handler and per-component `project` callables Appendix B says
it also carries.

**B13. There are no exports at all.** `rg '^\s*(export|public)\b' src/` returns
nothing across all 18 files. The caveat's reasoning about what "must never be
exported" implies an export list that does not exist. *Verified.*

**B14. `ServiceLifecycle.legal` is empty at 11 of its 12 construction sites.**

## C. Undocumented absences

**C1. §5.6 feedthrough tracing is absent in its entirety** — no tracer of
either mode, no SCC decomposition, no genuine/artificial classification. The
register mentions §5.6 only as a missing payload field on `AlgebraicCycle`. It
is a whole spec section with no implementation and no absence-list entry.

**C2. `GridUtilization` is a twelfth absent Appendix C kind.** The register
names ten, plus `DebtReanchor` under the §11.8 remainder. `GridUtilization` is
absent with no comment naming it, though its derivation path exists.

**C3. §6.2's library components** — `SumJunction{W,N}` with computed contracts,
and the `Constant` source that spells the zero-contributor end — do not exist.

**C4. §9.2's printable register is absent entirely.** There is no `show` method
anywhere in `src/`: no hyperperiod chart, no leave-one-out refinement factors,
no prime attribution. The register records only "D-187's grid diagnostics".

**C5. §13.7's predicate-based selection** on the passthrough helpers, and the
`Build` printer's face-provenance duty.

**C6. §12.2's coarse-phase `sleep` disposition and the thread-budget warning**
as mechanisms. The register lists the `ThreadBudget` *kind* as absent, which is
not the same statement.

**C7. §13.2's `FieldError`-recognition mechanism has no site.** `build.jl`
contains no `try` keyword at all, so the build-time framing of a user-code
throw has nowhere to happen. The register lists `BundleFieldError` and
`UserCodeFraming` as absent kinds but not that the mechanism behind them is
unbuilt. *Verified.*

**C8. §14.10's vocabulary is built and only the service is missing** — the five
selectors, the index argument, `TapResolution` with its `:x`/`:u`/`:y`
discriminator, and `capture(sim)` as the default operating point all exist.
Worth recording, because it sizes the remaining work.

## D. Documented but understated

**D1. §9.5.** The register says the return laws "are checked once, at the
probe". There is no runtime check at all: `executor.jl:143–146` runs the stage
and calls `scatter_group!` with no expected type, no `isa`, no diff, and
`scatter!` is `@generated` off the *declared* type assigning into a typed
buffer — so a divergent branch's wrong scalar is silently converted (Agent B
measured `3::Int` into a `Float64` cell storing `3.0`). All 15
`ConformanceFailure` sites are in `build.jl`, so §13.4's
conformance-failure-as-`StepError` species has no producer. *Verified.*

**D2. §13.3.** The register says the generic-holding check is absent in the
load-bearing register and that §14.2's locality law rides as convention.
Stronger: no site in `src/` tests concreteness at all
(`rg 'isconcretetype|generically_held|D-083|D-130' src/` is empty), and
condition entries and trim `reads` bypass `resolve` entirely for an exact-match
lookup into `flat.paths`. Three registers have collapsed into one. *Verified.*

**D3. Auto-published ports.** Recorded as absent. Not recorded: its trigger
condition is a hard build error, `probe_stage2` raising `DeclaredNotProduced`
(`build.jl:534–540`) for precisely the ports auto-publication should fill —
so the spec's own worked `Engine` example (spec:1799) would not build.

**D4. Payload gaps.** The register enumerates twelve kinds. Agent F found
twenty-one existing kinds carrying less than their Appendix C column.

**D5. Unguarded edges.** The register names two. Add: `stage!(sim, …)` has no
lifecycle gate and races a concurrent stopped-sim `attach!`'s non-atomic
harness-writer swap, bypassing §11.4's renormalization seam; and
`port(sim, …)`/`state(sim, …)` read the live store with no `assert_stopped`,
unlike `logged(sim)`.

## E. Where the register holds

No agent contradicted it on: `linearize`, mounting, the NLopt fallback,
§11.7's GUI write path, §10.7 pacing, pause and the control-plane surface,
`disable_sigint` masking, `InterruptException` reported as `DeviceCrash`,
`DeadStage`, or the ten absent kinds it names. The single stand-in row (the
per-writer status `Vector`) went unchallenged. Agent F's reverse sweep found no
`Diagnostic` subtype outside Appendix C, and `test_diagnostics.jl:492` pins
that with a `subtypes(Diagnostic)` set equality.

## F. Verification queue

Claims not yet checked by the coordinator, ranked:

Items 1–4 are now closed. What was checked, and how it came out:

1. **A3 — corrected, not confirmed.** See above; the agent's framing was too
   strong, the underlying per-arm gap is real.
2. **Agent A's port-value vocabulary — confirmed.** `leaves.jl:16` is
   `nleaves(::Type{P}) where {P} = sum(nleaves, fieldtypes(P); init = 0)`, so a
   fieldless type walks to zero leaves and `build.jl:281` raises
   `IllegalPortType`. An `@enum` is exactly that, so §3.1's mode-valued outputs
   are not expressible as ports. The file's own header comment states the
   closed vocabulary as "real scalars, static arrays, and isbits structs whose
   fields are drawn from the same vocabulary".
3. **B7 — confirmed.** The budget block at `localization.jl:72–82` returns
   before the θ = 0 validation below it, and the validation's own comment says
   an epoch-caused edge "consumes no budget". Past exhaustion it is reported as
   chattering anyway.
4. **Agent A's §7.5 row — distinct from the stand-in.** The recorded stand-in
   is the per-writer *status* `Vector`; A's row is about *snapshot* records.
   There is no `sizehint!` anywhere in `dataplane.jl`, and `:687` pushes the
   published snapshot objects themselves (D-023 rejected preallocated buffers).
   Minor, but it is a second unrecorded instance of the same shape.

Still open: the remaining `medium`-confidence rows, ~70 across the seven
reports. None of them carries a headline finding.

## G. Spec-side findings

Places where the code reads better than the spec, or the spec contradicts
itself. Collected here because they are spec-pass material, not code work.

- §5.3/§9.3: auto-publication versus `DeclaredNotProduced` is a contradiction
  in the spec, not only a gap in the code. Three other sections assume it.
- Six runtime Appendix C kinds are specified with a `device id` field the
  per-writer-cell architecture makes redundant. Answering that one question
  resolves six `partial` rows.
- §14.7/§14.8 disagree about which kind an unknown `reads` selector raises.
- §10.4 calls tick eligibility a *frame* property; §10.5's gate keys to the
  *tick* index. Different quantities whenever n > 1. The code is right and the
  spec never says what a non-tick frame top does.
- §11.4's "the CAS can fail only because a drain intercepted" is false for the
  multi-writer harness cell; the code's docstring is more honest.
- §9.1's eight-way collected deployment validation is not achievable in one
  barrier: two entries are preconditions of the other six.
- §9.5's canonicalizing reorder is a no-op given the name-keyed scatter.
- §11.3's stopped-sim state list omits `errored`; §11.8's `maxlog` obligation
  has no addressee; §12.4 never says whether `t_end` is absolute or a duration.
- D-133 spells the keyword `event_budget` where spec and code say
  `localization_budget`.
- §7.5's logging paragraph is stale against D-023/D-137.
- `ArgumentInvalid`'s call vocabulary in Appendix C is narrower than the code's
  eleven values, unratified by D-215.
- Trim's extra checks (second residual-return check at the first seeded
  evaluation, guess pre-clamp, inverted-box check) and the resolved-root-input
  collision key are all cases where the implementation is ahead of the spec.
