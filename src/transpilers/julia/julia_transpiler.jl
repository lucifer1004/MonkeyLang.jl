module JuliaTranspiler

using ...MonkeyLang

# Static helper functions - defined once at module load time
__IS_TRUTHY(a) = a != false && a !== nothing
__IS_FALSY(a) = !__IS_TRUTHY(a)

__WRAPPED_GETINDEX(v::Vector, id::Int) = 0 <= id < length(v) ? v[id + 1] : nothing
__WRAPPED_GETINDEX(d::Dict, key) = get(d, key, nothing)

__WRAPPED_STRING(a) = Base.string(a)
__WRAPPED_STRING(::Nothing) = "null"
__WRAPPED_STRING(s::String) = "\"" * s * "\""
function __WRAPPED_STRING(d::Dict)
    "{" *
    join(map(x -> __WRAPPED_STRING(x.first) * ": " * __WRAPPED_STRING(x.second),
             collect(d)),
         ", ") *
    "}"
end
__WRAPPED_STRING(v::Vector) = "[" * join(map(__WRAPPED_STRING, v), ", ") * "]"

# String concatenation operator - defined once at module load time
Base.:(+)(a::String, b::String) = a * b

# Builtin implementations
const __JULIA_FIRST = Base.first
const __JULIA_LAST = Base.last

function __type(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
end
__type(::String) = "STRING"
__type(::Int) = "INTEGER"
__type(::Bool) = "BOOLEAN"
__type(::Nothing) = "NULL"
__type(::Vector) = "ARRAY"
__type(::Dict) = "HASH"
__type(::Function) = "FUNCTION"

function __len(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
end
function __len(arg::Any)
    error("argument error: argument to `len` is not supported, got $(__type(arg))")
end
__len(s::String) = length(s)
__len(v::Vector) = length(v)
__len(d::Dict) = length(d)

function __first(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
end
function __first(arg::Any)
    error("argument error: argument to `first` is not supported, got $(__type(arg))")
end
__first(s::String) = length(s) >= 1 ? string(__JULIA_FIRST(s)) : nothing
__first(v::Vector) = length(v) >= 1 ? __JULIA_FIRST(v) : nothing

function __last(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
end
function __last(arg::Any)
    error("argument error: argument to `last` is not supported, got $(__type(arg))")
end
__last(s::String) = length(s) >= 1 ? string(__JULIA_LAST(s)) : nothing
__last(v::Vector) = length(v) >= 1 ? __JULIA_LAST(v) : nothing

function __rest(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
end
function __rest(arg::Any)
    error("argument error: argument to `rest` is not supported, got $(__type(arg))")
end
__rest(s::String) = length(s) >= 1 ? s[iterate(s)[2]:end] : nothing
__rest(v::Vector) = length(v) >= 1 ? v[2:end] : nothing

function __push(args...)
    error("argument error: wrong number of arguments. Got $(length(args)) instead of 2 or 3")
end
function __push(arg::Any, _)
    error("argument error: argument to `push` is not supported, got $(__type(arg))")
end
__push(v::Vector, ele) = [v..., ele]
function __push(arg::Any, _, _)
    error("argument error: argument to `push` is not supported, got $(__type(arg))")
end
__push(d::Dict, key, val) = Dict(d..., key => val)

# puts takes output as first parameter
function __puts(output::IO, args...)
    for arg in args
        if isa(arg, String)
            println(output, arg)
        else
            println(output, __WRAPPED_STRING(arg))
        end
    end
end

transpile(program::MonkeyLang.Program; input::IO = stdin, output::IO = stdout)::Expr = quote
    # Create local aliases for builtins with Monkey names
    # These are simple assignments, not method definitions
    local type = $__type
    local len = $__len
    local first = $__first
    local last = $__last
    local rest = $__rest
    local push = $__push
    # puts is a special case - it needs to capture the output
    local __output_ref = $output
    local puts = (args...) -> $__puts(__output_ref, args...)

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
                    "not a function: $($__type(e.f))"
                elseif e.f == $__WRAPPED_GETINDEX
                    c = e.args[1]
                    k = e.args[2]
                    if isa(c, Vector)
                        "unsupported index type: $($__type(k))"
                    else
                        "index operator not supported: $($__type(c))"
                    end
                elseif length(e.args) == 1 && e.f ∈ [!, -]
                    "unknown operator: $(e.f)$($__type(e.args[1]))"
                elseif length(e.args) == 2 && e.f ∈ [+, -, *, /, (==), !=, <, >]
                    t1 = $__type(e.args[1])
                    t2 = $__type(e.args[2])
                    if t1 != t2
                        "type mismatch: $t1 $(e.f) $t2"
                    else
                        "unknown operator: $($__type(e.args[1])) $(e.f) $($__type(e.args[2]))"
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

transpile(ws::MonkeyLang.WhileStatement)::Expr = Expr(:while,
                                                      simplify_condition(ws.condition),
                                                      transpile(ws.body))

transpile(ie::MonkeyLang.InfixExpression)::Expr = begin
    op = ie.operator == "/" ? "÷" : ie.operator
    Expr(:call, Symbol(op), transpile(ie.left), transpile(ie.right))
end

transpile(pe::MonkeyLang.PrefixExpression)::Expr =
    if pe.operator == "!"
        Expr(:call, :($__IS_FALSY), transpile(pe.right))
    else
        Expr(:call, Symbol(pe.operator), transpile(pe.right))
    end

transpile(ident::MonkeyLang.Identifier)::Symbol = Symbol(ident.value)

transpile(::Union{Nothing, MonkeyLang.NullLiteral})::Nothing = nothing

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

transpile(ce::MonkeyLang.CallExpression)::Expr = Expr(:call, transpile(ce.fn),
                                                      map(transpile, ce.arguments)...)

transpile(ce::MonkeyLang.IndexExpression)::Expr = Expr(:call, :($__WRAPPED_GETINDEX),
                                                       transpile(ce.left),
                                                       transpile(ce.index))

transpile(ie::MonkeyLang.IfExpression)::Expr = Expr(:if,
                                                    simplify_condition(ie.condition),
                                                    transpile(ie.consequence),
                                                    transpile(ie.alternative))

function transpile(code::String; input::IO = stdin, output::IO = stdout)
    begin
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
end

function simplify_condition(condition)
    begin
        condition = transpile(condition)

        if isa(condition, Expr)
            if !(condition.head == :call && condition.args[1] ∈ [:<, :>, :(==), :!=])
                condition = Expr(:call, :($__IS_TRUTHY), condition)
            end
        else
            condition = condition != false && !isnothing(condition)
        end

        return condition
    end
end

function run(code::String; input::IO = stdin, output::IO = stdout)
    begin
        julia_program = transpile(code; input, output)
        if !isnothing(julia_program)
            eval(julia_program)
        end
    end
end

macro monkey_julia_str(code::String)
    quote
        run($(esc(Meta.parse("\"$(escape_string(code))\""))))
    end
end

end
