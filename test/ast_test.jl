@testset "Test Stringify Program" begin
  program = m.Program([
    m.LetStatement(
      m.Token(m.LET, "let"),
      m.Identifier(m.Token(m.IDENT, "myVar"), "myVar"),
      m.Identifier(m.Token(m.IDENT, "anotherVar"), "anotherVar")
    )
  ])

  @test begin
    string(program) == "let myVar = anotherVar;"
  end
end