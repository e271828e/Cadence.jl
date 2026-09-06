module CadenceTests

using Test, StaticArrays, LinearAlgebra, ForwardDiff, BenchmarkTools
using Cadence

include("imports.jl")

include("fixtures.jl")
include("utils.jl")

include("test_leaves.jl")
include("test_declare.jl")
include("test_assembly.jl")
include("test_store.jl")
include("test_build.jl")

include("test_executor.jl")
include("test_continuous.jl")
include("test_discrete.jl")
include("test_stepper.jl")
include("test_events.jl")
include("test_localization.jl")

include("test_dataplane.jl")
include("test_roster.jl")
include("test_bindings.jl")
include("test_devices.jl")
include("test_log.jl")
include("test_trace.jl")
include("test_readers.jl")

include("test_conditions.jl")
include("test_trim.jl")

include("test_diagnostics.jl")
include("test_failures.jl")
include("test_lifecycle.jl")

"""
Run one file's tests in a testset named `name` and print its summary as soon as
it completes. A nested testset stays silent until the root prints the whole
tree, so the summary is printed here by hand. The results still reach the
parent, so the final hierarchy is unchanged.
"""
function live(name, f)
    ts = @testset "$name" begin f() end
    Test.print_test_results(ts)
end

"""
Run the whole suite. Each file's summary prints as the file completes. The root
prints the total at the end, and expands only where something failed. One
file's tests are callable on their own: `test_trace()`.
"""
function runall()
    @testset "Cadence" begin
        live("leaves",       test_leaves)
        live("declare",      test_declare)
        live("assembly",     test_assembly)
        live("store",        test_store)
        live("build",        test_build)
        live("executor",     test_executor)
        live("continuous",   test_continuous)
        live("discrete",     test_discrete)
        live("stepper",      test_stepper)
        live("events",       test_events)
        live("localization", test_localization)
        live("dataplane",    test_dataplane)
        live("roster",       test_roster)
        live("bindings",     test_bindings)
        live("devices",      test_devices)
        live("log",          test_log)
        live("trace",        test_trace)
        live("readers",      test_readers)
        live("conditions",   test_conditions)
        live("trim",         test_trim)
        live("diagnostics",  test_diagnostics)
        live("failures",     test_failures)
        live("lifecycle",    test_lifecycle)
    end
end

"""
    runonly("trace", "devices")

Run only the named files' tests — the loop between commits, where the whole
suite is too slow to run per edit. `runall` names them all. A cold process
costs about 30 s before the first file's tests run and little per file after
that, so name a generous set rather than the minimal one.
"""
function runonly(names::AbstractString...)
    fs = map(names) do n                       # resolve first: a typo costs no run
        s = Symbol("test_", n)
        isdefined(@__MODULE__, s) || error("no tests named `$n` (`runall` names them)")
        getfield(@__MODULE__, s)
    end
    @testset "selected" begin
        for (n, f) in zip(names, fs)
            live(n, f)
        end
    end
end

end # module CadenceTests
