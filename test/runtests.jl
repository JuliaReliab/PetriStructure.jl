using PetriStructure
using Test
using Random

@testset "PetriStructure.jl" begin
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

    @testset "events and rewards" begin
        pn = petri()
        place(pn, "p1", 0, 1)
        tr1 = exptrans(pn, "t1", 1.0)
        tr2 = exptrans(pn, "t2", 3.0)

        reward(pn, m -> sum(m))
        @test length(pn.reward) == 1

        rng = Random.MersenneTwister(1)
        ev = createevents(pn, rng, 20)
        @test all(x -> x in (tr1.id, tr2.id), ev)
        count1 = count(==(tr1.id), ev)
        count2 = count(==(tr2.id), ev)
        @test count2 > count1
    end

    @testset "pinvariant" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 1)
        p2 = place(pn, "p2", 0, 1)
        tr = exptrans(pn, "t", 1.0)

        inarc(pn, "p1", "t"; mul = 1)
        outarc(pn, "t", "p2"; mul = 1)

        C = incidence(pn)
        inv = pinvariant(C)

        @test size(inv) == (2, 1)
        @test inv[:, 1] == [1, 1]
        @test C' * inv == zeros(Int, size(C, 2), size(inv, 2))
    end

    @testset "tinvariant" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 1)
        p2 = place(pn, "p2", 0, 1)
        t1 = exptrans(pn, "t1", 1.0)
        t2 = exptrans(pn, "t2", 1.0)

        inarc(pn, "p1", "t1"; mul = 1)
        outarc(pn, "t1", "p2"; mul = 1)
        inarc(pn, "p2", "t2"; mul = 1)
        outarc(pn, "t2", "p1"; mul = 1)

        C = incidence(pn)
        tinv = tinvariant(C)

        @test size(tinv, 1) == 2
        @test C * tinv == zeros(Int, size(C, 1), size(tinv, 2))
        
        # For this cycle, firing each transition once returns to initial state
        @test any(all(tinv[:, i] .== [1, 1]) for i in 1:size(tinv, 2))
    end

    @testset "todot" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 2)
        p2 = place(pn, "p2", 0, 2)
        tr = exptrans(pn, "t1", 1.0)
        inarc(pn, "p1", "t1"; mul = 1)
        outarc(pn, "t1", "p2"; mul = 2)

        dotstr = todot(pn)
        @test startswith(dotstr, "digraph {")
        @test occursin("p1", dotstr)
        @test occursin("p2", dotstr)
        @test occursin("t1", dotstr)
        @test occursin("[label=\"2\"]", dotstr)
    end

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

    @testset "@petrinet macro" begin
        # Test basic place and transition creation
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
        
        # Test with multiplicities
        pn2 = @petrinet begin
            p1[3, 10]
            p2[0, 10]
            exp(1.0): t1
            p1 => t1[2]
            t1 => p2[3]
        end
        
        C = incidence(pn2)
        @test C[1, 1] == -2  # Input arc with multiplicity 2
        @test C[2, 1] == 3   # Output arc with multiplicity 3
        
        # Test immediate transition
        pn3 = @petrinet begin
            p1[1, 5]
            p2[0, 5]
            imm(2.5): t1
            p1 => t1
            t1 => p2
        end
        
        @test pn3.trans[1] isa PetriStructure.ImmTrans
        @test pn3.trans[1].weight == 2.5
        
        # Test multiple transitions and arcs
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
        
        # Test with guard
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
        
        # Test guard condition
        marking = [5, 0]
        @test pn5.trans[1].guard[1](marking) == true
        marking = [2, 0]
        @test pn5.trans[1].guard[1](marking) == false
    end
end
