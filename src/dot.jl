"""
    todot(pn)

Return a Graphviz DOT description for Petri net `pn`.
"""
function todot(pn::PN)
    io = IOBuffer()
    visited = Set{Any}()
    println(io, "digraph { layout=dot; overlap=false; splines=true; node [fontsize=10];")
    number = 0
    for p in pn.places
        if !(p in visited)
            println(io, "subgraph cluster$number {")
            _draw(pn, io, p, visited)
            println(io, "}")
            number += 1
        end
    end
    for tr in pn.trans
        if !(tr in visited)
            println(io, "subgraph cluster$number {")
            _draw(pn, io, tr, visited)
            println(io, "}")
            number += 1
        end
    end
    println(io, "}")
    String(take!(io))
end

function _draw(pn::PN, io::IO, x::Place, visited)
    if x in visited
        return nothing
    end
    println(io, "\"obj$(objectid(x))\" [shape=circle,label=\"$(x.label)\"];")
    push!(visited, x)
    for a in x.inarcs
        _draw(pn, io, a, visited)
    end
    for a in x.outarcs
        _draw(pn, io, a, visited)
    end
end

function _draw(pn::PN, io::IO, x::ImmTrans, visited)
    if x in visited
        return nothing
    end
    println(io, "\"obj$(objectid(x))\" [shape=box,label=\"$(x.label)\", width=0.8, height=0.02, style=\"filled,dashed\"];")
    push!(visited, x)
    for a in x.inarcs
        _draw(pn, io, a, visited)
    end
    for a in x.outarcs
        _draw(pn, io, a, visited)
    end
end

function _draw(pn::PN, io::IO, x::ExpTrans, visited)
    if x in visited
        return nothing
    end
    println(io, "\"obj$(objectid(x))\" [shape=box,label=\"$(x.label)\", width=0.8, height=0.2];")
    push!(visited, x)
    for a in x.inarcs
        _draw(pn, io, a, visited)
    end
    for a in x.outarcs
        _draw(pn, io, a, visited)
    end
end

function _draw(pn::PN, io::IO, x::InArc, visited)
    if x in visited
        return nothing
    end
    label_text = x.mul == 1 ? "" : string(x.mul)
    println(io, "\"obj$(objectid(x.src))\"->\"obj$(objectid(x.dest))\" [label=\"$label_text\"];")
    push!(visited, x)
    _draw(pn, io, x.src, visited)
    _draw(pn, io, x.dest, visited)
end

function _draw(pn::PN, io::IO, x::OutArc, visited)
    if x in visited
        return nothing
    end
    label_text = x.mul == 1 ? "" : string(x.mul)
    println(io, "\"obj$(objectid(x.src))\"->\"obj$(objectid(x.dest))\" [label=\"$label_text\"];")
    push!(visited, x)
    _draw(pn, io, x.src, visited)
    _draw(pn, io, x.dest, visited)
end
