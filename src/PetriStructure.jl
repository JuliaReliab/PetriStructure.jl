module PetriStructure

export petri, place, immtrans, exptrans, guard, arc, inarc, outarc, reward,
       initial, maxmark, minmark, createevents, enablefunc, firingfunc,
       domain, incidence, pinvariant, tinvariant, next, todot, load_pnml, WELL1024a,
       @petrinet

include("structure.jl")
include("analysis.jl")
include("dot.jl")
include("pnml.jl")
include("well1024a.jl")
include("macro.jl")

end
