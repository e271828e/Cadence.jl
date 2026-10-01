# Unit C — phase 1 (blind read of new.md)

V1 The probe validates each function once, on the initial state's branch.
V2 The schema-authority bargain's second clause ("at first execution otherwise", §8.1) is discharged by leaving the probe's comparison permanently in place.
V3 [bold] Where the executor stores a stage return into the table, it holds the complete expected return type at this activation. (D-235)
V4 The executor is the compiled form of the stage execution order.
V5 An activation is the build's typed products at a given scalar type.
V6 The expected type is the type of the cells this stage writes, as the probe fixed them at this activation.
V7 It is one concrete NamedTuple type per (component, stage): the stage's declared names at the types their cells hold. (§8.2)
V8 The write is generated over that type and the return's type.
V9 So the test is decided when the write's method is specialized; no per-field instruction reaches the conformant path.
V10 At generation the return's key set is compared with the expected type's.
V11 Each returned field is held to its cell's type under the relation below.
V12 A conformant return type generates the straight stores and nothing else.
V13 A non-conformant one generates a throw of the failure payload, raised the first time that branch executes.
V14 Type-stable conformant code: compiler proves the return type, one method, no check instruction to delete.
V15 Branch-divergent code: each return type gets its own method, the union split the code already pays.
V16 The check is absent from every conformant method.
V17 The divergent branch's method is the loud located error at its first execution.
V18 Type-unstable-but-conformant code pays the dynamic dispatch it already bought, nothing on top.
V19 [bold] Names are the pairing; field order carries no semantics. (D-151)
V20 Expected's order is an internal fact.
V21 It is derived from y_types, stage-filtered; no single declaration shows it to the author.
V22 The author never reproduces it.
V23 A return with the right names at the right types conforms in any order (example given).
V24 This is the general rule at every NamedTuple seam between author and framework.
V25 §14.7 states it for the trim problem's decisions and residuals.
V26 Downstream consumption already assumes it: the scatter writes each returned field into its own named cell. (§4.3)
V27 Therefore order-sensitivity would be incidental strictness rather than protection.
V28 Pairing by name costs nothing.
V29 The generated write reads each field by name and stores it into its cell; no permutation exists at runtime.
V30 Per-field reasoning happens on types at generation and emits no per-field instruction; that is how the economics hold. (D-053)
V31 The economics' one baked type test is resolved by dispatch rather than executed. (D-235)
V32 The canary (§7.5) verifies the fold empirically rather than by assertion.
V33 An error is a key-set mismatch or a per-field type mismatch, reported by the payload.
V34 A permutation is not an error.
V35 That is equally why the payload's diff never has to express one.
V36 [bold] At the nominal activation the check is an exact type match, no convert-on-write. (D-053)
V37 The nominal activation is the only one that ever runs in real time.
V38 It is decided at generation and absent from the conformant path. (D-235)
V39 The error can afford to be didactic (M_shaft example).
V40 Under a non-nominal activation the two leaf kinds the declaration distinguishes are checked differently. (§8.2)
V41 [bold] A walking (unpinned) leaf accepts exactly two types, the activation scalar or Float64. (D-053)
V42 The activation scalar is the fast path, the straight store.
V43 The executor embeds a Float64 as a zero-partial constant (convert through the leaf).
V44 Struct-valued ports use the standard cross-eltype constructor; a missing one fails loudly with both types named.
V45 [bold] An opaque leaf (§4.3) embeds nothing into a store, and is accepted there by identity alone. (D-237)
V46 At a wire the entry is a bound; a frozen opaque arrival is admitted as the producer's cell. (§6.1, D-264)
V47 Nothing else is accepted.
V48 [bold] The check is decided on the type, not leaf by leaf. (D-238)
V49 The arrival with Float64 positions lifted to the scalar wherever the declaration has one must be the declaration itself.
V50 So a differing field name, non-numeric type parameter or array mutability is refused.
V51 [bold] A pinned leaf takes the nominal-style exact check at every activation. (D-238)
V52 A pinned leaf is one wrapped as Pinned, or an Int, Bool or enum leaf that never walks.
V53 It takes that check because its declaration said the leaf never carries partials.
V54 An observed Dual there is the misplaced-pin error, the one honest cause.
V55 The didactic hint "remove its Pinned" is attached.
V56 The embedding is exact, not lenient.
V57 Promotion is airtight; there is no lossy Dual -> Float64 cast.
V58 So a Float64 observed at a walking leaf means no Dual entered its computation.
V59 Its true derivative along every seeded direction is zero, which the embedded constant says.
V60 This scopes the blanket convert-on-write rejection to the nominal check. (D-053)
V61 The guarded bug, silently zeroed partials, cannot arise from honest code.
V62 Because accidental Float64s from Dual operands are impossible (MethodError at the operation site).
V63 The residual is deliberate stripping (ForwardDiff.value), a stated intent, producing a silent zero in the Jacobian.
V64 That is the stop-gradient idiom.
V65 It is occasionally legitimate (frozen couplings, opaque non-Julia wrappers).
V66 Applied mid-expression it is equally invisible to a strict exact-match rule, so the leniency costs nothing.
V67 Stripping need not be invisible to the schema.
V68 [bold] The pinned leaf is the schema-visible freeze. (D-263)
V69 An author who means to strip declares Pinned{Float64} and strips inside the stage.
V70 The check holds the freeze to its word at every activation.
V71 Mid-expression stripping at an unpinned leaf remains legal and unseen.
V72 [bold] The check is uniform across all probed functions. (D-053)
V73 Each function is checked against its own predicate.
V74 [bold] x_deriv checks against X's own shape at the activation's T. (D-190)
V75 A scalar leaf expects T; an SArray leaf the same SArray at T. (§7.1)
V76 Its predicate is "every field scatters into its field's block at T".
V77 That predicate makes derivative completeness structural, not author discipline.
V78 Guards check against their probe-derived predicate form.
V79 s_update checks against its leaf's s shape.
V80 Handlers check against the §5.2 return law, key by key.
V81 [bold] x_projection checks against X's own shape at T, complete. (D-111)
V82 Complete because its result is written back to the buffer wholesale at both execution-order positions. (§5.3)
V83 Also complete because a projection with a mode-dependent branch first executes its second branch at run time.
V84 That is the same predicate as a handler's x key.
V85 [bold] The handler return's key set is checked first. (D-090)
V86 An unknown key, or one naming an undeclared store, is a build error with did-you-mean against {x, m} narrowed to existing stores.
V87 That is the bundle law's classification in the return direction.
V88 [bold] Per present key, x must be complete against the state field set; m may be partial. (D-053)
V89 x must also be conformant at T.
V90 m is checked by a names-subset-with-matching-types predicate, a type-level computation that folds when inferred.
V91 An absent key is not an error nor a no-op to diagnose; it says the handler does not touch that store.
V92 The asymmetry is storage-shaped: x flat buffer written back wholesale; m per-field stores, partial merge natural.
V93 [bold] The guard check is form-aware rather than a flat isa Bool. (D-053)
V94 Because guards have two admissible forms. (§2.1)
V95 Bool-form probed return is Bool; sign-form's is the nominal scalar.
V96 Guards run only at the nominal activation, so no parametrized-leaf case arises. (D-052)
V97 Any other probed return type is a build error naming both forms.
V98 Nothing further: the probed form is the detection policy, so no form/policy mismatch can be declared. (§10.4, D-179)
V99 [bold] The payload carries component path, function, event name on a handler's occurrence, field-level diff. (D-053, D-249)
V100 Simulation time is the carrier's, not the diagnostic's.
V101 At run time the failure travels as a species of StepError through the single catch site. (§13.4, D-059)
V102 That site's frame holds the boundary time and replay index.
V103 A build-time occurrence has no time to carry. (D-249)
V104 [bold] The source branch is deliberately absent from the payload. (D-053)
V105 A value does not say which branch produced it; the diff identifies it.
V106 [bold] The always-on input trace makes every such failure reproducible by replay. (D-053)
V107 The error names the boundary to replay to (to_boundary, §12.7).
V108 The catch site adds the loop-level nonfinite-state check as the failure's divergence sibling. (D-157)
