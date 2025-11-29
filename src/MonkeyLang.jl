module MonkeyLang

export start_repl, init_monkey_repl!, @monkey_eval_str, @monkey_vm_str

using Printf

const MONKEY_VERSION = v"0.2.1"
const MONKEY_AUTHOR = "Gabriel Wu"

# Tokens
include("token.jl")

# AST Nodes
include("ast.jl")

# Op Codes and Instructions
include("code.jl")

# Wrapped Objects
include("object.jl")

# Lexer
include("lexer.jl")

# Parser
include("parser.jl")

# Builtin Functions
include("builtins.jl")

# Evaluator
include("evaluator.jl")

# Auxiliary AST Modification Functions Used for Macros
include("ast_modify.jl")

# Symbol and Symbol Table
include("symbol_table.jl")

# Analyzer
include("analyzer.jl")

# Compiler
include("compiler.jl")

# VM
include("vm.jl")

# REPL
include("repl.jl")

# ReplMaker-based REPL mode (excluded from coverage)
include("repl_mode.jl")

# Transpilers
include("transpilers/transpilers.jl")

using .Transpilers.JuliaTranspiler: @monkey_julia_str
export @monkey_julia_str

# CLI
include("cli.jl")

end
