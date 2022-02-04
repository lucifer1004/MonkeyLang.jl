@testset "Test analyzer" begin
    @testset "Semantic analysis" begin
        for (code, expected) in [
            ("foobar", "identifier not found: foobar"),
            ("x = 2;", "identifier not found: x"),
            ("let a = 2; let a = 4;", "a is already defined"),
            ("break;", "syntax error: break outside loop"),
            ("continue;", "syntax error: continue outside loop"),
            ("fn () { break; } ", "syntax error: break outside loop"),
            ("fn () { continue; } ", "syntax error: continue outside loop"),
            ("while (x == 2) {}", "identifier not found: x"),
            ("while (true) { x = 2; }", "identifier not found: x"),
            ("if (x == 2) {}", "identifier not found: x"),
            ("if (true) { x }", "identifier not found: x"),
            ("if (true) { 2 } else { x }", "identifier not found: x"),
            ("-x", "identifier not found: x"),
            ("x + 2", "identifier not found: x"),
            ("x(3)", "identifier not found: x"),
            ("x[3]", "identifier not found: x"),
            ("[1, 2][x]", "identifier not found: x"),
            ("len(x)", "identifier not found: x"),
            ("[x]", "identifier not found: x"),
            ("{x: 2}", "identifier not found: x"),
            ("{2: x}", "identifier not found: x"),
            (
                "let f = fn(x) { if (x > 0) { f(x - 1); f = 2; } }",
                "cannot reassign the current function being defined: f",
            ),
        ]
            test_object(m.analyze(code), expected)
        end
    end
end
