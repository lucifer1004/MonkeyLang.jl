@testset "Julia Transpiler" begin
    t = m.Transpilers.JuliaTranspiler

    @testset "General" begin
        # General tests for all backends
        test_backend(t.run, "julia"; check_object = false)
    end

    @testset "String macro" begin
        for (code, expected, expected_output) in [
            ("let b = 4; b;", 4, ""),
            ("puts([1, 2, 3]);", nothing, "[1, 2, 3]\n"),
            ("let m = macro(x, y) { quote(unquote(y) - unquote(x)) }; m(5, 10);", 5, ""),
        ]
            c = IOCapture.capture() do
                eval(quote
                    $t.@monkey_julia_str($code)
                end)
            end

            @test c.value == expected
            @test c.output == expected_output
        end
    end
end
