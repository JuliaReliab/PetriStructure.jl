"""
Macro for defining Petri nets with a concise syntax.

# Syntax
```julia
@petrinet begin
    # Places: name[initial, max]
    p1[1, 10]
    p2[0, 5]
    
    # Transitions: exp(rate): name, imm(weight): name, or gen(dist): name
    exp(1.0): t1
    imm(1.0): t2
    gen(detdist(2.0)): t3            # general transition; optional policy: gen(detdist(2.0), :prs): t3
    
    # Arcs: source => destination or source => destination[mult]
    p1 => t1
    t1 => p2[2]
    p2 => t2
    t2 => p1
    
    # Guards: guard(trans, [places...], condition)
    # Use place names directly in condition
    guard(t1, [p1], p1 > 0)
    guard(t2, [p1, p2], p1 + p2 >= 3)
end
```
"""
macro petrinet(expr)
    return esc(_parse_petrinet_new(expr))
end

function _parse_petrinet_new(expr)
    if expr.head != :block
        error("@petrinet expects a begin...end block")
    end
    
    places_list = []  # [(name, initial, max), ...] - preserve order
    transitions_list = []  # (name, type, param)
    arcs_list = []  # (from, to, mult)
    guards_list = []  # (trans, places, condition)
    
    for line in expr.args
        if isa(line, LineNumberNode) || line === nothing
            continue
        end
        
        # Skip empty expressions
        if isa(line, Expr) && line.head == :tuple && isempty(line.args)
            continue
        end
        
        # Parse place: name[initial, max]
        if isa(line, Expr) && line.head == :ref
            place_name = line.args[1]
            if length(line.args) == 3
                push!(places_list, (name=place_name, initial=line.args[2], max=line.args[3]))
            elseif length(line.args) == 2
                push!(places_list, (name=place_name, initial=line.args[2], max=nothing))
            else
                error("Place syntax: name[initial, max] or name[initial]")
            end
        # Parse arc: a => b or a => b[mult]
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :(=>)
            lhs = line.args[2]
            rhs = line.args[3]
            mult = 1
            
            if isa(rhs, Expr) && rhs.head == :ref
                mult = rhs.args[2]
                rhs = rhs.args[1]
            end
            push!(arcs_list, (from=lhs, to=rhs, mult=mult))
        # Parse guard: guard(trans, [places...], condition)
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :guard
            if length(line.args) != 4
                error("Guard syntax: guard(trans, [places...], condition)")
            end
            trans_name = line.args[2]
            guard_places_expr = line.args[3]
            condition = line.args[4]
            
            # Extract places from vector
            guard_places = if isa(guard_places_expr, Expr) && guard_places_expr.head == :vect
                guard_places_expr.args
            else
                error("Guard places must be specified as [place1, place2, ...]")
            end
            
            push!(guards_list, (trans=trans_name, places=guard_places, cond=condition))
        # Parse transition: exp(rate): name or imm(weight): name
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :(:)
            trans_spec = line.args[2]
            trans_name = line.args[3]
            
            if isa(trans_spec, Expr) && trans_spec.head == :call
                trans_type = trans_spec.args[1]
                param = trans_spec.args[2]
                
                if trans_type in [:exp, :imm]
                    push!(transitions_list, (name=trans_name, type=trans_type, param=param, policy=nothing))
                elseif trans_type == :gen
                    # gen(dist): name  or  gen(dist, :policy): name
                    policy = length(trans_spec.args) >= 3 ? trans_spec.args[3] : nothing
                    push!(transitions_list, (name=trans_name, type=trans_type, param=param, policy=policy))
                else
                    error("Transition type must be exp(), imm() or gen()")
                end
            else
                error("Transition syntax: exp(rate): name, imm(weight): name or gen(dist): name")
            end
        else
            error("Unrecognized syntax: $line")
        end
    end
    
    # Generate code
    code = quote
        pn = petri()
    end
    
    # Add places (in order)
    for pinfo in places_list
        pname_str = String(pinfo.name)
        pmax = pinfo.max === nothing ? 1000000 : pinfo.max
        push!(code.args, :($(pinfo.name) = place(pn, $(pname_str), $(pinfo.initial), $(pmax))))
    end
    
    # Add transitions
    for t in transitions_list
        tname_str = String(t.name)
        if t.type == :exp
            push!(code.args, :($(t.name) = exptrans(pn, $(tname_str), $(t.param))))
        elseif t.type == :imm
            push!(code.args, :($(t.name) = immtrans(pn, $(tname_str), $(t.param))))
        else  # :gen
            if t.policy === nothing
                push!(code.args, :($(t.name) = gentrans(pn, $(tname_str), $(t.param))))
            else
                push!(code.args, :($(t.name) = gentrans(pn, $(tname_str), $(t.param); policy=$(t.policy))))
            end
        end
    end
    
    # Add arcs
    for a in arcs_list
        push!(code.args, :(arc(pn, $(a.from), $(a.to), mul=$(a.mult))))
    end
    
    # Add guards
    for g in guards_list
        guard_place_syms = Set(g.places)
        ast_expr = _parse_guard_cond(g.cond, guard_place_syms)
        places_vect = Expr(:vect, g.places...)
        push!(code.args, :(guard($(g.trans), $(ast_expr), $(places_vect))))
    end
    
    # Return the Petri net
    push!(code.args, :pn)

    return code
end

# Parse a guard condition expression (at macro-expand time) into a GuardExpr constructor call.
# place_syms: Set of Symbol names that are place variables in the guard.
# Returns a quoted expression that constructs a GuardExpr at runtime.
function _parse_guard_cond(expr, place_syms::Set)
    if isa(expr, Expr) && expr.head == :call
        op  = expr.args[1]
        lhs = expr.args[2]
        # Single-place comparison: p op val (lhs must be a place symbol)
        if length(expr.args) == 3 && op in [:>=, :>, :<=, :<, :(==), :!=] &&
                isa(lhs, Symbol) && lhs in place_syms
            k_sym = lhs              # place variable (Place object at runtime)
            val   = expr.args[3]    # token count (literal Int)
            return if op == :>=
                :(GuardGeq($(k_sym).id, $(val)))
            elseif op == :>
                :(GuardGeq($(k_sym).id, $(val) + 1))
            elseif op == :<=
                :(GuardLeq($(k_sym).id, $(val)))
            elseif op == :<
                :(GuardLeq($(k_sym).id, $(val) - 1))
            elseif op == :(==)
                :(GuardEq($(k_sym).id, $(val)))
            else  # :!=
                :(GuardOr(GuardLeq($(k_sym).id, $(val) - 1),
                          GuardGeq($(k_sym).id, $(val) + 1)))
            end
        # Boolean AND: a && b  or  a & b
        elseif length(expr.args) == 3 && op in [:&&, :&]
            return :(GuardAnd($(_parse_guard_cond(expr.args[2], place_syms)),
                              $(_parse_guard_cond(expr.args[3], place_syms))))
        # Boolean OR: a || b  or  a | b
        elseif length(expr.args) == 3 && op in [:||, :|]
            return :(GuardOr($(_parse_guard_cond(expr.args[2], place_syms)),
                             $(_parse_guard_cond(expr.args[3], place_syms))))
        # Negation: !a
        elseif length(expr.args) == 2 && op == :!
            return :(GuardNot($(_parse_guard_cond(expr.args[2], place_syms))))
        end
    # Handle short-circuit && / || as :&&/:|| head (Julia sometimes uses these)
    elseif isa(expr, Expr) && expr.head in [:&&, :||]
        op = expr.head
        return if op == :&&
            :(GuardAnd($(_parse_guard_cond(expr.args[1], place_syms)),
                       $(_parse_guard_cond(expr.args[2], place_syms))))
        else
            :(GuardOr($(_parse_guard_cond(expr.args[1], place_syms)),
                      $(_parse_guard_cond(expr.args[2], place_syms))))
        end
    end
    error("@petrinet guard: unsupported condition `$expr`.\n" *
          "Supported forms: p >= c, p <= c, p > c, p < c, p == c, p != c, " *
          "&&, ||, !  (where p is a single place variable and c is an integer literal).\n" *
          "For multi-place conditions, build GuardExpr directly and call guard() manually.")
end
