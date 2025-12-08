using EzXML

"""
    load_pnml(path)
    load_pnml(io::IO)

Load a PNML file or IO stream and return a `PN`.
Supports places with `initialMarking`, `ddOrder` (used as level), `bound` (max tokens),
and transitions with `rate`, `timed` (true -> exponential), `infiniteServer` (ignored for now).
Arc `inscription` is treated as multiplicity (default 1).
"""
function load_pnml(fn::AbstractString)
    doc = readxml(fn)
    _parse_pnml_doc(doc)
end

function load_pnml(io::IO)
    doc = readxml(io)
    _parse_pnml_doc(doc)
end

function _parse_pnml_doc(doc)
    places = Vector{Dict{String,Any}}()
    for x in findall("//net/place", root(doc))
        elem = Dict{String,Any}()
        elem["id"] = x["id"]
        for y in eachelement(x)
            if y.name == "initialMarking"
                for z in eachelement(y)
                    elem["initialMarking"] = parse(Int, nodecontent(z))
                end
            elseif y.name == "ddOrder"
                for z in eachelement(y)
                    elem["ddOrder"] = parse(Int, nodecontent(z))
                end
            elseif y.name == "bound"
                for z in eachelement(y)
                    elem["bound"] = parse(Int, nodecontent(z))
                end
            end
        end
        push!(places, elem)
    end
    sort!(places, by = p -> get(p, "ddOrder", typemax(Int)))

    trans = Vector{Dict{String,Any}}()
    for x in findall("//net/transition", root(doc))
        elem = Dict{String,Any}()
        elem["id"] = x["id"]
        for y in eachelement(x)
            if y.name == "rate"
                for z in eachelement(y)
                    elem["rate"] = parse(Float64, nodecontent(z))
                end
            elseif y.name == "timed"
                for z in eachelement(y)
                    elem["timed"] = parse(Bool, lowercase(nodecontent(z)))
                end
            elseif y.name == "infiniteServer"
                for z in eachelement(y)
                    elem["infiniteServer"] = parse(Bool, lowercase(nodecontent(z)))
                end
            end
        end
        push!(trans, elem)
    end

    arcs = Vector{Dict{String,Any}}()
    for x in findall("//net/arc", root(doc))
        elem = Dict{String,Any}()
        elem["id"] = x["id"]
        elem["source"] = x["source"]
        elem["target"] = x["target"]
        for y in eachelement(x)
            if y.name == "inscription"
                for z in eachelement(y)
                    elem["inscription"] = parse(Int, nodecontent(z))
                end
            end
        end
        push!(arcs, elem)
    end

    pn = petri()
    objects = Dict{String,Any}()

    for p in places
        init = get(p, "initialMarking", 0)
        bound = get(p, "bound", init)
        level = get(p, "ddOrder", 0)
        obj = place(pn, p["id"], init, bound; level = level)
        objects[p["id"]] = obj
    end

    for t in trans
        timed = get(t, "timed", true)
        rate = get(t, "rate", 1.0)
        level = 0
        obj = timed ? exptrans(pn, t["id"], rate; level = level) : immtrans(pn, t["id"], rate; level = level)
        objects[t["id"]] = obj
    end

    for a in arcs
        mul = get(a, "inscription", 1)
        src = objects[a["source"]]
        dst = objects[a["target"]]
        arc(pn, src, dst; mul = mul)
    end

    pn
end

