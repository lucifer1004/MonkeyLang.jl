using .Threads

@testset "Test REPL" begin
    @testset "Use Evaluator" begin
        for (raw_input, expected) in [
            (b"1\n2\n", ["1", "2"]),
            (b"a\n", ["ERROR: identifier not found: a"]),
            (b"1 / 0\n", ["ERROR: divide error: division by zero"]),
            (
                b"1 ++ 2\n",
                [
                    "ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found",
                ],
            ),
            (
                b"5 + 3; 23 -- ; f((\n",
                [
                    "ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead",
                ],
            ),
            (b"let a=fn(x) {a(x)}; a(3)\n", ["ERROR: runtime error: stack overflow"]),
            (
                b"let a = macro(x) {x + x}; a(2)\n",
                ["ERROR: macro error: we only support returning AST-nodes from macros"],
            ),
            (
                b"let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);\n",
                ["1"],
            ),
            (b"puts(\"Hello, world!\")\n", ["Hello, world!\nnull"]),
        ]
            input = IOBuffer(raw_input)
            output = IOBuffer(UInt8[], read = true, write = true)
            m.start_repl(input = input, output = output)
            @test String(output.data) ==
                  m.REPL_PRELUDE *
                  "\n" *
                  join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") *
                  "\n"
        end
    end

    @testset "Use Bytecode VM" begin
        for (raw_input, expected) in [
            (b"1\n2\n", ["1", "2"]),
            (b"a\n", ["ERROR: compilation error: identifier not found: a"]),
            (
                b"let b = 1 / 0;\nb;\n",
                [
                    "ERROR: divide error: division by zero",
                    "ERROR: compilation error: identifier not found: b",
                ],
            ),
            (
                b"1 ++ 2\n",
                [
                    "ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found",
                ],
            ),
            (
                b"5 + 3; 23 -- ; f((\n",
                [
                    "ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead",
                ],
            ),
            # (b"let a=fn(x) {a(x)}; a(3)\n", ["ERROR: stack overflow"]),
            (
                b"let a = macro(x) {x + x}; a(2)\n",
                ["ERROR: macro error: we only support returning AST-nodes from macros"],
            ),
            (
                b"let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);\n",
                ["1"],
            ),
            (b"puts(\"Hello, world!\")\n", ["Hello, world!\nnull"]),
        ]
            input = IOBuffer(raw_input)
            output = IOBuffer(UInt8[], read = true, write = true)
            m.start_repl(input = input, output = output, use_vm = true)
            @test String(output.data) ==
                  m.REPL_PRELUDE *
                  "\n" *
                  join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") *
                  "\n"
        end
    end
end
