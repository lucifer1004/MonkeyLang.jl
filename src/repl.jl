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
      program = parse!(p)
      if !isempty(p.errors)
        println(join(p.errors, "\n"))
        continue
      end
      println(program)
    end
  end
end
