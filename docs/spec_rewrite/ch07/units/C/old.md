### 7.3 Discrete state, modes, and workspace

Two homes sit outside the continuous [buffer](#g-buffer), and the rules they obey are
opposites. Discrete state and modes are state in the full sense. They are isbits
values that the framework owns and that a checkpoint copies wholesale. A
[workspace](#g-workspace) is mutable scratch, deliberately not state at all, governed by
contract rather than by checks.

#### Stores: discrete state and modes

**Rule.** Discrete state, a discrete leaf's `s`, and the modes `m` live in
**typed stores**, apart from the buffer that holds `x` ([§7.1][s7-1]). The framework
overwrites an `s` or `m` store when an update or a handler returns a new value.

An `s` or `m` store keeps the same immutable-value discipline as the table's
[cells](#g-cell), in a separate home. The vocabulary of [§4.1][s4-1] never counts a store
as a cell. The `s` and `m` stores never touch the integrator buffer, and no
arithmetic is ever done on them.

**Rule.** Every field of an `s` or `m` store value is **isbits or a `Symbol`**. Isbits is an
immutable value that holds no references, transitively. Enums, integers,
`Bool`s, `SArray`s and nested isbits structs all qualify. A `Symbol` is admitted
as the idiomatic label. It is interned, immutable and never freed, so it copies
as a pointer to permanent data and serializes as its name. The table admits it
on the same grounds, as an opaque leaf ([§4.3][s4-3]). A `String`, an array,
or a struct holding either does not qualify, and neither does a struct nesting a
`Symbol`. The structure step checks every `s_init` and `m_init` field and reports a
violation as `IllegalStoreField` ([§9.1][s9-1], [Appendix C][sC], [D-231][d-231]).

**Why.** State is what changes between [ticks](#g-tick). Bulk data and labels do not, and
their home is the component instance. The frozen-reference latitude signals
enjoy ([§4.1][s4-1]) exists for field handles ([§4.4][s4-4]), and no store needs it. Isbits is
what makes the rest of this section literal. Copying an `s` or `m` store copies
bits, so checkpoint and [replay](#g-replay) of the entire discrete side is "copy the
store values", and a stored value has one fixed layout per component.

#### Workspace

A workspace serves heavy algorithms, such as an n≈20 Kalman filter.

**Rule.** A workspace is [component](#g-component)-declared mutable scratch, instantiated by the
framework. It arrives as the `ws` field of the [bundle](#g-bundle) (the NamedTuple of
zero-copy views a component function receives) in every bundle-receiving
function of the declaring component ([§5.2][s5-2]). `x_projection` is positional and
receives none.

**Rule.** A workspace is **excluded from state semantics**. It is not
snapshotted, not replayed and never a condition target ([§14.1][s14-1]). It must carry no
information between calls.

The framework **never inspects or mutates a workspace**. The workspace is an
opaque, opt-in escape hatch from value semantics, used at the author's own risk,
and its rules are contract, not checks. At call entry, contents are unspecified
beyond the structure the allocator itself established. A plan or factorization
configured at allocation is valid from then on. Scratch is garbage until written
this call, and nothing a previous call left behind may be relied upon. No
poisoning of scratch is attempted ([D-183][d-183]).

**Declared by allocation.** The well-known method *is* the allocator.

```julia
ws_init(c::KF, ::Type{T}) where {T} =
    (P = Matrix{T}(undef, c.n, c.n), x̂ = Vector{T}(undef, c.n))
```

**Rule.** `ws_init(::C, ::Type{T})` takes the activation scalar on both
[tiers](#g-tier), and it is the one declaration that does. A discrete allocator
receives `Float64` at every activation, because the discrete tier never runs at
another scalar ([§9.4][s9-4]). `x_init`, `s_init`, `m_init` and the contracts take
the component alone on every tier.

**Why.** State and cells re-scalar through the walk ([§7.2][s7-2]), so those
declarations never need `T`. Scratch is allocated, not retyped. A factorization,
a plan or a buffer sized by the scalar has no rebuild the framework could
perform, so the eltypes can come from nowhere but the allocator's own argument
([D-077][d-077], [D-263][d-263]).

The allocator is called once per [activation](#g-activation) (the build's typed products at a
given scalar type) and once per scratch-store set ([§14.8][s14-8]). Sizes come from the
instance, and eltypes from the activation. Nothing downstream derives from a
workspace's type, and mistyped scratch detonates loudly at the `Dual` [probe](#g-probe).

The `undef` spelling is the recommended idiom and the sole visible marker that
contents are meaningless. It puts that fact in the declaration, which is the
by-allocation convention this store actually lives in. Declaration is by
allocation, never by initial value ([D-077][d-077]). The `init_` prefix means
*establish*, as the device contract's `init!` does ([§11.6][s11-6]), and carries no claim
that the allocated contents are a value ([D-220][d-220]).

**Available on both tiers.** Nothing in the workspace contract is tier-specific,
and a continuous workspace simply joins the `T`-generic surface. Under a `Dual`
activation the allocator is called at `Dual`, and the in-place math runs through
Julia's generic fallbacks. No BLAS is involved. Activations probe and linearize,
they don't run marathons.

The continuous side runs many calls per [boundary](#g-boundary), for RK stages, localization
trial evaluations and event re-[sweeps](#g-sweep). That multiplicity makes the
no-information-between-calls contract *more* essential there, not less.

**The [blessed](#g-blessed) idiom for zero-allocation [ticks](#g-tick) with immutable `s`.** Do the
in-place math (`mul!`, `cholesky!`, BLAS) on the workspace. At the end, snapshot
into an isbits container and return it, as in `s = KFState(SVector{20}(ws.x̂),
SMatrix{20,20}(ws.P))`.

**The blessed idiom for a PRNG in a discrete leaf.** A generator object such as
`Xoshiro` is mutable, so it is scratch and lives in the workspace, allocated
once. The values that determine its next draw are immutable, so they are state
and live in `s`, which is what makes replay deterministic ([§2.2][s2-2]). The tick loads
them into the generator at entry and snapshots them back at exit, in the same
shape as the Kalman idiom above.

```julia
s_init(::Noise)         = (rng = (0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667),)
ws_init(::Noise, ::Type) = (rng = Xoshiro(0, 0, 0, 0),)

function s_update(c::Noise, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng        # load the words at entry
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)       # snapshot them back
end
```

Rematerializing the generator from its values each tick reads naturally and
allocates. A sampler with an out-of-line tail lets the object escape ([D-231][d-231]).

Construction and storage of large `SArray`s are cheap and compile fine. The
StaticArrays "codegen catastrophe" lives in its *operations*, the unrolled
matmuls, which are never called on snapshots.

The discipline is that snapshot values are for storage, logging and element
access only, never arithmetic. It is optionally enforceable by an op-forbidding
`ValueSnapshot{N,T}` wrapper, an `NTuple` with only `getindex` and iteration,
structurally what `SArray` is minus the methods. The practical ceiling is a few
KB comfortable and tens of KB defensible. Beyond that, value semantics stop
making sense.

#### Double-buffered mutable state (deferred)

Double-buffered mutable state is a possible future extension only, deferred
([D-013][d-013]).

