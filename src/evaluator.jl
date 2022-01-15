function evaluate(node::Node, env::Environment)
  if isa(node, Program)
    return evaluate_program(node, env)
  elseif isa(node, LetStatement)
    val = evaluate(node.value, env)
    if isa(val, Error)
      return val
    end
    set!(env, node.name.value, val)
    return val
  elseif isa(node, ExpressionStatement)
    return evaluate(node.expression, env)
  elseif isa(node, IntegerLiteral)
    return Integer(node.value)
  elseif isa(node, BooleanLiteral)
    return node.value ? _TRUE : _FALSE
  elseif isa(node, PrefixExpression)
    right = evaluate(node.right, env)
    return isa(right, Error) ? right : evaluate_prefix_expression(node.operator, right)
  elseif isa(node, InfixExpression)
    left = evaluate(node.left, env)
    if isa(left, Error)
      return left
    end
    right = evaluate(node.right, env)
    return isa(right, Error) ? right : evaluate_infix_expression(node.operator, left, right)
  elseif isa(node, IfExpression)
    return evaluate_if_expression(node, env)
  elseif isa(node, BlockStatement)
    return evaluate_block_statement(node, env)
  elseif isa(node, ReturnStatement)
    val = evaluate(node.return_value, env)
    return isa(val, Error) ? val : ReturnValue(val)
  elseif isa(node, Identifier)
    return evaluate_identifier(node, env)
  elseif isa(node, FunctionLiteral)
    return FunctionObj(node.parameters, node.body, env)
  elseif isa(node, CallExpression)
    fn = evaluate(node.fn, env)
    if isa(fn, Error)
      return fn
    end

    args = evaluate_expressions(node.arguments, env)
    if length(args) == 1 && isa(args[1], Error)
      return args[1]
    end

    return apply_function(fn, args)
  else
    return _NULL
  end
end

function evaluate_identifier(node::Identifier, env::Environment)
  val = get(env, node.value)
  if isnothing(val)
    return Error("identifier not found: $(node.value)")
  end

  return val
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

  if isa(left, Integer) && isa(right, Integer)
    return evaluate_integer_infix_expression(operator, left, right)
  elseif operator == "=="
    return left === right ? _TRUE : _FALSE
  elseif operator == "!="
    return left !== right ? _TRUE : _FALSE
  else
    return Error("unknown operator: " * type_of(left) * " " * operator * " " * type_of(right))
  end
end

function evaluate_integer_infix_expression(operator::String, left::Integer, right::Integer)
  if operator == "+"
    return Integer(left.value + right.value)
  elseif operator == "-"
    return Integer(left.value - right.value)
  elseif operator == "*"
    return Integer(left.value * right.value)
  elseif operator == "/"
    return Integer(left.value ÷ right.value)
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

function evaluate_minus_prefix_operator_expression(right::Object)
  if isa(right, Integer)
    return Integer(-right.value)
  else
    return return Error("unknown operator: -" * type_of(right))
  end
end

function evaluate_if_expression(ie::IfExpression, env::Environment)
  condition = evaluate(ie.condition, env)

  if isa(condition, Error)
    return condition
  elseif is_truthy(condition)
    return evaluate(ie.consequence, env)
  elseif !isnothing(ie.alternative)
    return evaluate(ie.alternative, env)
  else
    return _NULL
  end
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

function evaluate_block_statement(block::BlockStatement, env::Environment)
  result = _NULL

  for statement in block.statements
    result = evaluate(statement, env)
    if isa(result, ReturnValue) || isa(result, Error)
      return result
    end
  end

  return result
end

function evaluate_program(program::Program, env::Environment)
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
