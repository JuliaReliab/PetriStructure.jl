"""
Dining Philosophers Problem

This example models the classical dining philosophers problem using a Petri net.
Each philosopher cycles through three states: idle, hungry, and eating.
Each philosopher needs two forks (their own and the next one) to eat.
"""

using PetriStructure

# Create Petri net
pn = petri()
maxplace = 1
n = 50

# Create places and transitions for each philosopher
for i = 0:n-1
    Pidle = "Pidle$i"
    Phungry = "Phungry$i"
    Peat = "Peat$i"
    Pfork = "Pfork$i"
    Tidle2hungry = "Tih$i"
    Thungry2eat = "The$i"
    Teat2fork = "Tef$i"
    
    # Places
    place(pn, Pidle, maxplace, maxplace)
    place(pn, Phungry, 0, maxplace)
    place(pn, Peat, 0, maxplace)
    place(pn, Pfork, maxplace, maxplace)
    
    # Transitions
    exptrans(pn, Tidle2hungry, 1.0)
    exptrans(pn, Thungry2eat, 1.0)
    exptrans(pn, Teat2fork, 1.0)
end

# Connect places and transitions with arcs
for i = 0:n-1
    Pidle = "Pidle$i"
    Phungry = "Phungry$i"
    Peat = "Peat$i"
    Pfork = "Pfork$i"
    Pnextfork = "Pfork$((i+1)%n)"
    Tidle2hungry = "Tih$i"
    Thungry2eat = "The$i"
    Teat2fork = "Tef$i"
    
    # Idle to hungry transition
    inarc(pn, Pidle, Tidle2hungry)
    outarc(pn, Tidle2hungry, Phungry)
    
    # Hungry to eat transition (needs two forks)
    inarc(pn, Phungry, Thungry2eat)
    inarc(pn, Pfork, Thungry2eat)
    inarc(pn, Pnextfork, Thungry2eat)
    outarc(pn, Thungry2eat, Peat)
    
    # Eat to fork transition (release forks)
    inarc(pn, Peat, Teat2fork)
    outarc(pn, Teat2fork, Pidle)
    outarc(pn, Teat2fork, Pfork)
    outarc(pn, Teat2fork, Pnextfork)
end

println("Petri net created with:")
println("  Places: ", length(pn.places))
println("  Transitions: ", length(pn.trans))
println()

# Calculate incidence matrix and P-invariants
C = incidence(pn)
println("Incidence matrix size: ", size(C))

M = pinvariant(C)
println("P-invariant matrix size: ", size(M))
println("Number of P-invariants: ", size(M, 2))
println()

# Verify P-invariants
println("Verifying P-invariants (C' * M should be zero):")
result = C' * M
println("Maximum absolute value in C' * M: ", maximum(abs.(result)))
println()

# Calculate P-invariant basis using Smith Normal Form
println("Computing P-invariant basis using Smith Normal Form:")
Mbasis = pinvariant_basis(C)
println("P-invariant basis size: ", size(Mbasis))
println("Number of basis vectors: ", size(Mbasis, 2))
println()

# Verify P-invariant basis
println("Verifying P-invariant basis (C' * Mbasis should be zero):")
result_basis = C' * Mbasis
println("Maximum absolute value in C' * Mbasis: ", maximum(abs.(result_basis)))
println()

# Display initial marking
m0 = initial(pn)
println("Initial marking total: ", sum(m0))
println("Expected total (philosophers + forks): ", 2 * n)
