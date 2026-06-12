module PetriStructure

export petri, place, immtrans, exptrans, gentrans, guard, arc, inarc, outarc,
       initial, maxmark, minmark, enablefunc, firingfunc,
       domain, incidence, pinvariant, pinvariant_basis, tinvariant, next, todot, load_pnml,
       integer_kernel, lll_reduce, pinvariant_reduce,
       getinoutplaces, getrelatedplaces,
       @petrinet,
       GuardExpr, GuardGeq, GuardLeq, GuardEq, GuardGt, GuardLt, GuardNe,
       GuardAnd, GuardOr, GuardNot, evaluate, guardplace_ids,
       GenDist, DetDist, UnifDist, ExpDist, detdist, unifdist, expdist

include("guard.jl")       # GuardExpr types must be defined before structure.jl
include("dist.jl")        # GenDist types must be defined before structure.jl
include("structure.jl")
include("analysis.jl")
include("dot.jl")
include("pnml.jl")
include("macro.jl")

end
