# --- the read-selector family and the compiled reader (§14.4; increment 21) ------
# The five deferred reads, their resolution against a build in §13.1's
# collecting form, and the gather twin of `apply!` over an executor. The fixtures
# live at top level for `implementation.md`'s local-scope reason; `lin_vector`
# and `lin_vector_point` are test_linearize.jl's.

# Every home a read can come from, and nothing that fires: a continuous `x`
# (the plant's `q`) with its derivative, a discrete `s` (the integrator's
# `acc`), a mode store no event transitions (`ModedSource`, §8.2), two root
# inputs and one root-exported output face.
readable() = Group((; plant = Plant(), ctl = DiscreteIntegrator(3.0), src = ModedSource());
                   inputs = ("u" => "plant/u", "e" => "ctl/e"),
                   outputs = ("plant/y" => "y",))

# The read world, authored: every store off its declared default, and `e` at
# zero so the integrator's `s_update` is stationary and boundary zero leaves
# `acc` as authored (§14.5).
readable_condition(q = SVector(0.3, -0.2), acc = 4.0) =
    combine(at("plant", fragment(x = (q = q,))),
            at("ctl", fragment(s = (acc = acc,))),
            at("src", fragment(m = (phase = :running,))),
            fragment(inputs = (u = 1.5, e = 0.0)))

# The read set the two activations share.
readable_reads() = reads(q = get_state("plant", :q), v = get_state("plant", "q[2]"),
                         acc = get_state("ctl", :acc), q̇ = get_deriv("plant", :q),
                         a = get_deriv("plant", "q[2]"), y = get_output("plant", :y),
                         u = get_input(:u), face = get_face(:y))

# A struct port holding a vector and a matrix, over a vector state: the leaf
# address's `.name`, `[k]` and `[k,l]` steps (§14.4, D-276). Every leaf is
# distinct, so a read of the wrong one shows.
struct LeafPose{T}
    v::SVector{3,T}
    m::SMatrix{2,2,T,4}
end
# The probe a root input of this type takes (§9.3), for test_linearize.jl's
# struct-typed root input.
probe_value(::Type{LeafPose{T}}) where {T} = LeafPose(zero(SVector{3,T}), zero(SMatrix{2,2,T,4}))

struct PoseSource <: AbstractComponent end
x_init(::PoseSource) = (q = SVector(0.5, -0.25),)
y_types(::PoseSource) = (pose = LeafPose{Float64},)
y_state(::PoseSource, (; x)) =
    (pose = LeafPose(SVector(x.q[1], x.q[2], 3.0), SMatrix{2,2}(1.0, 2.0, x.q[1], 4.0)),)
x_derivative(::PoseSource, (; x)) = (q = -x.q,)

pose_model() = single(PoseSource())

# Each step kind, the port whole in both spellings, and an index on the state.
pose_reads() = reads(v2 = get_output("c", "pose.v[2]"), m12 = get_output("c", "pose.m[1,2]"),
                     m3 = get_output("c", "pose.m[3]"), whole = get_output("c", "pose"),
                     short = get_output("c", :pose), q2 = get_state("c", "q[2]"))

# A discrete store holding a struct and a nested vector. Only the continuous
# tier is flat, so `get_state` on an `s` field takes the full address (§14.4, D-276).
struct PoseStore <: AbstractComponent end
s_init(::PoseStore) = (pose = LeafPose(SVector(1.0, 2.0, 3.0), SMatrix{2,2}(5.0, 6.0, 7.0, 8.0)),
                       w = SVector(SVector(1.0, 2.0), SVector(3.0, 4.0)))
y_types(::PoseStore) = (v1 = Float64,)
y_state(::PoseStore, (; s)) = (v1 = s.pose.v[1],)
s_update(::PoseStore, (; s)) = s

# Faces whose names hold a dot (§8.6), and `pose` exported beside `pose.v`, a
# struct face beside a face named like its field: a face selector matches its
# head against the face list, the longest name first (§14.4, D-276).
struct DottedFaces <: AbstractComponent end
x_init(::DottedFaces) = (q = SVector(0.5, -0.25),)
u_types(::DottedFaces) = (u = SVector{2,Float64},)
y_types(::DottedFaces) = (θ = Float64, pose = LeafPose{Float64}, v = SVector{3,Float64})
y_state(::DottedFaces, (; x)) =
    (θ = x.q[1], pose = LeafPose(SVector(x.q[1], x.q[2], 3.0), SMatrix{2,2}(1.0, 2.0, x.q[1] + 2.5, 4.0)),
     v = SVector(7.0, 8.0, 9.0))   # the matrix follows `T` too, so the build's Dual sweep admits it
x_derivative(::DottedFaces, (; x, u)) = (q = u.u - x.q,)

dotted_model() = Group((; c = DottedFaces()); inputs = ("left.brake" => "c/u",),
                       outputs = ("c/θ" => "att.theta", "c/pose" => "pose", "c/v" => "pose.v"))
dotted_condition() = fragment(inputs = (var"left.brake" = SVector(1.5, 2.5),))

# Every store, the root inputs and the clock, read straight out of an executor.
world(sim) = (copy(sim.exec.xbuf),
              [s === nothing ? nothing : s[] for s in sim.exec.sstores],
              [m === nothing ? nothing : m[] for m in sim.exec.mstores],
              [port(sim, "", f) for f in sim.deployment.build.structure.root_inputs],
              sim.exec.clock.t)

function test_readers()
    @testset "the five selectors read what they name, at either activation (§14.4)" begin
        for T in (Float64, D8)
            sim = Simulation(readable(), T; h = 1//10)
            init!(sim, readable_condition())
            evaluate!(sim.exec)                     # `ẋ` is integrator scratch: fill it first
            r = _compile_reads(readable_reads(), sim.deployment.build, T)
            v = gather_reads(r, sim.exec)

            @test keys(v) === (:q, :v, :acc, :q̇, :a, :y, :u, :face)
            @test v.q == SVector{2,T}(0.3, -0.2)     # the whole leaf, out of `xbuf`
            @test v.v === v.q[2]                     # an index step reads one component
            @test v.acc === 4.0                      # the discrete store, pinned Float64
            @test v.q̇[1] === v.q[2]                  # `x_derivative`'s own output, out of `ẋbuf`
            @test v.a === v.q̇[2]
            @test v.y === v.q[1]                     # the stage-1 port's cell
            @test v.u === T(1.5)                     # the root input cell
            @test v.face === v.y                     # the exported face is its producer's cell

            # The leaf types are the activation's, so a `Dual` world reads `Dual`s
            # and the frozen discrete store stays pinned (§9.4, D-166).
            @test v.q isa SVector{2,T} && v.q̇ isa SVector{2,T} && v.y isa T
            @test v.acc isa Float64

            # The leaf address steps into a struct port (§14.4, D-276): a field and
            # a component, a matrix entry by its indices and by its linear place.
            pose_sim = Simulation(pose_model(), T; h = 1//10)
            init!(pose_sim)
            pose = gather_reads(_compile_reads(pose_reads(), pose_sim.deployment.build, T), pose_sim.exec)
            @test pose.whole isa LeafPose{T} && pose.short === pose.whole  # `:pose` is `"pose"`
            @test pose.v2 === pose.whole.v[2] === T(-0.25)
            @test pose.m12 === pose.whole.m[1, 2] === T(0.5)
            @test pose.m3 === pose.m12                                        # `[3]` is `[1,2]`, column-major
            @test pose.q2 === T(-0.25)
        end

        # A discrete `s` field takes a `.name` step and a chain of two index steps.
        store_sim = Simulation(single(PoseStore()); h = 1//10)
        init!(store_sim)
        stored = gather_reads(_compile_reads(reads(m12 = get_state("c", "pose.m[1,2]"),
                                                   w21 = get_state("c", "w[2][1]")),
                                             store_sim.deployment.build), store_sim.exec)
        @test stored.m12 === 7.0 && stored.w21 === 3.0
    end

    @testset "the reader is the gather twin: allocation-free over an executor (§14.4, §7.5)" begin
        sim = Simulation(readable(); h = 1//10)
        init!(sim, readable_condition())
        evaluate!(sim.exec)
        reader, exec = _compile_reads(readable_reads(), sim.deployment.build), sim.exec
        gather_reads(reader, exec)
        @test @ballocated(gather_reads($reader, $exec)) == 0
        @test @inferred(gather_reads(reader, exec)) isa NamedTuple
        @test gather_reads(_compile_reads(reads(), sim.deployment.build), exec) === (;)   # the empty set reads nothing

        # A two-step address is unrolled at compile time, so it allocates nothing.
        pose_sim = Simulation(pose_model(); h = 1//10)
        init!(pose_sim)
        pose_reader, pose_exec = _compile_reads(pose_reads(), pose_sim.deployment.build), pose_sim.exec
        gather_reads(pose_reader, pose_exec)
        @test @ballocated(gather_reads($pose_reader, $pose_exec)) == 0
        @test @inferred(gather_reads(pose_reader, pose_exec)) isa NamedTuple
    end

    @testset "resolution collects every violation into one refusal (§14.4, §13.1)" begin
        readable_build = build(readable())
        err = failure(() -> _compile_reads(reads(a = get_state("plnt", :q),
                                                 b = get_output("plant", :thrust),
                                                 c = get_deriv("ctl", :acc),
                                                 d = get_face(:nope)), readable_build))
        @test err isa DiagnosticError && length(diagnostics(err)) == 4              # the full list, one throw
        (a, b_, c, d) = diagnostics(err)
        # The path itself is the walk's refusal, one case over, and the one
        # path arm that now carries a list in hand (§13.3).
        @test a isa PathResolution && a.reason === :unknown_child && a.segment == "plnt" &&
              a.candidates == ["plant", "ctl", "src"]
        @test startswith(a.entry, "the read labeled `a`")
        @test all(x -> x isa TapResolution, (b_, c, d))
        @test b_.reason === :undeclared && b_.declares === :output_port &&
              b_.field === :thrust && b_.candidates == [:y, :power]            # the list in hand
        @test c.selector == "get_deriv(\"ctl\", :acc)" && c.reason === :discrete_deriv
        @test d.reason === :unknown_output_face && d.field === :nope && d.candidates == [:y]
        @test [x.label for x in (b_, c, d)] == [:b, :c, :d]                     # each read, by label

        # An assembly path, a root input read as a face, an index on a scalar leaf,
        # and a state field the component does not declare.
        err = failure(() -> _compile_reads(reads(a = get_output("", :y), b = get_face(:u),
                                                 c = get_output("plant", "y[1]"),
                                                 d = get_state("plant", :ω),
                                                 e = get_input("u[1]"), f = get_face("y[1]")),
                                     readable_build))
        (a, b_, c, d, e, f) = diagnostics(err)
        @test a.reason === :assembly_path && a.path == "" && a.tap === :y
        @test b_.reason === :root_input_not_face && b_.field === :u
        @test c.reason === :not_indexable && c.step == "[1]" && c.declared === Float64 &&
              c.leaf == "y[1]" && c.field === :y
        @test d.reason === :undeclared && d.declares === :state_field && d.field === :ω &&
              d.candidates == [:q]
        # The two table selectors check their steps as the others do (D-276).
        @test e.reason === :not_indexable && e.step == "[1]" && e.declared === Float64 && e.tap === :u
        @test f.reason === :not_indexable && f.step == "[1]" && f.declared === Float64 && f.tap === :y
        # The selector as authored: a `Symbol` leaf with its colon, a string one quoted.
        @test b_.selector == "get_face(:u)" && c.selector == "get_output(\"plant\", \"y[1]\")"

        # Every step the leaf address cannot take, each checked against the type
        # resolved so far and named as spelled (§14.4, D-276).
        err = failure(() -> _compile_reads(reads(a = get_output("c", "pose.v["),
                                                 b = get_output("c", "pose.q"),
                                                 c = get_output("c", "pose.v.x"),
                                                 d = get_output("c", "pose[2]"),
                                                 e = get_output("c", "pose.m[1,2,1]"),
                                                 f = get_output("c", "pose.v[4]"),
                                                 g = get_state("c", "q.x")),
                                           build(pose_model())))
        by_label = Dict(d.label => d for d in diagnostics(err))
        @test length(by_label) == 7 && all(d -> d isa TapResolution, values(by_label))
        @test by_label[:a].reason === :leaf_syntax && by_label[:a].step == "[" &&
              by_label[:a].declared === nothing && by_label[:a].leaf == "pose.v["
        @test by_label[:b].reason === :no_such_field && by_label[:b].step == ".q" &&
              by_label[:b].declared === LeafPose{Float64} && by_label[:b].candidates == [:v, :m]
        @test by_label[:c].reason === :no_such_field && by_label[:c].step == ".x" &&
              by_label[:c].declared === SVector{3,Float64} && isempty(by_label[:c].candidates)
        @test by_label[:d].reason === :not_indexable && by_label[:d].step == "[2]" &&
              by_label[:d].declared === LeafPose{Float64}
        @test by_label[:e].reason === :index_arity && by_label[:e].step == "[1,2,1]" &&
              by_label[:e].declared === SMatrix{2,2,Float64,4}
        @test by_label[:f].reason === :index_bounds && by_label[:f].step == "[4]" &&
              by_label[:f].declared === SVector{3,Float64}
        # The state is flat (§7.1): a `.name` step on a store selector finds no field.
        @test by_label[:g].reason === :no_such_field && by_label[:g].step == ".x" &&
              by_label[:g].declared === SVector{2,Float64} && isempty(by_label[:g].candidates)
        # A step never enters an opaque leaf, which is read whole (§4.3).
        d = only(diagnostics(failure(() -> _compile_reads(reads(h = get_output("c", "terrain.h0")),
                                                          build(single(OffsetAtT()))))))
        @test d.reason === :opaque_leaf && d.step == ".h0" && d.declared === OffsetField{Float64}

        # The read set is a type, not a NamedTuple: the bare spelling is refused
        # with a directive, not a `MethodError` (§14.2's rule, one case over).
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} _compile_reads((q = get_state("plant", :q),), readable_build))
        @test d.reason === :not_a_read_set
        d = carried(@test_throws DiagnosticError{ReadSetMisuse} reads(q = 2.0))                    # nor is 2.0 a selector
        @test d.reason === :not_a_selector && d.label === :q
    end

    @testset "a read selector's path stays within a concretely declared subtree (§13.3, §14.7, D-125)" begin
        # No mounting exists, so every selector path is authored at the root and
        # walked from it in full: the first segment may be generically held, a
        # segment past one may not. `ConcreteHold`/`GenericHold` hold the same
        # instance two ways (`test_assembly.jl`).
        deep = reads(q = get_state("inner/plant", :q))
        d = only(diagnostics(failure(() -> _compile_reads(deep,
                                              build(GenericHold(SampledLoop()))))))
        @test d isa PathResolution && d.reason === :past_generic && d.segment == "inner"

        # Declaring the field's concrete type restores the deep read legally, with
        # the hard-coding visible in the declaration itself (§13.3).
        sim = Simulation(ConcreteHold(SampledLoop()); h = 1//50)
        init!(sim, combine(at("inner/plant", fragment(x = (q = SVector(0.3, 0.1),))),
                           fragment(inputs = (ref = 1.0,))))
        evaluate!(sim.exec)
        @test gather_reads(_compile_reads(deep, sim.deployment.build), sim.exec).q == SVector(0.3, 0.1)

        # D-125's own remedy, and the one that survives substitution: the seam
        # publishes a face, which is what the read binds to.
        for holder in (ConcreteHold(SampledLoop()), GenericHold(SampledLoop()))
            @test _compile_reads(reads(y = get_face(:y)), build(holder)) isa Reader
        end

        # The walk stops at a primitive here too: a leaf's component-typed field is
        # no level of the build, so the segment past it names no child and the
        # refusal has no list to offer (§8.5, §13.3).
        opaque_build = build(OpaqueHold(OpaqueLeaf(Gain(2.0))))
        d = only(diagnostics(failure(() ->
                _compile_reads(reads(z = get_state("c/hidden", :z)), opaque_build))))
        @test d isa PathResolution && d.reason === :unknown_child
        @test d.segment == "hidden" && d.owner == "`c`" && d.candidates == String[]
        @test startswith(d.entry, "the read labeled `z`")
    end

    @testset "the source rule: a snapshot-bound reader may not name a store selector (§14.4)" begin
        sim = Simulation(readable(); h = 1//10)
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(sim, Pad("t"), Readout(q = get_state("plant", :q))))
        @test d.reason === :store_selector &&
              d.selector == "get_state(\"plant\", :q)"
        @test isempty(sim.plane.roster)              # the rejection left the roster untouched

        # Every table member takes a leaf address, and a binding gather is the
        # family's baked read over the snapshot (§14.4, D-276).
        vector_sim = Simulation(lin_vector(); h = 1//10)
        handle = attach!(vector_sim, Pad("t"), Readout(q2 = get_output("p", "q[2]"),
                                                       qin1 = get_input("qin[1]"),
                                                       face2 = get_face("q[2]")))
        init!(vector_sim, lin_vector_point())
        snapshot = latest(vector_sim)
        @test gather(handle, snapshot) === (q2 = port(snapshot, "p", :q)[2],
                                            qin1 = port(snapshot, "", :qin)[1],
                                            face2 = port(snapshot, "", :q)[2])
        @test gather(handle, snapshot) === (q2 = 0.2, qin1 = 0.5, face2 = 0.2)

        # A `.name` step into a struct port, and a matrix entry by its indices.
        pose_sim = Simulation(pose_model(); h = 1//10)
        handle = attach!(pose_sim, Pad("t"), Readout(v = get_output("c", "pose.v"),
                                                     m12 = get_output("c", "pose.m[1,2]")))
        init!(pose_sim)
        snapshot = latest(pose_sim)
        pose = port(snapshot, "c", :pose)
        @test gather(handle, snapshot) === (v = pose.v, m12 = pose.m[1, 2])
        gatherer = handle.gatherer
        @test @ballocated(gather_snapshot($gatherer, $snapshot)) == 0      # `pose.m[1,2]` is two steps

        # A step the address cannot take is refused at attach with the family's
        # reason, the step named as spelled.
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(pose_sim, Pad("t"), Readout(q = get_output("c", "pose.q"))))
        @test d.reason === :no_such_field && d.step == ".q" && d.candidates == [:v, :m] &&
              d.declared === LeafPose{Float64} && d.leaf == "pose.q" && d.field === :pose
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(pose_sim, Pad("t"), Readout(v = get_output("c", "pose.v[4]"))))
        @test d.reason === :index_bounds && d.step == "[4]" && d.declared === SVector{3,Float64}
        @test length(pose_sim.plane.roster) == 1     # the two rejections left the roster as it was
    end

    @testset "a face name may hold a dot: a face selector's head is matched (§14.4, D-276)" begin
        sim = Simulation(dotted_model(); h = 1//10)
        init!(sim, dotted_condition())
        v = gather_reads(_compile_reads(reads(brake = get_input("left.brake"),
                                              short = get_input(:var"left.brake"),
                                              brake2 = get_input("left.brake[2]"),
                                              theta = get_face("att.theta"),
                                              pose_v = get_face("pose.v"),
                                              pose_v2 = get_face("pose.v[2]"),
                                              m12 = get_face("pose.m[1,2]")),
                                        sim.deployment.build), sim.exec)
        @test v.brake === v.short === SVector(1.5, 2.5)   # a `Symbol` names the face whole
        @test v.brake2 === 2.5
        @test v.theta === 0.5
        # The longest face wins: `pose.v` is the face, not `pose`'s field `v`.
        @test v.pose_v === SVector(7.0, 8.0, 9.0) && v.pose_v2 === 8.0
        @test v.m12 === 3.0                                # `pose`, then `.m[1,2]`

        # A binding read matches the same way (§11.2).
        bound_sim = Simulation(dotted_model(); h = 1//10)
        handle = attach!(bound_sim, Pad("t"), Readout(brake = get_input("left.brake"),
                                                      theta = get_face("att.theta"),
                                                      pose_v = get_face("pose.v")))
        init!(bound_sim, dotted_condition())
        snapshot = latest(bound_sim)
        @test gather(handle, snapshot) === (brake = SVector(1.5, 2.5), theta = 0.5,
                                            pose_v = SVector(7.0, 8.0, 9.0))

        # Where no face matches, `field` is the whole address, the candidates the list.
        err = failure(() -> _compile_reads(reads(a = get_input("left.brakes"),
                                                 b = get_face("att")), sim.deployment.build))
        (a, b_) = diagnostics(err)
        @test a.reason === :unknown_root_input && a.field === Symbol("left.brakes") &&
              a.candidates == [Symbol("left.brake")]
        @test b_.reason === :unknown_output_face && b_.field === :att &&
              b_.candidates == [Symbol("att.theta"), :pose, Symbol("pose.v")]
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(sim, Pad("t"), Readout(v = get_face("att.th"))))
        @test d.reason === :unknown_output_face && d.field === Symbol("att.th") &&
              d.candidates == [Symbol("att.theta"), :pose, Symbol("pose.v")]
        # A matched face refuses its steps under the face's own name.
        d = carried(@test_throws DiagnosticError{ReadBindingUnresolved} attach!(sim, Pad("t"), Readout(v = get_face("att.theta.x"))))
        @test d.reason === :no_such_field && d.field === Symbol("att.theta") && d.step == ".x"
    end

    @testset "a reader and a plan belong to one activation, by dispatch (§9.4, §14.4)" begin
        # The offsets, store types and cell addresses a compiled product bakes are
        # one activation's, so a `Float64` product against a `Dual` executor would
        # read and write another cell's slot in silence. The scalar rides in each
        # product's type, the pairing is dispatch, and the mismatch is refused with
        # both scalars named — before anything is touched. §14.4 makes that pairing
        # an invariant the services uphold, so the refusal is an internal assertion
        # and carries no kind name.
        nominal = Simulation(readable(); h = 1//10)
        seeded = Simulation(readable(), D8; h = 1//10)
        init!(seeded, readable_condition())
        before = world(seeded)

        err = failure(() -> gather_reads(_compile_reads(readable_reads(), nominal.deployment.build), seeded.exec))
        @test err isa InternalInvariant         # not a diagnostic kind, and not a DiagnosticError
        @test occursin("compiled at Float64", err.message) && occursin("Dual{Nothing, Float64, 8}", err.message)
        # `InternalInvariant` carries a message and no payload by design (D-215),
        # so it is matched on text — it is no diagnostic kind.

        authored = readable_condition()
        err = failure(() -> apply!(seeded.exec, resolve_condition(authored, nominal.deployment.build)))
        @test err isa InternalInvariant
        err = failure(() -> apply!(seeded.exec, compile_plan(authored, nominal.deployment.build), authored))
        @test err isa InternalInvariant

        @test world(seeded) == before                # every refusal left the executor alone
    end

    @testset "the origin is a `Float64`, so a seeded simulation takes `t0` (§12.6, D-260)" begin
        # `t₀` is the grid's anchor and no design reader wants it perturbed, so
        # it is a `Float64` on the clock while `t` stays in the deployment's
        # scalar. A `T`-typed keyword refused `t0 = 0.25` here.
        seeded = Simulation(readable(), D8; h = 1//10)
        init!(seeded, readable_condition(); t0 = 0.25)
        @test seeded.exec.clock.t₀ === 0.25
        @test seeded.exec.clock.t isa D8 && ForwardDiff.value(seeded.exec.clock.t) === 0.25
    end
end
