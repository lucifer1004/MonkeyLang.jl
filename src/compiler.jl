struct ByteCode
  instructions::Instructions
  constants::Vector{Object}
end

struct Compiler
  instructions::Instructions
  constants::Vector{Object}

  Compiler() = new(Instructions([]), [])
end

add!(c::Compiler, obj::Object)::Int64 = begin
  push!(c.constants, obj)
  return length(c.constants)
end

add!(c::Compiler, ins::Instructions)::Int64 = begin
  pos = length(c.instructions) + 1
  append!(c.instructions, ins)
  return pos
end

emit!(c::Compiler, op::OpCode, operands::Vararg{Int})::Int64 = begin
  ins = make(op, operands...)
  return add!(c, ins)
end

compile!(c::Compiler, node::Node) = nothing

compile!(c::Compiler, il::IntegerLiteral) = begin
  integer = IntegerObj(il.value)
  emit!(c, OpConstant, add!(c, integer) - 1)
end

compile!(c::Compiler, il::BooleanLiteral) = begin
  if il.value
    emit!(c, OpTrue)
  else
    emit!(c, OpFalse)
  end
end

compile!(c::Compiler, es::ExpressionStatement) = begin
  compile!(c, es.expression)
  emit!(c, OpPop)
end

compile!(c::Compiler, pe::PrefixExpression) = begin
  compile!(c, pe.right)

  if pe.operator == "-"
    emit!(c, OpMinus)
  elseif pe.operator == "!"
    emit!(c, OpBang)
  else
    error("unknown operator: $(pe.operator)")
  end
end

compile!(c::Compiler, ie::InfixExpression) = begin
  compile!(c, ie.left)
  compile!(c, ie.right)

  if ie.operator == "+"
    emit!(c, OpAdd)
  elseif ie.operator == "-"
    emit!(c, OpSub)
  elseif ie.operator == "*"
    emit!(c, OpMul)
  elseif ie.operator == "/"
    emit!(c, OpDiv)
  elseif ie.operator == "=="
    emit!(c, OpEqual)
  elseif ie.operator == "!="
    emit!(c, OpNotEqual)
  elseif ie.operator == "<"
    emit!(c, OpLessThan)
  elseif ie.operator == ">"
    emit!(c, OpGreaterThan)
  else
    error("unknown operator: $(ie.operator)")
  end
end

compile!(c::Compiler, program::Program) = begin
  for statement in program.statements
    compile!(c, statement)
  end
end

bytecode(c::Compiler) = ByteCode(c.instructions, c.constants)
