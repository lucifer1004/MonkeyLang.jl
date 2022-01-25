struct VM
  instructions::Instructions
  constants::Vector{Object}
  stack::Vector{Object}

  VM(bc::ByteCode) = new(bc.instructions, bc.constants, [])
end

Base.push!(vm::VM, obj::Object) = push!(vm.stack, obj)
Base.pop!(vm::VM) = pop!(vm.stack)
stack_top(vm::VM) = isempty(vm.stack) ? nothing : vm.stack[end]

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
    elseif op <= OpGT
      right = pop!(vm)
      left = pop!(vm)
      lval = left.value
      rval = right.value

      if op == OpAdd
        push!(vm, IntegerObj(lval + rval))
      elseif op == OpSub
        push!(vm, IntegerObj(lval - rval))
      elseif op == OpMul
        push!(vm, IntegerObj(lval * rval))
      elseif op == OpDiv
        push!(vm, IntegerObj(lval ÷ rval))
      elseif op == OpEqual
        push!(vm, BooleanObj(lval == rval))
      elseif op == OpNotEqual
        push!(vm, BooleanObj(lval != rval))
      elseif op == OpLT
        push!(vm, BooleanObj(lval < rval))
      elseif op == OpGT
        push!(vm, BooleanObj(lval > rval))
      end
    end

    ip += 1
  end

  return
end
