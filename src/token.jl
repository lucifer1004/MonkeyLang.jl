@enum TokenType ILLEGAL EOF IDENT INT ASSIGN PLUS MINUS BANG ASTERISK SLASH EQ NOT_EQ LT GT COMMA SEMICOLON LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COLON FUNCTION MACRO LET TRUE FALSE NULL IF ELSE WHILE BREAK CONTINUE RETURN STRING

struct Token
    type::TokenType
    literal::String
end

const KEYWORDS = Dict{String, TokenType}("fn" => FUNCTION,
                                         "let" => LET,
                                         "true" => TRUE,
                                         "false" => FALSE,
                                         "null" => NULL,
                                         "if" => IF,
                                         "else" => ELSE,
                                         "while" => WHILE,
                                         "break" => BREAK,
                                         "continue" => CONTINUE,
                                         "return" => RETURN,
                                         "macro" => MACRO)

lookup_indent(ident::AbstractString) = ident in keys(KEYWORDS) ? KEYWORDS[ident] : IDENT
