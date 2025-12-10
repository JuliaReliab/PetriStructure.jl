@testset "structure" begin
    @testset "places and domains" begin
        pn = petri()
        @test pn.labels == Dict()

        p1 = place(pn, "p1", 2, 3)
        p2 = place(pn, "p2", 0, 1)

        @test length(pn.places) == 2
        @test pn.labels["p1"] === p1
        @test initial(pn) == [2, 0]
        @test maxmark(pn) == [3, 1]
        @test minmark(pn) == [0, 0]
        @test domain(p1) == collect(0:3)
        @test domain(p2) == collect(0:1)
    end

    @testset "transitions and arcs" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 2)
        p2 = place(pn, "p2", 0, 2)
        tr = exptrans(pn, "t1", 1.5)
        tr2 = immtrans(pn, "t2", 2.0)

        @test length(pn.trans) == 2
        @test length(pn.exptrans) == 1
        @test length(pn.immtrans) == 1
        @test pn.exptrans[1] === tr
        @test pn.immtrans[1] === tr2

        inarc(pn, "p1", "t1"; mul = 1)
        outarc(pn, "t1", "p2"; mul = 1)

        @test length(tr.inarcs) == 1
        @test length(tr.outarcs) == 1
        @test PetriStructure.inputplaces(pn, tr) == [p1]
        @test PetriStructure.outputplaces(pn, tr) == [p2]
        @test PetriStructure.outputtrans(pn, p1) == [tr]
        @test PetriStructure.inputtrans(pn, p2) == [tr]
    end

    @testset "enable and firing" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 2)
        p2 = place(pn, "p2", 0, 2)
        tr = exptrans(pn, "t1", 1.0)

        inarc(pn, "p1", "t1"; mul = 1)
        outarc(pn, "t1", "p2"; mul = 1)
        guard(tr, m -> m[1] > 0, (p1,))

        enabled = enablefunc(pn, tr)
        fire = firingfunc(pn, tr)

        @test enabled([1, 0]) === true
        @test enabled([0, 0]) === false
        @test fire([1, 0]) == [0, 1]
        @test next(pn, tr, [1, 0]) == [0, 1]
        @test next(pn, tr, [0, 0]) == [0, 0]
    end
end
