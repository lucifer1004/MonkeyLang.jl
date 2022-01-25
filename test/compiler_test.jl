function test_instructions(actual, expected)
  concatted = vcat(expected...)

  @assert length(concatted) == length(actual) "Wrong instructions length. Expected $(length(concatted)), got $(length(actual)) instead."

  for i = 1:length(concatted)
    @assert concatted[i] == actual[i] "Wrong instruction at index $(i). Expected $(concatted[i]), got $(actual[i]) instead."
  end

  true
end

function test_constants(actual, expected)
  @assert length(expected) == length(actual) "Wrong constants length. Expected $(length(expected)), got $(length(actual)) instead."

  for (ca, ce) in zip(actual, expected)
    if isa(ce, Int)
      test_integer_object(ca, ce)
    end
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
end
