@enum OpCode::UInt8 OpConstant OpAdd OpSub OpMul OpDiv OpEqual OpNotEqual OpLessThan OpGreaterThan OpMinus OpBang OpPop OpTrue OpFalse

struct Instructions
  codes::Vector{UInt8}
end

Base.length(ins::Instructions) = length(ins.codes)
Base.getindex(ins::Instructions, i::Int) = ins.codes[i]
Base.getindex(ins::Instructions, r::UnitRange{Int}) = Instructions(@view ins.codes[r])
Base.lastindex(ins::Instructions) = lastindex(ins.codes)
Base.iterate(ins::Instructions) = iterate(ins.codes)
Base.iterate(ins::Instructions, i::Int) = iterate(ins.codes, i)
Base.vcat(is::Vararg{Instructions}) = Instructions(vcat(map(x -> x.codes, is)...))
Base.append!(ins::Instructions, other::Instructions) = append!(ins.codes, other.codes)
Base.string(ins::Instructions) = begin
  out = IOBuffer()
  i = 1
  while i <= length(ins)
    def = lookup(ins[i])
    if isnothing(def)
      write(out, "ERROR: unknown opcode: $(ins[i])\n")
      continue
    end

    operands, n = read_operands(def, ins[i+1:end])
    write(out, @sprintf("%04d %s\n", i - 1, format_instruction(def, operands)))
    i += n + 1
  end

  return String(take!(out))
end

struct Definition
  name::String
  operand_widths::Vector{Int}
end

const DEFINITIONS = Dict{OpCode,Definition}(
  OpConstant => Definition("OpConstant", [2]),
  OpAdd => Definition("OpAdd", []),
  OpSub => Definition("OpSub", []),
  OpMul => Definition("OpMul", []),
  OpDiv => Definition("OpDiv", []),
  OpEqual => Definition("OpEqual", []),
  OpNotEqual => Definition("OpNotEqual", []),
  OpLessThan => Definition("OpLessThan", []),
  OpGreaterThan => Definition("OpGreaterThan", []),
  OpMinus => Definition("OpMinus", []),
  OpBang => Definition("OpBang", []),
  OpPop => Definition("OpPop", []),
  OpTrue => Definition("OpTrue", []),
  OpFalse => Definition("OpFalse", []),
)

lookup(op::UInt8) = Base.get(DEFINITIONS, OpCode(op), nothing)

function format_instruction(def::Definition, operands::Vector{Int})
  operand_count = length(operands)

  if operand_count != length(def.operand_widths)
    return "ERROR: operand length mismatch. Expected $(length(def.operand_widths)), got $operand_count instead.\n"
  end

  if operand_count == 0
    return def.name
  elseif operand_count == 1
    return "$(def.name) $(operands[1])"
  end

  return "ERROR: unhandled operand_count $operand_count for $(def.name).\n"
end

function make(op::OpCode, operands::Vararg{Int})::Instructions
  if op ∉ keys(DEFINITIONS)
    return UInt8[]
  end

  def = DEFINITIONS[op]
  codes = UInt8[Integer(op)]

  for (operand, width) in zip(operands, def.operand_widths)
    if width == 2
      append!(codes, reinterpret(UInt8, [hton(UInt16(operand))]))
    else
    end
  end

  return Instructions(codes)
end

function read_operands(def::Definition, ins::Instructions)::Tuple{Vector{Int},Int}
  operands = Int[]
  offset = 0
  for width in def.operand_widths
    if width == 2
      push!(operands, read_uint16(ins[offset+1:offset+2]))
    end
    offset += width
  end
  return operands, offset
end

function read_uint16(ins::Instructions)::UInt16
  return hton(reinterpret(UInt16, ins.codes)[1])
end