"""
    GenDist

Abstract supertype for the firing-time distribution of a general (`GenTrans`)
transition. Concrete subtypes mirror the distributions of the `gospn` tool:
`DetDist` (deterministic), `UnifDist` (uniform), `ExpDist` (exponential).

The distribution is carried structurally; it is consumed by state-space /
simulation tools built on top of `PetriStructure`, not by the structural
analyses in this package.
"""
abstract type GenDist end

"""
    DetDist(value)

Deterministic (constant) distribution: the firing time is exactly `value`.
Construct with `detdist(value)`.
"""
struct DetDist <: GenDist
    value::Float64
end

"""
    UnifDist(a, b)

Uniform distribution on the interval `(a, b)`. Construct with `unifdist(a, b)`.
"""
struct UnifDist <: GenDist
    a::Float64
    b::Float64
end

"""
    ExpDist(rate)

Exponential distribution with the given `rate`. Construct with `expdist(rate)`.
"""
struct ExpDist <: GenDist
    rate::Float64
end

"""
    detdist(value)

Deterministic distribution with constant firing time `value` (a `DetDist`).
"""
detdist(value::Real) = DetDist(Float64(value))

"""
    unifdist(a, b)

Uniform distribution on `(a, b)` (a `UnifDist`).
"""
unifdist(a::Real, b::Real) = UnifDist(Float64(a), Float64(b))

"""
    expdist(rate)

Exponential distribution with the given `rate` (an `ExpDist`).
"""
expdist(rate::Real) = ExpDist(Float64(rate))

Base.show(io::IO, d::DetDist)  = print(io, "det(", d.value, ")")
Base.show(io::IO, d::UnifDist) = print(io, "unif(", d.a, ", ", d.b, ")")
Base.show(io::IO, d::ExpDist)  = print(io, "exp(", d.rate, ")")
