@testset "Julia Transpiler" begin
    t = m.Transpilers.JuliaTranspiler

    @testset "Expressions" begin
        for (input, expected) in [
            ("4", 4),
            ("\"foobar\"", "foobar"),
            ("false", false),
            ("true", true),
            ("null", nothing),
            ("2 * (-4 + 6 / (4 - 10) + 1000)", 1990),
            ("!true", false),
            ("!false", true),
            ("!null", true),
            ("!3", false),
            ("![2, 3]", false),
            ("1 == 2", false),
            ("1 != 2", true),
            ("2 < 3", true),
            ("2 > 3", false),
            ("\"foo\" == \"bar\"", false),
            ("\"foo\" != \"bar\"", true),
            ("\"foo\" + \"bar\"", "foobar"),
            ("[1, 2, 3] == [1, 2, 3]", true),
            ("[1, 2, 3] != [1, 2]", true),
            ("{1: 2, 3: 4} == {3: 4, 1: 2}", true),
            ("{1: 2, 3: 4} != {4: 3, 1: 2}", true),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Array Literals" begin
        for (input, expected) in [
            ("[2 * 3, 4 - 5, 1 / 2, \"hello\"]", [6, -1, 0, "hello"]),
            ("[2, [2, [2, [2]]]]", [2, [2, [2, [2]]]]),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Hash Literals" begin
        for (input, expected) in [
            (
                "{2: 3, 4: \"hello\", false: true, [2, 4]: {1: 1}}",
                Dict(2 => 3, 4 => "hello", false => true, [2, 4] => Dict(1 => 1)),
            ),
            ("{1: 2, 1: 3, 1: 4}", Dict(1 => 4)),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Index Expressions" begin
        for (input, expected) in [
            ("[1, 2, 3, 4][0]", 1),
            ("[1, 2, 3, 4][4]", nothing),
            ("{1: 2, 3: 4}[1]", 2),
            ("{1: 2, 3: 4}[4]", nothing),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Assignments" begin
        for (input, expected) in [
            ("let a = 2; a;", 2),
            ("let a = 2; a = 3; a = 4; a;", 4),
            ("let a = 3; let b = 4; let c = a + b; c;", 7),
            (
                "let a = [2, 3]; let b = {1: false}; let c = {a: b}; c;",
                Dict([2, 3] => Dict(1 => false)),
            ),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Function Calls" begin
        for (input, expected) in [
            ("(fn() { })()", nothing),
            ("(fn(x) { x * 2  })(1)", 2),
            ("(fn(x, y) { x + y }(1, 2))", 3),
            ("let a = fn(x) { x * x }; [a(1), a(2), a(3)];", [1, 4, 9]),
            ("let a = fn(x, y) { x + y }; let x = 1; let y = 2; a(x, y);", 3),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "If Expressions" begin
        for (input, expected) in [
            ("if (true) { 2 }", 2),
            ("if (false) { 2 }", nothing),
            ("if (false) { 2 } else { 3 }", 3),
            ("if (3) { 2 } else { 3 }", 2),
            ("if (null) { 2 } else { 3 }", 3),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "While Statements" begin
        for (input, expected) in [(
            """
            let x = 3; 
            let y = 0;
            while (x > 0) { 
                y = y + x; 
                x = x - 1; 
            } 
            y;
            """,
            6,
        )]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Builtins" begin
        for (input, expected) in [
            ("len([])", 0),
            ("len(\"hello\")", 5),
            ("first([])", nothing),
            ("first([1])", 1),
            ("first([false, [2, 3]])", false),
            ("first(\"\")", nothing),
            ("first(\"中国人\")", "中"),
            ("last([])", nothing),
            ("last([2, 3, true])", true),
            ("last(\"\")", nothing),
            ("last(\"Hello 世界\")", "界"),
            ("rest([])", nothing),
            ("rest([1])", []),
            ("rest([2, 3])", [3]),
            ("rest(\"\")", nothing),
            ("rest(\"a\")", ""),
            ("rest(\"Hello 世界\")", "ello 世界"),
            ("rest(\"你好 World\")", "好 World"),
            ("push([], 2)", [2]),
            ("push({}, 2, 3)", Dict(2 => 3)),
            ("type(false)", "BOOLEAN"),
            ("type(0)", "INTEGER"),
            ("type(null)", "NULL"),
            ("type(fn (x) { x })", "FUNCTION"),
            ("type(\"hello\")", "STRING"),
            ("type([1, 2])", "ARRAY"),
            ("type({1:2})", "HASH"),
        ]
            ans = eval(t.transpile(m.parse(input)))
            @test ans == expected
        end
    end

    @testset "Test puts()" begin
        for (input, expected) in [
            ("puts()", ""),
            ("puts(1)", "1\n"),
            ("puts(\"hello\")", "hello\n"),
            ("puts([23, \"hello\", false])", "[23, \"hello\", false]\n"),
            ("puts({2: false})", "{2: false}\n"),
            ("puts(23, \"hello\", false)", "23\nhello\nfalse\n"),
        ]
            output = IOBuffer(UInt8[], read = true, write = true)
            evaluated = eval(t.transpile(m.parse(input); output))
            @test isnothing(evaluated)
            @test String(take!(output)) == expected
        end
    end

    @testset "Test runtime errors" begin
        for (input, expected) in [
            (
                "len()",
                "ERROR: argument error: wrong number of arguments. Got 0 instead of 1\n",
            ),
            (
                "len(1)",
                "ERROR: argument error: argument to `len` is not supported, got INTEGER\n",
            ),
            (
                "push(1)",
                "ERROR: argument error: wrong number of arguments. Got 1 instead of 2 or 3\n",
            ),
            (
                "push(1, 2)",
                "ERROR: argument error: argument to `push` is not supported, got INTEGER\n",
            ),
            (
                "push([], 2, 4)",
                "ERROR: argument error: argument to `push` is not supported, got ARRAY\n",
            ),
            ("3[2]", "ERROR: index operator not supported: INTEGER\n"),
            ("[1, 2][false]", "ERROR: unsupported index type: BOOLEAN\n"),
            ("2(5)", "ERROR: not a function: INTEGER\n"),
            ("5 / 0", "ERROR: divide error: division by zero\n"),
        ]
            output = IOBuffer(UInt8[], read = true, write = true)
            evaluated = eval(t.transpile(m.parse(input); output))
            @test isnothing(evaluated)
            @test String(take!(output)) == expected
        end
    end

    @testset "Fib(35)" begin
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

        fibonacci(35);
        """

        evaluated = eval(t.transpile(m.parse(input)))
        @test evaluated == 9227465
    end

    @testset "Nested Scopes With Closure" begin
        input = """
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
        """

        evaluated = eval(t.transpile(m.parse(input)))
        @test evaluated == 150
    end

    @testset "String macros" begin
        for (code, expected, expected_output) in [
            ("let b = 4; b;", 4, ""),
            ("puts([1, 2, 3]);", nothing, "[1, 2, 3]\n"),
            ("let m = macro(x, y) { quote(unquote(y) - unquote(x)) }; m(5, 10);", 5, ""),
        ]
            c = IOCapture.capture() do
                eval(quote
                    $t.@monkey_julia_str($code)
                end)
            end

            @test c.value == expected
            @test c.output == expected_output
        end
    end
end
