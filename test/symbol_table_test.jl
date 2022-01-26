@testset "Test Symbol Table" begin
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
