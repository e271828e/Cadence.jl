module Blocks

import ..Redstone: AbstractComponent, Pinned, StateEvent,
    x_init, s_init, m_init, u_types, y_types, y_direct, y_state, x_deriv, s_update,
    state_events, local_wires, input_wires, output_wires, sample_times, transparent_container
using StaticArrays: StaticArray, SMatrix, SVector, SOneTo, SUnitRange, similar_type
using LinearAlgebra: I
import ForwardDiff

# The standard component library (§13.7, D-313). Written as a user's component
# file is: the import list above is its whole reach into the parent, so every
# block here is an ordinary component the framework knows nothing of.

# --- the junction (§6.2, D-311) -------------------------------------------------

"""
    Junction{In, Out, N}(f)

The N-to-1 block (§6.2): inputs `in1` to `inN` at `In`, one output `out` at
`Out`, and `out = f(in1, …, inN)`, the fold applied in positional order. A
stateless continuous leaf. The fold is instance data and `F` is inferred from
it. A custom fold, a weighted blend or a mass-properties composition, is written
at the site.

The fold is stateless and declares no events, so a discontinuity written into
it lands wherever it lands inside a step (§2.1). A clamp is fine, since its
kink is second-order downstream, and so is a branch on a `Bool` that flips at a
boundary, as a saturation code does. A branch on a continuous quantity is a
mode made silently, which the moded blocks exist to declare.
"""
struct Junction{In, Out, N, F} <: AbstractComponent
    f::F
end
(::Type{Junction{In, Out, N}})(f) where {In, Out, N} = Junction{In, Out, N, typeof(f)}(f)

"""
    SumJunction{V, N}()

The summing junction: the `Junction` at `+`, `N` inputs and the output at
`V` (§6.2).
"""
const SumJunction{V, N} = Junction{V, V, N, typeof(+)}

"""
    Or{N}()

The `Bool` gate at `|` over `N` inputs (§13.7): one consolidated `Bool` for a
consumer that wants one.
"""
const Or{N}  = Junction{Bool, Bool, N, typeof(|)}

"""
    And{N}()

The `Bool` gate at `&` over `N` inputs (§13.7).
"""
const And{N} = Junction{Bool, Bool, N, typeof(&)}

pack(args...) = SVector(args)

"""
    Pack{V, N}()

The pack: the `Junction` at `pack`, `N` inputs at `V` and the output at
`SVector{N, V}` (§13.7). The fold is the named function `pack` and not
`SVector`, whose type is a `UnionAll` that fixes no method, so the sweep would
dispatch on it at every call and allocate.
"""
const Pack{V, N} = Junction{V, SVector{N, V}, N, typeof(pack)}

(::Type{SumJunction{V, N}})() where {V, N} = SumJunction{V, N}(+)
(::Type{Or{N}})() where {N} = Or{N}(|)
(::Type{And{N}})() where {N} = And{N}(&)
(::Type{Pack{V, N}})() where {V, N} = Pack{V, N}(pack)

x_init(::Junction) = (;)
u_types(::Junction{In, Out, N}) where {In, Out, N} =
    NamedTuple{ntuple(i -> Symbol(:in, i), N)}(ntuple(_ -> In, N))
y_types(::Junction{In, Out}) where {In, Out} = (out = Out,)
y_direct(j::Junction, (; u)) = (out = j.f(u...),)

# --- the structure blocks (§13.7, D-313) ----------------------------------------

@generated unpack_names(::Val{N}) where {N} = ntuple(i -> Symbol(:out, i), N)

"""
    Unpack{V, N}()

The inverse of `Pack`: one input `in` at `SVector{N, V}`, and `N` outputs `out1`
to `outN` at `V`, `outi = in[i]`. A stateless continuous leaf. The output names
come from the generated `unpack_names`, which hands the body a constant tuple,
where names built in the body would allocate at every sweep.
"""
struct Unpack{V, N} <: AbstractComponent end
x_init(::Unpack) = (;)
u_types(::Unpack{V, N}) where {V, N} = (in = SVector{N, V},)
y_types(::Unpack{V, N}) where {V, N} = NamedTuple{unpack_names(Val(N))}(ntuple(_ -> V, N))
y_direct(::Unpack{V, N}, (; u)) where {V, N} = NamedTuple{unpack_names(Val(N))}(Tuple(u.in))

# --- the leaf blocks (§13.7, D-312) ---------------------------------------------

"""
    Constant(value)

The source block: no inputs, no state, and `out` publishes `value` from stage 1.
A stateless continuous leaf, so discrete consumers read it as well (§13.7).

`out` is pinned at `V`: a constant is never seeded, so it carries zero partials
under every `Dual` activation, and a tolerant consumer accepts it as a frozen
arrival. The value is instance data, not an overridable default; a source set
from outside is a root input (§11.3).
"""
struct Constant{V} <: AbstractComponent
    value::V
end
x_init(::Constant) = (;)
y_types(::Constant{V}) where {V} = (out = Pinned{V},)
y_state(c::Constant, _) = (out = c.value,)

"""
    UnitDelay(v0)

A discrete leaf, the tier's native `z⁻¹` (§10.6). `out` publishes the stored
value from stage 1, `v0` at the first publication, and each tick stores `in` for
the next one. Its store is isbits (D-231), which bounds `V`.

It breaks an algebraic loop (§5.5), and that is a modelling decision: placed
in a continuous loop it moves the signal onto the discrete tier and inserts a
`Δt_base`-scale zero-order hold.
"""
struct UnitDelay{V} <: AbstractComponent
    v0::V
end
s_init(delay::UnitDelay) = (v = delay.v0,)
u_types(::UnitDelay{V}) where {V} = (in = V,)
y_types(::UnitDelay{V}) where {V} = (out = V,)
y_state(::UnitDelay, (; s)) = (out = s.v,)
s_update(::UnitDelay, (; u)) = (v = u.in,)

"""
    Freeze{V}()

The declared stop-gradient (§13.7): `out` is `in` with its partials dropped,
pinned at `V`, so a walking producer may feed a pinned entry through it. At
nominal it is the identity. Every Jacobian along the path then reads a zero
coupling, which is the modelling decision it states. `V` is a `Real` or a
`StaticArray` of them; any other `V` is refused at the spelling.
"""
struct Freeze{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent end
x_init(::Freeze) = (;)
u_types(::Freeze{V}) where {V} = (in = V,)
y_types(::Freeze{V}) where {V} = (out = Pinned{V},)
y_direct(::Freeze, (; u)) = (out = ForwardDiff.value.(u.in),)

# --- the discrete tier (§7.3, §10.5, D-313) -------------------------------------

"""
    DiscreteIntegrator(; s0 = 0.0)

The discrete integrator: one store field `q` from `s0`, advanced each tick by
forward Euler, `q⁺ = q + Δt in`, and `out` publishing `q` from stage 1, so the
block breaks an algebraic loop as `UnitDelay` does (§5.5). `Δt` is the
component's own period (§10.5), so the integral is per second at any rate. `V`
is `Float64` or a static array of `Float64`, taken from `float(s0)`, so an
integer `s0` qualifies. The tier pins wholesale (D-263): under a `Dual`
activation the block holds its last value (§9.4).
"""
struct DiscreteIntegrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    s0::V
end
DiscreteIntegrator(; s0 = 0.0) = DiscreteIntegrator(float(s0))
s_init(c::DiscreteIntegrator) = (q = c.s0,)
u_types(::DiscreteIntegrator{V}) where {V} = (in = V,)
y_types(::DiscreteIntegrator{V}) where {V} = (out = V,)
y_state(::DiscreteIntegrator, (; s)) = (out = s.q,)
s_update(::DiscreteIntegrator, (; s, u, Δt)) = (q = s.q + Δt * u.in,)

"""
    DiscreteLimitedIntegrator(; lower, upper, s0 = zero(lower))

The discrete integrator held between `lower` and `upper`: `q⁺ = clamp(q + Δt in,
lower, upper)` from `s0`, and `out` publishing `q` from stage 1. The continuous
`LimitedIntegrator`'s mode and four events are this one `clamp`, with no mode
store and no localization. A second output, `saturation`, publishes the same
`Int8` code read off the state, also from stage 1: `1` at `upper`, `-1` at
`lower` and `0` between. At a limit with the input already pointing inward, the
code reads saturated until the next tick moves the state off.

Over a static vector, the limits and the codes are componentwise, and
`saturation` publishes a static vector of `Int8`. `lower < upper`,
componentwise over a vector. `s0`, `lower` and `upper` are promoted to one `V`,
which is `Float64` or a static array of `Float64`, and taken by `float`, so
integer values qualify.
"""
struct DiscreteLimitedIntegrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    s0::V
    lower::V
    upper::V
end
function DiscreteLimitedIntegrator(; lower, upper, s0 = zero(lower))
    s0, lower, upper = float.(promote(s0, lower, upper))
    DiscreteLimitedIntegrator(s0, lower, upper)
end
saturation_code(q, lower, upper) = q >= upper ? Int8(1) : q <= lower ? Int8(-1) : Int8(0)
s_init(c::DiscreteLimitedIntegrator) = (q = c.s0,)
u_types(::DiscreteLimitedIntegrator{V}) where {V} = (in = V,)
y_types(::DiscreteLimitedIntegrator{V}) where {V <: Real} = (out = V, saturation = Int8)
y_types(::DiscreteLimitedIntegrator{V}) where {V <: StaticArray} = (out = V, saturation = similar_type(V, Int8))
y_state(c::DiscreteLimitedIntegrator, (; s)) =
    (out = s.q, saturation = saturation_code.(s.q, c.lower, c.upper))
s_update(c::DiscreteLimitedIntegrator, (; s, u, Δt)) = (q = clamp.(s.q + Δt * u.in, c.lower, c.upper),)

"""
    RateLimiter(; rising, falling = rising, s0 = 0.0)

The rate limiter: `out` follows `in`, moving at most `rising Δt` up and
`falling Δt` down per tick. `Δt` is the component's own period (§10.5), so both
rates are per second, positive and pinned at `Float64`. One store field `v`
holds the previous output, and each tick stores `out`:

    out = v + clamp(in - v, -falling Δt, rising Δt)

`s0` is the previous output at the first tick, so the output at `t₀` is already
one slew step from it.

`out` reads `in`, so the block is feedthrough (§5.3), and a loop closed on it
through a memoryless path is refused. A form publishing the stored value from
stage 1 would break that loop, but it lags its input by one tick at every rate:
it is this block followed by a `UnitDelay`, a modelling decision (§5.5) the
model makes by placing the delay. `V` is `Float64` or a static array of
`Float64`, taken from `float(s0)`, and over a vector the slew is componentwise.
"""
struct RateLimiter{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    rising::Float64
    falling::Float64
    s0::V
end
function RateLimiter(; rising, falling = rising, s0 = 0.0)
    s0 = float(s0)
    RateLimiter{typeof(s0)}(rising, falling, s0)
end
s_init(c::RateLimiter) = (v = c.s0,)
u_types(::RateLimiter{V}) where {V} = (in = V,)
y_types(::RateLimiter{V}) where {V} = (out = V,)
y_direct(c::RateLimiter, (; s, u, Δt)) = (out = s.v + clamp.(u.in - s.v, -c.falling * Δt, c.rising * Δt),)
s_update(::RateLimiter, (; y)) = (v = y.out,)

# --- the noise source (§7.3, §2.2, D-231, D-313) --------------------------------

"""
    GaussianWhiteNoise(; seed, μ = nothing, σ = nothing, psd = nothing)

A discrete Gaussian white noise process: at each tick `out` publishes an
independent sample of mean `μ` and standard deviation `σ`, from stage 1. The
sample is a pure function of `seed` and the tick count `k`, the one store field
(D-231), so the stage draws, no generator or workspace is needed, and replay
reproduces the stream (§2.2). After a tick the store holds the next sample's
index, so `k` reads `N + 1` once the block has ticked `N` times past `t₀`. Two
blocks with one seed publish one stream, so independent sources take distinct
seeds.

Exactly one of `σ` and `psd` is given. `σ` is the standard deviation per
sample, at any period. `psd` is the two-sided intensity `Q` of the white noise
the samples stand for, with `σ² = Q/Δt` at the component's own period `Δt`
(§10.5), and a one-sided density is halved before being passed. `μ` left at
`nothing` is zero in the scale's shape. `μ` and the scale are broadcast to one
`V`, `Float64` or an `SVector` of `Float64`, so a scalar pairs with a vector,
and over a vector the components are independent.
"""
struct GaussianWhiteNoise{V <: Union{Float64, SVector{<:Any, Float64}}} <: AbstractComponent
    seed::UInt64
    μ::V
    σ::V              # per sample, or `sqrt(psd)` with `density` set
    density::Bool     # whether `σ` scales by `1/sqrt(Δt)`
end
function GaussianWhiteNoise(; seed, μ = nothing, σ = nothing, psd = nothing)
    (σ === nothing) == (psd === nothing) &&
        throw(ArgumentError("GaussianWhiteNoise takes exactly one of `σ` and `psd`."))
    scale = psd === nothing ? σ : sqrt.(psd)
    μ = something(μ, zero(scale))
    GaussianWhiteNoise(UInt64(seed), Float64.(μ .+ zero(scale)), Float64.(scale .+ zero(μ)), psd !== nothing)
end

# SplitMix64's output on the state after `k + 1` advances from `seed`: the
# stream's `k`-th word, reached without the `k` words before it.
function splitmix(seed, k)
    z = UInt64(seed) + (UInt64(k) + 1) * 0x9e3779b97f4a7c15
    z = (z ⊻ (z >> 30)) * 0xbf58476d1ce4e5b9
    z = (z ⊻ (z >> 27)) * 0x94d049bb133111eb
    z ⊻ (z >> 31)
end
# The `k`-th standard normal sample, by Box–Muller over the words `2k` and
# `2k + 1`. `u1` lies in `(0, 1]`, so the logarithm never sees zero.
function gaussian(seed, k)
    u1 = 1 - (splitmix(seed, 2k) >> 11) * 0x1p-53
    u2 = (splitmix(seed, 2k + 1) >> 11) * 0x1p-53
    sqrt(-2 * log(u1)) * cospi(2 * u2)
end
gaussian(seed, k, ::Type{Float64}) = gaussian(seed, k)
# Over a vector, component `i` reads the sub-counter `k N + i - 1`.
gaussian(seed, k, ::Type{SVector{N, Float64}}) where {N} =
    SVector(ntuple(i -> gaussian(seed, k * N + i - 1), Val(N)))

s_init(::GaussianWhiteNoise) = (k = UInt64(0),)
y_types(::GaussianWhiteNoise{V}) where {V} = (out = V,)
function y_state(c::GaussianWhiteNoise{V}, (; s, Δt)) where {V}
    scale = c.density ? c.σ ./ sqrt(Δt) : c.σ
    (out = c.μ .+ scale .* gaussian(c.seed, s.k, V),)
end
s_update(::GaussianWhiteNoise, (; s)) = (k = s.k + 1,)

# --- the continuous dynamics (§13.7, D-313) -------------------------------------

"""
    Integrator(; x0 = 0.0)

The integrator: one continuous state `q`, starting at `x0`, with `q̇ = in`, and
`out` publishing `q` from stage 1, so the block has no feedthrough (§5.3). `V`
is `Float64` or a static array of `Float64`, taken from `float(x0)`, so an
integer `x0` qualifies. A `Float64` state walks under a `Dual` activation
(§7.2), so the block linearizes as it integrates.
"""
struct Integrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
end
Integrator(; x0 = 0.0) = Integrator(float(x0))
x_init(c::Integrator) = (q = c.x0,)
u_types(::Integrator{V}) where {V} = (in = V,)
y_types(::Integrator{V}) where {V} = (out = V,)
y_state(::Integrator, (; x)) = (out = x.q,)
x_deriv(::Integrator, (; u)) = (q = u.in,)

"""
    FirstOrderLag(; τ, x0 = 0.0)

The first-order lag: `q̇ = (in - q) / τ` from `q = x0`, and `out` publishing `q`
from stage 1. The time constant `τ` is positive, and it is instance data pinned
at `Float64`. The state walks under a `Dual` activation (§7.2), so the lag
linearizes to `A = -1/τ` and `B = 1/τ`; a hand-written lag whose scratch is
pinned at `Float64` fails there instead (D-313). `V` is `Float64` or a static
array of `Float64`, taken from `float(x0)`, so an integer `x0` qualifies.
"""
struct FirstOrderLag{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    x0::V
    τ::Float64
end
function FirstOrderLag(; τ, x0 = 0.0)
    x0 = float(x0)
    FirstOrderLag{typeof(x0)}(x0, τ)
end
x_init(c::FirstOrderLag) = (q = c.x0,)
u_types(::FirstOrderLag{V}) where {V} = (in = V,)
y_types(::FirstOrderLag{V}) where {V} = (out = V,)
y_state(::FirstOrderLag, (; x)) = (out = x.q,)
x_deriv(c::FirstOrderLag, (; x, u)) = (q = (u.in - x.q) / c.τ,)

# --- the linear blocks (§13.7, §5.3, D-313) -------------------------------------

"""
    LinearBlock{FT}

The supertype of the linear blocks. `FT` is the feedthrough class: `false` when
the direct term is zero and `out` comes from stage 1, `true` when it is not and
`out` comes from stage 2 (§5.3). Every stage is defined here, once, over the
block's `realization`, so no linear block declares a stage of its own.
"""
abstract type LinearBlock{FT} <: AbstractComponent end

# The port edges. A port one wide is a `Float64` and a wider one an `SVector`,
# while the bodies always take matrix products over vectors.
port_type(width) = width == 1 ? Float64 : SVector{width, Float64}
as_vector(v::Real) = SVector(v)
as_vector(v::SVector) = v
as_port(v::SVector{1}) = v[1]
as_port(v::SVector) = v

x_init(c::LinearBlock) = (q = realization(c).x0,)
u_types(c::LinearBlock) = (in = port_type(size(realization(c).B, 2)),)
y_types(c::LinearBlock) = (out = port_type(size(realization(c).C, 1)),)
function x_deriv(c::LinearBlock, (; x, u))
    (; A, B) = realization(c)
    (q = A * x.q + B * as_vector(u.in),)
end
y_state(c::LinearBlock{false}, (; x)) = (out = as_port(realization(c).C * x.q),)
function y_direct(c::LinearBlock{true}, (; x, u))
    (; C, D) = realization(c)
    (out = as_port(C * x.q + D * as_vector(u.in)),)
end

"""
    StateSpace(; A, B, C, D = zeros(n_y, n_u), x0 = zeros(n_x))

The linear system in state-space form, one continuous state `q` from `x0`:

    q̇   = A q + B in
    out = C q + D in

`A` is `n_x × n_x`, `B` is `n_x × n_u`, `C` is `n_y × n_x` and `D` is
`n_y × n_u`. Each is any `AbstractMatrix` of reals, stored at full shape as a
static matrix of `Float64`, so integer entries qualify; a matrix that does not
fit the others is refused, and so is an `A` of size zero, since a block with no
state is a gain. `x0` is in the coordinates of `A`, a vector of length
`n_x`, or a real when `n_x` is one. The state is an `SVector` at every size. `in`
is a `Float64` when `n_u` is one and an `SVector{n_u, Float64}` otherwise, and
`out` likewise by `n_y`.

The type parameter `FT` is the feedthrough class, and `D` picks it. A zero `D`
publishes `out` from stage 1, so the block breaks an algebraic loop as the lag
does. A nonzero `D` publishes it from stage 2, so a loop closed on the block
through a memoryless path is refused (§5.3, §5.5). The matrices are pinned at
`Float64`, and the state and the ports walk under a `Dual` activation (§7.2), so
the block linearizes to its own matrices.

`linear_blocks.md` gives the reasoning: the storage, the realization a transfer
function goes through, and why the name is the one ControlSystemsBase exports.
"""
struct StateSpace{NX, NU, NY, FT, LA, LB, LC, LD} <: LinearBlock{FT}
    A::SMatrix{NX, NX, Float64, LA}
    B::SMatrix{NX, NU, Float64, LB}
    C::SMatrix{NY, NX, Float64, LC}
    D::SMatrix{NY, NU, Float64, LD}
    x0::SVector{NX, Float64}
end
StateSpace(A::SMatrix{NX, NX, Float64}, B::SMatrix{NX, NU, Float64}, C::SMatrix{NY, NX, Float64},
           D::SMatrix{NY, NU, Float64}, x0::SVector{NX, Float64}) where {NX, NU, NY} =
    StateSpace{NX, NU, NY, !iszero(D), NX * NX, NX * NU, NY * NX, NY * NU}(A, B, C, D, x0)
StateSpace(; A::AbstractMatrix, B::AbstractMatrix, C::AbstractMatrix,
           D::AbstractMatrix = zeros(size(C, 1), size(B, 2)), x0 = zeros(size(A, 1))) =
    StateSpace(static_system(A, B, C, D, x0)...)

# The keyword constructors' matrices and `x0`, checked against each other and
# made static. `DiscreteStateSpace` shares it.
function static_system(A, B, C, D, x0)
    size(A, 1) == 0 && throw(ArgumentError(
        "a state space with no state is a gain, which is written in a stage body, not a block"))
    n_x, n_u, n_y = size(A, 1), size(B, 2), size(C, 1)
    for (name, matrix, shape) in (("A", A, (n_x, n_x)), ("B", B, (n_x, n_u)),
                                  ("C", C, (n_y, n_x)), ("D", D, (n_y, n_u)))
        size(matrix) == shape ||
            throw(ArgumentError("`$name` is $(join(size(matrix), '×')) where $(join(shape, '×')) is needed"))
    end
    x0 isa Real && n_x == 1 || x0 isa AbstractVector && length(x0) == n_x ||
        throw(ArgumentError("`x0` has length $(length(x0)) where `A` asks for $n_x"))
    (SMatrix{n_x, n_x, Float64}(A), SMatrix{n_x, n_u, Float64}(B), SMatrix{n_y, n_x, Float64}(C),
     SMatrix{n_y, n_u, Float64}(D), SVector{n_x, Float64}(x0...))
end
realization(c::StateSpace) = c

"""
    realize(num, den)

The controllable canonical form of the transfer function `num / den`, its
coefficients highest power first and `num` no longer than `den`: the static
matrices `(; A, B, C, D)` of `Float64`, the denominator made monic and the
direct term split off. `linear_blocks.md`, section 2, derives it.
"""
function realize(num, den)
    order = length(den) - 1
    padded = [zeros(order + 1 - length(num)); collect(num)] ./ den[1]
    monic = collect(den) ./ den[1]
    direct = padded[1]
    num_tail = padded[2:end] .- direct .* monic[2:end]    # b̃_{n-1} … b̃_0, the direct term subtracted
    den_tail = monic[2:end]                                # a_{n-1} … a_0
    A = SMatrix{order, order, Float64}([zeros(order - 1) I(order - 1); -reverse(den_tail)'])
    B = SMatrix{order, 1, Float64}([zeros(order - 1); 1])
    C = SMatrix{1, order, Float64}(reverse(num_tail)')
    D = SMatrix{1, 1, Float64}(direct)
    (; A, B, C, D)
end

"""
    TransferFunction(; num, den, u0 = 0.0)

The linear system of one input and one output given by its transfer function,

    G(s) = (num[1] sᵐ + … + num[end]) / (den[1] sⁿ + … + den[end])

the coefficients highest power first, as tuples or vectors of reals. `in` and
`out` are `Float64`. The block keeps the coefficients and holds their
realization in controllable canonical form, a `StateSpace` whose stages it
shares.

There is no `x0`, because a realization's state means nothing to a user who
knows only `G(s)`. The block starts at rest, or, with `u0` given, at the steady
state for the constant input `u0`, where `out` is `G(0) u0`.

The type parameter `FT` is the feedthrough class, and the degrees pick it. A
numerator of lower degree than the denominator publishes `out` from stage 1, so
the block breaks an algebraic loop, and one of equal degree publishes it from
stage 2 (§5.3).

Four spellings are refused with an `ArgumentError`: a denominator of fewer
than two coefficients, whose order of zero makes a gain; a numerator longer
than the denominator, which is improper; a leading denominator coefficient of
zero; and a nonzero `u0` over a denominator whose constant coefficient is zero,
a pole at the origin, which has no steady state.

`linear_blocks.md` gives the realization in section 2 and the initial condition
in section 5.
"""
struct TransferFunction{N, FT, M, K, LA} <: LinearBlock{FT}
    num::NTuple{M, Float64}
    den::NTuple{K, Float64}
    realization::StateSpace{N, 1, 1, FT, LA, N, N, 1}
end
TransferFunction(num::NTuple{M, Float64}, den::NTuple{K, Float64},
                 realization::StateSpace{N, 1, 1, FT, LA}) where {M, K, N, FT, LA} =
    TransferFunction{N, FT, M, K, LA}(num, den, realization)
function TransferFunction(; num, den, u0 = 0.0)
    length(den) < 2 && throw(ArgumentError(
        "a transfer function of order zero is a gain, which is written in a stage body, not a block"))
    length(num) <= length(den) || throw(ArgumentError(
        "`num` has $(length(num)) coefficients where `den` has $(length(den)), an improper transfer function"))
    iszero(first(den)) && throw(ArgumentError("the leading coefficient of `den` is zero"))
    iszero(u0) || !iszero(last(den)) ||
        throw(ArgumentError("`u0` is $u0 where `den` has a pole at the origin, which has no steady state"))
    (; A, B, C, D) = realize(num, den)
    forced = B * SVector(float(u0))
    x0 = iszero(u0) ? zero(forced) : -(A \ forced)
    TransferFunction(Float64.(Tuple(num)), Float64.(Tuple(den)), StateSpace(A, B, C, D, x0))
end
realization(c::TransferFunction) = c.realization

# --- the discrete linear blocks (§13.7, §5.3, D-313) ----------------------------

"""
    DiscreteLinearBlock{FT}

The supertype of the discrete linear blocks, the linear blocks' twin on the
discrete tier. `FT` is the feedthrough class, as on `LinearBlock`: `false` when
the direct term is zero and `out` comes from stage 1, `true` when it is not and
`out` comes from stage 2 (§5.3). Two accessors serve every stage, defined here
once: `held(c)` returns the stored system, whose shapes, `C`, `D` and `x0` do
not depend on the period, and `realization(c, Δt)` returns the update matrices
at the period `Δt`. Only the update discretizes, so the declarations and the
output read `held` alone.
"""
abstract type DiscreteLinearBlock{FT} <: AbstractComponent end

s_init(c::DiscreteLinearBlock)  = (q = held(c).x0,)
u_types(c::DiscreteLinearBlock) = (in = port_type(size(held(c).B, 2)),)
y_types(c::DiscreteLinearBlock) = (out = port_type(size(held(c).C, 1)),)
function s_update(c::DiscreteLinearBlock, (; s, u, Δt))
    (; A, B) = realization(c, Δt)
    (q = A * s.q + B * as_vector(u.in),)
end
y_state(c::DiscreteLinearBlock{false}, (; s)) = (out = as_port(held(c).C * s.q),)
function y_direct(c::DiscreteLinearBlock{true}, (; s, u))
    (; C, D) = held(c)
    (out = as_port(C * s.q + D * as_vector(u.in)),)
end

"""
    DiscreteStateSpace(; A, B, C, D = zeros(n_y, n_u), x0 = zeros(n_x))

The linear system in discrete state-space form, one store field `q` from `x0`,
advanced once per tick:

    q⁺  = A q + B in
    out = C q + D in

The shapes, the storage, the ports and the refusals are `StateSpace`'s, and so
is the class: a zero `D` publishes `out` from stage 1, so the block breaks an
algebraic loop, and a nonzero `D` publishes it from stage 2 (§5.3, §5.5). The
tier pins wholesale (D-263): under a `Dual` activation the block holds its last
value (§9.4).

The matrices presuppose the period they were designed at. That period is the
scope's, bound at deployment after the block is built (§10.5), so the block
cannot check it. A system that should follow its period is a
`DiscretizedStateSpace`. `linear_blocks.md`, section 9, gives the reasoning.
"""
struct DiscreteStateSpace{NX, NU, NY, FT, LA, LB, LC, LD} <: DiscreteLinearBlock{FT}
    A::SMatrix{NX, NX, Float64, LA}
    B::SMatrix{NX, NU, Float64, LB}
    C::SMatrix{NY, NX, Float64, LC}
    D::SMatrix{NY, NU, Float64, LD}
    x0::SVector{NX, Float64}
end
DiscreteStateSpace(A::SMatrix{NX, NX, Float64}, B::SMatrix{NX, NU, Float64}, C::SMatrix{NY, NX, Float64},
                   D::SMatrix{NY, NU, Float64}, x0::SVector{NX, Float64}) where {NX, NU, NY} =
    DiscreteStateSpace{NX, NU, NY, !iszero(D), NX * NX, NX * NU, NY * NX, NY * NU}(A, B, C, D, x0)
DiscreteStateSpace(; A::AbstractMatrix, B::AbstractMatrix, C::AbstractMatrix,
                   D::AbstractMatrix = zeros(size(C, 1), size(B, 2)), x0 = zeros(size(A, 1))) =
    DiscreteStateSpace(static_system(A, B, C, D, x0)...)
held(c::DiscreteStateSpace) = c
realization(c::DiscreteStateSpace, _) = c

"""
    DiscreteTransferFunction(; num, den, u0 = 0.0)

The linear system of one input and one output given by its transfer function in
`z`,

    G(z) = (num[1] zᵐ + … + num[end]) / (den[1] zⁿ + … + den[end])

the coefficients highest power of `z` first, as `TransferFunction` takes them in
`s`. This is not the `z⁻¹` convention of `filter(b, a)`, which agrees with it
only when the degrees are equal. The block keeps the coefficients and holds
their realization in controllable canonical form, a `DiscreteStateSpace` whose
stages it shares, and the degrees pick the class as for `TransferFunction`.

The block starts at rest, or, with `u0` given, at the steady state for the
constant input `u0`, where `(I - A) q = B u0` and `out` is `G(1) u0`. The
refusals are `TransferFunction`'s, save that the pole with no steady state is at
`z = 1`: a nonzero `u0` is refused over a denominator whose coefficients sum to
zero within `1e-12` of the sum of their magnitudes, since a designed denominator
such as `(1, -0.7, -0.3)` misses an exact zero by rounding.

The coefficients presuppose the period they were designed at, which the block
cannot check, as for `DiscreteStateSpace`.
"""
struct DiscreteTransferFunction{N, FT, M, K, LA} <: DiscreteLinearBlock{FT}
    num::NTuple{M, Float64}
    den::NTuple{K, Float64}
    realization::DiscreteStateSpace{N, 1, 1, FT, LA, N, N, 1}
end
function DiscreteTransferFunction(; num, den, u0 = 0.0)
    length(den) < 2 && throw(ArgumentError(
        "a transfer function of order zero is a gain, which is written in a stage body, not a block"))
    length(num) <= length(den) || throw(ArgumentError(
        "`num` has $(length(num)) coefficients where `den` has $(length(den)), an improper transfer function"))
    iszero(first(den)) && throw(ArgumentError("the leading coefficient of `den` is zero"))
    monic = collect(den) ./ first(den)
    iszero(u0) || abs(sum(monic)) > 1e-12 * sum(abs, monic) ||
        throw(ArgumentError("`u0` is $u0 where `den` has a pole at `z = 1`, which has no steady state"))
    (; A, B, C, D) = realize(num, den)
    forced = B * SVector(float(u0))
    x0 = iszero(u0) ? zero(forced) : (I - A) \ forced
    DiscreteTransferFunction(Float64.(Tuple(num)), Float64.(Tuple(den)), DiscreteStateSpace(A, B, C, D, x0))
end
held(c::DiscreteTransferFunction) = c.realization
realization(c::DiscreteTransferFunction, _) = c.realization

"""
    DiscretizedStateSpace(sys::StateSpace)
    DiscretizedStateSpace(; A, B, C, D = zeros(n_y, n_u), x0 = zeros(n_x))

The continuous `StateSpace` `sys`, or the one the keywords build, run on the
discrete tier through a zero-order hold taken at each tick:

    A_d = e^{A Δt}        B_d = (∫₀^Δt e^{Aτ} dτ) B

with `C` and `D` unchanged. `A_d` and `B_d` are the top row of one exponential
of the augmented matrix `[A B; 0 0] Δt`. The hold is exact for an input held
constant over each period, so the samples are the continuous system's own.

`Δt` is the component's own period (§10.5), so the block follows its scope's
rate and carries no period of its own, where a `DiscreteStateSpace` presupposes
one. The class, the ports and `x0` are the continuous block's, `x0` in its
coordinates. The tier pins wholesale (D-263): under a `Dual` activation the
block holds its last value (§9.4). `linear_blocks.md`, section 9.2, gives the
reasoning.
"""
struct DiscretizedStateSpace{NX, NU, NY, FT, LA, LB, LC, LD} <: DiscreteLinearBlock{FT}
    continuous::StateSpace{NX, NU, NY, FT, LA, LB, LC, LD}
end
DiscretizedStateSpace(; kwargs...) = DiscretizedStateSpace(StateSpace(; kwargs...))
held(c::DiscretizedStateSpace) = c.continuous
# Assembled by `vcat` and `hcat`: the bracket spelling goes through a static
# `hvcat` that allocates on every call.
function realization(c::DiscretizedStateSpace{NX, NU}, Δt) where {NX, NU}
    (; A, B, C, D) = c.continuous
    augmented = vcat(hcat(A, B), hcat(zeros(SMatrix{NU, NX, Float64}), zeros(SMatrix{NU, NU, Float64})))
    exponential = exp(augmented * Δt)
    (; A = exponential[SOneTo(NX), SOneTo(NX)], B = exponential[SOneTo(NX), SUnitRange(NX + 1, NX + NU)], C, D)
end

"""
    DiscretizedTransferFunction(; num, den, u0 = 0.0)

The transfer function in `s` of `TransferFunction`, with its keywords, its
refusals and its start at rest or at `G(0) u0`, run on the discrete tier
through the zero-order hold of `DiscretizedStateSpace`, taken at each tick's
`Δt` (§10.5). The block keeps the coefficients and holds the realization
wrapped for the hold, and the degrees pick the class as for `TransferFunction`.

The hold keeps the class and matches the step response at the samples, where
Tustin's method would make every block feedthrough. A design that wants Tustin's
frequency response discretizes externally and uses `DiscreteTransferFunction`.
`linear_blocks.md`, section 9.2, gives the reasoning.
"""
struct DiscretizedTransferFunction{N, FT, M, K, LA} <: DiscreteLinearBlock{FT}
    num::NTuple{M, Float64}
    den::NTuple{K, Float64}
    realization::DiscretizedStateSpace{N, 1, 1, FT, LA, N, N, 1}
end
function DiscretizedTransferFunction(; num, den, u0 = 0.0)
    continuous = TransferFunction(; num, den, u0)
    DiscretizedTransferFunction(continuous.num, continuous.den, DiscretizedStateSpace(continuous.realization))
end
held(c::DiscretizedTransferFunction) = held(c.realization)
realization(c::DiscretizedTransferFunction, Δt) = realization(c.realization, Δt)

# --- the step (§2.1, §10.4, D-313) ----------------------------------------------

"""
    Step(; t_step, before = 0.0, after = 1.0, localized = true)

The step source: `out` publishes `before` until `t_step` and `after` from then
on. A mode-only leaf with no inputs: the mode `fired` picks the value, and one
state event, `fire`, sets it once `t` reaches `t_step`. `before` and `after`
are promoted to one `V`, `Float64` or a static array of `Float64`, and taken by
`float`, so integer values qualify; `t_step` is any time. `out` is pinned at
`V` (D-312): the value depends on neither state nor a walking input, so it
carries zero partials under every activation, as a `Constant`'s does.

`localized` picks the detection policy (§2.1). Localized, the guard is the sign
form `t - t_step`: the step ends at the crossing and the jump lands there.
Boundary-detected, the guard is the `Bool` `t ≥ t_step`: the event fires at the
end of the step in which it was first observed, so the jump lands on the first
boundary at or after `t_step`, never inside a step. The policy is the type
parameter `L` rather than a field because the build reads it off the guard's
return type (D-179).

Boundary zero sets every prior to not-holding (§10.6), so a `t_step` at or
before `t₀` fires there and `out` publishes `after` from the start.
"""
struct Step{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    before::V
    after::V
    t_step::Float64
end
function Step(; t_step, before = 0.0, after = 1.0, localized::Bool = true)
    before, after = float.(promote(before, after))
    Step{typeof(before), localized}(before, after, t_step)
end
x_init(::Step) = (;)
m_init(::Step) = (fired = false,)
y_types(::Step{V}) where {V} = (out = Pinned{V},)
y_state(c::Step, (; m)) = (out = m.fired ? c.after : c.before,)
step_guard(c::Step{V, true}, (; t)) where {V} = t - c.t_step     # sign form: localized
step_guard(c::Step{V, false}, (; t)) where {V} = t >= c.t_step   # Bool form: boundary-detected
step_handler(::Step, _) = (m = (fired = true,),)
state_events(::Step) = (fire = StateEvent(step_guard, step_handler),)

# --- the moded blocks (§10.4, §10.6, D-313) -------------------------------------

"""
    LimitedIntegrator(; lower, upper, x0 = zero(lower), localized = true)

The integrator held between `lower` and `upper`: one continuous state `q`, with
`q̇ = in` while free and `q̇ = 0` while saturated, and `out` publishing `q` from
stage 1. It is not a clamp. The mode `saturation` is read by the derivative,
and four state events move it. It is a signed `Int8` code, the sign of the
limit in force: `-1` at `lower`, `0` free and `+1` at `upper`.
`hit_upper` and `hit_lower` fire when `q` reaches a limit; their handlers write
`q` to the limit exactly and saturate. `leave_upper` and `leave_lower` fire
when `in` turns strictly back into the range, and free it; an input of exactly
zero at a limit keeps the mode saturated. The hit events are localized.

A second output, also `saturation`, publishes the code from stage 1, so it has
no feedthrough. It serves an anti-windup consumer, such as a controller that
gates its integrator on the code, which flips only when an event fires and so
only on a declared boundary.

`localized` picks the detection policy of the leave events (§2.1). Localized,
the guards are gated in §10.4's sign form, and the departure ends the step at
the input's zero crossing. Boundary-detected, the guards are the `Bool`
predicates, and the departure fires at the end of the step in which `in` first
pointed back into the range, so `q` is held on the limit for the rest of that
step and carries an offset of at most `a h² / 2` from then on, `a` the input's
slope at its zero crossing. What the cheap form buys is that a departure costs
no root-finding and splits no step, where a localized one pays about 22 trial
sweeps and a boundary. The policy is the type parameter `L` rather than a
field because the build reads it off the guard's return type (D-179).
`limited_integrator_variants.md` gives the reasoning.

Over a static vector, the limits and the codes are componentwise, and
`saturation` publishes a static vector of `Int8`. The block declares `N` copies
of the scalar events, one per component, named `hit_upper_1` to `hit_upper_N`,
then `hit_lower_i`, `leave_upper_i` and `leave_lower_i`: each guard reads its
one component and each handler writes it.

`lower < upper`, componentwise over a vector. `x0`, `lower` and `upper` are
promoted to one `V`, which is `Float64` or a static array of `Float64`, and
taken by `float`, so integer values qualify. Boundary zero sets every prior to
not-holding (§10.6), so an `x0` outside the limits is clamped there, and the
initial mode agrees with the initial input.
"""
struct LimitedIntegrator{V <: Union{Real, StaticArray{<:Tuple, <:Real}}, L} <: AbstractComponent
    x0::V
    lower::V
    upper::V
end
function LimitedIntegrator(; lower, upper, x0 = zero(lower), localized::Bool = true)
    x0, lower, upper = float.(promote(x0, lower, upper))
    LimitedIntegrator{typeof(x0), localized}(x0, lower, upper)
end
x_init(c::LimitedIntegrator) = (q = c.x0,)
m_init(c::LimitedIntegrator) = (saturation = Int8.(zero(c.x0)),)    # -1 lower, 0 free, +1 upper
u_types(::LimitedIntegrator{V}) where {V} = (in = V,)
y_types(::LimitedIntegrator{V}) where {V <: Real} = (out = V, saturation = Int8)
y_types(::LimitedIntegrator{V}) where {V <: StaticArray} = (out = V, saturation = similar_type(V, Int8))
y_state(::LimitedIntegrator, (; x, m)) = (out = x.q, saturation = m.saturation)
x_deriv(::LimitedIntegrator, (; u, m)) = (q = ifelse.(m.saturation .== 0, u.in, zero(u.in)),)
# The hit guards are not gated by the free code on purpose. Gated, a hit guard
# would read `0` the instant a leave handler frees the mode, present a fresh
# edge and saturate the block again.
hit_upper_guard(c::LimitedIntegrator, (; x)) = x.q - c.upper
hit_lower_guard(c::LimitedIntegrator, (; x)) = c.lower - x.q
# The leave guards gate on strictly inward input. Gated on the mode alone, an
# input of exactly zero reads `-0.0`, which holds, and frees the mode with `q`
# on the limit. The gate `u.in < 0` reads a wired signal, so §10.4's argument
# that gates stay fixed through a localization does not cover it: σ jumps from
# `-1` to a small positive value at the input's zero crossing. The bracket still
# converges on that crossing, since only the sign drives it, but ITP falls back
# to bisection's count, about 15 extra interior sweeps per leave.
leave_upper_guard(::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation == 1 && u.in < 0 ? -u.in : -one(u.in)
leave_lower_guard(::LimitedIntegrator{V, true}, (; m, u)) where {V} =
    m.saturation == -1 && u.in > 0 ? u.in : -one(u.in)
# The `Bool` forms are the same predicates, boundary-detected and strict by
# construction.
leave_upper_guard(::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation == 1 && u.in < 0
leave_lower_guard(::LimitedIntegrator{V, false}, (; m, u)) where {V} =
    m.saturation == -1 && u.in > 0
hit_upper_handler(c::LimitedIntegrator, _) = (x = (q = c.upper,), m = (saturation = Int8(1),))
hit_lower_handler(c::LimitedIntegrator, _) = (x = (q = c.lower,), m = (saturation = Int8(-1),))
leave_handler(::LimitedIntegrator, _) = (m = (saturation = Int8(0),),)
state_events(::LimitedIntegrator{V}) where {V <: Real} =
    (hit_upper = StateEvent(hit_upper_guard, hit_upper_handler),
     hit_lower = StateEvent(hit_lower_guard, hit_lower_handler),
     leave_upper = StateEvent(leave_upper_guard, leave_handler),
     leave_lower = StateEvent(leave_lower_guard, leave_handler))
# The events are per component, not reductions over the vector, so the scalar
# reasoning holds component by component. A reduced hit guard holds for good
# once one component sits clamped on its limit, so a second arrival makes no
# edge, and gating it by the mode brings back the re-saturation above.
function state_events(::LimitedIntegrator{V, L}) where {V <: StaticArray, L}
    N = length(V)
    hit_upper = ntuple(N) do i
        StateEvent((c, (; x)) -> x.q[i] - c.upper[i],
                   (c, (; x, m)) -> (x = (q = Base.setindex(x.q, c.upper[i], i),),
                                     m = (saturation = Base.setindex(m.saturation, Int8(1), i),)))
    end
    hit_lower = ntuple(N) do i
        StateEvent((c, (; x)) -> c.lower[i] - x.q[i],
                   (c, (; x, m)) -> (x = (q = Base.setindex(x.q, c.lower[i], i),),
                                     m = (saturation = Base.setindex(m.saturation, Int8(-1), i),)))
    end
    leave_upper = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0 ? -u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == 1 && u.in[i] < 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = Base.setindex(m.saturation, Int8(0), i),),))
    end
    leave_lower = ntuple(N) do i
        guard = L ? ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0 ? u.in[i] : -one(u.in[i])) :
                    ((c, (; m, u)) -> m.saturation[i] == -1 && u.in[i] > 0)
        StateEvent(guard, (c, (; m)) -> (m = (saturation = Base.setindex(m.saturation, Int8(0), i),),))
    end
    names = (ntuple(i -> Symbol(:hit_upper_, i), N)..., ntuple(i -> Symbol(:hit_lower_, i), N)...,
             ntuple(i -> Symbol(:leave_upper_, i), N)..., ntuple(i -> Symbol(:leave_lower_, i), N)...)
    NamedTuple{names}((hit_upper..., hit_lower..., leave_upper..., leave_lower...))
end

"""
    Relay(; lower, upper, off = zero(lower), on = one.(lower))

The relay with hysteresis: `out` publishes `off` or `on` by the mode `state`,
from stage 1. The mode is an `Int8` code, `0` off and `1` on. Two state events
move it. `switch_on` fires when `in` rises to `upper` while off, and
`switch_off` when `in` falls to `lower` while on. Both guards are sign forms
gated by the mode in §10.4's form, so both are localized.

`out` reads no input, so the block has no feedthrough (§5.3), and a relay
closing a feedback loop makes no algebraic loop. It is the library's reference
mode-switching leaf. `lower < upper`. The four values are promoted to one `V`,
which is `Float64` or a static array of `Float64`, and taken by `float`, so
integer values qualify. `out` is pinned at `V` (D-312): it depends on the mode
and the instance alone, so it carries zero partials under every activation.

Over a static vector, the thresholds, the values and the codes are
componentwise. The block declares `N` copies of the two events, one per
component, named `switch_on_1` to `switch_on_N`, then `switch_off_i`: each
guard reads its one component and each handler writes it.

The relay starts off. Boundary zero sets every prior to not-holding (§10.6), so
an input already at or above `upper` at `t₀` turns it on there, and an input
between the thresholds leaves it off, which is the hysteresis itself.
"""
struct Relay{V <: Union{Real, StaticArray{<:Tuple, <:Real}}} <: AbstractComponent
    lower::V      # switch off when `in` falls to it
    upper::V      # switch on when `in` rises to it
    off::V        # `out` while off
    on::V         # `out` while on
end
Relay(; lower, upper, off = zero(lower), on = one.(lower)) =
    Relay(float.(promote(lower, upper, off, on))...)
x_init(::Relay) = (;)
m_init(c::Relay) = (state = Int8.(zero(c.lower)),)    # 0 off, 1 on
u_types(::Relay{V}) where {V} = (in = V,)
y_types(::Relay{V}) where {V} = (out = Pinned{V},)
y_state(c::Relay, (; m)) = (out = ifelse.(m.state .== 1, c.on, c.off),)
switch_on_guard(c::Relay, (; m, u)) = m.state == 0 ? u.in - c.upper : -one(u.in)
switch_off_guard(c::Relay, (; m, u)) = m.state == 1 ? c.lower - u.in : -one(u.in)
switch_on_handler(::Relay, _) = (m = (state = Int8(1),),)
switch_off_handler(::Relay, _) = (m = (state = Int8(0),),)
state_events(::Relay{V}) where {V <: Real} =
    (switch_on = StateEvent(switch_on_guard, switch_on_handler),
     switch_off = StateEvent(switch_off_guard, switch_off_handler))
function state_events(::Relay{V}) where {V <: StaticArray}
    N = length(V)
    switch_on = ntuple(N) do i
        StateEvent((c, (; m, u)) -> m.state[i] == 0 ? u.in[i] - c.upper[i] : -one(u.in[i]),
                   (c, (; m)) -> (m = (state = Base.setindex(m.state, Int8(1), i),),))
    end
    switch_off = ntuple(N) do i
        StateEvent((c, (; m, u)) -> m.state[i] == 1 ? c.lower[i] - u.in[i] : -one(u.in[i]),
                   (c, (; m)) -> (m = (state = Base.setindex(m.state, Int8(0), i),),))
    end
    names = (ntuple(i -> Symbol(:switch_on_, i), N)..., ntuple(i -> Symbol(:switch_off_, i), N)...)
    NamedTuple{names}((switch_on..., switch_off...))
end

# --- the controller (§13.7, §5.4, D-313) ----------------------------------------

"""
    PIDBlock{Hold, Track}

The supertype of the two PID blocks, `PID` on the continuous tier and
`DiscretePID` on the discrete one. It carries what their law shares, the ports
picked by `Hold` and `Track`, the error's gate and the correction's reference,
while each block carries its fields, its store and its stages.
"""
abstract type PIDBlock{Hold, Track} <: AbstractComponent end

# The methods both blocks share live here: the four `u_types` arms, `y_types`,
# the gate and the reference rule.
u_types(::PIDBlock{false, false}) = (r = Float64, y = Float64)
u_types(::PIDBlock{true, false})  = (r = Float64, y = Float64, saturation = Int8)
u_types(::PIDBlock{false, true})  = (r = Float64, y = Float64, v = Float64)
u_types(::PIDBlock{true, true})   = (r = Float64, y = Float64, saturation = Int8, v = Float64)
y_types(::PIDBlock) = (u = Float64, u_raw = Float64)
# The gate tests the sign, not `saturation != 0`: integration resumes once the
# error points back into the range, while the path still reports saturation.
# The `!= 0` in front leaves a free path's zero error ungated, so the derivative
# at an equilibrium does not depend on how `sign` orders a zero-valued `Dual`.
gated_error(::PIDBlock{false}, e, u) = e
gated_error(::PIDBlock{true}, e, u) = u.saturation != 0 && u.saturation == sign(e) ? zero(e) : e
# With a hold, `v` is the reference only while the code is nonzero. Tracking is
# what to converge to while the path cannot follow; on a free path it would only
# couple the integrator to the transients downstream.
correction_reference(::PIDBlock{Hold, false}, u, y) where {Hold} = y.u
correction_reference(::PIDBlock{false, true}, u, y) = u.v
correction_reference(::PIDBlock{true, true}, u, y) = u.saturation == 0 ? y.u : u.v

"""
    PID(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf, u_min = -Inf, u_max = Inf,
          hold = false, tracking = false)

The PID controller with anti-windup. Inputs `r` and `y`, the error `e = r - y`,
and two outputs from stage 2: `u_raw = Kp e + q - Kd (y - yf) / τd`, and `u`,
its clamp to `[u_min, u_max]`. Two continuous states: `q`, the integral term,
and `yf`, the measurement through a lag, `ẏf = (y - yf) / τd`. One law moves
the integral term,

    q̇ = Ki · gate(e) + (ref - u_raw) / Tt

and two independent type parameters pick its parts, each adding an input port:

|         | reference: own `u`              | reference: tracking `v`                                   |
|:------- |:------------------------------- |:--------------------------------------------------------- |
| no hold | `Ki e + (u - u_raw) / Tt`       | `Ki e + (v - u_raw) / Tt`                                 |
| hold    | `Ki gate(e) + (u - u_raw) / Tt` | `Ki gate(e) + ((saturation == 0 ? u : v) - u_raw) / Tt` |

`hold = true`, the parameter `Hold`, adds the input `saturation`, an `Int8`
code such as a `LimitedIntegrator` publishes for the path downstream, and gates
the error: `gate(e) = saturation == sign(e) ? 0 : e`. `tracking = true`, the
parameter `Track`, adds the input `v`, the value the path delivered, as the
correction's reference in place of the own `u`. When both exist, `v` is the
reference only while the code is nonzero, and `u` while the path is free.

`q` holds the integral term in output units, with `Ki` inside the integral, so
a change in `Ki` alters only future accumulation. The derivative acts on the
measurement, not the error, so a step in `r` makes no kick; `τd` is positive.
The defaults make the plain spelling a P controller: `Ki = Kd = 0`, `Tt = Inf`,
which switches the correction off, and infinite limits.

A tracking input wired from a memoryless clamp of the block's own `u` is
refused as an `AlgebraicCycle` classified artificial (§5.4): `u` is a stage-2
output, so every input makes a feedthrough edge, whether `y_direct` reads it or
not. That is why the limits live inside the block. `v` serves a value published
from state, such as a stateful actuator's position. `pid_anti_windup.md` gives
the reasoning.
"""
struct PID{Hold, Track} <: PIDBlock{Hold, Track}
    Kp::Float64
    Ki::Float64
    Kd::Float64
    τd::Float64       # the derivative filter's time constant, positive
    Tt::Float64       # the tracking time; `Inf` switches the correction off
    u_min::Float64    # the own limits; infinite by default
    u_max::Float64
end
PID(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf, u_min = -Inf, u_max = Inf,
      hold::Bool = false, tracking::Bool = false) =
    PID{hold, tracking}(Kp, Ki, Kd, τd, Tt, u_min, u_max)

x_init(::PID) = (q = 0.0, yf = 0.0)
function y_direct(c::PID, (; x, u))
    u_raw = c.Kp * (u.r - u.y) + x.q - c.Kd * (u.y - x.yf) / c.τd
    (u = clamp(u_raw, c.u_min, c.u_max), u_raw = u_raw)
end
x_deriv(c::PID, (; x, u, y)) =
    (q  = c.Ki * gated_error(c, u.r - u.y, u) + (correction_reference(c, u, y) - y.u_raw) / c.Tt,
     yf = (u.y - x.yf) / c.τd)

"""
    DiscretePID(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf, u_min = -Inf, u_max = Inf,
                  hold = false, tracking = false)

The PID controller with anti-windup on the discrete tier: `PID`'s fields,
defaults, ports and law, with two store fields in place of its continuous
states, `q`, the integral term, and `yf`, the measurement through a lag. `Δt` is
the component's own period (§10.5). Inputs `r` and `y`, the error `e = r - y`,
and two outputs from stage 2: `u_raw = Kp e + q - Kd (y - yf) / (τd + Δt)`, and
`u`, its clamp to `[u_min, u_max]`. Each tick moves the lag by backward Euler,
`yf⁺ = yf + Δt (y - yf) / (τd + Δt)`, and the integral term by forward Euler
and the correction's exact step,

    q⁺ = q + Δt Ki · gate(e) + β (ref - u_raw),    β = 1 - exp(-Δt / Tt)

which reads, over `PID`'s two type parameters:

|         | reference: own `u`              | reference: tracking `v`                                   |
|:------- |:------------------------------- |:--------------------------------------------------------- |
| no hold | `Δt Ki e + β (u - u_raw)`       | `Δt Ki e + β (v - u_raw)`                                 |
| hold    | `Δt Ki gate(e) + β (u - u_raw)` | `Δt Ki gate(e) + β ((saturation == 0 ? u : v) - u_raw)` |

`hold` adds the input `saturation` and the gate, `tracking` the input `v`, and
with both the reference falls back to `u` while the code is zero, as in `PID`.

The backward Euler lag is stable at every period, and `τd = 0` is legal: `yf`
is then the previous measurement, and the D term the backward difference
`(y - yf) / Δt`. `β` is the exact step of the correction's relaxation over one
period, so every `Tt` is stable: `Tt = Inf` switches the correction off, and
`Tt = 0` is legal and brings `u_raw` to the reference by the next tick, the
clamping scheme as the limit of tracking.

A tracking input wired from a memoryless clamp of the block's own `u` is
refused as an `AlgebraicCycle`, as for `PID`, but classified real: a discrete
member traces structurally (§5.6), so no hop is named dead. `pid_anti_windup.md`,
section 9, gives the reasoning.
"""
struct DiscretePID{Hold, Track} <: PIDBlock{Hold, Track}
    Kp::Float64
    Ki::Float64
    Kd::Float64
    τd::Float64       # the derivative filter's time constant, nonnegative
    Tt::Float64       # the tracking time; `Inf` switches the correction off
    u_min::Float64    # the own limits; infinite by default
    u_max::Float64
end
DiscretePID(; Kp, Ki = 0.0, Kd = 0.0, τd = 0.1, Tt = Inf, u_min = -Inf, u_max = Inf,
              hold::Bool = false, tracking::Bool = false) =
    DiscretePID{hold, tracking}(Kp, Ki, Kd, τd, Tt, u_min, u_max)

s_init(::DiscretePID) = (q = 0.0, yf = 0.0)
function y_direct(c::DiscretePID, (; s, u, Δt))
    deriv = (u.y - s.yf) / (c.τd + Δt)
    u_raw = c.Kp * (u.r - u.y) + s.q - c.Kd * deriv
    (u = clamp(u_raw, c.u_min, c.u_max), u_raw = u_raw)
end
function s_update(c::DiscretePID, (; s, u, y, Δt))
    β = -expm1(-Δt / c.Tt)
    (q  = s.q + Δt * c.Ki * gated_error(c, u.r - u.y, u) + β * (correction_reference(c, u, y) - y.u_raw),
     yf = s.yf + Δt * (u.y - s.yf) / (c.τd + Δt))
end

# --- the anonymous assembly (§8.5, D-211) -------------------------------------

"""
`Group`: the library's on-the-fly assembly, whose *values* are the ad-hoc
topologies. It needs no new rule — the container-children rule makes the
`children` field's elements children of the `Group` itself, and the four
declarations are ordinary functions of the instance, free to read its fields.

The one declaration it adds is `transparent_container` (D-211): `children` is
name-transparent, so its elements go by **bare key** everywhere a child name
appears — `"ctl/out" => "plant/u"` for a wire, `(ctl = Relative(2),)` for a rate,
`at("ctl", …)` for a condition prefix, `"plant/y"` for a read path. A `Group`'s
declarations are then textually identical to a named assembly's; the rate
declaration's field-name sugar, keying on the field rather than on a path
segment, keeps working as `(children = Relative(2),)` for the uniform case.

The type parameters carry the children's concrete types, so the executor's
specialization is unchanged; what is given up against a named type is dispatch,
which exploratory composition does not want.
"""
struct Group{C <: NamedTuple, W, I, O, R <: NamedTuple} <: AbstractComponent
    children::C       # component-typed elements → children by the container rule
    local_wires::W    # inert parameter data
    input_wires::I
    output_wires::O
    sample_times::R   # the ad-hoc rate scope, keyed by bare element name (§8.7)
end

"""
    Group(children; local_wires = (), input_wires = (), output_wires = (),
          sample_times = (;))

The convenience form. Each keyword takes the name of the declaration it feeds.
A bare `Pair` passed for `local_wires`, `input_wires` or `output_wires` is the
one-entry tuple — the declarations are ordered collections of pairs, and a
single wire should not have to be written `("a/x" => "b/y",)`.
"""
Group(children; local_wires = (), input_wires = (), output_wires = (),
      sample_times = (;)) =
    Group(children, _entries(local_wires), _entries(input_wires),
          _entries(output_wires), sample_times)

_entries(wires::Pair) = (wires,)
_entries(wires) = wires

local_wires(g::Group) = g.local_wires
input_wires(g::Group) = g.input_wires
output_wires(g::Group) = g.output_wires
sample_times(g::Group) = g.sample_times
transparent_container(::Group) = :children

end # module Blocks
