abstract type Object end

const INTEGER = "INTEGER"
const BOOLEAN = "BOOLEAN"
const NULL = "NULL"
const RETURN_VALUE = "RETURN_VALUE"
const ERROR = "ERROR"
const FUNCTION_OBJ = "FUNCTION"

is_truthy(::Object) = true
Base.show(io::IO, object::Object) = print(io, string(object))

struct Integer <: Object
  value::Int64
end

type_of(::MonkeyLang.Integer) = INTEGER
Base.string(i::MonkeyLang.Integer) = string(i.value)

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
