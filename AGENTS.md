# MonkeyLang.jl - AI Coding Guide

## Project Overview

MonkeyLang.jl is a Julia implementation of the Monkey programming language, based on Thorsten Ball's "Writing An Interpreter In Go" and "Writing A Compiler In Go".

**Dual Backend Architecture**:
1. **Tree-walking Interpreter** (`evaluator.jl`) - Direct AST traversal execution
2. **Bytecode VM** (`compiler.jl` + `vm.jl`) - Compile to bytecode then execute

## Core Data Flow

```
Source Code → Lexer → Token Stream → Parser → AST → [Analyzer] → Evaluator/Compiler+VM → Result
```

## File Structure & Responsibilities

### Frontend (Lexical/Syntax Analysis)

| File | Responsibility | Key Structures |
|------|----------------|----------------|
| `token.jl` | Token type definitions | `@enum TokenType`, `Token`, `KEYWORDS` |
| `lexer.jl` | Lexical analysis | `Lexer`, `next_token!()` |
| `ast.jl` | AST node definitions | `Node`, `Statement`, `Expression` and subtypes |
| `parser.jl` | Pratt Parser | `Parser`, `parse!()`, `parse_*!()` functions |

### Runtime Objects

| File | Responsibility | Key Structures |
|------|----------------|----------------|
| `object.jl` | Runtime objects | `Object` and subtypes (`IntegerObj`, `StringObj`, ...) |
| `builtins.jl` | Built-in functions | `BUILTINS` array: `len`, `first`, `last`, `rest`, `push`, `puts`, `type` |

### Backend

| File | Responsibility | Key Structures |
|------|----------------|----------------|
| `evaluator.jl` | Tree-walking interpreter | `evaluate()` with multiple dispatch |
| `code.jl` | Bytecode definitions | `OpCode`, `Instructions` |
| `symbol_table.jl` | Symbol table | `Symbol`, `SymbolTable` |
| `compiler.jl` | Bytecode compiler | `Compiler`, `compile!()` |
| `vm.jl` | Virtual machine | `VM`, `run!()` |

### Auxiliary Modules

| File | Responsibility |
|------|----------------|
| `analyzer.jl` | Semantic analysis (variable reference checking, etc.) |
| `ast_modify.jl` | AST traversal/modification (for macro expansion) |
| `repl.jl` | REPL interaction |
| `cli.jl` | Command-line interface |
| `transpilers/` | Transpilers (e.g., to Julia) |

## Adding New Features

### 1. Adding a New Token (e.g., comments, new keywords)

**Files to modify**: `token.jl`

```julia
# 1. Add to @enum TokenType
@enum TokenType ... COMMENT ...

# 2. If it's a keyword, add to KEYWORDS dict
const KEYWORDS = Dict{String, TokenType}(
    ...
    "newkeyword" => NEWKEYWORD,
)
```

### 2. Adding Lexer Rules

**Files to modify**: `lexer.jl` - `next_token!()` function

```julia
function next_token!(l::Lexer)
    skip_whitespace!(l)
    ch = read_char(l)
    if ch == '#'  # New single-char handling
        # Processing logic
    elseif ...
```

### 3. Adding New Syntax

**Files to modify**:
1. `ast.jl` - Define new AST node
2. `parser.jl` - Register prefix/infix parse functions

```julia
# ast.jl
struct NewExpression <: Expression
    token::Token
    # other fields
end

# parser.jl - Register in Parser constructor
register_prefix!(p, NEW_TOKEN, parse_new_expression!)

# parser.jl - Implement parse function
function parse_new_expression!(p::Parser)
    # parsing logic
end
```

### 4. Adding Runtime Behavior

**Files to modify**:
- `evaluator.jl` - Add `evaluate()` method
- `compiler.jl` + `vm.jl` - Add compile and execution logic

```julia
# evaluator.jl
function evaluate(node::NewExpression, env::Environment)
    # evaluation logic
end
```

### 5. Adding Built-in Functions

**Files to modify**: `builtins.jl`

```julia
const BUILTINS = [
    ...
    "newbuiltin" => Builtin(function (args::Vararg{Object}; env::Environment = Environment())
        # implementation
    end),
]
```

## Testing Conventions

- Test files in `test/` directory
- Use `@testset` for organization
- Naming format: `<module>_test.jl`
- Run tests: `julia --project -e 'using Pkg; Pkg.test()'`

## Monkey Language Features

### Supported
- Variable binding: `let x = 5;`
- Reassignment: `x = 10;`
- Functions: `fn(x, y) { x + y }`
- Control flow: `if/else`, `while`, `break`, `continue`
- Data types: integers, booleans, strings, arrays, hash maps, null
- Closures
- Macro system: `macro`, `quote`, `unquote`
- Single-line comments: `# this is a comment`
- Token position tracking: line and column numbers

### Open Issues (To Be Implemented)
- `#11`: `const` immutable variables
- `#4`: `include()` built-in function
- `#1`: Nested macros
- `#27`: Type system

## Code Style

- Julia standard style
- Mutating functions end with `!`
- Prefer multiple dispatch over if-else type checking
- Concise over verbose
