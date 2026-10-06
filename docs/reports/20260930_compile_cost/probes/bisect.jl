Base.cumulative_compile_timing(true)
include(joinpath(@__DIR__, "cum_defs.jl"))
using Base.ScopedValues: with
import Redstone: StructureDraft, flatten!, _check_event_declarations, wire!, _check_wires, Structure,
    _nominal, Diagnostic, BUILD_WARNINGS, Build
m2 = many(2); b2 = build(m2)
ct() = Base.cumulative_compile_time_ns()[1] / 1e9
macro tm(label, ex)
    quote
        local c0 = ct(); local t = @elapsed local r = $(esc(ex))
        @printf("  %-32s %6.2f s (compile %6.2f)\n", $label, t, ct() - c0); r
    end
end
for N in (16, 64)
    println("build of a fresh $N-loop model, step by step:")
    root = many(N)
    with(BUILD_WARNINGS => Diagnostic[]) do
        diags = Diagnostic[]
        draft = @tm "StructureDraft(root)" StructureDraft(root)
        @tm "flatten! (the walk)" flatten!(draft, root, diags)
        @tm "_check_event_declarations" _check_event_declarations(draft, diags)
        conns, in_faces = @tm "wire!" wire!(draft)
        root_types = @tm "_check_wires" _check_wires(draft, conns, diags)
        structure = @tm "Structure(...)" Structure(draft, conns, in_faces, root_types)
        outputs, events, nominal = @tm "_nominal (probes, order, layout)" _nominal(structure)
        @tm "Build(...)" Build(structure, outputs, events, Dict{DataType,Any}(Float64 => nominal), ReentrantLock(), Diagnostic[])
    end
end
