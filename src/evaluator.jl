const _NULL = Null()
const _TRUE = Boolean(true)
const _FALSE = Boolean(false)

is_truthy(obj::Object) = !(obj === _NULL || obj === _FALSE)

function evaluate(node::Node)
  if isa(node, Program)
    return evaluate_program(node)
  elseif isa(node, ExpressionStatement)
    return evaluate(node.expression)
  elseif isa(node, IntegerLiteral)
    return Integer(node.value)
  elseif isa(node, BooleanLiteral)
    return node.value ? _TRUE : _FALSE
  elseif isa(node, PrefixExpression)
    right = evaluate(node.right)
    return isa(right, Error) ? right : evaluate_prefix_expression(node.operator, right)
  elseif isa(node, InfixExpression)
    left = evaluate(node.left)
    if isa(left, Error)
      return left
    end
    right = evaluate(node.right)
    return isa(right, Error) ? right : evaluate_infix_expression(node.operator, left, right)
  elseif isa(node, IfExpression)
    return evaluate_if_expression(node)
  elseif isa(node, BlockStatement)
    return evaluate_block_statement(node)
  elseif isa(node, ReturnStatement)
    val = evaluate(node.return_value)
    return isa(val, Error) ? val : ReturnValue(val)
  else
    return _NULL
  end
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

function evaluate_if_expression(ie::IfExpression)
  condition = evaluate(ie.condition)

  if isa(condition, Error)
    return condition
  elseif is_truthy(condition)
    return evaluate(ie.consequence)
  elseif !isnothing(ie.alternative)
    return evaluate(ie.alternative)
  else
    return _NULL
  end
end

function evaluate_block_statement(block::BlockStatement)
  result = _NULL

  for statement in block.statements
    result = evaluate(statement)
    if isa(result, ReturnValue) || isa(result, Error)
      return result
    end
  end

  return result
end

function evaluate_program(program::Program)
  result = _NULL

  for statement in program.statements
    result = evaluate(statement)
    if isa(result, ReturnValue)
      return result.value
    elseif isa(result, Error)
      return result
    end
  end

  return result
end
