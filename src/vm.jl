struct VM
  instructions::Instructions
  constants::Vector{Object}
  stack::Vector{Object}
  last_popped::Vector{Object}

  VM(bc::ByteCode) = new(bc.instructions, bc.constants, [], [_NULL])
end

Base.push!(vm::VM, obj::Object) = push!(vm.stack, obj)
Base.pop!(vm::VM) = pop!(vm.stack)
last_popped(vm::VM) = vm.last_popped[1]

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
      vm.last_popped[1] = pop!(vm)
    elseif op == OpTrue
      push!(vm, _TRUE)
    elseif op == OpFalse
      push!(vm, _FALSE)
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
  end

  push!(vm, result)
end

native_bool_to_boolean_obj(b::Bool) = b ? _TRUE : _FALSE
