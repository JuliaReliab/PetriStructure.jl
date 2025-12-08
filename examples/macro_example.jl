"""
Macro Example for PetriStructure.jl

This example demonstrates the @petrinet macro for concise Petri net definition.
"""

using PetriStructure

println("=== @petrinet Macro Examples ===\n")

# Example 1: Simple two-place network
println("1. Simple Two-Place Network")
println("-" ^ 40)

pn1 = @petrinet begin
    p1[1, 5]
    p2[0, 5]
    exp(2.0): t1
    p1 => t1
    t1 => p2
end

println("Places: ", length(pn1.places))
println("Transitions: ", length(pn1.trans))
C = incidence(pn1)
println("Incidence matrix:")
println(C)
println()

# Example 2: Producer-Consumer with buffer
println("2. Producer-Consumer Model")
println("-" ^ 40)

pn2 = @petrinet begin
    buffer[0, 10]
    producer[1, 1]
    consumer[1, 1]
    
    exp(2.0): produce
    exp(1.0): consume
    
    producer => produce
    produce => buffer
    produce => producer
    buffer => consume
    consume => consumer
    consume => consumer
end

println("Places: ", length(pn2.places))
println("Transitions: ", length(pn2.trans))
C2 = incidence(pn2)
println("Incidence matrix:")
println(C2)
println()

# Example 3: Arc with multiplicity
println("3. Network with Arc Multiplicities")
println("-" ^ 40)

pn3 = @petrinet begin
    input[5, 10]
    output[0, 10]
    
    exp(1.0): process
    
    input => process[2]    # Consumes 2 tokens
    process => output[3]   # Produces 3 tokens
end

println("Places: ", length(pn3.places))
println("Transitions: ", length(pn3.trans))
C3 = incidence(pn3)
println("Incidence matrix:")
println(C3)
println("Initial marking: ", initial(pn3))
println()

# Example 4: Immediate and Exponential transitions
println("4. Mixed Transition Types")
println("-" ^ 40)

pn4 = @petrinet begin
    p1[1, 5]
    p2[0, 5]
    p3[0, 5]
    
    exp(1.5): t1
    imm(2.0): t2
    
    p1 => t1
    t1 => p2
    p2 => t2
    t2 => p3
end

println("Places: ", length(pn4.places))
println("Transitions: ", length(pn4.trans))
println("Transition types:")
for t in pn4.trans
    ttype = t isa PetriStructure.ExpTrans ? "Exponential" : "Immediate"
    param = t isa PetriStructure.ExpTrans ? "rate=$(t.rate)" : "weight=$(t.weight)"
    println("  $(t.label): $ttype ($param)")
end
println()

# Example 5: Cyclic network with P-invariant
println("5. Cyclic Network")
println("-" ^ 40)

pn5 = @petrinet begin
    p1[1, 3]
    p2[0, 3]
    p3[0, 3]
    
    exp(1.0): t1
    exp(1.0): t2
    exp(1.0): t3
    
    p1 => t1
    t1 => p2
    p2 => t2
    t2 => p3
    p3 => t3
    t3 => p1
end

C5 = incidence(pn5)
Pinv = pinvariant(C5)
println("Incidence matrix:")
println(C5)
println("P-invariants:")
println(Pinv)
println("Verification (C' * Pinv should be zero):")
println(C5' * Pinv)
println()

# Example 6: Guard conditions
println("6. Guard Conditions")
println("-" ^ 40)

pn6 = @petrinet begin
    stock[10, 20]
    warehouse[0, 100]
    
    exp(2.0): ship
    
    stock => ship[3]        # Ship 3 items at a time
    ship => warehouse[3]
    
    # Only ship if stock has at least 5 items
    guard(ship, [stock], stock >= 5)
end

println("Places: ", length(pn6.places))
println("Transitions: ", length(pn6.trans))
println("Guard functions: ", length(pn6.trans[1].guard))
println("Guard places: ", length(pn6.trans[1].guardplaces))

# Test guard condition
m1 = [10, 0]
m2 = [4, 0]
println("Can ship with 10 items? ", pn6.trans[1].guard[1](m1))
println("Can ship with 4 items? ", pn6.trans[1].guard[1](m2))
println()

# Example with multiple places in guard
println("Guard with multiple places:")
pn7 = @petrinet begin
    buffer1[5, 10]
    buffer2[3, 10]
    output[0, 20]
    exp(1.0): process
    buffer1 => process
    buffer2 => process
    process => output[2]
    # Process only if both buffers have enough items
    guard(process, [buffer1, buffer2], buffer1 >= 2 && buffer2 >= 2)
end

m_ok = [5, 3, 0]
m_ng1 = [1, 3, 0]
m_ng2 = [5, 1, 0]
println("Can process with buffer1=5, buffer2=3? ", pn7.trans[1].guard[1](m_ok))
println("Can process with buffer1=1, buffer2=3? ", pn7.trans[1].guard[1](m_ng1))
println("Can process with buffer1=5, buffer2=1? ", pn7.trans[1].guard[1](m_ng2))
println()

# Example 7: Export to DOT
println("7. DOT Export")
println("-" ^ 40)

dot_output = todot(pn2)
println("Generated DOT format (first 200 chars):")
println(dot_output[1:min(200, length(dot_output))])
println("...")
println()

println("=== Macro Examples Complete ===")
