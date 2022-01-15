evaluate(::Node, ::Environment) = _NULL

evaluate(node::ExpressionStatement, env::Environment) = evaluate(node.expression, env)
evaluate(node::IntegerLiteral, ::Environment) = IntegerObj(node.value)
evaluate(node::BooleanLiteral, ::Environment) = node.value ? _TRUE : _FALSE
evaluate(node::StringLiteral, ::Environment) = StringObj(node.value)
evaluate(node::FunctionLiteral, env::Environment) = FunctionObj(node.parameters, node.body, env)

evaluate(node::ArrayLiteral, env::Environment) = begin
  elements = evaluate_expressions(node.elements, env)
  if length(elements) == 1 && isa(elements[1], Error)
    return elements[1]
  end
  return ArrayObj(elements)
end

evaluate(node::Identifier, env::Environment) = begin
  val = get(env, node.value)

  if !isnothing(val)
    return val
  end

  builtin = Base.get(BUILTINS, node.value, nothing)

  if !isnothing(builtin)
    return builtin
  end

  return Error("identifier not found: $(node.value)")
end

evaluate(node::PrefixExpression, env::Environment) = begin
  right = evaluate(node.right, env)
  return isa(right, Error) ? right : evaluate_prefix_expression(node.operator, right)
end

evaluate(node::InfixExpression, env::Environment) = begin
  left = evaluate(node.left, env)
  if isa(left, Error)
    return left
  end
  right = evaluate(node.right, env)
  return isa(right, Error) ? right : evaluate_infix_expression(node.operator, left, right)
end

evaluate(node::IfExpression, env::Environment) = begin
  condition = evaluate(node.condition, env)

  if isa(condition, Error)
    return condition
  elseif is_truthy(condition)
    return evaluate(node.consequence, env)
  elseif !isnothing(node.alternative)
    return evaluate(node.alternative, env)
  else
    return _NULL
  end
end

evaluate(node::CallExpression, env::Environment) = begin
  fn = evaluate(node.fn, env)
  if isa(fn, Error)
    return fn
  end

  args = evaluate_expressions(node.arguments, env)
  if length(args) == 1 && isa(args[1], Error)
    return args[1]
  end

  return apply_function(fn, args)
end

evaluate(node::IndexExpression, env::Environment) = begin
  left = evaluate(node.left, env)
  if isa(left, Error)
    return left
  end

  index = evaluate(node.index, env)
  if isa(index, Error)
    return index
  end

  return evaluate_index_expression(left, index)
end

evaluate(node::LetStatement, env::Environment) = begin
  val = evaluate(node.value, env)
  if isa(val, Error)
    return val
  end
  set!(env, node.name.value, val)
  return val
end

evaluate(node::ReturnStatement, env::Environment) = begin
  val = evaluate(node.return_value, env)
  return isa(val, Error) ? val : ReturnValue(val)
end

evaluate(block::BlockStatement, env::Environment) = begin
  result = _NULL

  for statement in block.statements
    result = evaluate(statement, env)
    if isa(result, ReturnValue) || isa(result, Error)
      return result
    end
  end

  return result
end

evaluate(program::Program, env::Environment) = begin
  result = _NULL

  for statement in program.statements
    result = evaluate(statement, env)
    if isa(result, ReturnValue)
      return result.value
    elseif isa(result, Error)
      return result
    end
  end

  return result
end

function evaluate_prefix_expression(operator::String, right::Object)
  if operator == "!"
    return evaluate_bang_operator_expression(right)
  elseif operator == "-"
    return evaluate_minus_prefix_operator_expression(right)
  else
    return Error("unknown operator: " * operator * type_of(right))
  end
end

function evaluate_infix_expression(operator::String, left::Object, right::Object)
  if type_of(left) != type_of(right)
    return Error("type mismatch: " * type_of(left) * " " * operator * " " * type_of(right))
  end

  if operator == "=="
    return left === right ? _TRUE : _FALSE
  elseif operator == "!="
    return left !== right ? _TRUE : _FALSE
  else
    return Error("unknown operator: " * type_of(left) * " " * operator * " " * type_of(right))
  end
end

function evaluate_infix_expression(operator::String, left::StringObj, right::StringObj)
  if operator == "+"
    return StringObj(left.value * right.value)
  else
    return Error("unknown operator: " * type_of(left) * " " * operator * " " * type_of(right))
  end
end

function evaluate_infix_expression(operator::String, left::IntegerObj, right::IntegerObj)
  if operator == "+"
    return IntegerObj(left.value + right.value)
  elseif operator == "-"
    return IntegerObj(left.value - right.value)
  elseif operator == "*"
    return IntegerObj(left.value * right.value)
  elseif operator == "/"
    return IntegerObj(left.value ÷ right.value)
  elseif operator == "<"
    return left.value < right.value ? _TRUE : _FALSE
  elseif operator == ">"
    return left.value > right.value ? _TRUE : _FALSE
  elseif operator == "=="
    return left.value == right.value ? _TRUE : _FALSE
  elseif operator == "!="
    return left.value != right.value ? _TRUE : _FALSE
  else
    return Error("unknown operator: " * type_of(left) * " " * operator * type_of(right))
  end
end

function evaluate_bang_operator_expression(right::Object)
  if right === _FALSE || right === _NULL
    return _TRUE
  else
    return _FALSE
  end
end

evaluate_minus_prefix_operator_expression(right::Object) = Error("unknown operator: -" * type_of(right))
evaluate_minus_prefix_operator_expression(right::IntegerObj) = IntegerObj(-right.value)

evaluate_index_expression(left::Object, ::Object) = Error("index operator not supported: $(type_of(left))")
evaluate_index_expression(::ArrayObj, index::Object) = Error("unsupported index type: $(type_of(index))")
evaluate_index_expression(left::ArrayObj, index::IntegerObj) = begin
  idx = index.value
  max_idx = length(left.elements) - 1
  return 0 <= idx <= max_idx ? left.elements[idx+1] : _NULL
end

function evaluate_expressions(expressions::Vector{Expression}, env::Environment)
  results = Object[]

  for expression in expressions
    evaluated = evaluate(expression, env)
    if isa(evaluated, Error)
      return [evaluated]
    end
    push!(results, evaluated)
  end

  return results
end

function apply_function(fn::FunctionObj, args::Vector{Object})
  extended_env = extend_function_environment(fn, args)
  evaluated = evaluate(fn.body, extended_env)
  return unwrap_return_value(evaluated)
end

apply_function(fn::Object, ::Vector{Object}) = Error("not a function: " * type_of(fn))
apply_function(fn::Builtin, args::Vector{Object}) = fn.fn(args...)

function extend_function_environment(fn::FunctionObj, args::Vector{Object})
  env = Environment(fn.env)

  for (param, arg) in zip(fn.parameters, args)
    set!(env, param.value, arg)
  end

  return env
end

function unwrap_return_value(obj::Object)
  if isa(obj, ReturnValue)
    return obj.value
  else
    return obj
  end
end
