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
  env = Environment(; input = input, output = output)
  macro_env = Environment(; input = input, output = output)

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

      program = define_macros!(macro_env, program)

      try
        expanded = expand_macros(program, macro_env)
        evaluated = evaluate(expanded, env)
        if !isnothing(evaluated)
          println(output, evaluated)
        end
      catch e
        if isa(e, StackOverflowError)
          println(output, ErrorObj("stack overflow"))
        elseif :msg in fieldnames(typeof(e))
          println(output, ErrorObj(e.msg))
        else
          println(output, ErrorObj("unknown error"))
        end
      end

    end
  end
end
