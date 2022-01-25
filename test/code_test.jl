@testset "Test Make" begin
  for (op, operands, expected) in [
    (m.OpConstant, [65534], [UInt8(m.OpConstant), 255, 254]),
    (m.OpAdd, [], [UInt8(m.OpAdd)]),
    (m.OpSub, [], [UInt8(m.OpSub)]),
    (m.OpMul, [], [UInt8(m.OpMul)]),
    (m.OpDiv, [], [UInt8(m.OpDiv)]),
    (m.OpEqual, [], [UInt8(m.OpEqual)]),
    (m.OpNotEqual, [], [UInt8(m.OpNotEqual)]),
    (m.OpLT, [], [UInt8(m.OpLT)]),
    (m.OpGT, [], [UInt8(m.OpGT)]),
  ]
    @test begin
      instruction = m.make(op, operands...)

      @assert length(instruction) == length(expected) "Instruction has wrong length. Expected $(length(expected)), got $(length(instruction)) instead."

      for (i, e) in enumerate(expected)
        @assert instruction[i] == e "Instruction has wrong value at index $(i). Expected $(e), got $(instruction[i]) instead."
      end

      true
    end
  end
end

@testset "Test Stringifying Instructions" begin
  for (instructions, expected) in [
    (
      [m.make(m.OpConstant, 1), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpConstant 1\n0003 OpConstant 2\n0006 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpAdd), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpAdd\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpSub), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpSub\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpMul), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpMul\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpDiv), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpDiv\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpEqual), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpEqual\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpNotEqual), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpNotEqual\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpLT), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpLT\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
    (
      [m.make(m.OpGT), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
      "0000 OpGT\n0001 OpConstant 2\n0004 OpConstant 65535\n",
    ),
  ]
    @test begin
      concatted = vcat(instructions...)

      @assert string(concatted) == expected "Instructions wrongly formatted. Expected $(expected), got $(string(concatted)) instead."

      true
    end
  end
end

@testset "Test Reading Operands" begin
  for (op, operands, bytes_read) in [
    (m.OpConstant, [65535], 2),
  ]
    @test begin
      instruction = m.make(op, operands...)
      def = m.lookup(Integer(op))

      @assert !isnothing(def) "Definition for $op not found."

      operands_read, n = m.read_operands(def, instruction[2:end])
      @assert n == bytes_read "Wrong number of bytes read. Expected $bytes_read, got $n instead."
      for (i, want) in enumerate(operands)
        @assert want == operands_read[i] "Wrong operand at index $i. Expected $(want), got $(operands_read[i]) instead."
      end

      true
    end
  end
end
