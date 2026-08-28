abstract type AbstractNode end
abstract type AbstractArc end
abstract type AbstractPlace <: AbstractNode end
abstract type AbstractTrans <: AbstractNode end

function Base.show(io::IO, node::AbstractNode)
    Base.show(io, node.label)
end

"""
    Place

A place node that carries a label, marking domain, and incoming/outgoing arcs.
"""
struct Place <: AbstractPlace
    id::Int
    label::String
    level::Int
    initial::Int
    domains::Vector{Int}
    inarcs::Vector{AbstractArc}
    outarcs::Vector{AbstractArc}
end

"""
    InArc

An input arc from a place to a transition. `mul` is the required token count.

`src` is a concrete `Place` rather than an `AbstractPlace`: `enablefunc` and
`firingfunc` read `a.src.id` for every arc of every transition at every marking,
and an abstractly typed field makes that access a dynamic lookup that the
compiler cannot inline, boxing a value per iteration. `dest` points back at the
owning transition, which really can be any of the three kinds, and is not read on
those paths.
"""
struct InArc <: AbstractArc
    src::Place
    dest::AbstractTrans
    mul::Int
end

"""
    OutArc

An output arc from a transition to a place. `mul` is the produced token count.
`dest` is a concrete `Place` for the reason given on [`InArc`](@ref).
"""
struct OutArc <: AbstractArc
    src::AbstractTrans
    dest::Place
    mul::Int
end

"""
    ImmTrans

Immediate transition with weight and optional guard expressions.
"""
struct ImmTrans <: AbstractTrans
    id::Int
    label::String
    level::Int
    inarcs::Vector{InArc}
    outarcs::Vector{OutArc}
    weight::Float64
    guard::Vector{GuardExpr}
    guardplaces::Set{Place}
end

"""
    ExpTrans

Exponential (timed) transition with firing rate and optional guard expressions.
"""
struct ExpTrans <: AbstractTrans
    id::Int
    label::String
    level::Int
    inarcs::Vector{InArc}
    outarcs::Vector{OutArc}
    rate::Float64
    guard::Vector{GuardExpr}
    guardplaces::Set{Place}
end

"""
    GenTrans

General transition whose firing time follows a `GenDist` (`dist`). `policy` is
the memory policy applied on preemption, mirroring `gospn`:

- `:prd` — preemptive repeat different (resample on preemption; the default)
- `:prs` — preemptive resume (the elapsed age is kept)
- `:pri` — preemptive repeat identical (the sampled firing time is kept)

The policy is carried structurally for downstream state-space / simulation tools.
"""
struct GenTrans <: AbstractTrans
    id::Int
    label::String
    level::Int
    inarcs::Vector{InArc}
    outarcs::Vector{OutArc}
    dist::GenDist
    policy::Symbol
    guard::Vector{GuardExpr}
    guardplaces::Set{Place}
end

"""
    guard(tr, g::GuardExpr, places)

Attach structured guard expression `g` to transition `tr` and record dependent `places`.
"""
function guard(tr::AbstractTrans, g::GuardExpr, p)
    push!(tr.guard, g)
    push!(tr.guardplaces, p...)
end

"""
    PN

Container for a Petri net, storing places, transitions, and arcs.
"""
struct PN
    labels::Dict{String,Union{AbstractPlace,AbstractTrans}}
    places::Vector{Place}
    trans::Vector{AbstractTrans}   # every kind, in insertion order -- genuinely mixed
    exptrans::Vector{ExpTrans}
    immtrans::Vector{ImmTrans}
    gentrans::Vector{GenTrans}
    place_index::Dict{Symbol,Int}  # place label (Symbol) => index in places array
end

"""
    petri()

Create an empty Petri net container.
"""
function petri()
    PN(Dict(), Place[], AbstractTrans[], ExpTrans[], ImmTrans[], GenTrans[], Dict())
end

"""
    place(pn, label, init, max; level=0)

Add a place with `label`, initial marking `init`, and domain `0:max`.
"""
function place(pn::PN, label::String, init::Int, max::Int; level = 0)
    if level == 0
        level = length(pn.places)+1
    end
    p = Place(length(pn.places)+1, label, level, init, collect(0:max), AbstractArc[], AbstractArc[])
    push!(pn.places, p)
    pn.labels[label] = p
    pn.place_index[Symbol(label)] = length(pn.places)  # Register index by Symbol
    p
end

"""
    immtrans(pn, label, weight; level=0)

Add an immediate transition with priority `weight`.
"""
function immtrans(pn::PN, label::String, weight::Float64; level = 0)
    if level == 0
        level = length(pn.trans)+1
    end
    e = ImmTrans(length(pn.trans)+1, label, level, InArc[], OutArc[], weight, GuardExpr[], Set{Place}())
    push!(pn.trans, e)
    push!(pn.immtrans, e)
    pn.labels[label] = e
    e
end

"""
    exptrans(pn, label, rate; level=0)

Add an exponential (timed) transition with firing rate `rate`.
"""
function exptrans(pn::PN, label::String, rate::Float64; level = 0)
    if level == 0
        level = length(pn.trans)+1
    end
    e = ExpTrans(length(pn.trans)+1, label, level, InArc[], OutArc[], rate, GuardExpr[], Set{Place}())
    push!(pn.trans, e)
    push!(pn.exptrans, e)
    pn.labels[label] = e
    e
end

"""
    gentrans(pn, label, dist::GenDist; policy=:prd, level=0)

Add a general transition whose firing time follows distribution `dist`.
`policy` is the preemption memory policy (`:prd`, `:prs`, or `:pri`); see
[`GenTrans`](@ref). Build `dist` with [`detdist`](@ref), [`unifdist`](@ref),
or [`expdist`](@ref).
"""
function gentrans(pn::PN, label::String, dist::GenDist; policy::Symbol = :prd, level = 0)
    if !(policy in (:prd, :prs, :pri))
        error("gentrans: policy must be :prd, :prs or :pri (got :$policy)")
    end
    if level == 0
        level = length(pn.trans)+1
    end
    e = GenTrans(length(pn.trans)+1, label, level, InArc[], OutArc[], dist, policy, GuardExpr[], Set{Place}())
    push!(pn.trans, e)
    push!(pn.gentrans, e)
    pn.labels[label] = e
    e
end

"""
    inarc(pn, src, dest; mul=1)
    arc(pn, src::AbstractPlace, dest::AbstractTrans; mul=1)

Create an input arc from place `src` to transition `dest` with multiplicity `mul`.
"""
function inarc(pn::PN, src::String, dest::String; mul::Int = 1)
    p = pn.labels[src]
    t = pn.labels[dest]
    a = InArc(p, t, mul)
    push!(p.outarcs, a)
    push!(t.inarcs, a)
    a
end

function arc(pn::PN, src::AbstractPlace, dest::AbstractTrans; mul::Int = 1)
    a = InArc(src, dest, mul)
    push!(src.outarcs, a)
    push!(dest.inarcs, a)
    a
end

"""
    outarc(pn, src, dest; mul=1)
    arc(pn, src::AbstractTrans, dest::AbstractPlace; mul=1)

Create an output arc from transition `src` to place `dest` with multiplicity `mul`.
"""
function outarc(pn::PN, src::String, dest::String; mul::Int = 1)
    t = pn.labels[src]
    p = pn.labels[dest]
    a = OutArc(t, p, mul)
    push!(t.outarcs, a)
    push!(p.inarcs, a)
    a
end

function arc(pn::PN, src::AbstractTrans, dest::AbstractPlace; mul::Int = 1)
    a = OutArc(src, dest, mul)
    push!(src.outarcs, a)
    push!(dest.inarcs, a)
    a
end

"""
    initial(pn)

Return the vector of initial markings for all places.
"""
function initial(pn::PN)
    [x.initial for x in pn.places]
end

"""
    maxmark(pn)

Return the maximum marking in each place domain.
"""
function maxmark(pn::PN)
    [maximum(x.domains) for x in pn.places]
end

"""
    domain(p)

Return the domain of allowed markings for place `p`.
"""
function domain(p::AbstractPlace)
    p.domains
end

"""
    minmark(pn)

Return the minimum marking in each place domain.
"""
function minmark(pn::PN)
    [minimum(x.domains) for x in pn.places]
end

function inputplaces(::PN, tr::AbstractTrans)
    [a.src for a in tr.inarcs]
end

function outputplaces(::PN, tr::AbstractTrans)
    [a.dest for a in tr.outarcs]
end

function guardplaces(::PN, tr::AbstractTrans)
    [x for x in tr.guardplaces]
end

function inputtrans(::PN, p::AbstractPlace)
    [x.src for x in p.inarcs]
end

function outputtrans(::PN, p::AbstractPlace)
    [x.dest for x in p.outarcs]
end

"""
    getinouttrans(pn, p)

Return transition ids connected to place `p`.
"""
function getinouttrans(pn::PN, p::AbstractPlace)
    result = Set()
    for tr in inputtrans(pn, p)
        push!(result, tr.id)
    end
    for tr in outputtrans(pn, p)
        push!(result, tr.id)
    end
    result
end

"""
    getinoutplaces(pn, tr)

Return place ids connected to transition `tr`.
"""
function getinoutplaces(pn::PN, tr::AbstractTrans)
    result = Set()
    for p in inputplaces(pn, tr)
        push!(result, p.id)
    end
    for p in outputplaces(pn, tr)
        push!(result, p.id)
    end
    result
end

"""
    getrelatedplaces(pn, tr)

Return place ids related to transition `tr`, including guard places.
"""
function getrelatedplaces(pn::PN, tr::AbstractTrans)
    result = Set()
    for p in inputplaces(pn, tr)
        push!(result, p.id)
    end
    for p in outputplaces(pn, tr)
        push!(result, p.id)
    end
    for p in guardplaces(pn, tr)
        push!(result, p.id)
    end
    result
end
