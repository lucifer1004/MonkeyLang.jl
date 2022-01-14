using MonkeyLang
using Test

const m = MonkeyLang

@testset "MonkeyLang.jl" begin
    include("lexer_test.jl")
    include("ast_test.jl")
    include("parser_test.jl")
    include("evaluator_test.jl")
end
