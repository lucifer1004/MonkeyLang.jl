import Pkg;
Pkg.instantiate();

using BenchmarkTools
using MonkeyLang

const m = MonkeyLang

upper = 35

function fib(x)
    if x == 0
        0
    else
        if x == 1
            1
        else
            fib(x - 1) + fib(x - 2)
        end
    end
end

naive = """
let fibonacci = fn(x) {
    if (x == 0) {
        0
    } else {
        if (x == 1) {
            1
        } else {
            fibonacci(x - 1) + fibonacci(x - 2);
        }
    }
};

fibonacci($upper);
"""

tailrec = """
let fibonacci = fn(x, a, b) {
    if (x == 1) {
        b
    } else {
        fibonacci(x - 1, b, a + b)
    }
};

fibonacci($upper);
"""

memoized = """
let d = {};

let fibonacci = fn(x) {
    if (x == 0) {
        0
    } else {
        if (x == 1) {
            1;
        } else {
            if (type(d[x]) == "NULL") {
                let g = fibonacci(x - 1) + fibonacci(x - 2);
                d = push(d, x, g);
            }

            d[x];
        }
    }
}

fibonacci($upper);
"""

dp = """
let fibonacci = fn(x) {
    let i = 2;
    let a = 0;
    let b = 1;

    while (!(i > x)) {
        let c = a + b;
        a = b;
        b = c;
        i = i + 1;
    }

    b;
}

fibonacci($upper);
"""

println("=== Julia native ===")
@btime fib($upper)

println("=== Using evaluator (naive) ===")
@btime m.evaluate($naive)

println("=== Using compiler (naive) ===")
@btime m.run($naive)

println("=== Using Julia as the Backend (naive) ===")
@btime m.Transpilers.JuliaTranspiler.run($naive)

println("=== Using evaluator (tailrec) ===")
@btime m.evaluate($tailrec)

println("=== Using compiler (tailrec) ===")
@btime m.run($tailrec)

println("=== Using Julia as the Backend ===")
@btime m.Transpilers.JuliaTranspiler.run($tailrec)

println("=== Using evaluator (memoized) ===")
@btime m.evaluate($memoized)

println("=== Using compiler (memoized) ===")
@btime m.run($memoized)

println("=== Using Julia as the Backend ===")
@btime m.Transpilers.JuliaTranspiler.run($memoized)

println("=== Using evaluator (dp) ===")
@btime m.evaluate($dp)

println("=== Using compiler (dp) ===")
@btime m.run($dp)

println("=== Using Julia as the Backend ===")
@btime m.Transpilers.JuliaTranspiler.run($dp)
