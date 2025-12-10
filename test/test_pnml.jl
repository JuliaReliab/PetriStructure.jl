@testset "load_pnml" begin
    pnml_file = joinpath(@__DIR__, "test.pnml")
    pn = load_pnml(pnml_file)

    @test length(pn.places) == 40
    @test length(pn.trans) == 30

    @test pn.labels["P0"].initial == 1
    @test pn.labels["P1"].initial == 0
    @test maximum(pn.labels["P0"].domains) == 1

    @test pn.labels["T0"] isa PetriStructure.ExpTrans
    @test pn.labels["T0"].rate ≈ 1.9225350492273154

    init_marking = initial(pn)
    @test sum(init_marking) == 20

    io = IOBuffer(read(pnml_file))
    pn2 = load_pnml(io)
    @test length(pn2.places) == 40
    @test length(pn2.trans) == 30
    @test initial(pn2) == initial(pn)
end
