mutable struct Lexer
    input::String
    next::Union{Tuple{Char, Int}, Nothing}
end

Lexer(input::String) = Lexer(input, iterate(input))

function read_char(l::Lexer)
    if isnothing(l.next)
        return
    else
        ch, _ = l.next
        return ch
    end
end

function peek_char(l::Lexer)
    if isnothing(l.next)
        return
    else
        _, state = l.next
        nxt = iterate(l.input, state)
        if !isnothing(nxt)
            ch, _ = nxt
            return ch
        else
            return
        end
    end
end

function read_char!(l::Lexer)
    if isnothing(l.next)
        return
    else
        ch, state = l.next
        l.next = iterate(l.input, state)
        return ch
    end
end

function next_token!(l::Lexer)
    skip_whitespace!(l)
    ch = read_char(l)
    if ch == '='
        if peek_char(l) == '='
            read_char!(l)
            token = Token(EQ, "==")
        else
            token = Token(ASSIGN, "=")
        end
    elseif ch == ';'
        token = Token(SEMICOLON, ";")
    elseif ch == '('
        token = Token(LPAREN, "(")
    elseif ch == ')'
        token = Token(RPAREN, ")")
    elseif ch == ','
        token = Token(COMMA, ",")
    elseif ch == '!'
        if peek_char(l) == '='
            read_char!(l)
            token = Token(NOT_EQ, "!=")
        else
            token = Token(BANG, "!")
        end
    elseif ch == '+'
        token = Token(PLUS, "+")
    elseif ch == '-'
        token = Token(MINUS, "-")
    elseif ch == '*'
        token = Token(ASTERISK, "*")
    elseif ch == '/'
        token = Token(SLASH, "/")
    elseif ch == '<'
        token = Token(LT, "<")
    elseif ch == '>'
        token = Token(GT, ">")
    elseif ch == '{'
        token = Token(LBRACE, "{")
    elseif ch == '}'
        token = Token(RBRACE, "}")
    elseif ch == '"'
        return read_string!(l)
    elseif ch == '['
        token = Token(LBRACKET, "[")
    elseif ch == ']'
        token = Token(RBRACKET, "]")
    elseif ch == ':'
        token = Token(COLON, ":")
    elseif isnothing(ch)
        token = Token(EOF, "")
    elseif isidentletter(ch)
        return read_identifier!(l)
    elseif isdigit(ch)
        return read_number!(l)
    else
        token = Token(ILLEGAL, string(ch))
    end

    read_char!(l)
    return token
end

function read_identifier!(l::Lexer)
    chars = Char[]
    while isidentletter(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end
    literal = join(chars, "")
    return Token(lookup_indent(literal), literal)
end

function read_number!(l::Lexer)
    chars = Char[]
    while isdigit(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end
    literal = join(chars, "")
    return Token(INT, literal)
end

function read_string!(l::Lexer)
    read_char!(l)

    chars = Char[]
    while read_char(l) != '"' && !isnothing(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end

    read_char!(l)

    return Token(STRING, join(chars, ""))
end

function skip_whitespace!(l::Lexer)
    while isspace(read_char(l))
        read_char!(l)
    end
end

isidentletter(ch) = !isnothing(ch) && ('a' <= ch <= 'z' || 'A' <= ch <= 'Z' || ch == '_')
isspace(ch) = !isnothing(ch) && (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r')
isdigit(ch) = !isnothing(ch) && ('0' <= ch <= '9')
