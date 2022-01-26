@enum TokenType ILLEGAL EOF IDENT INT ASSIGN PLUS MINUS BANG ASTERISK SLASH EQ NOT_EQ LT GT COMMA SEMICOLON LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COLON FUNCTION MACRO LET TRUE FALSE NULL IF ELSE RETURN STRING

struct Token
    type::TokenType
    literal::String
end

const KEYWORDS = Dict{String,TokenType}(
    "fn" => FUNCTION,
    "let" => LET,
    "true" => TRUE,
    "false" => FALSE,
    "null" => NULL,
    "if" => IF,
    "else" => ELSE,
    "return" => RETURN,
    "macro" => MACRO,
)

lookup_indent(ident::AbstractString) =
    if ident in keys(KEYWORDS)
        KEYWORDS[ident]
    else
        IDENT
    end
