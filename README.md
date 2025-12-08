# PetriStructure.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://okamumu.github.io/PetriStructure.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://okamumu.github.io/PetriStructure.jl/dev/)
[![Build Status](https://github.com/okamumu/PetriStructure.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/okamumu/PetriStructure.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/okamumu/PetriStructure.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/okamumu/PetriStructure.jl)

A Julia package for modeling and analyzing Petri nets, including Generalized Stochastic Petri Nets (GSPNs).

## Features

- **Petri Net Construction**: Create places, transitions, and arcs with intuitive API
- **Transition Types**:
  - Exponential (timed) transitions with configurable rates
  - Immediate transitions with priority weights
- **Analysis Tools**:
  - Incidence matrix computation
  - P-invariant and T-invariant calculation
  - Marking analysis (initial, minimum, maximum)
- **PNML Support**: Load Petri nets from PNML format files
- **Visualization**: Export to Graphviz DOT format
- **Random Number Generation**: Built-in WELL1024a generator
- **Event Generation**: Generate stochastic event sequences

## Important Notes

⚠️ **This package does NOT generate marking graphs (reachability graphs).** 

The package focuses on:
- Structural analysis (incidence matrices, invariants)
- Stochastic simulation and event generation
- Model construction and visualization

For reachability analysis and state space exploration, please use specialized tools designed for that purpose.

## Installation

```julia
using Pkg
Pkg.add("PetriStructure")
```

Or from the Julia REPL package mode:
```julia
] add PetriStructure
```

## Quick Start

```julia
using PetriStructure

# Create a Petri net
pn = petri()

# Add places with (label, initial_marking, max_capacity)
p1 = place(pn, "p1", 2, 5)
p2 = place(pn, "p2", 0, 3)

# Add exponential transition with rate
t1 = exptrans(pn, "t1", 1.5)

# Connect with arcs
inarc(pn, "p1", "t1"; mul = 1)    # Input arc from p1 to t1
outarc(pn, "t1", "p2"; mul = 1)   # Output arc from t1 to p2

# Get initial marking
m0 = initial(pn)  # [2, 0]

# Compute incidence matrix
C = incidence(pn)

# Find P-invariants (conservation laws)
Pinv = pinvariant(C)

# Find T-invariants (cyclic sequences)
Tinv = tinvariant(C)

# Export to DOT format
dot_string = todot(pn)
```

### Using the `@petrinet` Macro

The `@petrinet` macro provides a concise syntax for defining Petri nets:

```julia
using PetriStructure

# Define a simple producer-consumer model
pn = @petrinet begin
    # Places: name[initial_marking, max_marking]
    buffer[0, 10]
    producer[1, 1]
    consumer[1, 1]
    
    # Transitions: exp(rate): name or imm(weight): name
    exp(2.0): produce
    exp(1.0): consume
    
    # Arcs: source => destination [multiplicity]
    producer => produce
    produce => buffer
    produce => producer
    buffer => consume
    consume => consumer
    consume => consumer
end

# Arc multiplicities
pn2 = @petrinet begin
    input[5, 10]
    output[0, 10]
    exp(1.0): process
    input => process[2]    # Consumes 2 tokens
    process => output[3]   # Produces 3 tokens
end

# With guard conditions (use place names directly)
pn3 = @petrinet begin
    stock[10, 20]
    warehouse[0, 100]
    exp(2.0): ship
    stock => ship[3]
    ship => warehouse[3]
    # Only fire if stock >= 5
    guard(ship, m -> m.stock >= 5, [stock])
end
```

## Examples

### Simple Producer-Consumer

```julia
using PetriStructure

pn = petri()

# Places
buffer = place(pn, "buffer", 0, 10)
ready = place(pn, "ready", 1, 1)

# Transitions
produce = exptrans(pn, "produce", 2.0)  # rate = 2.0
consume = exptrans(pn, "consume", 1.0)  # rate = 1.0

# Producer cycle
inarc(pn, "ready", "produce")
outarc(pn, "produce", "buffer")
outarc(pn, "produce", "ready")

# Consumer
inarc(pn, "buffer", "consume")

# Generate random events
using Random
rng = Random.MersenneTwister(42)
events = createevents(pn, rng, 100)
```

### Loading from PNML

```julia
using PetriStructure

# Load from file
pn = load_pnml("model.pnml")

# Or from IO stream
io = IOBuffer(pnml_string)
pn = load_pnml(io)

println("Places: ", length(pn.places))
println("Transitions: ", length(pn.trans))
```

### Using WELL1024a Random Generator

```julia
using PetriStructure

# Create RNG with seed
rng = WELL1024a(123456789)

# Generate random numbers
x = rand(rng)  # Single Float64 in [0, 1)

# Use with Petri net events
events = createevents(pn, rng, 1000)
```

## API Reference

### Petri Net Construction

#### Macro Syntax

- `@petrinet begin ... end` - Declarative Petri net definition

```julia
@petrinet begin
    place_name[initial, max]           # Define place
    exp(rate): trans_name              # Exponential transition
    imm(weight): trans_name            # Immediate transition
    source => destination              # Arc (multiplicity 1)
    source => destination[mult]        # Arc with multiplicity
    guard(trans, func, [places...])    # Guard condition (use m.place_name)
end

# Guard examples:
guard(t1, m -> m.p1 >= 5, [p1])                      # Single place
guard(t2, m -> m.p1 + m.p2 >= 10, [p1, p2])          # Multiple places
guard(t3, m -> m.stock >= 3 && m.buffer < 10, [stock, buffer])  # Complex condition
```

#### Functional API

- `petri()` - Create empty Petri net
- `place(pn, label, initial, max; level=0)` - Add place
- `exptrans(pn, label, rate; level=0)` - Add exponential transition
- `immtrans(pn, label, weight; level=0)` - Add immediate transition
- `inarc(pn, place, trans; mul=1)` - Add input arc
- `outarc(pn, trans, place; mul=1)` - Add output arc
- `arc(pn, src, dest; mul=1)` - Generic arc (direction auto-detected)
- `guard(trans, func, places)` - Add guard condition to transition
- `reward(pn, func)` - Add reward function

### Marking Operations

- `initial(pn)` - Get initial marking vector
- `maxmark(pn)` - Get maximum marking vector
- `minmark(pn)` - Get minimum marking vector
- `domain(place)` - Get allowed marking range for place

### Transition Operations

- `enablefunc(pn, trans)` - Get predicate to check if transition is enabled
- `firingfunc(pn, trans)` - Get function to fire transition
- `next(pn, trans, marking)` - Fire transition if enabled

### Analysis

- `incidence(pn)` - Compute incidence matrix
- `pinvariant(C)` - Compute P-invariants from incidence matrix (conservation laws)
- `tinvariant(C)` - Compute T-invariants from incidence matrix (cyclic firing sequences)
- `createevents(pn, rng, n)` - Generate n random transition events

### File I/O

- `load_pnml(path)` - Load from PNML file
- `load_pnml(io)` - Load from IO stream
- `todot(pn)` - Export to Graphviz DOT format

### Random Number Generation

- `WELL1024a(seed)` - Create WELL1024a RNG with seed
- `WELL1024a(init_array)` - Create from UInt32 array
- `rand(rng)` - Generate random Float64

## More Examples

See the [`examples/`](examples/) directory for detailed examples:

- [`simple_example.jl`](examples/simple_example.jl) - Basic Petri net operations
- [`dining_philosophers.jl`](examples/dining_philosophers.jl) - Classic dining philosophers problem
- [`invariant_example.jl`](examples/invariant_example.jl) - P-invariants and T-invariants analysis
- [`well1024a_example.jl`](examples/well1024a_example.jl) - Random number generation
- [`pnml_example.jl`](examples/pnml_example.jl) - Loading PNML files

## Visualization

Export to DOT format and visualize with Graphviz:

```julia
dot_string = todot(pn)
write("model.dot", dot_string)
```

Then convert to image:
```bash
dot -Tpng model.dot -o model.png
dot -Tsvg model.dot -o model.svg
```

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("PetriStructure")
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- **Petri Nets**: C.A. Petri, "Kommunikation mit Automaten" (1962)
- **GSPN**: M. Ajmone Marsan et al., "Modelling with Generalized Stochastic Petri Nets" (1995)
- **WELL1024a**: F. Panneton, P. L'Ecuyer, M. Matsumoto, "Improved Long-Period Generators Based on Linear Recurrences Modulo 2" (2006)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Authors

- Hiroyuki Okamura <okamu@hiroshima-u.ac.jp>
