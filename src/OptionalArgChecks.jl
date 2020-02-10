module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @argcheck, @skipargcheck

"""
    @argcheck ex

Marks `ex` as an optional argument check, so when a function is called via
[`@skipargcheck`](@ref), `ex` will be omitted.

```@meta
DocTestSetup = :(using OptionalArgChecks)
```
```jldoctest
julia> function half(x::Integer)
           @argcheck iseven(x) || throw(DomainError(x, "x has to be an even number"))
           return x ÷ 2
       end
half (generic function with 1 method)

julia> half(4)
2

julia> half(3)
ERROR: DomainError with 3:
x has to be an even number
[...]

julia> @skipargcheck half(3)
1
```
"""
macro argcheck(ex)
    return Expr(:block, Expr(:meta, :begin_argcheck), esc(ex), Expr(:meta, :end_argcheck))
end

@dynamo function skipargcheck(x...)
    ir = IR(x...)
    ir === nothing && return
    next = iterate(ir)
    while next !== nothing
        (x, st), state = next
        if Meta.isexpr(st.expr, :meta) && st.expr.args[1] === :begin_argcheck
            orig = block(ir, x)
            delete!(ir, x)
            
            (x, st), state = iterate(ir, state)
            while !(Meta.isexpr(st.expr, :meta) && st.expr.args[1] === :end_argcheck)
                delete!(ir, x)
                (x, st), state = iterate(ir, state)
            end
            
            dest = block(ir, x)
            if orig != dest
                empty!(branches(orig))
                branch!(orig, dest)
            end
            delete!(ir, x)
        end
        next = iterate(ir, state)
    end
    recurse!(ir)
    return ir
end

"""
    @skipargcheck ex

For every function call in `ex`, expressions wrapped in [`@argcheck`](@ref) get omitted
recursively.
"""
macro skipargcheck(ex)
    ex = postwalk(ex) do x
        if Meta.isexpr(x, :call)
            pushfirst!(x.args, GlobalRef(@__MODULE__, :skipargcheck))
        end
        return x
    end
    return esc(ex)
end

end
