# --- the signal table (§9.7, §7.2, §7.3, D-162, D-166) ------------------------
# Cells are flattened by the §7.1 leaf walk into one contiguous buffer per
# element type, so what this file asserts is which buffers a model ends up with
# and what an address into them costs. Two routes make a cell span several: a
# leaf whose eltype is not the activation scalar, and a leaf deliberately pinned
# off it. The offsets live in the address's fields, which is what lets instances
# of one component type share one compiled body. §7.3's third register is here
# too, by contrast: the workspace is the one that is deliberately *not* a store.

# A deliberately pinned leaf (D-263): `frozen` is declared `Pinned{Float64}`, so
# it must not follow the activation scalar.
struct PinnedLeaf <: AbstractComponent end
init_x(::PinnedLeaf) = (;)
output_types(::PinnedLeaf) = (a = Float64, frozen = Pinned{Float64})
output_state(::PinnedLeaf, (; t)) = (a = t, frozen = 2.0)

function store_pinned_leaf()
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
# beside `T` leaves, and a pinned `Float64` a declared struct fixes as a field
# type, which the walk never reaches (D-263). The cell spans one buffer per
# leaf eltype; its address carries one cursor per eltype as an `NTuple` field
# (D-162's C2M point).
struct TaggedValue{T}
    v::T
    n::Int
end
struct MixedCell <: AbstractComponent end
init_x(::MixedCell) = (;)
output_types(::MixedCell) = (out = TaggedValue{Float64},)
output_state(::MixedCell, (; t)) = (out = TaggedValue(t, 1),)

struct PinnedPair{T}
    a::T
    ref::Float64
end
struct PinnedInside <: AbstractComponent end
init_x(::PinnedInside) = (;)
output_types(::PinnedInside) = (out = PinnedPair{Float64},)
output_state(::PinnedInside, (; t)) = (out = PinnedPair(t, 2.0),)

function store_mixed_cell()
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

        # The pinned leaf inside a declared struct (D-263): homogeneous at nominal
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

# --- the discrete tier's own cells (§7.3) -------------------------------------

function store_discrete_cells()
    @testset "discrete state and modes live outside the buffer (§7.3)" begin
        sim = Simulation(Group((; counter = TickCounter(), moded = ModedSource()));
                         h = 1//10)
        # The flat buffer is continuous state only; the counter's `Int` is in its
        # own store, and no store mirrors another.
        @test isempty(sim.exec.xbuf)
        @test state(sim, "counter") === (n = 0,)
        @test modes(sim, "moded") === (phase = :idle,)

        # `Int` and `Bool` cells force their own buffers — the plural in
        # "per-eltype stores", first exercised here. The field names are the
        # eltypes' fully-qualified spellings (`_cell_key`), which is the one
        # spelling a `@generated` gather and a plain `compile` agree on.
        @test Set(keys(sim.exec.store.stores)) ==
              Set([_cell_key(Int), _cell_key(Bool), _cell_key(Float64)])

        init!(sim)
        @test state(sim, "counter") === (n = 1,)   # boundary zero is a tick
        @test port(sim, "counter", :n) === 0       # the cell holds what it published
        @test port(sim, "counter", :even) === true
        run!(sim; t_end = 0.5)
        # Six boundaries: zero, then one per step. The store leads the cell by one,
        # the update having run after the output stage at each of them.
        @test state(sim, "counter") === (n = 6,)
        @test port(sim, "counter", :n) === 5
    end
end

# --- the workspace, the register that is not a store (§7.3) -------------------

function store_workspace()
    @testset "the workspace is scratch, on both tiers (§7.3)" begin
        sim = Simulation(Group((; sm = Smoother(0.5), src = ModedSource(), wg = WorkGain(2.0));
                               wires = ("src/out" => "sm/a",
                                        "src/out" => "sm/b",
                                        "src/out" => "wg/in"));
                         h = 1//10)
        init!(sim)
        @test port(sim, "wg", :out) == 0.0      # 2 × the idle-phase constant
        run!(sim; t_end = 0.3)
        @test state(sim, "sm").v isa SVector{2,Float64}

        # Allocation is what the idiom is for: in-place math on scratch, an isbits
        # snapshot into the store, and nothing on the measured path.
        bodies = phase_bodies(sim)
        for name in (:sweep_1, :sweep_2, :rhs, :ticks)
            body = bodies[name]
            body(); body(1)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end
    end
end

# --- one compiled body per component type (D-162) -----------------------------

function store_shared_bodies()
    @testset "instances of one component type share one compiled body (D-162)" begin
        # Two independent loops, each a sub-assembly of one root: eight components,
        # still one entry type per stage per component type — the store's addressing
        # keeps offsets in fields. The root's one face fans out to both.
        two = Group((; a = feedback_model(), b = feedback_model(k = 3.0));
                    inputs = ("ref" => ("a/ref", "b/ref"),))
        sim = Simulation(two; h = 1//100)
        types(body) = unique(typeof(e) for e in walked(body))
        @test length(types(sim.exec.bodies.sweep_1)) == 1     # two Plants, one output_state body
        @test length(types(sim.exec.bodies.sweep_2)) == 3    # Plant, Gain, Sum
        @test length(types(sim.exec.bodies.rhs)) == 1

        # The discrete tier keeps the property: a state store is a `Ref` whose
        # *type* every instance of a component type shares, so the store lives in a
        # field and two counters still compile to one `state_update` body.
        counters = Simulation(Group((; c1 = TickCounter(), c2 = TickCounter()));
                              h = 1//10)
        @test length(walked(counters.exec.bodies.ticks)) == 2
        @test length(types(counters.exec.bodies.ticks)) == 1
        @test length(types(counters.exec.bodies.sweep_1)) == 1
        # And one bundle type per model, whatever the eltype count (D-162).
        @test counters.exec.store isa StoreBundle
    end
end

# A `state_update` that widens its own store: the discrete world is pinned, so
# this is an error rather than a silent conversion at the store assignment.
struct WidenedUpdate <: AbstractComponent end
init_s(::WidenedUpdate) = (n = 0,)
output_types(::WidenedUpdate) = (n = Int,)
output_state(::WidenedUpdate, (; s)) = (n = s.n,)
state_update(::WidenedUpdate, (; s)) = (n = s.n + 0.5,)

function store_successor_type()
    @testset "a discrete successor is the store's own type (§7.3)" begin
        d = only(diagnostics(failure(() -> build(single(WidenedUpdate())))))
        @test d isa ConformanceFailure && d.what == "state_update" && d.reason === :field_set &&
              d.shape === :init_s && d.observed === @NamedTuple{n::Float64}
    end
end

# D-237's opaque leaf in the table: a handle type is its own leaf eltype, so it
# gets one homogeneous `CellStore` beside the numeric ones, and the gather and
# the scatter are one load and one store of the whole struct.
function store_opaque_leaf()
    @testset "a handle type is its own cell store (§4.4, D-237)" begin
        sim = Simulation(handle_model(); h = 1//10)
        @test Set(keys(sim.exec.store.stores)) ==
              Set([_cell_key(Float64), _cell_key(HeightField)])

        init!(sim)
        @test port(sim, "src", :terrain) isa HeightField
        @test port(sim, "q", :h) == 3.0

        # The cell hands out the one reference: the bulk data is shared, never
        # rebuilt, which is what makes the handle a handle.
        @test port(sim, "src", :terrain).z === port(sim, "src", :terrain).z

        # The handle's declaration carries no `T`, so its cell is the same type
        # at every activation while the numeric ports follow the scalar.
        dual_sim = Simulation(build(handle_model()), D8; h = 1//10)
        init!(dual_sim)
        @test _cell_key(HeightField) in keys(dual_sim.exec.store.stores)
        @test port(dual_sim, "src", :terrain) isa HeightField
        @test port(dual_sim, "q", :h) isa D8

        # One load and one store: the sweep that gathers and scatters a handle
        # allocates nothing (§9.7's canary, `test_executor.jl`).
        bodies = phase_bodies(sim)
        for name in (:sweep_1, :sweep_2, :rhs, :ticks)
            body = bodies[name]
            body(); body(0)
            @test @ballocated($body()) == 0
            @test @ballocated($body(1)) == 0
        end

        # The log and the trace: a snapshot copies the buffer whole, so the
        # handle cell is one struct copy sharing the bulk reference (§4.4).
        run!(sim; t_end = 0.5)
        @test port(latest(sim), "src", :terrain) isa HeightField
        trc = trace(sim)
        twin = Simulation(handle_model(); h = 1//10)
        init!(twin)
        replay!(twin, trc)
        @test port(twin, "q", :h) == 3.0

        # The abstract entry admits the handle by the bound clause (D-236).
        abstract_model = Group((; src = Terrain(), q = AbstractTerrainQuery());
                               wires = ("src/terrain" => "q/terrain",))
        abstract_sim = Simulation(abstract_model; h = 1//10)
        init!(abstract_sim)
        @test port(abstract_sim, "q", :h) == 3.0
    end
end

function test_store()
    store_pinned_leaf()
    store_mixed_cell()
    store_discrete_cells()
    store_workspace()
    store_shared_bodies()
    store_successor_type()
    store_opaque_leaf()
end
