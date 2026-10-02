## 7. State and data representation

### 7.1 Continuous state: structured immutable, flat backing

Each [continuous component](#g-continuous-component) declares its state by value (`x_init`, [§8.2][s8-2]). The
declaration is a NamedTuple whose leaves are drawn from a **deliberately closed
vocabulary, plain real scalars and `SArray`s (static vectors and matrices) of a
common eltype `T`**, and nothing else. `Int`s, enums and `Bool`s belong in
modes. Domain wrapper types (`RQuat`, `Ranged`) are not state leaves. An
attitude state is an `SVector{4,T}`, cast where rotation semantics are wanted,
as described below. The declaration is flat. Each field is one leaf, never a
`NamedTuple` of leaves. The condition algebra and the readers address a field
as one leaf ([§14.3][s14-3], [§14.4][s14-4]), and structure comes from the component tree, not
from the value ([D-094][d-094]). The framework does three things with the declaration.

- It computes a **flat layout** at build time, with compile-time offsets over
  one contiguous `Vector{T}` [buffer](#g-buffer) it owns.
- It **reconstructs** the typed immutable state value for a [component](#g-component) at each
  evaluation and passes it to every function receiving state views, under the
  argument rule of [§5.2][s5-2]. The reconstruction is field loads at known offsets,
  register-level, at zero cost.
- It receives immutable results back. Derivative functions return an `Ẋ`-typed
  value, which is scatter-stored into the flat `ẋ` buffer. Event handlers and
  [projection](#g-projection) return a new `X`, which is written back, with projection at the two
  positions in the [execution order](#g-execution-order) of [§5.3][s5-3].

**What `Ẋ` is.** With the leaf vocabulary closed, the answer takes one line. `Ẋ`
has exactly `X`'s shape at the [activation](#g-activation) scalar. A scalar leaf's derivative is
a `T`, and an `SArray` leaf's is the same `SArray` at `T`. This is the
vocabulary rule paying rent. An invariant-carrying leaf like a unit quaternion
has a derivative off its own type, and `Ẋ` would need a separate derivation.
Here the attitude leaf is an `SVector{4,T}` and so is its rate. The conformance
predicate is structural. *Each field of `x_deriv`'s return scatters
into its field's block at `T`* ([§9.5][s9-5] states the check). That makes derivative
completeness a property of the layout rather than of author discipline. There is
deliberately **no `derivative_type` hook** ([D-190][d-190]).

**The buffer is authoritative, and typed values are ephemeral reconstructions.**
Nobody outside the framework ever holds a mutable reference to state.
"Ephemeral" is literal. An isbits view materializes in the caller's frame for
exactly the duration of the call, and has no existence between calls. Where it
materializes, in registers or on the spilled stack, is the compiler's business.
Re-materializing is the same loads, and it is value-identical because the value
is immutable and the buffer is unchanged within a [sweep](#g-sweep).

Whether repeated reads within a sweep re-materialize or reuse the loads is
codegen freedom, in the literal sense that the freedom is the code generator's.
The [executor](#g-executor) (the compiled form of the stage execution order) is spelled
rebuild-per-call, and hoisting a repeated read is the code generator's CSE. The
legality condition of that CSE is exactly the buffer-unchanged-within-a-sweep
rule ([§9.7][s9-7]).

The complementary rule is **[one home per datum](#g-one-home-per-datum)** ([§5.2][s5-2]). The buffer holds `x`,
the stores hold `s` and `m`, and the table holds produced signals. No store ever
mirrors another. In particular there are no state [cells](#g-cell) in the table beyond
the declared [ports](#g-port) a component returns from `y_state` ([§5.3][s5-3]),
which are interface, not transport.

**The vocabulary is closed because views must materialize without running
anyone's invariants.** Scalars and `SArray`s have invariant-free constructors.
`SVector`'s stores its tuple, `NamedTuple` construction runs no user code, and
nothing normalizes or clamps. Building a view through ordinary public
construction is therefore bit-faithful automatically. `reconstruct(flatten(x))
== x` holds identically, with no constructor bypass, no `reinterpret`, and no
reliance on a custom struct's memory layout mirroring the buffer's.
Invariant-carrying leaves are closed ([D-094][d-094]). Domain semantics are instead an
**explicit, invariant-free cast at the point of use**, the conversion today's
`f_ode!` code performs on its raw views. Invariants live where the design
already put them, in `x_projection` at [boundaries](#g-boundary) and in writers. Handlers
build their returned values through ordinary constructors, and the condition
apply converts authored values through ordinary `convert` methods ([§14.3][s14-3]).
Constructors run on the write paths, never on views.

Against today's flat-`Vector` + `ComponentArrays`-views pattern, this buys five
things.

- There are no aliased mutable views, where who writes what is a matter of
  convention.
- Derivative completeness is **structural**. The returned `Ẋ` has every field by
  construction, so a forgotten `ẋ` entry is impossible rather than silently
  stale.
- State fields arrive as the declared scalars and `SArray`s, immutable. The
  domain wrapper, where wanted, is one explicit invariant-free cast (`RQuat(x.q,
  normalization = false)`). That is the conversion the mutable-views pattern
  performed implicitly, now visible and chosen.
- The flat vector still exists. Integrator compatibility (OrdinaryDiffEq or
  custom), trim solvers, HDF5 logging and linearization all get their arrays.
- The hand-written per-aircraft state-space mapping layer
  (`get_x_ss`/`assign_x_ss!`/`get_u_ss`/...) is deleted, replaced by the
  framework's canonical layout.

