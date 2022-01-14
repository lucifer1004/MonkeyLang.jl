function test_evaluate(input::String)
  l = m.Lexer(input)
  p = m.Parser(l)
  program = m.parse!(p)

  return m.evaluate(program)
end

function test_integer_object(obj::m.Object, expected::Int64)
  @assert isa(obj, m.Integer) "obj is not an Integer. Got $(typeof(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."
end

function test_boolean_object(obj::m.Object, expected::Bool)
  @assert isa(obj, m.Boolean) "obj is not a Boolean. Got $(typeof(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."
end

function test_null_object(obj::m.Object)
  @assert obj === m._NULL "object is not NULL. Got $(obj) instead."
end

@testset "Test Evaluating Integer Expressions" begin
  for (input, expected) in [
    ("5", 5),
    ("10", 10),
    ("-5", -5),
    ("-10", -10),
    ("5 + 5 + 5 + 5 - 10", 10),
    ("2 * 2 * 2 * 2 * 2", 32),
    ("-50 + 100 + -50", 0),
    ("5 * 2 + 10", 20),
    ("5 + 2 * 10", 25),
    ("20 + 2 * -10", 0),
    ("50 / 2 * 2 + 10", 60),
    ("2 * (5 + 10)", 30),
    ("3 * 3 * 3 + 10", 37),
    ("3 * (3 * 3) + 10", 37),
    ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
  ]
    @test begin
      evaluted = test_evaluate(input)
      test_integer_object(evaluted, expected)

      true
    end
  end
end

@testset "Test Evaluating Boolean Expressions" begin
  for (input, expected) in [
    ("false", false),
    ("true", true),
    ("1 < 2", true),
    ("1 > 2", false),
    ("1 < 1", false),
    ("1 > 1", false),
    ("1 == 1", true),
    ("1 != 1", false),
    ("1 == 2", false),
    ("1 != 2", true),
    ("true == true", true),
    ("false == false", true),
    ("true == false", false),
    ("true != false", true),
    ("false != true", true),
    ("(1 < 2) == true", true),
    ("(1 < 2) == false", false),
    ("(1 > 2) == true", false),
    ("(1 > 2) == false", true),
  ]
    @test begin
      evaluted = test_evaluate(input)
      test_boolean_object(evaluted, expected)

      true
    end
  end
end

@testset "Test Bang Operator" begin
  for (input, expected) in [
    ("!true", false),
    ("!false", true),
    ("!5", false),
    ("!!true", true),
    ("!!false", false),
    ("!!5", true),
  ]
    @test begin
      evaluted = test_evaluate(input)
      test_boolean_object(evaluted, expected)

      true
    end
  end
end

@testset "Test If Else Expressions" begin
  for (input, expected) in [
    ("if (true) { 10 }", 10),
    ("if (false) { 10 }", m._NULL),
    ("if (1) { 10 }", 10),
    ("if (1 < 2) { 10 }", 10),
    ("if (1 > 2) { 10 }", m._NULL),
    ("if (1 > 2) { 10 } else { 20 }", 20),
    ("if (1 < 2) { 10 } else { 20 }", 10),
  ]
    @test begin
      evaluted = test_evaluate(input)
      if isa(expected, Integer)
        test_integer_object(evaluted, expected)
      else
        test_null_object(evaluted)
      end

      true
    end
  end
end

@testset "Test Return Statements" begin
  for (input, expected) in [
    ("return 10;", 10),
    ("return 10; 9;", 10),
    ("return 2 * 5; 9;", 10),
    ("9; return 2 * 5; 9;", 10),
    ("""
    if (10 > 1) {
      if (10 > 1) {
        return 10;
      }

      return 1;
    }
    """, 10)
  ]
    @test begin
      evaluted = test_evaluate(input)
      test_integer_object(evaluted, expected)

      true
    end
  end
end
