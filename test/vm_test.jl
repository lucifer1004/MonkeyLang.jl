function test_vm(input::String, expected)
  program = m.parse(input)
  c = m.Compiler()
  m.compile!(c, program)
  vm = m.VM(m.bytecode(c))
  m.run!(vm)

  test_object(m.last_popped(vm), expected)
end

@testset "Test VM" begin
  @testset "Integer Arithmetic" begin
    for (input, expected) in [
      ("1", 1),
      ("2", 2),
      ("1 + 2", 3),
      ("1 - 2", -1),
      ("1 * 2", 2),
      ("1 / 2", 0),
      ("50 / 2 * 2 + 10 - 5", 55),
      ("5 + 5 + 5 + 5 - 10", 10),
      ("2 * 2 * 2 * 2 * 2", 32),
      ("5 * 2 + 10", 20),
      ("5 + 2 * 10", 25),
      ("5 * (2 + 10)", 60),
      ("-5", -5),
      ("-10", -10),
      ("-50 + 100 + -50", 0),
      ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
    ]
      @test begin
        test_vm(input, expected)
      end
    end
  end

  @testset "Boolean Expressions" begin
    for (input, expected) in [
      ("true", true),
      ("false", false),
      ("1 < 2", true),
      ("1 > 2", false),
      ("1 < 1", false),
      ("1 > 1", false),
      ("1 == 1", true),
      ("1 != 1", false),
      ("1 == 2", false),
      ("1 != 2", true),
      ("true == true", true),
      ("false == false", true),
      ("true == false", false),
      ("true != false", true),
      ("false != true", true),
      ("(1 < 2) == true", true),
      ("(1 < 2) == false", false),
      ("(1 > 2) == true", false),
      ("(1 > 2) == false", true),
      ("!true", false),
      ("!false", true),
      ("!5", false),
      ("!!true", true),
      ("!!false", false),
      ("!!5", true),
    ]
      @test begin
        test_vm(input, expected)
      end
    end
  end
end
