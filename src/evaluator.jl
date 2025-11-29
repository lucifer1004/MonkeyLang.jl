macro monkey_eval_str(code::String)
    quote
        evaluate($(esc(Meta.parse("\"$(escape_string(code))\""))))
    end
end

function evaluate(code::String; input = stdin, output = stdout)
    raw_program = parse(code; input, output)
    if !isnothing(raw_program)
        macro_env = Environment(; input, output)
        program = define_macros!(macro_env, raw_program)
        expanded = expand_macros(program, macro_env)

        syntax_check_result = analyze(expanded)
        if isa(syntax_check_result, ErrorObj)
            println(output, syntax_check_result)
            return syntax_check_result
        end

        result = evaluate(expanded, Environment(; input, output))
        if isa(result, ErrorObj)
            println(output, result)
        end

        return result
    end
end

evaluate(::Node, ::Environment) = _NULL
evaluate(node::ExpressionStatement, env::Environment) = evaluate(node.expression, env)
evaluate(node::IntegerLiteral, ::Environment) = IntegerObj(node.value)
evaluate(node::BooleanLiteral, ::Environment) = node.value ? _TRUE : _FALSE
evaluate(node::StringLiteral, ::Environment) = StringObj(node.value)
function evaluate(node::FunctionLiteral, env::Environment)
    FunctionObj(node.parameters, node.body, env)
end

function evaluate(node::ArrayLiteral, env::Environment)
    elements = evaluate_expressions(node.elements, env)
    if length(elements) == 1 && isa(elements[1], ErrorObj)
        return elements[1]
    end
    return ArrayObj(elements)
end

evaluate(node::HashLiteral, env::Environment) = begin
    pairs = Dict{Object, Object}()

    for (key_node, value_node) in node.pairs
        key = evaluate(key_node, env)
        if isa(key, ErrorObj)
            return key
        end

        value = evaluate(value_node, env)
        if isa(value, ErrorObj)
            return value
        end

        pairs[key] = value
    end

    return HashObj(pairs)
end

function evaluate(node::Identifier, env::Environment)
    val = get(env, node.value)

    if !isnothing(val)
        return val
    end

    builtin = get_builtin_by_name(node.value)

    if !isnothing(builtin)
        return builtin
    end
end

function evaluate(node::PrefixExpression, env::Environment)
    right = evaluate(node.right, env)
    return isa(right, ErrorObj) ? right :
           evaluate_prefix_expression(node.operator, right)
end

function evaluate(node::InfixExpression, env::Environment)
    left = evaluate(node.left, env)
    if isa(left, ErrorObj)
        return left
    end
    right = evaluate(node.right, env)
    return isa(right, ErrorObj) ? right :
           evaluate_infix_expression(node.operator, left, right)
end

function evaluate(node::IfExpression, env::Environment)
    condition = evaluate(node.condition, env)

    if isa(condition, ErrorObj)
        return condition
    elseif is_truthy(condition)
        return evaluate(node.consequence, env)
    elseif !isnothing(node.alternative)
        return evaluate(node.alternative, env)
    else
        return _NULL
    end
end

function evaluate(node::CallExpression, env::Environment)
    # TODO: Currently, `quote()` only processes its first argument
    if token_literal(node.fn) == "quote"
        if isempty(node.arguments)
            return _NULL
        end
        return QuoteObj(evaluate_unquote_calls(node.arguments[1], env))
    end

    fn = evaluate(node.fn, env)
    if isa(fn, ErrorObj)
        return fn
    end

    args = evaluate_expressions(node.arguments, env)
    if length(args) == 1 && isa(args[1], ErrorObj)
        return args[1]
    end

    return isa(fn, Builtin) ? apply_builtin(fn, args, env) : apply_function(fn, args)
end

function evaluate(node::IndexExpression, env::Environment)
    left = evaluate(node.left, env)
    if isa(left, ErrorObj)
        return left
    end

    index = evaluate(node.index, env)
    if isa(index, ErrorObj)
        return index
    end

    return evaluate_index_expression(left, index)
end

function evaluate(node::LetStatement, env::Environment)
    val = evaluate(node.value, env)
    if isa(val, ErrorObj)
        return val
    end
    if node.reassign
        return reassign!(env, node.name.value, val)
    else
        set!(env, node.name.value, val)
    end
    return val
end

function evaluate(node::ReturnStatement, env::Environment)
    val = evaluate(node.return_value, env)
    return isa(val, ErrorObj) ? val : ReturnValue(val)
end

evaluate(::BreakStatement, env::Environment) = BreakObj()

evaluate(::ContinueStatement, env::Environment) = ContinueObj()

function evaluate(node::WhileStatement, env::Environment)
    while true
        condition = evaluate(node.condition, env)
        if isa(condition, ErrorObj)
            return condition
        end

        if is_truthy(condition)
            result = evaluate(node.body, Environment(env))
            if isa(result, ReturnValue) || isa(result, ErrorObj)
                return result
            elseif isa(result, BreakObj)
                break
            elseif isa(result, ContinueObj)
                continue
            end
        else
            break
        end
    end

    return _NULL
end

function evaluate(block::BlockStatement, env::Environment)
    result = _NULL

    for statement in block.statements
        result = evaluate(statement, env)
        if isa(result, BreakObj) ||
           isa(result, ContinueObj) ||
           isa(result, ReturnValue) ||
           isa(result, ErrorObj)
            return result
        end
    end

    return result
end

function evaluate(program::Program, env::Environment)
    result = _NULL

    for statement in program.statements
        result = evaluate(statement, env)
        if isa(result, ReturnValue)
            return result.value
        elseif isa(result, ErrorObj)
            return result
        end
    end

    return result
end

function evaluate_prefix_expression(operator::String, right::Object)
    if operator == "!"
        return evaluate_bang_operator_expression(right)
    elseif operator == "-"
        return evaluate_minus_prefix_operator_expression(right)
    else
        return ErrorObj("unknown operator: " * operator * type_of(right))
    end
end

function evaluate_infix_expression(operator::String, left::Object, right::Object)
    if type_of(left) != type_of(right)
        return ErrorObj("type mismatch: " * type_of(left) * " " * operator * " " *
                        type_of(right))
    end

    if operator == "=="
        return left == right ? _TRUE : _FALSE
    elseif operator == "!="
        return left != right ? _TRUE : _FALSE
    else
        return ErrorObj("unknown operator: " * type_of(left) * " " * operator * " " *
                        type_of(right))
    end
end

function evaluate_infix_expression(operator::String, left::StringObj, right::StringObj)
    if operator == "+"
        return StringObj(left.value * right.value)
    elseif operator == "=="
        return left.value == right.value ? _TRUE : _FALSE
    elseif operator == "!="
        return left.value != right.value ? _TRUE : _FALSE
    else
        return ErrorObj("unknown operator: " * type_of(left) * " " * operator * " " *
                        type_of(right))
    end
end

function evaluate_infix_expression(operator::String, left::IntegerObj, right::IntegerObj)
    if operator == "+"
        return IntegerObj(left.value + right.value)
    elseif operator == "-"
        return IntegerObj(left.value - right.value)
    elseif operator == "*"
        return IntegerObj(left.value * right.value)
    elseif operator == "/"
        if right.value == 0
            return ErrorObj("divide error: division by zero")
        end
        return IntegerObj(left.value ÷ right.value)
    elseif operator == "<"
        return left.value < right.value ? _TRUE : _FALSE
    elseif operator == ">"
        return left.value > right.value ? _TRUE : _FALSE
    elseif operator == "=="
        return left.value == right.value ? _TRUE : _FALSE
    elseif operator == "!="
        return left.value != right.value ? _TRUE : _FALSE
    else
        return ErrorObj("unknown operator: " * type_of(left) * " " * operator * " " *
                        type_of(right))
    end
end

function evaluate_bang_operator_expression(right::Object)
    if right === _FALSE || right === _NULL
        return _TRUE
    else
        return _FALSE
    end
end

function evaluate_minus_prefix_operator_expression(right::Object)
    ErrorObj("unknown operator: -" * type_of(right))
end
evaluate_minus_prefix_operator_expression(right::IntegerObj) = IntegerObj(-right.value)

function evaluate_index_expression(left::Object, ::Object)
    ErrorObj("index operator not supported: $(type_of(left))")
end
function evaluate_index_expression(::ArrayObj, index::Object)
    ErrorObj("unsupported index type: $(type_of(index))")
end
evaluate_index_expression(hash::HashObj, key::Object) = Base.get(hash.pairs, key, _NULL)
function evaluate_index_expression(left::ArrayObj, index::IntegerObj)
    begin
        idx = index.value
        max_idx = length(left.elements) - 1
        return 0 <= idx <= max_idx ? left.elements[idx + 1] : _NULL
    end
end

function evaluate_expressions(expressions::Vector{Expression}, env::Environment)
    results = Object[]

    for expression in expressions
        evaluated = evaluate(expression, env)
        if isa(evaluated, ErrorObj)
            return [evaluated]
        end
        push!(results, evaluated)
    end

    return results
end

function evaluate_unquote_calls(quoted::Node, env::Environment)
    modify(quoted,
        function modifier(node::Node)
            if isa(node, CallExpression)
                if token_literal(node.fn) == "unquote" && length(node.arguments) >= 1
                    Node(evaluate(node.arguments[1], env))
                else
                    return CallExpression(node.token,
                        modify(node.fn, modifier),
                        map(expression -> modify(expression, modifier),
                            node.arguments))
                end
            else
                return node
            end
        end)
end

function apply_function(fn::FunctionObj, args::Vector{Object})
    if length(fn.parameters) != length(args)
        return ErrorObj("argument error: wrong number of arguments: got $(length(args))")
    end

    extended_env = extend_function_environment(fn, args)
    evaluated = evaluate(fn.body, extended_env)
    return unwrap_return_value(evaluated)
end

apply_function(fn::Object, ::Vector{Object}) = ErrorObj("not a function: " * type_of(fn))
function apply_builtin(fn::Builtin, args::Vector{Object}, env::Environment)
    fn.fn(args...; env = env)
end

function extend_function_environment(fn::FunctionObj, args::Vector{Object})
    env = Environment(fn.env)

    for (param, arg) in zip(fn.parameters, args)
        set!(env, param.value, arg)
    end

    return env
end

function unwrap_return_value(obj::Object)
    if isa(obj, ReturnValue)
        return obj.value
    else
        return obj
    end
end

Node(::Object) = NullLiteral(Token(NULL, "null", 0, 0))
Node(obj::IntegerObj) = IntegerLiteral(Token(INT, string(obj.value), 0, 0), obj.value)
Node(obj::StringObj) = StringLiteral(Token(STRING, obj.value, 0, 0), obj.value)
function Node(obj::BooleanObj)
    BooleanLiteral(Token(obj.value ? TRUE : FALSE, string(obj.value), 0, 0), obj.value)
end
function Node(obj::HashObj)
    HashLiteral(Token(LBRACE, "{", 0, 0),
        Dict(Node(key) => Node(value) for (key, value) in collect(obj.pairs)))
end
Node(obj::ArrayObj) = ArrayLiteral(Token(LBRACKET, "[", 0, 0), map(Node, obj.elements))
function Node(obj::FunctionObj)
    FunctionLiteral(Token(FUNCTION, "fn", 0, 0), obj.parameters, obj.body)
end
Node(obj::QuoteObj) = obj.node

# TODO: Currently, only top-level macro definitions are allowed. We don’t walk down the Statements and check the child nodes for more.
function define_macros!(env::Environment, program::Program)
    new_statements = []

    for statement in program.statements
        if is_macro_definition(statement)
            add_macro!(env, statement)
        else
            push!(new_statements, statement)
        end
    end

    return Program(new_statements)
end

is_macro_definition(::Node) = false
is_macro_definition(ls::LetStatement) = isa(ls.value, MacroLiteral)

function add_macro!(env::Environment, ls::LetStatement)
    begin
        name = ls.name.value
        value = ls.value
        set!(env, name, MacroObj(value.parameters, value.body, env))
    end
end

function expand_macros(program::Program, env::Environment)
    return modify(program,
        (node::Node) -> begin
            if !isa(node, CallExpression)
                return node
            end

            mc = get_macro_call(node, env)
            if isnothing(mc)
                return node
            end

            args = quote_args(node)
            eval_env = extend_macro_env(mc, args)
            evaluated = evaluate(mc.body, eval_env)

            if !isa(evaluated, QuoteObj)
                error("macro error: we only support returning AST-nodes from macros")
            end

            return evaluated.node
        end)
end

function get_macro_call(node::CallExpression, env::Environment)
    ident = node.fn
    if !isa(ident, Identifier)
        return nothing
    end

    mc = get(env, ident.value)
    if !isa(mc, MacroObj)
        return nothing
    end

    return mc
end

quote_args(node::CallExpression) = map(QuoteObj, node.arguments)

function extend_macro_env(mc::MacroObj, args::Vector{QuoteObj})
    extended_env = Environment(mc.env)
    for (parameter, argument) in zip(mc.parameters, args)
        set!(extended_env, parameter.value, argument)
    end
    return extended_env
end
