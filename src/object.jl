abstract type Object end

const INTEGER = "INTEGER"
const BOOLEAN = "BOOLEAN"
const NULL = "NULL"
const RETURN_VALUE = "RETURN_VALUE"
const ERROR = "ERROR"

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
end

Environment() = Environment(Dict())
get(env::Environment, name::String) = Base.get(env.store, name, nothing)
set!(env::Environment, name::String, value::Object) = push!(env.store, name => value)
