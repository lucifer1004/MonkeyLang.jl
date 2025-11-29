@testset "Test AST" begin
    @testset "Test Token Literal" begin for (program, expected) in [
        (m.Program([]), ""),
        (m.Program([
                       m.LetStatement(T(m.LET, "let"),
                                      m.Identifier(T(m.IDENT, "myVar"), "myVar"),
                                      m.Identifier(T(m.IDENT, "anotherVar"),
                                                   "anotherVar"),
                                      false),
                   ]),
         "let"),
    ]
        @test m.token_literal(program) == expected
    end end

    @testset "Test Stringifying Program" begin
        program = m.Program([
                                m.LetStatement(T(m.LET, "let"),
                                               m.Identifier(T(m.IDENT, "myVar"),
                                                            "myVar"),
                                               m.Identifier(T(m.IDENT, "anotherVar"),
                                                            "anotherVar"),
                                               false),
                            ])

        @test string(program) == "let myVar = anotherVar;"
    end

    @testset "Test Stringifying a Complicated Program" begin
        input = """
            let a = 1;
            let b = a + 2;
            let f = if (true) {
            fn(x) {
                x + 1;
            }
            } else { 
            fn(x) { 
                return x * 2;
            }
            }
            let c = f(b);
            let d = [a, b, c];
            let e = {a:b};
            let g = macro(x) {x + x};
            while (true) {
                break;
            }
            while (false) {
                continue;
            }
        """

        expected = "let a = 1;let b = (a + 2);let f = if (true) { fn(x) { (x + 1) } } else { fn(x) { return (x * 2); } };let c = f(b);let d = [a, b, c];let e = {a:b};let g = macro(x) {(x + x)};while (true) { break; }while (false) { continue; }"
        l = m.Lexer(input)
        p = m.Parser(l)
        program = m.parse!(p)
        @test string(program) == expected
    end
end
