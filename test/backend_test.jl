function test_backend(run::Function, name::String; check_object::Bool = true)
    function check(code::String, expected, expected_output::String = "")
        c = IOCapture.capture() do
            run(code)
        end

        if check_object
            test_object(c.value, expected)
        else
            @test c.value == expected
        end

        @test c.output == expected_output
    end

    @testset "Empty program" begin
        @test isnothing(run(""))
    end

    @testset "Integer expression" begin
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
            check(code, expected)
        end
    end

    @testset "Boolean expression" begin
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
            check(code, expected)
        end
    end

    @testset "String expression" begin
        for (code, expected) in [
            ("\"Hello World!\"", "Hello World!"),
            ("\"newline\n\n\t\"", "newline\n\n\t"),
            (""""Hello" + " " + "World!\"""", "Hello World!"),
        ]
            check(code, expected)
        end
    end

    @testset "Array" begin
        @testset "Literal" begin
            for (code, expected) in
                [("[]", []), ("[1, 2, 3]", [1, 2, 3]), ("[1, 2 * 2, 3 + 3]", [1, 4, 6])]
                check(code, expected)
            end
        end

        @testset "Index" begin
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
                check(code, expected)
            end
        end
    end

    @testset "Hash" begin
        @testset "Literal" begin
            for (input, expected) in [
                ("""{"foo": "bar", true: false}""", Dict("foo" => "bar", true => false)),
                ("{1: 2, 1: 3, 1: 4}", Dict(1 => 4)),
                (
                    "{null: [], [2]: null, {3: 5}: {\"1\": 2}}",
                    Dict(nothing => [], [2] => nothing, Dict(3 => 5) => Dict("1" => 2)),
                ),
            ]
                check(input, expected)
            end
        end

        @testset "Index" begin
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
                check(code, expected)
            end

            @testset "Maybe broken" begin
                for (code, expected) in [
                    ("let a = {1: 2, true: 3}; a[1] + a[true]", 5), # Julia backend fails this test since in Julia `true == 1` holds
                ]
                    if name == "julia"
                        @test_broken run(code) == expected
                    else
                        check(code, expected)
                    end
                end
            end
        end
    end

    @testset "Bang operator" begin
        for (code, expected) in [
            ("!true", false),
            ("!false", true),
            ("!5", false),
            ("!!true", true),
            ("!!false", false),
            ("!!5", true),
            ("!\"hello\"", false),
            ("!null", true),
            ("![1, 2, 3]", false),
            ("!{1: 2}", false),
            ("!(fn(x) {x})", false),
        ]
            check(code, expected)
        end
    end

    @testset "If-else expression" begin
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
            check(code, expected)
        end
    end

    @testset "While statement" begin
        @testset "Plain" begin
            for (code, expected) in [
                ("let x = 1; while (false) { x = x + 1; } x", 1),
                ("let x = 1; let y = 1; while (y > 0) { y = y - 1; x = x + 1; } x", 2),
            ]
                check(code, expected)
            end
        end

        @testset "Nested" begin
            for (code, expected) in [(
                """
                let a = 6;
                let b = a;
                let x = 1;
                while (x > 0) {
                    x = x - 1;
                    a = 5;
                    b = b + a;
                    let c = 8;
                    c = c / 2;
                    b = b + c;
                    let y = 1;
                    while (y > 0) {
                        y = y - 1;
                        a = a + 3;
                        b = b + a;
                    }
                }
                b = b + a;
                """,
                31,
            )]
                check(code, expected)
            end
        end

        @testset "Inside functions" begin
            for (code, expected) in [
                (
                    """
                    let f = fn(x) {
                        while (x > 0) {
                            if (x == 3) {
                                return 4;
                            }
                            x = x - 1;
                        }
                    }
                    f(4);
                    """,
                    4,
                ),
                (
                    """
                    let f = fn(x) {
                        while (x > 0) {
                            if (x == 3) {
                                return 4;
                            }
                            x = x - 1;
                        }
                    }
                    f(2);
                    """,
                    nothing,
                ),
                (
                    """
                    let x = 5;
                    let y = 0;
                    while (x > 0) {
                        x = x - 1;
                        let z = 5;
                        let f = fn() {
                            let w = 1;
                            while (z > 0) {
                                w = w * 2;
                                y = y + z * w;
                                z = z - 1;
                                f();
                            }
                        }
                        f();
                    }
                    y;
                    """,
                    150,
                ),
            ]
                check(code, expected)
            end
        end
    end

    @testset "Break statement" begin
        for (code, expected) in [(
            """
            let a = 2;
            let b = 0;
            while (a > 0) {
                b = b + a;
                if (a == 2) {
                    break;
                }
                a = a - 1;
            }
            b;
            """,
            2,
        )]
            check(code, expected)
        end
    end

    @testset "Continue statement" begin
        for (code, expected) in [(
            """
            let a = 4;
            let b = 0;
            while (a > 0) {
                a = a - 1;
                if (a == 2) {
                    continue;
                }
                b = b + a;
            }
            b;
            """,
            4,
        )]
            check(code, expected)
        end
    end

    @testset "Return statement" begin
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
            ("while (true) { return 10; }", 10),
        ]
            check(code, expected)
        end
    end

    @testset "Let statement" begin
        @testset "Plain" begin
            for (code, expected) in [
                ("let a = 5; a;", 5),
                ("let a = 5 * 5; a;", 25),
                ("let a = 5; let b = a; b;", 5),
                ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
                ("let a = 5; a = a + 1; a;", 6),
            ]
                check(code, expected)
            end
        end

        @testset "Reassign" begin
            for (code, expected) in [("let a = 5; a = a + 1; a;", 6)]
                check(code, expected)
            end
        end

        @testset "Redefine" begin
            for (code, expected) in [(
                """
                let x = 5;
                let y = 1;
                let z = 0;
                while (y > 0) {
                    z = z + x;
                    let x = 9;
                    z = z + x;
                    y = y - 1;
                }
                z = z + x;
                z;
                """,
                19,
            )]
                if name == "julia"
                    @test_broken run(code) == expected
                else
                    check(code, expected)
                end
            end
        end
    end

    @testset "Function" begin
        if name == "evaluator"
            @testset "Definition" begin
                code = "fn(x) { x + 2; };"
                result = run(code)

                @test isa(result, m.FunctionObj)
                @test string(result.parameters[1]) == "x"
                @test string(result.body) == "(x + 2)"
            end
        end

        @testset "Application" begin
            for (code, expected) in [
                ("let identity = fn(x) { x; }; identity(5);", 5),
                ("let identity = fn(x) { return x; }; identity(5);", 5),
                ("let double = fn(x) { x * 2; }; double(5);", 10),
                ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
                ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
                ("fn(x) { x; }(5)", 5),
            ]
                check(code, expected)
            end
        end

        @testset "Closure" begin
            for (code, expected) in [(
                """
               let newAdder = fn(x) { 
                 fn(y) { x + y };
               }

               let addTwo = newAdder(2);
               addTwo(2);
               """,
                4,
            ), (
                """
                let a = 2;
                let ans = [];

                let g = fn() {
                    let b = 2;
                    let f = fn() {
                        b = b - 1;
                        return b;
                    }
                    return f;
                }

                let f = g();

                ans = push(ans, f());
                ans = push(ans, f());

                let ff = g();

                ans = push(ans, ff());
                ans = push(ans, ff());

                ans;
                """,
                [1, 0, 1, 0],
            )]
                check(code, expected)
            end
        end

        @testset "Recursion" begin
            for (code, expected) in [(
                """
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

                fibonacci(10);
                """,
                55,
            )]
                check(code, expected)
            end
        end
    end

    @testset "Built-in functions" begin
        @testset "len" begin
            for (code, expected) in [
                ("len(\"\")", 0),
                ("len(\"four\")", 4),
                ("len([1, 2, 3])", 3),
                ("len([])", 0),
                ("len([[1, 2, 3], [4, 5, 6]])", 2),
                ("len({\"a\": 1, \"b\": 2})", 2),
                ("len({})", 0),
            ]
                check(code, expected)
            end
        end

        @testset "first" begin
            for (code, expected) in [
                ("first([1, 2, 3])", 1),
                ("first([])", nothing),
                ("first(\"hello\")", "h"),
                ("first(\"\")", nothing),
            ]
                check(code, expected)
            end
        end

        @testset "last" begin
            for (code, expected) in [
                ("last([1, 2, 3])", 3),
                ("last([])", nothing),
                ("last(\"hello\")", "o"),
                ("last(\"\")", nothing),
            ]
                check(code, expected)
            end
        end

        @testset "rest" begin
            for (code, expected) in [
                ("rest([1, 2, 3])", [2, 3]),
                ("rest([1])", []),
                ("rest([])", nothing),
                ("rest(\"hello\")", "ello"),
                ("rest(\"h\")", ""),
                ("rest(\"\")", nothing),
            ]
                check(code, expected)
            end
        end

        @testset "push" begin
            for (code, expected) in [("push([], 2)[0]", 2), ("push({2: 3}, 4, 5)[4]", 5)]
                check(code, expected)
            end
        end

        @testset "type" begin
            for (code, expected) in [
                ("type(false)", m.BOOLEAN_OBJ),
                ("type(true)", m.BOOLEAN_OBJ),
                ("type(null)", m.NULL_OBJ),
                ("type(0)", m.INTEGER_OBJ),
                ("type(fn (x) { x })", name == "vm" ? m.CLOSURE_OBJ : m.FUNCTION_OBJ),
                ("type(\"hello\")", m.STRING_OBJ),
                ("type([1, 2])", m.ARRAY_OBJ),
                ("type({1:2})", m.HASH_OBJ),
            ]
                check(code, expected)
            end
        end

        @testset "puts" begin
            for (code, expected_output) in [
                ("puts()", ""),
                ("puts(1)", "1\n"),
                ("puts(\"hello\")", "hello\n"),
                ("puts([23, \"hello\"])", "[23, \"hello\"]\n"),
            ]
                check(code, nothing, expected_output)
            end
        end

        @testset "Complex combination" begin
            for (code, expected) in [
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
            ]
                check(code, expected)
            end
        end
    end

    @testset "Macro" begin
        for (code, expected) in [
            (
                """
                let double_len_macro = macro(x) { quote(len(unquote(x)) * 2); };
                let double_len = double_len_macro([1, 2, 3]);
                    double_len;
                """,
                6,
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

                unless(10 > 5, "not greater", "greater");
                """,
                "greater",
            ),
        ]
            check(code, expected)
        end
    end

    @testset "Error handling" begin
        @testset "Invalid expression" begin
            for (code, expected) in [
                # `INTEGER + BOOLEAN` works well in Julia
                ("5 + null", "type mismatch: INTEGER + NULL"),
                ("5 + null; 5;", "type mismatch: INTEGER + NULL"),
                ("-null", "unknown operator: -NULL"),
                ("null + null;", "unknown operator: NULL + NULL"),
                ("5; null + null; 5", "unknown operator: NULL + NULL"),
                ("if (10 > 1) { null + null; }", "unknown operator: NULL + NULL"),
                (
                    """
                    if (10 > 1) {
                        if (10 > 1) {
                            return null + null;
                        }

                        return 1;
                    }
                   """,
                    "unknown operator: NULL + NULL",
                ),
                ("\"Hello\" - \"World\"", "unknown operator: STRING - STRING"),
                ("5 / 0", "divide error: division by zero"),
                ("[5 / 0]", "divide error: division by zero"),
                ("{5 / 0: 2}", "divide error: division by zero"),
                ("{2: 5 / 0}", "divide error: division by zero"),
                ("(5 / 0) + (5 / 0)", "divide error: division by zero"),
                ("if (5 / 0) { 2 }", "divide error: division by zero"),
                ("while (5 / 0) { 2 }", "divide error: division by zero"),
                ("(5 / 0)()", "divide error: division by zero"),
                ("let a = fn(x) { x }; a(5 / 0);", "divide error: division by zero"),
                ("{1:2}[5 / 0]", "divide error: division by zero"),
                ("(5 / 0)[2]", "divide error: division by zero"),
                ("let a = 5 / 0", "divide error: division by zero"),
                ("if (true) { 5 / 0; 2 + 3; 4; }", "divide error: division by zero"),
                ("\"str\"[1]", "index operator not supported: STRING"),
                ("[1, 2, 3][\"23\"]", "unsupported index type: STRING"),
                ("2(3)", "not a function: INTEGER"),
                ("fn() { 1; }(1);", "argument error: wrong number of arguments: got 1"),
                ("fn(a) { a; }();", "argument error: wrong number of arguments: got 0"),
                (
                    "fn(a, b) { a + b; }(1);",
                    "argument error: wrong number of arguments: got 1",
                ),
            ]
                if check_object
                    check(code, expected, "ERROR: $expected\n")
                else
                    check(code, nothing, "ERROR: $expected\n")
                end
            end

            @testset "Semantic analysis" begin
                for (code, expected) in [
                    ("foobar", "identifier not found: foobar"),
                    ("x = 2;", "identifier not found: x"),
                    ("let a = 2; let a = 4;", "a is already defined"),
                ]
                    if check_object
                        check(code, expected, "ERROR: $expected\n")
                    else
                        check(code, nothing, "ERROR: $expected\n")
                    end
                end
            end
        end

        @testset "Built-in function" begin
            for (code, expected) in [
                (
                    "len(1)",
                    "argument error: argument to `len` is not supported, got INTEGER",
                ),
                (
                    "len(\"one\", \"two\")",
                    "argument error: wrong number of arguments. Got 2 instead of 1",
                ),
                (
                    "first([1, 2], [2])",
                    "argument error: wrong number of arguments. Got 2 instead of 1",
                ),
                (
                    "first(1)",
                    "argument error: argument to `first` is not supported, got INTEGER",
                ),
                (
                    "last(1)",
                    "argument error: argument to `last` is not supported, got INTEGER",
                ),
                (
                    "last([1, 2], [2])",
                    "argument error: wrong number of arguments. Got 2 instead of 1",
                ),
                (
                    "rest(1)",
                    "argument error: argument to `rest` is not supported, got INTEGER",
                ),
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
                (
                    "type(1, 2)",
                    "argument error: wrong number of arguments. Got 2 instead of 1",
                ),
            ]
                if check_object
                    check(code, expected, "ERROR: $expected\n")
                else
                    check(code, nothing, "ERROR: $expected\n")
                end
            end
        end
    end
end
