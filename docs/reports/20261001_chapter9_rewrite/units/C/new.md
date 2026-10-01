### 9.5 The always-on conformance check

The [probe](#g-probe) validates each function *once*, on the initial state's
branch. The schema-authority bargain's second clause ("at first execution
otherwise", [§8.1][s8-1]) is discharged by leaving the probe's comparison
permanently in place.

#### The generated write

At the point where the [executor](#g-executor) (the compiled form of the
stage [execution order](#g-execution-order)) stores a stage return into the
table, it holds the complete expected return type at this
[activation](#g-activation). The expected type is the type of the
[cells](#g-cell) this stage writes, as the probe fixed them at this
activation. It is one concrete `NamedTuple` type per
([component](#g-component), stage), the stage's declared names at the types
their cells hold ([§8.2][s8-2]). **The write is generated over that type and
the return's type** ([D-235][d-235]). So the test is decided when the write's
method is specialized, and no per-field instruction reaches the conformant
path.

When the write's method is generated, the return's key set is compared with the
expected type's. At the same point, each returned field is held to its cell's
type under the relation below. A conformant return type generates the straight
stores and nothing else. A non-conformant one generates a throw of the failure
payload, raised the first time that branch executes.

How the stage's code is typed decides what the check costs it:

- For type-stable conformant code, the compiler proves the return type, one
  method is generated, and no check instruction exists to delete.
- For branch-divergent code, each return type the stage can produce gets its
  own method, the union split the code already pays. The check is absent from
  every conformant one. The divergent branch's method is the loud located
  error at its first execution.
- Type-unstable-but-conformant code pays the dynamic dispatch it already
  bought, and nothing on top.

#### Pairing by name

**The names are the pairing**, and field order carries no semantics
([D-151][d-151]). The expected type's order is an internal fact. It is derived
from `y_types`, stage-filtered, an order no single declaration shows the author.
The author never reproduces it. A return spelling the right names at the right
types conforms in any order. The following two are the same return, of a
shaft's power `P` and torque `M_shaft`.

```julia
(; P = M*ω, M_shaft = M)
(; M_shaft = M, P = M*ω)
```

This is the general rule at every `NamedTuple` [seam](#g-seam) between author
and framework. [§14.7][s14-7] states it for the trim problem's decisions and
residuals. It is also what downstream consumption already assumes. The scatter
writes each returned field into its own *named* cell ([§4.3][s4-3]).
Order-sensitivity in the check would therefore be incidental strictness rather
than protection.

Pairing by name costs nothing. The generated write reads each returned field by
name and stores it into its cell, so no permutation of the value exists at
runtime. The per-field reasoning happens on types at generation and emits no
per-field instruction, which is how the check's economics ([D-053][d-053]) hold.
The check's one baked type test is resolved by dispatch rather than executed
([D-235][d-235]). The canary ([§7.5][s7-5]) verifies empirically that the check
folds away, rather than by assertion.

What is an error is a key-set mismatch or a per-field type mismatch, reported
by the [payload](#g-payload) below. A permutation is not an error at all. That
is equally why the payload's diff never has to express one.

#### Exact match and embed-accept

At the nominal activation, the only one that ever runs in real time, **the
check is an exact type match**, with no convert-on-write ([D-053][d-053]). It
is decided at generation and absent from the conformant path ([D-235][d-235]).
The error can afford to be didactic, as in "field `M_shaft`: expected
`Float64`, got `Int64` — return `zero(x.ω)`, not `0`".

Under a non-nominal activation (the build's typed products at a given scalar
type), the two leaf kinds the declaration ([§8.2][s8-2]) distinguishes,
walking and pinned, are checked differently. An opaque leaf has a rule of its
own. **A walking leaf, one
the author left unpinned, accepts exactly two types**, the activation scalar or
`Float64` ([D-053][d-053]). The activation scalar is the fast path, the
straight store. The executor embeds a `Float64` as a zero-partial constant
(`convert` through the leaf). Struct-valued [ports](#g-port) use the standard
cross-eltype constructor, and a missing one fails loudly with both types
named.

**An opaque leaf ([§4.3][s4-3]) embeds nothing into a store**, and it is
accepted there by identity alone ([D-237][d-237]). At a wire the entry is a
bound, and a frozen opaque arrival is admitted as the producer's cell
([§6.1][s6-1], [D-264][d-264]).

Nothing else is accepted. **The check is decided on the type**, not leaf by
leaf ([D-238][d-238]). The arrival with its `Float64` positions lifted to
the scalar wherever the declaration has one must be the declaration itself.
So a field name, a non-numeric type parameter or an array's mutability that
differs is refused like any other mismatch.

A [pinned](#g-walked) leaf takes the nominal-style exact check at *every*
activation ([D-238][d-238], [D-263][d-263]). A pinned leaf is one the author
wrapped as `Pinned`, or an `Int`, `Bool` or enum leaf that never walks. It takes
that check because its declaration said the leaf never carries partials. An
observed `Dual` there is the misplaced-pin error, that being the one honest
cause. The didactic hint is attached, "if `F` participates in differentiation,
remove its `Pinned`".

The embedding is exact, not lenient. Promotion is airtight and there is no
lossy `Dual → Float64` cast. So a `Float64` observed at a walking leaf means no
`Dual` entered its computation. Its true derivative along every seeded
direction is zero, which is precisely what the embedded constant says. This
scopes the blanket convert-on-write rejection to the nominal check
([D-053][d-053]).

#### Deliberate stripping

The bug the convert-on-write rejection guards against, silently zeroed
partials, cannot arise from honest code. The reason is that accidental
`Float64`s from `Dual` operands are impossible (`MethodError` at the operation
site). The residual is
deliberate stripping (`ForwardDiff.value`), a stated intent to discard
partials, producing a silent zero in the Jacobian. That is the stop-gradient
idiom. It is occasionally legitimate, as with deliberately frozen couplings
and opaque non-Julia wrappers. Applied mid-expression it is equally invisible
to a strict exact-match rule, so the leniency costs nothing.

But stripping need not be invisible to the schema. **The pinned leaf is
the schema-visible freeze** ([D-263][d-263]). An author who means to strip
declares the leaf `Pinned{Float64}` and strips inside the stage. The check
above holds the freeze to its word at every activation. Stripping
mid-expression at a leaf left unpinned remains legal and remains unseen, as
the sharp tool it is.

#### Per-function predicates

**The check is uniform across all probed functions** ([D-053][d-053]). Each
function is checked against its own predicate.

- **`x_deriv` checks against `X`'s own shape** at the activation's `T`
  ([D-190][d-190]). A scalar leaf expects a `T`, and an `SArray` leaf the same
  `SArray` at `T` ([§7.1][s7-1]). Its predicate is "every field scatters into
  its field's block at `T`". That predicate is what makes derivative
  completeness structural rather than a matter of author discipline.
- `s_update` checks against its leaf's `s` shape.
- Handlers check against the [§5.2][s5-2] return law, key by key.
- [Guards](#g-guard) check against their probe-derived
  [predicate](#g-predicate) form (below).
- **`x_projection` checks against `X`'s own shape** at `T`, complete
  ([D-111][d-111]). It is complete because its result is written back to the
  [buffer](#g-buffer) wholesale at both of the positions in the execution order
  ([§5.3][s5-3]), and because a [projection](#g-projection) with a
  mode-dependent branch first executes its second branch at run time. That is
  the same predicate as a handler's `x` key.

#### Handler returns

**The returned NamedTuple's key set is checked first** ([D-090][d-090]). An
unknown key, or a key naming a store the component does not declare, is a
build error with [did-you-mean](#g-did-you-mean) against `{x, m}` narrowed to
the stores that exist. That is the [bundle law](#g-bundle)'s classification
running in the return direction.

Then, per present key, `x` must be complete against the state field set,
while `m` may be partial ([D-053][d-053], [D-090][d-090]). `x` must also
be conformant at `T` like any state value. `m` is checked against a
names-subset-with-matching-types predicate, still a type-level computation
that folds when inferred. An absent key is not an error and not a no-op to
diagnose. It is the handler saying it does not touch that store.

The completeness asymmetry is storage-shaped. `x` must be complete because it
lives in a flat buffer written back wholesale. `m` may be partial because `m`
lives in per-field stores where a partial merge is the natural write.

#### Guard forms

The guard check is form-aware rather than a flat `isa Bool`
([D-053][d-053]). The reason is that guards have two admissible forms
([§2.1][s2-1]). A `Bool`-form guard's probed return is `Bool`, and a
sign-form guard's is the nominal scalar. Guards run only at the nominal
activation ([D-052][d-052]), so no parametrized-leaf case arises here. Any
other probed return type is a build error naming both admissible forms.

There is nothing further to check. The probed form *is* the detection policy
([§10.4][s10-4], [D-179][d-179]), so no form/policy mismatch can be declared.

#### The failure payload

**The payload carries the component path, the function, the event name on a
handler's occurrence, and the field-level diff** (missing / unexpected /
per-field expected-vs-observed) ([D-053][d-053], [D-249][d-249]). Simulation
time is the carrier's, not the diagnostic's. At run time the failure travels
as a [species](#g-species) of `StepError` through the single catch site
([§13.4][s13-4], [D-059][d-059]). That site's frame holds the boundary time
and the replay index. A build-time occurrence has no time to carry
([D-249][d-249]).

**The source branch is deliberately absent from the payload**
([D-053][d-053]). A value does not say which branch produced it, and the diff
identifies it.

The always-on input [trace](#g-trace) makes every such failure reproducible
by [replay](#g-replay) ([D-053][d-053]). The error names the
[boundary](#g-boundary) to replay to (`to_boundary`, [§12.7][s12-7]). The
catch site adds the loop-level nonfinite-state check as the failure's
divergence sibling ([D-157][d-157]).
