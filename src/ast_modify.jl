modify(::Nothing, ::Function) = nothing
modify(node::Node, modifier::Function) = modifier(node)

function modify(program::Program, modifier::Function)
    Program(map(statement -> modify(statement, modifier), program.statements))
end

function modify(node::LetStatement, modifier::Function)
    LetStatement(node.token, node.name, modify(node.value, modifier), node.reassign)
end

function modify(node::ReturnStatement, modifier::Function)
    ReturnStatement(node.token, modify(node.return_value, modifier))
end

function modify(node::ExpressionStatement, modifier::Function)
    ExpressionStatement(node.token, modify(node.expression, modifier))
end

function modify(node::BlockStatement, modifier::Function)
    BlockStatement(node.token,
        map(statement -> modify(statement, modifier), node.statements))
end

function modify(node::PrefixExpression, modifier::Function)
    PrefixExpression(node.token, node.operator, modify(node.right, modifier))
end

function modify(node::InfixExpression, modifier::Function)
    InfixExpression(node.token,
        modify(node.left, modifier),
        node.operator,
        modify(node.right, modifier))
end

function modify(node::IfExpression, modifier::Function)
    IfExpression(node.token,
        modify(node.condition, modifier),
        modify(node.consequence, modifier),
        modify(node.alternative, modifier))
end

function modify(node::IndexExpression, modifier::Function)
    IndexExpression(node.token, modify(node.left, modifier), modify(node.index, modifier))
end

function modify(node::ArrayLiteral, modifier::Function)
    ArrayLiteral(node.token, map(expression -> modify(expression, modifier), node.elements))
end

function modify(node::HashLiteral, modifier::Function)
    HashLiteral(node.token,
        Dict(modify(key, modifier) => modify(value, modifier)
        for
        (key, value) in collect(node.pairs)))
end

function modify(node::FunctionLiteral, modifier::Function)
    FunctionLiteral(node.token,
        node.parameters,
        modify(node.body, modifier);
        name = node.name)
end

# !!! Do not add the function below.
# !!! We should not call recursively on `CallExpression`s since we need to actually modify them (the `unquote()` calls).
# modify(node::CallExpression, modifier::Function) =
#   CallExpression(node.token, modify(node.function, modifier), map(expression -> modify(expression, modifier), node.arguments))
