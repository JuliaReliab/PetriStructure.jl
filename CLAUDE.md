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

- **`dist.jl`** — Firing-time distributions for general transitions. Abstract `GenDist` with concrete `DetDist`/`UnifDist`/`ExpDist`; lowercase constructors `detdist`/`unifdist`/`expdist` (lowercase deliberately, so `det` does not shadow `LinearAlgebra.det` in downstream packages). Must be included before `structure.jl` (referenced by `GenTrans`).

- **`structure.jl`** — Core types and construction API. Defines `Place`, `ImmTrans`, `ExpTrans`, `GenTrans`, `InArc`, `OutArc`, and the `PN` container. All construction functions (`petri`, `place`, `exptrans`, `immtrans`, `gentrans`, `inarc`, `outarc`, `arc`, `guard`) live here. `GenTrans` carries a `GenDist` plus a preemption `policy` (`:prd`/`:prs`/`:pri`) and is tracked in `PN.gentrans` (parallel to `pn.exptrans`/`pn.immtrans`); the distribution/policy are structural metadata only — `enablefunc`/`firingfunc`/`incidence` treat every transition uniformly via its arcs and guard. `PN.place_index` maps place label `Symbol`s to their position in `pn.places`, used at runtime by guard closures. `InArc`/`OutArc` are defined *before* the transition types so a transition can hold `Vector{InArc}`/`Vector{OutArc}` — see the typing design point below.

- **`analysis.jl`** — Structural analysis. Imports `Nemo` for Smith Normal Form. Implements:
  - `isenabled(pn, tr, m)`/`fire(pn, tr, m)` — the token game. **Call these in a loop.**
    `enablefunc`/`firingfunc` return a closure and are one-line wrappers over them, kept
    for the existing API; building a closure per call is a real cost to a caller that
    checks every transition at every marking (see `PetriAnalysis.jl`)
  - `next(pn, tr, m)` — fire if enabled, otherwise copy
  - `and(x, y)` — how `isenabled` combines guards and arcs; see the design point below
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

- **The net's own types are concrete, deliberately.** `Place`, `PN.places`, the per-kind
  transition lists (`PN.exptrans`/`immtrans`/`gentrans`), a transition's `inarcs`/`outarcs`
  and the place a hot arc points at (`InArc.src`, `OutArc.dest`) all name a concrete type.
  They were declared as their abstract supertype until 1.3.0, which meant the token game
  could not be inlined and boxed a value for every arc of every call — on a reachability
  search that was the dominant cost (about 10x the time and 3x the memory of the same
  search over concretely typed data). **Do not widen these back to `AbstractPlace` /
  `AbstractTrans` / `AbstractArc`.** Two places stay abstract on purpose and are not on a
  hot path: `PN.trans`, which genuinely holds all three transition kinds, and
  `Place.inarcs`/`outarcs`, because arcs and places refer to each other so one side has to
  stay abstract.

- **Immutable structs with mutable fields**: `Place`, `ImmTrans`, `ExpTrans` are `struct` (not `mutable struct`), but their `inarcs`/`outarcs`/`guard`/`guardplaces` fields are `Vector`/`Set` and are mutated in-place during construction.
- **Index = insertion order**: A node's `.id` equals its position in `pn.places` or `pn.trans` at construction time. The marking vector is always indexed by `place.id`. `ddOrder` in PNML controls insertion order (and hence place.id) for MDD-based engines.
- **Transition separation**: `pn.trans` holds all transitions in insertion order; `pn.exptrans` and `pn.immtrans` hold references to the same objects for fast filtered access.
- **No reachability**: The package is intentionally structural-only. It does not build or enumerate the reachability graph.
- **Guard evaluation polymorphism**: `evaluate(g, m)`, `isenabled` and `enablefunc` accept any vector `m` including `Vector{Meddly.Edge}` — downstream MDD engines rely on this duck-typing to build symbolic MDD guard representations. `isenabled` therefore combines its terms with `and(x, y)` rather than `&&`, and visits **every** guard and arc even once a `Bool` result would be settled: an MDD engine adds its own `and` method that builds an expression node, and needs every term. **Do not turn those loops into short-circuits** — it looks like free speed in a hot path and silently breaks symbolic evaluation. `m` must likewise stay unconstrained.

## Dependencies

- `Nemo` — used only in `analysis.jl` for `snf_with_transform` (`pinvariant_basis`, `integer_kernel`) and `lll` (`lll_reduce`)
- `EzXML` — used only in `pnml.jl` for PNML parsing
