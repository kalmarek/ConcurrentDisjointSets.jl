using LockFreeDisjointSet
using Documenter

DocMeta.setdocmeta!(LockFreeDisjointSet, :DocTestSetup, :(using LockFreeDisjointSet); recursive=true)

makedocs(;
    modules=[LockFreeDisjointSet],
    authors="Marek Kaluba <kalmar@mailbox.org>",
    repo="https://github.com/kalmarek/LockFreeDisjointSet.jl/blob/{commit}{path}#{line}",
    sitename="LockFreeDisjointSet.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kalmarek.github.io/LockFreeDisjointSet.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kalmarek/LockFreeDisjointSet.jl",
    devbranch="main",
)
