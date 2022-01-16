function test_quote_object(evaluated::m.Object, expected::String)
  @assert isa(evaluated, m.QuoteObj) "evaluated is not a QuoteObj. Got $(typeof(evaluated)) instead."

  string(evaluated.node) == expected
end

@testset "Test quote" begin
  for (input, expected) in [
    ("quote(5)", "5"),
    ("quote(5 + 8)", "(5 + 8)"),
    ("quote(foobar)", "foobar"),
    ("quote(foobar + barfoo)", "(foobar + barfoo)"),
  ]
    @test begin
      evaluated = m.evaluate(input)
      test_quote_object(evaluated, expected)
    end
  end
end

@testset "Test quote and unquote" begin
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
    ("quote(unquote(fn(x){x}))", "fn(x) {x}"),
    ("quote(unquote(quote(4 + 4)))", "(4 + 4)"),
    (
      "let quotedInfixExpression = quote(4 + 4); quote(unquote(4 + 4) + unquote(quotedInfixExpression))",
      "(8 + (4 + 4))",
    ),
  ]
    @test begin
      evaluated = m.evaluate(input)
      test_quote_object(evaluated, expected)
    end
  end
end
