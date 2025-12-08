"""
Macro for defining Petri nets with a concise syntax.

# Syntax
```julia
@petrinet begin
    # Places: name[initial, max]
    p1[1, 10]
    p2[0, 5]
    
    # Transitions: exp(rate): name or imm(weight): name
    exp(1.0): t1
    imm(1.0): t2
    
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
                    push!(transitions_list, (name=trans_name, type=trans_type, param=param))
                else
                    error("Transition type must be exp() or imm()")
                end
            else
                error("Transition syntax: exp(rate): name or imm(weight): name")
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
        else  # :imm
            push!(code.args, :($(t.name) = immtrans(pn, $(tname_str), $(t.param))))
        end
    end
    
    # Add arcs
    for a in arcs_list
        push!(code.args, :(arc(pn, $(a.from), $(a.to), mul=$(a.mult))))
    end
    
    # Add guards
    for g in guards_list
        # Create wrapper function that converts marking vector to local variables
        # Use pn.place_index to look up indices at runtime
        guard_place_names = g.places
        
        # Build variable assignments: place_name = m_vec[pn.place_index[:place_name]]
        var_assignments = [:($(pname) = m_vec[pn.place_index[$(QuoteNode(pname))]]) for pname in guard_place_names]
        
        # Create wrapper: m_vec -> begin place1=...; place2=...; condition end
        wrapper = :(m_vec -> begin
            $(var_assignments...)
            $(g.cond)
        end)
        
        places_vect = Expr(:vect, g.places...)
        push!(code.args, :(guard($(g.trans), $(wrapper), $(places_vect))))
    end
    
    # Return the Petri net
    push!(code.args, :pn)
    
    return code
end
