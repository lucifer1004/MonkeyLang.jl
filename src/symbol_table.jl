const GLOBAL_SCOPE = "GLOBAL"
const LOCAL_SCOPE = "LOCAL"
const BUILTIN_SCOPE = "BUILTIN"

struct MonkeySymbol
    name::String
    scope::String
    index::Int
end

struct SymbolTable
    store::Dict{String,MonkeySymbol}
    definition_count::Ref{Int}
    outer::Union{SymbolTable,Nothing}

    SymbolTable(outer = nothing) = new(Dict(), Ref(0), outer)
end

define!(s::SymbolTable, name::String) = begin
    scope = isnothing(s.outer) ? GLOBAL_SCOPE : LOCAL_SCOPE
    sym = MonkeySymbol(name, scope, s.definition_count[])
    s.store[name] = sym
    s.definition_count[] += 1
    return sym
end

define_builtin!(s::SymbolTable, name::String, index::Int) = begin
    sym = MonkeySymbol(name, BUILTIN_SCOPE, index)
    s.store[name] = sym
    return sym
end

resolve(s::SymbolTable, name::String) = begin
    obj = Base.get(s.store, name, nothing)
    if isnothing(obj) && !isnothing(s.outer)
        return resolve(s.outer, name)
    else
        return obj
    end
end
