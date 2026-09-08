# --- the leaf walk (§7.1, §7.2) -----------------------------------------------
# The closed value vocabulary — real scalars, static arrays, isbits structs of
# the same — walked to shape a flat buffer, to name a position in it, and to
# retype a declaration at the activation scalar. A leaf whose type is not
# `Float64` does not follow it, which is what the pins and the mixed cells in
# `test_store.jl` are laid out around.

# The fixtures cover the vocabulary one shape at a time. §7.1 admits real
# scalars and `SArray`s of a common eltype, so `Body` nests a struct, a static
# vector and a static matrix, and no static array of static arrays.
struct Pose
    x::Float64
    y::Float64
end

struct Body
    pose::Pose
    v::SVector{3,Float64}
    m::SMatrix{2,2,Float64,4}
end

# Two eltypes in one value: leaves that follow the activation scalar beside a
# pinned `Int`. `Counted` meets the same two the other way round, which is what
# holds `leaf_eltypes` to the walk's order rather than a canonical one.
struct Tagged{T}
    v::SVector{2,T}
    n::Int
end

struct Counted
    n::Int
    w::Float64
end

# The shape §13.4 names an offending leaf of: a state declaration.
const StateNT = @NamedTuple{q::Float64, v::SVector{3,Float64}}

# The abstract arm of the wire relation (§4.4, §8.2, D-236): one stable face
# with several concrete producer types below it.
abstract type Handle end

struct HandleA <: Handle
    a::Float64
end

# D-238's parameters: the facts that distinguish two concrete types carrying the
# same leaves. `Labeled`'s symbol tags the type without reaching a leaf, and
# `Placement` is the parametric shape the non-parametric `Pose` above is not.
struct Labeled{S}
    v::Float64
end

struct Placement{T}
    x::T
    y::T
end

# A struct nesting a handle (`HeightField`, `fixtures.jl`) beside a plain leaf.
# It is itself concrete, immutable and not isbits, so D-237 stops the walk at
# `Framed` rather than descending to find the handle inside it.
struct Framed
    f::HeightField
    s::Float64
end

# One round trip at a nonzero offset into an oversized buffer: the value comes
# back identical, and only the `nleaves` entries it owns were written. `E` is
# the buffer's eltype: a cell carrying an opaque leaf needs one that holds it.
function roundtrip(v, off; E = Float64)
    n = nleaves(typeof(v))
    buf = Vector{E}(fill(NaN, off + n + 3))
    flatten!(buf, off, v)
    @test reconstruct(typeof(v), buf, off) === v
    @test all(isnan, buf[1:off])
    @test all(isnan, buf[off+n+1:end])
end

# `_mreconstruct_expr` and `_mflatten_expr` build the bodies of `store.jl`'s
# generated gather and scatter: one buffer bound per leaf eltype, every index
# static against `offs`. Compiling one into a function of exactly the arguments
# the generator binds runs it with no store bundle in the way. Both take a
# `buf2` even at `K = 1`, where the built expression ignores it. Each returns
# the `bases` vector the builder mutated as it walked, and wraps the compiled
# method in `invokelatest`, which is what a method defined mid-call costs.
function mgather(P)
    bases = zeros(Int, length(leaf_eltypes(P)))
    e = _mreconstruct_expr(P, leaf_eltypes(P), bases)
    fn = Core.eval(@__MODULE__, Expr(:->, Expr(:tuple, :buf1, :buf2, :offs), e))
    (a...) -> Base.invokelatest(fn, a...), bases
end

function mscatter(P)
    bases = zeros(Int, length(leaf_eltypes(P)))
    e = _mflatten_expr(P, :v, leaf_eltypes(P), bases)
    fn = Core.eval(@__MODULE__, Expr(:->, Expr(:tuple, :buf1, :buf2, :offs, :v), e))
    (a...) -> Base.invokelatest(fn, a...), bases
end

function leaves_shape()
    @testset "the flat shape of a value type (§7.1)" begin
        @test nleaves(Float64) == 1
        @test nleaves(SVector{3,Float64}) == 3
        @test nleaves(SMatrix{2,2,Float64,4}) == 4
        @test nleaves(Pose) == 2
        @test nleaves(Body) == 9
        @test nleaves(StateNT) == 4

        # `leaf_types` is the shape counterpart of `nleaves`, so the two must
        # agree entry for entry.
        @test leaf_types(Body) == fill(Float64, 9)
        @test length(leaf_types(StateNT)) == nleaves(StateNT)
        @test leaf_types(Tagged{Float64}) == Type[Float64, Float64, Int]

        # First-appearance order over the walk, and nothing else: the same two
        # eltypes come back in whichever order the walk meets them. That order
        # is the contract layout and the store bundle share.
        @test leaf_eltypes(Tagged{Float64}) == Type[Float64, Int]
        @test leaf_eltypes(Counted) == Type[Int, Float64]
        @test leaf_eltypes(Body) == Type[Float64]

        # D-237's opaque leaf: a concrete immutable type that is not isbits is
        # one leaf of its own type, and the walk never looks inside it.
        @test nleaves(HeightField) == 1
        @test leaf_types(HeightField) == Type[HeightField]
        @test leaf_names(HeightField) == [""]
        # The rule reads off the outermost type: a struct carrying a handle is
        # itself non-isbits, so it is the opaque leaf and its `Float64` field is
        # not a leaf of its own.
        @test nleaves(Framed) == 1
        @test leaf_types(Framed) == Type[Framed]
        @test leaf_names(Framed) == [""]

        # The refusal's walker: the first mutable position the walk meets, the
        # port type itself spelled `""`. A handle is opaque, so its `Matrix`
        # field is not a position the walk visits.
        @test mutable_position(Matrix{Float64}) == ("", Matrix{Float64})
        @test mutable_position(SVector{2,Matrix{Float64}}) == ("[1]", Matrix{Float64})
        @test mutable_position(HeightField) === nothing
        @test mutable_position(Float64) === nothing
    end
end

function leaves_names()
    @testset "the dotted spelling of a flat position (§7.1, §13.4)" begin
        # One name per leaf in the flat order: a nested field dotted, a static
        # array's elements indexed, the matrix's linearly.
        @test leaf_names(Pose) == ["x", "y"]
        @test leaf_names(Body) == ["pose.x", "pose.y", "v[1]", "v[2]", "v[3]",
                                   "m[1]", "m[2]", "m[3]", "m[4]"]
        @test leaf_names(StateNT) == ["q", "v[1]", "v[2]", "v[3]"]
        @test length(leaf_names(Body)) == nleaves(Body)
    end
end

function leaves_roundtrip()
    @testset "the flat round trip (§7.1)" begin
        b = Body(Pose(1.0, 2.0), SVector(3.0, 4.0, 5.0),
                 SMatrix{2,2}(6.0, 7.0, 8.0, 9.0))

        # The flat order is the walk's: fields in declaration order, a static
        # array's elements linearly, so the matrix lies down column-major.
        buf = zeros(20)
        flatten!(buf, 5, b)
        @test buf[6:14] == 1.0:9.0

        # Bit-faithful both ways, at an offset, over each case of the vocabulary.
        roundtrip(1.5, 4)
        roundtrip(SVector(1.0, 2.0, 3.0), 0)
        roundtrip(Pose(1.0, 2.0), 2)
        roundtrip(b, 7)
        # A NamedTuple takes its fields as one tuple rather than positionally,
        # which is its own branch of the reconstruct builder.
        roundtrip((q = 1.0, v = SVector(2.0, 3.0, 4.0)), 3)

        # An opaque leaf makes the round trip whole: `===` on the reconstructed
        # `Framed` is `===` on the handle, which is `===` on the one `Matrix`
        # (D-237). A buffer that holds it is not a `Float64` one.
        fr = Framed(height_field(Terrain()), 5.0)
        roundtrip(fr, 2; E = Any)
        buf = Vector{Any}(undef, 4)
        flatten!(buf, 1, fr)
        @test reconstruct(Framed, buf, 1).f.z === fr.f.z
    end
end

function leaves_mixed()
    @testset "a value whose leaves span several eltypes (§7.2)" begin
        P = Tagged{Float64}
        v = P(SVector(1.5, 2.5), 7)

        # One running base per eltype, each left at that eltype's leaf count.
        scat, sbases = mscatter(P)
        @test sbases == [2, 1]
        @test sbases == [count(==(L), leaf_types(P)) for L in leaf_eltypes(P)]

        # Every leaf lands in its own eltype's buffer, at that buffer's own
        # offset. The `Int` is stored as an `Int`, never widened into the
        # `Float64` buffer.
        f1, f2 = zeros(6), zeros(Int, 4)
        scat(f1, f2, (3, 1), v)
        @test f1 == [0.0, 0.0, 0.0, 1.5, 2.5, 0.0]
        @test f2 == [0, 7, 0, 0]

        gath, gbases = mgather(P)
        @test gbases == sbases
        @test gath(f1, f2, (3, 1)) === v

        # The NamedTuple branch of the same builder.
        gnt, _ = mgather(@NamedTuple{a::Float64, n::Int})
        @test gnt([9.5], [4], (0, 0)) === (a = 9.5, n = 4)

        # `K = 1` is the homogeneous case, where the builders emit the
        # single-base expressions: what `flatten!` wrote reads back through them.
        b = Body(Pose(1.0, 2.0), SVector(3.0, 4.0, 5.0),
                 SMatrix{2,2}(6.0, 7.0, 8.0, 9.0))
        buf = zeros(12)
        flatten!(buf, 2, b)
        ghom, hbases = mgather(Body)
        @test hbases == [nleaves(Body)]
        @test ghom(buf, buf, (2,)) === b
    end
end

function leaves_retype()
    @testset "the activation walk (§7.2)" begin
        @test retype(D8, Float64) === D8
        @test retype(D8, SVector{3,Float64}) === SVector{3,D8}
        @test retype(D8, Int) === Int
        @test retype(Float64, SVector{2,Float64}) === SVector{2,Float64}
        @test retype_value(D8, (q = SVector(1.0, 2.0),)).q isa SVector{2,D8}

        # The wire relation's lifted candidate retypes a declaration already
        # evaluated at `T`, so the walk is idempotent and passes through anything
        # with no `Float64` position to replace — a `Union` and a `UnionAll`
        # included, which `.parameters` would have thrown on.
        @test retype(D8, retype(D8, SVector{3,Float64})) === retype(D8, SVector{3,Float64})
        @test retype(D8, Tagged{D8}) === Tagged{D8}
        @test retype(D8, AbstractVector) === AbstractVector
        @test retype(D8, Union{Float64,Int}) === Union{Float64,Int}
    end
end

function leaves_wire_relation()
    @testset "the wire relation with its abstract arm (§6.1, D-236)" begin
        # A concrete entry is embed-accept leaf by leaf: a pinned entry refuses a
        # walking producer and takes a frozen one, a `T` entry takes both.
        @test !_accepts_wire(SVector{3,Float64}, SVector{3,D8}, D8)
        @test _accepts_wire(SVector{3,Float64}, SVector{3,Float64}, D8)
        @test _accepts_wire(SVector{3,D8}, SVector{3,Float64}, D8)

        # exact on the type (D-238): the relation walks the two parameter lists,
        # so a field name, a non-numeric parameter and an array's mutability are
        # refused like any other mismatch, where the leafwise form passed them.
        @test !_accepts(@NamedTuple{a::Float64}, @NamedTuple{b::Float64}, D8)
        @test !_accepts(Labeled{:a}, Labeled{:b}, D8)
        @test !_accepts(SVector{3,Float64}, MVector{3,Float64}, D8)
        @test _accepts(@NamedTuple{a::D8, b::Int}, @NamedTuple{a::Float64, b::Int}, D8)
        @test !_accepts(@NamedTuple{a::D8, b::Int}, @NamedTuple{b::Int, a::Float64}, D8)
        @test _accepts(SVector{2,Placement{D8}}, SVector{2,Placement{Float64}}, D8)

        # An abstract entry has no leaves to walk, so it is decided on the whole
        # declaration: `V` as declared, or `V` with every pinned leaf lifted.
        @test _accepts_wire(AbstractVector{D8}, SVector{3,D8}, D8)
        @test _accepts_wire(AbstractVector{D8}, SVector{3,Float64}, D8)   # the lifted candidate
        @test !_accepts_wire(AbstractVector{Float64}, SVector{3,D8}, D8)
        @test _accepts_wire(Real, D8, D8)
        @test _accepts_wire(Real, Float64, D8)
        @test _accepts_wire(Handle, HandleA, D8)      # §4.4's substitutability
        @test !_accepts_wire(Handle, Float64, D8)

        # At nominal every lift is the identity and the relation is §6.1's bound
        # check: `<:`, degenerating to equality on a concrete entry.
        @test _accepts_wire(Float64, Float64, Float64)
        @test !_accepts_wire(Bool, Float64, Float64)
        @test _accepts_wire(Real, Float64, Float64)
        @test _accepts_wire(Handle, HandleA, Float64)

        # At the marker the same relation is the walk clause: a `Marker` leaf
        # walks, everything else is pinned, and a pinned leaf satisfies either
        # entry.
        @test !_accepts_wire(Float64, Marker, Marker)
        @test _accepts_wire(Marker, Float64, Marker)
        @test _accepts_wire(Marker, Marker, Marker)
        @test _accepts_wire(Int, Int, Marker)
        @test !_accepts_wire(AbstractVector{Float64}, SVector{3,Marker}, Marker)
        @test _accepts_wire(AbstractVector{Marker}, SVector{3,Float64}, Marker)

        # A declaration at the marker prints as its author wrote it, which is what
        # a `WalkingFaceAtFrozenEntry` message shows; the payload keeps the type.
        # (a parametric type's printed form carries its own module, so the
        # containment rather than equality — implementation.md's caveat.)
        @test string(Marker) == "T"
        @test occursin("SVector{3, T}", string(SVector{3,Marker}))
    end
end

function test_leaves()
    leaves_shape()
    leaves_names()
    leaves_roundtrip()
    leaves_mixed()
    leaves_retype()
    leaves_wire_relation()
end
