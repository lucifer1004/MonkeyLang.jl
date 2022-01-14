abstract type Object end

const INTEGER = "INTEGER"
const BOOLEAN = "BOOLEAN"
const NULL = "NULL"
const RETURN_VALUE = "RETURN_VALUE"
const ERROR = "ERROR"

Base.show(io::IO, object::Object) = print(io, string(object))

struct Integer <: Object
  value::Int64
end

type_of(::MonkeyLang.Integer) = INTEGER
Base.string(i::MonkeyLang.Integer) = string(i.value)

struct Boolean <: Object
  value::Bool
end

type_of(::Boolean) = BOOLEAN
Base.string(i::Boolean) = string(i.value)

struct Null <: Object end

type_of(::Null) = NULL
Base.string(i::Null) = "null"

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
