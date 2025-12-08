using Test

include("../src/well1024a.jl")

@testset "WELL1024a" begin
    @testset "Basic construction" begin
        rng = WELL1024a(123456789)
        @test rng isa WELL1024a
        @test length(rng.state) == 32
        @test rng.state_i == 1
    end
    
    @testset "Random number generation" begin
        rng = WELL1024a(123456789)
        
        # Generate some random numbers
        x1 = rand(rng)
        x2 = rand(rng)
        x3 = rand(rng)
        
        # Check they are in [0, 1)
        @test 0.0 <= x1 < 1.0
        @test 0.0 <= x2 < 1.0
        @test 0.0 <= x3 < 1.0
        
        # Check they are different
        @test x1 != x2
        @test x2 != x3
        @test x1 != x3
    end
    
    @testset "Reproducibility" begin
        rng1 = WELL1024a(42)
        rng2 = WELL1024a(42)
        
        # Same seed should produce same sequence
        seq1 = [rand(rng1) for _ in 1:100]
        seq2 = [rand(rng2) for _ in 1:100]
        
        @test seq1 == seq2
    end
    
    @testset "Different seeds" begin
        rng1 = WELL1024a(123)
        rng2 = WELL1024a(456)
        
        # Different seeds should produce different sequences
        seq1 = [rand(rng1) for _ in 1:10]
        seq2 = [rand(rng2) for _ in 1:10]
        
        @test seq1 != seq2
    end
    
    @testset "Array initialization" begin
        init = rand(UInt32, 32)
        rng = WELL1024a(init)
        
        @test rng.state == init
        @test rand(rng) isa Float64
    end
    
    @testset "Long sequence" begin
        rng = WELL1024a(1)
        
        # Generate a long sequence to test state cycling
        for _ in 1:1000
            x = rand(rng)
            @test 0.0 <= x < 1.0
        end
    end
    
    @testset "Type specification" begin
        rng = WELL1024a(999)
        
        x = rand(rng, Float64)
        @test x isa Float64
        @test 0.0 <= x < 1.0
    end
end

println("\nSample output from WELL1024a(123456789):")
rng = WELL1024a(123456789)
for i in 1:10
    println("  ", rand(rng))
end
