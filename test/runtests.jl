using Test
using OptionalArgChecks

function f(x)
    @mark argcheck x<2 && if x == 1
        return "foo"
    else
        error("Test")
    end
    return x + 3
end

for x in 0:2
    @test @skipargcheck f(x) == x + 3
end

g(x) = @argcheck x > 0

@test_throws ArgumentError g(-1)
@test g(1) === nothing

using Documenter
DocMeta.setdocmeta!(OptionalArgChecks, :DocTestSetup, :(using OptionalArgChecks); recursive=true)
doctest(OptionalArgChecks; manual = false)
