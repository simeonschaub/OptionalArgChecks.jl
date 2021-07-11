using Test
using OptionalArgChecks

module A
    struct MyLabel end
end
using .A: MyLabel
const alias_AMyLabel = A.MyLabel()

module B
    struct MyLabel end
end
struct MyMainLabel end
myone = 1

@testset "non symbolic labels" begin
    function f1()
        @mark 1 begin
            return :executed
        end
        return :skipped
    end
    function fMyMainLabel()
        @mark MyMainLabel() begin
            return :executed
        end
        return :skipped
    end
    function fAMyLabel()
        @mark A.MyLabel() begin
            return :executed
        end
        return :skipped
    end
    @test @skip(1, f1())    == :skipped
    @test @skip(1.0, f1())  == :skipped
    @test @skip(myone,f1()) == :skipped
    @test @skip(2-1,f1())   == :skipped
    @test @skip(1:3,f1())   == :skipped
    @test @skip(2:3,f1()) == :executed
    @test @skip(2,f1()) == :executed
    @test @skip(MyMainLabel(),f1()) == :executed
    @test @skip(:one,f1()) == :executed
    @test @skip(A.MyLabel(),f1()) == :executed

    @test @skip(A.MyLabel(), fAMyLabel()) == :skipped
    @test @skip(MyLabel(), fAMyLabel()) == :skipped
    @test @skip(alias_AMyLabel, fAMyLabel()) == :skipped
    @test @skip([A.MyLabel(), 1], fAMyLabel()) == :skipped
    @test @skip(B.MyLabel(), fAMyLabel()) == :executed
    @test @skip(:MyLabel, fAMyLabel()) == :executed
    @test @skip(1, fAMyLabel()) == :executed
end

@testset "argcheck" begin
    function f(x)
        @mark :argcheck x<2 && if x == 1
            return "foo"
        else
            error("Test")
        end
        return x + 3
    end

    for x in 0:2
        @test @skip :argcheck f(x) == x + 3
    end

    g(x) = @argcheck x > 0

    @test_throws ArgumentError g(-1)
    @test @unsafe_skipargcheck(g(-1)) === nothing
    @test_throws ArgumentError @skip(:argcheck, g(-1)) === nothing
    @test g(1) === nothing

    g(x) = @check x > 0

    @test_throws Exception g(-1)
    @test @unsafe_skipargcheck(g(-1)) === nothing
    @test_throws Exception @skip(:argcheck, g(-1)) === nothing
    @test g(1) === nothing

    outer(x) = inner(x)
    inner(x) = (@argcheck x; return x)
    @test @unsafe_skipargcheck(inner(true)) == true
    @test @unsafe_skipargcheck(inner(false)) == false
    @test @unsafe_skipargcheck(inner(false), recursive=true) == false
    @test @unsafe_skipargcheck(inner(false), recursive=false) == false

    @test @unsafe_skipargcheck(outer(true)) == true
    @test @unsafe_skipargcheck(outer(false)) == false
    @test @unsafe_skipargcheck(outer(false), recursive=true) == false
    @test_throws ArgumentError @unsafe_skipargcheck(outer(false), recursive=false)
end

@testset "mark skip" begin
    function simple()
        @mark :return1 begin
            return 1
        end
        return 2
    end

    @test simple() === 1
    @test @skip(:does_not_exist, simple()) === 1
    @test @skip(:return1, simple()) === 2

    # @test_throws LoadError eval(:(@skip(2 + 3, simple())))
    @skip(2 + 3, simple())

    function indirect()
        simple()
    end

    @test indirect() === 1
    @test @skip(:does_not_exist, indirect()) === 1
    @test @skip(:return1, indirect()) === 2

    function complex()
        ret = Int[]
        push!(ret,1)
        @mark :two begin
            push!(ret,2)
        end
        push!(ret, 3)
        @mark :four begin
            push!(ret, 4)
        end
        ret
    end

    @test complex() == 1:4
    @test @skip(:does_not_exist, complex()) == 1:4
    @test @skip(:two, complex()) == [1,3,4]
    @test @skip(:four, complex()) == [1,2,3]
    @test @skip([:two, :four], complex()) == [1,3]

    function nested()
        ret = Int[]
        @mark :nested begin
            push!(ret, 1)
            @mark :nested begin
                push!(ret,2)
            end
            push!(ret,3)
        end
        push!(ret, 4)
        ret
    end

    @test nested() == 1:4
    @test @skip(:nested, nested()) == [4]

    function complex_nested()
        ret = Char[]
        push!(ret,'a')
        @mark :bcdg begin
            push!(ret,'b')
            @mark :cdh begin
                push!(ret,'c')
                @mark :bcdg begin
                    push!(ret,'d')
                end
            end
        end
        push!(ret,'e')
        @mark :fgh begin
            push!(ret,'f')
            @mark :bcdg begin
                push!(ret,'g')
            end
            @mark :cdh begin
                push!(ret,'h')
            end
        end
        ret
    end

    @test @skip([], complex_nested()) == 'a':'h'
    @test @skip([:bcdg], complex_nested()) == collect("aefh")
    @test @skip([:cdh], complex_nested()) == collect("abefg")
    @test @skip([:fgh], complex_nested()) == 'a':'e'
    @test @skip([:bcdg, :cdh], complex_nested()) == collect("aef")
    @test @skip([:fgh,  :cdh], complex_nested()) == collect("abe")
    @test @skip([:bcdg, :cdh, :fgh], complex_nested()) == collect("ae")
end

@testset "recursion through function calls" begin
    function inner()
        ret = Int[]
        push!(ret, 2)
        @mark :three begin
            push!(ret, 3)
        end
        ret
    end

    function outer()
        ret = Int[]
        push!(ret, 1)
        x = inner()
        append!(ret, x)
        @mark :four begin
            push!(ret, 4)
        end
        push!(ret, 5)
        ret
    end

    @test outer() == 1:5
    @test @skip(:four, outer(), recursive=true) == [1,2,3,5]
    @test @skip(:four, outer(), recursive=false) == [1,2,3,5]
    @test @skip(:three, outer(), recursive=true) == [1,2,4,5]
    @test @skip(:three, outer(), recursive=false) == 1:5
    @test @skip([:three, :four], outer()) == [1,2,5]
    @test @skip([:three, :four], outer(), recursive=false) == [1,2,3,5]
end

using Documenter
DocMeta.setdocmeta!(OptionalArgChecks, :DocTestSetup, :(using OptionalArgChecks); recursive=true)
doctest(OptionalArgChecks; manual = false)
