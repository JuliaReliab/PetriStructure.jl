# Changelog

All notable changes to PetriStructure.jl are documented in this file.

## [1.2.0] - 2026-06-12

### Added

- **`dist.jl`** — firing-time distributions for general transitions
  - Abstract type `GenDist` with concrete `DetDist`, `UnifDist`, `ExpDist`
  - Constructors `detdist(v)`, `unifdist(a, b)`, `expdist(rate)` (lowercase to avoid
    clashing with `LinearAlgebra.det`)
- **`GenTrans`** — general transition carrying a `GenDist` and a preemption
  `policy` (`:prd` default, `:prs`, `:pri`), mirroring the `gospn` tool
  - `gentrans(pn, label, dist; policy=:prd, level=0)` constructor; transitions are
    tracked in the new `PN.gentrans` list
  - Participates in `enablefunc`/`firingfunc`/`incidence` like any transition
    (guards supported)
  - `@petrinet` gains `gen(dist): name` (and `gen(dist, :policy): name`) syntax
  - Graphviz export draws GEN transitions as a light-gray box
  - The distribution/policy are stored structurally for downstream state-space and
    simulation tools; the structural analyses here do not interpret them

## [1.1.0] - 2026-05-11

### Added

- **`guard.jl`** — symbolic guard condition tree
  - Abstract type `GuardExpr` and leaf nodes `GuardGeq`, `GuardLeq`, `GuardEq`
  - Constructor aliases `GuardGt`, `GuardLt`, `GuardNe` (normalised to Geq/Leq via integer discreteness)
  - Composite nodes `GuardAnd`, `GuardOr`, `GuardNot`
  - `evaluate(g, m)` — evaluate any `GuardExpr` against a marking vector; duck-typed to accept `Vector{Meddly.Edge}` for symbolic MDD evaluation
  - `guardplace_ids(g)` — return `Set{Int}` of place ids referenced by a guard
  - All guard types exported from the module

- **SNF / LLL parametrisation** (in `analysis.jl`)
  - `integer_kernel(J)` — right integer null space of `J` via Smith Normal Form (last `d` columns of the right unimodular transform `V`)
  - `lll_reduce(K)` — LLL lattice basis reduction on a column matrix `K` (via `Nemo.lll`)
  - `pinvariant_reduce(pn)` / `pinvariant_reduce(C, m0)` — full pipeline returning `(x0, K, rank_J)` for the change of variables `x = x₀ + K·t`

- **Neighbourhood query functions**
  - `getinouttrans(pn, p)` — `Set` of transition ids connected to place `p` (used by MDD engines)
  - `getinoutplaces(pn, tr)` — `Set` of place ids connected to transition `tr`
  - `getrelatedplaces(pn, tr)` — `Set` of place ids connected to `tr`, including guard places
  - `geteqns(pn, M, tr)` — column indices in P-invariant matrix `M` that overlap `tr`'s neighbourhood

- **Documentation**
  - Rewrote `README.md`: accurate API tables, guard types, SNF/LLL section, neighbourhood query section, correct test command
  - Updated `CLAUDE.md`: `guard.jl` section, duck-typing design note, all new functions documented

### Changed

- `guard.jl` is now included before `structure.jl` in `PetriStructure.jl` so guard types are available to all other modules
- `@petrinet` macro guard conditions now compile to structured `GuardExpr` trees instead of plain closures, enabling symbolic evaluation by MDD/SMT engines

---

## [1.0.0] - 2025-12-10

### Added

- **Core Petri net types** — `Place`, `ImmTrans`, `ExpTrans`, `InArc`, `OutArc`, `PN`
- **Construction API** — `petri()`, `place()`, `exptrans()`, `immtrans()`, `inarc()`, `outarc()`, `arc()`, `guard()`
- **Marking operations** — `initial()`, `maxmark()`, `minmark()`, `domain()`
- **Token-game simulation** — `enablefunc()`, `firingfunc()`, `next()`
- **Structural analysis**
  - `incidence()` — incidence matrix (places × transitions)
  - `pinvariant(C)` / `pinvariant(pn)` — non-negative P-invariants via Farkas elimination
  - `pinvariant_basis(C)` — signed P-invariant basis via Smith Normal Form
  - `tinvariant(C)` — T-invariants (delegates to `pinvariant(C')`)
- **`@petrinet` macro** — concise DSL for net definition (`place[init,max]`, `exp(r): t`, `imm(w): t`, `src => dst[mul]`, `guard(t, [places], cond)`)
- **PNML I/O** — `load_pnml(path)` / `load_pnml(io)` supporting `initialMarking`, `bound`, `ddOrder`, `rate`, `timed`, `inscription`
- **DOT visualisation** — `todot(pn)` for Graphviz export
- **Test suite** refactored into separate files: `test_structure.jl`, `test_analysis.jl`, `test_dot.jl`, `test_macro.jl`, `test_pnml.jl`

### Removed

- `reward(pn, f)` and `PN.reward` field — reward functions moved to application layer
- `createevents(pn, rng, k)` — event sampling moved to `PS4GSPN.jl`
- `well1024a.jl` / `WELL1024a` PRNG — split into the separate `WELL1024.jl` package
- `StatsBase` dependency
