# Copy from https://github.com/JuliaLang/julia/issues/4648#issuecomment-761030051
@generated structEqual(e1, e2) = begin
  if fieldcount(e1) == 0
    return :(true)
  end
  mkEq = fldName -> :(e1.$fldName == e2.$fldName)
  # generate individual equality checks
  eqExprs = map(mkEq, fieldnames(e1))
  # construct &&-expression for chaining all checks
  mkAnd = (expr, acc) -> Expr(:&&, expr, acc)
  # no need in initial accumulator because eqExprs is not empty
  foldr(mkAnd, eqExprs)
end

Base.:(==)(x::m.Node, y::m.Node) = structEqual(x, y)

@testset "Test Modifying AST" begin
  one = () -> m.IntegerLiteral(m.Token(m.INT, "1"), 1)
  two = () -> m.IntegerLiteral(m.Token(m.INT, "2"), 2)
  turn_one_into_two = (node::m.Node) -> isa(node, m.IntegerLiteral) && node.value == 1 ? two() : node

  for (input, expected) in [
    (one(), two()),
    (
      m.Program([m.ExpressionStatement(one().token, one())]),
      m.Program([m.ExpressionStatement(one().token, two())])
    ),
    (
      m.InfixExpression(m.Token(m.PLUS, "+"), one(), "+", two()),
      m.InfixExpression(m.Token(m.PLUS, "+"), two(), "+", two())
    ),
    (
      m.InfixExpression(m.Token(m.PLUS, "+"), two(), "+", one()),
      m.InfixExpression(m.Token(m.PLUS, "+"), two(), "+", two())
    ),
    (
      m.PrefixExpression(m.Token(m.MINUS, "-"), "-", one()),
      m.PrefixExpression(m.Token(m.MINUS, "-"), "-", two())
    ),
    (
      m.IndexExpression(one().token, one(), one()),
      m.IndexExpression(one().token, two(), two()),
    ),
    (
      m.IfExpression(
        m.Token(m.IF, "if"),
        one(),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, one())]),
        nothing,
      ),
      m.IfExpression(
        m.Token(m.IF, "if"),
        two(),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, two())]),
        nothing,
      ),
    ),
    (
      m.IfExpression(
        m.Token(m.IF, "if"),
        one(),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, one())]),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, one())]),
      ),
      m.IfExpression(
        m.Token(m.IF, "if"),
        two(),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, two())]),
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, two())]),
      ),
    ),
    (
      m.ReturnStatement(m.Token(m.RETURN, "return"), one()),
      m.ReturnStatement(m.Token(m.RETURN, "return"), two()),
    ),
    (
      m.LetStatement(m.Token(m.IDENT, "x"), m.Identifier(m.Token(m.IDENT, "x"), "x"), one()),
      m.LetStatement(m.Token(m.IDENT, "x"), m.Identifier(m.Token(m.IDENT, "x"), "x"), two()),
    ),
    (
      m.FunctionLiteral(
        m.Token(m.FUNCTION, "fn"),
        [m.Identifier(m.Token(m.IDENT, "x"), "x")],
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, one())]),
      ),
      m.FunctionLiteral(
        m.Token(m.FUNCTION, "fn"),
        [m.Identifier(m.Token(m.IDENT, "x"), "x")],
        m.BlockStatement(one().token, [m.ExpressionStatement(one().token, two())]),
      ),
    ),
    (
      m.ArrayLiteral(one().token, [one(), one()]),
      m.ArrayLiteral(one().token, [two(), two()]),
    ),
    (
      m.HashLiteral(one().token, Dict(one() => one())),
      m.HashLiteral(one().token, Dict(two() => two())),
    )
  ]
    @test begin
      modified = m.modify(input, turn_one_into_two)
      modified == expected
    end
  end
end