using MonkeyLang
using Test
using IOCapture

const m = MonkeyLang

@testset "MonkeyLang.jl" begin
    include("test_helpers.jl")

    include("lexer_test.jl")
    include("ast_test.jl")
    include("parser_test.jl")
    include("object_test.jl")

    include("evaluator_test.jl")
    include("quote_test.jl")
    include("ast_modify_test.jl")

    include("code_test.jl")
    include("symbol_table_test.jl")
    include("compiler_test.jl")
    include("vm_test.jl")

    include("repl_test.jl")
    include("cli_test.jl")

    include("transpilers/transpiler_test.jl")
end
