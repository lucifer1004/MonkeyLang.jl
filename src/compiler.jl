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

function last_instruction(c::CompilationScope)
    isempty(c.previous_instructions) ? nothing : c.previous_instructions[end]
end

function prev_instruction(c::CompilationScope)
    length(c.previous_instructions) < 2 ? nothing : c.previous_instructions[1]
end

mutable struct Compiler
    symbol_table::SymbolTable
    constants::Vector{Object}
    scopes::Vector{CompilationScope}

    Compiler() = begin
        s = SymbolTable()
        for (i, (name, _)) in enumerate(BUILTINS)
            define_builtin!(s, name, i - 1)
        end
        new(s, [], [CompilationScope(Instructions([]), [])])
    end
    function Compiler(s::SymbolTable, constants::Vector{Object})
        new(s, constants, [CompilationScope(Instructions([]), [])])
    end
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

function replace_last!(c::Compiler, ins::Instructions)
    cs = current_scope(c)
    last_pos = last_instruction(c).position
    replace!(c, last_pos, ins)
    cs.previous_instructions[end] = EmittedInstruction(OpReturnValue, last_pos)
end

function set_last!(c::Compiler, op::OpCode, pos::Int)
    cs = current_scope(c)
    last = EmittedInstruction(op, pos)
    if length(cs.previous_instructions) == 2
        cs.previous_instructions[1] = cs.previous_instructions[2]
        cs.previous_instructions[2] = last
    else
        push!(cs.previous_instructions, last)
    end
end

function remove_last!(c::Compiler)
    begin
        cs = current_scope(c)
        splice!(cs.instructions, (last_instruction(cs).position):length(cs.instructions))
        pop!(cs.previous_instructions)
    end
end

remove_last_pop!(c::Compiler) =
    if last_instruction_is(c, OpPop)
        remove_last!(c)
    end

function replace_last_pop_with_return!(c::Compiler)
    if last_instruction_is(c, OpPop)
        replace_last!(c, make(OpReturnValue))
    end
end

function replace!(c::Compiler, pos::Int, new_ins::Instructions)
    cs = current_scope(c)
    for i in 1:length(new_ins)
        if pos + i - 1 <= length(cs.instructions)
            cs.instructions[pos + i - 1] = new_ins[i]
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

function enter_scope!(c::Compiler; within_loop::Bool = false)
    c.symbol_table = SymbolTable(; outer = c.symbol_table, within_loop)
    push!(c.scopes, CompilationScope(Instructions([]), []))
end

leave_scope!(c::Compiler)::CompilationScope = begin
    c.symbol_table = c.symbol_table.outer
    pop!(c.scopes)
end

function load_symbol!(c::Compiler, s::MonkeySymbol)
    begin if s.scope == GlobalScope
        emit!(c, OpGetGlobal, s.index)
    elseif s.scope == LocalScope
        emit!(c, OpGetLocal, s.index)
    elseif s.scope == BuiltinScope
        emit!(c, OpGetBuiltin, s.index)
    elseif s.scope == FreeScope
        emit!(c, OpGetFree, s.index)
    elseif s.scope == OuterScope
        emit!(c, OpGetOuter, s.ptr.level, Int(s.ptr.scope), s.ptr.index)
    else
        emit!(c, OpCurrentClosure)
    end end
end

function compile!(c::Compiler, il::IntegerLiteral)
    emit!(c, OpConstant, add!(c, IntegerObj(il.value)) - 1)
end

compile!(c::Compiler, il::BooleanLiteral) = emit!(c, il.value ? OpTrue : OpFalse)

compile!(c::Compiler, ::NullLiteral) = emit!(c, OpNull)

function compile!(c::Compiler, sl::StringLiteral)
    emit!(c, OpConstant, add!(c, StringObj(sl.value)) - 1)
end

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

function compile!(c::Compiler, fl::FunctionLiteral; within_loop::Bool = false)
    enter_scope!(c; within_loop)

    if !isempty(fl.name)
        define_function!(c.symbol_table, fl.name)
    end

    for param in fl.parameters
        define!(c.symbol_table, param.value)
    end

    compile!(c, fl.body)

    if !within_loop
        replace_last_pop_with_return!(c)
        if !last_instruction_is(c, OpReturnValue)
            emit!(c, OpReturn)
        end
    end

    free_symbols = c.symbol_table.free_symbols
    local_count = c.symbol_table.definition_count
    instructions = leave_scope!(c).instructions

    for sym in free_symbols
        load_symbol!(c, sym)
    end

    fn = CompiledFunctionObj(instructions, local_count, length(fl.parameters),
                             within_loop)
    emit!(c, OpClosure, add!(c, fn) - 1, length(free_symbols))
end

compile!(c::Compiler, ident::Identifier) = begin
    sym, _ = resolve(c.symbol_table, ident.value)
    load_symbol!(c, sym)
end

compile!(c::Compiler, es::ExpressionStatement) = begin
    compile!(c, es.expression)
    emit!(c, OpPop)
end

function compile!(c::Compiler, ls::LetStatement)
    compile!(c, ls.value)

    sym, _ = resolve(c.symbol_table, ls.name.value)

    if ls.reassign
        if sym.scope == GlobalScope
            # Reassign a global variable
            emit!(c, OpSetGlobal, sym.index)
        elseif sym.scope == LocalScope
            # Reassign a local variable
            emit!(c, OpSetLocal, sym.index)
        elseif sym.scope == FreeScope
            # Reassign a free variable (for functions)
            emit!(c, OpSetFree, sym.index)
        else
            # Reassign an outer variable (for while loops)
            emit!(c, OpSetOuter, sym.ptr.level, Int(sym.ptr.scope), sym.ptr.index)
        end
    else
        sym = define!(c.symbol_table, ls.name.value)
        if sym.scope == GlobalScope
            emit!(c, OpSetGlobal, sym.index)
        else
            emit!(c, OpSetLocal, sym.index)
        end
    end
end

function compile!(c::Compiler, pe::PrefixExpression)
    compile!(c, pe.right)

    if pe.operator == "-"
        emit!(c, OpMinus)
    elseif pe.operator == "!"
        emit!(c, OpBang)
    else
        error("unknown operator: $(pe.operator)")
    end
end

function compile!(c::Compiler, ie::InfixExpression)
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

function compile!(c::Compiler, ie::IfExpression)
    compile!(c, ie.condition)
    jump_not_truthy_pos = emit!(c, OpJumpNotTruthy, 9999)
    compile!(c, ie.consequence)
    if isempty(ie.consequence.statements)
        emit!(c, OpNull)
    else
        remove_last_pop!(c)
    end

    jump_pos = emit!(c, OpJump, 9999)
    after_consequence_pos = length(c)
    change_operand!(c, jump_not_truthy_pos, after_consequence_pos)

    if isnothing(ie.alternative) || isempty(ie.alternative.statements)
        emit!(c, OpNull)
    else
        compile!(c, ie.alternative)
        remove_last_pop!(c)
    end

    after_alternative_pos = length(c)
    change_operand!(c, jump_pos, after_alternative_pos)
end

function compile!(c::Compiler, ws::WhileStatement)
    loop_start_pos = length(c)
    compile!(c, ws.condition)
    jump_not_truthy_pos = emit!(c, OpJumpNotTruthy, 9999)

    # Compile body of a while statement to a special closure that resolves 
    # outer variables instead of free variables.
    body = BlockStatement(ws.body.token,
                          [
                              ws.body.statements...,
                              ContinueStatement(Token(CONTINUE, "continue")),
                          ])
    fl = FunctionLiteral(Token(FUNCTION, "fn"), Identifier[], body)
    compile!(c, fl; within_loop = true)

    # Call the closure and use the return value to detect a break or continue
    emit!(c, OpCall, 0)
    jump_on_break_pos = emit!(c, OpJumpNotTruthy, 9999)

    emit!(c, OpJump, loop_start_pos)
    after_body_pos = length(c)

    change_operand!(c, jump_not_truthy_pos, after_body_pos)
    change_operand!(c, jump_on_break_pos, after_body_pos)

    emit!(c, OpNull)
    emit!(c, OpPop)
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

compile!(c::Compiler, ::BreakStatement) = emit!(c, OpBreak)

compile!(c::Compiler, ::ContinueStatement) = emit!(c, OpContinue)

function compile!(c::Compiler, bs::BlockStatement)
    for statement in bs.statements
        compile!(c, statement)
    end
end

function compile!(c::Compiler, program::Program)
    for statement in program.statements
        compile!(c, statement)
    end
end

bytecode(c::Compiler) = ByteCode(current_scope(c).instructions, c.constants)
