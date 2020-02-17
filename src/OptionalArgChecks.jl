module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @mark, @skip, @skipargcheck

# reexport @argcheck and @check
using ArgCheck: @argcheck, @check
export @argcheck, @check

"""
    @mark label ex

Marks `ex` as an optional argument check, so when a function is called via
[`@skip`](@ref) with label `label`, `ex` will be omitted.

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

julia> @skip check_even half(3)
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

struct Skip{labels}
    Skip(labels::Symbol...) = new{labels}()
end

@dynamo function (::Skip{labels})(x...) where {labels}
    ir = IR(x...)
    ir === nothing && return

    tape = ()
    local orig

    for (x, st) in ir
        is_layer_begin = Meta.isexpr(st.expr, :meta) &&
            st.expr.args[1] === :begin_optional &&
            st.expr.args[2] in labels
        is_layer_end =  Meta.isexpr(st.expr, :meta) &&
            st.expr.args[1] === :end_optional &&
            !isempty(tape) && st.expr.args[2] === last(tape)

        if is_layer_begin
            tape = (tape..., st.expr.args[2])
        elseif is_layer_end
            tape = Base.front(tape)
        end

        is_begin = is_layer_begin && length(tape) == 1
        is_end   = is_layer_end   && isempty(tape)

        if is_begin
            orig = block(ir, x)
        elseif is_end
            dest = block(ir, x)
            if orig != dest
                empty!(branches(orig))
                branch!(orig, dest)
            end
        end

        if is_layer_begin || is_layer_end || !isempty(tape)
            delete!(ir, x)
        end
    end

    @assert isempty(tape)

    recurse!(ir)
    return ir
end

"""
    @skip label ex
    @skip [label1, label2, ...] ex

For every function call in `ex`, expressions marked with label `label` (or any of the labels
`label*` respectively) using the macro [`@mark`](@ref) get omitted recursively.
"""
macro skip(l, ex)
    if l isa Symbol
        labels = [l]
    elseif Meta.isexpr(l, :vect)
        labels::Vector{Symbol} = l.args
    else
        error("label has to be a name or array of names")
    end

    ex = postwalk(ex) do x
        if Meta.isexpr(x, :call)
            pushfirst!(x.args, Expr(
                :call,
                GlobalRef(@__MODULE__, :Skip),
                Expr.(:quote, labels)...
            ))
        end
        return x
    end
    return esc(ex)
end

"""
    @skipargcheck ex

Elides argument checks created with [`@argcheck`](@ref) or [`@check`](@ref), provided by the
package `ArgCheck.jl`. Is equivalent to `@skip argcheck ex`.
"""
macro skipargcheck(ex)
    return :(@skip argcheck $(esc(ex)))
end

end
