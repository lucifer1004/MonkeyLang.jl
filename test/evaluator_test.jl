@testset "Test Evaluator" begin
    @testset "Test Evaluating Integer Expressions" begin
        for (code, expected) in [
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
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Evaluating Boolean Expressions" begin
        for (code, expected) in [
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
            ("\"a\" == \"a\"", true),
            ("\"a\" != \"a\"", false),
            ("\"a\" == \"b\"", false),
            ("\"a\" != \"b\"", true),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Bang Operator" begin
        for (code, expected) in [
            ("!true", false),
            ("!false", true),
            ("!5", false),
            ("!!true", true),
            ("!!false", false),
            ("!!5", true),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test If Else Expressions" begin
        for (code, expected) in [
            ("if (true) { 10 }", 10),
            ("if (false) { 10 }", nothing),
            ("if (null) { 2 } else { 3 }", 3),
            ("if (1) { 10 }", 10),
            ("if (1 < 2) { 10 }", 10),
            ("if (1 > 2) { 10 }", nothing),
            ("if (1 > 2) { 10 } else { 20 }", 20),
            ("if (1 < 2) { 10 } else { 20 }", 10),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Return Statements" begin
        for (code, expected) in [
            ("return 10;", 10),
            ("return 10; 9;", 10),
            ("return 2 * 5; 9;", 10),
            ("9; return 2 * 5; 9;", 10),
            (
                """
               if (10 > 1) {
                 if (10 > 1) {
                   return 10;
                 }

                 return 1;
               }
               """,
                10,
            ),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Error Handling" begin
        for (code, expected_message) in [
            ("5 + true", "type mismatch: INTEGER + BOOLEAN"),
            ("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
            ("-true", "unknown operator: -BOOLEAN"),
            ("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
            ("5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"),
            ("if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"),
            (
                """
               if (10 > 1) {
                 if (10 > 1) {
                   return true + false;
                 }

                 return 1;
               }
               """,
                "unknown operator: BOOLEAN + BOOLEAN",
            ),
            ("foobar", "identifier not found: foobar"),
            ("\"Hello\" - \"World\"", "unknown operator: STRING - STRING"),
            ("5 / 0", "divide error: division by zero"),
            ("[5 / 0]", "divide error: division by zero"),
            ("{5 / 0: 2}", "divide error: division by zero"),
            ("{2: 5 / 0}", "divide error: division by zero"),
            ("(5 / 0) + (5 / 0)", "divide error: division by zero"),
            ("if (5 / 0) { 2 }", "divide error: division by zero"),
            ("(5 / 0)()", "divide error: division by zero"),
            ("let a = fn(x) { x }; a(5 / 0);", "divide error: division by zero"),
            ("{1:2}[5 / 0]", "divide error: division by zero"),
            ("(5 / 0)[2]", "divide error: division by zero"),
            ("let a = 5 / 0", "divide error: division by zero"),
            ("\"str\"[1]", "index operator not supported: STRING"),
            ("[1, 2, 3][\"23\"]", "unsupported index type: STRING"),
            ("if (true) { 5 / 0; 2 + 3; 4; }", "divide error: division by zero"),
            ("2(3)", "not a function: INTEGER"),
        ]
            @test begin
                test_object(m.evaluate(code), expected_message)

                true
            end
        end
    end

    @testset "Test Let Statements" begin
        for (code, expected) in [
            ("let a = 5; a;", 5),
            ("let a = 5 * 5; a;", 25),
            ("let a = 5; let b = a; b;", 5),
            ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
        ]
            @test begin
                test_object(m.evaluate(code), expected)
            end
        end
    end

    @testset "Test Function Object" begin
        @test begin
            code = "fn(x) { x + 2; };"
            evaluated = m.evaluate(code)
            @assert isa(evaluated, m.FunctionObj) "object is not a FUNCTION. Got $(m.type_of(evaluated)) instead."

            @assert string(evaluated.parameters[1]) == "x" "parameters[1] is not 'x'. Got $(string(evaluated.parameters[1])) instead."

            @assert string(evaluated.body) == "(x + 2)" "body is not '(x + 2)'. Got $(evaluated.body) instead."

            true
        end
    end

    @testset "Test Function Application" begin
        for (code, expected) in [
            ("let identity = fn(x) { x; }; identity(5);", 5),
            ("let identity = fn(x) { return x; }; identity(5);", 5),
            ("let double = fn(x) { x * 2; }; double(5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
            ("fn(x) { x; }(5)", 5),
        ]
            @test begin
                test_object(m.evaluate(code), expected)
            end
        end
    end

    @testset "Test Closures" begin
        code = """
        let newAdder = fn(x) { 
          fn(y) { x + y };
        }

        let addTwo = newAdder(2);
        addTwo(2);
        """

        @test begin
            test_object(m.evaluate(code), 4)
        end
    end

    @testset "Test String Literal" begin
        code = "\"Hello World!\""

        @test begin
            evaluated = m.evaluate(code)
            @assert isa(evaluated, m.StringObj) "object is not a STRING. Got $(m.type_of(evaluated)) instead."

            @assert evaluated.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluated.value) instead."

            true
        end
    end

    @testset "Test String Concatenation" begin
        code = """"Hello" + " " + "World!\""""

        @test begin
            evaluated = m.evaluate(code)
            @assert isa(evaluated, m.StringObj) "object is not a STRING. Got $(m.type_of(evaluated)) instead."

            @assert evaluated.value == "Hello World!" "value is not 'Hello World!'. Got $(evaluated.value) instead."

            true
        end
    end

    @testset "Test Builtin Functions" begin
        for (code, expected) in [
            ("len(\"\")", 0),
            ("len(\"four\")", 4),
            ("len(\"hello world\")", 11),
            ("len(1),", "argument error: argument to `len` is not supported, got INTEGER"),
            (
                "len(\"one\", \"two\")",
                "argument error: wrong number of arguments. Got 2 instead of 1",
            ),
            (
                """
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
               """,
                8,
            ),
            (
                """
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
               """,
                15,
            ),
            (
                "first([1, 2], [2])",
                "argument error: wrong number of arguments. Got 2 instead of 1",
            ),
            ("first([1, 2, 3])", 1),
            ("first([])", nothing),
            ("first(\"hello\")", "h"),
            ("first(\"\")", nothing),
            (
                "first(1)",
                "argument error: argument to `first` is not supported, got INTEGER",
            ),
            ("last([1, 2, 3])", 3),
            ("last([])", nothing),
            ("last(\"hello\")", "o"),
            ("last(\"\")", nothing),
            ("last(1)", "argument error: argument to `last` is not supported, got INTEGER"),
            (
                "last([1, 2], [2])",
                "argument error: wrong number of arguments. Got 2 instead of 1",
            ),
            ("rest([1, 2, 3])[0]", 2),
            ("rest([])", nothing),
            ("rest(\"hello\")", "ello"),
            ("rest(\"\")", nothing),
            ("rest(1)", "argument error: argument to `rest` is not supported, got INTEGER"),
            (
                "rest([1, 2], [2])",
                "argument error: wrong number of arguments. Got 2 instead of 1",
            ),
            (
                "push()",
                "argument error: wrong number of arguments. Got 0 instead of 2 or 3",
            ),
            (
                "push({}, 2)",
                "argument error: argument to `push` is not supported, got HASH",
            ),
            (
                "push([], 2, 3)",
                "argument error: argument to `push` is not supported, got ARRAY",
            ),
            ("push([], 2)[0]", 2),
            ("push({2: 3}, 4, 5)[4]", 5),
            ("type(1, 2)", "argument error: wrong number of arguments. Got 2 instead of 1"),
            ("type(false)", "BOOLEAN"),
            ("type(0)", "INTEGER"),
            ("type(fn (x) { x })", "FUNCTION"),
            ("type(\"hello\")", "STRING"),
            ("type([1, 2])", "ARRAY"),
            ("type({1:2})", "HASH"),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end

        @testset "Test puts()" begin
            for (code, expected) in [
                ("puts()", ""),
                ("puts(1)", "1\n"),
                ("puts(\"hello\")", "hello\n"),
                ("puts([23, \"hello\"])", "[23, \"hello\"]\n"),
            ]
                @test begin
                    output = IOBuffer(UInt8[], read = true, write = true)
                    evaluated = m.evaluate(code; output = output)
                    test_object(evaluated, nothing)
                    String(output.data) == expected
                end
            end
        end
    end

    @testset "Test Array Literal" begin
        code = "[1, 2 * 2, 3 + 3]"

        @test begin
            evaluated = m.evaluate(code)

            @assert isa(evaluated, m.ArrayObj) "evaluated is not an ARRAY. Got $(m.type_of(evaluated)) instead."

            @assert length(evaluated.elements) == 3 "length(evaluated.elements) is not 3. Got $(length(evaluated.elements)) instead."

            test_object(evaluated.elements[1], 1)
            test_object(evaluated.elements[2], 4)
            test_object(evaluated.elements[3], 6)
        end
    end

    @testset "Test Array Index Expressions" begin
        for (code, expected) in [
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
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Hash Literal" begin
        code = """
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
            hash = m.evaluate(code)

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
                test_object(hash.pairs[key], value)
            end

            true
        end
    end

    @testset "Test Hash Index Expressions" begin
        for (code, expected) in [
            ("{\"foo\": 5}[\"foo\"]", 5),
            ("{\"foo\": 5}[\"bar\"]", nothing),
            ("let key = \"foo\"; {\"foo\": 5}[key]", 5),
            ("{}[\"foo\"]", nothing),
            ("{5: 5}[5]", 5),
            ("{true: 5}[true]", 5),
            ("{false: 5}[false]", 5),
        ]
            @test begin
                evaluated = m.evaluate(code)
                test_object(evaluated, expected)
            end
        end
    end

    @testset "Test Recursive Function Call" begin
        code = """
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
            evaluated = m.evaluate(code)
            test_object(evaluated, 55)
        end
    end

    @testset "Test Defining Macro" begin
        code = """
          let number = 1;
          let function = fn(x, y) { x + y };
          let mymacro = macro(x, y) { x + y };
        """

        @test begin
            env = m.Environment()
            program = m.define_macros!(env, m.parse(code))

            @assert length(program.statements) == 2 "length(program.statements) is not 2. Got $(length(program.statements)) instead."
            @assert isnothing(m.get(env, "number")) "number should not be defined"
            @assert isnothing(m.get(env, "function")) "function should not be defined"

            mc = m.get(env, "mymacro")
            @assert !isnothing(mc) "mymacro should be defined"

            @assert length(mc.parameters) == 2 "length(mc.parameters) is not 2. Got $(length(mc.parameters)) instead."

            @assert string(mc.parameters[1]) == "x" "mc.parameters[1] is not x. Got $(string(mc.parameters[1])) instead."

            @assert string(mc.parameters[2]) == "y" "mc.parameters[2] is not y. Got $(string(mc.parameters[2])) instead."

            @assert string(mc.body) == "(x + y)" "mc.body is not (x + y). Got $(string(mc.body)) instead."

            true
        end
    end

    @testset "Test Expanding Macros" begin
        for (code, expected) in [
            (
                "let infixExpression = macro() { quote(1 + 2) }; infixExpression();",
                "(1 + 2)",
            ),
            (
                "let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);",
                "((10 - 5) - (2 + 2))",
            ),
            (
                """
                let unless = macro(condition, consequence, alternative) {
                    quote(if (!(unquote(condition))) {
                        unquote(consequence);
                    } else {
                        unquote(alternative);
                    });
                };

                unless(10 > 5, puts("not greater"), puts("greater"));
                """,
                "if ((!(10 > 5))) { puts(\"not greater\") } else { puts(\"greater\") }",
            ),
        ]
            @test begin
                env = m.Environment()
                program = m.define_macros!(env, m.parse(code))
                expanded = m.expand_macros(program, env)

                @assert string(expanded) == expected "Expected $expected. Got $expanded instead."

                true
            end
        end
    end
end
