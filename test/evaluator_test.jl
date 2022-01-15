function test_integer_object(obj::m.Object, expected::Int64)
  @assert isa(obj, m.IntegerObj) "obj is not an INTEGER. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_boolean_object(obj::m.Object, expected::Bool)
  @assert isa(obj, m.BooleanObj) "obj is not a BooleanObj. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_null_object(obj::m.Object)
  @assert obj === m._NULL "object is not NULL. Got $(obj) instead."

  true
end

function test_error_object(obj::m.Object, expected::String)
  @assert isa(obj, m.ErrorObj) "no error object returned. Got $(m.type_of(obj)) instead."

  @assert obj.message == expected "wrong error message. Got $(obj.message) instead."

  true
end

function test_string_object(obj::m.Object, expected::String)
  @assert isa(obj, m.StringObj) "no string object returned. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "Expected $expected. Got $(obj.value) instead."

  true
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
      evaluated = m.evaluate(input)
      test_integer_object(evaluated, expected)
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
      evaluated = m.evaluate(input)
      test_boolean_object(evaluated, expected)
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
      evaluated = m.evaluate(input)
      test_boolean_object(evaluated, expected)
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
      evaluated = m.evaluate(input)
      if isa(expected, Integer)
        test_integer_object(evaluated, expected)
      else
        test_null_object(evaluated)
      end
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
      evaluated = m.evaluate(input)
      test_integer_object(evaluated, expected)
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
      test_error_object(m.evaluate(input), expected_message)

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
      test_integer_object(m.evaluate(input), expected)
    end
  end
end

@testset "Test Function Object" begin
  @test begin
    input = "fn(x) { x + 2; };"
    evaluated = m.evaluate(input)
    @assert isa(evaluated, m.FunctionObj) "object is not a FUNCTION. Got $(m.type_of(evaluated)) instead."

    @assert string(evaluated.parameters[1]) == "x" "parameters[1] is not 'x'. Got $(string(evaluated.parameters[1])) instead."

    @assert string(evaluated.body) == "(x + 2)" "body is not '(x + 2)'. Got $(evaluated.body) instead."

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
      test_integer_object(m.evaluate(input), expected)
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
    test_integer_object(m.evaluate(input), 4)
  end
end

@testset "Test String Literal" begin
  input = "\"Hello World!\""

  @test begin
    evaluated = m.evaluate(input)
    @assert isa(evaluated, m.StringObj) "object is not a STRING. Got $(m.type_of(evaluated)) instead."

    @assert evaluated.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluated.value) instead."

    true
  end
end

@testset "Test String Concatenation" begin
  input = """"Hello" + " " + "World!\""""

  @test begin
    evaluated = m.evaluate(input)
    @assert isa(evaluated, m.StringObj) "object is not a STRING. Got $(m.type_of(evaluated)) instead."

    @assert evaluated.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluated.value) instead."

    true
  end
end

@testset "Test Builtin Functions" begin
  for (input, expected) in [
    ("len(\"\")", 0),
    ("len(\"four\")", 4),
    ("len(\"hello world\")", 11),
    ("len(1),", "argument error: argument to `len` is not supported, got INTEGER"),
    ("len(\"one\", \"two\")", "argument error: wrong number of arguments. Got 2 instead of 1"),
    ("""
      let map = fn(arr, f) {
        let iter = fn(arr, accumulated) { 
          if (len(arr) == 0) {  
            accumulated 
          } else { 
            iter(rest(arr), push(accumulated, f(first(arr)))); 
          } 
        };

        iter(arr, []);
      };

      let a = [1, 2, 3, 4];
      let double = fn(x) { x * 2};
      map(a, double)[3]
    """, 8),
    ("""
    let reduce = fn(arr, initial, f) {
      let iter = fn(arr, result) {
        if (len(arr) == 0) {
          result
        } else { 
          iter(rest(arr), f(result, first(arr)))
        }
      }

      iter(arr, initial)
    }

    let sum = fn(arr) { 
      reduce(arr, 0, fn(initial, el) { initial + el })
    }

    sum([1, 2, 3, 4, 5])
    """, 15),
    ("first([1, 2, 3])", 1),
    ("first([])", nothing),
    ("first(\"hello\")", "h"),
    ("first(\"\")", nothing),
    ("last([1, 2, 3])", 3),
    ("last([])", nothing),
    ("last(\"hello\")", "o"),
    ("last(\"\")", nothing),
    ("rest([1, 2, 3])[0]", 2),
    ("rest([])", nothing),
    ("rest(\"hello\")", "ello"),
    ("rest(\"\")", nothing),
    ("push([], 2)[0]", 2),
    ("push({2: 3}, 4, 5)[4]", 5),
    ("puts()", nothing),
    ("type(false)", "BOOLEAN"),
    ("type(0)", "INTEGER"),
    ("type(fn (x) { x })", "FUNCTION"),
    ("type(\"hello\")", "STRING"),
    ("type([1, 2])", "ARRAY"),
    ("type({1:2})", "HASH"),
  ]
    @test begin
      evaluated = m.evaluate(input)
      if isa(expected, String)
        if occursin("error", expected)
          test_error_object(evaluated, expected)
        else
          test_string_object(evaluated, expected)
        end
      elseif isa(expected, Integer)
        test_integer_object(evaluated, expected)
      elseif isnothing(expected)
        test_null_object(evaluated)
      end
    end
  end
end

@testset "Test Array Literal" begin
  input = "[1, 2 * 2, 3 + 3]"

  @test begin
    evaluated = m.evaluate(input)

    @assert isa(evaluated, m.ArrayObj) "evaluated is not an ARRAY. Got $(m.type_of(evaluated)) instead."

    @assert length(evaluated.elements) == 3 "length(evaluated.elements) is not 3. Got $(length(evaluated.elements)) instead."

    test_integer_object(evaluated.elements[1], 1)
    test_integer_object(evaluated.elements[2], 4)
    test_integer_object(evaluated.elements[3], 6)
  end
end

@testset "Test Array Index Expressions" begin
  for (input, expected) in [
    ("[1, 2, 3][0]", 1),
    ("[1, 2, 3][1]", 2),
    ("[1, 2, 3][2]", 3),
    ("let i = 0; [1][i]", 1),
    ("[1, 2, 3][1 + 1]", 3),
    ("let myArray = [1, 2, 3]; myArray[2];", 3),
    ("let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2]", 6),
    ("let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", 2),
    ("[1, 2, 3][3]", nothing),
    ("[1, 2, 3][-1]", nothing),
  ]
    @test begin
      evaluated = m.evaluate(input)
      if isa(expected, Int)
        test_integer_object(evaluated, expected)
      else
        test_null_object(evaluated)
      end
    end
  end
end

@testset "Test Hash Literal" begin
  input = """
    let two = "two";
    {
      "one": 10 - 9,
      two: 1 + 1,
      "thr" + "ee": 6 / 2,
      4: 4,
      true: 5,
      false: 6,
    }
  """

  @test begin
    hash = m.evaluate(input)

    expected = [
      (m.StringObj("one"), 1),
      (m.StringObj("two"), 2),
      (m.StringObj("three"), 3),
      (m.IntegerObj(4), 4),
      (m.BooleanObj(true), 5),
      (m.BooleanObj(false), 6),
    ]

    @assert length(hash.pairs) == 6 "length(hash.pairs) is not 6. Got $(length(hash.pairs)) instead."

    for (key, value) in expected
      @assert key ∈ keys(hash.pairs) "$key not found."

      test_integer_object(hash.pairs[key], value)
    end

    true
  end
end

@testset "Test Hash Index Expressions" begin
  for (input, expected) in [
    ("{\"foo\": 5}[\"foo\"]", 5),
    ("{\"foo\": 5}[\"bar\"]", nothing),
    ("let key = \"foo\"; {\"foo\": 5}[key]", 5),
    ("{}[\"foo\"]", nothing),
    ("{5: 5}[5]", 5),
    ("{true: 5}[true]", 5),
    ("{false: 5}[false]", 5),
  ]
    @test begin
      evaluated = m.evaluate(input)
      if isa(expected, Integer)
        test_integer_object(evaluated, expected)
      else
        test_null_object(evaluated)
      end
    end
  end
end

@testset "Test Recursive Function Call" begin
  input = """
  let fibonacci = fn(x) {
    if (x == 0) {
      0
    } else {
      if (x == 1) {
        return 1;
      } else {
        fibonacci(x - 1) + fibonacci(x - 2);
      }
    }
  };

  fibonacci(10)
  """

  @test begin
    evaluated = m.evaluate(input)
    test_integer_object(evaluated, 55)
  end
end
