# PetriStructure.jl Examples

This directory contains example scripts demonstrating various features of the PetriStructure.jl package.

## Running the Examples

All examples can be run from the package root directory:

```bash
cd PetriStructure.jl
julia --project examples/<example_name>.jl
```

## Available Examples

### 1. simple_example.jl

A basic introduction to PetriStructure.jl covering:
- Creating places and transitions
- Connecting them with arcs
- Computing incidence matrices
- Finding P-invariants
- Enabling and firing transitions
- Exporting to DOT format

**Run:**
```bash
julia --project examples/simple_example.jl
```

### 2. dining_philosophers.jl

Implementation of the classical dining philosophers problem with 50 philosophers:
- Models philosophers cycling through idle → hungry → eating states
- Each philosopher requires two forks to eat
- Demonstrates deadlock-free resource allocation
- Computes and verifies P-invariants

**Run:**
```bash
julia --project examples/dining_philosophers.jl
```

### 3. pnml_example.jl

Shows how to load Petri nets from PNML format files:
- Loading from file path
- Loading from IO stream or string
- Inspecting loaded structure
- Computing P-invariants
- Exporting to DOT format

**Run:**
```bash
julia --project examples/pnml_example.jl
```

### 4. macro_example.jl

Demonstrates the `@petrinet` macro for concise Petri net definition:
- Declarative syntax for places and transitions
- Arc definitions with multiplicities
- Mixed exponential and immediate transitions
- P-invariant computation
- DOT export

**Run:**
```bash
julia --project examples/macro_example.jl
```

### 5. invariant_example.jl

Shows P-invariant and T-invariant analysis:
- Computing conservation laws (P-invariants)
- Finding cyclic firing sequences (T-invariants)
- Mathematical verification
- Interpretation of invariants

**Run:**
```bash
julia --project examples/invariant_example.jl
```

## Visualizing Petri Nets

Several examples generate DOT files that can be visualized using Graphviz:

```bash
# Install Graphviz (if not already installed)
# macOS: brew install graphviz
# Ubuntu: sudo apt-get install graphviz

# Convert DOT to PNG
dot -Tpng simple_example.dot -o simple_example.png

# Or use other formats
dot -Tsvg simple_example.dot -o simple_example.svg
dot -Tpdf simple_example.dot -o simple_example.pdf
```

## Key Concepts

### Places
- Represent states or resources in the system
- Have initial marking, minimum and maximum token capacity
- Created with `place(pn, label, initial, max; level=0)`

### Transitions
- Represent events or actions
- **Exponential transitions**: Timed with exponential distribution
- **Immediate transitions**: Fire instantly with priority weights
- Created with `exptrans(pn, label, rate)` or `immtrans(pn, label, weight)`

### Arcs
- Connect places to transitions (input arcs) or transitions to places (output arcs)
- Can have multiplicity for multiple tokens
- Created with `inarc(pn, place, trans)` or `outarc(pn, trans, place)`

### Analysis
- **Incidence Matrix**: `C = incidence(pn)` - structural analysis
- **P-invariants**: `M = pinvariant(C)` - conservation laws
- **T-invariants**: `M = tinvariant(C)` - cyclic firing sequences
- **Enable/Fire**: Check if transitions can fire and compute resulting marking

### File I/O
- Import from PNML: `load_pnml(filename)` or `load_pnml(io)`
- Export to DOT: `todot(pn)` for Graphviz visualization

## Further Reading

See the main package documentation for detailed API reference and theory.
