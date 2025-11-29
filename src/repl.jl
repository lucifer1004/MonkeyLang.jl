using ReplMaker

const PROMPT = ">> "
const MONKEY_PROMPT = "monkey> "
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

# Global state for ReplMaker-based REPL
const _REPL_ENV = Ref{Union{Environment, Nothing}}(nothing)
const _REPL_MACRO_ENV = Ref{Union{Environment, Nothing}}(nothing)
const _REPL_USE_VM = Ref{Bool}(false)
const _REPL_CONSTANTS = Ref{Union{Vector{Object}, Nothing}}(nothing)
const _REPL_GLOBALS = Ref{Union{Vector{Object}, Nothing}}(nothing)
const _REPL_SYMBOL_TABLE = Ref{Union{SymbolTable, Nothing}}(nothing)

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
                println(output,
                        ErrorObj("parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")"))
                println(output, join(map(string, p.errors), "\n"))
                continue
            end

            program = define_macros!(macro_env, program)

            try
                expanded = expand_macros(program, macro_env)

                if use_vm
                    syntax_check_result = analyze(expanded;
                                                  existing_symbol_table = symbol_table)
                    if isa(syntax_check_result, ErrorObj)
                        println(output, syntax_check_result)
                        continue
                    end

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

                            append!(globals,
                                    fill(_NULL,
                                         symbol_table.definition_count - length(globals)))
                            for name in to_fix
                                pop!(symbol_table.store, name)
                            end
                        end
                    end
                else
                    syntax_check_result = analyze(expanded; exisiting_env = env)
                    if isa(syntax_check_result, ErrorObj)
                        println(output, syntax_check_result)
                        continue
                    end

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

# codecov: ignore start
"""
    init_monkey_repl!(; use_vm::Bool = false, start_key = ')')

Initialize a Monkey REPL mode in the Julia REPL using ReplMaker.jl.

Press the `start_key` (default ')') to enter Monkey mode.
Press backspace on an empty line to return to Julia mode.

# Arguments
- `use_vm::Bool = false`: If true, use the bytecode VM backend. Otherwise, use tree-walking interpreter.
- `start_key = ')'`: The key to press to enter Monkey mode.

# Example
```julia
using MonkeyLang
init_monkey_repl!()  # Now press ')' to enter Monkey mode
```
"""
function init_monkey_repl!(; use_vm::Bool = false, start_key = ')')
    # Initialize global state
    _REPL_USE_VM[] = use_vm
    _REPL_MACRO_ENV[] = Environment()
    
    if use_vm
        _REPL_ENV[] = nothing
        _REPL_CONSTANTS[] = Object[]
        _REPL_GLOBALS[] = Object[]
        _REPL_SYMBOL_TABLE[] = SymbolTable()
        for (i, (name, _)) in enumerate(BUILTINS)
            define_builtin!(_REPL_SYMBOL_TABLE[], name, i - 1)
        end
    else
        _REPL_ENV[] = Environment()
        _REPL_CONSTANTS[] = nothing
        _REPL_GLOBALS[] = nothing
        _REPL_SYMBOL_TABLE[] = nothing
    end

    initrepl(_monkey_repl_parser;
             prompt_text = MONKEY_PROMPT,
             prompt_color = :yellow,
             start_key = start_key,
             mode_name = :monkey,
             startup_text = false)
    
    println("Monkey REPL mode initialized. Press '$start_key' to enter Monkey mode.")
    nothing
end
# codecov: ignore end

function _monkey_repl_parser(code::AbstractString)
    code = String(strip(code))
    isempty(code) && return nothing
    
    # Parse
    l = Lexer(code)
    p = Parser(l)
    program = parse!(p)
    
    if !isempty(p.errors)
        return ErrorObj("parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")\n" *
                       join(map(string, p.errors), "\n"))
    end
    
    # Define macros
    program = define_macros!(_REPL_MACRO_ENV[], program)
    
    try
        expanded = expand_macros(program, _REPL_MACRO_ENV[])
        
        if _REPL_USE_VM[]
            return _eval_vm(expanded)
        else
            return _eval_interpreter(expanded)
        end
    catch e
        if isa(e, StackOverflowError)
            return ErrorObj("runtime error: stack overflow")
        elseif hasproperty(e, :msg)
            if occursin("macro error", e.msg)
                return ErrorObj(e.msg)
            else
                return ErrorObj("runtime error: " * e.msg)  # codecov: ignore
            end
        else
            return ErrorObj("runtime error: unknown error")  # codecov: ignore
        end
    end
end

function _eval_interpreter(program::Program)
    syntax_check_result = analyze(program; exisiting_env = _REPL_ENV[])
    if isa(syntax_check_result, ErrorObj)
        return syntax_check_result
    end
    
    result = evaluate(program, _REPL_ENV[])
    return result
end

function _eval_vm(program::Program)
    syntax_check_result = analyze(program; existing_symbol_table = _REPL_SYMBOL_TABLE[])
    if isa(syntax_check_result, ErrorObj)
        return syntax_check_result
    end
    
    c = Compiler(_REPL_SYMBOL_TABLE[], _REPL_CONSTANTS[])
    compile!(c, program)
    
    vm = VM(bytecode(c), _REPL_GLOBALS[])
    result = run!(vm)
    
    # Fix dangling global symbols on error
    if isa(result, ErrorObj)
        to_fix = []
        for (name, sym) in _REPL_SYMBOL_TABLE[].store
            if sym.scope == GlobalScope && sym.index >= length(_REPL_GLOBALS[])
                push!(to_fix, name)
            end
        end
        append!(_REPL_GLOBALS[],
                fill(_NULL, _REPL_SYMBOL_TABLE[].definition_count - length(_REPL_GLOBALS[])))
        for name in to_fix
            pop!(_REPL_SYMBOL_TABLE[].store, name)
        end
    end
    
    return result
end
