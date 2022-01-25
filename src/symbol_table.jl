const GLOBAL_SCOPE = "GLOBAL"

struct MonkeySymbol
  name::String
  scope::String
  index::Int
end

struct SymbolTable
  store::Dict{String,MonkeySymbol}
  definition_count::Ref{Int}

  SymbolTable() = new(Dict(), Ref(0))
end

define!(s::SymbolTable, name::String) = begin
  sym = MonkeySymbol(name, GLOBAL_SCOPE, s.definition_count[])
  s.store[name] = sym
  s.definition_count[] += 1
  return sym
end

resolve(s::SymbolTable, name::String) = Base.get(s.store, name, nothing)
