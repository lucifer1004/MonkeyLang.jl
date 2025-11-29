@testset "Test Objects" begin
    int_obj = m.IntegerObj(123)
    str_obj = m.StringObj("str")
    true_obj = m._TRUE
    false_obj = m._FALSE
    null_obj = m._NULL
    error_obj = m.ErrorObj("error")
    arr_obj = m.ArrayObj([m.IntegerObj(1), m.IntegerObj(2)])
    hash_obj = m.HashObj(Dict(m.IntegerObj(1) => m.IntegerObj(2),
        m.IntegerObj(3) => m.IntegerObj(4)))
    function_obj = m.FunctionObj([m.Identifier(T(m.IDENT, "x"), "x")],
        m.BlockStatement(T(m.LBRACE, "{"),
            [
                m.ExpressionStatement(T(m.IDENT,
                    "x"),
                m.InfixExpression(T(m.PLUS,
                        "+"),
                    m.Identifier(T(m.IDENT,
                            "x"),
                        "x"),
                    "+",
                    m.IntegerLiteral(T(m.INT,
                            "2"),
                        2)))
            ]),
        m.Environment())
    macro_obj = m.MacroObj([m.Identifier(T(m.IDENT, "x"), "x")],
        m.BlockStatement(T(m.LBRACE, "{"), []),
        m.Environment())
    len = m.get_builtin_by_name("len")
    return_value = m.ReturnValue(m._TRUE)
    quote_obj = m.QuoteObj(m.NullLiteral(T(m.NULL, "null")))
    compiled_function_obj = m.CompiledFunctionObj(m.Instructions([]), 0, 0, true)
    closure_obj = m.ClosureObj(compiled_function_obj, [])

    @testset "Is Truthy" begin
        @test m.is_truthy(m.IntegerObj(1))
        @test m.is_truthy(m.IntegerObj(0))
        @test m.is_truthy(int_obj)
        @test m.is_truthy(m.StringObj(""))
        @test m.is_truthy(m.StringObj("0"))
        @test m.is_truthy(m.StringObj("1"))
        @test m.is_truthy(str_obj)
        @test m.is_truthy(true_obj)
        @test !m.is_truthy(false_obj)
        @test !m.is_truthy(null_obj)
        @test m.is_truthy(error_obj)
        @test m.is_truthy(arr_obj)
        @test m.is_truthy(hash_obj)
        @test m.is_truthy(function_obj)
        @test m.is_truthy(macro_obj)
        @test m.is_truthy(len)
        @test m.is_truthy(return_value)
        @test m.is_truthy(quote_obj)
        @test m.is_truthy(compiled_function_obj)
        @test m.is_truthy(closure_obj)
    end

    @testset "Get Type" begin
        @test m.type_of(int_obj) == "INTEGER"
        @test m.type_of(str_obj) == "STRING"
        @test m.type_of(true_obj) == "BOOLEAN"
        @test m.type_of(false_obj) == "BOOLEAN"
        @test m.type_of(null_obj) == "NULL"
        @test m.type_of(error_obj) == "ERROR"
        @test m.type_of(arr_obj) == "ARRAY"
        @test m.type_of(hash_obj) == "HASH"
        @test m.type_of(function_obj) == "FUNCTION"
        @test m.type_of(macro_obj) == "MACRO"
        @test m.type_of(len) == "BUILTIN"
        @test m.type_of(return_value) == "RETURN_VALUE"
        @test m.type_of(quote_obj) == "QUOTE"
        @test m.type_of(compiled_function_obj) == "COMPILED_FUNCTION"
        @test m.type_of(closure_obj) == "CLOSURE"
    end

    @testset "Stringify" begin
        @test string(int_obj) == "123"
        @test string(true_obj) == "true"
        @test string(false_obj) == "false"
        @test string(null_obj) == "null"
        @test string(str_obj) == "\"str\""
        @test string(error_obj) == "ERROR: error"
        @test string(arr_obj) == "[1, 2]"
        @test string(hash_obj) ∈ ["{1:2, 3:4}", "{3:4, 1:2}"]
        @test string(function_obj) == "fn(x) {\n(x + 2)\n}"
        @test string(macro_obj) == "macro(x) {\n\n}"
        @test string(len) == "builtin function"
        @test string(return_value) == "true"
        @test string(quote_obj) == "QUOTE(null)"
        @test string(compiled_function_obj) == "compiled function"
        @test string(closure_obj) == "closure"
    end

    @testset "Equality" begin
        @test int_obj == m.IntegerObj(123)
        @test int_obj != m.IntegerObj(122)
        @test str_obj == m.StringObj("str")
        @test str_obj != m.StringObj("srt")
        @test true_obj == m.BooleanObj(true)
        @test false_obj == m.BooleanObj(false)
        @test null_obj == m.NullObj()
        @test true_obj != false_obj
        @test false_obj != null_obj
        @test true_obj != null_obj
        @test arr_obj == m.ArrayObj([m.IntegerObj(1), m.IntegerObj(2)])
        @test arr_obj != m.ArrayObj([m.IntegerObj(2), m.IntegerObj(1)])
        @test hash_obj == m.HashObj(Dict(m.IntegerObj(1) => m.IntegerObj(2),
            m.IntegerObj(3) => m.IntegerObj(4)))
        @test hash_obj == m.HashObj(Dict(m.IntegerObj(3) => m.IntegerObj(4),
            m.IntegerObj(1) => m.IntegerObj(2)))
        @test hash_obj != m.HashObj(Dict(m.IntegerObj(3) => m.StringObj("4"),
            m.IntegerObj(1) => m.IntegerObj(2)))
        @test hash_obj != m.HashObj(Dict(m.IntegerObj(3) => m.IntegerObj(4),
            m.IntegerObj(1) => m._TRUE))
    end
end
