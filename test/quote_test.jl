@testset "Test Quote" begin
    @testset "quote" begin
        @test isa(m.evaluate("quote()"), m.NullObj)

        for (input, expected) in [
            ("quote(5)", "5"),
            ("quote(5 + 8)", "(5 + 8)"),
            ("quote(foobar)", "foobar"),
            ("quote(foobar + barfoo)", "(foobar + barfoo)"),
        ]
            evaluated = m.evaluate(input)
            test_quote_object(evaluated, expected)
        end
    end

    @testset "quote and unquote" begin
        for (input, expected) in [
            ("quote(unquote(4))", "4"),
            ("quote(unquote(4 + 4))", "8"),
            ("quote(8 + unquote(4 + 4))", "(8 + 8)"),
            ("quote(unquote(4 + 4) + 8)", "(8 + 8)"),
            ("quote(unquote(null))", "null"),
            ("quote(unquote(true))", "true"),
            ("quote(unquote(true == false))", "false"),
            ("quote(unquote(\"hello\"))", "\"hello\""),
            ("quote(unquote([1, 2, 3]))", "[1, 2, 3]"),
            ("quote(unquote({2 + 3: \"4\" + \"5\"}))", "{5:\"45\"}"),
            ("quote(unquote(fn(x){x}))", "fn(x) {\n    x\n}"),
            ("quote(unquote(quote(4 + 4)))", "(4 + 4)"),
            (
                "let quotedInfixExpression = quote(4 + 4); quote(unquote(4 + 4) + unquote(quotedInfixExpression))",
                "(8 + (4 + 4))",
            ),
        ]
            evaluated = m.evaluate(input)
            test_quote_object(evaluated, expected)
        end
    end
end
