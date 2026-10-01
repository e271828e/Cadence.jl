### 9.5 The always-on conformance check

The [probe](#g-probe) validates each function *once*, on the initial state's branch.
The schema-authority bargain's second clause ("at first execution otherwise",
[§8.1][s8-1]) is discharged by leaving the probe's comparison permanently in place.
At the point where the [executor](#g-executor) (the compiled form of the stage
execution order) stores a stage return into the table, it holds the complete
expected return type at this [activation](#g-activation). That type is the type of the
[cells](#g-cell) this stage writes, as the probe fixed them at this activation. It is one
concrete `NamedTuple` type per ([component](#g-component), stage), the stage's declared
names at the types their cells hold ([§8.2][s8-2]). The write is generated over
that type and the return's type, so the test is decided when the write's
method is specialized, and no per-field instruction reaches the conformant
path ([D-235][d-235]). When the write's method is
generated, the return's key set is compared with the expected type's, and
each returned field is held to its cell's type under the relation below. A
conformant return type generates the straight stores and nothing else. A
non-conformant one generates a throw of the failure payload, raised the first
time that branch executes. For type-stable conformant code, the compiler
proves the return type, one method is generated, and no check instruction
exists to delete. For branch-divergent code, each return type the stage can
produce gets its own method, the union split the code already pays, and the
check is absent from every conformant one. The divergent branch's method is
the loud located error at its first execution. Type-unstable-but-conformant
code pays the dynamic dispatch it already bought, and nothing on top.

**The names are the pairing, and field order carries no semantics.**
`Expected`'s order is an internal fact. It is derived from `y_types`,
stage-filtered, an order no single declaration shows the author. The author
never reproduces it. A return spelling the right names at the right types
conforms in any order.
`(; P = M*ω, M_shaft = M)` and `(; M_shaft = M, P = M*ω)` are the same
return. This is the general rule at every `NamedTuple` [seam](#g-seam) between author
and framework ([§14.7][s14-7] states it for the trim problem's decisions and
residuals). It is also what downstream consumption already assumes. The
scatter writes each returned field into its own *named* cell ([§4.3][s4-3]).
Order-sensitivity in the check would therefore be incidental strictness
rather than protection. Pairing by name costs nothing. The generated write
reads each returned field by name and stores it into its cell, so no
permutation of the value exists at runtime. The per-field reasoning happens
on types at generation and emits no per-field instruction, which is how the
economics ([D-053][d-053]) hold. Its one baked type test is resolved by dispatch
rather than executed ([D-235][d-235]). The canary ([§7.5][s7-5]) verifies the fold
empirically rather than by assertion. What is an error is a key-set mismatch
or a per-field type mismatch, reported by the [payload](#g-payload) below. A permutation
is not an error at all, which is equally why that diff never has to express
one.

**Exact match at nominal, embed-accept at walking leaves.** At the
nominal activation, the only one that ever runs in real time, the check is an
exact type match, with no convert-on-write, decided at generation and absent
from the conformant path ([D-053][d-053], [D-235][d-235]). The error can afford to be
didactic: "field `M_shaft`: expected `Float64`, got `Int64` — return
`zero(x.ω)`, not `0`". Under a non-nominal activation (the build's typed
products at a given scalar type) the two leaf kinds the declaration ([§8.2][s8-2])
distinguishes are checked differently. A **walking leaf**, one the author left
unpinned, accepts exactly two types, the activation scalar or
`Float64`. The activation scalar is the fast path, the straight store. A
`Float64` the executor **embeds** as a zero-partial constant (`convert`
through the leaf). Struct-valued [ports](#g-port) use the standard cross-eltype
constructor, and a missing one fails loudly with both types named. An opaque
leaf ([§4.3][s4-3], [D-237][d-237]) embeds nothing into a store. It is accepted there
by identity alone. At a wire the entry is a bound, and a frozen opaque
arrival is admitted as the producer's cell ([§6.1][s6-1], [D-264][d-264]).
Nothing else is accepted. The check is decided on the type, not leaf by leaf.
The arrival with its `Float64` positions lifted to the scalar wherever the
declaration has one must be the declaration itself, so a field name, a
non-numeric type parameter or an array's mutability that differs is refused
like any other mismatch ([D-238][d-238]). A **[pinned](#g-walked) leaf**, one the author
wrapped as `Pinned`, or an `Int`, `Bool` or enum leaf that never walks, takes
the nominal-style exact check at *every* activation, because its declaration
said the leaf never carries partials. An observed `Dual` there is the
misplaced-pin error, that being the one honest cause. The didactic hint is
attached: "if `F` participates in differentiation, remove its `Pinned`". The
embedding is exact, not lenient. Promotion is airtight and there is no lossy
`Dual → Float64` cast, so a `Float64` observed at a walking leaf means
no `Dual` entered its computation. Its true derivative along every seeded
direction is zero, which is precisely what the embedded constant says. This
scopes the blanket convert-on-write rejection to the nominal check ([D-053][d-053]).
The bug that rejection guards against, silently zeroed partials, cannot arise
from honest code, because accidental `Float64`s from `Dual` operands are
impossible (`MethodError` at the operation site). The residual is
**deliberate stripping** (`ForwardDiff.value`), a stated intent to discard
partials, producing a silent zero in the Jacobian. That is the stop-gradient
idiom, occasionally legitimate, as with deliberately frozen couplings and
opaque non-Julia wrappers. Applied mid-expression it is equally invisible to a
strict exact-match rule, so the leniency costs nothing. What it need not be
is invisible to the schema. **The pinned leaf is the schema-visible freeze.**
An author who means to strip declares the leaf `Pinned{Float64}` and strips
inside the stage, and the check above holds the freeze to its word at every
activation. Stripping mid-expression at a leaf left unpinned remains legal and
remains unseen, as the sharp tool it is.

**Uniform across all probed functions.** `x_deriv` checks against
`X`'s own shape at the activation's `T` ([§7.1][s7-1]: a scalar leaf expects a
`T`, an `SArray` leaf the same `SArray` at `T`). Its predicate is "every field
scatters into its field's block at `T`", which is what makes derivative
completeness structural rather than a matter of author discipline. [Guards](#g-guard)
check against their probe-derived [predicate](#g-predicate) form (below), `s_update`
against its leaf's `s` shape, and handlers against the [§5.2][s5-2] return law,
key by key. `x_projection` checks against `X`'s own shape at `T`,
**complete**, since its result is written back to the [buffer](#g-buffer) wholesale at
both of the positions in the [execution order](#g-execution-order) ([§5.3][s5-3]) and a [projection](#g-projection) with a
mode-dependent branch first executes its second branch at run time. That is
the same predicate as a handler's `x` key.

**Handler returns, key by key.** The returned NamedTuple's key set is checked
first. An unknown key, or a key naming a store the component does not
declare, is a build error with [did-you-mean](#g-did-you-mean) against `{x, m}` narrowed to
the stores that exist. That is the [bundle law](#g-bundle)'s classification running in
the return direction. Then, per present key, `x` must be **complete** against
the state field set (and conformant at `T` like any state value), while `m`
may be **partial**, checked against a names-subset-with-matching-types
predicate, still a type-level computation that folds when inferred. An
absent key is not an error and not a no-op to diagnose. It is the handler
saying it does not touch that store. The completeness asymmetry is
storage-shaped. `x` must be complete because it lives in a flat buffer
written back wholesale, while `m` may be partial because `m` lives in
per-field stores where a partial merge is the natural write.

**Guards have two admissible forms** ([§2.1][s2-1]), so their check is form-aware
rather than a flat `isa Bool`. A `Bool`-form guard's probed return is `Bool`,
and a sign-form guard's is the nominal scalar. Guards run only at the nominal
activation ([D-052][d-052]), so no parametrized-leaf case arises here. Any other
probed return type is a build error naming both admissible forms. There is
nothing further to check. The probed form *is* the detection policy ([§10.4][s10-4],
[D-179][d-179]), so no form/policy mismatch can be declared.

**Failure payload.** The payload carries the component path, the function,
the event name on a handler's occurrence, and the field-level diff (missing /
unexpected / per-field expected-vs-observed). Simulation time is the
carrier's, not the diagnostic's. At run time the failure travels as a
[species](#g-species) of `StepError` through the single catch site ([§13.4][s13-4]), whose
frame holds the boundary time and the replay index, and a build-time
occurrence has no time to carry ([D-249][d-249]). Deliberately absent is the source
branch. A value does not say which branch produced it, and the diff identifies
it. The always-on input [trace](#g-trace) makes every such failure **reproducible by
[replay](#g-replay)**. The error
names the [boundary](#g-boundary) to replay to (`to_boundary`, [§12.7][s12-7]). The catch site adds
the loop-level nonfinite-state check as the failure's divergence sibling.
