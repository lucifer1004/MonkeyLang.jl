@testset "Test VM" begin
    @testset "Integer Arithmetic" begin
        for (input, expected) in [
            ("1", 1),
            ("2", 2),
            ("1 + 2", 3),
            ("1 - 2", -1),
            ("1 * 2", 2),
            ("1 / 2", 0),
            ("50 / 2 * 2 + 10 - 5", 55),
            ("5 + 5 + 5 + 5 - 10", 10),
            ("2 * 2 * 2 * 2 * 2", 32),
            ("5 * 2 + 10", 20),
            ("5 + 2 * 10", 25),
            ("5 * (2 + 10)", 60),
            ("-5", -5),
            ("-10", -10),
            ("-50 + 100 + -50", 0),
            ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Boolean Expressions" begin
        for (input, expected) in [
            ("true", true),
            ("false", false),
            ("1 < 2", true),
            ("1 > 2", false),
            ("1 < 1", false),
            ("1 > 1", false),
            ("1 == 1", true),
            ("1 != 1", false),
            ("1 == 2", false),
            ("1 != 2", true),
            ("true == true", true),
            ("false == false", true),
            ("true == false", false),
            ("true != false", true),
            ("false != true", true),
            ("(1 < 2) == true", true),
            ("(1 < 2) == false", false),
            ("(1 > 2) == true", false),
            ("(1 > 2) == false", true),
            ("!true", false),
            ("!false", true),
            ("!5", false),
            ("!!true", true),
            ("!!false", false),
            ("!!5", true),
            ("\"monkey\"==\"monkey\"", true),
            ("\"monkey\"==\"monke\"", false),
            ("\"monkey\"!=\"monkey\"", false),
            ("\"monkey\"!=\"monke\"", true),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Conditionals" begin
        for (input, expected) in [
            ("if (true) { 10 }", 10),
            ("if (true) { 10 } else { 20 }", 10),
            ("if (false) { 10 } else { 20 }", 20),
            ("if (1) { 10 }", 10),
            ("if (1 < 2) { 10 }", 10),
            ("if (1 < 2) { 10 } else { 20 }", 10),
            ("if (1 > 2) { 10 } else { 20 }", 20),
            ("if (1 > 2) { 10 }", nothing),
            ("if (false) { 10 }", nothing),
            ("if ((if (false) { 10 })) { 10 } else { 20 }", 20),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Global Let Statements" begin
        for (input, expected) in [
            ("let one = 1; one", 1),
            ("let one = 1; let two = 2; one + two", 3),
            ("let one = 1; let two = one + one; one + two", 3),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "String Expressions" begin
        for (input, expected) in [
            ("\"monkey\"", "monkey"),
            ("\"mon\" + \"key\"", "monkey"),
            ("\"mon\" + \"key\" + \"banana\"", "monkeybanana"),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Array Literals" begin
        for (input, expected) in
            [("[]", []), ("[1, 2, 3]", [1, 2, 3]), ("[1 + 2, 3 * 4, 5 + 6]", [3, 12, 11])]
            @test test_vm(input, expected)
        end
    end

    @testset "Hash Literals" begin
        for (input, expected) in [
            ("{1: 2, 2: 3}", Dict(m.IntegerObj(1) => 2, m.IntegerObj(2) => 3)),
            (
                "{1 + 1: 2 * 2, 3 + 3: 4 * 4}",
                Dict(m.IntegerObj(2) => 4, m.IntegerObj(6) => 16),
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Index Expressions" begin
        for (input, expected) in [
            ("[1, 2, 3][1]", 2),
            ("[1, 2, 3][0 + 2]", 3),
            ("[[1, 1, 1]][0][0]", 1),
            ("[][0]", nothing),
            ("[1, 2, 3][99]", nothing),
            ("[1][-1]", nothing),
            ("{1: 1, 2: 2}[1]", 1),
            ("{1: 1, 2: 2}[2]", 2),
            ("{1: 1}[0]", nothing),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions" begin
        for (input, expected) in [
            ("let fivePlusTen = fn() { 5 + 10; }; fivePlusTen()", 15),
            (
                """
                let one = fn() { 1; };
                let two = fn() { 2; };
                one() + two()
                """,
                3,
            ),
            (
                """
                let a = fn() { 1; };
                let b = fn() { a() + 1; };
                let c = fn() { b() + 1; };
                c();
                """,
                3,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions With Return Statement" begin
        for (input, expected) in [
            (
                """
                let earlyExit = fn() { return 99; 100; };
                earlyExit();
                """,
                99,
            ),
            (
                """
                let earlyExit = fn() { return 99; return 100; };
                earlyExit();
                """,
                99,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions Without Return Value" begin
        for (input, expected) in [
            (
                """
                let noReturn = fn() { };
                noReturn();
                """,
                nothing,
            ),
            (
                """
                let noReturn = fn() { };
                let noReturnTwo = fn() { noReturn(); };
                noReturn();
                noReturnTwo();
                """,
                nothing,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "First Class Functions" begin
        for (input, expected) in [
            (
                """
                let returnsOne = fn() { 1 };
                let returnsOneReturner = fn() { returnsOne; };
                returnsOneReturner()();
                """,
                1,
            ),
            (
                """
                let returnsOneReturner = fn() { 
                  let returnsOne = fn() { 1; }; 
                  returnsOne;
                };
                returnsOneReturner()();
                """,
                1,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions With Bindings" begin
        for (input, expected) in [
            (
                """
                let one = fn() { let one = 1; one };
                one();
                """,
                1,
            ),
            (
                """
                let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
                oneAndTwo();
                """,
                3,
            ),
            (
                """
                let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
                let threeAndFour = fn() { let three = 3; let four = 4; three + four; };
                oneAndTwo() + threeAndFour();
                """,
                10,
            ),
            (
                """
                let firstFoobar = fn() { let foobar = 50; foobar; };
                let secondFooBar = fn() { let fooBar = 100; fooBar; };
                firstFoobar() + secondFooBar();
                """,
                150,
            ),
            (
                """
                let globalSeed = 50;
                let minusOne = fn() { 
                  let num = 1;
                  globalSeed - num;
                }
                let minusTwo = fn() {
                  let num = 2;
                  globalSeed - num;
                }
                minusOne() + minusTwo();
                """,
                97,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions With Arguments And Bindings" begin
        for (input, expected) in [
            (
                """
                let identity = fn(a) { a; };
                identity(4);
                """,
                4,
            ),
            (
                """
                let sum = fn(a, b) { a + b; };
                sum(1, 2);
                """,
                3,
            ),
            (
                """
                let sum = fn(a, b) { 
                    let c = a + b;
                    c; 
                };
                sum(1, 2);
                """,
                3,
            ),
            (
                """
                let sum = fn(a, b) { 
                    let c = a + b;
                    c; 
                };
                sum(1, 2) + sum(3, 4);
                """,
                10,
            ),
            (
                """
                let sum = fn(a, b) { 
                    let c = a + b;
                    c; 
                };
                let outer = fn() {
                    sum(1, 2) + sum(3, 4);
                };
                outer();
                """,
                10,
            ),
            (
                """
                let globalNum = 10;

                let sum = fn(a, b) { 
                    let c = a + b;
                    c + globalNum;
                };

                let outer = fn() {
                    sum(1, 2) + sum(3, 4) + globalNum;
                };
                outer() + globalNum;
                """,
                50,
            ),
        ]
            @test test_vm(input, expected)
        end
    end

    @testset "Calling Functions With Wrong Arguments" begin
        for (input, expected) in [
            (
                "fn() { 1; }(1);",
                "wrong number of arguments: expected 0, got 1",
            ),
            (
                "fn(a) { a; }();",
                "wrong number of arguments: expected 1, got 0",
            ),
            (
                "fn(a, b) { a + b; }(1);",
                "wrong number of arguments: expected 2, got 1",
            ),
        ]
            @test_throws ErrorException(expected) test_vm(input, expected)
        end
    end
end
