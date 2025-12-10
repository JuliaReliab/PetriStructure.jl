import Nemo

function and(x::Bool, y::Bool)
    x && y
end

"""
    next(pn, tr, marking)

Apply transition `tr` to `marking` if enabled; otherwise return a copy.
"""
function next(pn::PN, tr::AbstractTrans, x)
    if enablefunc(pn, tr)(x)
        firingfunc(pn, tr)(x)
    else
        copy(x)
    end
end

"""
    enablefunc(pn, tr)

Return a predicate that checks whether transition `tr` is enabled for a marking.
"""
function enablefunc(::PN, tr::AbstractTrans)
    m -> begin
        enable = true
        for g in tr.guard
            enable = and(enable, g(m))
        end
        for a in tr.inarcs
            enable = and(enable, m[a.src.id] >= a.mul)
        end
        enable
    end
end

"""
    firingfunc(pn, tr)

Return the state update function that fires transition `tr` on a marking.
"""
function firingfunc(pn::PN, tr::AbstractTrans)
    m -> begin
        mm = copy(m)
        for a in tr.inarcs
            mm[a.src.id] -= a.mul
        end
        for a in tr.outarcs
            mm[a.dest.id] += a.mul
        end
        mm
    end
end

"""
    incidence(pn)

Return the incidence matrix of Petri net `pn`.
"""
function incidence(pn::PN)
    C = [0 for p in pn.places, t in pn.trans]
    for p in pn.places
        for a in p.inarcs
            t = a.src
            C[p.id, t.id] += a.mul
        end
        for a in p.outarcs
            t = a.dest
            C[p.id, t.id] += -a.mul
        end
    end
    return C
end

"""
    pinvariant(C)

Compute P-invariants of incidence matrix `C`.

P-invariants are non-negative integer vectors x such that C' * x = 0,
representing conservation laws for places.
"""
function pinvariant(C)
    m, n = size(C)
    im = zeros(Int,m,m)
    for i in 1:m
        im[i,i] = 1
    end
    A = [C im]
    for j in 1:n
        jplus = findall(x->x>0, A[:,j])
        jminus = findall(x->x<0, A[:,j])
        if length(jplus) > 0 && length(jminus) > 0
            for iplus in jplus
                for iminus in jminus
                    d = lcm(A[iplus,j], -A[iminus,j])
                    dplus = d // A[iplus,j]
                    dminus = -d // A[iminus,j]
                    v = [Int(x) for x in dplus * A[iplus,:] + dminus * A[iminus,:]]
                    A = vcat(A, v')
                end
            end
        end
        A = A[setdiff(1:end, union(jplus,jminus)),:]
    end
    X = collect(A[:,n+1:end]')
    return X
end

"""
    pinvariant_basis(C)

Compute a basis of P-invariants for incidence matrix `C` via Smith normal
form using `Nemo.snf_with_transform`. Returns a matrix whose rows form a basis
for the left-nullspace of `C`, allowing both positive and negative coefficients.
"""
function pinvariant_basis(C)
    m, n = size(C)
    A = Nemo.matrix(Nemo.ZZ, C)

    S, T, _ = Nemo.snf_with_transform(A)
    r = Nemo.rank(S)
    if r >= m
        return zeros(Int, 0, n)
    end

    basis = T[(r + 1):m, :]
    B = zeros(Int, Nemo.ncols(basis), Nemo.nrows(basis))
    for i in 1:Nemo.nrows(basis), j in 1:Nemo.ncols(basis)
        B[j, i] = Int(basis[i, j])
    end
    return B
end

"""
    tinvariant(C)

Compute T-invariants of incidence matrix `C`.

T-invariants are non-negative integer vectors y such that C * y = 0,
representing feasible firing sequences that return to the initial marking.
"""
function tinvariant(C)
    # T-invariants: C * y = 0  ⟺  C' * y = 0 for transposed problem
    # Apply the same algorithm to C'
    return pinvariant(C')
end

"""
    geteqns(pn, M, tr)

Return equation indices related to transition `tr` from matrix `M`.
"""
function geteqns(pn::PN, M, tr::AbstractTrans)
    p = getrelatedplaces(pn, tr)
    result = Set()
    for i in p
        tmp = findall(x->x!=0, M[i,:])
        if length(tmp) >= 1
            push!(result, findall(x->x!=0, M[i,:])...)
        end
    end
    sort([i for i in result])
end
