@testset "analysis" begin
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

    @testset "pinvariant_basis" begin
        pn = petri()
        p1 = place(pn, "p1", 1, 1)
        p2 = place(pn, "p2", 0, 1)
        tr = exptrans(pn, "t", 1.0)

        inarc(pn, "p1", "t"; mul = 1)
        outarc(pn, "t", "p2"; mul = 1)

        C = incidence(pn)
        inv = pinvariant_basis(C)

        @test size(inv) == (1, 2)
        @test C' * inv' == zeros(Int, size(C, 2), size(inv, 1))
        @test inv[1, :] == [1, 1] || inv[1, :] == [-1, -1]
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
        @test any(all(tinv[:, i] .== [1, 1]) for i in 1:size(tinv, 2))
    end
end
