# The same 64 loops under a struct-declared assembly whose type does not carry
# its children (abstract field) versus one whose type does (typed field).
Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
import Cadence: child_connections, input_connections, output_connections, transparent_container
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
struct Bank <: AbstractComponent; m::NamedTuple; end            # tiny type
struct BankT{NT<:NamedTuple} <: AbstractComponent; m::NT; end   # type carries the subtree
for B in (Bank, BankT)
    @eval begin
        child_connections(::$B) = ()
        transparent_container(::$B) = :m
        input_connections(b::$B) = ("ref" => ntuple(i -> "m$(i)/ref", length(b.m)),)
        output_connections(::$B) = ()
    end
end
loops(N) = NamedTuple{ntuple(i -> Symbol(:m, i), N)}(ntuple(i -> loop(Plant(2.0, 0.3)), N))
# warm-up on 2 loops for each spelling
for B in (Bank, BankT)
    s = Simulation(B(loops(2)); h = 1//1000); init!(s, fragment(inputs = (ref = 1.0,))); run!(s; t_end = 0.01)
end
for (label, root) in (("Bank (abstract field), 64 loops", Bank(loops(64))), ("BankT (typed field), 64 loops", BankT(loops(64))))
    println(label, " — type string $(length(string(typeof(root)))) chars")
    global b, sim
    c0 = ct(); t = @elapsed b = build(root);                      @printf("  build      %6.2f s (compile %6.2f)\n", t, ct() - c0)
    c0 = ct(); t = @elapsed sim = Simulation(b; h = 1//1000);      @printf("  Simulation %6.2f s (compile %6.2f)\n", t, ct() - c0)
    c0 = ct(); t = @elapsed init!(sim, fragment(inputs = (ref = 1.0,))); @printf("  init!      %6.2f s (compile %6.2f)\n", t, ct() - c0)
    c0 = ct(); t = @elapsed run!(sim; t_end = 0.01);               @printf("  run!       %6.2f s (compile %6.2f)\n", t, ct() - c0)
end
