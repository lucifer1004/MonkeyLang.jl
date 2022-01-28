using BenchmarkTools
using MonkeyLang

const m = MonkeyLang

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

println("=== Julia native ===")
@btime fib(15)

println("=== Using evaluator ===")
@btime m.evaluate($input)

println("=== Using compiler ===")
@btime m.run($input)
