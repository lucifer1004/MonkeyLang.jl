const PROMPT = ">> "

function start_repl()
  env = Environment()

  println("""

  ███╗   ███╗ ██████╗ ███╗   ██╗██╗  ██╗███████╗██╗   ██╗   |
  ████╗ ████║██╔═══██╗████╗  ██║██║ ██╔╝██╔════╝╚██╗ ██╔╝   |
  ██╔████╔██║██║   ██║██╔██╗ ██║█████╔╝ █████╗   ╚████╔╝    |
  ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔═██╗ ██╔══╝    ╚██╔╝     |  Version $MONKEY_VERSION
  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║  ██╗███████╗   ██║      |
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝   ╚═╝      |  BY $MONKEY_AUTHOR
  
""")

  while true
    print(PROMPT)
    line = readline()
    if line == ""
      println("Good bye!")
      break
    else
      l = Lexer(line)
      p = Parser(l)
      program = parse!(p)
      if !isempty(p.errors)
        println(ErrorObj("parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")"))
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
