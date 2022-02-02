const HELP_INFO = """

This is MonkeyLang.jl $MONKEY_VERSION by $MONKEY_AUTHOR.

Usage:

monkey run <file> [--vm | --jl]
monkey repl [--vm]
"""

function julia_main(; input::IO = stdin, output::IO = stdout)::Cint
  if length(ARGS) == 0 || ARGS[1] ∉ ["run", "repl"]
    println(output, HELP_INFO)
    return 0
  end

  if ARGS[1] == "run"
    if length(ARGS) < 2
      println(output, "Usage: monkey run <file> [--vm | --jl]")
      return 0
    end

    _, ext = splitext(ARGS[2])
    if ext != ".mo"
      println(output, "ERROR: Only .mo files are supported!")
      return 0
    end

    if !isfile(ARGS[2])
      println(output, "ERROR: File not found!")
      return 0
    end

    code = String(read(open(ARGS[2])))
    if length(ARGS) == 3
      if ARGS[3] == "--vm"
        MonkeyLang.run(code; input, output)
      elseif ARGS[3] == "--jl"
        MonkeyLang.Transpilers.JuliaTranspiler.run(code; input, output)
      else
        println(output, "Usage: monkey run <file> [--vm | --jl]")
        return 0
      end
    else
      result = evaluate(code; input, output)
      if isa(result, ErrorObj)
        println(output, result)
      end
    end
  else
    start_repl(; input, output, use_vm = "--vm" ∈ ARGS)
  end

  return 0
end
