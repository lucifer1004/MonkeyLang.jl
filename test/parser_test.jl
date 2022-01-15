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
end

function test_integer_literal(il::m.Expression, value::Int64)
  @assert isa(il, m.IntegerLiteral) "il is not an IntegerLiteral. Got $(typeof(il)) instead."
  @assert il.value == value "il.value is not $value. Got $(il.value) instead."
  @assert m.token_literal(il) == string(value) "token_literal(il) is not $value. Got $(m.token_literal(il)) instead."
end

function test_boolean_literal(bl::m.Expression, value::Bool)
  @assert isa(bl, m.BooleanLiteral) "il is not a BooleanLiteral. Got $(typeof(bl)) instead."
  @assert bl.value == value "bl.value is not $value. Got $(bl.value) instead."
  @assert m.token_literal(bl) == string(value) "token_literal(bl) is not $value. Got $(m.token_literal(bl)) instead."
end

function test_literal_expression(expr::m.Expression, expected)
  if isa(expected, Int)
    test_integer_literal(expr, Int64(expected))
  elseif isa(expected, String)
    test_identifier(expr, expected)
  elseif isa(expected, Bool)
    test_boolean_literal(expr, expected)
  else
    error("unexpected type for expected")
  end
end

function test_infix_expression(expr::m.Expression, left, operator::String, right)
  @assert isa(expr, m.InfixExpression) "expr is not an InfixExpression. Got $(typeof(expr)) instead."

  test_literal_expression(expr.left, left)

  @assert expr.operator == operator "expr.operator is not $operator. Got $(expr.operator) instead."

  test_literal_expression(expr.right, right)
end

@testset "Test Parsing Let Statements" begin
  for (input, expected_ident, expected_value) in [
    ("let x = 5;", "x", 5),
    ("let y = true;", "y", true),
    ("let foobar = y;", "foobar", "y"),
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

      true
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

      true
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

      true
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

      true
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

      true
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

      true
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

      true
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

      true
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

      true
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

      true
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
