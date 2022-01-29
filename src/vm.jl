mutable struct Frame
    cl::ClosureObj
    ip::Int
    base_ptr::Int

    Frame(cl::ClosureObj, base_ptr::Int) = new(cl, 0, base_ptr)
end

instructions(f::Frame) = f.cl.fn.instructions

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
            main_fn = CompiledFunctionObj(bc.instructions, 0, 0)
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
    if vm.sp == 1
        return nothing
    end
    vm.sp -= 1
    return vm.stack[vm.sp]
end

pop_frame!(vm::VM) = pop!(vm.frames)

last_popped(vm::VM) = vm.sp > length(vm.stack) ? nothing : vm.stack[vm.sp]

current_frame(vm::VM) = vm.frames[end]

instructions(vm::VM) = instructions(current_frame(vm))

run(code::String) = begin
    l = Lexer(code)
    p = Parser(l)
    program = parse!(p)
    c = Compiler()
    compile!(c, program)

    vm = VM(bytecode(c), Object[])
    return run!(vm)
end

run!(vm::VM) = begin
    while current_frame(vm).ip[] < length(instructions(vm))
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
                runtime_error!(
                    vm,
                    "bounds error: attempt to access $(length(vm.constants))-element vector at index [$const_id]",
                )
            end
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
        elseif op == OpGetBuiltin
            current_frame(vm).ip += 1
            builtin_id = ins[ip+1] + 1
            builtin = BUILTINS[builtin_id].second
            push!(vm, builtin)
        elseif op == OpGetFree
            current_frame(vm).ip += 1
            free_id = ins[ip+1] + 1
            push!(vm, current_frame(vm).cl.free[free_id])
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
                    runtime_error!(vm, "invalid index $index for ARRAY")
                    continue
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
                runtime_error!(vm, "index operator not supported on $(type_of(left))")
            end
        elseif op == OpCall
            current_frame(vm).ip += 1
            arg_count = ins[ip+1]
            callee = vm.stack[vm.sp-1-arg_count]
            call!(vm, callee, arg_count)
        elseif op == OpReturnValue
            return_value = pop!(vm)
            frame = pop_frame!(vm)
            vm.sp = frame.base_ptr - 1
            push!(vm, return_value)
        elseif op == OpReturn
            frame = pop_frame!(vm)
            vm.sp = frame.base_ptr - 1
            push!(vm, _NULL)
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
            runtime_error!(vm, "unsupported type for negation: $(type_of(right))")
        end
    end
end

execute_binary_operation!(vm::VM, op::OpCode, left::Object, right::Object) = begin
    if type_of(left) != type_of(right)
        return runtime_error!(
            vm,
            "type mismatch: left: " * type_of(left) * ", right: " * type_of(right),
        )
    end

    result = if op == OpEqual
        native_bool_to_boolean_obj(left == right)
    elseif op == OpNotEqual
        native_bool_to_boolean_obj(left != right)
    else
        return runtime_error!(
            vm,
            "unknown operator: " * type_of(left) * " " * string(op) * " " * type_of(right),
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
        return runtime_error!(vm, "unknown operator: STRING " * string(op) * " STRING")
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
            return runtime_error!(vm, "divide error: division by zero")
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
        return runtime_error!(vm, "unknown operator: INTEGER " * string(op) * " INTEGER")
    end

    push!(vm, result)
end

build_array!(vm::VM, element_count::Integer) = begin
    elements = vm.stack[vm.sp-element_count:vm.sp-1]

    vm.sp -= element_count

    return ArrayObj(elements)
end

build_hash!(vm::VM, element_count::Integer) = begin
    elements = vm.stack[vm.sp-element_count:vm.sp-1]
    vm.sp -= element_count
    prs = Dict(elements[i] => elements[i+1] for i = 1:2:length(elements))
    return HashObj(prs)
end

call!(vm::VM, ::Object, ::Integer) =
    runtime_error!(vm, "can only call functions or builtins")

call!(vm::VM, cl::ClosureObj, arg_count::Integer) = begin
    if arg_count != cl.fn.param_count
        vm.sp += cl.fn.local_count - arg_count
        runtime_error!(
            vm,
            "wrong number of arguments: expected $(cl.fn.param_count), got $(arg_count)",
        )
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
    vm.sp -= arg_count + 1
    push!(vm, result)
end

runtime_error!(vm::VM, msg::String) = push!(vm, ErrorObj(msg))

native_bool_to_boolean_obj(b::Bool) = b ? _TRUE : _FALSE
