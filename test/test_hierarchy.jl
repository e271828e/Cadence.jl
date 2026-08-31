# A deliberately pinned leaf (D-166): `frozen` is declared `Float64` rather than
# `T`, so it must not follow the activation scalar.
struct PinnedLeaf <: AbstractComponent end
output_types(::PinnedLeaf, ::Type{T}) where {T <: Real} = (a = T, frozen = Float64)
h_x(::PinnedLeaf, (; t)) = (a = t, frozen = 2.0)

function hierarchy_pinned_leaf()
    @testset "a pinned leaf lives in its own store (D-166, D-162)" begin
        # Nominally the pin and the activation scalar coincide: one buffer.
        sim = Simulation(single(PinnedLeaf()); h = 1//100)
        @test keys(sim.exec.store.stores) === (_cell_key(Float64),)
        # Off nominal the pin keeps a `Float64` buffer of its own beside the `Dual`
        # one, rather than being flattened into it as a zero-partial.
        sim = Simulation(single(PinnedLeaf()), D8; h = 1//100)
        @test Set(keys(sim.exec.store.stores)) == Set([_cell_key(D8), _cell_key(Float64)])
        init!(sim)
        @test port(sim, "c", :a) isa D8
        @test port(sim, "c", :frozen) isa Float64
        @test port(sim, "c", :frozen) == 2.0  # a stored constant, not a computed product
    end
end

# Mixed-leaf cells (§7.2's per-leaf table): the ordinary route, an `Int` leaf
# beside `T` leaves, and the D-166 route, a pinned `Float64` inside a declared
# struct. The cell spans one buffer per leaf eltype; its address carries one
# cursor per eltype as an `NTuple` field (D-162's C2M point).
struct TaggedValue{T}
    v::T
    n::Int
end
struct MixedCell <: AbstractComponent end
output_types(::MixedCell, ::Type{T}) where {T <: Real} = (out = TaggedValue{T},)
h_x(::MixedCell, (; t)) = (out = TaggedValue(t, 1),)

struct PinnedPair{T}
    a::T
    ref::Float64
end
struct PinnedInside <: AbstractComponent end
output_types(::PinnedInside, ::Type{T}) where {T <: Real} = (out = PinnedPair{T},)
h_x(::PinnedInside, (; t)) = (out = PinnedPair(t, 2.0),)

function hierarchy_mixed_cell()
    @testset "a mixed-leaf cell lays out across its eltypes' buffers (§7.2, D-162)" begin
        # The Int leaf beside T: mixed at every activation. The tag must come back
        # as a stored `Int`, not a converted double in the `T` buffer.
        sim = Simulation(single(MixedCell()); h = 1//100)
        @test Set(keys(sim.exec.store.stores)) == Set([_cell_key(Float64), _cell_key(Int)])
        init!(sim)
        out = port(sim, "c", :out)
        @test out isa TaggedValue{Float64} && out.n === 1
        step!(sim, 1e-2)
        @test @ballocated(step!($sim, 1e-2)) == 0

        # The pinned leaf inside a declared struct (D-166): homogeneous at nominal
        # (K = 1), mixed off it — same declaration, and at `Dual` the `T` half
        # walks while `ref` stays a pinned `Float64` in its own buffer.
        sim = Simulation(single(PinnedInside()); h = 1//100)
        @test keys(sim.exec.store.stores) === (_cell_key(Float64),)
        sim = Simulation(single(PinnedInside()), D8; h = 1//100)
        @test Set(keys(sim.exec.store.stores)) == Set([_cell_key(D8), _cell_key(Float64)])
        init!(sim)
        out = port(sim, "c", :out)
        @test out isa PinnedPair{D8}
        @test out.a isa D8 && out.ref === 2.0
    end
end

function test_hierarchy()
    hierarchy_pinned_leaf()
    hierarchy_mixed_cell()
end
