using OptionalArgChecks
using Documenter

DocMeta.setdocmeta!(OptionalArgChecks, :DocTestSetup, :(using OptionalArgChecks); recursive=true)

makedocs(;
    modules=[OptionalArgChecks],
    authors="Simeon Schaub",
    repo="https://github.com/simeonschaub/OptionalArgChecks.jl/blob/{commit}{path}#L{line}",
    sitename="OptionalArgChecks.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://simeonschaub.github.io/OptionalArgChecks.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/simeonschaub/OptionalArgChecks.jl",
)
