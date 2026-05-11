"""
    GuardExpr

Abstract supertype for structured guard conditions.
Use concrete subtypes to build conditions symbolically;
call `evaluate(g, m)` to test a marking vector.
"""
abstract type GuardExpr end

# ------------------------------------------------------------------ #
# Leaf nodes — single-place comparisons                               #
# place_id : 1-based (matches marking vector index / place.id)       #
# val      : actual token count (not MEDDLY 0-indexed)               #
# ------------------------------------------------------------------ #

struct GuardGeq <: GuardExpr; place_id::Int; val::Int end  # m[k] >= val
struct GuardLeq <: GuardExpr; place_id::Int; val::Int end  # m[k] <= val
struct GuardEq  <: GuardExpr; place_id::Int; val::Int end  # m[k] == val

# Normalise strict / inequality-not forms using integer discreteness
GuardGt(k::Int, v::Int) = GuardGeq(k, v + 1)
GuardLt(k::Int, v::Int) = GuardLeq(k, v - 1)
GuardNe(k::Int, v::Int) = GuardOr(GuardLeq(k, v - 1), GuardGeq(k, v + 1))

# ------------------------------------------------------------------ #
# Composite nodes — boolean combinations                              #
# ------------------------------------------------------------------ #

struct GuardAnd <: GuardExpr; left::GuardExpr; right::GuardExpr end
struct GuardOr  <: GuardExpr; left::GuardExpr; right::GuardExpr end
struct GuardNot <: GuardExpr; expr::GuardExpr end

# ------------------------------------------------------------------ #
# Evaluation                                                          #
# ------------------------------------------------------------------ #

evaluate(g::GuardGeq, m) = m[g.place_id] >= g.val
evaluate(g::GuardLeq, m) = m[g.place_id] <= g.val
evaluate(g::GuardEq,  m) = m[g.place_id] == g.val
evaluate(g::GuardAnd, m) = evaluate(g.left, m) && evaluate(g.right, m)
evaluate(g::GuardOr,  m) = evaluate(g.left, m) || evaluate(g.right, m)
evaluate(g::GuardNot, m) = !evaluate(g.expr, m)

# ------------------------------------------------------------------ #
# Place-id extraction (for dependency analysis)                       #
# ------------------------------------------------------------------ #

guardplace_ids(g::GuardGeq) = Set{Int}([g.place_id])
guardplace_ids(g::GuardLeq) = Set{Int}([g.place_id])
guardplace_ids(g::GuardEq)  = Set{Int}([g.place_id])
guardplace_ids(g::GuardAnd) = union(guardplace_ids(g.left),  guardplace_ids(g.right))
guardplace_ids(g::GuardOr)  = union(guardplace_ids(g.left),  guardplace_ids(g.right))
guardplace_ids(g::GuardNot) = guardplace_ids(g.expr)
