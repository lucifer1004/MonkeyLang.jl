function test_integer_object(obj::m.Object, expected::Int64)
  @assert isa(obj, m.IntegerObj) "obj is not an INTEGER. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_boolean_object(obj::m.Object, expected::Bool)
  @assert isa(obj, m.BooleanObj) "obj is not a BooleanObj. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "obj.value is not $expected. Got $(obj.value) instead."

  true
end

function test_null_object(obj::m.Object)
  @assert obj === m._NULL "object is not NULL. Got $(obj) instead."

  true
end

function test_error_object(obj::m.Object, expected::String)
  @assert isa(obj, m.ErrorObj) "no error object returned. Got $(m.type_of(obj)) instead."

  @assert obj.message == expected "wrong error message. Expected \"$expected\". Got \"$(obj.message)\" instead."

  true
end

function test_string_object(obj::m.Object, expected::String)
  @assert isa(obj, m.StringObj) "no string object returned. Got $(m.type_of(obj)) instead."

  @assert obj.value == expected "Expected $expected. Got $(obj.value) instead."

  true
end

function test_object(obj::m.Object, expected)
  if isa(expected, Int)
    test_integer_object(obj, expected)
  elseif isa(expected, Bool)
    test_boolean_object(obj, expected)
  elseif isa(expected, String)
    test_string_object(obj, expected)
  end
end
