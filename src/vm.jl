mutable struct Frame
    cl::ClosureObj
    ip::Int
    base_ptr::Int

    Frame(cl::ClosureObj, base_ptr::Int) = new(cl, 0, base_ptr)
end

instructions(f::Frame) = f.cl.fn.instructions
within_loop(f::Frame) = f.cl.fn.within_loop

mutable struct VM
    constants::Vector{Object}
    stack::Vector{Object}
    sp::Int64
    globals::Vector{Object}
    frames::Vector{Frame}
    input::IO
    output::IO

    VM(bc::ByteCode, globals::Vector{Object} = Object[]; input = stdin, output = stdout) =
        begin
            main_fn = CompiledFunctionObj(bc.instructions, 0, 0, false)
            main_closure = ClosureObj(main_fn, [])
            main_frame = Frame(main_closure, 0)
            frames = [main_frame]
            new(bc.constants, [], 1, globals, frames, input, output)
        end
end

Base.push!(vm::VM, obj::Object) = begin
    if vm.sp > length(vm.stack)
        append!(vm.stack, fill(_NULL, vm.sp - 1 - length(vm.stack)))
        push!(vm.stack, obj)
    else
        vm.stack[vm.sp] = obj
    end

    vm.sp += 1
end

push_frame!(vm::VM, frame::Frame) = push!(vm.frames, frame)

push_closure!(vm::VM, id::Int, free_count::Integer) = begin
    fn = vm.constants[id]
    free = vm.stack[vm.sp-free_count:vm.sp-1]
    vm.sp -= free_count
    closure = ClosureObj(fn, free)
    push!(vm, closure)
end

Base.pop!(vm::VM) = begin
    if vm.sp <= 1 || vm.sp > length(vm.stack) + 1
        error("stack underflow")
    end
    vm.sp -= 1
    return vm.stack[vm.sp]
end

pop_frame!(vm::VM) = pop!(vm.frames)

last_popped(vm::VM) = vm.sp > length(vm.stack) ? nothing : vm.stack[vm.sp]

current_frame(vm::VM) = vm.frames[end]

instructions(vm::VM) = instructions(current_frame(vm))

macro monkey_vm_str(code::String)
    quote
        run($(esc(Meta.parse("\"$(escape_string(code))\""))))
    end
end

run(code::String; input = stdin, output = stdout) = begin
    raw_program = parse(code; input, output)
    if !isnothing(raw_program)
        macro_env = Environment(; input, output)
        program = define_macros!(macro_env, raw_program)
        expanded = expand_macros(program, macro_env)

        syntax_check_result = analyze(expanded)
        if isa(syntax_check_result, ErrorObj)
            println(output, syntax_check_result)
            return syntax_check_result
        end

        c = Compiler()
        compile!(c, expanded)
        vm = VM(bytecode(c), Object[]; input, output)

        result = run!(vm)
        if isa(result, ErrorObj)
            println(output, result)
        end

        return result
    end
end

run!(vm::VM) = begin
    @debug "Executing instructions:\n$(string(instructions(vm)))"

    while current_frame(vm).ip < length(instructions(vm))
        current_frame(vm).ip += 1
        ip = current_frame(vm).ip
        ins = instructions(vm)
        op = OpCode(ins[ip])
        if op == OpConstant
            current_frame(vm).ip += 2
            const_id = read_uint16(ins, ip + 1) + 1
            if 1 <= const_id <= length(vm.constants)
                push!(vm, vm.constants[const_id])
            else
                return ErrorObj(
                    "bounds error: attempt to access $(length(vm.constants))-element vector at index [$const_id]",
                )
            end
        elseif OpAdd <= op <= OpGreaterThan
            right = pop!(vm)
            left = pop!(vm)
            err = execute_binary_operation!(vm, op, left, right)
            if isa(err, ErrorObj)
                return err
            end
        elseif OpMinus <= op <= OpBang
            right = pop!(vm)
            err = execute_unary_operation!(vm, op, right)
            if isa(err, ErrorObj)
                return err
            end
        elseif op == OpPop
            pop!(vm)
        elseif op == OpTrue
            push!(vm, _TRUE)
        elseif op == OpFalse
            push!(vm, _FALSE)
        elseif op == OpNull
            push!(vm, _NULL)
        elseif OpJump <= op <= OpJumpNotTruthy
            pos = read_uint16(ins, ip + 1)

            if op == OpJump
                current_frame(vm).ip = pos
            else
                current_frame(vm).ip += 2
                condition = pop!(vm)
                if !is_truthy(condition)
                    current_frame(vm).ip = pos
                end
            end
        elseif OpGetGlobal <= op <= OpSetGlobal
            current_frame(vm).ip += 2
            global_id = read_uint16(ins, ip + 1)

            if op == OpSetGlobal
                if global_id + 1 > length(vm.globals)
                    push!(vm.globals, pop!(vm))
                else
                    vm.globals[global_id+1] = pop!(vm)
                end
            else
                push!(vm, vm.globals[global_id+1])
            end
        elseif OpGetLocal <= op <= OpSetLocal
            current_frame(vm).ip += 1
            local_id = ins[ip+1]
            frame = current_frame(vm)

            if op == OpSetLocal
                vm.stack[frame.base_ptr+local_id] = pop!(vm)
            else
                push!(vm, vm.stack[frame.base_ptr+local_id])
            end
        elseif OpGetOuter <= op <= OpSetOuter
            current_frame(vm).ip += 3
            level = ins[ip+1]
            scope = Scope(ins[ip+2])
            id = ins[ip+3]

            frame = vm.frames[end-level]

            if op == OpGetOuter
                if scope == LocalScope
                    push!(vm, vm.stack[frame.base_ptr+id])
                elseif scope == FreeScope
                    push!(vm, frame.cl.free[id+1])
                elseif scope == FunctionScope
                    push!(vm, frame.cl)
                end
            else
                if scope == LocalScope
                    vm.stack[frame.base_ptr+id] = pop!(vm)
                elseif scope == FreeScope
                    frame.cl.free[id+1] = pop!(vm)
                end
            end
        elseif op == OpGetBuiltin
            current_frame(vm).ip += 1
            builtin_id = ins[ip+1] + 1
            builtin = BUILTINS[builtin_id].second
            push!(vm, builtin)
        elseif OpGetFree <= op <= OpSetFree
            current_frame(vm).ip += 1
            free_id = ins[ip+1] + 1

            if op == OpGetFree
                push!(vm, current_frame(vm).cl.free[free_id])
            else
                current_frame(vm).cl.free[free_id] = pop!(vm)
            end
        elseif op == OpArray
            current_frame(vm).ip += 2
            element_count = read_uint16(ins, ip + 1)
            arr = build_array!(vm, element_count)
            push!(vm, arr)
        elseif op == OpHash
            current_frame(vm).ip += 2
            element_count = read_uint16(ins, ip + 1)
            hash = build_hash!(vm, element_count)
            push!(vm, hash)
        elseif op == OpClosure
            current_frame(vm).ip += 3
            const_id = read_uint16(ins, ip + 1) + 1
            free_count = ins[ip+3]
            push_closure!(vm, const_id, free_count)
        elseif op == OpCurrentClosure
            push!(vm, current_frame(vm).cl)
        elseif op == OpIndex
            index = pop!(vm)
            left = pop!(vm)
            if isa(left, ArrayObj)
                if !isa(index, IntegerObj)
                    return ErrorObj("unsupported index type: $(type_of(index))")
                end

                i = index.value
                if 0 <= i < length(left.elements)
                    push!(vm, left.elements[i+1])
                else
                    push!(vm, _NULL)
                end
            elseif isa(left, HashObj)
                if index ∈ keys(left.pairs)
                    push!(vm, left.pairs[index])
                else
                    push!(vm, _NULL)
                end
            else
                return ErrorObj("index operator not supported: $(type_of(left))")
            end
        elseif op == OpCall
            current_frame(vm).ip += 1
            arg_count = ins[ip+1]
            callee = vm.stack[vm.sp-1-arg_count]
            err = call!(vm, callee, arg_count)
            if isa(err, ErrorObj)
                return err
            end
        elseif OpBreak <= op <= OpContinue
            current_frame(vm).ip += 1
            return_value = native_bool_to_boolean_obj(op == OpContinue)
            frame = pop_frame!(vm)
            vm.sp = frame.base_ptr - 1
            push!(vm, return_value)
        elseif OpReturnValue <= op <= OpReturn
            return_value = op == OpReturnValue ? pop!(vm) : _NULL
            frame = pop_frame!(vm)
            if op == OpReturnValue
                while within_loop(frame)
                    frame = pop_frame!(vm)
                end
            end
            if isempty(vm.frames)
                return return_value
            end
            vm.sp = frame.base_ptr - 1
            push!(vm, return_value)
        end
    end

    return last_popped(vm)
end

execute_unary_operation!(vm::VM, op::OpCode, right::Object) = begin
    if op == OpBang
        push!(vm, native_bool_to_boolean_obj(!is_truthy(right)))
    elseif op == OpMinus
        if isa(right, IntegerObj)
            push!(vm, IntegerObj(-right.value))
        else
            return ErrorObj("unknown operator: -$(type_of(right))")
        end
    end
end

execute_binary_operation!(vm::VM, op::OpCode, left::Object, right::Object) = begin
    if type_of(left) != type_of(right)
        return ErrorObj(
            "type mismatch: " *
            type_of(left) *
            " " *
            OPCODE_STRINGS[op] *
            " " *
            type_of(right),
        )
    end

    result = if op == OpEqual
        native_bool_to_boolean_obj(left == right)
    elseif op == OpNotEqual
        native_bool_to_boolean_obj(left != right)
    else
        return ErrorObj(
            "unknown operator: " *
            type_of(left) *
            " " *
            OPCODE_STRINGS[op] *
            " " *
            type_of(right),
        )
    end

    push!(vm, result)
end

execute_binary_operation!(vm::VM, op::OpCode, left::StringObj, right::StringObj) = begin
    lval = left.value
    rval = right.value

    result = if op == OpAdd
        StringObj(lval * rval)
    elseif op == OpEqual
        native_bool_to_boolean_obj(lval == rval)
    elseif op == OpNotEqual
        native_bool_to_boolean_obj(lval != rval)
    else
        return ErrorObj("unknown operator: STRING " * OPCODE_STRINGS[op] * " STRING")
    end

    push!(vm, result)
end

execute_binary_operation!(vm::VM, op::OpCode, left::IntegerObj, right::IntegerObj) = begin
    lval = left.value
    rval = right.value

    result = if op == OpAdd
        IntegerObj(lval + rval)
    elseif op == OpSub
        IntegerObj(lval - rval)
    elseif op == OpMul
        IntegerObj(lval * rval)
    elseif op == OpDiv
        if rval == 0
            return ErrorObj("divide error: division by zero")
        end
        IntegerObj(lval ÷ rval)
    elseif op == OpEqual
        native_bool_to_boolean_obj(lval == rval)
    elseif op == OpNotEqual
        native_bool_to_boolean_obj(lval != rval)
    elseif op == OpLessThan
        native_bool_to_boolean_obj(lval < rval)
    elseif op == OpGreaterThan
        native_bool_to_boolean_obj(lval > rval)
    else
        return ErrorObj("unknown operator: INTEGER " * string(op) * " INTEGER")
    end

    push!(vm, result)
end

build_array!(vm::VM, element_count::Integer)::ArrayObj = begin
    elements = vm.stack[vm.sp-element_count:vm.sp-1]

    vm.sp -= element_count

    return ArrayObj(elements)
end

build_hash!(vm::VM, element_count::Integer)::HashObj = begin
    elements = vm.stack[vm.sp-element_count:vm.sp-1]
    vm.sp -= element_count
    prs = Dict(elements[i] => elements[i+1] for i = 1:2:length(elements))
    return HashObj(prs)
end

call!(::VM, obj::Object, ::Integer) = return ErrorObj("not a function: $(type_of(obj))")

call!(vm::VM, cl::ClosureObj, arg_count::Integer) = begin
    if arg_count != cl.fn.param_count
        vm.sp += cl.fn.local_count - arg_count
        return ErrorObj("argument error: wrong number of arguments: got $(arg_count)")
    else
        frame = Frame(cl, vm.sp - arg_count)
        push_frame!(vm, frame)
        vm.sp += cl.fn.local_count - arg_count
    end
end

call!(vm::VM, builtin::Builtin, arg_count::Integer) = begin
    args = vm.stack[vm.sp-arg_count:vm.sp-1]
    result =
        builtin.fn(args...; env = Environment(; input = vm.input, output = vm.output))
    if isa(result, ErrorObj)
        return result
    end
    vm.sp -= arg_count + 1
    push!(vm, result)
end

native_bool_to_boolean_obj(b::Bool) = b ? _TRUE : _FALSE
