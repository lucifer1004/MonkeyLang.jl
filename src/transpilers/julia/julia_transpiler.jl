module JuliaTranspiler

using ...MonkeyLang

transpile(program::MonkeyLang.Program; input::IO = stdin, output::IO = stdout)::Expr = quote
    # Define wrappers
    __IS_TRUTHY(a) = a != false && a != nothing
    __IS_FALSY(a) = !__IS_TRUTHY(a)

    __WRAPPED_GETINDEX(v::Vector, id::Int) = 0 <= id < length(v) ? v[id+1] : nothing
    __WRAPPED_GETINDEX(d::Dict, key) = get(d, key, nothing)

    __WRAPPED_STRING(a) = Base.string(a)
    __WRAPPED_STRING(::Nothing) = "null"
    __WRAPPED_STRING(s::String) = "\"" * s * "\""
    __WRAPPED_STRING(d::Dict) =
        "{" *
        join(
            map(
                x -> __WRAPPED_STRING(x.first) * ": " * __WRAPPED_STRING(x.second),
                collect(d),
            ),
            ", ",
        ) *
        "}"
    __WRAPPED_STRING(v::Vector) = "[" * join(map(__WRAPPED_STRING, v), ", ") * "]"
    Base.:(+)(a::String, b::String) = a * b

    # Define builtins
    __JULIA_FIRST = Base.first
    __JULIA_LAST = Base.last

    type(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
    )
    type(::String) = "STRING"
    type(::Int) = "INTEGER"
    type(::Bool) = "BOOLEAN"
    type(::Nothing) = "NULL"
    type(::Vector) = "ARRAY"
    type(::Dict) = "HASH"
    type(::Function) = "FUNCTION"

    len(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
    )
    len(arg::Any) =
        error("argument error: argument to `len` is not supported, got $(type(arg))")
    len(s::String) = length(s)
    len(v::Vector) = length(v)
    len(d::Dict) = length(d)

    first(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
    )
    first(arg::Any) =
        error("argument error: argument to `first` is not supported, got $(type(arg))")
    first(s::String) = length(s) >= 1 ? string(__JULIA_FIRST(s)) : nothing
    first(v::Vector) = length(v) >= 1 ? __JULIA_FIRST(v) : nothing

    last(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
    )
    last(arg::Any) =
        error("argument error: argument to `last` is not supported, got $(type(arg))")
    last(s::String) = length(s) >= 1 ? string(__JULIA_LAST(s)) : nothing
    last(v::Vector) = length(v) >= 1 ? __JULIA_LAST(v) : nothing

    rest(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
    )
    rest(arg::Any) =
        error("argument error: argument to `rest` is not supported, got $(type(arg))")
    rest(s::String) = length(s) >= 1 ? s[iterate(s)[2]:end] : nothing
    rest(v::Vector) = length(v) >= 1 ? v[2:end] : nothing

    push(args...) = error(
        "argument error: wrong number of arguments. Got $(length(args)) instead of 2 or 3",
    )
    push(arg::Any, _) =
        error("argument error: argument to `push` is not supported, got $(type(arg))")
    push(v::Vector, ele) = [v..., ele]
    push(arg::Any, _, _) =
        error("argument error: argument to `push` is not supported, got $(type(arg))")
    push(d::Dict, key, val) = Dict(d..., key => val)

    puts(args...) =
        for arg in args
            if isa(arg, String)
                println($output, arg)
            else
                println($output, __WRAPPED_STRING(arg))
            end
        end

    let
        try
            $(map(transpile, program.statements)...)
        catch e
            msg = if isa(e, UndefVarError)
                "identifier not found: $(e.var)"
            elseif isa(e, DivideError)
                "divide error: division by zero"
            elseif isa(e, MethodError)
                if !isa(e.f, Function)
                    "not a function: $(type(e.f))"
                elseif e.f == __WRAPPED_GETINDEX
                    c = e.args[1]
                    k = e.args[2]
                    if isa(c, Vector)
                        "unsupported index type: $(type(k))"
                    else
                        "index operator not supported: $(type(c))"
                    end
                elseif length(e.args) == 1 && e.f ∈ [!, -]
                    "unknown operator: $(e.f)$(type(e.args[1]))"
                elseif length(e.args) == 2 && e.f ∈ [+, -, *, /, (==), !=, <, >]
                    t1 = type(e.args[1])
                    t2 = type(e.args[2])
                    if t1 != t2
                        "type mismatch: $t1 $(e.f) $t2"
                    else
                        "unknown operator: $(type(e.args[1])) $(e.f) $(type(e.args[2]))"
                    end
                else
                    "argument error: wrong number of arguments: got $(length(e.args))"
                end
            else
                hasproperty(e, :msg) ? e.msg : string(e)
            end

            println($output, "ERROR: $msg")
        end
    end
end

transpile(bs::MonkeyLang.BlockStatement)::Expr = quote
    $(map(transpile, bs.statements)...)
end

transpile(::MonkeyLang.BreakStatement)::Expr = Expr(:break)

transpile(::MonkeyLang.ContinueStatement)::Expr = Expr(:continue)

transpile(es::MonkeyLang.ExpressionStatement) = transpile(es.expression)

transpile(ls::MonkeyLang.LetStatement)::Expr = begin
    value = transpile(ls.value)

    if isa(value, Expr) && value.head == :function
        parameters = value.args[1].args
        body = value.args[2]
        Expr(:function, Expr(:call, Symbol(ls.name.value), parameters...), body)
    else
        Expr(:(=), Symbol(ls.name.value), value)
    end
end

transpile(rs::MonkeyLang.ReturnStatement)::Expr = Expr(:return, transpile(rs.return_value))

transpile(ws::MonkeyLang.WhileStatement)::Expr =
    Expr(:while, simplify_condition(ws.condition), transpile(ws.body))

transpile(ie::MonkeyLang.InfixExpression)::Expr = begin
    op = ie.operator == "/" ? "÷" : ie.operator
    Expr(:call, Symbol(op), transpile(ie.left), transpile(ie.right))
end

transpile(pe::MonkeyLang.PrefixExpression)::Expr =
    if pe.operator == "!"
        Expr(:call, :__IS_FALSY, transpile(pe.right))
    else
        Expr(:call, Symbol(pe.operator), transpile(pe.right))
    end

transpile(ident::MonkeyLang.Identifier)::Symbol = Symbol(ident.value)

transpile(::Union{Nothing,MonkeyLang.NullLiteral})::Nothing = nothing

transpile(il::MonkeyLang.IntegerLiteral)::Int = il.value

transpile(bl::MonkeyLang.BooleanLiteral)::Bool = bl.value

transpile(sl::MonkeyLang.StringLiteral)::String = sl.value

transpile(al::MonkeyLang.ArrayLiteral)::Expr = Expr(:vect, map(transpile, al.elements)...)

transpile(hl::MonkeyLang.HashLiteral)::Expr = begin
    pairs = []
    for (k, v) in hl.pairs
        k = transpile(k)
        v = transpile(v)
        push!(pairs, :($k => $v))
    end

    Expr(:call, :Dict, pairs...)
end

transpile(fl::MonkeyLang.FunctionLiteral)::Expr = begin
    params = []
    for p in fl.parameters
        push!(params, Symbol(p.value))
    end

    body = transpile(fl.body)

    Expr(:function, :(($(params...),)), body)
end

transpile(ce::MonkeyLang.CallExpression)::Expr =
    Expr(:call, transpile(ce.fn), map(transpile, ce.arguments)...)

transpile(ce::MonkeyLang.IndexExpression)::Expr =
    Expr(:call, :__WRAPPED_GETINDEX, transpile(ce.left), transpile(ce.index))

transpile(ie::MonkeyLang.IfExpression)::Expr = Expr(
    :if,
    simplify_condition(ie.condition),
    transpile(ie.consequence),
    transpile(ie.alternative),
)

transpile(code::String; input::IO = stdin, output::IO = stdout) = begin
    raw_program = MonkeyLang.parse(code; input, output)
    if !isnothing(raw_program)
        macro_env = MonkeyLang.Environment(; input, output)
        program = MonkeyLang.define_macros!(macro_env, raw_program)
        expanded = MonkeyLang.expand_macros(program, macro_env)

        syntax_check_result = MonkeyLang.analyze(expanded)
        if isa(syntax_check_result, MonkeyLang.ErrorObj)
            println(output, syntax_check_result)
            return nothing
        end

        return transpile(expanded; input, output)
    end
end

simplify_condition(condition) = begin
    condition = transpile(condition)

    if isa(condition, Expr)
        if !(condition.head == :call && condition.args[1] ∈ [:<, :>, :(==), :!=])
            condition = Expr(:call, :__IS_TRUTHY, condition)
        end
    else
        condition = condition != false && !isnothing(condition)
    end

    return condition
end

run(code::String; input::IO = stdin, output::IO = stdout) = begin
    julia_program = transpile(code; input, output)
    if !isnothing(julia_program)
        eval(julia_program)
    end
end

macro monkey_julia_str(code::String)
    :(run($code))
end

end
