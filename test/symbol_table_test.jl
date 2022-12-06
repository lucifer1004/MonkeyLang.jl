@testset "Test Symbol Table" begin
    @testset "Scope" begin
        expected = Dict("a" => m.MonkeySymbol("a", m.GlobalScope, 0, nothing),
                        "b" => m.MonkeySymbol("b", m.GlobalScope, 1, nothing),
                        "c" => m.MonkeySymbol("c", m.LocalScope, 0, nothing),
                        "d" => m.MonkeySymbol("d", m.LocalScope, 1, nothing),
                        "e" => m.MonkeySymbol("e", m.LocalScope, 0, nothing),
                        "f" => m.MonkeySymbol("f", m.LocalScope, 1, nothing))

        g = m.SymbolTable()

        a = m.define!(g, "a")
        @test a == expected["a"]

        b = m.define!(g, "b")
        @test b == expected["b"]

        l1 = m.SymbolTable(; outer = g)

        c = m.define!(l1, "c")
        @test c == expected["c"]

        d = m.define!(l1, "d")
        @test d == expected["d"]

        l2 = m.SymbolTable(; outer = l1)

        e = m.define!(l2, "e")
        @test e == expected["e"]

        f = m.define!(l2, "f")
        @test f == expected["f"]

        @test m.resolve(g, "a")[1] == expected["a"]
        @test m.resolve(g, "b")[1] == expected["b"]

        @test m.resolve(l1, "a")[1] == expected["a"]
        @test m.resolve(l1, "b")[1] == expected["b"]
        @test m.resolve(l1, "c")[1] == expected["c"]
        @test m.resolve(l1, "d")[1] == expected["d"]

        @test m.resolve(l2, "a")[1] == expected["a"]
        @test m.resolve(l2, "b")[1] == expected["b"]
        @test m.resolve(l2, "e")[1] == expected["e"]
        @test m.resolve(l2, "f")[1] == expected["f"]
    end

    @testset "Shadowing Variables" begin
        g = m.SymbolTable()
        a = m.define!(g, "a")
        b = m.define!(g, "b")

        l1 = m.SymbolTable(; outer = g)
        @test m.resolve(l1, "a")[1] == m.MonkeySymbol("a", m.GlobalScope, 0, nothing)

        a1 = m.define!(l1, "a")
        @test a1 == m.MonkeySymbol("a", m.LocalScope, 0, nothing)
        @test m.resolve(l1, "a")[1] == m.MonkeySymbol("a", m.LocalScope, 0, nothing)
        @test m.resolve(l1, "b")[1] == m.MonkeySymbol("b", m.GlobalScope, 1, nothing)

        l2 = m.SymbolTable(; outer = l1, within_loop = true)
        @test m.resolve(l2, "a")[1] ==
              m.MonkeySymbol("a", m.OuterScope, 0, m.SymbolPointer(1, m.LocalScope, 0))
        @test m.resolve(l2, "b")[1] == m.MonkeySymbol("b", m.GlobalScope, 1, nothing)

        l3 = m.SymbolTable(; outer = l2, within_loop = true)
        @test m.resolve(l3, "a")[1] ==
              m.MonkeySymbol("a", m.OuterScope, 0, m.SymbolPointer(2, m.LocalScope, 0))
        @test m.resolve(l3, "b")[1] == m.MonkeySymbol("b", m.GlobalScope, 1, nothing)
    end

    @testset "Builtins" begin
        expected = Dict("a" => m.MonkeySymbol("a", m.BuiltinScope, 0, nothing),
                        "c" => m.MonkeySymbol("c", m.BuiltinScope, 1, nothing),
                        "e" => m.MonkeySymbol("e", m.BuiltinScope, 2, nothing),
                        "f" => m.MonkeySymbol("f", m.BuiltinScope, 3, nothing))

        g = m.SymbolTable()
        l1 = m.SymbolTable(; outer = g)
        l2 = m.SymbolTable(; outer = l1)

        for (i, k) in expected |> keys |> collect |> sort |> enumerate
            m.define_builtin!(g, k, i - 1)
        end

        for s in [g, l1, l2]
            for (k, v) in expected
                @test m.resolve(s, k)[1] == v
            end
        end
    end

    @testset "Free Variables" begin
        g = m.SymbolTable()
        m.define!(g, "a")
        m.define!(g, "b")

        l1 = m.SymbolTable(; outer = g)
        m.define!(l1, "c")
        m.define!(l1, "d")

        l2 = m.SymbolTable(; outer = l1)
        m.define!(l2, "e")
        m.define!(l2, "f")

        for (table, expected_symbols, expected_free_symbols) in [
            (l1,
             [
                 m.MonkeySymbol("a", m.GlobalScope, 0, nothing),
                 m.MonkeySymbol("b", m.GlobalScope, 1, nothing),
                 m.MonkeySymbol("c", m.LocalScope, 0, nothing),
                 m.MonkeySymbol("d", m.LocalScope, 1, nothing),
             ],
             []),
            (l2,
             [
                 m.MonkeySymbol("a", m.GlobalScope, 0, nothing),
                 m.MonkeySymbol("b", m.GlobalScope, 1, nothing),
                 m.MonkeySymbol("c", m.FreeScope, 0, nothing),
                 m.MonkeySymbol("d", m.FreeScope, 1, nothing),
                 m.MonkeySymbol("e", m.LocalScope, 0, nothing),
                 m.MonkeySymbol("f", m.LocalScope, 1, nothing),
             ],
             [
                 m.MonkeySymbol("c", m.LocalScope, 0, nothing),
                 m.MonkeySymbol("d", m.LocalScope, 1, nothing),
             ]),
        ]
            for sym in expected_symbols
                @test m.resolve(table, sym.name)[1] == sym
            end

            @test length(table.free_symbols) == length(expected_free_symbols)

            for (actual, expected) in zip(table.free_symbols, expected_free_symbols)
                @test actual == expected
            end
        end
    end

    @testset "Unresolvable Free Variables" begin
        g = m.SymbolTable()
        m.define!(g, "a")

        l1 = m.SymbolTable(; outer = g)
        m.define!(l1, "c")

        l2 = m.SymbolTable(; outer = l1)
        m.define!(l2, "e")
        m.define!(l2, "f")

        expected = [
            m.MonkeySymbol("a", m.GlobalScope, 0, nothing),
            m.MonkeySymbol("c", m.FreeScope, 0, nothing),
            m.MonkeySymbol("e", m.LocalScope, 0, nothing),
            m.MonkeySymbol("f", m.LocalScope, 1, nothing),
        ]

        for sym in expected
            @test m.resolve(l2, sym.name)[1] == sym
        end

        for name in ["b", "d"]
            @test isnothing(m.resolve(l2, name)[1])
        end
    end

    @testset "Define And Resolve Function Name" begin
        g = m.SymbolTable()
        m.define_function!(g, "a")

        @test m.resolve(g, "a")[1] == m.MonkeySymbol("a", m.FunctionScope, 0, nothing)
    end

    @testset "Shadowing Function Name" begin
        g = m.SymbolTable()
        m.define_function!(g, "a")
        m.define!(g, "a")

        @test m.resolve(g, "a")[1] == m.MonkeySymbol("a", m.GlobalScope, 0, nothing)
    end
end
