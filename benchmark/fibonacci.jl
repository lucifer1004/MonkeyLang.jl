using BenchmarkTools
using MonkeyLang

const m = MonkeyLang

input = """
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

fibonacci(15);
"""

println("=== Using evaluator ===")
@btime m.evaluate($input)

println("=== Using compiler ===")
@btime m.run($input)
