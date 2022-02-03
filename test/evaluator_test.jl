@testset "Test Evaluator" begin
    @testset "Test Evaluating Empty Program" begin
        @test isnothing(m.evaluate(""))
    end

    # These cases should not occur unless the internal data are malformed.
    @testset "Test Malformed Expressions" begin
        test_object(
            m.evaluate_prefix_expression("+", m.IntegerObj(1)),
            "unknown operator: +INTEGER",
        )

        test_object(
            m.evaluate_infix_expression("&", m.IntegerObj(1), m.IntegerObj(1)),
            "unknown operator: INTEGER & INTEGER",
        )
    end

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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
        end
    end

    @testset "Test While Statements" begin
        for (code, expected) in [
            ("let x = 1; while (false) { x = x + 1; } x", 1),
            ("let x = 1; let y = 1; while (y > 0) { y = y - 1; x = x + 1; } x", 2),
        ]
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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
            (
                """
                while (true) {
                    return 10;
                }
                """,
                10,
            ),
        ]
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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
            ("x = 2;", "identifier not found: x"),
            (
                "while (len(1)) { puts(2); }",
                "argument error: argument to `len` is not supported, got INTEGER",
            ),
            ("let a = 2; let a = 4;", "a is already defined"),
        ]
            test_object(m.evaluate(code), expected_message)
        end
    end

    @testset "Test Let Statements" begin
        @testset "Plain" begin
            for (code, expected) in [
                ("let a = 5; a;", 5),
                ("let a = 5 * 5; a;", 25),
                ("let a = 5; let b = a; b;", 5),
                ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
                ("let a = 5; a = a + 1; a;", 6),
            ]
                test_object(m.evaluate(code), expected)
            end
        end

        @testset "Reassign" begin
            for (code, expected) in [("let a = 5; a = a + 1; a;", 6)]
                test_object(m.evaluate(code), expected)
            end
        end

        @testset "Nested Scopes" begin
            for (code, expected) in [(
                """
                let a = 6;
                let b = 0;
                let x = 1;
                while (x > 0) {
                    x = x - 1;
                    let a = 5;
                    b = b + a;
                    let y = 1;
                    while (y > 0) {
                        y = y - 1;
                        a = a + 3;
                        b = b + a;
                    }
                }
                b = b + a;
                """,
                19,
            )]
                test_object(m.evaluate(code), expected)
            end
        end
    end

    @testset "Test Function Object" begin
        code = "fn(x) { x + 2; };"
        evaluated = m.evaluate(code)

        @test isa(evaluated, m.FunctionObj)
        @test string(evaluated.parameters[1]) == "x"
        @test string(evaluated.body) == "(x + 2)"
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
            test_object(m.evaluate(code), expected)
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

        test_object(m.evaluate(code), 4)
    end

    @testset "Test String Literal" begin
        code = "\"Hello World!\""
        evaluated = m.evaluate(code)

        @test isa(evaluated, m.StringObj)
        @test evaluated.value == "Hello World!"
    end

    @testset "Test String Concatenation" begin
        code = """"Hello" + " " + "World!\""""
        evaluated = m.evaluate(code)

        @test isa(evaluated, m.StringObj)
        @test evaluated.value == "Hello World!"
    end

    @testset "Test Builtin Functions" begin
        for (code, expected) in [
            ("len(\"\")", 0),
            ("len(\"four\")", 4),
            ("len(\"hello world\")", 11),
            ("len(1)", "argument error: argument to `len` is not supported, got INTEGER"),
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
                let double = fn(x) { x * 2 };
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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
        end

        @testset "Test puts()" begin
            for (code, expected) in [
                ("puts()", ""),
                ("puts(1)", "1\n"),
                ("puts(\"hello\")", "hello\n"),
                ("puts([23, \"hello\"])", "[23, \"hello\"]\n"),
            ]
                output = IOBuffer(UInt8[], read = true, write = true)
                evaluated = m.evaluate(code; output = output)
                test_object(evaluated, nothing)
                @test String(take!(output)) == expected
            end
        end
    end

    @testset "Test Array Literal" begin
        code = "[1, 2 * 2, 3 + 3]"
        evaluated = m.evaluate(code)

        @test isa(evaluated, m.ArrayObj)
        @test length(evaluated.elements) == 3

        test_object(evaluated.elements[1], 1)
        test_object(evaluated.elements[2], 4)
        test_object(evaluated.elements[3], 6)
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
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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

        hash = m.evaluate(code)

        expected = [
            (m.StringObj("one"), 1),
            (m.StringObj("two"), 2),
            (m.StringObj("three"), 3),
            (m.IntegerObj(4), 4),
            (m.BooleanObj(true), 5),
            (m.BooleanObj(false), 6),
        ]

        @test length(hash.pairs) == 6

        for (key, value) in expected
            @test key ∈ keys(hash.pairs)
            test_object(hash.pairs[key], value)
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
            ("let a = [1, 2]; {a: 2}[[1, 2]]", 2),
            ("let a = {1: 2, 3: 4}; {a: 2}[{3: 4, 1: 2}]", 2),
        ]
            evaluated = m.evaluate(code)
            test_object(evaluated, expected)
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

        evaluated = m.evaluate(code)
        test_object(evaluated, 55)
    end

    @testset "Test Defining Macro" begin
        code = """
          let number = 1;
          let function = fn(x, y) { x + y };
          let mymacro = macro(x, y) { x + y };
        """

        env = m.Environment()
        program = m.define_macros!(env, m.parse(code))

        @test length(program.statements) == 2
        @test isnothing(m.get(env, "number"))
        @test isnothing(m.get(env, "function"))

        mc = m.get(env, "mymacro")
        @test !isnothing(mc)
        @test length(mc.parameters) == 2
        @test string(mc.parameters[1]) == "x"
        @test string(mc.parameters[2]) == "y"
        @test string(mc.body) == "(x + y)"
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
            env = m.Environment()
            program = m.define_macros!(env, m.parse(code))
            expanded = m.expand_macros(program, env)
            @test string(expanded) == expected
        end
    end

    @testset "String macros" begin
        for (code, expected, expected_output) in [
            ("let b = 4; b;", 4, ""),
            ("puts([1, 2, 3]);", nothing, "[1, 2, 3]\n"),
            ("let m = macro(x, y) { quote(unquote(y) - unquote(x)) }; m(5, 10);", 5, ""),
        ]
            c = IOCapture.capture() do
                eval(quote
                    m.@monkey_eval_str($code)
                end)
            end

            test_object(c.value, expected)
            @test c.output == expected_output
        end
    end
end
