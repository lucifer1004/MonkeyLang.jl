# CHANGELOG

## [v0.2.1] - 2022-02-11

### Changed

- String macros `@monkey_eval_str`, `@monkey_vm_str` and `@monkey_julia_str` now support string interpolations.

## [v0.2.0] - 2022-02-04

### Added

- Transpile Monkey to Julia `Expr`.
- Support `while` loops, along with `break` and `continue`.
- Support mutable variables.
- `MonkeyLang.jl` can now be built into a standalone executable.
- Bytecode VM implemented according to [the Compiler Book](https://compilerbook.com). VM powered repl can be used with the newly added `use_vm` option of the `MonkeyLang.start_repl()` function.
- Macro system (`quote` / `unquote` / `macro`) implemented according to [the Lost Chapter](https://interpreterbook.com/lost/))
- `NullLiteral`
- `evaluate(::String)` for direct code evaluation (macros not supported yet)
- `Ctrl-C` (`SIGINT`) is handled elegantly.
- Many test cases. Code coverage is around 99% at the moment.

### Changed

- Improved error handling
- Monkey code can now be evaluated with IO redirected.
- Empty line (`\n`) will not cause the REPL to exit, while `Ctrl-D` (`EOF`) still works as before.
- Equality of `STRING`s can be corrected handled. (#d3ac)

### Removed

- Unnecessary GO-style dummy functions for type recognition.

## [v0.1.0] - 2022-01-15

The first release version.
