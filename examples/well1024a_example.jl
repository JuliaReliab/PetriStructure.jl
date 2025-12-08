"""
WELL1024a Random Number Generator Example

This example demonstrates the usage of the WELL1024a random number generator
with PetriStructure event generation.
"""

using PetriStructure
using Random

println("=== WELL1024a Random Number Generator ===\n")

# Create WELL1024a RNG with a seed
seed = 123456789
rng = WELL1024a(seed)

println("1. Basic random number generation:")
println("Generating 10 random numbers with seed=$seed")
for i in 1:10
    println("  $i: ", rand(rng))
end
println()

# Reproducibility test
println("2. Reproducibility test:")
rng1 = WELL1024a(42)
rng2 = WELL1024a(42)

seq1 = [rand(rng1) for _ in 1:5]
seq2 = [rand(rng2) for _ in 1:5]

println("Sequence 1 (seed=42): ", seq1)
println("Sequence 2 (seed=42): ", seq2)
println("Sequences match: ", seq1 == seq2)
println()

# Compare with Julia's default RNG
println("3. Comparison with Julia's default RNG:")
well_rng = WELL1024a(999)
julia_rng = Random.MersenneTwister(999)

println("WELL1024a samples: ", [rand(well_rng) for _ in 1:5])
println("MersenneTwister samples: ", [rand(julia_rng) for _ in 1:5])
println("(Different algorithms produce different sequences)")
println()

# Statistical test
println("4. Basic statistical properties:")
well_rng = WELL1024a(111)
n_samples = 100000
samples = [rand(well_rng) for _ in 1:n_samples]

mean_val = sum(samples) / n_samples
variance = sum((x - mean_val)^2 for x in samples) / (n_samples - 1)

println("Number of samples: ", n_samples)
println("Mean (expected ≈ 0.5): ", mean_val)
println("Variance (expected ≈ 0.0833): ", variance)
println("Min value: ", minimum(samples))
println("Max value: ", maximum(samples))
println()

# Use with PetriNet
println("5. Using WELL1024a with PetriNet:")
pn = petri()
place(pn, "p1", 1, 1)
place(pn, "p2", 0, 1)
t1 = exptrans(pn, "t1", 1.0)
t2 = exptrans(pn, "t2", 2.0)

inarc(pn, "p1", "t1")
outarc(pn, "t1", "p2")
inarc(pn, "p2", "t2")
outarc(pn, "t2", "p1")

# Generate events with WELL1024a
well_rng = WELL1024a(555)
events_well = createevents(pn, well_rng, 1000)

# Generate events with MersenneTwister
mt_rng = Random.MersenneTwister(555)
events_mt = createevents(pn, mt_rng, 1000)

count_t1_well = count(==(t1.id), events_well)
count_t2_well = count(==(t2.id), events_well)
count_t1_mt = count(==(t1.id), events_mt)
count_t2_mt = count(==(t2.id), events_mt)

println("Generated 1000 events with each RNG:")
println("WELL1024a - t1: $count_t1_well, t2: $count_t2_well, ratio: ", 
        round(count_t2_well/count_t1_well, digits=3))
println("MersenneTwister - t1: $count_t1_mt, t2: $count_t2_mt, ratio: ",
        round(count_t2_mt/count_t1_mt, digits=3))
println("Expected ratio (rate t2/t1 = 2.0/1.0): 2.0")
println()

# Performance comparison
println("6. Performance comparison:")
println("Generating 1,000,000 random numbers...")

well_rng = WELL1024a(777)
@time for _ in 1:1_000_000
    rand(well_rng)
end

mt_rng = Random.MersenneTwister(777)
@time for _ in 1:1_000_000
    rand(mt_rng)
end
