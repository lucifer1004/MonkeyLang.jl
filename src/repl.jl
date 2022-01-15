const PROMPT = ">> "

function start_repl()
  env = Environment()

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
        println(Error("parser has $(length(p.errors)) errors"))
        println(join(map(string, p.errors), "\n"))
        continue
      end

      evaluated = evaluate(program, env)
      if !isnothing(evaluated)
        println(evaluated)
      end
    end
  end
end
