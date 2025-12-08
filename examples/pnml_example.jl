"""
PNML File Loading Example

This example demonstrates how to load Petri nets from PNML format files.
"""

using PetriStructure

println("=== PNML File Loading Example ===\n")

# Load from file
pnml_file = joinpath(@__DIR__, "..", "test", "test.pnml")

if isfile(pnml_file)
    println("1. Loading PNML from file: $pnml_file")
    pn = load_pnml(pnml_file)
    
    println("Successfully loaded Petri net:")
    println("  Number of places: ", length(pn.places))
    println("  Number of transitions: ", length(pn.trans))
    println("  Number of exponential transitions: ", length(pn.exptrans))
    println()
    
    # Display place information
    println("2. Place information (first 5):")
    for i in 1:min(5, length(pn.places))
        p = pn.places[i]
        println("  $(p.label): initial=$(p.initial), level=$(p.level), domain=$(first(p.domains)):$(last(p.domains))")
    end
    println()
    
    # Display transition information
    println("3. Transition information (first 5):")
    for i in 1:min(5, length(pn.trans))
        t = pn.trans[i]
        if t isa PetriNet.ExpTrans
            println("  $(t.label): ExpTrans, rate=$(t.rate)")
        else
            println("  $(t.label): ImmTrans, weight=$(t.weight)")
        end
    end
    println()
    
    # Initial marking
    m0 = initial(pn)
    println("4. Initial marking:")
    println("  Total tokens: ", sum(m0))
    println("  First 10 places: ", m0[1:min(10, length(m0))])
    println()
    
    # Incidence matrix
    C = incidence(pn)
    println("5. Incidence matrix:")
    println("  Size: ", size(C))
    println("  Non-zero entries: ", count(!=(0), C))
    println()
    
    # P-invariants
    println("6. Computing P-invariants...")
    M = pinvariant(C)
    println("  P-invariant matrix size: ", size(M))
    println("  Number of P-invariants: ", size(M, 2))
    
    # Verify
    verification = C' * M
    max_error = maximum(abs.(verification))
    println("  Verification (max |C' * M|): ", max_error)
    println("  P-invariants are ", max_error == 0 ? "valid ✓" : "invalid ✗")
    println()
    
else
    println("Test PNML file not found: $pnml_file")
    println("Please run the tests first to generate the test PNML file.")
    println()
end

# Load from IO (string)
println("7. Loading PNML from IO (string example):")

pnml_string = """<?xml version="1.0" encoding="UTF-8"?>
<pnml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <net id="SimpleNet" type="P/T net">
        <place id="P0">
            <initialMarking><value>1</value></initialMarking>
            <ddOrder><value>0</value></ddOrder>
            <bound><value>2</value></bound>
        </place>
        <place id="P1">
            <initialMarking><value>0</value></initialMarking>
            <ddOrder><value>1</value></ddOrder>
            <bound><value>2</value></bound>
        </place>
        <transition id="T0">
            <rate><value>1.5</value></rate>
            <timed><value>true</value></timed>
        </transition>
        <arc id="A0" source="P0" target="T0">
            <inscription><value>1</value></inscription>
        </arc>
        <arc id="A1" source="T0" target="P1">
            <inscription><value>1</value></inscription>
        </arc>
    </net>
</pnml>
"""

io = IOBuffer(pnml_string)
pn_from_string = load_pnml(io)

println("Successfully loaded from string:")
println("  Places: ", length(pn_from_string.places))
println("  Transitions: ", length(pn_from_string.trans))
println("  Initial marking: ", initial(pn_from_string))
println()

# Export to DOT
if isfile(pnml_file)
    println("8. Exporting loaded net to DOT format:")
    dot_output = todot(pn)
    
    output_file = "loaded_pnml.dot"
    open(output_file, "w") do f
        write(f, dot_output)
    end
    
    println("  DOT file saved as: $output_file")
    println("  Visualize with: dot -Tpng $output_file -o loaded_pnml.png")
end
