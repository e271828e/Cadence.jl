## 7. State and data representation

This chapter fixes where data lives and how each home holds its values.
Continuous state is an immutable value over a flat buffer the framework owns,
and the continuous path is generic over its scalar type. Discrete state and
modes live in stores, and scratch lives in a workspace. [§7.1][s7-1] covers continuous
state, [§7.2][s7-2] numeric genericity, [§7.3][s7-3] discrete state, modes and the workspace,
[§7.4][s7-4] the fused-evaluation lineage that led to the interfaces of [§5.2][s5-2], and [§7.5][s7-5]
the allocation policy.

### 7.1 Continuous state: structured immutable, flat backing

This section fixes how a [continuous component](#g-continuous-component) (the hybrid primitive, with
continuous state, flow and events) declares its state, and how the framework
lays that state out, reads it and writes it back. It covers, in order, the
closed leaf vocabulary, the three things the framework does with a declaration,
the buffer and its views, why the vocabulary is closed, the shape of `Ẋ`, and
what the design buys against FlightCore's mutable-views pattern.

Each continuous component declares its state by value (`x_init`,
[§8.2][s8-2], [D-033][d-033]). The declaration is a NamedTuple
([D-247][d-247]). **Its leaves are drawn from a deliberately closed
vocabulary**, plain real scalars and `SArray`s (static vectors and matrices) of
a common eltype `T`, and nothing else ([D-094][d-094]). `Int`s, enums and
`Bool`s belong in modes. Domain wrapper types are not state leaves either. Two
such types are `RQuat`, a rotation quaternion type with a `normalization`
keyword, and `Ranged`, a clamped scalar. An attitude state is an
`SVector{4,T}`, cast where rotation semantics are wanted, as described below.
The structure step refuses a field outside the vocabulary as
`IllegalStateLeaf` ([§9.1][s9-1]). [§8.2][s8-2] shows the kind's messages.

**The declaration is flat** ([D-094][d-094]). Each field is one leaf, never a `NamedTuple` of
leaves. The condition algebra and the readers address a field as one leaf
([§14.3][s14-3], [§14.4][s14-4]), and structure comes from the [component](#g-component) tree, not from the value.

The framework does three things with the declaration.

- It computes a flat layout at build time. The layout has compile-time offsets
  into one contiguous `Vector{T}` that the framework owns, the
  [buffer](#g-buffer).
- It reconstructs the typed immutable state value for a component at each
  evaluation. The value's type, `X`, is derived from `x_init`. The framework
  passes that value to every function receiving state [views](#g-view) (zero-copy
  reconstructions of a store), under the argument rule of [§5.2][s5-2] ([D-035][d-035]). The
  reconstruction is field loads at known offsets, register-level, at zero cost.
- It receives immutable results back. Derivative functions return an `Ẋ`-typed
  value, which is scatter-stored into the flat `ẋ` buffer. A handler's `x` key
  and the [projection](#g-projection) (the optional hook `x_projection`) carry a new `X`, which
  is written back. Projection's write-back happens at the two positions in the
  [execution order](#g-execution-order) of [§5.3][s5-3] ([D-111][d-111]).

**The buffer is authoritative, and typed values are ephemeral
reconstructions** ([D-010][d-010]). Nobody outside the framework ever holds a
mutable reference to state. "Ephemeral" is literal. An isbits view
materializes in the caller's frame for exactly the duration of the call, and
has no existence between calls. Where it materializes, in registers or on the
spilled stack, is the compiler's business. Re-materializing is the same loads,
and it is value-identical because the value is immutable and the buffer is
unchanged within a [sweep](#g-sweep) (one pass through the execution order). This
buffer-unchanged-within-a-sweep rule is exactly the legality condition of the
code generator's CSE, the common-subexpression elimination that hoists
repeated reads of views rebuilt per call ([§9.7][s9-7], [D-288][d-288]).

The complementary rule is [one home per datum](#g-one-home-per-datum) (each
datum has exactly one home), stated in [§5.2][s5-2] ([D-035][d-035]). In
particular there are no state [cells](#g-cell) in the
[signal table](#g-signal-table) beyond the declared [ports](#g-port) a
component returns from `y_state` ([§5.3][s5-3], [D-252][d-252]), which are
interface, not transport.

The vocabulary is closed because views must materialize without running
anyone's invariants. Scalars and `SArray`s have invariant-free constructors.
`SVector`'s stores its tuple, `NamedTuple` construction runs no user code, and
nothing normalizes or clamps. Building a view through ordinary public
construction is therefore bit-faithful automatically. `reconstruct(flatten(x))
== x` holds identically, with no constructor bypass, no `reinterpret`, and no
reliance on a custom struct's memory layout mirroring the buffer's.
Invariant-carrying leaves are excluded from the vocabulary ([D-094][d-094]).

Domain semantics are instead an explicit, invariant-free cast at the point of
use. It is the conversion that `f_ode!`, FlightCore's in-place derivative
function, performed on its raw views. Invariants live where the design already
put them, in `x_projection` at [boundaries](#g-boundary) (published consistency points) and in
writers. Handlers build their returned values through ordinary constructors, and
the condition apply converts authored values through ordinary `convert` methods
([§14.3][s14-3]). Constructors run on the write paths, never on views.

With the leaf vocabulary closed, the shape of `Ẋ` takes one line to state. `Ẋ`
has exactly `X`'s shape at the [activation](#g-activation) scalar (the scalar type `T` at which
the build types the model). A scalar leaf's derivative is a `T`, and an `SArray`
leaf's is the same `SArray` at `T`. This is what the closed vocabulary buys. An
invariant-carrying leaf like a unit quaternion has a derivative off its own
type, and `Ẋ` would need a separate derivation. Here the attitude leaf is an
`SVector{4,T}`, and so is its rate. The conformance predicate is structural.
*Each field of `x_deriv`'s return scatters into its field's block at `T`* ([§9.5][s9-5]
states the check). That makes derivative completeness a property of the layout
rather than of author discipline. There is deliberately no `derivative_type`
hook ([D-190][d-190]).

FlightCore's pattern was a flat `Vector` read through `ComponentArrays` views,
which are mutable views into the flat vector. Against that pattern and the
Flight.jl code around it, this design buys five things.

- There are no aliased mutable views, where who writes what is a matter of
  convention.
- Derivative completeness is structural. The returned `Ẋ` has every field by
  construction, so a forgotten `ẋ` entry is impossible rather than silently
  stale.
- State fields arrive as the declared scalars and `SArray`s, immutable. The
  domain wrapper, where wanted, is one explicit invariant-free cast
  (`RQuat(x.q, normalization = false)`). That is the conversion the
  mutable-views pattern performed implicitly, now visible and chosen.
- The flat vector still exists. Integrator compatibility (OrdinaryDiffEq or
  custom), trim solvers, HDF5 logging and linearization all get their arrays.
- Flight.jl's hand-written per-aircraft state-space mapping layer
  (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout ([D-072][d-072]).
