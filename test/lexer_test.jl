@testset "Test Lexer" begin
    @testset "Test token position" begin
        # Single line
        l = m.Lexer("let x = 5;")
        t = m.next_token!(l)  # let
        @test t.line == 1 && t.column == 1
        t = m.next_token!(l)  # x
        @test t.line == 1 && t.column == 5
        t = m.next_token!(l)  # =
        @test t.line == 1 && t.column == 7
        t = m.next_token!(l)  # 5
        @test t.line == 1 && t.column == 9
        t = m.next_token!(l)  # ;
        @test t.line == 1 && t.column == 10

        # Multi-line
        l = m.Lexer("let x = 1;\nlet y = 2;")
        for _ in 1:5
            m.next_token!(l)  # skip first line
        end
        t = m.next_token!(l)  # let on line 2
        @test t.line == 2 && t.column == 1
        t = m.next_token!(l)  # y
        @test t.line == 2 && t.column == 5

        # With comments
        l = m.Lexer("# comment\nlet x = 1;")
        t = m.next_token!(l)  # let (after comment)
        @test t.line == 2 && t.column == 1

        # String literal position
        l = m.Lexer("let s = \"hello\";")
        for _ in 1:3
            m.next_token!(l)  # skip let, s, =
        end
        t = m.next_token!(l)  # "hello"
        @test t.line == 1 && t.column == 9
    end

    @testset "Test comments" begin
        # Single line comment at end of line
        l = m.Lexer("1 + 2 # this is a comment")
        test_token(m.next_token!(l), test_token(m.INT, "1"))
        test_token(m.next_token!(l), test_token(m.PLUS, "+"))
        test_token(m.next_token!(l), test_token(m.INT, "2"))
        test_token(m.next_token!(l), test_token(m.EOF, ""))

        # Comment on its own line
        l = m.Lexer("""
        # comment line
        5
        """)
        test_token(m.next_token!(l), test_token(m.INT, "5"))
        test_token(m.next_token!(l), test_token(m.EOF, ""))

        # Multiple comments
        l = m.Lexer("""
        # first comment
        let x = 5; # inline comment
        # another comment
        x
        """)
        test_token(m.next_token!(l), test_token(m.LET, "let"))
        test_token(m.next_token!(l), test_token(m.IDENT, "x"))
        test_token(m.next_token!(l), test_token(m.ASSIGN, "="))
        test_token(m.next_token!(l), test_token(m.INT, "5"))
        test_token(m.next_token!(l), test_token(m.SEMICOLON, ";"))
        test_token(m.next_token!(l), test_token(m.IDENT, "x"))
        test_token(m.next_token!(l), test_token(m.EOF, ""))

        # Comment with special characters
        l = m.Lexer("1 # !@#\$%^&*() 中文 🚀")
        test_token(m.next_token!(l), test_token(m.INT, "1"))
        test_token(m.next_token!(l), test_token(m.EOF, ""))
    end

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
            expected = map(x -> test_token(x...),
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
                           ])

            l = m.Lexer("=+(){},;~")

            for token in expected
                @test begin
                    test_token(m.next_token!(l), token)

                    true
                end
            end
        end

        @testset "Advanced Test" begin
            expected = map(x -> test_token(x...),
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
                               (m.BREAK, "break"),
                               (m.SEMICOLON, ";"),
                               (m.CONTINUE, "continue"),
                               (m.SEMICOLON, ";"),
                               (m.RBRACE, "}"),
                               (m.SEMICOLON, ";"),
                               (m.EOF, ""),
                           ])

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

            while (true) { puts(3); break; continue; };
            """)

            for token in expected
                test_token(m.next_token!(l), token)
            end
        end
    end
end
