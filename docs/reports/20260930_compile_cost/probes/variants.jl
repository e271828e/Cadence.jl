Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using Base.ScopedValues: with
import Cadence: StructureDraft, flatten!, _check_event_declarations, wire!, _check_wires, Structure,
    _nominal, Diagnostic, DiagnosticError, BUILD_WARNINGS, Build, activation, logline
m2 = many(2); b2 = build(m2)
ct() = Base.cumulative_compile_time_ns()[1] / 1e9

function core(root, activations, raised_warnings)   # the closure body, as a function
    diags = Diagnostic[]
    draft = StructureDraft(root)
    flatten!(draft, root, diags)
    _check_event_declarations(draft, diags)
    isempty(diags) || throw(DiagnosticError(diags))
    conns, in_faces = wire!(draft)
    root_types = _check_wires(draft, conns, diags)
    isempty(diags) || throw(DiagnosticError(diags))
    structure = Structure(draft, conns, in_faces, root_types)
    outputs, events, nominal = _nominal(structure)
    built = Build(structure, outputs, events, Dict{DataType,Any}(Float64 => nominal), ReentrantLock(), raised_warnings)
    for scalar in activations; activation(built, scalar); end
    built
end
# V0: verbatim shape — closure over root, try/catch, warn loop
function v0(root; activations::Tuple = ())
    raised_warnings = Diagnostic[]
    built = try
        with(BUILD_WARNINGS => raised_warnings) do
            core(root, activations, raised_warnings)
        end
    catch err
        (err isa DiagnosticError && !isempty(raised_warnings)) && throw(DiagnosticError(err.carried, raised_warnings))
        rethrow()
    end
    for warning in raised_warnings; @warn logline(warning); end
    built
end
# V1: no try/catch
function v1(root; activations::Tuple = ())
    raised_warnings = Diagnostic[]
    built = with(BUILD_WARNINGS => raised_warnings) do
        core(root, activations, raised_warnings)
    end
    for warning in raised_warnings; @warn logline(warning); end
    built
end
# V2: no try/catch, no warn loop
function v2(root; activations::Tuple = ())
    raised_warnings = Diagnostic[]
    with(BUILD_WARNINGS => raised_warnings) do
        core(root, activations, raised_warnings)
    end
end
# V3: as V0 but the root reaches the closure untyped
function v3(root; activations::Tuple = ())
    raised_warnings = Diagnostic[]
    rootany::Any = root
    built = try
        with(BUILD_WARNINGS => raised_warnings) do
            core(rootany, activations, raised_warnings)
        end
    catch err
        (err isa DiagnosticError && !isempty(raised_warnings)) && throw(DiagnosticError(err.carried, raised_warnings))
        rethrow()
    end
    for warning in raised_warnings; @warn logline(warning); end
    built
end
# V4: core called directly under `with`, no closure capture of root (Base.invokelatest-free)
function v4(root; activations::Tuple = ())
    raised_warnings = Diagnostic[]
    with(() -> core(root, activations, raised_warnings), BUILD_WARNINGS => raised_warnings)
end
for (label, f, N) in (("V0 verbatim shape", v0, 60), ("V1 no try/catch", v1, 61), ("V2 no try/catch, no warn loop", v2, 62),
                      ("V3 root untyped into the closure", v3, 63), ("V4 with(f, pair) form", v4, 64), ("Cadence.build itself", build, 65))
    root = many(N)
    c0 = ct(); t = @elapsed f(root)
    @printf("%-36s N=%d  %6.2f s (compile %6.2f)\n", label, N, t, ct() - c0)
end
