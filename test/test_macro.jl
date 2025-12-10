@testset "@petrinet macro" begin
    pn = @petrinet begin
        p1[1, 5]
        p2[0, 5]
        exp(2.0): t1
        p1 => t1
        t1 => p2
    end

    @test length(pn.places) == 2
    @test length(pn.trans) == 1
    @test initial(pn) == [1, 0]
    @test pn.trans[1] isa PetriStructure.ExpTrans
    @test pn.trans[1].rate == 2.0

    pn2 = @petrinet begin
        p1[3, 10]
        p2[0, 10]
        exp(1.0): t1
        p1 => t1[2]
        t1 => p2[3]
    end

    C = incidence(pn2)
    @test C[1, 1] == -2
    @test C[2, 1] == 3

    pn3 = @petrinet begin
        p1[1, 5]
        p2[0, 5]
        imm(2.5): t1
        p1 => t1
        t1 => p2
    end

    @test pn3.trans[1] isa PetriStructure.ImmTrans
    @test pn3.trans[1].weight == 2.5

    pn4 = @petrinet begin
        p1[1, 3]
        p2[0, 3]
        p3[0, 3]
        exp(1.0): t1
        exp(2.0): t2
        p1 => t1
        t1 => p2
        p2 => t2
        t2 => p3
    end

    @test length(pn4.places) == 3
    @test length(pn4.trans) == 2
    @test initial(pn4) == [1, 0, 0]

    pn5 = @petrinet begin
        p1[5, 10]
        p2[0, 10]
        exp(1.0): t1
        p1 => t1
        t1 => p2
        guard(t1, [p1], p1 >= 3)
    end

    @test length(pn5.trans) == 1
    @test length(pn5.trans[1].guard) == 1
    @test length(pn5.trans[1].guardplaces) == 1

    marking = [5, 0]
    @test pn5.trans[1].guard[1](marking) == true
    marking = [2, 0]
    @test pn5.trans[1].guard[1](marking) == false
end
