abstract type Object end

@enum ObjectType INTEGER BOOLEAN NULL RETURN_VALUE

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
