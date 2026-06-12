using PetriStructure
using Test

@testset "PetriStructure.jl" begin
    include("test_structure.jl")
    include("test_gen.jl")
    include("test_analysis.jl")
    include("test_dot.jl")
    include("test_pnml.jl")
    include("test_macro.jl")
end
