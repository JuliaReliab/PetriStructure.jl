"""
Macro for defining Petri nets with a concise syntax.

# Syntax
```julia
@petrinet begin
    # Places: place_name[initial_marking, max_marking]
    p1[1, 10]
    p2[0, 5]
    
    # Transitions:
    # exp(rate): t_name          # Exponential transition
    # imm(weight): t_name         # Immediate transition
    exp(1.0): t1
    imm(1.0): t2
    
    # Arcs: source => destination [multiplicity]
    p1 => t1
    t1 => p2 [2]
    p2 => t2
    t2 => p1
    
    # Guards: guard(trans_name, condition, [dependent_places...])
    # Use place names directly: m.place_name
    guard(t1, m -> m.p1 > 0, [p1])
end
```

# Examples
```julia
# Simple producer-consumer
@petrinet begin
    buffer[0, 10]
    producer[1, 1]
    consumer[1, 1]
    
    exp(2.0): produce
    exp(1.0): consume
    
    producer => produce
    produce => buffer
    produce => producer
    buffer => consume
    consume => consumer
    consume => consumer
end

# With guard condition (use place names directly)
@petrinet begin
    p1[5, 10]
    p2[0, 10]
    exp(1.0): t1
    p1 => t1
    t1 => p2
    guard(t1, m -> m.p1 >= 3, [p1])  # Only fire if p1 has >= 3 tokens
end

# Minimal example
@petrinet begin
    p1[1, 5]
    p2[0, 5]
    exp(1.0): t1
    p1 => t1
    t1 => p2
end
```
"""
macro petrinet(expr)
    return esc(_parse_petrinet(expr))
end

"""
Parse the petrinet macro body and generate code to construct the Petri net.
"""
function _parse_petrinet(expr)
    if expr.head != :block
        error("@petrinet expects a begin...end block")
    end
    
    places = []
    transitions = []
    arcs = []
    guards = []
    
    for line in expr.args
        # Skip line number nodes
        if isa(line, LineNumberNode)
            continue
        end
        
        # Skip empty lines
        if line == nothing || (isa(line, Expr) && line.head == :tuple && isempty(line.args))
            continue
        end
        
        # Parse place: name[initial, max]
        if isa(line, Expr) && line.head == :ref
            place_name = line.args[1]
            if length(line.args) == 3
                initial = line.args[2]
                maxmark = line.args[3]
                push!(places, (name=place_name, initial=initial, maxmark=maxmark))
            elseif length(line.args) == 2
                initial = line.args[2]
                push!(places, (name=place_name, initial=initial, maxmark=nothing))
            else
                error("Place syntax: name[initial, max] or name[initial]")
            end
        # Parse transition with type: exp(rate): name or imm(weight): name
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :(=>)
            # This is an arc definition
            lhs = line.args[2]
            rhs = line.args[3]
            
            # Check if multiplicity is specified: rhs => lhs [mult]
            mult = 1
            if isa(rhs, Expr) && rhs.head == :ref
                mult = rhs.args[2]
                rhs = rhs.args[1]
            end
            
            push!(arcs, (from=lhs, to=rhs, mult=mult))
        # Parse guard: guard(trans_name, func, [places...])
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :guard
            if length(line.args) < 3
                error("Guard syntax: guard(trans_name, function, [place1, place2, ...])")
            end
            trans_name = line.args[2]
            guard_func = line.args[3]
            guard_places = length(line.args) >= 4 ? line.args[4] : []
            
            # Convert guard_places to vector if it's not already
            if !isa(guard_places, Expr) || guard_places.head != :vect
                if guard_places != []
                    guard_places = [guard_places]
                else
                    guard_places = []
                end
            else
                guard_places = guard_places.args
            end
            
            push!(guards, (trans=trans_name, func=guard_func, places=guard_places))
        # Parse transition definition: type(param): name
        elseif isa(line, Expr) && line.head == :call && line.args[1] == :(:)
            trans_spec = line.args[2]
            trans_name = line.args[3]
            
            if isa(trans_spec, Expr) && trans_spec.head == :call
                trans_type = trans_spec.args[1]
                param = trans_spec.args[2]
                
                if trans_type == :exp
                    push!(transitions, (name=trans_name, type=:exp, param=param))
                elseif trans_type == :imm
                    push!(transitions, (name=trans_name, type=:imm, param=param))
                else
                    error("Unknown transition type: $trans_type. Use exp() or imm()")
                end
            else
                error("Transition syntax: exp(rate): name or imm(weight): name")
            end
        else
            error("Unrecognized syntax: $line")
        end
    end
    
    # Generate code to construct the Petri net
    code = quote
        pn = petri()
    end
    
    # Add places
    for p in places
        if p.maxmark === nothing
            # Default max to a large value if not specified
            push!(code.args, :($(p.name) = place(pn, $(String(p.name)), $(p.initial), 1000000)))
        else
            push!(code.args, :($(p.name) = place(pn, $(String(p.name)), $(p.initial), $(p.maxmark))))
        end
    end
    
    # Add transitions
    for t in transitions
        if t.type == :exp
            push!(code.args, :($(t.name) = exptrans(pn, $(String(t.name)), $(t.param))))
        elseif t.type == :imm
            push!(code.args, :($(t.name) = immtrans(pn, $(String(t.name)), $(t.param))))
        end
    end
    
    # Add arcs
    for a in arcs
        push!(code.args, :(arc(pn, $(a.from), $(a.to), mul=$(a.mult))))
    end
    
    # Add guards
    for g in guards
        places_array = Expr(:vect, g.places...)
        
        # Create a wrapper function that converts marking vector to named tuple
        # This allows users to write: m -> m.place_name >= 5
        # instead of: m -> m[1] >= 5
        place_names = [Symbol(String(p)) for p in g.places]
        place_indices = [findfirst(pl -> pl.name == p, places) for p in g.places]
        
        # Generate: (m_vec) -> begin m = (; place1=m_vec[i1], place2=m_vec[i2], ...); original_func(m) end
        namedtuple_expr = Expr(:tuple, [Expr(:(=), pname, :(m_vec[$(pidx)])) for (pname, pidx) in zip(place_names, place_indices)]...)
        wrapper_func = :(m_vec -> begin
            m = (; $(namedtuple_expr.args...))
            ($(g.func))(m)
        end)
        
        push!(code.args, :(guard($(g.trans), $(wrapper_func), $(places_array))))
    end
    
    # Return the Petri net
    push!(code.args, :pn)
    
    return code
end
