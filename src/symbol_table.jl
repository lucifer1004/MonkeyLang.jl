const GLOBAL_SCOPE = "GLOBAL"
const LOCAL_SCOPE = "LOCAL"
const BUILTIN_SCOPE = "BUILTIN"
const FREE_SCOPE = "FREE"
const FUNCTION_SCOPE = "FUNCTION"

struct MonkeySymbol
    name::String
    scope::String
    index::Int
end

mutable struct SymbolTable
    store::Dict{String,MonkeySymbol}
    definition_count::Int
    outer::Union{SymbolTable,Nothing}
    free_symbols::Vector{MonkeySymbol}

    SymbolTable(outer = nothing) = new(Dict(), 0, outer, [])
end

define!(s::SymbolTable, name::String) = begin
    scope = isnothing(s.outer) ? GLOBAL_SCOPE : LOCAL_SCOPE
    sym = MonkeySymbol(name, scope, s.definition_count)
    s.store[name] = sym
    s.definition_count += 1
    return sym
end

define_builtin!(s::SymbolTable, name::String, index::Int) = begin
    sym = MonkeySymbol(name, BUILTIN_SCOPE, index)
    s.store[name] = sym
    return sym
end

define_free!(s::SymbolTable, original::MonkeySymbol) = begin
    push!(s.free_symbols, original)
    sym = MonkeySymbol(original.name, FREE_SCOPE, length(s.free_symbols) - 1)
    s.store[original.name] = sym
    return sym
end

define_function!(s::SymbolTable, name::String) = begin
    sym = MonkeySymbol(name, FUNCTION_SCOPE, 0)
    s.store[name] = sym
    return sym
end

resolve(s::SymbolTable, name::String) = begin
    obj = Base.get(s.store, name, nothing)
    if isnothing(obj) && !isnothing(s.outer)
        obj = resolve(s.outer, name)

        if isnothing(obj)
            return nothing
        end

        if obj.scope == GLOBAL_SCOPE || obj.scope == BUILTIN_SCOPE
            return obj
        end

        free = define_free!(s, obj)

        return free
    else
        return obj
    end
end
