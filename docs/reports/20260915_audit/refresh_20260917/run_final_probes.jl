using Dates
root = @__DIR__
names = ("handler_probe" => joinpath(root, "handler_probe.jl"),
         "execution_time_bounds" => joinpath(root, "..", "probes", "execution_time_bounds.jl"),
         "periphery_replay_payload" => joinpath(root, "..", "probes", "periphery_replay_payload.jl"),
         "periphery_timedout_handle" => joinpath(root, "..", "probes", "periphery_timedout_handle.jl"),
         "services_confirmed_gaps" => joinpath(root, "..", "probes", "services_confirmed_gaps.jl"),
         "termination_priority" => joinpath(root, "..", "probes", "termination_priority.jl"))
open(joinpath(root, "runtime-probes-final.log"), "w") do summary
    println(summary, "Started ", now(UTC), " UTC; Julia ", VERSION)
    for (name, file) in names
        open(joinpath(root, name * "-final.log"), "w") do output
            p = run(pipeline(ignorestatus(Cmd([joinpath(Sys.BINDIR, "julia"), "--project=test", file])), stdout=output, stderr=output))
            println(summary, name, ": exit=", p.exitcode)
            flush(summary)
        end
    end
    println(summary, "Finished ", now(UTC), " UTC")
end
