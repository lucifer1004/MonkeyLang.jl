const PROMPT = ">> "

function start_repl()
  while true
    print(PROMPT)
    line = readline()
    if line == ""
      break
    else
      l = Lexer(line)
      p = Parser(l)
      try
        program = parse!(p)
        println(program)
      catch
        if !isempty(p.errors)
          println(join(p.errors, "\n"))
          continue
        end
      end
    end
  end
end
