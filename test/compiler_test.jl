function test_instructions(actual, expected)
  concatted = vcat(expected...)

  @assert length(concatted) == length(actual) "Wrong instructions length. Expected $concatted), got $actual instead."

  for i = 1:length(concatted)
    @assert concatted[i] == actual[i] "Wrong instruction at index $(i). Expected $(concatted[i]), got $(actual[i]) instead. Expected $concatted, got $actual instead."
  end

  true
end

function test_constants(actual, expected)
  @assert length(expected) == length(actual) "Wrong constants length. Expected $(length(expected)), got $(length(actual)) instead."

  for (ca, ce) in zip(actual, expected)
    test_object(ca, ce)
  end

  true
end

function run_compiler_tests(input::String, expected_constants::Vector, expected_instructions::Vector{m.Instructions})
  program = m.parse(input)
  c = m.Compiler()
  m.compile!(c, program)

  bc = m.bytecode(c)

  test_instructions(bc.instructions, expected_instructions)
  test_constants(bc.constants, expected_constants)

  true
end

@testset "Test Compiler" begin
  @testset "Integer Arithmetic" begin
    for (input, expected_constants, expected_instructions) in [
      (
        "1; 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpPop),
          m.make(m.OpConstant, 1),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 + 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpAdd),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 - 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpSub),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 * 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpMul),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 / 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpDiv),
          m.make(m.OpPop),
        ],
      ),
      (
        "-1",
        [1],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpMinus),
          m.make(m.OpPop),
        ],
      ),
    ]
      @test run_compiler_tests(input, expected_constants, expected_instructions)
    end
  end

  @testset "Boolean Expressions" begin
    for (input, expected_constants, expected_instructions) in [
      (
        "true",
        [],
        [
          m.make(m.OpTrue),
          m.make(m.OpPop),
        ],
      ),
      (
        "false",
        [],
        [
          m.make(m.OpFalse),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 == 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpEqual),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 != 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpNotEqual),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 < 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpLessThan),
          m.make(m.OpPop),
        ],
      ),
      (
        "1 > 2",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpGreaterThan),
          m.make(m.OpPop),
        ],
      ),
      (
        "true == false",
        [],
        [
          m.make(m.OpTrue),
          m.make(m.OpFalse),
          m.make(m.OpEqual),
          m.make(m.OpPop),
        ],
      ),
      (
        "true != false",
        [],
        [
          m.make(m.OpTrue),
          m.make(m.OpFalse),
          m.make(m.OpNotEqual),
          m.make(m.OpPop),
        ],
      ),
      (
        "!true",
        [],
        [
          m.make(m.OpTrue),
          m.make(m.OpBang),
          m.make(m.OpPop),
        ],
      ),
    ]
      @test run_compiler_tests(input, expected_constants, expected_instructions)
    end
  end

  @testset "Conditionals" begin
    for (input, expected_constants, expected_instructions) in [
      (
        "if (true) { 10 }; 3333",
        [10, 3333],
        [
          m.make(m.OpTrue),
          m.make(m.OpJumpNotTruthy, 10),
          m.make(m.OpConstant, 0),
          m.make(m.OpJump, 11),
          m.make(m.OpNull),
          m.make(m.OpPop),
          m.make(m.OpConstant, 1),
          m.make(m.OpPop),
        ],
      ),
      (
        "if (true) { 10 } else { 20 }; 3333",
        [10, 20, 3333],
        [
          m.make(m.OpTrue),
          m.make(m.OpJumpNotTruthy, 10),
          m.make(m.OpConstant, 0),
          m.make(m.OpJump, 13),
          m.make(m.OpConstant, 1),
          m.make(m.OpPop),
          m.make(m.OpConstant, 2),
          m.make(m.OpPop),
        ],
      ),
    ]
      @test run_compiler_tests(input, expected_constants, expected_instructions)
    end
  end

  @testset "Global Let Statements" begin
    for (input, expected_constants, expected_instructions) in [
      (
        "let one = 1;\nlet two = 2;\n",
        [1, 2],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpSetGlobal, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpSetGlobal, 1),
        ],
      ),
      (
        "let one = 1;\none;\n",
        [1],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpSetGlobal, 0),
          m.make(m.OpGetGlobal, 0),
          m.make(m.OpPop),
        ],
      ),
      (
        "let one = 1;\nlet two = one;\ntwo;\n",
        [1],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpSetGlobal, 0),
          m.make(m.OpGetGlobal, 0),
          m.make(m.OpSetGlobal, 1),
          m.make(m.OpGetGlobal, 1),
          m.make(m.OpPop),
        ],
      ),
    ]
      @test run_compiler_tests(input, expected_constants, expected_instructions)
    end
  end

  @testset "String Expressions" begin
    for (input, expected_constants, expected_instructions) in [
      (
        "\"monkey\"",
        ["monkey"],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpPop),
        ],
      ),
      (
        "\"mon\" + \"key\"",
        ["mon", "key"],
        [
          m.make(m.OpConstant, 0),
          m.make(m.OpConstant, 1),
          m.make(m.OpAdd),
          m.make(m.OpPop),
        ],
      ),
    ]
      @test run_compiler_tests(input, expected_constants, expected_instructions)
    end
  end
end
