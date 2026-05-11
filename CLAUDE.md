# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the full test suite (from repo root)
julia --project=PetriStructure.jl -e 'using Pkg; Pkg.test()'

# Run the full test suite (from inside PetriStructure.jl/)
julia --project -e 'using Pkg; Pkg.test()'

# Run a single test file interactively
julia --project=PetriStructure.jl test/test_structure.jl

# Instantiate dependencies (first time or after Project.toml changes)
julia --project=PetriStructure.jl -e 'using Pkg; Pkg.instantiate()'

# Visualize a DOT output
dot -Tpng model.dot -o model.png
```

## Architecture

The package has six source files, each with a distinct responsibility:

- **`guard.jl`** — Guard condition types. `GuardExpr` abstract type; leaf nodes `GuardGeq`, `GuardLeq`, `GuardEq` (single-place comparisons); composite nodes `GuardAnd`, `GuardOr`, `GuardNot`. Constructor aliases `GuardGt`/`GuardLt`/`GuardNe` normalise strict inequalities to `Geq`/`Leq` using integer discreteness. `evaluate(g, m)` evaluates any `GuardExpr` against a marking vector; `guardplace_ids(g)` returns the `Set{Int}` of referenced place ids. Must be included first (before `structure.jl`).

- **`structure.jl`** — Core types and construction API. Defines `Place`, `ImmTrans`, `ExpTrans`, `InArc`, `OutArc`, and the `PN` container. All construction functions (`petri`, `place`, `exptrans`, `immtrans`, `inarc`, `outarc`, `arc`, `guard`) live here. `PN.place_index` maps place label `Symbol`s to their position in `pn.places`, used at runtime by guard closures.

- **`analysis.jl`** — Structural analysis. Imports `Nemo` for Smith Normal Form. Implements:
  - `enablefunc`/`firingfunc`/`next` for token-game simulation
  - `incidence` for the C matrix (places × transitions)
  - `pinvariant` (Farkas-style elimination for non-negative integer solutions)
  - `pinvariant_basis` (SNF-based, allows signed coefficients; rows = left-nullspace of C)
  - `tinvariant` (delegates to `pinvariant(C')`)
  - `getinouttrans(pn, p)` — transition ids connected to place `p`
  - `getinoutplaces(pn, tr)` — place ids connected to transition `tr`
  - `getrelatedplaces(pn, tr)` — place ids connected to `tr` including guard places
  - `geteqns(pn, M, tr)` — column indices in P-invariant matrix M that overlap `tr`'s neighbourhood
  - `integer_kernel(J)` — right integer null space of J via SNF right unimodular transform (last d columns of V)
  - `lll_reduce(K)` — LLL lattice basis reduction on column matrix K (m×d)
  - `pinvariant_reduce(pn)` / `pinvariant_reduce(C, m0)` — full `x = x₀ + K·t` parametrisation

- **`macro.jl`** — `@petrinet` macro. Parses a `begin...end` DSL block at macro-expand time into a sequence of `petri()`/`place()`/`exptrans()`/etc. calls. Guard conditions reference place names directly; the generated closure looks up runtime indices via `place.id`. Supported guard forms: single-place `>=`, `>`, `<=`, `<`, `==`, `!=`, combined with `&&`, `||`, `!`. Multi-place linear conditions must use `GuardExpr` directly.

- **`pnml.jl`** — PNML file I/O using `EzXML`. `load_pnml` reads place `initialMarking`/`ddOrder`/`bound`, transition `rate`/`timed` flags, and arc `inscription` (multiplicity). Places are sorted by `ddOrder` before insertion, which determines their index in the marking vector (critical for MDD engines that index by place.id).

- **`dot.jl`** — Graphviz DOT export. `todot` traverses the net and emits nodes (circles = places, filled-dashed boxes = immediate transitions, solid boxes = exponential transitions) with edge labels for non-unit multiplicities.

## Key design points

- **Immutable structs with mutable fields**: `Place`, `ImmTrans`, `ExpTrans` are `struct` (not `mutable struct`), but their `inarcs`/`outarcs`/`guard`/`guardplaces` fields are `Vector`/`Set` and are mutated in-place during construction.
- **Index = insertion order**: A node's `.id` equals its position in `pn.places` or `pn.trans` at construction time. The marking vector is always indexed by `place.id`. `ddOrder` in PNML controls insertion order (and hence place.id) for MDD-based engines.
- **Transition separation**: `pn.trans` holds all transitions in insertion order; `pn.exptrans` and `pn.immtrans` hold references to the same objects for fast filtered access.
- **No reachability**: The package is intentionally structural-only. It does not build or enumerate the reachability graph.
- **Guard evaluation polymorphism**: `evaluate(g, m)` and `enablefunc` accept any vector `m` including `Vector{Meddly.Edge}` — downstream MDD engines rely on this duck-typing to build symbolic MDD guard representations.

## Dependencies

- `Nemo` — used only in `analysis.jl` for `snf_with_transform` (`pinvariant_basis`, `integer_kernel`) and `lll` (`lll_reduce`)
- `EzXML` — used only in `pnml.jl` for PNML parsing
