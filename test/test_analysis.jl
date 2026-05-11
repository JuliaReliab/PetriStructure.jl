@testset "analysis" begin
    @testset "integer_kernel" begin
        # Single invariant [1,1]: null space is span{[1,-1]} or span{[-1,1]}
        J1 = reshape([1, 1], 1, 2)   # 1×2 (rows-as-invariants convention)
        K1 = integer_kernel(J1)
        @test size(K1, 1) == 2
        @test size(K1, 2) == 1
        @test J1 * K1 == zeros(Int, 1, 1)

        # Two invariants on 4 places: null space is 2-dimensional
        J2 = [1 1 0 0; 0 0 1 1]   # 2×4
        K2 = integer_kernel(J2)
        @test size(K2, 1) == 4
        @test size(K2, 2) == 2
        @test J2 * K2 == zeros(Int, 2, 2)

        # Empty invariant set: identity kernel (all of Z^m is free)
        J0 = zeros(Int, 0, 3)
        K0 = integer_kernel(J0)
        @test size(K0, 1) == 3
        @test size(K0, 2) == 3
    end

    @testset "lll_reduce" begin
        # Null vector: LLL should preserve the null-space property
        J = reshape([1, 1], 1, 2)
        K = integer_kernel(J)
        L = lll_reduce(K)
        @test size(L) == size(K)
        @test J * L == zeros(Int, 1, size(L, 2))

        # Empty basis: no-op
        K0 = zeros(Int, 3, 0)
        @test lll_reduce(K0) == K0
    end

    @testset "pinvariant_reduce" begin
        pn = petri()
        place(pn, "p1", 1, 1)
        place(pn, "p2", 0, 1)
        exptrans(pn, "t", 1.0)
        inarc(pn, "p1", "t")
        outarc(pn, "t", "p2")

        result = pinvariant_reduce(pn)

        @test result.x0 == [1, 0]
        @test result.rank_J == 1
        @test size(result.K) == (2, 1)

        # K must lie in the null space of the P-invariant constraint system
        J = pinvariant_basis(incidence(pn))   # 1×2 after fix
        @test J * result.K == zeros(Int, size(J, 1), size(result.K, 2))

        # [0, 1] is reachable as x0 + K*t for some integer t (sign-agnostic)
        k_col = result.K[:, 1]
        @test result.x0 + k_col == [0, 1] || result.x0 - k_col == [0, 1]

        # C-matrix overload produces the same result
        result2 = pinvariant_reduce(incidence(pn), initial(pn))
        @test result2.x0 == result.x0
        @test result2.rank_J == result.rank_J
        @test size(result2.K) == size(result.K)
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
