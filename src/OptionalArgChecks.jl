module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @mark, @elide#, @skipargcheck

"""
    @argcheck ex

Marks `ex` as an optional argument check, so when a function is called via
[`@skipargcheck`](@ref), `ex` will be omitted.

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
macro mark(label, ex)
    label isa Symbol || error("label has to be a Symbol")
    return Expr(
        :block,
        Expr(:meta, :begin_optional, label),
        esc(ex),
        Expr(:meta, :end_optional, label),
    )
end

struct ElideCheck{label}
    ElideCheck(label::Symbol) = new{label}()
end

@dynamo function (::ElideCheck{label})(x...) where {label}
    ir = IR(x...)
    ir === nothing && return
    next = iterate(ir)
    while next !== nothing
        (x, st), state = next
        if Meta.isexpr(st.expr, :meta) &&
            st.expr.args[1] === :begin_optional &&
            st.expr.args[2] === label

            orig = block(ir, x)
            delete!(ir, x)
            
            (x, st), state = iterate(ir, state)
            while !(Meta.isexpr(st.expr, :meta) &&
                st.expr.args[1] === :end_optional &&
                st.expr.args[2] === label)

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

macro elide(label, ex)
    label isa Symbol || error("label has to be a Symbol")
    ex = postwalk(ex) do x
        if Meta.isexpr(x, :call)
            pushfirst!(x.args, Expr(:call, GlobalRef(@__MODULE__, :ElideCheck), Expr(:quote, label)))
        end
        return x
    end
    return esc(ex)
end

"""
    @skipargcheck ex

For every function call in `ex`, expressions wrapped in [`@argcheck`](@ref) get omitted
recursively.
"""
macro skipargcheck(ex)
    return :(@elide argcheck $(esc(ex)))
end

end
