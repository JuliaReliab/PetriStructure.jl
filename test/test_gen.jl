@testset "GenTrans construction" begin
    pn = petri()
    p1 = place(pn, "p1", 1, 1)
    p2 = place(pn, "p2", 0, 1)
    g = gentrans(pn, "g1", detdist(2.0))

    @test g isa PetriStructure.GenTrans
    @test g.dist == DetDist(2.0)
    @test g.policy == :prd                       # default policy
    @test g in pn.trans
    @test g in pn.gentrans
    @test pn.labels["g1"] === g
    @test g.id == 1                              # shares the transition index space
end

@testset "GenTrans distributions and policy" begin
    pn = petri()
    a = gentrans(pn, "a", detdist(3))
    b = gentrans(pn, "b", unifdist(0, 1); policy = :prs)
    c = gentrans(pn, "c", expdist(0.5); policy = :pri)

    @test a.dist == DetDist(3.0)
    @test b.dist == UnifDist(0.0, 1.0)
    @test c.dist == ExpDist(0.5)
    @test b.policy == :prs
    @test c.policy == :pri
    @test length(pn.gentrans) == 3
    @test_throws ErrorException gentrans(pn, "bad", detdist(1.0); policy = :nope)
end

@testset "GenTrans participates in structure" begin
    # p1 --g--> p2 : the general transition behaves structurally like any other.
    pn = petri()
    p1 = place(pn, "p1", 1, 1)
    p2 = place(pn, "p2", 0, 1)
    g = gentrans(pn, "g", detdist(1.0))
    arc(pn, p1, g)
    arc(pn, g, p2)

    @test g.guard == GuardExpr[]
    @test enablefunc(pn, g)([1, 0]) == true      # p1 has a token
    @test enablefunc(pn, g)([0, 0]) == false     # p1 empty -> disabled
    @test firingfunc(pn, g)([1, 0]) == [0, 1]    # moves the token

    C = incidence(pn)                            # 2 places x 1 transition
    @test size(C) == (2, 1)
    @test C[p1.id, g.id] == -1
    @test C[p2.id, g.id] == 1
end

@testset "GenTrans with guard" begin
    pn = petri()
    p1 = place(pn, "p1", 2, 2)
    g = gentrans(pn, "g", expdist(1.0))
    arc(pn, p1, g)
    guard(g, GuardGeq(p1.id, 2), [p1])

    @test enablefunc(pn, g)([2]) == true
    @test enablefunc(pn, g)([1]) == false        # arc satisfied but guard fails
end

@testset "GenTrans in @petrinet macro" begin
    pn = @petrinet begin
        p1[1, 1]
        p2[0, 1]
        gen(detdist(2.0)): g1
        gen(unifdist(0.0, 1.0), :prs): g2
        p1 => g1
        g1 => p2
    end

    @test length(pn.gentrans) == 2
    g1 = pn.labels["g1"]
    g2 = pn.labels["g2"]
    @test g1.dist == DetDist(2.0)
    @test g1.policy == :prd
    @test g2.dist == UnifDist(0.0, 1.0)
    @test g2.policy == :prs
end

@testset "GenTrans DOT export" begin
    pn = petri()
    p1 = place(pn, "p1", 1, 1)
    g = gentrans(pn, "g", detdist(1.0))
    arc(pn, p1, g)
    dot = todot(pn)
    @test occursin("\"g\"", dot) || occursin("label=\"g\"", dot)
    @test occursin("fillcolor=lightgray", dot)   # the GEN-specific style
end
