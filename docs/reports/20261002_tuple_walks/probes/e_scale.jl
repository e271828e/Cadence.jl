# E: how publish!'s bytes scale with the signal table and with the roster.
using Redstone, StaticArrays, LinearAlgebra
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))
saw(n) = Group(NamedTuple{ntuple(i -> Symbol(:s, i), n)}(ntuple(_ -> Sawtooth(1.0), n)))
for (n, devices) in ((4, 0), (64, 0), (256, 0), (4, 1), (4, 2), (4, 4))
    sim = Simulation(saw(n); h = 1//1000)
    for _ in 1:devices; attach!(sim, TailProbe(), NoClaim()); end
    init!(sim, fragment(); log = false); run!(sim; t_end = 0.05)
    init!(sim, fragment(); log = false)
    a = @allocated run!(sim; t_end = 2.0)
    cells = sum(length(v.buffer) for v in values(sim.exec.store.stores))
    println("components=$n cells=$cells devices=$devices per frame=", round(a / sim.exec.clock.frame, digits = 1), " B")
end
