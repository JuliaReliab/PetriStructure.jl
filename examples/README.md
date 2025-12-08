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
- Generating random events
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

### 3. well1024a_example.jl

Demonstrates the WELL1024a random number generator:
- Basic random number generation
- Reproducibility with seeds
- Statistical properties verification
- Integration with PetriNet event generation
- Performance comparison with MersenneTwister

**Run:**
```bash
julia --project examples/well1024a_example.jl
```

### 4. pnml_example.jl

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
- **Enable/Fire**: Check if transitions can fire and compute resulting marking

### Random Number Generation
- Built-in WELL1024a generator for high-quality random numbers
- Compatible with Julia's Random interface
- Use with `createevents(pn, rng, n)` for event generation

### File I/O
- Import from PNML: `load_pnml(filename)` or `load_pnml(io)`
- Export to DOT: `todot(pn)` for Graphviz visualization

## Further Reading

See the main package documentation for detailed API reference and theory.
