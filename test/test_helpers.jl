function test_object(obj::m.Object, expected::Int64)
  @assert isa(obj, m.IntegerObj) "obj is not an INTEGER. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_object(obj::m.Object, expected::Bool)
  @assert isa(obj, m.BooleanObj) "obj is not a BOOLEAN. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_object(obj::m.Object, ::Nothing)
  @assert obj === m._NULL "obj is not NULL. Got $(m.type_of(obj)) instead."

  true
end

function test_object(obj::m.Object, expected::String)
  if occursin("error", expected)
    test_error_object(obj, expected)
  else
    test_string_object(obj, expected)
  end
end

function test_object(obj::m.ArrayObj, expected::Vector)
  @assert length(obj.elements) == length(expected) "Wrong number of elements. Expected $(length(expected)), got $(length(obj.elements)) instead."

  for (ca, ce) in zip(obj.elements, expected)
    test_object(ca, ce)
  end

  true
end

function test_object(obj::m.HashObj, expected::Dict)
  @assert length(obj.pairs) == length(expected) "Wrong number of pairs. Expected $(length(expected)), got $(length(obj.pairs)) instead."

  for (k, ce) in collect(expected)
    if isa(k, Int)
      ca = get(obj.pairs, k, nothing)
      test_object(ca, ce)
    end
  end

  true
end

function test_object(obj::m.CompiledFunctionObj, expected::m.Instructions)
  test_instructions(obj.instructions, [expected])
end

function test_error_object(obj::m.Object, expected::String)
  @assert isa(obj, m.ErrorObj) "obj is not an ERROR. Got $(m.type_of(obj)) instead."

  @assert obj.message == expected "wrong error message. Expected \"$expected\". Got \"$(obj.message)\" instead."

  true
end

function test_string_object(obj::m.Object, expected::String)
  @assert isa(obj, m.StringObj) "object is not a STRING. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "Expected $expected. Got $(obj.value) instead."

  true
end

function test_instructions(actual, expected)
  concatted = vcat(expected...)

  @assert length(concatted) == length(actual) "Wrong instructions length. Expected $concatted, got $actual instead."

  for i = 1:length(concatted)
    @assert concatted[i] == actual[i] "Wrong instruction at index $(i). Expected $(concatted[i]), got $(actual[i]) instead."
  end

  true
end

function test_constants(actual, expected)
  @assert length(expected) == length(actual) "Wrong constants length. Expected $(length(expected)), got $(length(actual)) instead."

  for (ca, ce) in zip(actual, expected)
    test_object(ca, ce)
  end

  true
end

function run_compiler_tests(input::String, expected_constants::Vector, expected_instructions::Vector{m.Instructions})
  program = m.parse(input)
  c = m.Compiler()
  m.compile!(c, program)

  bc = m.bytecode(c)

  test_instructions(bc.instructions, expected_instructions)
  test_constants(bc.constants, expected_constants)

  true
end

function test_vm(input::String, expected)
  program = m.parse(input)
  c = m.Compiler()
  m.compile!(c, program)
  vm = m.VM(m.bytecode(c))
  m.run!(vm)

  test_object(m.last_popped(vm), expected)
end
