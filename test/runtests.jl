using Test
using OptionalArgChecks

@testset "argcheck" begin
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
    @test @skipargcheck(g(-1)) === nothing
    @test @skip(argcheck, g(-1)) === nothing
    @test g(1) === nothing

    g(x) = @check x > 0

    @test_throws Exception g(-1)
    @test @skipargcheck(g(-1)) === nothing
    @test @skip(argcheck, g(-1)) === nothing
    @test g(1) === nothing
end

@testset "mark skip" begin
    function simple()
        @mark return1 begin
            return 1
        end
        return 2
    end

    @test simple() === 1
    @test @skip(does_not_exist, simple()) === 1
    @test @skip(return1, simple()) === 2

    function indirect()
        simple()
    end

    @test indirect() === 1
    @test @skip(does_not_exist, indirect()) === 1
    @test @skip(return1, indirect()) === 2

    function complex()
        ret = Int[]
        push!(ret,1)
        @mark two begin
            push!(ret,2)
        end
        push!(ret, 3)
        @mark four begin
            push!(ret, 4)
        end
        ret
    end

    @test complex() == 1:4
    @test @skip(does_not_exist, complex()) == 1:4
    @test @skip(two, complex()) == [1,3,4]
    @test @skip(four, complex()) == [1,2,3]
    @test @skip([two, four], complex()) == [1,3]

    function nested()
        ret = Int[]
        @mark nested begin
            push!(ret, 1)
            @mark nested begin
                push!(ret,2)
            end
            push!(ret,3)
        end
        push!(ret, 4)
        ret
    end

    @test nested() == 1:4
    @test @skip(nested, nested()) == [4]

    function complex_nested()
        ret = Char[]
        push!(ret,'a')
        @mark bcdg begin
            push!(ret,'b')
            @mark cdh begin
                push!(ret,'c')
                @mark bcdg begin
                    push!(ret,'d')
                end
            end
        end
        push!(ret,'e')
        @mark fgh begin
            push!(ret,'f')
            @mark bcdg begin
                push!(ret,'g')
            end
            @mark cdh begin
                push!(ret,'h')
            end
        end
        ret
    end

    @test @skip([], complex_nested()) == 'a':'h'
    @test @skip([bcdg], complex_nested()) == collect("aefh")
    @test @skip([cdh], complex_nested()) == collect("abefg")
    @test @skip([fgh], complex_nested()) == 'a':'e'
    @test @skip([bcdg, cdh], complex_nested()) == collect("aef")
    @test @skip([fgh, cdh], complex_nested()) == collect("abe")
    @test @skip([bcdg, cdh, fgh], complex_nested()) == collect("ae")
end

using Documenter
DocMeta.setdocmeta!(OptionalArgChecks, :DocTestSetup, :(using OptionalArgChecks); recursive=true)
doctest(OptionalArgChecks; manual = false)
