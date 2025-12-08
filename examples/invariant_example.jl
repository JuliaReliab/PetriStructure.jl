"""
Invariant Analysis Example

Demonstrates P-invariants and T-invariants computation and verification.
"""

using PetriStructure

println("=== Invariant Analysis Example ===\n")

# Example 1: Simple cycle (P-invariant and T-invariant)
println("1. Simple Cycle Network")
println("-" ^ 40)

pn = petri()
p1 = place(pn, "p1", 1, 1)
p2 = place(pn, "p2", 0, 1)
t1 = exptrans(pn, "t1", 1.0)
t2 = exptrans(pn, "t2", 1.0)

inarc(pn, "p1", "t1")
outarc(pn, "t1", "p2")
inarc(pn, "p2", "t2")
outarc(pn, "t2", "p1")

C = incidence(pn)
println("Incidence matrix C:")
display(C)
println("\n")

# P-invariants
pinv = pinvariant(C)
println("P-invariants (columns of matrix):")
display(pinv)
println("\nVerification C' * P-inv = 0:")
display(C' * pinv)
println("\n")

# T-invariants
tinv = tinvariant(C)
println("T-invariants (columns of matrix):")
display(tinv)
println("\nVerification C * T-inv = 0:")
display(C * tinv)
println("\n")

# Interpretation
println("Interpretation:")
println("  P-invariant [1, 1]: Total tokens in (p1 + p2) is conserved")
println("  T-invariant [1, 1]: Firing t1 once and t2 once returns to initial state")
println()

# Example 2: Producer-Consumer with buffer
println("2. Producer-Consumer with Buffer")
println("-" ^ 40)

pn2 = petri()
idle = place(pn2, "idle", 1, 1)
buffer = place(pn2, "buffer", 0, 5)
produce = exptrans(pn2, "produce", 2.0)
consume = exptrans(pn2, "consume", 1.0)

inarc(pn2, "idle", "produce")
outarc(pn2, "produce", "buffer")
outarc(pn2, "produce", "idle")
inarc(pn2, "buffer", "consume")

C2 = incidence(pn2)
println("Incidence matrix C:")
display(C2)
println("\n")

pinv2 = pinvariant(C2)
println("P-invariants:")
display(pinv2)
println("\nVerification C' * P-inv = 0:")
display(C2' * pinv2)
println("\n")

tinv2 = tinvariant(C2)
println("T-invariants:")
display(tinv2)
println("\nVerification C * T-inv = 0:")
display(C2 * tinv2)
println("\n")

println("Interpretation:")
println("  P-invariant shows token conservation")
println("  T-invariant shows that produce and consume must balance")
println()

# Example 3: Dining philosophers (subset)
println("3. Dining Philosophers (3 philosophers)")
println("-" ^ 40)

pn3 = petri()
n = 3

# Create structure for 3 philosophers
for i = 0:n-1
    place(pn3, "idle$i", 1, 1)
    place(pn3, "hungry$i", 0, 1)
    place(pn3, "eat$i", 0, 1)
    place(pn3, "fork$i", 1, 1)
    exptrans(pn3, "ih$i", 1.0)  # idle -> hungry
    exptrans(pn3, "he$i", 1.0)  # hungry -> eat
    exptrans(pn3, "ei$i", 1.0)  # eat -> idle
end

for i = 0:n-1
    next_fork = (i+1) % n
    # idle -> hungry
    inarc(pn3, "idle$i", "ih$i")
    outarc(pn3, "ih$i", "hungry$i")
    # hungry -> eat (need two forks)
    inarc(pn3, "hungry$i", "he$i")
    inarc(pn3, "fork$i", "he$i")
    inarc(pn3, "fork$next_fork", "he$i")
    outarc(pn3, "he$i", "eat$i")
    # eat -> idle (release forks)
    inarc(pn3, "eat$i", "ei$i")
    outarc(pn3, "ei$i", "idle$i")
    outarc(pn3, "ei$i", "fork$i")
    outarc(pn3, "ei$i", "fork$next_fork")
end

C3 = incidence(pn3)
println("Network size:")
println("  Places: $(size(C3, 1))")
println("  Transitions: $(size(C3, 2))")
println("  Non-zero entries in C: $(count(!=(0), C3))")
println()

println("Computing P-invariants...")
pinv3 = pinvariant(C3)
println("  Number of P-invariants: $(size(pinv3, 2))")
println("  Verification: max|C' * P-inv| = $(maximum(abs.(C3' * pinv3)))")
println()

println("Computing T-invariants...")
tinv3 = tinvariant(C3)
println("  Number of T-invariants: $(size(tinv3, 2))")
println("  Verification: max|C * T-inv| = $(maximum(abs.(C3 * tinv3)))")
println()

# Show a T-invariant
if size(tinv3, 2) > 0
    println("Example T-invariant (first column):")
    for i in 1:length(pn3.trans)
        if tinv3[i, 1] != 0
            println("  $(pn3.trans[i].label): $(tinv3[i, 1])")
        end
    end
    println("\nThis represents a feasible firing sequence returning to initial state")
end
println()

# Summary
println("=== Summary ===")
println("P-invariants represent:")
println("  - Conservation laws (tokens that remain constant)")
println("  - Structural properties independent of initial marking")
println()
println("T-invariants represent:")
println("  - Feasible firing sequences returning to initial state")
println("  - Repeatability and cyclic behavior")
println("  - Liveness and boundedness properties")
