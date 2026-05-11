# PetriStructure.jl

A Julia package for structural modeling and analysis of Petri nets and Generalized Stochastic Petri Nets (GSPNs).

## Features

- **Net construction** — functional API and `@petrinet` macro DSL
- **Transition types** — exponential (timed) and immediate
- **Guard conditions** — symbolic `GuardExpr` tree (Geq, Leq, Eq, And, Or, Not)
- **Structural analysis** — incidence matrix, P-invariants (Farkas and SNF), T-invariants
- **SNF / LLL parametrization** — absorb P-invariant constraints into a change of variables `x = x₀ + K·t`
- **PNML I/O** — load nets from PNML files (supports `ddOrder`, `bound`, `rate`, `timed`)
- **Visualization** — export to Graphviz DOT format

The package is intentionally structural-only. It does **not** build or enumerate reachability graphs.

## Installation

This package is distributed as a path dependency within the `experiment-ps4gspn` workspace.
To use it standalone, add it by path:

```julia
using Pkg
Pkg.develop(path = "path/to/PetriStructure.jl")
```

## Quick Start

### Functional API

```julia
using PetriStructure

pn = petri()

# Places: label, initial marking, max capacity
p1 = place(pn, "p1", 1, 1)
p2 = place(pn, "p2", 0, 1)

# Exponential (timed) transition
t1 = exptrans(pn, "t1", 2.0)   # rate = 2.0

# Arcs
arc(pn, p1, t1)   # input arc  (place → transition)
arc(pn, t1, p2)   # output arc (transition → place)

initial(pn)   # [1, 0]
maxmark(pn)   # [1, 1]
incidence(pn) # 2×1 incidence matrix
```

### `@petrinet` Macro

```julia
pn = @petrinet begin
    # Places: name[initial, max]
    think[1, 1]
    fork[1, 1]
    eat[0, 1]

    # Transitions: exp(rate): name  or  imm(weight): name
    exp(1.0): take
    exp(2.0): release

    # Arcs: source => destination  or  source => destination[mult]
    think => take
    fork  => take
    take  => eat
    eat   => release
    release => think
    release => fork
end
```

Guard conditions (single-place comparisons and boolean combinations):

```julia
pn = @petrinet begin
    stock[10, 20]
    exp(1.0): ship

    stock => ship[3]
    ship  => stock[0]   # placeholder; normally ship → output place

    guard(ship, [stock], stock >= 3)
end
```

### Loading from PNML

```julia
pn = load_pnml("models/phil_10.pnml")

println("Places: ",      length(pn.places))
println("Transitions: ", length(pn.trans))
println("Initial marking: ", initial(pn))
```

## API Reference

### Construction

| Function | Description |
|---|---|
| `petri()` | Create empty `PN` |
| `place(pn, label, init, max; level=0)` | Add place; domain is `0:max` |
| `exptrans(pn, label, rate; level=0)` | Add exponential transition |
| `immtrans(pn, label, weight; level=0)` | Add immediate transition |
| `arc(pn, place, trans; mul=1)` | Add input arc (place → transition) |
| `arc(pn, trans, place; mul=1)` | Add output arc (transition → place) |
| `inarc(pn, src, dest; mul=1)` | Same as above but by label string |
| `outarc(pn, src, dest; mul=1)` | Same as above but by label string |
| `guard(tr, g::GuardExpr, places)` | Attach guard to transition |
| `@petrinet begin … end` | Macro DSL — see below |

### Marking

| Function | Description |
|---|---|
| `initial(pn)` | Initial marking vector |
| `maxmark(pn)` | Maximum marking vector |
| `minmark(pn)` | Minimum marking vector |
| `domain(p)` | Allowed marking range (`Vector{Int}`) for place `p` |

### Token game

| Function | Description |
|---|---|
| `enablefunc(pn, tr)` | Returns a predicate `m -> Bool` |
| `firingfunc(pn, tr)` | Returns the state update `m -> m'` |
| `next(pn, tr, m)` | Fire `tr` on marking `m` if enabled; else return copy |

### Structural analysis

| Function | Description |
|---|---|
| `incidence(pn)` | `n_places × n_trans` incidence matrix |
| `pinvariant(pn)` / `pinvariant(C)` | Non-negative P-invariant vectors (Farkas elimination); columns satisfy `C' * y = 0` |
| `pinvariant_basis(C)` | SNF-based signed P-invariant basis; rows span the integer left-nullspace of `C` |
| `tinvariant(C)` | T-invariants; columns satisfy `C * y = 0` |
| `integer_kernel(J)` | Right integer null space of `J` (via SNF right unimodular transform) |
| `lll_reduce(K)` | LLL lattice basis reduction on column matrix `K` |
| `pinvariant_reduce(pn)` / `pinvariant_reduce(C, m0)` | Full pipeline → `(x0, K, rank_J)` for `x = x₀ + K·t` |

### Neighbourhood queries

These are used internally by MDD/SMT engines to identify affected variables.

| Function | Description |
|---|---|
| `getinouttrans(pn, p)` | `Set` of transition ids connected to place `p` |
| `getinoutplaces(pn, tr)` | `Set` of place ids connected to transition `tr` |
| `getrelatedplaces(pn, tr)` | `Set` of place ids connected to `tr`, including guard places |
| `geteqns(pn, M, tr)` | Column indices in `M` (P-invariant matrix) that overlap `tr`'s neighbourhood |

### Guard types

Guards are stored as an expression tree; `evaluate(g, m)` tests a marking vector.

| Type | Meaning |
|---|---|
| `GuardGeq(place_id, val)` | `m[place_id] >= val` |
| `GuardLeq(place_id, val)` | `m[place_id] <= val` |
| `GuardEq(place_id, val)` | `m[place_id] == val` |
| `GuardGt(place_id, val)` | `m[place_id] >= val+1` (integer normalised) |
| `GuardLt(place_id, val)` | `m[place_id] <= val-1` (integer normalised) |
| `GuardNe(place_id, val)` | `GuardOr(GuardLeq(…,val-1), GuardGeq(…,val+1))` |
| `GuardAnd(left, right)` | Logical AND |
| `GuardOr(left, right)` | Logical OR |
| `GuardNot(expr)` | Logical NOT |

`guardplace_ids(g)` returns the `Set{Int}` of place ids referenced by guard `g`.

### `@petrinet` macro syntax

```
place_name[initial, max]               # place
exp(rate): trans_name                  # exponential transition
imm(weight): trans_name                # immediate transition
src => dst                             # arc, multiplicity 1
src => dst[mult]                       # arc with multiplicity
guard(trans, [p1, p2, …], condition)   # guard
```

Supported guard condition forms (single-place comparisons only):

```
p >= c    p > c    p <= c    p < c    p == c    p != c
cond1 && cond2    cond1 || cond2    !cond
```

For multi-place linear conditions (e.g. `p1 + p2 >= k`), build `GuardExpr` manually and call `guard()` directly.

### File I/O and visualisation

| Function | Description |
|---|---|
| `load_pnml(path)` | Load from PNML file |
| `load_pnml(io::IO)` | Load from IO stream |
| `todot(pn)` | Export to Graphviz DOT string |

PNML attributes supported per element:

- **place**: `initialMarking`, `bound` (max tokens), `ddOrder` (insertion order for MDD variable levels)
- **transition**: `rate`, `timed` (true → exponential; false → immediate)
- **arc**: `inscription` (multiplicity, default 1)

## SNF / LLL parametrisation

P-invariants define constraints `J·x = J·m₀` on reachable markings (`J` = row-stacked invariant vectors).
`pinvariant_reduce` absorbs these into a change of variables so that the free parameter vector `t` has no invariant constraints:

```julia
x0, K, rank_J = pinvariant_reduce(pn)
# x = x0 + K * t  for any integer t satisfying capacity bounds
# rank_J = number of absorbed conservation laws
# size(K, 2) = n_places - rank_J = free dimension
```

The basis `K` is LLL-reduced for shorter, sparser columns — important for keeping MDD/BDD node counts small when used in state-space methods.

## Examples

See the [`examples/`](examples/) directory:

| File | Topic |
|---|---|
| `simple_example.jl` | Basic construction and incidence matrix |
| `dining_philosophers.jl` | Classic dining philosophers |
| `invariant_example.jl` | P-invariants and T-invariants |
| `macro_example.jl` | `@petrinet` macro |
| `pnml_example.jl` | Loading PNML files |
| `hnf_lll_example.jl` | SNF / LLL parametrisation |

## Testing

```bash
julia --project=PetriStructure.jl -e 'using Pkg; Pkg.test()'
```

## Dependencies

- [`Nemo`](https://nemocas.github.io/Nemo.jl/stable/) — Smith Normal Form and LLL (used in `analysis.jl`)
- [`EzXML`](https://juliaio.github.io/EzXML.jl/stable/) — PNML parsing (used in `pnml.jl`)

## License

MIT — see [LICENSE](LICENSE).

## Author

Hiroyuki Okamura <okamu@hiroshima-u.ac.jp>
