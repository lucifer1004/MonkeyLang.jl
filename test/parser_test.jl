function check_parser_errors(p::m.Parser)
  if !isempty(p.errors)
    msg = join(vcat(["parser has $(length(p.errors)) errors"], ["parser error: $x" for x in p.errors]), "\n")
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

@testset "Test Parsing Let Statements" begin
  for (input, expected_ident, expected_value) in [
    ("let x = 5;", "x", 5),
    ("let y = true;", "y", true),
    ("let foobar = y;", "foobar", "y"),
    ("let a = null;", "a", nothing),
  ]
    test_let_statement(ls::m.LetStatement, name::String) = ls.name.value == name && m.token_literal(ls.name) == name

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."

      statement = program.statements[1]
      test_let_statement(statement, expected_ident)

      val = statement.value
      test_literal_expression(val, expected_value)
    end
  end
end

@testset "Test Parsing Return Statements" begin
  for (input, expected_value) in [
    ("return 5;", 5),
    ("return false;", false),
    ("return y;", "y"),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."

      statement = program.statements[1]
      test_literal_expression(statement.return_value, expected_value)
    end
  end
end

@testset "Test Parsing Identifier Expression" begin
  for (input, value) in [
    ("foobar;", "foobar"),
  ]

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      ident = statement.expression
      test_literal_expression(ident, value)
    end
  end
end

@testset "Test Parsing BooleanLiteral Expression" begin
  for (input, value) in [
    ("true;", true),
    ("false;", false),
  ]

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      bool = statement.expression
      test_literal_expression(bool, value)
    end
  end
end

@testset "Test Parsing Integer Literal Expression" begin
  for (input, value) in [
    ("5;", 5)
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      il = statement.expression
      test_literal_expression(il, value)
    end
  end
end

@testset "Test Parsing Prefix Expressions" begin
  for (input, operator, right_value) in [
    ("!5", "!", 5),
    ("-15", "-", 15),
    ("-a", "-", "a"),
    ("!true", "!", true),
    ("!false", "!", false),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      expr = statement.expression
      @assert isa(expr, m.PrefixExpression) "statement.expression is not a PrefixExpression. Got $(typeof(expr)) instead."
      @assert expr.operator == operator "expr.operator is not $operator. Got $(expr.operator) instead."

      test_literal_expression(expr.right, right_value)
    end
  end
end

@testset "Test Parsing Infix Expressions" begin
  for (input, left_value, operator, right_value) in [
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
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      expr = statement.expression
      test_infix_expression(expr, left_value, operator, right_value)
    end
  end
end

@testset "Test Parsing If Expression" begin
  for (input) in [
    ("if (x < y) { x }")
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      expr = statement.expression

      @assert isa(expr, m.IfExpression) "expr is not an IfExpression. Got $(typeof(expr)) instead."

      test_infix_expression(expr.condition, "x", "<", "y")

      @assert length(expr.consequence.statements) == 1 "consequence.statements does not contain 1 statement. Got $(length(expr.consequence.statements)) instead."

      consequence = expr.consequence.statements[1]
      @assert isa(consequence, m.ExpressionStatement) "consequence.statements[1] is not an ExpressionStatement. Got $(typeof(consequence.statements[1])) instead."

      test_identifier(consequence.expression, "x")

      @assert isnothing(expr.alternative) "expr.alternative is not nothing. Got $(expr.alternative) instead."

      true
    end
  end
end

@testset "Test Parsing If Else Expression" begin
  for (input) in [
    ("if (x < y) { x } else { y }")
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      expr = statement.expression

      @assert isa(expr, m.IfExpression) "expr is not an IfExpression. Got $(typeof(expr)) instead."

      test_infix_expression(expr.condition, "x", "<", "y")

      @assert length(expr.consequence.statements) == 1 "consequence.statements does not contain 1 statement. Got $(length(expr.consequence.statements)) instead."

      consequence = expr.consequence.statements[1]
      @assert isa(consequence, m.ExpressionStatement) "consequence.statements[1] is not an ExpressionStatement. Got $(typeof(consequence.statements[1])) instead."

      test_identifier(consequence.expression, "x")

      alternative = expr.alternative.statements[1]
      @assert isa(alternative, m.ExpressionStatement) "alternative.statements[1] is not an ExpressionStatement. Got $(typeof(alternative.statements[1])) instead."

      test_identifier(alternative.expression, "y")
    end
  end
end

@testset "Test Parsing Functional Literal" begin
  for (input) in [
    ("fn(x, y) { x + y; }"),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      fn = statement.expression

      @assert isa(fn, m.FunctionLiteral) "fn is not a FunctionLiteral. Got $(typeof(fn)) instead."

      @assert length(fn.parameters) == 2 "fn.parameters does not contain 2 parameters. Got $(length(fn.parameters)) instead."

      test_literal_expression(fn.parameters[1], "x")
      test_literal_expression(fn.parameters[2], "y")

      @assert length(fn.body.statements) == 1 "fn.body.statements does not contain 1 statement. Got $(length(fn.body.statements)) instead."

      body_statement = fn.body.statements[1]
      @assert isa(body_statement, m.ExpressionStatement) "body.statement[1] is not an ExpressionStatement. Got $(typeof(body_statement)) instead."

      test_infix_expression(body_statement.expression, "x", "+", "y")
    end
  end
end

@testset "Test Parsing Function Parameters" begin
  for (input, expected) in [
    ("fn() {};", []),
    ("fn(x) {};", ["x"]),
    ("fn(x, y, z) {};", ["x", "y", "z"]),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      fn = statement.expression

      @assert length(fn.parameters) == length(expected) "fn.parameters does not contain $(length(expected)) parameters. Got $(length(fn.parameters)) instead."

      for (parameter, expected_parameter) in zip(fn.parameters, expected)
        test_literal_expression(parameter, expected_parameter)
      end

      true
    end
  end
end

@testset "Test Parsing Call Expression" begin
  for (input) in [
    ("add(1, 2 * 3, 4 + 5)"),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert length(program.statements) == 1 "program.statements does not contain 1 statement. Got $(length(program.statements)) instead."
      @assert isa(program.statements[1], m.ExpressionStatement) "program.statements[1] is not an ExpressionStatement. Got $(typeof(program.statements[1])) instead."

      statement = program.statements[1]
      expr = statement.expression

      @assert isa(expr, m.CallExpression) "expr is not a CallExpression. Got $(typeof(expr)) instead."

      test_identifier(expr.fn, "add")

      @assert length(expr.arguments) == 3 "expr.arguments does not contain $(length(expected)) arguments. Got $(length(expr.arguments)) instead."

      test_literal_expression(expr.arguments[1], 1)
      test_infix_expression(expr.arguments[2], 2, "*", 3)
      test_infix_expression(expr.arguments[3], 4, "+", 5)
    end
  end
end

@testset "Test Parsing String Literal Expression" begin
  input = "\"hello world\""

  @test begin
    l = m.Lexer(input)
    p = m.Parser(l)
    program = m.parse!(p)

    check_parser_errors(p)

    expr = program.statements[1].expression
    @assert isa(expr, m.StringLiteral) "expr is not a StringLiteral. Got $(typeof(expr)) instead."

    @assert expr.value == "hello world" "expr.value is not \"hello world\". Got $(expr.value) instead."

    true
  end
end

@testset "Test Parsing Array Literal" begin
  input = "[1, 2 * 2, 3 + 3]"

  @test begin
    l = m.Lexer(input)
    p = m.Parser(l)
    program = m.parse!(p)

    check_parser_errors(p)

    arr = program.statements[1].expression
    @assert isa(arr, m.ArrayLiteral) "expr is not a ArrayLiteral. Got $(typeof(arr)) instead."

    @assert length(arr.elements) == 3 "length(arr.elements) is not 3. Got $(length(arr.elements)) instead."

    test_integer_literal(arr.elements[1], 1)
    test_infix_expression(arr.elements[2], 2, "*", 2)
    test_infix_expression(arr.elements[3], 3, "+", 3)

    true
  end
end

@testset "Test Parsing Index Expression" begin
  input = "myArray[1 + 1]"

  @test begin
    l = m.Lexer(input)
    p = m.Parser(l)
    program = m.parse!(p)

    check_parser_errors(p)

    expr = program.statements[1].expression
    @assert isa(expr, m.IndexExpression) "expr is not an IndexExpression. Got $(typeof(expr)) instead."

    test_identifier(expr.left, "myArray")
    test_infix_expression(expr.index, 1, "+", 1)
  end
end

@testset "Test Parsing Hash Literal" begin
  @testset "Test Parsing Hash Literal with String Keys" begin
    input = """{"one": 1, "two": 2, "three": 3}"""
    expected = Dict("one" => 1, "two" => 2, "three" => 3)

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      hash = program.statements[1].expression
      @assert isa(hash, m.HashLiteral) "hash is not a HashLiteral. Got $(typeof(hash)) instead."

      @assert length(hash.pairs) == 3 "length(hash.pairs) is not 3. Got $(length(hash.pairs)) instead."

      for (key, value) in hash.pairs
        @assert isa(key, m.StringLiteral) "key is not a StringLiteral. Got $(typeof(key)) instead."

        @assert string(key) ∈ keys(expected) "$key should not exist"

        test_integer_literal(value, expected[string(key)])
      end

      true
    end
  end

  @testset "Test Parsing Hash Literal with String Keys and Expression Values" begin
    input = """{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}"""
    tests = Dict(
      "one" => x -> test_infix_expression(x, 0, "+", 1),
      "two" => x -> test_infix_expression(x, 10, "-", 8),
      "three" => x -> test_infix_expression(x, 15, "/", 5),
    )

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      hash = program.statements[1].expression
      @assert isa(hash, m.HashLiteral) "hash is not a HashLiteral. Got $(typeof(hash)) instead."

      @assert length(hash.pairs) == 3 "length(hash.pairs) is not 3. Got $(length(hash.pairs)) instead."

      for (key, value) in hash.pairs
        @assert isa(key, m.StringLiteral) "key is not a StringLiteral. Got $(typeof(key)) instead."

        @assert key.value ∈ keys(tests) "$key should not exist"

        tests[key.value](value)
      end

      true
    end
  end

  @testset "Test Parsing Hash Literal with Integer Keys" begin
    input = "{1: 1, 2: 2, 3: 3}"
    expected = Dict(1 => 1, 2 => 2, 3 => 3)

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      hash = program.statements[1].expression
      @assert isa(hash, m.HashLiteral) "hash is not a HashLiteral. Got $(typeof(hash)) instead."

      @assert length(hash.pairs) == 3 "length(hash.pairs) is not 3. Got $(length(hash.pairs)) instead."

      for (key, value) in hash.pairs
        @assert isa(key, m.IntegerLiteral) "key is not an IntegerLiteral. Got $(typeof(key)) instead."

        @assert key.value ∈ keys(expected) "$key should not exist"

        test_integer_literal(value, expected[key.value])
      end

      true
    end
  end

  @testset "Test Parsing Hash Literal with Boolean Keys" begin
    input = "{false: 0, true: 1}"
    expected = Dict(false => 0, true => 1)

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      hash = program.statements[1].expression
      @assert isa(hash, m.HashLiteral) "hash is not a HashLiteral. Got $(typeof(hash)) instead."

      @assert length(hash.pairs) == 2 "length(hash.pairs) is not 2. Got $(length(hash.pairs)) instead."

      for (key, value) in hash.pairs
        @assert isa(key, m.BooleanLiteral) "key is not a BooleanLiteral. Got $(typeof(key)) instead."

        @assert key.value ∈ keys(expected) "$key should not exist"

        test_integer_literal(value, expected[key.value])
      end

      true
    end
  end

  @testset "Test Parsing Empty Hash Literal" begin
    input = "{}"

    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      hash = program.statements[1].expression
      @assert isa(hash, m.HashLiteral) "hash is not a HashLiteral. Got $(typeof(hash)) instead."

      @assert length(hash.pairs) == 0 "length(hash.pairs) is not 0. Got $(length(hash.pairs)) instead."

      true
    end
  end
end

@testset "Test Operator Order" begin
  for (input, expected) in [
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
    ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
    ("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"),
    ("a * [1, 2, 3, 4][b * c] * d", "((a * ([1, 2, 3, 4][(b * c)])) * d)"),
    ("add(a * b[2], b[1], 2 * [1, 2][1])", "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)

      check_parser_errors(p)

      @assert string(program) == expected "expected = $expected, got = $(string(program))"

      true
    end
  end
end

@testset "Test Parsing Errors" begin
  for (input, expected) in [
    ("100000000000000000000", ["ERROR: parse error: could not parse 100000000000000000000 as integer"]),
    ("{1:2", ["ERROR: parse error: expected next token to be COMMA, got EOF instead"]),
    ("{1}", ["ERROR: parse error: expected next token to be COLON, got RBRACE instead", "ERROR: parse error: no prefix parse function for RBRACE found"]),
    ("[1", ["ERROR: parse error: expected next token to be RBRACKET, got EOF instead"]),
    ("{1:2}[1", ["ERROR: parse error: expected next token to be RBRACKET, got EOF instead"]),
    ("fn x", ["ERROR: parse error: expected next token to be LPAREN, got IDENT instead"]),
    ("fn (x {x}", ["ERROR: parse error: expected next token to be RPAREN, got LBRACE instead"]),
    ("fn (x) x", ["ERROR: parse error: expected next token to be LBRACE, got IDENT instead"]),
    ("if x", ["ERROR: parse error: expected next token to be LPAREN, got IDENT instead"]),
    ("if (x", ["ERROR: parse error: expected next token to be RPAREN, got EOF instead"]),
    ("if (x) c", ["ERROR: parse error: expected next token to be LBRACE, got IDENT instead"]),
    ("if (x) { 1 } else 2", ["ERROR: parse error: expected next token to be LBRACE, got INT instead"]),
    ("let 5", ["ERROR: parse error: expected next token to be IDENT, got INT instead"]),
    ("let x 3", ["ERROR: parse error: expected next token to be ASSIGN, got INT instead"]),
  ]
    @test begin
      l = m.Lexer(input)
      p = m.Parser(l)
      program = m.parse!(p)
      @assert map(string, p.errors) == expected "expected = $expected, got = $(map(string, p.errors))"

      true
    end
  end
end
