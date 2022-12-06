@testset "Test OpCode" begin
    @testset "Test Make" begin for (op, operands, expected) in [
        (m.OpConstant, [65534], [UInt8(m.OpConstant), 255, 254]),
        (m.OpAdd, [], [UInt8(m.OpAdd)]),
        (m.OpSub, [], [UInt8(m.OpSub)]),
        (m.OpMul, [], [UInt8(m.OpMul)]),
        (m.OpDiv, [], [UInt8(m.OpDiv)]),
        (m.OpEqual, [], [UInt8(m.OpEqual)]),
        (m.OpNotEqual, [], [UInt8(m.OpNotEqual)]),
        (m.OpLessThan, [], [UInt8(m.OpLessThan)]),
        (m.OpGreaterThan, [], [UInt8(m.OpGreaterThan)]),
        (m.OpGetLocal, [255], [UInt8(m.OpGetLocal), 255]),
        (m.OpGetFree, [1], [UInt8(m.OpGetFree), 1]),
        (m.OpGetOuter, [1, 2, 3], [UInt8(m.OpGetOuter), 1, 2, 3]),
        (m.OpClosure, [65534, 255], [UInt8(m.OpClosure), 255, 254, 255]),
        (m.OpIllegal, [], []),
    ]
        @test begin
            instruction = m.make(op, operands...)

            @assert length(instruction)==length(expected) "Instruction has wrong length. Expected $(length(expected)), got $(length(instruction)) instead."

            for (i, e) in enumerate(expected)
                @assert instruction[i]==e "Instruction has wrong value at index $(i). Expected $(e), got $(instruction[i]) instead."
            end

            true
        end
    end end

    @testset "Test Stringifying Instructions" begin for (instructions, expected) in [
        ([
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
         ],
         "0000 OpConstant 1\n0003 OpConstant 2\n0006 OpConstant 65535\n"),
        ([m.make(m.OpAdd), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
         "0000 OpAdd\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([m.make(m.OpSub), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
         "0000 OpSub\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([m.make(m.OpMul), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
         "0000 OpMul\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([m.make(m.OpDiv), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
         "0000 OpDiv\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([m.make(m.OpEqual), m.make(m.OpConstant, 2), m.make(m.OpConstant, 65535)],
         "0000 OpEqual\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([
             m.make(m.OpNotEqual),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
         ],
         "0000 OpNotEqual\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([
             m.make(m.OpLessThan),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
         ],
         "0000 OpLessThan\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([
             m.make(m.OpGreaterThan),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
         ],
         "0000 OpGreaterThan\n0001 OpConstant 2\n0004 OpConstant 65535\n"),
        ([
             m.make(m.OpAdd),
             m.make(m.OpGetLocal, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
         ],
         "0000 OpAdd\n0001 OpGetLocal 1\n0003 OpConstant 2\n0006 OpConstant 65535\n"),
        ([
             m.make(m.OpAdd),
             m.make(m.OpGetLocal, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 65535),
             m.make(m.OpClosure, 65535, 255),
         ],
         "0000 OpAdd\n0001 OpGetLocal 1\n0003 OpConstant 2\n0006 OpConstant 65535\n0009 OpClosure 65535 255\n"),
        ([m.Instructions([UInt8(m.OpIllegal)])], "ERROR: unknown opcode: 36\n"),
    ]
        @test string(vcat(instructions...)) == expected
    end end

    @testset "Test Reading Operands" begin for (op, operands, bytes_read) in [
        (m.OpConstant, [65535], 2),
        (m.OpGetLocal, [255], 1),
        (m.OpClosure, [65535, 255], 3),
    ]
        @test begin
            instruction = m.make(op, operands...)
            def = m.lookup(Integer(op))

            @assert !isnothing(def) "Definition for $op not found."

            operands_read, n = m.read_operands(def, instruction[2:end])
            @assert n==bytes_read "Wrong number of bytes read. Expected $bytes_read, got $n instead."
            for (i, want) in enumerate(operands)
                @assert want==operands_read[i] "Wrong operand at index $i. Expected $(want), got $(operands_read[i]) instead."
            end

            true
        end
    end end
end
