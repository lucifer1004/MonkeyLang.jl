abstract type Object end

const INTEGER_OBJ = "INTEGER"
const BOOLEAN = "BOOLEAN"
const NULL = "NULL"
const RETURN_VALUE = "RETURN_VALUE"
const ERROR = "ERROR"
const FUNCTION_OBJ = "FUNCTION"
const STRING_OBJ = "STRING"
const BUILTIN_OBJ = "BUILTIN"
const ARRAY_OBJ = "ARRAY"

is_truthy(::Object) = true
Base.show(io::IO, object::Object) = print(io, string(object))

struct IntegerObj <: Object
  value::Int64
end

type_of(::IntegerObj) = INTEGER_OBJ
Base.string(i::IntegerObj) = string(i.value)

struct Boolean <: Object
  value::Bool
end

const _TRUE = Boolean(true)
const _FALSE = Boolean(false)
is_truthy(i::Boolean) = i.value
type_of(::Boolean) = BOOLEAN
Base.string(i::Boolean) = string(i.value)

struct Null <: Object end

const _NULL = Null()
is_truthy(::Null) = false
type_of(::Null) = NULL
Base.string(::Null) = "null"

struct ReturnValue <: Object
  value::Object
end

type_of(::ReturnValue) = RETURN_VALUE
Base.string(i::ReturnValue) = string(i.value)

struct Error <: Object
  message::String
end

type_of(::Error) = ERROR
Base.string(e::Error) = "ERROR: " * e.message

struct Environment
  store::Dict{String,Object}
  outer::Union{Environment,Nothing}
end

Environment() = Environment(Dict(), nothing)
Environment(outer::Environment) = Environment(Dict(), outer)
get(env::Environment, name::String) = begin
  result = Base.get(env.store, name, nothing)
  if isnothing(result) && !isnothing(env.outer)
    return get(env.outer, name)
  end
  return result
end
set!(env::Environment, name::String, value::Object) = push!(env.store, name => value)

struct FunctionObj <: Object
  parameters::Vector{Identifier}
  body::BlockStatement
  env::Environment
end

type_of(::FunctionObj) = FUNCTION_OBJ
Base.string(f::FunctionObj) = "fn(" * join(map(string, f.parameters), ", ") * ") {\n" * string(f.body) * "\n}"

struct StringObj <: Object
  value::String
end

type_of(::StringObj) = STRING_OBJ
Base.string(s::StringObj) = s.value

struct ArrayObj <: Object
  elements::Vector{Object}
end

type_of(::ArrayObj) = ARRAY_OBJ
Base.string(a::ArrayObj) = "[" * join(map(string, a.elements), ", ") * "]"

struct Builtin <: Object
  fn::Function
end

type_of(::Builtin) = BUILTIN_OBJ
Base.string(b::Builtin) = "builtin function"
