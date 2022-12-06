function test_token(token::m.Token, expected::m.Token)
    @test token == expected
end

function check_parser_errors(p::m.Parser)
    if !isempty(p.errors)
        msg = join(vcat(["parser has $(length(p.errors)) errors"],
                        ["parser error: $x" for x in p.errors]),
                   "\n")
        error(msg)
    end
end

function test_identifier(expr::m.Expression, value::String)
    @test isa(expr, m.Identifier)
    @test expr.value == value
    @test m.token_literal(expr) == value
end

function test_integer_literal(il::m.Expression, value::Int64)
    @test isa(il, m.IntegerLiteral)
    @test il.value == value
    @test m.token_literal(il) == string(value)
end

function test_boolean_literal(bl::m.Expression, value::Bool)
    @test isa(bl, m.BooleanLiteral)
    @test bl.value == value
    @test m.token_literal(bl) == string(value)
end

function test_null_literal(bl::m.Expression)
    @test isa(bl, m.NullLiteral)
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
end

function test_infix_expression(expr::m.Expression, left, operator::String, right)
    @test isa(expr, m.InfixExpression)

    test_literal_expression(expr.left, left)

    @test expr.operator == operator

    test_literal_expression(expr.right, right)
end

function test_quote_object(evaluated::m.Object, expected::String)
    @test isa(evaluated, m.QuoteObj)
    @test string(evaluated.node) == expected
end

function test_object(obj::m.Object, expected::Int64)
    @test isa(obj, m.IntegerObj)
    @test obj.value == expected
end

function test_object(obj::m.Object, expected::Bool)
    @test isa(obj, m.BooleanObj)
    @test obj.value == expected
end

function test_object(obj::m.Object, ::Nothing)
    @test obj === m._NULL
end

function test_object(obj::m.Object, expected::String)
    if occursin("error", expected)
        test_error_object(obj, expected)
    else
        test_string_object(obj, expected)
    end
end

function test_object(obj::m.ArrayObj, expected::Vector)
    @test length(obj.elements) == length(expected)

    for (ca, ce) in zip(obj.elements, expected)
        test_object(ca, ce)
    end
end

function test_object(obj::m.HashObj, expected::Dict)
    @test length(obj.pairs) == length(expected)

    for (k, ce) in collect(expected)
        key = m.Object(k)
        test_object(get(obj.pairs, key, nothing), ce)
    end
end

function test_object(obj::m.ErrorObj, expected::String)
    @test obj.message == expected
end

function test_object(obj::m.CompiledFunctionObj, expected::m.Instructions)
    test_instructions(obj.instructions, [expected])
end

function test_string_object(obj::m.StringObj, expected::String)
    @test obj.value == expected
end

function test_instructions(actual, expected)
    concatted = vcat(expected...)

    @test string(actual) == string(concatted)
end

function test_constants(actual, expected)
    @test length(expected) == length(actual)

    for (ca, ce) in zip(actual, expected)
        test_object(ca, ce)
    end
end

function run_compiler_tests(input::String,
                            expected_constants::Vector,
                            expected_instructions::Vector{m.Instructions})
    program = m.parse(input)
    c = m.Compiler()
    m.compile!(c, program)

    bc = m.bytecode(c)

    test_instructions(bc.instructions, expected_instructions)
    test_constants(bc.constants, expected_constants)
end

function test_vm(code::String, expected, expected_output::String = "")
    c = IOCapture.capture() do
        m.run(code)
    end
    test_object(c.value, expected)
    @test c.output == expected_output
end
