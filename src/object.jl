abstract type Object end

const INTEGER_OBJ = "INTEGER"
const BOOLEAN_OBJ = "BOOLEAN"
const NULL_OBJ = "NULL"
const RETURN_VALUE = "RETURN_VALUE"
const ERROR_OBJ = "ERROR"
const FUNCTION_OBJ = "FUNCTION"
const STRING_OBJ = "STRING"
const BUILTIN_OBJ = "BUILTIN"
const ARRAY_OBJ = "ARRAY"
const HASH_OBJ = "HASH"
const QUOTE_OBJ = "QUOTE"
const MACRO_OBJ = "MACRO"
const COMPILED_FUNCTION_OBJ = "COMPILED_FUNCTION"
const CLOSURE_OBJ = "CLOSURE"

is_truthy(::Object) = true
Base.show(io::IO, object::Object) = print(io, string(object))

struct IntegerObj <: Object
    value::Int64
end

type_of(::IntegerObj) = INTEGER_OBJ
Base.string(i::IntegerObj) = string(i.value)
Base.:(==)(a::IntegerObj, b::IntegerObj) = a.value == b.value
Base.hash(i::IntegerObj) = hash(i.value)

struct BooleanObj <: Object
    value::Bool
end

const _TRUE = BooleanObj(true)
const _FALSE = BooleanObj(false)
is_truthy(b::BooleanObj) = b.value
type_of(::BooleanObj) = BOOLEAN_OBJ
Base.string(b::BooleanObj) = string(b.value)
Base.:(==)(a::BooleanObj, b::BooleanObj) = a.value == b.value
Base.hash(b::BooleanObj) = hash(b.value)

struct NullObj <: Object end

const _NULL = NullObj()
is_truthy(::NullObj) = false
type_of(::NullObj) = NULL_OBJ
Base.string(::NullObj) = "null"

struct ReturnValue <: Object
    value::Object
end

type_of(::ReturnValue) = RETURN_VALUE
Base.string(r::ReturnValue) = string(r.value)

struct ErrorObj <: Object
    message::String
end

type_of(::ErrorObj) = ERROR_OBJ
Base.string(e::ErrorObj) = "ERROR: " * e.message

struct Environment
    store::Dict{String,Object}
    outer::Union{Environment,Nothing}
    input::IO
    output::IO
end

Environment(; input = stdin, output = stdout) = Environment(Dict(), nothing, input, output)
Environment(outer::Environment) = Environment(Dict(), outer, outer.input, outer.output)
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
Base.string(f::FunctionObj) =
    "fn(" * join(map(string, f.parameters), ", ") * ") {\n" * string(f.body) * "\n}"

struct StringObj <: Object
    value::String
end

type_of(::StringObj) = STRING_OBJ
Base.string(s::StringObj) = "\"" * string(s.value) * "\""
Base.:(==)(a::StringObj, b::StringObj) = a.value == b.value
Base.hash(s::StringObj) = hash(s.value)

struct ArrayObj <: Object
    elements::Vector{Object}
end

type_of(::ArrayObj) = ARRAY_OBJ
Base.string(a::ArrayObj) = "[" * join(map(string, a.elements), ", ") * "]"
Base.:(==)(a::ArrayObj, b::ArrayObj) = a.elements == b.elements
Base.hash(a::ArrayObj) = hash(a.elements)

struct Builtin <: Object
    fn::Function
end

type_of(::Builtin) = BUILTIN_OBJ
Base.string(b::Builtin) = "builtin function"

struct HashObj <: Object
    pairs::Dict{Object,Object}
end

type_of(::HashObj) = HASH_OBJ
Base.string(h::HashObj) =
    "{" * join(map(x -> string(x[1]) * ":" * string(x[2]), collect(h.pairs)), ", ") * "}"
Base.:(==)(a::HashObj, b::HashObj) = a.pairs == b.pairs
Base.hash(h::HashObj) = hash(h.pairs)

struct QuoteObj <: Object
    node::Node
end

type_of(::QuoteObj) = QUOTE_OBJ
Base.string(q::QuoteObj) = "QUOTE(" * string(q.node) * ")"

struct MacroObj <: Object
    parameters::Vector{Identifier}
    body::BlockStatement
    env::Environment
end

type_of(::MacroObj) = MACRO_OBJ
Base.string(m::MacroObj) =
    "macro(" * join(map(string, m.parameters), ", ") * ") {\n" * string(m.body) * "\n}"

struct CompiledFunctionObj <: Object
    instructions::Instructions
    local_count::Int
    param_count::Int
end

type_of(::CompiledFunctionObj) = COMPILED_FUNCTION_OBJ
Base.string(c::CompiledFunctionObj) = "compiled function"

struct ClosureObj <: Object
    fn::CompiledFunctionObj
    free::Vector{Object}
end

type_of(::ClosureObj) = CLOSURE_OBJ
Base.string(c::ClosureObj) = "closure"
