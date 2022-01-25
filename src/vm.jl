struct VM
  instructions::Instructions
  constants::Vector{Object}
  stack::Vector{Object}
  globals::Vector{Object}
  sp::Ref{Int64}

  VM(bc::ByteCode) = new(bc.instructions, bc.constants, [], [], Ref(1))
  VM(bc::ByteCode, globals::Vector{Object}) = new(bc.instructions, bc.constants, [], globals, Ref(1))
end

Base.push!(vm::VM, obj::Object) = begin
  if vm.sp[] > length(vm.stack)
    push!(vm.stack, obj)
  else
    vm.stack[vm.sp[]] = obj
  end

  vm.sp[] += 1
end

Base.pop!(vm::VM) = begin
  if vm.sp[] == 1
    return nothing
  end
  ret = vm.stack[vm.sp[]-1]
  vm.sp[] -= 1
  return ret
end

last_popped(vm::VM) = vm.sp[] > length(vm.stack) ? nothing : vm.stack[vm.sp[]]

run!(vm::VM) = begin
  ip = 1
  while ip <= length(vm.instructions)
    op = OpCode(vm.instructions[ip])
    if op == OpConstant
      const_id = read_uint16(vm.instructions[ip+1:ip+2]) + 1
      ip += 2
      if const_id > length(vm.constants)
        error("bounds error: attempt to access $(length(vm.constants))-element vector at index [$const_id]")
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
      pos = read_uint16(vm.instructions[ip+1:ip+2])

      if op == OpJump
        ip = pos
      else
        ip += 2
        condition = pop!(vm)
        if !is_truthy(condition)
          ip = pos
        end
      end
    elseif OpGetGlobal <= op <= OpSetGlobal
      global_index = read_uint16(vm.instructions[ip+1:ip+2])
      ip += 2

      if op == OpSetGlobal
        if global_index + 1 > length(vm.globals)
          push!(vm.globals, pop!(vm))
        else
          vm.globals[global_index+1] = pop!(vm)
        end
      else
        push!(vm, vm.globals[global_index+1])
      end
    elseif op == OpArray
      element_count = read_uint16(vm.instructions[ip+1:ip+2])
      ip += 2
      arr = build_array!(vm, element_count)
      push!(vm, arr)
    end

    ip += 1
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

native_bool_to_boolean_obj(b::Bool) = b ? _TRUE : _FALSE
