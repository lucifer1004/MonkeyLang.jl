@testset "Test Symbol Table" begin
    @testset "Scope" begin
        expected = Dict(
            "a" => m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0),
            "b" => m.MonkeySymbol("b", m.GLOBAL_SCOPE, 1),
            "c" => m.MonkeySymbol("c", m.LOCAL_SCOPE, 0),
            "d" => m.MonkeySymbol("d", m.LOCAL_SCOPE, 1),
            "e" => m.MonkeySymbol("e", m.LOCAL_SCOPE, 0),
            "f" => m.MonkeySymbol("f", m.LOCAL_SCOPE, 1),
        )

        g = m.SymbolTable()

        a = m.define!(g, "a")
        @test a == expected["a"]

        b = m.define!(g, "b")
        @test b == expected["b"]

        l1 = m.SymbolTable(g)

        c = m.define!(l1, "c")
        @test c == expected["c"]

        d = m.define!(l1, "d")
        @test d == expected["d"]

        l2 = m.SymbolTable(l1)

        e = m.define!(l2, "e")
        @test e == expected["e"]

        f = m.define!(l2, "f")
        @test f == expected["f"]

        @test m.resolve(g, "a") == expected["a"]
        @test m.resolve(g, "b") == expected["b"]

        @test m.resolve(l1, "a") == expected["a"]
        @test m.resolve(l1, "b") == expected["b"]
        @test m.resolve(l1, "c") == expected["c"]
        @test m.resolve(l1, "d") == expected["d"]

        @test m.resolve(l2, "a") == expected["a"]
        @test m.resolve(l2, "b") == expected["b"]
        @test m.resolve(l2, "e") == expected["e"]
        @test m.resolve(l2, "f") == expected["f"]
    end

    @testset "Builtins" begin
        expected = Dict(
            "a" => m.MonkeySymbol("a", m.BUILTIN_SCOPE, 0),
            "c" => m.MonkeySymbol("c", m.BUILTIN_SCOPE, 1),
            "e" => m.MonkeySymbol("e", m.BUILTIN_SCOPE, 2),
            "f" => m.MonkeySymbol("f", m.BUILTIN_SCOPE, 3),
        )

        g = m.SymbolTable()
        l1 = m.SymbolTable(g)
        l2 = m.SymbolTable(l1)

        for (i, k) in expected |> keys |> collect |> sort |> enumerate
            m.define_builtin!(g, k, i - 1)
        end

        for s in [g, l1, l2]
            for (k, v) in expected
                @test m.resolve(s, k) == v
            end
        end
    end

    @testset "Free Variables" begin
        g = m.SymbolTable()
        m.define!(g, "a")
        m.define!(g, "b")

        l1 = m.SymbolTable(g)
        m.define!(l1, "c")
        m.define!(l1, "d")

        l2 = m.SymbolTable(l1)
        m.define!(l2, "e")
        m.define!(l2, "f")

        for (table, expected_symbols, expected_free_symbols) in [
            (
                l1,
                [
                    m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0),
                    m.MonkeySymbol("b", m.GLOBAL_SCOPE, 1),
                    m.MonkeySymbol("c", m.LOCAL_SCOPE, 0),
                    m.MonkeySymbol("d", m.LOCAL_SCOPE, 1),
                ],
                [],
            ),
            (
                l2,
                [
                    m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0),
                    m.MonkeySymbol("b", m.GLOBAL_SCOPE, 1),
                    m.MonkeySymbol("c", m.FREE_SCOPE, 0),
                    m.MonkeySymbol("d", m.FREE_SCOPE, 1),
                    m.MonkeySymbol("e", m.LOCAL_SCOPE, 0),
                    m.MonkeySymbol("f", m.LOCAL_SCOPE, 1),
                ],
                [
                    m.MonkeySymbol("c", m.LOCAL_SCOPE, 0),
                    m.MonkeySymbol("d", m.LOCAL_SCOPE, 1),
                ],
            ),
        ]
            for sym in expected_symbols
                @test m.resolve(table, sym.name) == sym
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

        l1 = m.SymbolTable(g)
        m.define!(l1, "c")

        l2 = m.SymbolTable(l1)
        m.define!(l2, "e")
        m.define!(l2, "f")

        expected = [
            m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0),
            m.MonkeySymbol("c", m.FREE_SCOPE, 0),
            m.MonkeySymbol("e", m.LOCAL_SCOPE, 0),
            m.MonkeySymbol("f", m.LOCAL_SCOPE, 1),
        ]

        for sym in expected
            @test m.resolve(l2, sym.name) == sym
        end

        for name in ["b", "d"]
            @test isnothing(m.resolve(l2, name))
        end
    end

    @testset "Define And Resolve Function Name" begin
        g = m.SymbolTable()
        m.define_function!(g, "a")

        @test m.resolve(g, "a") == m.MonkeySymbol("a", m.FUNCTION_SCOPE, 0)
    end

    @testset "Shadowing Function Name" begin
        g = m.SymbolTable()
        m.define_function!(g, "a")
        m.define!(g, "a")

        @test m.resolve(g, "a") == m.MonkeySymbol("a", m.GLOBAL_SCOPE, 0)
    end
end
