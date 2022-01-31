@testset "Test CLI" begin
    for (args, expected_output) in [
        (["help"], m.HELP_INFO * "\n"),
        (["ask"], m.HELP_INFO * "\n"),
        (["run"], "Usage: monkey run <file> [--vm]\n"),
        (["run", "fixtures/hello_world.m"], "ERROR: Only .mo files are supported!\n"),
        (["run", "fixtures/not_exist.mo"], "ERROR: File not found!\n"),
        (["run", "fixtures/hello_world.mo"], "Hello, world!\n"),
        (["run", "fixtures/hello_world.mo", "--vm"], "Hello, world!\n"),
        (["repl"], m.REPL_PRELUDE * "\n>> " * m.REPL_FAREWELL * "\n"),
        (["repl", "--vm"], m.REPL_PRELUDE * "\n>> " * m.REPL_FAREWELL * "\n"),
    ]
        input = IOBuffer()
        output = IOBuffer(UInt8[], read = true, write = true)

        for arg in args
            push!(ARGS, arg)
        end

        m.julia_main(; input = input, output = output)
        @test String(output.data) == expected_output

        for _ = 1:length(args)
            pop!(ARGS)
        end
    end
end
