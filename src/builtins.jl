const BUILTINS = Pair{String,Builtin}[
    "len"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 1
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
                )
            end

            arg = args[1]
            if isa(arg, StringObj)
                return IntegerObj(length(arg.value))
            elseif isa(arg, ArrayObj)
                return IntegerObj(length(arg.elements))
            elseif isa(arg, HashObj)
                return IntegerObj(length(arg.pairs))
            end

            return ErrorObj(
                "argument error: argument to `len` is not supported, got $(type_of(arg))",
            )
        end,
    ),
    "first"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 1
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
                )
            end

            arg = args[1]
            if isa(arg, StringObj)
                return length(arg.value) >= 1 ? StringObj(string(first(arg.value))) : _NULL
            elseif isa(arg, ArrayObj)
                return length(arg.elements) >= 1 ? first(arg.elements) : _NULL
            end

            return ErrorObj(
                "argument error: argument to `first` is not supported, got $(type_of(arg))",
            )
        end,
    ),
    "last"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 1
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
                )
            end

            arg = args[1]
            if isa(arg, StringObj)
                return length(arg.value) >= 1 ? StringObj(string(last(arg.value))) : _NULL
            elseif isa(arg, ArrayObj)
                return length(arg.elements) >= 1 ? last(arg.elements) : _NULL
            end

            return ErrorObj(
                "argument error: argument to `last` is not supported, got $(type_of(arg))",
            )
        end,
    ),
    "rest"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 1
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
                )
            end

            arg = args[1]
            if isa(arg, StringObj)
                if length(arg.value) >= 1
                    _, start = iterate(arg.value)
                    return StringObj(arg.value[start:end])
                else
                    return _NULL
                end
            elseif isa(arg, ArrayObj)
                l = length(arg.elements)
                return l >= 1 ? ArrayObj(arg.elements[2:end]) : _NULL
            end

            return ErrorObj(
                "argument error: argument to `rest` is not supported, got $(type_of(arg))",
            )
        end,
    ),
    "push"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 2 && length(args) != 3
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 2 or 3",
                )
            end

            if length(args) == 2
                if !isa(args[1], ArrayObj)
                    return ErrorObj(
                        "argument error: argument to `push` is not supported, got $(type_of(args[1]))",
                    )
                end

                arr = args[1]
                elements = copy(arr.elements)
                push!(elements, args[2])

                return ArrayObj(elements)
            else
                if !isa(args[1], HashObj)
                    return ErrorObj(
                        "argument error: argument to `push` is not supported, got $(type_of(args[1]))",
                    )
                end

                hash = args[1]
                pairs = copy(hash.pairs)
                push!(pairs, args[2] => args[3])

                return HashObj(pairs)
            end
        end,
    ),
    "puts"=>Builtin(function (args::Vararg{Object}; env::Environment = Environment())
        for arg in args
            if isa(arg, StringObj)
                println(env.output, arg.value)
            else
                println(env.output, arg)
            end
        end

        return _NULL
    end),
    "type"=>Builtin(
        function (args::Vararg{Object}; env::Environment = Environment())
            if length(args) != 1
                return ErrorObj(
                    "argument error: wrong number of arguments. Got $(length(args)) instead of 1",
                )
            end

            return StringObj(type_of(args[1]))
        end,
    ),
]

get_builtin_by_name(name::String) = begin
    for (_name, builtin) in BUILTINS
        if name == _name
            return builtin
        end
    end

    return nothing
end
