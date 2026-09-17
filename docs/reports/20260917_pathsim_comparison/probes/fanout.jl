include(joinpath(@__DIR__, "..", "..", "..", "..", "test", "repl.jl"))

two_loops(inputs) = Group((plant1 = Plant(), ctl1 = Gain(4.0), sum1 = Sum(),
                           plant2 = Plant(), ctl2 = Gain(4.0), sum2 = Sum());
    wires = ("ctl1/out" => "plant1/u", "sum1/e" => "ctl1/e", "plant1/y" => "sum1/b",
             "ctl2/out" => "plant2/u", "sum2/e" => "ctl2/e", "plant2/y" => "sum2/b"),
    inputs, outputs = ("plant1/y" => "y1", "plant2/y" => "y2"))

println("--- repeated pairs (what I wrote in the benchmark)")
try
    Simulation(two_loops(("ref" => "sum1/a", "ref" => "sum2/a")); h = 1//1000)
catch e
    println(sprint(showerror, e))
end

println("--- tuple of endpoints (§8.6's fan-out form)")
sim = Simulation(two_loops(("ref" => ("sum1/a", "sum2/a"),)); h = 1//1000)
init!(sim, fragment(inputs = (ref = 0.7,)))
run!(sim; t_end = 2.0)
println("y1 = ", port(sim, "plant1", :y), "   y2 = ", port(sim, "plant2", :y))
