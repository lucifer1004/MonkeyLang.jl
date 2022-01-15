@enum ExpressionOrder LOWEST EQUALS LESSGREATER SUM PRODUCT PREFIX CALL INDEX

const ORDERS = Dict{TokenType,ExpressionOrder}(
  EQ => EQUALS,
  NOT_EQ => EQUALS,
  LT => LESSGREATER,
  GT => LESSGREATER,
  PLUS => SUM,
  MINUS => SUM,
  SLASH => PRODUCT,
  ASTERISK => PRODUCT,
  LPAREN => CALL,
  LBRACKET => INDEX,
)

mutable struct Parser
  l::Lexer
  errors::Vector{ErrorObj}
  cur_token::Token
  peek_token::Token
  prefix_parse_functions::Dict{TokenType,Function}
  infix_parse_functions::Dict{TokenType,Function}
end

function Parser(l::Lexer)
  cur_token = next_token!(l)
  peek_token = next_token!(l)
  p = Parser(l, [], cur_token, peek_token, Dict(), Dict())

  register_prefix!(p, IDENT, parse_identifier!)
  register_prefix!(p, INT, parse_integer_literal!)
  register_prefix!(p, BANG, parse_prefix_expression!)
  register_prefix!(p, MINUS, parse_prefix_expression!)
  register_prefix!(p, TRUE, parse_boolean!)
  register_prefix!(p, FALSE, parse_boolean!)
  register_prefix!(p, LPAREN, parse_grouped_expression!)
  register_prefix!(p, IF, parse_if_expression!)
  register_prefix!(p, FUNCTION, parse_function_literal!)
  register_prefix!(p, STRING, parse_string_literal!)
  register_prefix!(p, LBRACKET, parse_array_literal!)
  register_prefix!(p, LBRACE, parse_hash_literal!)

  register_infix!(p, PLUS, parse_infix_expression!)
  register_infix!(p, MINUS, parse_infix_expression!)
  register_infix!(p, SLASH, parse_infix_expression!)
  register_infix!(p, ASTERISK, parse_infix_expression!)
  register_infix!(p, EQ, parse_infix_expression!)
  register_infix!(p, NOT_EQ, parse_infix_expression!)
  register_infix!(p, LT, parse_infix_expression!)
  register_infix!(p, GT, parse_infix_expression!)
  register_infix!(p, LPAREN, parse_call_expression!)
  register_infix!(p, LBRACKET, parse_index_expression!)

  return p
end

register_prefix!(p::Parser, t::TokenType, fn::Function) = p.prefix_parse_functions[t] = fn
register_infix!(p::Parser, t::TokenType, fn::Function) = p.infix_parse_functions[t] = fn

function next_token!(p::Parser)
  p.cur_token = p.peek_token
  p.peek_token = next_token!(p.l)
end

function parse_statement!(p::Parser)
  if p.cur_token.type == LET
    return parse_let_statement!(p)
  elseif p.cur_token.type == RETURN
    return parse_return_statement!(p)
  else
    return parse_expression_statement!(p)
  end
end

function parse_let_statement!(p::Parser)
  token = p.cur_token

  if !expect_peek!(p, IDENT)
    return nothing
  end

  name = Identifier(p.cur_token, p.cur_token.literal)

  if !expect_peek!(p, ASSIGN)
    return nothing
  end

  next_token!(p)

  value = parse_expression!(p, LOWEST)

  if p.peek_token.type == SEMICOLON
    next_token!(p)
  end

  return LetStatement(token, name, value)
end

function parse_return_statement!(p::Parser)
  token = p.cur_token

  next_token!(p)

  value = parse_expression!(p, LOWEST)

  if p.peek_token.type == SEMICOLON
    next_token!(p)
  end

  return ReturnStatement(token, value)
end

function parse_expression_statement!(p::Parser)
  token = p.cur_token
  expression = parse_expression!(p, LOWEST)
  if p.peek_token.type == SEMICOLON
    next_token!(p)
  end

  return ExpressionStatement(token, expression)
end

function parse_block_statement!(p::Parser)
  token = p.cur_token
  statements = Statement[]

  next_token!(p)

  while p.cur_token.type != RBRACE && p.cur_token.type != EOF
    statement = parse_statement!(p)

    if !isnothing(statement)
      push!(statements, statement)
    end

    next_token!(p)
  end

  return BlockStatement(token, statements)
end

function parse_expression!(p::Parser, order::ExpressionOrder)
  if p.cur_token.type ∉ keys(p.prefix_parse_functions)
    push!(p.errors, ErrorObj("parse error: no prefix parse function for $(p.cur_token.type) found"))
    return nothing
  else
    prefix_fn = p.prefix_parse_functions[p.cur_token.type]
    left = prefix_fn(p)

    while p.peek_token.type != SEMICOLON && order < peek_order(p)
      if p.peek_token.type ∉ keys(p.infix_parse_functions)
        return left
      end

      infix_fn = p.infix_parse_functions[p.peek_token.type]
      next_token!(p)
      left = infix_fn(p, left)
    end

    return left
  end
end

parse_boolean!(p::Parser) = BooleanLiteral(p.cur_token, p.cur_token.type == TRUE)

parse_identifier!(p::Parser) = Identifier(p.cur_token, p.cur_token.literal)

function parse_integer_literal!(p::Parser)
  token = p.cur_token
  try
    value = parse(Int64, p.cur_token.literal)
    return IntegerLiteral(token, value)
  catch
    push!(p.errors, ErrorObj("parse error: could not parse $(p.cur_token.literal) as integer"))
    return nothing
  end
end

function parse_string_literal!(p::Parser)
  return StringLiteral(p.cur_token, p.cur_token.literal)
end

function parse_array_literal!(p::Parser)
  token = p.cur_token
  elements = parse_expression_list!(p, RBRACKET)
  return ArrayLiteral(token, elements)
end

function parse_hash_literal!(p::Parser)
  token = p.cur_token
  pairs = Dict{Expression,Expression}()

  while p.peek_token.type != RBRACE
    next_token!(p)
    key = parse_expression!(p, LOWEST)
    if !expect_peek!(p, COLON)
      return nothing
    end

    next_token!(p)
    val = parse_expression!(p, LOWEST)
    pairs[key] = val

    if p.peek_token.type != RBRACE && !expect_peek!(p, COMMA)
      return nothing
    end
  end

  if !expect_peek!(p, RBRACE)
    return nothing
  end

  return HashLiteral(token, pairs)
end

function parse_index_expression!(p::Parser, left::Expression)
  token = p.cur_token
  next_token!(p)
  index = parse_expression!(p, LOWEST)

  if !expect_peek!(p, RBRACKET)
    return nothing
  end

  return IndexExpression(token, left, index)
end

function parse_prefix_expression!(p::Parser)
  token = p.cur_token
  operator = p.cur_token.literal
  next_token!(p)
  right = parse_expression!(p, PREFIX)
  return PrefixExpression(token, operator, right)
end

function parse_infix_expression!(p::Parser, left::Expression)
  token = p.cur_token
  operator = p.cur_token.literal

  order = cur_order(p)
  next_token!(p)
  right = parse_expression!(p, order)

  return InfixExpression(token, left, operator, right)
end

function parse_grouped_expression!(p::Parser)
  next_token!(p)
  expr = parse_expression!(p, LOWEST)
  if !expect_peek!(p, RPAREN)
    return nothing
  end
  return expr
end

function parse_expression_list!(p::Parser, end_token::TokenType)
  expressions = Expression[]

  if p.peek_token.type == end_token
    next_token!(p)
    return expressions
  end

  next_token!(p)
  push!(expressions, parse_expression!(p, LOWEST))

  while p.peek_token.type == COMMA
    next_token!(p)
    next_token!(p)
    push!(expressions, parse_expression!(p, LOWEST))
  end

  if !expect_peek!(p, end_token)
    return nothing
  end

  return expressions
end

function parse_if_expression!(p::Parser)
  token = p.cur_token

  if !expect_peek!(p, LPAREN)
    return nothing
  end

  next_token!(p)
  condition = parse_expression!(p, LOWEST)

  if !expect_peek!(p, RPAREN)
    return nothing
  end

  if !expect_peek!(p, LBRACE)
    return nothing
  end

  consequence = parse_block_statement!(p)

  if p.peek_token.type == ELSE
    next_token!(p)

    if !expect_peek!(p, LBRACE)
      return nothing
    end

    alternative = parse_block_statement!(p)
  else
    alternative = nothing
  end

  return IfExpression(token, condition, consequence, alternative)
end

function parse_function_parameters!(p::Parser)
  identifiers = Identifier[]

  if p.peek_token.type == RPAREN
    next_token!(p)
    return identifiers
  end

  next_token!(p)
  ident = Identifier(p.cur_token, p.cur_token.literal)
  push!(identifiers, ident)

  while p.peek_token.type == COMMA
    next_token!(p)
    next_token!(p)
    ident = Identifier(p.cur_token, p.cur_token.literal)
    push!(identifiers, ident)
  end

  if !expect_peek!(p, RPAREN)
    return nothing
  end

  return identifiers
end

function parse_function_literal!(p::Parser)
  token = p.cur_token

  if !expect_peek!(p, LPAREN)
    return nothing
  end

  parameters = parse_function_parameters!(p)

  if !expect_peek!(p, LBRACE)
    return nothing
  end

  body = parse_block_statement!(p)

  return FunctionLiteral(token, parameters, body)
end

function parse_call_expression!(p::Parser, fn::Expression)
  token = p.cur_token
  arguments = parse_expression_list!(p, RPAREN)

  return CallExpression(token, fn, arguments)
end

function expect_peek!(p::Parser, t::TokenType)
  if p.peek_token.type == t
    next_token!(p)
    return true
  else
    peek_error!(p, t)
    return false
  end
end

function peek_error!(p::Parser, t::TokenType)
  push!(p.errors, ErrorObj("parse error: expected next token to be $t, got $(p.peek_token.type) instead"))
end

function cur_order(p::Parser)
  if p.cur_token.type ∉ keys(ORDERS)
    return LOWEST
  else
    return ORDERS[p.cur_token.type]
  end
end

function peek_order(p::Parser)
  if p.peek_token.type ∉ keys(ORDERS)
    return LOWEST
  else
    return ORDERS[p.peek_token.type]
  end
end

function parse!(p::Parser)
  program = Program([])

  while p.cur_token.type != EOF
    try
      statement = parse_statement!(p)
      if !isnothing(statement)
        push!(program.statements, statement)
      end
    catch
    finally
      next_token!(p)
    end
  end

  return program
end