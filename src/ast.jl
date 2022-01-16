abstract type Node end
abstract type Statement <: Node end
abstract type Expression <: Node end

token_literal(node::Node) = node.token.literal
Base.string(node::Node) = node.token.literal

struct Program <: Node
  statements::Vector{Statement}
end

token_literal(p::Program) = length(p.statements) > 0 ? token_literal(p.statements[1]) : ""
Base.string(p::Program) = join(map(string, p.statements))

struct Identifier <: Expression
  token::Token
  value::String
end

Base.string(i::Identifier) = i.value

struct BooleanLiteral <: Expression
  token::Token
  value::Bool
end

struct NullLiteral <: Expression
  token::Token
end

struct IntegerLiteral <: Expression
  token::Token
  value::Int64
end

struct PrefixExpression <: Expression
  token::Token
  operator::String
  right::Expression
end

Base.string(pe::PrefixExpression) = "(" * pe.operator * string(pe.right) * ")"

struct InfixExpression <: Expression
  token::Token
  left::Expression
  operator::String
  right::Expression
end

Base.string(ie::InfixExpression) = "(" * string(ie.left) * " " * ie.operator * " " * string(ie.right) * ")"

struct BlockStatement <: Statement
  token::Token
  statements::Vector{Statement}
end

Base.string(bs::BlockStatement) = join(map(string, bs.statements))

struct IfExpression <: Expression
  token::Token
  condition::Expression
  consequence::BlockStatement
  alternative::Union{BlockStatement,Nothing}
end

Base.string(ie::IfExpression) = begin
  left = "if (" * string(ie.condition) * ") { " * string(ie.consequence) * " } "
  return isnothing(ie.alternative) ? left : (left * "else { " * string(ie.alternative) * " }")
end

struct IndexExpression <: Expression
  token::Token
  left::Expression
  index::Expression
end

Base.string(ie::IndexExpression) = "(" * string(ie.left) * "[" * string(ie.index) * "])"

struct StringLiteral <: Expression
  token::Token
  value::String
end

struct ArrayLiteral <: Expression
  token::Token
  elements::Vector{Expression}
end

Base.string(al::ArrayLiteral) = "[" * join(map(string, al.elements), ", ") * "]"

struct HashLiteral <: Expression
  token::Token
  pairs::Dict{Expression,Expression}
end

Base.string(h::HashLiteral) = "{" * join(map(x -> string(x[1]) * ":" * string(x[2]), collect(h.pairs)), ", ") * "}"

struct FunctionLiteral <: Expression
  token::Token
  parameters::Vector{Identifier}
  body::BlockStatement
end

Base.string(fl::FunctionLiteral) = fl.token.literal * "(" * join(map(string, fl.parameters), ", ") * ") {" * string(fl.body) * "}"

struct CallExpression <: Expression
  token::Token
  fn::Expression
  arguments::Vector{Expression}
end

Base.string(ce::CallExpression) = string(ce.fn) * "(" * join(map(string, ce.arguments), ", ") * ")"

struct LetStatement <: Statement
  token::Token
  name::Identifier
  value::Expression
end

Base.string(ls::LetStatement) = ls.token.literal * " " * string(ls.name) * " = " * string(ls.value) * ";"

struct ReturnStatement <: Statement
  token::Token
  return_value::Expression
end

Base.string(rs::ReturnStatement) = rs.token.literal * " " * string(rs.return_value) * ";"

struct ExpressionStatement <: Statement
  token::Token
  expression::Expression
end

Base.string(es::ExpressionStatement) = string(es.expression)
