include(joinpath(@__DIR__, "..", "..", "..", "..", "test", "CadenceTests.jl"))

const CT = Main.CadenceTests
const C = CT.Cadence

function source_trace()
    sim = CT.Simulation(CT.two_root_inputs(); h = 1 // 10)
    CT.init!(sim, CT.fragment(inputs = (a = 1.0, b = 2.0)))
    CT.stage!(sim, "a" => 3.0)
    CT.step!(sim)
    CT.trace(sim)
end

function target(a, b)
    sim = CT.Simulation(CT.two_root_inputs(); h = 1 // 10)
    CT.init!(sim, CT.fragment(inputs = (; a, b)))
    sim
end

function with_roots(h, roots)
    C.TraceHeader{Float64}(
        copy(h.x), copy(h.s), copy(h.m), roots, deepcopy(h.schemas),
        h.deployment, deepcopy(h.layout),
    )
end

trc = source_trace()

# The header's layout still self-reports both root faces, but its payload omits b.
# The entry check accepts it, and replay silently retains b from the target's old
# trajectory instead of establishing the recording's complete initial world.
missing = C.Trace(
    with_roots(trc.header, Pair{Symbol,Any}[:a => 1.0]),
    copy(trc.batches), trc.frames,
)
sim_missing = target(10.0, 20.0)
CT.replay!(sim_missing, missing; to_boundary = 0)
missing_a = CT.port(sim_missing, "", :a)
missing_b = CT.port(sim_missing, "", :b)
println("missing root accepted: a=$missing_a, b=$missing_b, lifecycle=$(CT.lifecycle(sim_missing))")

# The same self-reported layout lets an extra unknown root reach the write loop.
# The valid entry before it is committed, then the KeyError escapes before
# _open_trajectory! or the boundary-zero host: lifecycle and latest still describe
# the old trajectory while the live store has been partially changed.
extra = C.Trace(
    with_roots(trc.header, Pair{Symbol,Any}[:a => 99.0, :zzz => 4.0]),
    copy(trc.batches), trc.frames,
)
sim_extra = target(10.0, 20.0)
err = try
    CT.replay!(sim_extra, extra; to_boundary = 0)
    nothing
catch e
    e
end
extra_live_a = CT.port(sim_extra, "", :a)
extra_latest_a = CT.port(CT.latest(sim_extra), "", :a)
println("extra root error=$(typeof(err)); live a=$extra_live_a; latest a=$extra_latest_a; " *
        "lifecycle=$(CT.lifecycle(sim_extra))")

# trace(sim) copies only the outer batches vector and shares the header. Mutating
# either inner vector through the returned value changes the simulation's register.
sim_alias = CT.Simulation(CT.two_root_inputs(); h = 1 // 10)
CT.init!(sim_alias, CT.fragment(inputs = (a = 0.0, b = 0.0)))
CT.stage!(sim_alias, "a" => 5.0)
CT.step!(sim_alias)
out = CT.trace(sim_alias)
push!(last(out.header.schemas[1]), :injected)
out.batches[1].entries[1] = 2 => 77.0
again = CT.trace(sim_alias)
println("trace aliases register: schema=$(again.header.schemas[1]), entries=$(again.batches[1].entries)")
