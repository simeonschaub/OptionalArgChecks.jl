module OptionalArgChecks

using IRTools: @dynamo, IR, recurse!, block, branches, branch!
using MacroTools: postwalk

export @argcheck, @skipargcheck

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
