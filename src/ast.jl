abstract type Node end
abstract type Statement <: Node end
abstract type Expression <: Node end

Base.show(io::IO, node::Node) = print(io, string(node))

struct Program <: Node
  statements::Vector{Statement}
end

token_literal(p::Program) = length(p.statements) > 0 ? token_literal(p.statements[1]) : ""
Base.string(p::Program) = join(map(string, p.statements))
Base.show(io::IO, p::Program) = print(io, string(p))

struct Identifier <: Expression
  token::Token
  value::String
end

token_literal(i::Identifier) = i.token.literal
Base.string(i::Identifier) = i.value

struct BooleanLiteral <: Expression
  token::Token
  value::Bool
end

token_literal(b::BooleanLiteral) = b.token.literal
Base.string(b::BooleanLiteral) = b.token.literal

struct IntegerLiteral <: Expression
  token::Token
  value::Int64
end

token_literal(il::IntegerLiteral) = il.token.literal
Base.string(il::IntegerLiteral) = il.token.literal

struct PrefixExpression <: Expression
  token::Token
  operator::String
  right::Expression
end

token_literal(pe::PrefixExpression) = pe.token.literal
Base.string(pe::PrefixExpression) = "(" * pe.operator * string(pe.right) * ")"

struct InfixExpression <: Expression
  token::Token
  left::Expression
  operator::String
  right::Expression
end

token_literal(ie::InfixExpression) = ie.token.literal
Base.string(ie::InfixExpression) = "(" * string(ie.left) * " " * ie.operator * " " * string(ie.right) * ")"

struct BlockStatement <: Statement
  token::Token
  statements::Vector{Statement}
end

token_literal(bs::BlockStatement) = bs.token.literal
Base.string(bs::BlockStatement) = join(map(string, bs.statements))

struct IfExpression <: Expression
  token::Token
  condition::Expression
  consequence::BlockStatement
  alternative::Union{BlockStatement,Nothing}
end

token_literal(ie::IfExpression) = ie.token.literal
Base.string(ie::IfExpression) = begin
  left = "if" * string(ie.condition) * " " * string(ie.consequence)
  return isnothing(ie.alternative) ? left : left * "else " * string(ie.alternative)
end

struct IndexExpression <: Expression
  token::Token
  left::Expression
  index::Expression
end

token_literal(ie::IndexExpression) = ie.token.literal
Base.string(ie::IndexExpression) = "(" * string(ie.left) * "[" * string(ie.index) * "])"

struct StringLiteral <: Expression
  token::Token
  value::String
end

token_literal(sl::StringLiteral) = sl.token.literal
Base.string(sl::StringLiteral) = sl.token.literal

struct ArrayLiteral <: Expression
  token::Token
  elements::Vector{Expression}
end

token_literal(ar::ArrayLiteral) = ar.token.literal
Base.string(al::ArrayLiteral) = "[" * join(map(string, al.elements), ", ") * "]"

struct HashLiteral <: Expression
  token::Token
  pairs::Dict{Expression,Expression}
end

token_literal(h::HashLiteral) = h.token.literal
Base.string(h::HashLiteral) = "{" * join(map(x -> string(x[1]) * ":" * string(x[2]), collect(h.pairs)), ", ") * "}"

struct FunctionLiteral <: Expression
  token::Token
  parameters::Vector{Identifier}
  body::BlockStatement
end

expression_node(::FunctionLiteral) = nothing
token_literal(fl::FunctionLiteral) = fl.token.literal
Base.string(fl::FunctionLiteral) = fl.token.literal * "(" * join(map(string, fl.parameters), ", ") * ") " * string(fl.body)

struct CallExpression <: Expression
  token::Token
  fn::Expression
  arguments::Vector{Expression}
end

expression_node(::CallExpression) = nothing
token_literal(ce::CallExpression) = ce.token.literal
Base.string(ce::CallExpression) = string(ce.fn) * "(" * join(map(string, ce.arguments), ", ") * ")"

struct LetStatement <: Statement
  token::Token
  name::Identifier
  value::Expression
end

statement_node(::LetStatement) = nothing
token_literal(ls::LetStatement) = ls.token.literal
Base.string(ls::LetStatement) = ls.token.literal * " " * string(ls.name) * " = " * string(ls.value) * ";"

struct ReturnStatement <: Statement
  token::Token
  return_value::Expression
end

statement_node(::ReturnStatement) = nothing
token_literal(rs::ReturnStatement) = rs.token.literal
Base.string(rs::ReturnStatement) = rs.token.literal * " " * string(rs.return_value) * ";"

struct ExpressionStatement <: Statement
  token::Token
  expression::Expression
end

statement_node(::ExpressionStatement) = nothing
token_literal(es::ExpressionStatement) = es.token.literal
Base.string(es::ExpressionStatement) = string(es.expression)
