"""
Simple Petri Net Example

This example demonstrates basic usage of the PetriStructure package:
- Creating places and transitions
- Connecting them with arcs
- Computing incidence matrix and P-invariants
- Generating random events
"""

using PetriStructure
using Random

# Create a simple Petri net
pn = petri()

# Add places
p1 = place(pn, "p1", 2, 5)    # initial=2, max=5
p2 = place(pn, "p2", 0, 3)    # initial=0, max=3
p3 = place(pn, "p3", 1, 2)    # initial=1, max=2

# Add transitions
t1 = exptrans(pn, "t1", 1.5)  # exponential with rate 1.5
t2 = exptrans(pn, "t2", 2.0)  # exponential with rate 2.0

# Connect with arcs
inarc(pn, "p1", "t1"; mul = 1)   # p1 -> t1
outarc(pn, "t1", "p2"; mul = 1)  # t1 -> p2

inarc(pn, "p2", "t2"; mul = 1)   # p2 -> t2
inarc(pn, "p3", "t2"; mul = 1)   # p3 -> t2
outarc(pn, "t2", "p1"; mul = 1)  # t2 -> p1
outarc(pn, "t2", "p3"; mul = 1)  # t2 -> p3

println("=== Petri Net Structure ===")
println("Places: ", length(pn.places))
println("Transitions: ", length(pn.trans))
println()

# Initial marking
m0 = initial(pn)
println("Initial marking: ", m0)
println("Maximum marking: ", maxmark(pn))
println("Minimum marking: ", minmark(pn))
println()

# Place domains
println("Place domains:")
for p in pn.places
    println("  $(p.label): $(domain(p))")
end
println()

# Incidence matrix
C = incidence(pn)
println("Incidence matrix C:")
display(C)
println("\n")

# P-invariants
M = pinvariant(C)
println("P-invariant matrix M:")
display(M)
println("\n")

# Verify P-invariants
println("Verification C' * M (should be zero):")
display(C' * M)
println("\n")

# Test firing
println("=== Transition Firing ===")
m = copy(m0)
println("Current marking: ", m)

enabled1 = enablefunc(pn, t1)
fire1 = firingfunc(pn, t1)

if enabled1(m)
    println("t1 is enabled")
    m = fire1(m)
    println("After firing t1: ", m)
else
    println("t1 is not enabled")
end
println()

# Export to DOT format
println("=== DOT Format Export ===")
dot_string = todot(pn)
println("First 200 characters of DOT output:")
println(dot_string[1:min(200, length(dot_string))])
println("...")
println()

# Save to file
open("simple_example.dot", "w") do io
    write(io, dot_string)
end
println("DOT file saved as: simple_example.dot")
println("Visualize with: dot -Tpng simple_example.dot -o simple_example.png")
