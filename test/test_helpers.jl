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
