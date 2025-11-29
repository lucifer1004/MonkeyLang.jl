mutable struct Lexer
    input::String
    next::Union{Tuple{Char, Int}, Nothing}
    line::Int
    column::Int
end

Lexer(input::String) = Lexer(input, iterate(input), 1, 1)

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
        if ch == '\n'
            l.line += 1
            l.column = 1
        else
            l.column += 1
        end
        return ch
    end
end

function next_token!(l::Lexer)
    skip_whitespace_and_comments!(l)
    line, col = l.line, l.column
    ch = read_char(l)
    if ch == '='
        if peek_char(l) == '='
            read_char!(l)
            token = Token(EQ, "==", line, col)
        else
            token = Token(ASSIGN, "=", line, col)
        end
    elseif ch == ';'
        token = Token(SEMICOLON, ";", line, col)
    elseif ch == '('
        token = Token(LPAREN, "(", line, col)
    elseif ch == ')'
        token = Token(RPAREN, ")", line, col)
    elseif ch == ','
        token = Token(COMMA, ",", line, col)
    elseif ch == '!'
        if peek_char(l) == '='
            read_char!(l)
            token = Token(NOT_EQ, "!=", line, col)
        else
            token = Token(BANG, "!", line, col)
        end
    elseif ch == '+'
        token = Token(PLUS, "+", line, col)
    elseif ch == '-'
        token = Token(MINUS, "-", line, col)
    elseif ch == '*'
        token = Token(ASTERISK, "*", line, col)
    elseif ch == '/'
        token = Token(SLASH, "/", line, col)
    elseif ch == '<'
        token = Token(LT, "<", line, col)
    elseif ch == '>'
        token = Token(GT, ">", line, col)
    elseif ch == '{'
        token = Token(LBRACE, "{", line, col)
    elseif ch == '}'
        token = Token(RBRACE, "}", line, col)
    elseif ch == '"'
        return read_string!(l, line, col)
    elseif ch == '['
        token = Token(LBRACKET, "[", line, col)
    elseif ch == ']'
        token = Token(RBRACKET, "]", line, col)
    elseif ch == ':'
        token = Token(COLON, ":", line, col)
    elseif isnothing(ch)
        token = Token(EOF, "", line, col)
    elseif isidentletter(ch)
        return read_identifier!(l, line, col)
    elseif isdigit(ch)
        return read_number!(l, line, col)
    else
        token = Token(ILLEGAL, string(ch), line, col)
    end

    read_char!(l)
    return token
end

function read_identifier!(l::Lexer, line::Int, col::Int)
    chars = Char[]
    while isidentletter(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end
    literal = join(chars, "")
    return Token(lookup_indent(literal), literal, line, col)
end

function read_number!(l::Lexer, line::Int, col::Int)
    chars = Char[]
    while isdigit(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end
    literal = join(chars, "")
    return Token(INT, literal, line, col)
end

function read_string!(l::Lexer, line::Int, col::Int)
    read_char!(l)

    chars = Char[]
    while read_char(l) != '"' && !isnothing(read_char(l))
        push!(chars, read_char(l))
        read_char!(l)
    end

    read_char!(l)

    return Token(STRING, join(chars, ""), line, col)
end

function skip_whitespace_and_comments!(l::Lexer)
    while true
        ch = read_char(l)
        if isspace(ch)
            read_char!(l)
        elseif ch == '#'
            skip_comment!(l)
        else
            break
        end
    end
end

function skip_comment!(l::Lexer)
    while true
        ch = read_char!(l)
        if isnothing(ch) || ch == '\n'
            break
        end
    end
end

isidentletter(ch) = !isnothing(ch) && ('a' <= ch <= 'z' || 'A' <= ch <= 'Z' || ch == '_')
isspace(ch) = !isnothing(ch) && (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r')
isdigit(ch) = !isnothing(ch) && ('0' <= ch <= '9')
