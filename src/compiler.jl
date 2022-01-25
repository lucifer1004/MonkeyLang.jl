struct ByteCode
  instructions::Instructions
  constants::Vector{Object}
end

struct EmittedInstruction
  op::OpCode
  position::Int
end

struct Compiler
  instructions::Instructions
  symbol_table::SymbolTable
  constants::Vector{Object}
  previous_instructions::Vector{EmittedInstruction}

  Compiler() = new(Instructions([]), SymbolTable(), [], [])
  Compiler(s::SymbolTable, constants::Vector{Object}) = new(Instructions([]), s, constants, [])
end

last_instruction(c::Compiler) = isempty(c.previous_instructions) ? nothing : c.previous_instructions[end]

prev_instruction(c::Compiler) = length(c.previous_instructions) < 2 ? nothing : c.previous_instructions[1]

add!(c::Compiler, obj::Object)::Int64 = begin
  push!(c.constants, obj)
  return length(c.constants)
end

add!(c::Compiler, ins::Instructions)::Int64 = begin
  pos = length(c.instructions) + 1
  append!(c.instructions, ins)
  return pos
end

set_last!(c::Compiler, op::OpCode, pos::Int) = begin
  last = EmittedInstruction(op, pos)
  if length(c.previous_instructions) == 2
    c.previous_instructions[1] = c.previous_instructions[2]
    c.previous_instructions[2] = last
  else
    push!(c.previous_instructions, last)
  end
end

remove_last!(c::Compiler) = begin
  splice!(c.instructions, last_instruction(c).position:length(c.instructions))
  pop!(c.previous_instructions)
end

remove_last_pop!(c::Compiler) =
  if last_instruction(c).op == OpPop
    remove_last!(c)
  end

replace!(c::Compiler, pos::Int, new_ins::Instructions) = begin
  for i in 1:length(new_ins)
    if pos + i - 1 <= length(c.instructions)
      c.instructions[pos+i-1] = new_ins[i]
    else
      push!(c.instructions, new_ins[i])
    end
  end
end

change_operand!(c::Compiler, pos::Int, operand::Int) = begin
  op = OpCode(c.instructions[pos])
  new_ins = make(op, operand)
  replace!(c, pos, new_ins)
end

emit!(c::Compiler, op::OpCode, operands::Vararg{Int})::Int64 = begin
  ins = make(op, operands...)
  pos = add!(c, ins)
  set_last!(c, op, pos)
  return pos
end

compile!(::Compiler, ::Node) = nothing

compile!(c::Compiler, il::IntegerLiteral) =
  emit!(c, OpConstant, add!(c, IntegerObj(il.value)) - 1)

compile!(c::Compiler, il::BooleanLiteral) = begin
  if il.value
    emit!(c, OpTrue)
  else
    emit!(c, OpFalse)
  end
end

compile!(c::Compiler, ::NullLiteral) = emit!(c, OpNull)

compile!(c::Compiler, sl::StringLiteral) =
  emit!(c, OpConstant, add!(c, StringObj(sl.value)) - 1)

compile!(c::Compiler, ident::Identifier) = begin
  sym = resolve(c.symbol_table, ident.value)

  if isnothing(sym)
    throw(UndefVarError(ident.value))
  end

  emit!(c, OpGetGlobal, sym.index)
end

compile!(c::Compiler, es::ExpressionStatement) = begin
  compile!(c, es.expression)
  emit!(c, OpPop)
end

compile!(c::Compiler, ls::LetStatement) = begin
  compile!(c, ls.value)
  sym = define!(c.symbol_table, ls.name.value)
  emit!(c, OpSetGlobal, sym.index)
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

compile!(c::Compiler, ie::IfExpression) = begin
  compile!(c, ie.condition)
  jump_not_truthy_pos = emit!(c, OpJumpNotTruthy, 9999)
  compile!(c, ie.consequence)
  remove_last_pop!(c)

  jump_pos = emit!(c, OpJump, 9999)
  after_consequence_pos = length(c.instructions)
  change_operand!(c, jump_not_truthy_pos, after_consequence_pos)

  if !isnothing(ie.alternative)
    compile!(c, ie.alternative)
    remove_last_pop!(c)
  else
    emit!(c, OpNull)
  end

  after_alternative_pos = length(c.instructions)
  change_operand!(c, jump_pos, after_alternative_pos)
end

compile!(c::Compiler, bs::BlockStatement) = begin
  for statement in bs.statements
    compile!(c, statement)
  end
end

compile!(c::Compiler, program::Program) = begin
  for statement in program.statements
    compile!(c, statement)
  end
end

bytecode(c::Compiler) = ByteCode(c.instructions, c.constants)
