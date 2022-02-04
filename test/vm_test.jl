@testset "Test VM" begin
    @testset "General" begin
        # General tests for all backends
        test_backend(m.run, "vm")
    end

    @testset "Stack underflow" begin
        vm = m.VM(m.ByteCode(m.Instructions([]), []))
        @test_throws ErrorException("stack underflow") m.pop!(vm)
    end

    @testset "String macro" begin
        for (code, expected, expected_output) in [
            ("let b = 4; b;", 4, ""),
            ("puts([1, 2, 3]);", nothing, "[1, 2, 3]\n"),
            ("let m = macro(x, y) { quote(unquote(y) - unquote(x)) }; m(5, 10);", 5, ""),
        ]
            c = IOCapture.capture() do
                eval(quote
                    m.@monkey_vm_str($code)
                end)
            end

            test_object(c.value, expected)
            @test c.output == expected_output
        end
    end
end
