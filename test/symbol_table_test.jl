@testset "Test Symbol Table" begin
  expected = Dict(
    "a" => m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0),
    "b" => m.MonkeySymbol("b", m.GLOBAL_SCOPE, 1),
  )

  @testset "Test Defining Symbols" begin
    g = m.SymbolTable()

    a = m.define!(g, "a")
    @test a == expected["a"]

    b = m.define!(g, "b")
    @test b == expected["b"]
  end

  @testset "Test Resolving Global Symbols" begin
    g = m.SymbolTable()

    m.define!(g, "a")
    m.define!(g, "b")

    @test m.resolve(g, "a") == expected["a"]
    @test m.resolve(g, "b") == expected["b"]
  end
end