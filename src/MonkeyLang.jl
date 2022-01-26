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

end
