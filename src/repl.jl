const PROMPT = ">> "
const REPL_PRELUDE = """

  ███╗   ███╗ ██████╗ ███╗   ██╗██╗  ██╗███████╗██╗   ██╗   |
  ████╗ ████║██╔═══██╗████╗  ██║██║ ██╔╝██╔════╝╚██╗ ██╔╝   |
  ██╔████╔██║██║   ██║██╔██╗ ██║█████╔╝ █████╗   ╚████╔╝    |
  ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔═██╗ ██╔══╝    ╚██╔╝     |  Version $MONKEY_VERSION
  ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║  ██╗███████╗   ██║      |
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝   ╚═╝      |  BY $MONKEY_AUTHOR
"""
const REPL_FAREWELL = "Good bye!"

function start_repl(; input::IO = stdin, output::IO = stdout)
  env = Environment()

  println(output, REPL_PRELUDE)

  while true
    print(output, PROMPT)
    line = readline(input)
    if line == ""
      println(output, REPL_FAREWELL)
      break
    else
      l = Lexer(line)
      p = Parser(l)
      program = parse!(p)
      if !isempty(p.errors)
        println(output, ErrorObj("parser has $(length(p.errors)) error$(length(p.errors) == 1 ? "" : "s")"))
        println(output, join(map(string, p.errors), "\n"))
        continue
      end

      evaluated = evaluate(program, env)
      if !isnothing(evaluated)
        println(output, evaluated)
      end
    end
  end
end
