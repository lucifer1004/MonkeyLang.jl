function analyze(code::String; input::IO = stdin, output::IO = stdout)
    raw_program = parse(code; input, output)
    if !isnothing(raw_program)
        macro_env = Environment(; input, output)
        program = define_macros!(macro_env, raw_program)
        expanded = expand_macros(program, macro_env)
        return analyze(expanded)
    end
end

function analyze(program::Program; existing_symbol_table::Union{SymbolTable,Nothing} = nothing, exisiting_env::Union{Environment,Nothing} = nothing)
    if !isnothing(existing_symbol_table)
        symbol_table = SymbolTable(existing_symbol_table)
    else
        symbol_table = SymbolTable()
        for (i, (name, _)) in enumerate(BUILTINS)
            define_builtin!(symbol_table, name, i - 1)
        end

        if !isnothing(exisiting_env)
            for key in keys(exisiting_env.store)
                define!(symbol_table, key)
            end
        end
    end

    for statement in program.statements
        result = analyze(statement, symbol_table)
        if isa(result, ErrorObj)
            return result
        end
    end
end

function analyze(bs::BlockStatement, symbol_table::SymbolTable)
    for statement in bs.statements
        result = analyze(statement, symbol_table)
        if isa(result, ErrorObj)
            return result
        end
    end
end

analyze(es::ExpressionStatement, symbol_table::SymbolTable) =
    analyze(es.expression, symbol_table)

function analyze(ls::LetStatement, symbol_table::SymbolTable)
    if ls.reassign
        sym, _ = analyze_resolve(symbol_table, ls.name.value)

        if isnothing(sym)
            return ErrorObj("identifier not found: $(ls.name.value)")
        end

        if sym.scope == FunctionScope || (sym.scope == OuterScope && sym.ptr.scope == FunctionScope)
            return ErrorObj(
                "cannot reassign the current function being defined: $(ls.name.value)",
            )
        end
    else
        if ls.name.value ∈ keys(symbol_table.store)
            sym = symbol_table.store[ls.name.value]

            if sym.scope == LocalScope || (is_global(symbol_table) && sym.scope == GlobalScope)
                return ErrorObj("$(ls.name.value) is already defined")
            elseif sym.scope == GlobalScope
                return ErrorObj("cannot redefine global variable $(ls.name.value), since it has been used in the current scope")
            elseif sym.scope == BuiltinScope
                return ErrorObj("cannot redefine builtin $(ls.name.value), since it has been used in the current scope")
            else
                return ErrorObj("cannot redefine variable $(ls.name.value), since it has been used in the current scope")
            end
        end

        define!(symbol_table, ls.name.value)
    end

    return analyze(ls.value, symbol_table)
end

function analyze(ws::WhileStatement, symbol_table::SymbolTable)
    result = analyze(ws.condition, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    inner = SymbolTable(; outer = symbol_table, within_loop = true)
    return analyze(ws.body, inner)
end

analyze(rs::ReturnStatement, symbol_table::SymbolTable) =
    analyze(rs.return_value, symbol_table)

function analyze(::BreakStatement, symbol_table::SymbolTable)
    if !within_loop(symbol_table)
        return ErrorObj("syntax error: break outside loop")
    end
end

function analyze(::ContinueStatement, symbol_table::SymbolTable)
    if !within_loop(symbol_table)
        return ErrorObj("syntax error: continue outside loop")
    end
end

function analyze(ident::Identifier, symbol_table::SymbolTable)
    sym, _ = analyze_resolve(symbol_table, ident.value)
    if isnothing(sym)
        return ErrorObj("identifier not found: $(ident.value)")
    end
end

function analyze(al::ArrayLiteral, symbol_table::SymbolTable)
    for element in al.elements
        result = analyze(element, symbol_table)
        if isa(result, ErrorObj)
            return result
        end
    end
end

function analyze(hl::HashLiteral, symbol_table::SymbolTable)
    for (key, value) in hl.pairs
        result = analyze(key, symbol_table)
        if isa(result, ErrorObj)
            return result
        end

        result = analyze(value, symbol_table)
        if isa(result, ErrorObj)
            return result
        end
    end
end

function analyze(fl::FunctionLiteral, symbol_table::SymbolTable)
    inner = SymbolTable(; outer = symbol_table)

    if !isempty(fl.name)
        define_function!(inner, fl.name)
    end

    for param in fl.parameters
        define!(inner, param.value)
    end

    return analyze(fl.body, inner)
end

function analyze(ie::IfExpression, symbol_table::SymbolTable)
    result = analyze(ie.condition, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    result = analyze(ie.consequence, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    if !isnothing(ie.alternative)
        return analyze(ie.alternative, symbol_table)
    end
end

analyze(pe::PrefixExpression, symbol_table::SymbolTable) = analyze(pe.right, symbol_table)

function analyze(ie::InfixExpression, symbol_table::SymbolTable)
    result = analyze(ie.left, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    return analyze(ie.right, symbol_table)
end

function analyze(ie::IndexExpression, symbol_table::SymbolTable)
    result = analyze(ie.left, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    return analyze(ie.index, symbol_table)
end

function analyze(ce::CallExpression, symbol_table::SymbolTable)
    if (token_literal(ce.fn) == "quote")
        return nothing
    end

    result = analyze(ce.fn, symbol_table)
    if isa(result, ErrorObj)
        return result
    end

    for arg in ce.arguments
        result = analyze(arg, symbol_table)
        if isa(result, ErrorObj)
            return result
        end
    end
end

analyze_resolve(s::SymbolTable, name::String; level::Int = 0) = begin
    obj = Base.get(s.store, name, nothing)
    if isnothing(obj) && !isnothing(s.outer)
        obj, level = analyze_resolve(s.outer, name; level = level + 1)

        if isnothing(obj)
            return nothing, 0
        end

        if obj.scope == GlobalScope || obj.scope == BuiltinScope
            s.store[name] = obj # Mark the usage of global / builtin variables for the analyzer.
            return obj, level
        end

        sym = s.within_loop ? define_outer!(s, obj, level) : define_free!(s, obj)
        return sym, level
    else
        return obj, level
    end
end

# The following functions do nothing in the current version.

analyze(il::IntegerLiteral, symbol_table::SymbolTable) = nothing

analyze(sl::StringLiteral, symbol_table::SymbolTable) = nothing

analyze(bl::BooleanLiteral, symbol_table::SymbolTable) = nothing

analyze(::NullLiteral, ::SymbolTable) = nothing
