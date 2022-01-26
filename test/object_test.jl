@testset "Test Objects" begin
    int_obj = m.IntegerObj(123)
    str_obj = m.StringObj("str")
    true_obj = m._TRUE
    false_obj = m._FALSE
    null_obj = m._NULL
    error_obj = m.ErrorObj("error")
    arr_obj = m.ArrayObj([])
    hash_obj = m.HashObj(Dict())
    function_obj = m.evaluate("fn(x) { x + 2 }")
    macro_obj = m.MacroObj(
        [m.Identifier(m.Token(m.IDENT, "x"), "x")],
        m.BlockStatement(m.Token(m.LBRACE, "{"), []),
        m.Environment(),
    )
    len = m.BUILTINS["len"]
    ret = m.ReturnValue(m._TRUE)
    qt = m.QuoteObj(m.NullLiteral(m.Token(m.NULL, "null")))

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
    @test m.is_truthy(ret)
    @test m.is_truthy(qt)

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
    @test m.type_of(ret) == "RETURN_VALUE"
    @test m.type_of(qt) == "QUOTE"

    @test string(int_obj) == "123"
    @test string(true_obj) == "true"
    @test string(false_obj) == "false"
    @test string(null_obj) == "null"
    @test string(str_obj) == "\"str\""
    @test string(error_obj) == "ERROR: error"
    @test string(arr_obj) == "[]"
    @test string(hash_obj) == "{}"
    @test string(function_obj) == "fn(x) {\n(x + 2)\n}"
    @test string(macro_obj) == "macro(x) {\n\n}"
    @test string(len) == "builtin function"
    @test string(ret) == "true"
    @test string(qt) == "QUOTE(null)"
end
