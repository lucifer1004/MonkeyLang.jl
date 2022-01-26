struct ByteCode
    instructions::Instructions
    constants::Vector{Object}
end

struct EmittedInstruction
    op::OpCode
    position::Int
end

struct CompilationScope
    instructions::Instructions
    previous_instructions::Vector{EmittedInstruction}
end

last_instruction(c::CompilationScope) =
    isempty(c.previous_instructions) ? nothing : c.previous_instructions[end]

prev_instruction(c::CompilationScope) =
    length(c.previous_instructions) < 2 ? nothing : c.previous_instructions[1]

struct Compiler
    symbol_table::Ref{SymbolTable}
    constants::Vector{Object}
    scopes::Vector{CompilationScope}

    Compiler() = begin
        s = SymbolTable()
        for (i, (name, _)) in enumerate(BUILTINS)
            define_builtin!(s, name, i - 1)
        end
        new(Ref(s), [], [CompilationScope(Instructions([]), [])])
    end
    Compiler(s::SymbolTable, constants::Vector{Object}) =
        new(Ref(s), constants, [CompilationScope(Instructions([]), [])])
end

Base.length(c::Compiler) = length(current_scope(c).instructions)

current_scope(c::Compiler) = c.scopes[end]

last_instruction(c::Compiler) = last_instruction(current_scope(c))

last_instruction_is(c::Compiler, op::OpCode) = begin
    last = last_instruction(c)
    return !isnothing(last) && last.op == op
end

prev_instruction(c::Compiler) = prev_instruction(current_scope(c))

add!(c::Compiler, obj::Object)::Int64 = begin
    push!(c.constants, obj)
    return length(c.constants)
end

add!(c::Compiler, ins::Instructions)::Int64 = begin
    cs = current_scope(c)
    pos = length(cs.instructions) + 1
    append!(cs.instructions, ins)
    return pos
end

replace_last!(c::Compiler, ins::Instructions) = begin
    cs = current_scope(c)
    last_pos = last_instruction(c).position
    replace!(c, last_pos, ins)
    cs.previous_instructions[end] = EmittedInstruction(OpReturnValue, last_pos)
end

set_last!(c::Compiler, op::OpCode, pos::Int) = begin
    cs = current_scope(c)
    last = EmittedInstruction(op, pos)
    if length(cs.previous_instructions) == 2
        cs.previous_instructions[1] = cs.previous_instructions[2]
        cs.previous_instructions[2] = last
    else
        push!(cs.previous_instructions, last)
    end
end

remove_last!(c::Compiler) = begin
    cs = current_scope(c)
    splice!(cs.instructions, last_instruction(cs).position:length(cs.instructions))
    pop!(cs.previous_instructions)
end

remove_last_pop!(c::Compiler) =
    if last_instruction_is(c, OpPop)
        remove_last!(c)
    end

replace_last_pop_with_return!(c::Compiler) = begin
    last = last_instruction(c)
    if last_instruction_is(c, OpPop)
        replace_last!(c, make(OpReturnValue))
    end
end

replace!(c::Compiler, pos::Int, new_ins::Instructions) = begin
    cs = current_scope(c)
    for i = 1:length(new_ins)
        if pos + i - 1 <= length(cs.instructions)
            cs.instructions[pos+i-1] = new_ins[i]
        else
            push!(cs.instructions, new_ins[i])
        end
    end
end

change_operand!(c::Compiler, pos::Int, operand::Int) = begin
    cs = current_scope(c)
    op = OpCode(cs.instructions[pos])
    new_ins = make(op, operand)
    replace!(c, pos, new_ins)
end

emit!(c::Compiler, op::OpCode, operands::Vararg{Int})::Int64 = begin
    ins = make(op, operands...)
    pos = add!(c, ins)
    set_last!(c, op, pos)
    return pos
end

enter_scope!(c::Compiler) = begin
    c.symbol_table[] = SymbolTable(c.symbol_table[])
    push!(c.scopes, CompilationScope(Instructions([]), []))
end

leave_scope!(c::Compiler)::CompilationScope = begin
    c.symbol_table[] = c.symbol_table[].outer
    pop!(c.scopes)
end

load_symbol!(c::Compiler, s::MonkeySymbol) = begin
    if s.scope == GLOBAL_SCOPE
        emit!(c, OpGetGlobal, s.index)
    elseif s.scope == LOCAL_SCOPE
        emit!(c, OpGetLocal, s.index)
    else
        emit!(c, OpGetBuiltin, s.index)
    end
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

compile!(c::Compiler, al::ArrayLiteral) = begin
    for element in al.elements
        compile!(c, element)
    end

    emit!(c, OpArray, length(al.elements))
end

compile!(c::Compiler, hl::HashLiteral) = begin
    ks = collect(keys(hl.pairs))
    sort!(ks)
    for k in ks
        compile!(c, k)
        compile!(c, hl.pairs[k])
    end
    emit!(c, OpHash, length(ks) * 2)
end

compile!(c::Compiler, fl::FunctionLiteral) = begin
    enter_scope!(c)
    for param in fl.parameters
        define!(c.symbol_table[], param.value)
    end
    compile!(c, fl.body)
    replace_last_pop_with_return!(c)
    if !last_instruction_is(c, OpReturnValue)
        emit!(c, OpReturn)
    end
    local_count = c.symbol_table[].definition_count[]
    instructions = leave_scope!(c).instructions
    fn = CompiledFunctionObj(instructions, local_count, length(fl.parameters))
    emit!(c, OpConstant, add!(c, fn) - 1)
end

compile!(c::Compiler, ident::Identifier) = begin
    sym = resolve(c.symbol_table[], ident.value)

    if isnothing(sym)
        throw(UndefVarError(ident.value))
    end

    load_symbol!(c, sym)
end

compile!(c::Compiler, es::ExpressionStatement) = begin
    compile!(c, es.expression)
    emit!(c, OpPop)
end

compile!(c::Compiler, ls::LetStatement) = begin
    compile!(c, ls.value)
    sym = define!(c.symbol_table[], ls.name.value)
    if sym.scope == GLOBAL_SCOPE
        emit!(c, OpSetGlobal, sym.index)
    else
        emit!(c, OpSetLocal, sym.index)
    end
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
    after_consequence_pos = length(c)
    change_operand!(c, jump_not_truthy_pos, after_consequence_pos)

    if !isnothing(ie.alternative)
        compile!(c, ie.alternative)
        remove_last_pop!(c)
    else
        emit!(c, OpNull)
    end

    after_alternative_pos = length(c)
    change_operand!(c, jump_pos, after_alternative_pos)
end

compile!(c::Compiler, ie::IndexExpression) = begin
    compile!(c, ie.left)
    compile!(c, ie.index)
    emit!(c, OpIndex)
end

compile!(c::Compiler, ce::CallExpression) = begin
    compile!(c, ce.fn)
    for arg in ce.arguments
        compile!(c, arg)
    end
    emit!(c, OpCall, length(ce.arguments))
end

compile!(c::Compiler, rs::ReturnStatement) = begin
    compile!(c, rs.return_value)
    emit!(c, OpReturnValue)
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

bytecode(c::Compiler) = ByteCode(current_scope(c).instructions, c.constants)
