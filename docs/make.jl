using PetriStructure
using Documenter

DocMeta.setdocmeta!(PetriStructure, :DocTestSetup, :(using PetriStructure); recursive=true)

makedocs(;
    modules=[PetriStructure],
    authors="Hiroyuki Okamura <okamu@hiroshima-u.ac.jp> and contributors",
    sitename="PetriStructure.jl",
    format=Documenter.HTML(;
        canonical="https://okamumu.github.io/PetriStructure.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/okamumu/PetriStructure.jl",
    devbranch="main",
)
