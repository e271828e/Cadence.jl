using Cadence
const C = Cadence

struct AuditPublication <: C.AbstractComponent end
C.output_types(::AuditPublication, ::Type{T}) where {T <: Real} = (value = T,)
C.output_state(::AuditPublication, (; t)) = (value = t,)

measure_publication(sim) = @allocated C.publish!(sim)
measure_step(sim) = @allocated C.step!(sim; frames = 1)

function main()
    println("Julia ", VERSION, "; threads=", Threads.nthreads())
    for logging in (false, true)
        sim = C.Simulation(AuditPublication(); h = 1//100, trace = false,
                           log = logging, log_max = 1024)
        C.init!(sim)
        for _ in 1:20
            measure_publication(sim)
            measure_step(sim)
        end
        published = minimum(measure_publication(sim) for _ in 1:10)
        stepped = minimum(measure_step(sim) for _ in 1:10)
        println("log=", logging, ": publication bytes=", published,
                "; whole frame bytes=", stepped)
        @assert published > 0
    end
end
main()
