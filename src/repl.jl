const PROMPT = ">> "
const REPL_PRELUDE = """

  ███╗   ███╗ ██████╗ ███╗   ██╗██╗  ██╗███████╗██╗   ██╗   |
  ████╗ ████║██╔═══██╗████╗  ██║██║ ██╔╝██╔════╝╚██╗ ██╔╝   |
  ██╔████╔██║██║   ██║██╔██╗ ██║█████╔╝ █████╗   ╚████╔╝    |
  ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔═██╗ ██╔══╝    ╚██╔╝     |  Version $MONKEY_VERSION
  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║  ██╗███████╗   ██║      |
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝   ╚═╝      |  BY $MONKEY_AUTHOR
"""
const REPL_FAREWELL = "Good bye!"
const _READY_TO_READ = Threads.Condition() # For test-use only.

function start_repl(; input::IO = stdin, output::IO = stdout)
    # Handle SIGINT more elegantly
    Base.exit_on_sigint(false)

    env = Environment(; input = input, output = output)
    macro_env = Environment(; input = input, output = output)

    println(output, REPL_PRELUDE)

    while true
        print(output, PROMPT)

        try
            line = readline(input; keep = true)

            # Ctrl-D (EOF) causes the REPL to stop
            if isempty(line)
                println(output, REPL_FAREWELL)
                break
            end

            l = Lexer(string(strip(line, '\n')))
            p = Parser(l)
            program = parse!(p)

            if !isempty(p.errors)
                println(
                    output,
                    ErrorObj(
                        "parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")",
                    ),
                )
                println(output, join(map(string, p.errors), "\n"))
                continue
            end

            program = define_macros!(macro_env, program)

            try
                expanded = expand_macros(program, macro_env)
                evaluated = evaluate(expanded, env)
                if !isnothing(evaluated)
                    println(output, evaluated)
                end
            catch e
                if isa(e, StackOverflowError) # `StackOverflowError` does not have `:msg` field
                    println(output, ErrorObj("stack overflow"))
                elseif :msg in fieldnames(typeof(e))
                    println(output, ErrorObj(e.msg))
                else
                    println(output, ErrorObj("unknown error"))
                end
            end
        catch e
            # Handle SIGINT elegantly
            # `e` should be an InterruptException, but there might be some edge cases
            if !isa(e, InterruptException)
                println(output, ErrorObj("unknown error"))
            end
            println(output, REPL_FAREWELL)
            break
        end
    end
end

function start_jit_repl(; input::IO = stdin, output::IO = stdout)
    constants = Object[]
    globals = Object[]
    symbol_table = SymbolTable()
    for (i, (name, _)) in enumerate(BUILTINS)
        define_builtin!(symbol_table, name, i - 1)
    end

    while true
        print(output, PROMPT)
        line = readline(input; keep = true)

        # Ctrl-D (EOF) causes the REPL to stop
        if isempty(line)
            println(output, REPL_FAREWELL)
            break
        end

        l = Lexer(string(strip(line, '\n')))
        p = Parser(l)
        program = parse!(p)

        if !isempty(p.errors)
            println(
                output,
                ErrorObj(
                    "parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")",
                ),
            )
            println(output, join(map(string, p.errors), "\n"))
            continue
        end

        c = Compiler(symbol_table, constants)

        try
            compile!(c, program)
        catch e
            println(output, "Woops! Compilation failed:\n $e")
            continue
        end

        try
            vm = VM(bytecode(c), globals)
            run!(vm)
            println(output, last_popped(vm))
        catch e
            println(output, "Woops! Bytecode execution failed:\n $e")
            continue
        end
    end
end
