module PetriStructure

export petri, place, immtrans, exptrans, guard, arc, inarc, outarc,
       initial, maxmark, minmark, enablefunc, firingfunc,
       domain, incidence, pinvariant, pinvariant_basis, tinvariant, next, todot, load_pnml,
       @petrinet

include("structure.jl")
include("analysis.jl")
include("dot.jl")
include("pnml.jl")
include("macro.jl")

end
