using .Threads

@testset "Test REPL" begin
    @testset "ReplMaker parser function - Interpreter" begin
        # Initialize interpreter mode
        m._REPL_USE_VM[] = false
        m._REPL_ENV[] = m.Environment()
        m._REPL_MACRO_ENV[] = m.Environment()

        # Empty input
        @test isnothing(m._monkey_repl_parser(""))
        @test isnothing(m._monkey_repl_parser("   "))

        # Basic expressions
        result = m._monkey_repl_parser("1 + 2")
        @test result isa m.IntegerObj
        @test result.value == 3

        result = m._monkey_repl_parser("\"hello\" + \" world\"")
        @test result isa m.StringObj
        @test result.value == "hello world"

        result = m._monkey_repl_parser("!true")
        @test result isa m.BooleanObj
        @test result.value == false

        # Variable binding persists across calls
        m._monkey_repl_parser("let x = 10")
        result = m._monkey_repl_parser("x * 2")
        @test result isa m.IntegerObj
        @test result.value == 20

        # Variable reassignment
        m._monkey_repl_parser("x = 30")
        result = m._monkey_repl_parser("x")
        @test result isa m.IntegerObj
        @test result.value == 30

        # Function definition and call
        m._monkey_repl_parser("let add = fn(a, b) { a + b }")
        result = m._monkey_repl_parser("add(3, 4)")
        @test result isa m.IntegerObj
        @test result.value == 7

        # Array and indexing
        m._monkey_repl_parser("let arr = [1, 2, 3]")
        result = m._monkey_repl_parser("arr[1]")
        @test result isa m.IntegerObj
        @test result.value == 2

        # Hash and indexing
        m._monkey_repl_parser("let h = {\"a\": 1, \"b\": 2}")
        result = m._monkey_repl_parser("h[\"a\"]")
        @test result isa m.IntegerObj
        @test result.value == 1

        # Built-in functions
        result = m._monkey_repl_parser("len(\"hello\")")
        @test result isa m.IntegerObj
        @test result.value == 5

        result = m._monkey_repl_parser("first([10, 20, 30])")
        @test result isa m.IntegerObj
        @test result.value == 10

        # If expression
        result = m._monkey_repl_parser("if (true) { 1 } else { 2 }")
        @test result isa m.IntegerObj
        @test result.value == 1

        # Parser error - single error
        result = m._monkey_repl_parser("1 ++ 2")
        @test result isa m.ErrorObj
        @test occursin("parser has 1 error", result.message)

        # Parser error - multiple errors
        result = m._monkey_repl_parser("1 ++ 2 ++ 3")
        @test result isa m.ErrorObj
        @test occursin("parser has 2 errors", result.message)

        # Runtime error - undefined identifier
        result = m._monkey_repl_parser("undefined_var")
        @test result isa m.ErrorObj
        @test occursin("identifier not found", result.message)

        # Runtime error - division by zero
        result = m._monkey_repl_parser("10 / 0")
        @test result isa m.ErrorObj
        @test occursin("division by zero", result.message)

        # Macro support
        m._monkey_repl_parser("let unless = macro(cond, cons, alt) { quote(if (!unquote(cond)) { unquote(cons) } else { unquote(alt) }) }")
        result = m._monkey_repl_parser("unless(false, 1, 2)")
        @test result isa m.IntegerObj
        @test result.value == 1

        # Macro error - returning non-AST node
        m._monkey_repl_parser("let badmacro = macro(x) { x + x }")
        result = m._monkey_repl_parser("badmacro(2)")
        @test result isa m.ErrorObj
        @test occursin("macro error", result.message)

        # Stack overflow error (recursive function)
        m._monkey_repl_parser("let recurse = fn(x) { recurse(x) }")
        result = m._monkey_repl_parser("recurse(1)")
        @test result isa m.ErrorObj
        @test occursin("stack overflow", result.message)

        # Syntax check error - reassigning current function
        result = m._monkey_repl_parser("let f = fn(x) { f = 3 }")
        @test result isa m.ErrorObj
        @test occursin("cannot reassign", result.message)
    end

    @testset "ReplMaker parser function - VM" begin
        # Initialize VM mode
        m._REPL_USE_VM[] = true
        m._REPL_ENV[] = nothing
        m._REPL_MACRO_ENV[] = m.Environment()
        m._REPL_CONSTANTS[] = m.Object[]
        m._REPL_GLOBALS[] = m.Object[]
        m._REPL_SYMBOL_TABLE[] = m.SymbolTable()
        for (i, (name, _)) in enumerate(m.BUILTINS)
            m.define_builtin!(m._REPL_SYMBOL_TABLE[], name, i - 1)
        end

        # Empty input
        @test isnothing(m._monkey_repl_parser(""))

        # Basic expression
        result = m._monkey_repl_parser("5 * 5")
        @test result isa m.IntegerObj
        @test result.value == 25

        # Variable binding persists
        m._monkey_repl_parser("let y = 100")
        result = m._monkey_repl_parser("y - 50")
        @test result isa m.IntegerObj
        @test result.value == 50

        # Function in VM
        m._monkey_repl_parser("let double = fn(x) { x * 2 }")
        result = m._monkey_repl_parser("double(21)")
        @test result isa m.IntegerObj
        @test result.value == 42

        # Array in VM
        result = m._monkey_repl_parser("len([1, 2, 3, 4])")
        @test result isa m.IntegerObj
        @test result.value == 4

        # Runtime error recovery - undefined variable should not corrupt state
        result = m._monkey_repl_parser("unknown_var")
        @test result isa m.ErrorObj

        # Previous bindings should still work after error
        result = m._monkey_repl_parser("y")
        @test result isa m.IntegerObj
        @test result.value == 100

        # Division by zero in VM - triggers dangling symbol cleanup
        result = m._monkey_repl_parser("let bad = 1 / 0")
        @test result isa m.ErrorObj
        @test occursin("division by zero", result.message)

        # Verify dangling symbol cleanup works - can define new variable after error
        result = m._monkey_repl_parser("let good = 42")
        result = m._monkey_repl_parser("good")
        @test result isa m.IntegerObj
        @test result.value == 42

        # Syntax check error in VM mode - reassigning current function
        result = m._monkey_repl_parser("let f = fn(x) { f = 3 }")
        @test result isa m.ErrorObj
        @test occursin("cannot reassign", result.message)

        # Multiple errors after dangling cleanup - ensure state is still consistent
        result = m._monkey_repl_parser("let bad2 = 10 / 0")
        @test result isa m.ErrorObj
        result = m._monkey_repl_parser("let ok = 123")
        result = m._monkey_repl_parser("ok + good")
        @test result isa m.IntegerObj
        @test result.value == 165
    end

    @testset "Use Evaluator" begin
        for (raw_input, expected) in [
            (b"1\n2\n", ["1", "2"]),
            (b"let a = 1;\na;\n", ["1", "1"]),
            (b"a\n", ["ERROR: identifier not found: a"]),
            (b"1 / 0\n", ["ERROR: divide error: division by zero"]),
            (b"1 ++ 2\n",
                [
                    "ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found"
                ]),
            (b"5 + 3; 23 -- ; f((\n",
                [
                    "ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead"
                ]),
            (b"let a=fn(x) {a(x)}; a(3)\n", ["ERROR: runtime error: stack overflow"]),
            (b"let a = macro(x) {x + x}; a(2)\n",
                ["ERROR: macro error: we only support returning AST-nodes from macros"]),
            (
                b"let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);\n",
                ["1"]),
            (b"puts(\"Hello, world!\")\n", ["Hello, world!\nnull"])
        ]
            input = IOBuffer(raw_input)
            output = IOBuffer()
            m.start_repl(input = input, output = output)
            @test String(take!(output)) ==
                  m.REPL_PRELUDE *
                  "\n" *
                  join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") *
                  "\n"
        end
    end

    @testset "Use Bytecode VM" begin
        for (raw_input, expected) in [
            (b"1\n2\n", ["1", "2"]),
            (b"let a = 1;\na;\n", ["1", "1"]),
            (b"a\n", ["ERROR: identifier not found: a"]),
            (b"let b = 1 / 0;\nb;\n",
                ["ERROR: divide error: division by zero", "ERROR: identifier not found: b"]),
            (b"1 ++ 2\n",
                [
                    "ERROR: parser has 1 error\nERROR: parse error: no prefix parse function for PLUS found"
                ]),
            (b"5 + 3; 23 -- ; f((\n",
                [
                    "ERROR: parser has 3 errors\nERROR: parse error: no prefix parse function for SEMICOLON found\nERROR: parse error: no prefix parse function for EOF found\nERROR: parse error: expected next token to be RPAREN, got EOF instead"
                ]),
            # (b"let a=fn(x) {a(x)}; a(3)\n", ["ERROR: stack overflow"]),
            (b"let a = macro(x) {x + x}; a(2)\n",
                ["ERROR: macro error: we only support returning AST-nodes from macros"]),
            (
                b"let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); }; reverse(2 + 2, 10 - 5);\n",
                ["1"]),
            (b"puts(\"Hello, world!\")\n", ["Hello, world!\nnull"])
        ]
            input = IOBuffer(raw_input)
            output = IOBuffer()
            m.start_repl(input = input, output = output, use_vm = true)
            @test String(take!(output)) ==
                  m.REPL_PRELUDE *
                  "\n" *
                  join(map(x -> ">> " * x, vcat(expected, [m.REPL_FAREWELL])), "\n") *
                  "\n"
        end
    end
end
