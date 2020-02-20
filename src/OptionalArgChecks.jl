module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @mark, @skip, @unsafe_skipargcheck

# reexport @argcheck and @check
using ArgCheck: @argcheck, @check, LABEL_ARGCHECK
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

struct Skip{labels,recursive}
    Skip(labels...; recursive=true) = new{labels,recursive}()
end

@dynamo function (::Skip{labels,recursive})(x...) where {labels,recursive}
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

    recursive && recurse!(ir)
    return ir
end

function _skip(l, ex, recursive=true)
    labels::Vector{Symbol} = if l isa Symbol
        [l]
    elseif Meta.isexpr(l, :vect)
        labels = l.args
    else
        error("label has to be a name or array of names")
    end
    return _skip(labels, ex, recursive)
end

function _skip(labels::Vector, ex, recursive)
    ex = postwalk(ex) do x
        if Meta.isexpr(x, :call)
            pushfirst!(x.args, Expr(
                :call,
                GlobalRef(@__MODULE__, :Skip),
                Expr(:parameters, Expr(:kw, :recursive, recursive)),
                Expr.(:quote, labels)...
            ))
        end
        return x
    end
    return esc(ex)
end

"""
    @skip label ex[[ recursive=true]]
    @skip [label1, label2, ...] ex[[ recursive=true]]

For every function call in `ex`, expressions marked with label `label` (or any of the labels
`label*` respectively) using the macro [`@mark`](@ref) get omitted recursively.
"""
macro skip end

macro skip(l, ex)
    return _skip(l, ex, true)
end

macro skip(l, ex, r)
    r = parse_recursive(r)
    return _skip(l, ex, r)
end

function parse_recursive(r)::Bool
    Meta.isexpr(r, :(=)) || error("expected keyword argument instead of `$r`")
    argname = r.args[1]
    argname == :recursive || error("unknown kewyword argument `$argname`")
    recursive = r.args[2]
    recursive isa Bool || error("keyword argument `recursive` has to be a `Bool` literal")
    return recursive
end

"""
    @unsafe_skipargcheck ex[[ recursive=true]]

Elides argument checks created with [`@argcheck`](@ref) or [`@check`](@ref),
provided by the package `ArgCheck.jl`.
"""
macro unsafe_skipargcheck(ex)
    return _skip([LABEL_ARGCHECK], ex, true)
end

macro unsafe_skipargcheck(ex, r)
    r = parse_recursive(r)
    return _skip([LABEL_ARGCHECK], ex, r)
end

end
