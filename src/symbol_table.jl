@enum Scope GlobalScope LocalScope BuiltinScope FreeScope FunctionScope OuterScope

struct SymbolPointer
    level::Int
    scope::Scope
    index::Int
end

struct MonkeySymbol
    name::String
    scope::Scope
    index::Int
    ptr::Union{SymbolPointer,Nothing}
end

mutable struct SymbolTable
    store::Dict{String,MonkeySymbol}
    definition_count::Int
    outer::Union{SymbolTable,Nothing}
    is_function::Bool
    free_symbols::Vector{MonkeySymbol}

    SymbolTable(outer = nothing, is_function = false) =
        new(Dict(), 0, outer, is_function, [])
end

define!(s::SymbolTable, name::String) = begin
    scope = isnothing(s.outer) ? GlobalScope : LocalScope
    sym = MonkeySymbol(name, scope, s.definition_count, nothing)
    s.store[name] = sym
    s.definition_count += 1
    return sym
end

define_builtin!(s::SymbolTable, name::String, index::Int) = begin
    sym = MonkeySymbol(name, BuiltinScope, index, nothing)
    s.store[name] = sym
    return sym
end

define_free!(s::SymbolTable, original::MonkeySymbol) = begin
    push!(s.free_symbols, original)
    sym = MonkeySymbol(original.name, FreeScope, length(s.free_symbols) - 1, nothing)
    s.store[original.name] = sym
    return sym
end

define_outer!(s::SymbolTable, original::MonkeySymbol, level::Int) = begin
    if original.scope == LocalScope ||
       original.scope == FreeScope ||
       original.scope == FunctionScope
        sym = MonkeySymbol(
            original.name,
            OuterScope,
            0,
            SymbolPointer(level, original.scope, original.index),
        )
    elseif original.scope == OuterScope
        sym = MonkeySymbol(
            original.name,
            OuterScope,
            0,
            SymbolPointer(
                level + original.ptr.level,
                original.ptr.scope,
                original.ptr.index,
            ),
        )
    end
    s.store[original.name] = sym
    return sym
end

define_function!(s::SymbolTable, name::String) = begin
    sym = MonkeySymbol(name, FunctionScope, 0, nothing)
    s.store[name] = sym
    return sym
end

resolve(s::SymbolTable, name::String; level::Int = 0) = begin
    obj = Base.get(s.store, name, nothing)
    if isnothing(obj) && !isnothing(s.outer)
        obj, level = resolve(s.outer, name; level = level + 1)

        if isnothing(obj)
            return nothing, 0
        end

        if obj.scope == GlobalScope || obj.scope == BuiltinScope
            return obj, level
        end

        sym = s.is_function ? define_free!(s, obj) : define_outer!(s, obj, level)
        return sym, level
    else
        return obj, level
    end
end
