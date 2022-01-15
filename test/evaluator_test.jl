function test_evaluate(input::String)
  l = m.Lexer(input)
  p = m.Parser(l)
  program = m.parse!(p)
  env = m.Environment()

  return m.evaluate(program, env)
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

@testset "Test Error Handling" begin
  for (input, expected_message) in [
    ("5 + true", "type mismatch: INTEGER + BOOLEAN"),
    ("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
    ("-true", "unknown operator: -BOOLEAN"),
    ("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
    ("5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"),
    ("if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"),
    ("""
    if (10 > 1) {
      if (10 > 1) {
        return true + false;
      }

      return 1;
    }
    """, "unknown operator: BOOLEAN + BOOLEAN"),
    ("foobar", "identifier not found: foobar"),
    ("\"Hello\" - \"World\"", "unknown operator: STRING - STRING"),
  ]
    @test begin
      evaluted = test_evaluate(input)
      @assert isa(evaluted, m.Error) "no error object returned. Got $(typeof(evaluted)) instead."

      @assert evaluted.message == expected_message "wrong error message. Got $(evaluted.message) instead."

      true
    end
  end
end

@testset "Test Let Statements" begin
  for (input, expected) in [
    ("let a = 5; a;", 5),
    ("let a = 5 * 5; a;", 25),
    ("let a = 5; let b = a; b;", 5),
    ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
  ]
    @test begin
      test_integer_object(test_evaluate(input), expected)

      true
    end
  end
end

@testset "Test Function Object" begin
  @test begin
    input = "fn(x) { x + 2; };"
    evaluted = test_evaluate(input)
    @assert isa(evaluted, m.FunctionObj) "object is not a FunctionObj. Got $(typeof(evaluted)) instead."

    @assert string(evaluted.parameters[1]) == "x" "parameters[1] is not 'x'. Got $(string(evaluted.parameters[1])) instead."

    @assert string(evaluted.body) == "(x + 2)" "body is not '(x + 2)'. Got $(evaluted.body) instead."

    true
  end
end

@testset "Test Function Application" begin
  for (input, expected) in [
    ("let identity = fn(x) { x; }; identity(5);", 5),
    ("let identity = fn(x) { return x; }; identity(5);", 5),
    ("let double = fn(x) { x * 2; }; double(5);", 10),
    ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
    ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
    ("fn(x) { x; }(5)", 5),
  ]
    @test begin
      test_integer_object(test_evaluate(input), expected)

      true
    end
  end
end

@testset "Test Closures" begin
  input = """
  let newAdder = fn(x) { 
    fn(y) { x + y };
  }

  let addTwo = newAdder(2);
  addTwo(2);
  """

  @test begin
    test_integer_object(test_evaluate(input), 4)

    true
  end
end

@testset "Test String Literal" begin
  input = "\"Hello World!\""

  @test begin
    evaluted = test_evaluate(input)
    @assert isa(evaluted, m.StringObj) "object is not a StringObj. Got $(typeof(evaluted)) instead."

    @assert evaluted.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluted.value) instead."

    true
  end
end

@testset "Test String Concatenation" begin
  input = """"Hello" + " " + "World!\""""

  @test begin
    evaluted = test_evaluate(input)
    @assert isa(evaluted, m.StringObj) "object is not a StringObj. Got $(typeof(evaluted)) instead."

    @assert evaluted.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluted.value) instead."

    true
  end
end
