import Pkg;
Pkg.instantiate();

using BenchmarkTools
using MonkeyLang

const m = MonkeyLang

upper = 35

fib(x) = begin
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
            return 1;
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

println("=== Using evaluator ===")
@btime m.evaluate($naive)

println("=== Using compiler ===")
@btime m.run($naive)

println("=== Using evaluator (tailrec) ===")
@btime m.evaluate($tailrec)

println("=== Using compiler (tailrec) ===")
@btime m.run($tailrec)

println("=== Using evaluator (memoized) ===")
@btime m.evaluate($memoized)

println("=== Using compiler (memoized) ===")
@btime m.run($memoized)

println("=== Using evaluator (dp) ===")
@btime m.evaluate($dp)

println("=== Using compiler (dp) ===")
@btime m.run($dp)
