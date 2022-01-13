const PROMPT = ">> "

function start_repl()
  while true
    print(PROMPT)
    line = readline()
    if line == ""
      break
    else
      l = Lexer(line)
      token = next_token!(l)
      while token.type != EOF
        println(token)
        token = next_token!(l)
      end
    end
  end
end
