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

function start_repl(; input::IO = stdin, output::IO = stdout, use_vm::Bool = false)
    # Handle SIGINT more elegantly
    Base.exit_on_sigint(false)

    env = use_vm ? nothing : Environment(; input = input, output = output)
    macro_env = Environment(; input = input, output = output)
    constants = use_vm ? Object[] : nothing
    globals = use_vm ? Object[] : nothing
    symbol_table = use_vm ? SymbolTable() : nothing

    if use_vm
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
                syntax_check_result = analyze(expanded)
                if isa(syntax_check_result, ErrorObj)
                    println(output, syntax_check_result)
                    continue
                end

                if use_vm
                    # There should be no compilation errors.
                    c = Compiler(symbol_table, constants)
                    compile!(c, expanded)

                    vm = VM(bytecode(c), globals; input = input, output = output)
                    result = run!(vm)
                    if !isnothing(result)
                        println(output, result)

                        # Fix dangling global symbols
                        if isa(result, ErrorObj)
                            to_fix = []

                            for (name, sym) in symbol_table.store
                                if sym.scope == GlobalScope && sym.index >= length(globals)
                                    push!(to_fix, name)
                                end
                            end

                            append!(
                                globals,
                                fill(
                                    _NULL,
                                    symbol_table.definition_count - length(globals),
                                ),
                            )
                            for name in to_fix
                                pop!(symbol_table.store, name)
                            end
                        end
                    end
                else
                    evaluated = evaluate(expanded, env)
                    if !isnothing(evaluated)
                        println(output, evaluated)
                    end
                end
            catch e
                if isa(e, StackOverflowError) # `StackOverflowError` does not have `:msg` field
                    println(output, ErrorObj("runtime error: stack overflow"))
                elseif hasproperty(e, :msg)
                    if occursin("macro error", e.msg)
                        println(output, ErrorObj(e.msg))
                    else
                        println(output, ErrorObj("runtime error: " * e.msg))
                    end
                else
                    println(output, ErrorObj("runtime error: unknown error"))
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
