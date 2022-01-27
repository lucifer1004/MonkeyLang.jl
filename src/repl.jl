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

function start_repl(; input::IO = stdin, output::IO = stdout, use_jit::Bool = false)
    # Handle SIGINT more elegantly
    Base.exit_on_sigint(false)

    env = use_jit ? nothing : Environment(; input = input, output = output)
    macro_env = Environment(; input = input, output = output)
    constants = use_jit ? Object[] : nothing
    globals = use_jit ? Object[] : nothing
    symbol_table = use_jit ? SymbolTable() : nothing

    if use_jit
        for (i, (name, _)) in enumerate(BUILTINS)
            define_builtin!(symbol_table, name, i - 1)
        end
    end

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
                if use_jit
                    c = Compiler(symbol_table, constants)
                    try
                        compile!(c, expanded)
                    catch e
                        msg = hasproperty(e, :msg) ? e.msg : "unknown error"
                        println(output, ErrorObj("compilation error: $msg"))
                        continue
                    end

                    try
                        vm = VM(bytecode(c), globals)
                        run!(vm)
                        result = last_popped(vm)
                        if !isnothing(result)
                            println(output, result)
                        end
                    catch e
                        msg = hasproperty(e, :msg) ? e.msg : "unknown error"
                        println(output, ErrorObj("runtime error: $msg"))
                        continue
                    end
                else
                    evaluated = evaluate(expanded, env)
                    if !isnothing(evaluated)
                        println(output, evaluated)
                    end
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
