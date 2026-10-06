module Blocks

import ..Redstone: AbstractComponent, Pinned,
    x_init, s_init, u_types, y_types, y_direct, y_state, s_update,
    inner_wires, input_wires, output_wires, sample_times, transparent_container
using StaticArrays: StaticArray
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

(::Type{SumJunction{V, N}})() where {V, N} = SumJunction{V, N}(+)
(::Type{Or{N}})() where {N} = Or{N}(|)
(::Type{And{N}})() where {N} = And{N}(&)

x_init(::Junction) = (;)
u_types(::Junction{In, Out, N}) where {In, Out, N} =
    NamedTuple{ntuple(i -> Symbol(:in, i), N)}(ntuple(_ -> In, N))
y_types(::Junction{In, Out}) where {In, Out} = (out = Out,)
y_direct(j::Junction, (; u)) = (out = j.f(u...),)

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

A discrete leaf, the tier's native `z⁻¹` (§10.6). `out` publishes the stored value from stage 1, `v0` at the first
publication, and each tick stores `in` for the next one. Its store is isbits
(D-231), which bounds `V`.

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

# --- the anonymous assembly (§8.5, D-211) -------------------------------------

"""
`Group`: the library's on-the-fly assembly, whose *values* are the ad-hoc
topologies. It needs no new rule — the
container-children rule makes the `children` field's elements children of the
`Group` itself, and the four declarations are ordinary functions of the
instance, free to read its fields.

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
    inner_wires::W    # inert parameter data
    input_wires::I
    output_wires::O
    sample_times::R   # the ad-hoc rate scope, keyed by bare element name (§8.7)
end

"""
    Group(children; inner_wires = (), input_wires = (), output_wires = (),
          sample_times = (;))

The convenience form. Each keyword takes the name of the declaration it feeds.
A bare `Pair` passed for `inner_wires`, `input_wires` or `output_wires` is the
one-entry tuple — the declarations are ordered collections of pairs, and a
single wire should not have to be written `("a/x" => "b/y",)`.
"""
Group(children; inner_wires = (), input_wires = (), output_wires = (),
      sample_times = (;)) =
    Group(children, _entries(inner_wires), _entries(input_wires),
          _entries(output_wires), sample_times)

_entries(wires::Pair) = (wires,)
_entries(wires) = wires

inner_wires(g::Group) = g.inner_wires
input_wires(g::Group) = g.input_wires
output_wires(g::Group) = g.output_wires
sample_times(g::Group) = g.sample_times
transparent_container(::Group) = :children

end # module Blocks
