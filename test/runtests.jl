using Test
using OptionalArgChecks

function f(x)
    @argcheck x<2 && if x == 1
        return "foo"
    else
        error("Test")
    end
    return x + 3
end

for x in 0:2
    @test @skipargcheck f(x) == x + 3
end
