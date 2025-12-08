using PetriNet
using Documenter

DocMeta.setdocmeta!(PetriNet, :DocTestSetup, :(using PetriNet); recursive=true)

makedocs(;
    modules=[PetriNet],
    authors="Hiroyuki Okamura <okamu@hiroshima-u.ac.jp> and contributors",
    sitename="PetriNet.jl",
    format=Documenter.HTML(;
        canonical="https://okamumu.github.io/PetriNet.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/okamumu/PetriNet.jl",
    devbranch="main",
)
