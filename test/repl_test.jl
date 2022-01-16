@testset "Test REPL" begin
  for (raw_input, expected) in [
    (b"1\n2\n\n", ["1", "2"]),
    (b"a\n\n", ["ERROR: identifier not found: a"]),
    (b"1 / 0\n\n", ["ERROR: divide error: division by zero"]),
    (b"1 ++ 2\n\n", ["ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found"]),
    (b"5 + 3; 23 -- ; f((\n\n", ["ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead"]),
    (b"let a=fn(x) {a(x)}; a(3)", ["ERROR: stack overflow"]),
  ]
    @test begin
      input = IOBuffer(raw_input)
      output = IOBuffer(UInt8[], read = true, write = true)
      m.start_repl(input = input, output = output)
      String(output.data) == m.REPL_PRELUDE * "\n" * join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") * "\n"
    end
  end
end
