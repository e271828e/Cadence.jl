using Cadence
using StaticArrays

import Cadence: AbstractComponent, DiagnosticError, Simulation, TrimProblem, _compile_reads,
    at, build, evaluate!, fragment, gather, get_state, init!, init_x, input_types,
    output_direct, output_state, output_types, reads, resolve_condition,
    state_derivative, trim!

function show_result(label, f)
    try
        println(label, ": success => ", f())
    catch err
        carried = err isa DiagnosticError ? err.carried : nothing
        println(label, ": ", typeof(err), " carried=", carried === nothing ? "none" : typeof(carried))
    end
end

struct ServiceVectorState <: AbstractComponent end
init_x(::ServiceVectorState) = (q = SVector(1.0, 2.0),)
output_types(::ServiceVectorState, ::Type{T}) where {T<:Real} = (q = SVector{2,T},)
output_state(::ServiceVectorState, (; x)) = (q = x.q,)
state_derivative(::ServiceVectorState, (; x)) = (q = zero(x.q),)

# §14.9 requires `at(prefix, problem)` and its read-set half.
empty_problem = TrimProblem(guess = (;), lower = (;), upper = (;),
                            condition = _ -> fragment(), reads = reads(),
                            residuals = (_, _) -> (;), tolerances = (;))
show_result("relocate TrimProblem", () -> at("mount", empty_problem))
show_result("relocate Reads", () -> at("mount", reads(q = get_state("", :q))))

# A statically out-of-range component selector resolves, then fails during gather.
sim = Simulation(ServiceVectorState(); h = 1//10)
init!(sim)
evaluate!(sim.exec)
reader = _compile_reads(reads(q3 = get_state("", :q, 3)), sim.build)
show_result("out-of-range compiled read", () -> gather(reader, sim.exec))

# A non-callable required TrimProblem field bypasses collected setup validation.
bad_condition = TrimProblem(guess = (;), lower = (;), upper = (;), condition = 42,
                            reads = reads(), residuals = (_, _) -> (;), tolerances = (;))
show_result("non-callable trim condition", () ->
    trim!(Simulation(ServiceVectorState(); h = 1//10), bad_condition; baseline = fragment()))

# Conversion failures are collected, but an operator interrupt must unwind.
struct InterruptValue end
Base.convert(::Type{Float64}, ::InterruptValue) = throw(InterruptException())
struct ServiceInput <: AbstractComponent end
input_types(::ServiceInput, ::Type{T}) where {T<:Real} = (u = T,)
output_types(::ServiceInput, ::Type{T}) where {T<:Real} = (y = T,)
output_direct(::ServiceInput, (; u)) = (y = u.u,)
show_result("interrupt during condition conversion", () ->
    resolve_condition(fragment(inputs = (u = InterruptValue(),)), build(ServiceInput())))

println("linearize defined: ", isdefined(Cadence, :linearize))
