struct Frame
    fn::CompiledFunctionObj
    ip::Ref{Int}
    base_ptr::Int

    Frame(fn::CompiledFunctionObj, base_ptr::Int) = new(fn, Ref(0), base_ptr)
end

instructions(f::Frame) = f.fn.instructions

struct VM
    constants::Vector{Object}
    stack::Vector{Object}
    sp::Ref{Int64}
    globals::Vector{Object}
    frames::Vector{Frame}

    VM(bc::ByteCode, globals::Vector{Object} = Object[]) = begin
        main_fn = CompiledFunctionObj(bc.instructions, 0, 0)
        main_frame = Frame(main_fn, 0)
        frames = [main_frame]
        new(bc.constants, [], Ref(1), globals, frames)
    end
end

Base.push!(vm::VM, obj::Object) = begin
    if vm.sp[] > length(vm.stack)
        append!(vm.stack, fill(_NULL, vm.sp[] - 1 - length(vm.stack)))
        push!(vm.stack, obj)
    else
        vm.stack[vm.sp[]] = obj
    end

    vm.sp[] += 1
end

Base.push!(vm::VM, frame::Frame) = push!(vm.frames, frame)

Base.pop!(vm::VM) = begin
    if vm.sp[] == 1
        return nothing
    end
    vm.sp[] -= 1
    return vm.stack[vm.sp[]]
end

pop_frame!(vm::VM) = pop!(vm.frames)

last_popped(vm::VM) = vm.sp[] > length(vm.stack) ? nothing : vm.stack[vm.sp[]]

current_frame(vm::VM) = vm.frames[end]

instructions(vm::VM) = instructions(current_frame(vm))

run!(vm::VM) = begin
    while current_frame(vm).ip[] < length(instructions(vm))
        cip = current_frame(vm).ip
        cip[] += 1
        ip = cip[]
        ins = instructions(vm)
        op = OpCode(ins[ip])
        if op == OpConstant
            cip[] += 2
            const_id = read_uint16(ins[ip+1:ip+2]) + 1
            if const_id > length(vm.constants)
                error(
                    "bounds error: attempt to access $(length(vm.constants))-element vector at index [$const_id]",
                )
            end
            push!(vm, vm.constants[const_id])
        elseif OpAdd <= op <= OpGreaterThan
            right = pop!(vm)
            left = pop!(vm)
            execute_binary_operation!(vm, op, left, right)
        elseif OpMinus <= op <= OpBang
            right = pop!(vm)
            execute_unary_operation!(vm, op, right)
        elseif op == OpPop
            pop!(vm)
        elseif op == OpTrue
            push!(vm, _TRUE)
        elseif op == OpFalse
            push!(vm, _FALSE)
        elseif op == OpNull
            push!(vm, _NULL)
        elseif OpJump <= op <= OpJumpNotTruthy
            pos = read_uint16(ins[ip+1:ip+2])

            if op == OpJump
                cip[] = pos
            else
                cip[] += 2
                condition = pop!(vm)
                if !is_truthy(condition)
                    cip[] = pos
                end
            end
        elseif OpGetGlobal <= op <= OpSetGlobal
            cip[] += 2
            global_index = read_uint16(ins[ip+1:ip+2])

            if op == OpSetGlobal
                if global_index + 1 > length(vm.globals)
                    push!(vm.globals, pop!(vm))
                else
                    vm.globals[global_index+1] = pop!(vm)
                end
            else
                push!(vm, vm.globals[global_index+1])
            end
        elseif OpGetLocal <= op <= OpSetLocal
            cip[] += 1
            local_index = ins[ip+1]
            frame = current_frame(vm)

            if op == OpSetLocal
                vm.stack[frame.base_ptr+local_index] = pop!(vm)
            else
                push!(vm, vm.stack[frame.base_ptr+local_index])
            end
        elseif op == OpArray
            cip[] += 2
            element_count = read_uint16(ins[ip+1:ip+2])
            arr = build_array!(vm, element_count)
            push!(vm, arr)
        elseif op == OpHash
            cip[] += 2
            element_count = read_uint16(ins[ip+1:ip+2])
            hash = build_hash!(vm, element_count)
            push!(vm, hash)
        elseif op == OpIndex
            index = pop!(vm)
            left = pop!(vm)
            if isa(left, ArrayObj)
                if !isa(index, IntegerObj)
                    error("invalid index $index for ARRAY")
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
                error("index operator not supported on $(type_of(left))")
            end
        elseif op == OpCall
            cip[] += 1
            arg_count = ins[ip+1]
            fn = vm.stack[vm.sp[]-1-arg_count]
            if !isa(fn, CompiledFunctionObj)
                error("can only call functions")
            end
            if arg_count != fn.param_count
                error("wrong number of arguments: expected $(fn.param_count), got $(arg_count)")
            end
            frame = Frame(fn, vm.sp[] - arg_count)
            push!(vm, frame)
            vm.sp[] = frame.base_ptr + fn.local_count
        elseif op == OpReturnValue
            return_value = pop!(vm)
            frame = pop_frame!(vm)
            vm.sp[] = frame.base_ptr - 1
            push!(vm, return_value)
        elseif op == OpReturn
            frame = pop_frame!(vm)
            vm.sp[] = frame.base_ptr - 1
            push!(vm, _NULL)
        end
    end

    return
end

execute_unary_operation!(vm::VM, op::OpCode, right::Object) = begin
    if op == OpBang
        push!(vm, native_bool_to_boolean_obj(!is_truthy(right)))
    elseif op == OpMinus
        if isa(right, IntegerObj)
            push!(vm, IntegerObj(-right.value))
        else
            error("unsupported type for negation: $(type_of(right))")
        end
    end
end

execute_binary_operation!(vm::VM, op::OpCode, left::Object, right::Object) = begin
    if type_of(left) != type_of(right)
        error("type mismatch: left: " * type_of(left) * ", right: " * type_of(right))
    end

    result = if op == OpEqual
        native_bool_to_boolean_obj(left == right)
    elseif op == OpNotEqual
        native_bool_to_boolean_obj(left != right)
    else
        error("unknown operator: " * type_of(left) * " " * string(op) * " " * type_of(right))
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
        error("unknown operator: STRING " * string(op) * " STRING")
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
        error("unknown operator: INTEGER " * string(op) * " INTEGER")
    end

    push!(vm, result)
end

build_array!(vm::VM, element_count::Integer) = begin
    elements = vm.stack[vm.sp[]-element_count:vm.sp[]-1]

    vm.sp[] -= element_count

    return ArrayObj(elements)
end

build_hash!(vm::VM, element_count::Integer) = begin
    elements = vm.stack[vm.sp[]-element_count:vm.sp[]-1]
    vm.sp[] -= element_count
    prs = Dict(elements[i] => elements[i+1] for i = 1:2:length(elements))
    return HashObj(prs)
end

native_bool_to_boolean_obj(b::Bool) = b ? _TRUE : _FALSE
