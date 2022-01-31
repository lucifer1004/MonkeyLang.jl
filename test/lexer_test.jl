@testset "Test Lexer" begin
    @testset "Test basic functions" begin
        l = m.Lexer("1 + 1")

        @test m.read_char(l) == '1'
        @test m.peek_char(l) == ' '
        @test m.read_char!(l) == '1'
        @test m.read_char!(l) == ' '
        @test m.read_char!(l) == '+'
        @test m.read_char!(l) == ' '
        @test m.read_char!(l) == '1'
        @test isnothing(m.peek_char(l))
    end

    @testset "Test Next Token" begin
        @testset "Simple Test" begin
            expected = map(
                x -> m.Token(x...),
                [
                    (m.ASSIGN, "="),
                    (m.PLUS, "+"),
                    (m.LPAREN, "("),
                    (m.RPAREN, ")"),
                    (m.LBRACE, "{"),
                    (m.RBRACE, "}"),
                    (m.COMMA, ","),
                    (m.SEMICOLON, ";"),
                    (m.ILLEGAL, "~"),
                    (m.EOF, ""),
                ],
            )

            l = m.Lexer("=+(){},;~")

            for token in expected
                @test begin
                    test_token(m.next_token!(l), token)

                    true
                end
            end
        end

        @testset "Advanced Test" begin
            expected = map(
                x -> m.Token(x...),
                [
                    (m.LET, "let"),
                    (m.IDENT, "five"),
                    (m.ASSIGN, "="),
                    (m.INT, "5"),
                    (m.SEMICOLON, ";"),
                    (m.LET, "let"),
                    (m.IDENT, "ten"),
                    (m.ASSIGN, "="),
                    (m.INT, "10"),
                    (m.SEMICOLON, ";"),
                    (m.LET, "let"),
                    (m.IDENT, "add"),
                    (m.ASSIGN, "="),
                    (m.FUNCTION, "fn"),
                    (m.LPAREN, "("),
                    (m.IDENT, "x"),
                    (m.COMMA, ","),
                    (m.IDENT, "y"),
                    (m.RPAREN, ")"),
                    (m.LBRACE, "{"),
                    (m.IDENT, "x"),
                    (m.PLUS, "+"),
                    (m.IDENT, "y"),
                    (m.SEMICOLON, ";"),
                    (m.RBRACE, "}"),
                    (m.SEMICOLON, ";"),
                    (m.LET, "let"),
                    (m.IDENT, "result"),
                    (m.ASSIGN, "="),
                    (m.IDENT, "add"),
                    (m.LPAREN, "("),
                    (m.IDENT, "five"),
                    (m.COMMA, ","),
                    (m.IDENT, "ten"),
                    (m.RPAREN, ")"),
                    (m.SEMICOLON, ";"),
                    (m.BANG, "!"),
                    (m.MINUS, "-"),
                    (m.SLASH, "/"),
                    (m.ASTERISK, "*"),
                    (m.INT, "5"),
                    (m.SEMICOLON, ";"),
                    (m.INT, "5"),
                    (m.LT, "<"),
                    (m.INT, "10"),
                    (m.GT, ">"),
                    (m.INT, "5"),
                    (m.SEMICOLON, ";"),
                    (m.IF, "if"),
                    (m.LPAREN, "("),
                    (m.INT, "5"),
                    (m.LT, "<"),
                    (m.INT, "10"),
                    (m.RPAREN, ")"),
                    (m.LBRACE, "{"),
                    (m.RETURN, "return"),
                    (m.TRUE, "true"),
                    (m.SEMICOLON, ";"),
                    (m.RBRACE, "}"),
                    (m.ELSE, "else"),
                    (m.LBRACE, "{"),
                    (m.RETURN, "return"),
                    (m.FALSE, "false"),
                    (m.SEMICOLON, ";"),
                    (m.RBRACE, "}"),
                    (m.INT, "10"),
                    (m.EQ, "=="),
                    (m.INT, "10"),
                    (m.SEMICOLON, ";"),
                    (m.INT, "10"),
                    (m.NOT_EQ, "!="),
                    (m.INT, "9"),
                    (m.SEMICOLON, ";"),
                    (m.STRING, "foobar"),
                    (m.STRING, "foo bar"),
                    (m.LBRACKET, "["),
                    (m.INT, "1"),
                    (m.COMMA, ","),
                    (m.INT, "2"),
                    (m.RBRACKET, "]"),
                    (m.SEMICOLON, ";"),
                    (m.LBRACE, "{"),
                    (m.STRING, "foo"),
                    (m.COLON, ":"),
                    (m.STRING, "bar"),
                    (m.RBRACE, "}"),
                    (m.SEMICOLON, ";"),
                    (m.NULL, "null"),
                    (m.SEMICOLON, ";"),
                    (m.MACRO, "macro"),
                    (m.LPAREN, "("),
                    (m.IDENT, "x"),
                    (m.COMMA, ","),
                    (m.IDENT, "y"),
                    (m.RPAREN, ")"),
                    (m.LBRACE, "{"),
                    (m.IDENT, "x"),
                    (m.PLUS, "+"),
                    (m.IDENT, "y"),
                    (m.SEMICOLON, ";"),
                    (m.RBRACE, "}"),
                    (m.SEMICOLON, ";"),
                    (m.WHILE, "while"),
                    (m.LPAREN, "("),
                    (m.TRUE, "true"),
                    (m.RPAREN, ")"),
                    (m.LBRACE, "{"),
                    (m.IDENT, "puts"),
                    (m.LPAREN, "("),
                    (m.INT, "3"),
                    (m.RPAREN, ")"),
                    (m.SEMICOLON, ";"),
                    (m.RBRACE, "}"),
                    (m.SEMICOLON, ";"),
                    (m.EOF, ""),
                ],
            )

            l = m.Lexer("""
            let five = 5;
            let ten = 10;

            let add = fn(x, y) {
            x + y;
            };

            let result = add(five, ten);
            !-/*5;
            5 < 10 > 5;

            if (5 < 10) {
            return true;
            } else {
            return false;
            }

            10 == 10;
            10 != 9;
            "foobar"
            "foo bar"
            [1, 2];
            {"foo": "bar"};
            null;
            macro(x, y) { x + y; };

            while (true) { puts(3); };
            """)

            for token in expected
                test_token(m.next_token!(l), token)
            end
        end
    end
end
