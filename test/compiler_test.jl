@testset "Test Compiler" begin
    @testset "Integer Arithmetic" begin for (input, expected_constants, expected_instructions) in [
        ("1; 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpPop),
             m.make(m.OpConstant, 1),
             m.make(m.OpPop),
         ]),
        ("1 + 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpAdd),
             m.make(m.OpPop),
         ]),
        ("1 - 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpSub),
             m.make(m.OpPop),
         ]),
        ("1 * 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpMul),
             m.make(m.OpPop),
         ]),
        ("1 / 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpDiv),
             m.make(m.OpPop),
         ]),
        ("-1", [1], [m.make(m.OpConstant, 0), m.make(m.OpMinus), m.make(m.OpPop)]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Boolean Expressions" begin for (input, expected_constants, expected_instructions) in [
        ("true", [], [m.make(m.OpTrue), m.make(m.OpPop)]),
        ("false", [], [m.make(m.OpFalse), m.make(m.OpPop)]),
        ("1 == 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpEqual),
             m.make(m.OpPop),
         ]),
        ("1 != 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpNotEqual),
             m.make(m.OpPop),
         ]),
        ("1 < 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpLessThan),
             m.make(m.OpPop),
         ]),
        ("1 > 2",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpGreaterThan),
             m.make(m.OpPop),
         ]),
        ("true == false",
         [],
         [m.make(m.OpTrue), m.make(m.OpFalse), m.make(m.OpEqual), m.make(m.OpPop)]),
        ("true != false",
         [],
         [
             m.make(m.OpTrue),
             m.make(m.OpFalse),
             m.make(m.OpNotEqual),
             m.make(m.OpPop),
         ]),
        ("!true", [], [m.make(m.OpTrue), m.make(m.OpBang), m.make(m.OpPop)]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Conditionals" begin for (input, expected_constants, expected_instructions) in [
        ("if (true) {};",
         [],
         [
             m.make(m.OpTrue),
             m.make(m.OpJumpNotTruthy, 8),
             m.make(m.OpNull),
             m.make(m.OpJump, 9),
             m.make(m.OpNull),
             m.make(m.OpPop),
         ]),
        ("if (true) { 10 }; 3333",
         [10, 3333],
         [
             m.make(m.OpTrue),
             m.make(m.OpJumpNotTruthy, 10),
             m.make(m.OpConstant, 0),
             m.make(m.OpJump, 11),
             m.make(m.OpNull),
             m.make(m.OpPop),
             m.make(m.OpConstant, 1),
             m.make(m.OpPop),
         ]),
        ("if (true) { 10 } else { 20 }; 3333",
         [10, 20, 3333],
         [
             m.make(m.OpTrue),
             m.make(m.OpJumpNotTruthy, 10),
             m.make(m.OpConstant, 0),
             m.make(m.OpJump, 13),
             m.make(m.OpConstant, 1),
             m.make(m.OpPop),
             m.make(m.OpConstant, 2),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Global Let Statements" begin for (input, expected_constants, expected_instructions) in [
        ("let one = 1;\nlet two = 2;\n",
         [1, 2],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpSetGlobal, 1),
         ]),
        ("let one = 1;\none;\n",
         [1],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpPop),
         ]),
        ("let one = 1;\nlet two = one;\ntwo;\n",
         [1],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpSetGlobal, 1),
             m.make(m.OpGetGlobal, 1),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Global Let Statements" begin for (input, expected_constants, expected_instructions) in [
        ("let num = 55;\nfn() { num }",
         [55, vcat(m.make(m.OpGetGlobal, 0), m.make(m.OpReturnValue))],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpClosure, 1, 0),
             m.make(m.OpPop),
         ]),
        ("fn() {\nlet num = 55;\nnum\n}",
         [
             55,
             vcat(m.make(m.OpConstant, 0),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 1, 0), m.make(m.OpPop)]),
        ("""
         fn() {
           let a = 55;
           let b = 77;
           a + b
         }
         """,
         [
             55,
             77,
             vcat(m.make(m.OpConstant, 0),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpConstant, 1),
                  m.make(m.OpSetLocal, 1),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpGetLocal, 1),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 2, 0), m.make(m.OpPop)]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "String Expressions" begin for (input, expected_constants, expected_instructions) in [
        ("\"monkey\"", ["monkey"], [m.make(m.OpConstant, 0), m.make(m.OpPop)]),
        ("\"mon\" + \"key\"",
         ["mon", "key"],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpAdd),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Array Literals" begin for (input, expected_constants, expected_instructions) in [
        ("[]", [], [m.make(m.OpArray, 0), m.make(m.OpPop)]),
        ("[1, 2, 3]",
         [1, 2, 3],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpArray, 3),
             m.make(m.OpPop),
         ]),
        ("[1 + 2, 3 - 4, 5 * 6]",
         [1, 2, 3, 4, 5, 6],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpAdd),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 3),
             m.make(m.OpSub),
             m.make(m.OpConstant, 4),
             m.make(m.OpConstant, 5),
             m.make(m.OpMul),
             m.make(m.OpArray, 3),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Hash Literals" begin for (input, expected_constants, expected_instructions) in [
        ("{}", [], [m.make(m.OpHash, 0), m.make(m.OpPop)]),
        ("{1: 2, 3: 4, 5: 6}",
         [1, 2, 3, 4, 5, 6],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 3),
             m.make(m.OpConstant, 4),
             m.make(m.OpConstant, 5),
             m.make(m.OpHash, 6),
             m.make(m.OpPop),
         ]),
        ("{1: 2 + 3, 4: 5 * 6}",
         [1, 2, 3, 4, 5, 6],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpAdd),
             m.make(m.OpConstant, 3),
             m.make(m.OpConstant, 4),
             m.make(m.OpConstant, 5),
             m.make(m.OpMul),
             m.make(m.OpHash, 4),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Index Expressions" begin for (input, expected_constants, expected_instructions) in [
        ("[1, 2, 3][1 + 1]",
         [1, 2, 3, 1, 1],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpArray, 3),
             m.make(m.OpConstant, 3),
             m.make(m.OpConstant, 4),
             m.make(m.OpAdd),
             m.make(m.OpIndex),
             m.make(m.OpPop),
         ]),
        ("{1: 2}[2 - 1]",
         [1, 2, 2, 1],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpHash, 2),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 3),
             m.make(m.OpSub),
             m.make(m.OpIndex),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Functions" begin for (input, expected_constants, expected_instructions) in [
        ("fn() { return 5 + 10 }",
         [
             5,
             10,
             vcat(m.make(m.OpConstant, 0),
                  m.make(m.OpConstant, 1),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 2, 0), m.make(m.OpPop)]),
        ("fn() { 5 + 10 }",
         [
             5,
             10,
             vcat(m.make(m.OpConstant, 0),
                  m.make(m.OpConstant, 1),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 2, 0), m.make(m.OpPop)]),
        ("fn() { 1; 2 }",
         [
             1,
             2,
             vcat(m.make(m.OpConstant, 0),
                  m.make(m.OpPop),
                  m.make(m.OpConstant, 1),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 2, 0), m.make(m.OpPop)]),
        ("fn() { }",
         [m.make(m.OpReturn)],
         [m.make(m.OpClosure, 0, 0), m.make(m.OpPop)]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Compiler Scopes" begin
        c = m.Compiler()
        g = c.symbol_table
        @test length(c.scopes) == 1

        m.emit!(c, m.OpMul)
        m.enter_scope!(c)
        @test length(c.scopes) == 2

        m.emit!(c, m.OpSub)
        @test length(c) == 1

        last = m.last_instruction(c)
        @test last.op == m.OpSub
        @test c.symbol_table.outer == g

        m.leave_scope!(c)
        @test length(c.scopes) == 1
        @test c.symbol_table == g
        @test isnothing(c.symbol_table.outer)

        m.emit!(c, m.OpAdd)
        @test length(c) == 2

        last = m.last_instruction(c)
        @test last.op == m.OpAdd

        previous = m.prev_instruction(c)
        @test previous.op == m.OpMul
    end

    @testset "Function Calls" begin for (input, expected_constants, expected_instructions) in [
        ("fn() { 24 }()",
         [24, vcat(m.make(m.OpConstant, 0), m.make(m.OpReturnValue))],
         [m.make(m.OpClosure, 1, 0), m.make(m.OpCall, 0), m.make(m.OpPop)]),
        ("let noArg = fn() { 24 }; noArg()",
         [24, vcat(m.make(m.OpConstant, 0), m.make(m.OpReturnValue))],
         [
             m.make(m.OpClosure, 1, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpCall, 0),
             m.make(m.OpPop),
         ]),
        ("let oneArg = fn(a) { }; oneArg(24)",
         [m.make(m.OpReturn), 24],
         [
             m.make(m.OpClosure, 0, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpCall, 1),
             m.make(m.OpPop),
         ]),
        ("let manyArg = fn(a, b, c) { }; manyArg(24, 25, 26)",
         [m.make(m.OpReturn), 24, 25, 26],
         [
             m.make(m.OpClosure, 0, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 3),
             m.make(m.OpCall, 3),
             m.make(m.OpPop),
         ]),
        ("let oneArg = fn(a) { a }; oneArg(24)",
         [vcat(m.make(m.OpGetLocal, 0), m.make(m.OpReturnValue)), 24],
         [
             m.make(m.OpClosure, 0, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpCall, 1),
             m.make(m.OpPop),
         ]),
        ("let manyArg = fn(a, b, c) { a; b; c; }; manyArg(24, 25, 26)",
         [
             vcat(m.make(m.OpGetLocal, 0),
                  m.make(m.OpPop),
                  m.make(m.OpGetLocal, 1),
                  m.make(m.OpPop),
                  m.make(m.OpGetLocal, 2),
                  m.make(m.OpReturnValue)),
             24,
             25,
             26,
         ],
         [
             m.make(m.OpClosure, 0, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpConstant, 2),
             m.make(m.OpConstant, 3),
             m.make(m.OpCall, 3),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Builtin Functions" begin for (input, expected_constants, expected_instructions) in [
        ("len([]); push([], 1)",
         [1],
         [
             m.make(m.OpGetBuiltin, 0),
             m.make(m.OpArray, 0),
             m.make(m.OpCall, 1),
             m.make(m.OpPop),
             m.make(m.OpGetBuiltin, 4),
             m.make(m.OpArray, 0),
             m.make(m.OpConstant, 0),
             m.make(m.OpCall, 2),
             m.make(m.OpPop),
         ]),
        ("fn() { len([]) }",
         [
             vcat(m.make(m.OpGetBuiltin, 0),
                  m.make(m.OpArray, 0),
                  m.make(m.OpCall, 1),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 0, 0), m.make(m.OpPop)]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Closures" begin for (input, expected_constants, expected_instructions) in [
        ("""
         fn(a) {
             fn(b) {
                 a + b
             }
         }
         """,
         [
             vcat(m.make(m.OpGetFree, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
             vcat(m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 0, 1),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 1, 0), m.make(m.OpPop)]),
        ("""
         fn(a) {
             fn(b) {
                 fn(c) {
                     a + b + c
                 }
             }
         }
         """,
         [
             vcat(m.make(m.OpGetFree, 0),
                  m.make(m.OpGetFree, 1),
                  m.make(m.OpAdd),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
             vcat(m.make(m.OpGetFree, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 0, 2),
                  m.make(m.OpReturnValue)),
             vcat(m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 1, 1),
                  m.make(m.OpReturnValue)),
         ],
         [m.make(m.OpClosure, 2, 0), m.make(m.OpPop)]),
        ("""
         let global = 55;
         fn() {
             let a = 66;
             fn() {
                 a = a + 2;
                 let b = 77;
                 fn() {
                     global = global + 4;
                     let c = 88;
                     global + a + b + c
                 }
             }
         }
         """,
         [
             55,
             66,
             2,
             77,
             4,
             88,
             vcat(m.make(m.OpGetGlobal, 0),
                  m.make(m.OpConstant, 4),
                  m.make(m.OpAdd),
                  m.make(m.OpSetGlobal, 0),
                  m.make(m.OpConstant, 5),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetGlobal, 0),
                  m.make(m.OpGetFree, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpGetFree, 1),
                  m.make(m.OpAdd),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
             vcat(m.make(m.OpGetFree, 0),
                  m.make(m.OpConstant, 2),
                  m.make(m.OpAdd),
                  m.make(m.OpSetFree, 0),
                  m.make(m.OpConstant, 3),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetFree, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 6, 2),
                  m.make(m.OpReturnValue)),
             vcat(m.make(m.OpConstant, 1),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 7, 1),
                  m.make(m.OpReturnValue)),
         ],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpClosure, 8, 0),
             m.make(m.OpPop),
         ]),
        ("""
         let i = 2;
         while (i > 0) {
             i = i - 1;
             let j = 3;
             let f = fn() {
                 i + j;
             }
             while (j > 0) {
                 j = j - 1;
                 puts(f() + j);
             }
         }
         """,
         [
             2,
             0,
             1,
             3,
             vcat(m.make(m.OpGetGlobal, 0),
                  m.make(m.OpGetFree, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpReturnValue)),
             0,
             1,
             vcat(m.make(m.OpGetOuter, 1, 1, 0),
                  m.make(m.OpConstant, 6),
                  m.make(m.OpSub),
                  m.make(m.OpSetOuter, 1, 1, 0),
                  m.make(m.OpGetBuiltin, 5),
                  m.make(m.OpGetOuter, 1, 1, 1),
                  m.make(m.OpCall, 0),
                  m.make(m.OpGetOuter, 1, 1, 0),
                  m.make(m.OpAdd),
                  m.make(m.OpCall, 1),
                  m.make(m.OpPop),
                  m.make(m.OpContinue)),
             vcat(m.make(m.OpGetGlobal, 0),
                  m.make(m.OpConstant, 2),
                  m.make(m.OpSub),
                  m.make(m.OpSetGlobal, 0),
                  m.make(m.OpConstant, 3),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpClosure, 4, 1),
                  m.make(m.OpSetLocal, 1),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpConstant, 5),
                  m.make(m.OpGreaterThan),
                  m.make(m.OpJumpNotTruthy, 44),
                  m.make(m.OpClosure, 7, 0),
                  m.make(m.OpCall, 0),
                  m.make(m.OpJumpNotTruthy, 44),
                  m.make(m.OpJump, 23),
                  m.make(m.OpNull),
                  m.make(m.OpPop),
                  m.make(m.OpContinue)),
         ],
         [
             m.make(m.OpConstant, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 1),
             m.make(m.OpGreaterThan),
             m.make(m.OpJumpNotTruthy, 28),
             m.make(m.OpClosure, 8, 0),
             m.make(m.OpCall, 0),
             m.make(m.OpJumpNotTruthy, 28),
             m.make(m.OpJump, 6),
             m.make(m.OpNull),
             m.make(m.OpPop),
         ]),
        ("""
         while (true) { 
             break;
             continue;
         }
         """,
         [vcat(m.make(m.OpBreak), m.make(m.OpContinue), m.make(m.OpContinue))],
         [
             m.make(m.OpTrue),
             m.make(m.OpJumpNotTruthy, 16),
             m.make(m.OpClosure, 0, 0),
             m.make(m.OpCall, 0),
             m.make(m.OpJumpNotTruthy, 16),
             m.make(m.OpJump, 0),
             m.make(m.OpNull),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Recursive Functions" begin for (input, expected_constants, expected_instructions) in [
        ("""
         let countDown = fn(x) { countDown(x - 1); };
         countDown(1);
         """,
         [
             1,
             vcat(m.make(m.OpCurrentClosure),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpConstant, 0),
                  m.make(m.OpSub),
                  m.make(m.OpCall, 1),
                  m.make(m.OpReturnValue)),
             1,
         ],
         [
             m.make(m.OpClosure, 1, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpConstant, 2),
             m.make(m.OpCall, 1),
             m.make(m.OpPop),
         ]),
        ("""
         let wrapper = fn() {
             let countDown = fn(x) { countDown(x - 1); };
             countDown(1);
         }
         wrapper();
         """,
         [
             1,
             vcat(m.make(m.OpCurrentClosure),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpConstant, 0),
                  m.make(m.OpSub),
                  m.make(m.OpCall, 1),
                  m.make(m.OpReturnValue)),
             1,
             vcat(m.make(m.OpClosure, 1, 0),
                  m.make(m.OpSetLocal, 0),
                  m.make(m.OpGetLocal, 0),
                  m.make(m.OpConstant, 2),
                  m.make(m.OpCall, 1),
                  m.make(m.OpReturnValue)),
         ],
         [
             m.make(m.OpClosure, 3, 0),
             m.make(m.OpSetGlobal, 0),
             m.make(m.OpGetGlobal, 0),
             m.make(m.OpCall, 0),
             m.make(m.OpPop),
         ]),
    ]
        run_compiler_tests(input, expected_constants, expected_instructions)
    end end

    @testset "Error handling" begin
        @test_throws ErrorException("unknown operator: &") begin
            c = m.Compiler()
            m.compile!(c,
                       m.InfixExpression(m.Token(m.PLUS, "+"),
                                         m.IntegerLiteral(m.Token(m.INT, "2"), 2),
                                         "&",
                                         m.IntegerLiteral(m.Token(m.INT, "2"), 2)))
        end

        @test_throws ErrorException("unknown operator: +") begin
            c = m.Compiler()
            m.compile!(c,
                       m.PrefixExpression(m.Token(m.PLUS, "+"),
                                          "+",
                                          m.IntegerLiteral(m.Token(m.INT, "2"), 2)))
        end
    end
end
