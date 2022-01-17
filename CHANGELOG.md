# CHANGELOG

## [v0.2.0] - Unreleased

### Added

- macro system (`quote` / `unquote` / `macro`) implemented according to [the Lost Chapter](https://interpreterbook.com/lost/))
- `NullLiteral`
- `evaluate(::String)` for direct code evaluation (macros not supported yet)
- `Ctrl-C` (`SIGINT`) is handled elegantly.
- Many test cases. Code coverage is around 99% at the moment.

### Changed

- Improved error handling
- Monkey code can now be evaluated with IO redirected.
- Empty line (`\n`) will not cause the REPL to exit, while `Ctrl-D` (`EOF`) still works as before.

### Removed

- Unnecessary GO-style dummy functions for type recognition.


## [v0.1.0] - 2022-01-15

The first release version.
