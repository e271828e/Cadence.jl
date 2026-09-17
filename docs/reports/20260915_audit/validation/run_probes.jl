# Run from the repository root. Every probe gets a fresh process/module namespace.
# Exit zero means the probe reproduced its assertions, not that Cadence conforms.
using Dates

root = dirname(@__DIR__)
names = ("build_confirmed_gaps", "execution_time_bounds",
         "execution_handler_key_drift", "periphery_replay_payload",
         "periphery_timedout_handle", "services_confirmed_gaps",
         "publication_allocation", "termination_priority", "storage_diagnostic_gaps")
failed = String[]
open(joinpath(@__DIR__, "probe-results-final.log"), "w") do summary
    println(summary, "Started ", now(UTC), " UTC; Julia ", VERSION)
    for name in names
        file = joinpath(root, "probes", name * ".jl")
        logfile = joinpath(@__DIR__, name * "-final.log")
        command = Cmd([joinpath(Sys.BINDIR, "julia"), "--project=test", file])
        result = open(logfile, "w") do io
            process = run(pipeline(command; stdout=io, stderr=io); wait=false)
            wait(process)
            process.exitcode
        end
        println(summary, name, ": exit=", result)
        flush(summary)
        result == 0 || push!(failed, name)
    end
    println(summary, "Finished ", now(UTC), " UTC")
end
isempty(failed) || error("Probe execution failures: " * join(failed, ", "))
