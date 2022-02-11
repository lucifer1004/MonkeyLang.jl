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
    within_loop::Bool
    free_symbols::Vector{MonkeySymbol}

    SymbolTable(; outer::Union{SymbolTable,Nothing} = nothing, within_loop::Bool = false) =
        new(Dict(), 0, outer, within_loop, [])

    SymbolTable(s::SymbolTable) =
        new(copy(s.store), s.definition_count, s.outer, s.within_loop, s.free_symbols)
end

is_global(s::SymbolTable) = isnothing(s.outer)

within_loop(s::SymbolTable) = s.within_loop

define!(s::SymbolTable, name::String) = begin
    scope = is_global(s) ? GlobalScope : LocalScope
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

        sym = s.within_loop ? define_outer!(s, obj, level) : define_free!(s, obj)
        return sym, level
    else
        return obj, level
    end
end
