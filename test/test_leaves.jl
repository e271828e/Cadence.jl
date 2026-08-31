# --- the leaf walk (§7.1, §7.2) -----------------------------------------------
# The closed value vocabulary — real scalars, static arrays, isbits structs of
# the same — walked to retype a declaration at the activation scalar. A leaf
# whose type is not `Float64` does not follow it, which is what the pins and the
# mixed cells in `test_store.jl` are laid out around.

function test_leaves()
    @testset "the activation walk (§7.2)" begin
        @test retype(D8, Float64) === D8
        @test retype(D8, SVector{3,Float64}) === SVector{3,D8}
        @test retype(D8, Int) === Int
        @test retype(Float64, SVector{2,Float64}) === SVector{2,Float64}
        @test retype_value(D8, (q = SVector(1.0, 2.0),)).q isa SVector{2,D8}
    end
end
