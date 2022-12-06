@testset "Test Evaluator" begin
    @testset "General" begin
    # General tests for all backends
    test_backend(m.evaluate, "evaluator") end

    # These cases should not occur unless the internal data are malformed.
    @testset "Test Malformed Expressions" begin
        test_object(m.evaluate_prefix_expression("+", m.IntegerObj(1)),
                    "unknown operator: +INTEGER")

        test_object(m.evaluate_infix_expression("&", m.IntegerObj(1), m.IntegerObj(1)),
                    "unknown operator: INTEGER & INTEGER")
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

    @testset "Test Expanding Macros" begin for (code, expected) in [
        ("let infixExpression = macro() { quote(1 + 2) }; infixExpression();",
         "(1 + 2)"),
        ("let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);",
         "((10 - 5) - (2 + 2))"),
        ("""
         let unless = macro(condition, consequence, alternative) {
             quote(if (!(unquote(condition))) {
                 unquote(consequence);
             } else {
                 unquote(alternative);
             });
         };

         unless(10 > 5, puts("not greater"), puts("greater"));
         """,
         "if ((!(10 > 5))) { puts(\"not greater\") } else { puts(\"greater\") }"),
    ]
        env = m.Environment()
        program = m.define_macros!(env, m.parse(code))
        expanded = m.expand_macros(program, env)
        @test string(expanded) == expected
    end end

    @testset "String macro" begin for (code, expected, expected_output) in [
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
    end end
end
