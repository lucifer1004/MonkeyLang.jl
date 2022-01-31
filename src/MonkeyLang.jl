module MonkeyLang

using Printf

const MONKEY_VERSION = v"0.2.0"
const MONKEY_AUTHOR = "Gabriel Wu"

include("token.jl")
include("ast.jl")
include("code.jl")
include("object.jl")
include("lexer.jl")
include("parser.jl")
include("builtins.jl")
include("evaluator.jl")
include("ast_modify.jl")
include("symbol_table.jl")
include("compiler.jl")
include("vm.jl")
include("repl.jl")

const HELP_INFO = """

This is MonkeyLang.jl $MONKEY_VERSION by $MONKEY_AUTHOR.

Usage:

monkey run <file> [--vm]
monkey repl [--vm]
"""

function julia_main(; input::IO = stdin, output::IO = stdout)::Cint
    if length(ARGS) == 0 || ARGS[1] ∉ ["run", "repl"]
        println(output, HELP_INFO)
        return 0
    end

    if ARGS[1] == "run"
        if length(ARGS) < 2
            println(output, "Usage: monkey run <file> [--vm]")
            return 0
        end

        _, ext = splitext(ARGS[2])
        if ext != ".mo"
            println(output, "ERROR: Only .mo files are supported!")
            return 0
        end

        if !isfile(ARGS[2])
            println(output, "ERROR: File not found!")
            return 0
        end

        code = String(read(open(ARGS[2])))
        if length(ARGS) == 3 && ARGS[3] == "--vm"
            run(code; input = input, output = output)
        else
            evaluate(code; input = input, output = output)
        end
    else
        start_repl(; input = input, output = output, use_vm = "--vm" ∈ ARGS)
    end

    return 0
end

end
