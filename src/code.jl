@enum OpCode::UInt8 OpConstant OpAdd OpSub OpMul OpDiv OpEqual OpNotEqual OpLessThan OpGreaterThan OpMinus OpBang OpTrue OpFalse OpNull OpPop OpJump OpJumpNotTruthy OpGetGlobal OpSetGlobal OpGetLocal OpSetLocal OpGetBuiltin OpGetFree OpSetFree OpGetOuter OpSetOuter OpCurrentClosure OpArray OpHash OpClosure OpIndex OpCall OpBreak OpContinue OpReturnValue OpReturn OpIllegal

struct Instructions
    codes::Vector{UInt8}
end

Base.length(ins::Instructions) = length(ins.codes)
Base.getindex(ins::Instructions, i::Int) = ins.codes[i]
Base.getindex(ins::Instructions, r::UnitRange{Int}) = Instructions(ins.codes[r])
Base.setindex!(ins::Instructions, val::UInt8, i::Int) = ins.codes[i] = val
Base.lastindex(ins::Instructions) = lastindex(ins.codes)
Base.vcat(is::Vararg{Instructions}) = Instructions(vcat(map(x -> x.codes, is)...))
Base.append!(ins::Instructions, other::Instructions) = append!(ins.codes, other.codes)
Base.splice!(ins::Instructions, r::UnitRange{Int}) = splice!(ins.codes, r)
Base.string(ins::Instructions) = begin
    out = IOBuffer()
    i = 1
    while i <= length(ins)
        def = lookup(ins[i])
        if isnothing(def)
            write(out, "ERROR: unknown opcode: $(ins[i])\n")
            i += 1
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

const OPCODE_STRINGS = Dict{OpCode,String}(
    OpAdd => "+",
    OpSub => "-",
    OpMul => "*",
    OpDiv => "/",
    OpEqual => "==",
    OpNotEqual => "!=",
    OpLessThan => "<",
    OpGreaterThan => ">",
    OpMinus => "-",
    OpBang => "!",
)

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
    OpTrue => Definition("OpTrue", []),
    OpFalse => Definition("OpFalse", []),
    OpNull => Definition("OpNull", []),
    OpPop => Definition("OpPop", []),
    OpJump => Definition("OpJump", [2]),
    OpJumpNotTruthy => Definition("OpJumpNotTruthy", [2]),
    OpGetGlobal => Definition("OpGetGlobal", [2]),
    OpSetGlobal => Definition("OpSetGlobal", [2]),
    OpGetLocal => Definition("OpGetLocal", [1]),
    OpSetLocal => Definition("OpSetLocal", [1]),
    OpGetBuiltin => Definition("OpGetBuiltin", [1]),
    OpGetFree => Definition("OpGetFree", [1]),
    OpSetFree => Definition("OpSetFree", [1]),
    OpGetOuter => Definition("OpGetOuter", [1, 1, 1]),
    OpSetOuter => Definition("OpSetOuter", [1, 1, 1]),
    OpCurrentClosure => Definition("OpCurrentClosure", []),
    OpArray => Definition("OpArray", [2]),
    OpHash => Definition("OpHash", [2]),
    OpClosure => Definition("OpClosure", [2, 1]),
    OpIndex => Definition("OpIndex", []),
    OpCall => Definition("OpCall", [1]),
    OpBreak => Definition("OpBreak", []),
    OpContinue => Definition("OpContinue", []),
    OpReturnValue => Definition("OpReturnValue", []),
    OpReturn => Definition("OpReturn", []),
)

lookup(op::UInt8) = Base.get(DEFINITIONS, OpCode(op), nothing)

function format_instruction(def::Definition, operands::Vector{Int})
    operand_count = length(operands)

    if operand_count != length(def.operand_widths)
        return "ERROR: operand length mismatch. Expected $(length(def.operand_widths)), got $operand_count instead.\n"
    end

    return def.name * join(map(x -> " " * string(x), operands))
end

function make(op::OpCode, operands::Vararg{Int})::Instructions
    if op ∉ keys(DEFINITIONS)
        return Instructions(UInt8[])
    end

    def = DEFINITIONS[op]
    codes = UInt8[Integer(op)]

    for (operand, width) in zip(operands, def.operand_widths)
        if width == 2
            push!(codes, UInt8(operand >> 8))
            push!(codes, UInt8(operand & 0xFF))
        elseif width == 1
            push!(codes, UInt8(operand))
        end
    end

    return Instructions(codes)
end

function read_operands(def::Definition, ins::Instructions)::Tuple{Vector{Int},Int}
    operands = Int[]
    offset = 0
    for width in def.operand_widths
        if width == 2
            push!(operands, read_uint16(ins, offset + 1))
        elseif width == 1
            push!(operands, ins[offset+1])
        end
        offset += width
    end
    return operands, offset
end

function read_uint16(ins::Instructions, pos::Int)::UInt16
    return UInt16(ins.codes[pos]) << 8 | ins.codes[pos+1]
end
