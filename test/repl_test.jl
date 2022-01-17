using .Threads

@testset "Test REPL" begin
  for (raw_input, expected) in [
    (b"1\n2\n", ["1", "2"]),
    (b"a\n", ["ERROR: identifier not found: a"]),
    (b"1 / 0\n", ["ERROR: divide error: division by zero"]),
    (b"1 ++ 2\n", ["ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found"]),
    (b"5 + 3; 23 -- ; f((\n", ["ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead"]),
    (b"let a=fn(x) {a(x)}; a(3)\n", ["ERROR: stack overflow"]),
    (b"let a = macro(x) {x + x}; a(2)\n", ["ERROR: macro error: we only support returning AST-nodes from macros"]),
    (b"puts(\"Hello, world!\")\n", ["Hello, world!\nnull"]),
  ]
    @test begin
      input = IOBuffer(raw_input)
      output = IOBuffer(UInt8[], read = true, write = true)
      m.start_repl(input = input, output = output)
      String(output.data) == m.REPL_PRELUDE * "\n" * join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") * "\n"
    end
  end
end
