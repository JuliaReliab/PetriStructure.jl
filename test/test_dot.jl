@testset "dot" begin
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
