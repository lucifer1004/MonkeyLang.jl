const BUILTINS = Dict{String,Builtin}(
  "len" => Builtin(function (args::Vararg{Object})
    if length(args) != 1
      return Error("argument error: wrong number of arguments. Got $(length(args)) instead of 1")
    end

    arg = args[1]
    if isa(arg, StringObj)
      return Integer(length(arg.value))
    end

    return Error("argument error: argument to `len` is not supported, got $(type_of(arg))")
  end)
)