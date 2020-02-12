module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @mark, @elide, @skipargcheck

# reexport @argcheck and @check
using ArgCheck: @argcheck, @check
export @argcheck, @check

"""
    @mark label ex

Marks `ex` as an optional argument check, so when a function is called via
[`@elide`](@ref) with label `label`, `ex` will be omitted.

```jldoctest
julia> function half(x::Integer)
           @mark check_even iseven(x) || throw(DomainError(x, "x has to be an even number"))
           return x ÷ 2
       end
half (generic function with 1 method)

julia> half(4)
2

julia> half(3)
ERROR: DomainError with 3:
x has to be an even number
[...]

julia> @elide check_even half(3)
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

"""
    @elide label ex

For every function call in `ex`, expressions marked with label `label` using the macro
[`@mark`](@ref) get omitted recursively.
"""
macro elide(label, ex)
    label isa Symbol || error("label has to be a Symbol")
    ex = postwalk(ex) do x
        if Meta.isexpr(x, :call)
            pushfirst!(x.args, Expr(
                :call,
                GlobalRef(@__MODULE__, :ElideCheck),
                Expr(:quote, label)
            ))
        end
        return x
    end
    return esc(ex)
end

"""
    @skipargcheck ex

Elides argument checks created with [`@argcheck`](@ref) or [`@check`](@ref), provided by the
package `ArgCheck.jl`. Is equivalent to `@elide argcheck ex`.
"""
macro skipargcheck(ex)
    return :(@elide argcheck $(esc(ex)))
end

end
