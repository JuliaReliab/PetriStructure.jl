"""
SNF/LLL Parametrization Example

Demonstrates how P-invariants can be absorbed into a change of variables
    x = x0 + K * t,  t ∈ ℤᵈ
using integer_kernel (right null space via Smith Normal Form) and lll_reduce
(LLL lattice basis reduction).  The t-space has dimension d = m - rank(J)
where m is the number of places and J is the P-invariant matrix (rows as
invariants).

Why SNF (not HNF): the right null space {x : J·x = 0} is spanned by the last
d columns of the right unimodular transform V from snf_with_transform (S = U·J·V).
Row HNF gives only a left transform U and cannot extract the right null space
directly; applying row HNF to J^T would work but requires an extra transpose step.

Wide P-invariants (large support across many places) inflate MDD node counts;
absorbing them into the parametrization eliminates them from the state-space
representation and keeps MDD structures compact.
"""

using PetriStructure
using Printf

# ─────────────────────────────────────────────────────────────────────────────
# Example 1: simple p1 → t → p2 net (2 places, 1 P-invariant)
# ─────────────────────────────────────────────────────────────────────────────
println("=" ^ 60)
println("Example 1: Simple Transfer Net (2 places)")
println("=" ^ 60)

pn1 = @petrinet begin
    p1[1, 1]
    p2[0, 1]
    exp(1.0): t
    p1 => t
    t  => p2
end

C1 = incidence(pn1)
m0_1 = initial(pn1)

println("Places : p1 (initial=1), p2 (initial=0)")
println("Initial marking m0 = ", m0_1)

# Raw P-invariant
J1 = pinvariant_basis(C1)   # 1×2, rows are invariants
println("\nP-invariant matrix J (rows = invariants):")
display(J1)

# Right null space of J
K1_raw = integer_kernel(J1)   # 2×1
println("\nKernel basis K_raw (columns = free directions):")
display(K1_raw)

# LLL-reduced basis (already minimal here)
K1 = lll_reduce(K1_raw)
println("\nLLL-reduced kernel K:")
display(K1)

# Full pipeline
res1 = pinvariant_reduce(pn1)
println("\npinvariant_reduce result:")
println("  x0      = ", res1.x0)
println("  K       = ", vec(res1.K))   # display as vector since it's 2×1
println("  rank_J  = ", res1.rank_J, "  (1 conservation law absorbed)")
println("  free dim = ", size(res1.K, 2), "  (was 2, now 1)")

println("\nReachable markings as x = x0 + K*t:")
for t in [-1, 0, 1]
    x = res1.x0 + res1.K * [t]
    in_bounds = all(minmark(pn1) .<= x .<= maxmark(pn1))
    println("  t = $t  →  x = $x  $(in_bounds ? "(reachable)" : "(out of bounds)")")
end

# ─────────────────────────────────────────────────────────────────────────────
# Example 2: Producer–Consumer (3 places, 1 P-invariant, still 1D reduction)
# ─────────────────────────────────────────────────────────────────────────────
println()
println("=" ^ 60)
println("Example 2: Producer–Consumer (2 places, 1 P-invariant)")
println("=" ^ 60)
println("  produce: ready → buffer + ready  (ready is restored each time)")
println("  consume: buffer →")
println("  P-invariant: ready = 1 always  →  buffer is the only free dim")
println()

pn2 = @petrinet begin
    ready[1, 1]
    buffer[0, 5]
    exp(2.0): produce
    exp(1.0): consume
    ready   => produce
    produce => buffer
    produce => ready
    buffer  => consume
end

C2 = incidence(pn2)
m0_2 = initial(pn2)

println("Places: ready (init=1, max=1), buffer (init=0, max=5)")
println("Initial marking m0 = ", m0_2)

res2 = pinvariant_reduce(pn2)
J2   = pinvariant_basis(C2)

println("\nP-invariant matrix J ($(size(J2,1)) invariants × $(size(J2,2)) places):")
display(J2)
println("  → J = [1, 0]: 'ready' is always 1 (consumed then immediately restored)")

println("\nLLL-reduced kernel K ($(size(res2.K,1)) × $(size(res2.K,2))):")
display(res2.K)
println("  → K = [0, 1]: only 'buffer' can vary freely")

println("\npinvariant_reduce:")
println("  rank_J   = ", res2.rank_J, "  (", res2.rank_J, " conservation law absorbed)")
println("  free dim = ", size(res2.K, 2))

println("\nVerification J * K = 0:")
display(J2 * res2.K)

# ─────────────────────────────────────────────────────────────────────────────
# Example 3: Two-slot Token Ring (4 places, 2 invariants → 2D reduction)
# ─────────────────────────────────────────────────────────────────────────────
println()
println("=" ^ 60)
println("Example 3: Two-Slot Token Ring (4 places, 2 P-invariants)")
println("=" ^ 60)
println("  slot0_A ⇄ slot0_B  (independent cycle 1)")
println("  slot1_A ⇄ slot1_B  (independent cycle 2)")
println("  Wide invariant: slot0_A+slot0_B = 1, slot1_A+slot1_B = 1")
println()

pn3 = @petrinet begin
    s0A[1, 1]
    s0B[0, 1]
    s1A[1, 1]
    s1B[0, 1]
    exp(1.0): t0
    exp(1.0): t1
    s0A => t0
    t0  => s0B
    s1A => t1
    t1  => s1B
end

C3 = incidence(pn3)
m0_3 = initial(pn3)

println("Initial marking m0 = ", m0_3)

res3 = pinvariant_reduce(pn3)
J3   = pinvariant_basis(C3)

println("P-invariant matrix J ($(size(J3,1)) × $(size(J3,2))):")
display(J3)
println("\nLLL-reduced kernel K ($(size(res3.K,1)) × $(size(res3.K,2))):")
display(res3.K)
println("\npinvariant_reduce:")
println("  rank_J   = ", res3.rank_J)
println("  free dim = ", size(res3.K, 2),
        "  (reduced from 4 to 2 — each ring absorbs one dimension)")

# Show how raw SNF kernel compares to LLL-reduced
K3_raw = integer_kernel(J3)
println("\nRaw SNF kernel K_raw:")
display(K3_raw)
println("\nAfter LLL:")
display(res3.K)
println("(LLL keeps vectors local/short; raw SNF may produce denser vectors)")

# ─────────────────────────────────────────────────────────────────────────────
# Example 4: Dining Philosophers (scale study)
# Demonstrates dimension reduction growing with model size
# ─────────────────────────────────────────────────────────────────────────────
println()
println("=" ^ 60)
println("Example 4: Dining Philosophers — Dimension Reduction at Scale")
println("=" ^ 60)
println("  For N philosophers: 4N places, ~2N P-invariants → ~2N free dims")
println("  Wide invariants (fork sharing) are absorbed, MDD stays compact.")
println()

function build_philosophers(n)
    pn = petri()
    for i in 0:n-1
        place(pn, "idle$i",   1, 1)
        place(pn, "hungry$i", 0, 1)
        place(pn, "eat$i",    0, 1)
        place(pn, "fork$i",   1, 1)
        exptrans(pn, "ih$i", 1.0)
        exptrans(pn, "he$i", 1.0)
        exptrans(pn, "ei$i", 1.0)
    end
    for i in 0:n-1
        nf = (i+1) % n
        inarc(pn, "idle$i",   "ih$i");  outarc(pn, "ih$i", "hungry$i")
        inarc(pn, "hungry$i", "he$i");  inarc(pn, "fork$i",  "he$i")
        inarc(pn, "fork$nf",  "he$i");  outarc(pn, "he$i",  "eat$i")
        inarc(pn, "eat$i",    "ei$i");  outarc(pn, "ei$i",  "idle$i")
        outarc(pn, "ei$i", "fork$i");   outarc(pn, "ei$i",  "fork$nf")
    end
    pn
end

println(@sprintf("%-6s  %-8s  %-10s  %-10s  %-10s",
                 "N", "places", "rank_J", "free_dim", "reduction%"))
println("-" ^ 52)

for n in [2, 3, 4, 5, 8, 10]
    local pn_n = build_philosophers(n)
    C  = incidence(pn_n)
    m0 = initial(pn_n)
    res = pinvariant_reduce(pn_n)
    m   = length(pn_n.places)
    d   = size(res.K, 2)
    pct = round(100 * (1 - d/m), digits=1)
    println(@sprintf("%-6d  %-8d  %-10d  %-10d  %-9s%%",
                     n, m, res.rank_J, d, pct))
end

println()
println("Interpretation:")
println("  rank_J ≈ 2N: N philosopher-state invariants + N fork invariants")
println("  free_dim ≈ 2N: remaining degrees of freedom after absorbing invariants")
println("  reduction% ≈ 50%: half the original dimensions are eliminated")
println()
println("The fork-sharing invariants (e.g., fork_k + eat_k + eat_{k-1} = 1)")
println("span 3 places each and are wide enough to cause O(N) MDD node growth.")
println("After LLL parametrization they vanish from the MDD structure entirely.")

# ─────────────────────────────────────────────────────────────────────────────
# Example 5: Direct use of integer_kernel and lll_reduce
# ─────────────────────────────────────────────────────────────────────────────
println()
println("=" ^ 60)
println("Example 5: Direct Use of integer_kernel / lll_reduce")
println("=" ^ 60)

# Suppose we have a manually specified constraint system:
#   x1 + x2 + x3 + x4 = 2   (one wide invariant)
#   x1 + x2             = 1  (narrow invariant)
# Variables: x1..x4

J_manual = [1 1 1 1;
            1 1 0 0]   # 2×4, rows are invariants

println("Constraint matrix J:")
display(J_manual)

K_raw_m = integer_kernel(J_manual)   # 4×2
println("\nRaw null space K_raw (columns = free directions):")
display(K_raw_m)

K_lll_m = lll_reduce(K_raw_m)
println("\nLLL-reduced K:")
display(K_lll_m)

println("\nVerification J * K_raw = 0:")
display(J_manual * K_raw_m)
println("\nVerification J * K_lll = 0:")
display(J_manual * K_lll_m)

println()
println("The LLL basis gives shorter, more localized free directions,")
println("which correspond to narrower MDD nodes in the t-space representation.")
