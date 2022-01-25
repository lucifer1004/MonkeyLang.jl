@testset "Test VM" begin
  for (input, expected) in [
    ("1", 1),
    ("2", 2),
    ("1 + 2", 3),
    ("1 - 2", -1),
    ("1 * 2", 2),
    ("1 / 2", 0),
    ("1 == 2", false),
    ("1 != 2", true),
    ("1 < 2", true),
    ("1 > 2", false),
  ]
    @test begin
      program = m.parse(input)
      c = m.Compiler()
      m.compile!(c, program)
      vm = m.VM(m.bytecode(c))
      m.run!(vm)

      test_object(m.stack_top(vm), expected)
    end
  end
end