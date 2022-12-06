@testset "Test Parser" begin
    @testset "Empty program" begin @test isnothing(m.parse("")) end

    @testset "Test Parsing Let Statements" begin for (code, expected_ident, expected_value) in [
        ("let x = 5;", "x", 5),
        ("let y = true;", "y", true),
        ("let foobar = y;", "foobar", "y"),
        ("let a = null;", "a", nothing),
    ]
        function test_let_statement(ls::m.LetStatement, name::String)
            ls.name.value == name && m.token_literal(ls.name) == name
        end

        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1

        statement = program.statements[1]
        test_let_statement(statement, expected_ident)

        val = statement.value
        test_literal_expression(val, expected_value)
    end end

    @testset "Test Parsing Return Statements" begin for (code, expected_value) in [
        ("return 5;", 5),
        ("return false;", false),
        ("return y;", "y"),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1

        statement = program.statements[1]
        test_literal_expression(statement.return_value, expected_value)
    end end

    @testset "Test Parsing Identifier Expression" begin for (code, value) in [("foobar;",
                                                                               "foobar")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        ident = statement.expression
        test_literal_expression(ident, value)
    end end

    @testset "Test Parsing BooleanLiteral Expression" begin for (code, value) in [
        ("true;", true),
        ("false;", false),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        bool = statement.expression
        test_literal_expression(bool, value)
    end end

    @testset "Test Parsing Integer Literal Expression" begin for (code, value) in [("5;",
                                                                                    5)]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        il = statement.expression
        test_literal_expression(il, value)
    end end

    @testset "Test Parsing Prefix Expressions" begin for (code, operator, right_value) in [
        ("!5", "!", 5),
        ("-15", "-", 15),
        ("-a", "-", "a"),
        ("!true", "!", true),
        ("!false", "!", false),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        expr = statement.expression
        @test isa(expr, m.PrefixExpression)
        @test expr.operator == operator

        test_literal_expression(expr.right, right_value)
    end end

    @testset "Test Parsing Infix Expressions" begin for (code, left_value, operator, right_value) in [
        ("5 + 5", 5, "+", 5),
        ("5 - 5", 5, "-", 5),
        ("5 * 5", 5, "*", 5),
        ("5 / 5", 5, "/", 5),
        ("5 > 5", 5, ">", 5),
        ("5 < 5", 5, "<", 5),
        ("5 == 5", 5, "==", 5),
        ("5 != 5", 5, "!=", 5),
        ("true == true", true, "==", true),
        ("true != false", true, "!=", false),
        ("false == false", false, "==", false),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        expr = statement.expression
        test_infix_expression(expr, left_value, operator, right_value)
    end end

    @testset "Test Parsing If Expression" begin for (code) in [("if (x < y) { x }")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        expr = statement.expression

        @test isa(expr, m.IfExpression)

        test_infix_expression(expr.condition, "x", "<", "y")

        @test length(expr.consequence.statements) == 1

        consequence = expr.consequence.statements[1]
        @test isa(consequence, m.ExpressionStatement)

        test_identifier(consequence.expression, "x")

        @test isnothing(expr.alternative)
    end end

    @testset "Test Parsing If Else Expression" begin for (code) in [("if (x < y) { x } else { y }")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        expr = statement.expression

        @test isa(expr, m.IfExpression)

        test_infix_expression(expr.condition, "x", "<", "y")

        @test length(expr.consequence.statements) == 1

        consequence = expr.consequence.statements[1]
        @test isa(consequence, m.ExpressionStatement)

        test_identifier(consequence.expression, "x")

        alternative = expr.alternative.statements[1]
        @test isa(alternative, m.ExpressionStatement)

        test_identifier(alternative.expression, "y")
    end end

    @testset "Test Parsing While Statement" begin for (code) in [("while (x < y) { x = x + 1 }")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.WhileStatement)

        statement = program.statements[1]

        @test isa(statement, m.WhileStatement)

        test_infix_expression(statement.condition, "x", "<", "y")

        @test length(statement.body.statements) == 1

        ls = statement.body.statements[1]
        @test isa(ls, m.LetStatement)
        @test ls.reassign

        test_identifier(ls.name, "x")
        test_infix_expression(ls.value, "x", "+", 1)
    end end

    @testset "Test Parsing Break Statement" begin for code in ["break", "break;"]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.BreakStatement)
    end end

    @testset "Test Parsing Continue Statement" begin for code in ["continue", "continue;"]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ContinueStatement)
    end end

    @testset "Test Parsing Functional Literal" begin for (code) in [("fn(x, y) { x + y; }")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)
        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        fn = statement.expression

        @test isa(fn, m.FunctionLiteral)
        @test length(fn.parameters) == 2

        test_literal_expression(fn.parameters[1], "x")
        test_literal_expression(fn.parameters[2], "y")

        @test length(fn.body.statements) == 1

        body_statement = fn.body.statements[1]
        @test isa(body_statement, m.ExpressionStatement)
        test_infix_expression(body_statement.expression, "x", "+", "y")
    end end

    @testset "Test Parsing Functional Literal With Name" begin for (code) in [("let myFunction = fn() { };")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.LetStatement)

        fl = program.statements[1].value
        @test fl.name == "myFunction"
    end end

    @testset "Test Parsing Function Parameters" begin for (code, expected) in [
        ("fn() {};", []),
        ("fn(x) {};", ["x"]),
        ("fn(x, y, z) {};", ["x", "y", "z"]),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)
        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        fn = statement.expression

        @test length(fn.parameters) == length(expected)

        for (parameter, expected_parameter) in zip(fn.parameters, expected)
            test_literal_expression(parameter, expected_parameter)
        end
    end end

    @testset "Test Parsing Call Expression" begin for (code) in [("add(1, 2 * 3, 4 + 5)")]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)
        check_parser_errors(p)

        @test length(program.statements) == 1
        @test isa(program.statements[1], m.ExpressionStatement)

        statement = program.statements[1]
        expr = statement.expression
        @test isa(expr, m.CallExpression)
        test_identifier(expr.fn, "add")

        @test length(expr.arguments) == 3
        test_literal_expression(expr.arguments[1], 1)
        test_infix_expression(expr.arguments[2], 2, "*", 3)
        test_infix_expression(expr.arguments[3], 4, "+", 5)
    end end

    @testset "Test Parsing String Literal Expression" begin
        code = "\"hello world\""
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        expr = program.statements[1].expression
        @test isa(expr, m.StringLiteral)
        @test expr.value == "hello world"
    end

    @testset "Test Parsing Array Literal" begin
        code = "[1, 2 * 2, 3 + 3]"
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        arr = program.statements[1].expression
        @test isa(arr, m.ArrayLiteral)
        @test length(arr.elements) == 3

        test_integer_literal(arr.elements[1], 1)
        test_infix_expression(arr.elements[2], 2, "*", 2)
        test_infix_expression(arr.elements[3], 3, "+", 3)
    end

    @testset "Test Parsing Index Expression" begin
        code = "myArray[1 + 1]"
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)
        check_parser_errors(p)

        expr = program.statements[1].expression
        @test isa(expr, m.IndexExpression)

        test_identifier(expr.left, "myArray")
        test_infix_expression(expr.index, 1, "+", 1)
    end

    @testset "Test Parsing Hash Literal" begin
        @testset "Test Parsing Hash Literal with String Keys" begin
            code = """{"one": 1, "two": 2, "three": 3}"""
            expected = Dict("one" => 1, "two" => 2, "three" => 3)
            l = m.Lexer(code)
            p = m.Parser(l)
            program = m.parse!(p)
            check_parser_errors(p)

            hash = program.statements[1].expression
            @test isa(hash, m.HashLiteral)
            @test length(hash.pairs) == 3

            for (key, value) in hash.pairs
                @test isa(key, m.StringLiteral)
                @test key.value ∈ keys(expected)
                test_integer_literal(value, expected[key.value])
            end
        end

        @testset "Test Parsing Hash Literal with String Keys and Expression Values" begin
            code = """{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}"""
            tests = Dict("one" => x -> test_infix_expression(x, 0, "+", 1),
                         "two" => x -> test_infix_expression(x, 10, "-", 8),
                         "three" => x -> test_infix_expression(x, 15, "/", 5))

            l = m.Lexer(code)
            p = m.Parser(l)
            program = m.parse!(p)

            check_parser_errors(p)

            hash = program.statements[1].expression
            @test isa(hash, m.HashLiteral)

            @test length(hash.pairs) == 3

            for (key, value) in hash.pairs
                @test isa(key, m.StringLiteral)

                @test key.value ∈ keys(tests)

                tests[key.value](value)
            end
        end

        @testset "Test Parsing Hash Literal with Integer Keys" begin
            code = "{1: 1, 2: 2, 3: 3}"
            expected = Dict(1 => 1, 2 => 2, 3 => 3)
            l = m.Lexer(code)
            p = m.Parser(l)
            program = m.parse!(p)

            check_parser_errors(p)

            hash = program.statements[1].expression
            @test isa(hash, m.HashLiteral)

            @test length(hash.pairs) == 3

            for (key, value) in hash.pairs
                @test isa(key, m.IntegerLiteral)

                @test key.value ∈ keys(expected)

                test_integer_literal(value, expected[key.value])
            end
        end

        @testset "Test Parsing Hash Literal with Boolean Keys" begin
            code = "{false: 0, true: 1}"
            expected = Dict(false => 0, true => 1)
            l = m.Lexer(code)
            p = m.Parser(l)
            program = m.parse!(p)

            check_parser_errors(p)

            hash = program.statements[1].expression
            @test isa(hash, m.HashLiteral)

            @test length(hash.pairs) == 2

            for (key, value) in hash.pairs
                @test isa(key, m.BooleanLiteral)

                @test key.value ∈ keys(expected)

                test_integer_literal(value, expected[key.value])
            end
        end

        @testset "Test Parsing Empty Hash Literal" begin
            code = "{}"
            l = m.Lexer(code)
            p = m.Parser(l)
            program = m.parse!(p)

            check_parser_errors(p)

            hash = program.statements[1].expression
            @test isa(hash, m.HashLiteral)

            @test length(hash.pairs) == 0
        end
    end

    @testset "Test Parsing Macro Literal" begin
        code = "macro(x, y) { x + y; }"
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        ml = program.statements[1].expression
        @test isa(ml, m.MacroLiteral)

        @test length(ml.parameters) == 2

        test_literal_expression(ml.parameters[1], "x")
        test_literal_expression(ml.parameters[2], "y")

        @test length(ml.body.statements) == 1

        test_infix_expression(ml.body.statements[1].expression, "x", "+", "y")
    end

    @testset "Test Operator Order" begin for (code, expected) in [
        ("-a * b", "((-a) * b)"),
        ("!-a", "(!(-a))"),
        ("a + b + c", "((a + b) + c)"),
        ("a + b - c", "((a + b) - c)"),
        ("a * b * c", "((a * b) * c)"),
        ("a * b / c", "((a * b) / c)"),
        ("a + b / c", "(a + (b / c))"),
        ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
        ("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"), #FIXME
        ("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
        ("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"),
        ("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
        ("true", "true"),
        ("false", "false"),
        ("3 > 5 == false", "((3 > 5) == false)"),
        ("3 < 5 == true", "((3 < 5) == true)"),
        ("1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"),
        ("(5 + 5) * 2", "((5 + 5) * 2)"),
        ("2 / (5 + 5)", "(2 / (5 + 5))"),
        ("-(5 + 5)", "(-(5 + 5))"),
        ("!(true == true)", "(!(true == true))"),
        ("a + add(b * c) + d", "((a + add((b * c))) + d)"),
        ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
         "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
        ("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"),
        ("a * [1, 2, 3, 4][b * c] * d", "((a * ([1, 2, 3, 4][(b * c)])) * d)"),
        ("add(a * b[2], b[1], 2 * [1, 2][1])",
         "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)

        check_parser_errors(p)

        @test string(program) == expected
    end end

    @testset "Test Parsing Errors" begin for (code, expected) in [
        ("100000000000000000000",
         ["ERROR: parse error: could not parse 100000000000000000000 as integer"]),
        ("2!", ["ERROR: parse error: no prefix parse function for EOF found"]),
        ("{1:2",
         ["ERROR: parse error: expected next token to be COMMA, got EOF instead"]),
        ("{1}",
         [
             "ERROR: parse error: expected next token to be COLON, got RBRACE instead",
             "ERROR: parse error: no prefix parse function for RBRACE found",
         ]),
        ("[1",
         ["ERROR: parse error: expected next token to be RBRACKET, got EOF instead"]),
        ("{1:2}[1",
         ["ERROR: parse error: expected next token to be RBRACKET, got EOF instead"]),
        ("fn x",
         ["ERROR: parse error: expected next token to be LPAREN, got IDENT instead"]),
        ("fn (x {x}",
         [
             "ERROR: parse error: expected next token to be RPAREN, got LBRACE instead",
         ]),
        ("fn (x) x",
         ["ERROR: parse error: expected next token to be LBRACE, got IDENT instead"]),
        ("fn (x) {x", ["ERROR: parse error: braces must be closed"]),
        ("if x",
         ["ERROR: parse error: expected next token to be LPAREN, got IDENT instead"]),
        ("if (x",
         ["ERROR: parse error: expected next token to be RPAREN, got EOF instead"]),
        ("if (x) c",
         ["ERROR: parse error: expected next token to be LBRACE, got IDENT instead"]),
        ("if (x) { 1 } else 2",
         ["ERROR: parse error: expected next token to be LBRACE, got INT instead"]),
        ("if (true) {", ["ERROR: parse error: braces must be closed"]),
        ("while",
         ["ERROR: parse error: expected next token to be LPAREN, got EOF instead"]),
        ("while (true",
         ["ERROR: parse error: expected next token to be RPAREN, got EOF instead"]),
        ("while (true)",
         ["ERROR: parse error: expected next token to be LBRACE, got EOF instead"]),
        ("while (true) {", ["ERROR: parse error: braces must be closed"]),
        ("let 5",
         ["ERROR: parse error: expected next token to be IDENT, got INT instead"]),
        ("let x 3",
         ["ERROR: parse error: expected next token to be ASSIGN, got INT instead"]),
        ("macro x",
         ["ERROR: parse error: expected next token to be LPAREN, got IDENT instead"]),
        ("macro (x",
         [
             "ERROR: parse error: expected next token to be RPAREN, got EOF instead",
             "ERROR: parse error: expected next token to be LBRACE, got EOF instead",
         ]),
        ("macro (x)",
         ["ERROR: parse error: expected next token to be LBRACE, got EOF instead"]),
        ("macro (x) {x", ["ERROR: parse error: braces must be closed"]),
    ]
        l = m.Lexer(code)
        p = m.Parser(l)
        program = m.parse!(p)
        @test map(string, p.errors) == expected
    end end

    @testset "Test Directly Parsing" begin for (code, expected_output) in [
        ("100000000000000000000",
         "ERROR: parser has 1 error\nERROR: parse error: could not parse 100000000000000000000 as integer\n"),
    ]
        c = IOCapture.capture() do
            program = m.parse(code)
            @test isnothing(program)
        end

        @test c.output == expected_output
    end end
end
