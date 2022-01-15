module MonkeyLang

const MONKEY_VERSION = v"0.1.0"
const MONKEY_AUTHOR = "Gabriel Wu"

include("token.jl")
include("ast.jl")
include("object.jl")
include("lexer.jl")
include("parser.jl")
include("builtins.jl")
include("evaluator.jl")
include("repl.jl")

end
