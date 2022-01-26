function test_token(token::m.Token, expected::m.Token)
    @assert token == expected "Expected $(expected.type), got $(token.type) instead"

    true
end

function check_parser_errors(p::m.Parser)
    if !isempty(p.errors)
        msg = join(
            vcat(
                ["parser has $(length(p.errors)) errors"],
                ["parser error: $x" for x in p.errors],
            ),
            "\n",
        )
        error(msg)
    end
end

function test_identifier(expr::m.Expression, value::String)
    @assert isa(expr, m.Identifier) "expr is not an Identifier. Got $(typeof(expr)) instead."

    @assert expr.value == value "expr.value is not $value. Got $(expr.value) instead."

    @assert m.token_literal(expr) == value "token_literal(expr) is not $value. Got $(m.token_literal(expr)) instead."

    true
end

function test_integer_literal(il::m.Expression, value::Int64)
    @assert isa(il, m.IntegerLiteral) "il is not an IntegerLiteral. Got $(typeof(il)) instead."
    @assert il.value == value "il.value is not $value. Got $(il.value) instead."
    @assert m.token_literal(il) == string(value) "token_literal(il) is not $value. Got $(m.token_literal(il)) instead."

    true
end

function test_boolean_literal(bl::m.Expression, value::Bool)
    @assert isa(bl, m.BooleanLiteral) "il is not a BooleanLiteral. Got $(typeof(bl)) instead."
    @assert bl.value == value "bl.value is not $value. Got $(bl.value) instead."
    @assert m.token_literal(bl) == string(value) "token_literal(bl) is not $value. Got $(m.token_literal(bl)) instead."

    true
end

function test_null_literal(bl::m.Expression)
    @assert isa(bl, m.NullLiteral) "il is not a NullLiteral. Got $(typeof(bl)) instead."

    true
end

function test_literal_expression(expr::m.Expression, expected)
    if isa(expected, Int)
        test_integer_literal(expr, Int64(expected))
    elseif isa(expected, String)
        test_identifier(expr, expected)
    elseif isa(expected, Bool)
        test_boolean_literal(expr, expected)
    elseif isnothing(expected)
        test_null_literal(expr)
    else
        error("unexpected type for expected")
    end

    true
end

function test_infix_expression(expr::m.Expression, left, operator::String, right)
    @assert isa(expr, m.InfixExpression) "expr is not an InfixExpression. Got $(typeof(expr)) instead."

    test_literal_expression(expr.left, left)

    @assert expr.operator == operator "expr.operator is not $operator. Got $(expr.operator) instead."

    test_literal_expression(expr.right, right)

    true
end

function test_quote_object(evaluated::m.Object, expected::String)
    @assert isa(evaluated, m.QuoteObj) "evaluated is not a QuoteObj. Got $(typeof(evaluated)) instead."

    string(evaluated.node) == expected
end

function test_object(obj::m.Object, expected::Int64)
    @assert isa(obj, m.IntegerObj) "obj is not an INTEGER. Got $(m.type_of(obj)) instead."

    @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

    true
end

function test_object(obj::m.Object, expected::Bool)
    @assert isa(obj, m.BooleanObj) "obj is not a BOOLEAN. Got $(m.type_of(obj)) instead."

    @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

    true
end

function test_object(obj::m.Object, ::Nothing)
    @assert obj === m._NULL "obj is not NULL. Got $(m.type_of(obj)) instead."

    true
end

function test_object(obj::m.Object, expected::String)
    if occursin("error", expected)
        test_error_object(obj, expected)
    else
        test_string_object(obj, expected)
    end
end

function test_object(obj::m.ArrayObj, expected::Vector)
    @assert length(obj.elements) == length(expected) "Wrong number of elements. Expected $(length(expected)), got $(length(obj.elements)) instead."

    for (ca, ce) in zip(obj.elements, expected)
        test_object(ca, ce)
    end

    true
end

function test_object(obj::m.HashObj, expected::Dict)
    @assert length(obj.pairs) == length(expected) "Wrong number of pairs. Expected $(length(expected)), got $(length(obj.pairs)) instead."

    for (k, ce) in collect(expected)
        if isa(k, Int)
            ca = get(obj.pairs, k, nothing)
            test_object(ca, ce)
        end
    end

    true
end

function test_object(obj::m.ErrorObj, expected::String)
    @assert obj.message == expected "wrong error message. Expected \"$expected\". Got \"$(obj.message)\" instead."

    true
end

function test_object(obj::m.CompiledFunctionObj, expected::m.Instructions)
    test_instructions(obj.instructions, [expected])
end

function test_string_object(obj::m.StringObj, expected::String)
    @assert obj.value == expected "Expected $expected. Got $(obj.value) instead."

    true
end

function test_instructions(actual, expected)
    concatted = vcat(expected...)

    @assert length(concatted) == length(actual) "Wrong instructions length. Expected $concatted, got $actual instead."

    for i = 1:length(concatted)
        @assert concatted[i] == actual[i] "Wrong instruction at index $(i). Expected $(concatted[i]), got $(actual[i]) instead."
    end

    true
end

function test_constants(actual, expected)
    @assert length(expected) == length(actual) "Wrong constants length. Expected $(length(expected)), got $(length(actual)) instead."

    for (ca, ce) in zip(actual, expected)
        test_object(ca, ce)
    end

    true
end

function run_compiler_tests(
    input::String,
    expected_constants::Vector,
    expected_instructions::Vector{m.Instructions},
)
    program = m.parse(input)
    c = m.Compiler()
    m.compile!(c, program)

    bc = m.bytecode(c)

    test_instructions(bc.instructions, expected_instructions)
    test_constants(bc.constants, expected_constants)

    true
end

function test_vm(input::String, expected)
    program = m.parse(input)
    c = m.Compiler()
    m.compile!(c, program)
    vm = m.VM(m.bytecode(c))
    m.run!(vm)

    test_object(m.last_popped(vm), expected)
end
