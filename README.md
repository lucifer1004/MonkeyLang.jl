# MonkeyLang

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://lucifer1004.github.io/MonkeyLang.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://lucifer1004.github.io/MonkeyLang.jl/dev)
[![Build Status](https://github.com/lucifer1004/MonkeyLang.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/lucifer1004/MonkeyLang.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/lucifer1004/MonkeyLang.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/lucifer1004/MonkeyLang.jl)
[![wakatime](https://wakatime.com/badge/github/lucifer1004/MonkeyLang.jl.svg)](https://wakatime.com/badge/github/lucifer1004/MonkeyLang.jl)

> Monkey Programming Language written in Julia.

**Table of Contents**

- [MonkeyLang](#monkeylang)
  - [Compile MonkeyLang.jl to a standalone executable](#compile-monkeylangjl-to-a-standalone-executable)
  - [Start the REPL](#start-the-repl)
  - [Documentation](#documentation)
    - [Summary](#summary)
    - [Syntax overview](#syntax-overview)
      - [If](#if)
      - [While](#while)
      - [Operators](#operators)
      - [Return](#return)
    - [Variable bindings](#variable-bindings)
    - [Scopes](#scopes)
      - [Global Scope](#global-scope)
      - [Local Scope](#local-scope)
      - [Closure Scope](#closure-scope)
      - [CurrentClosure Scope](#currentclosure-scope)
    - [Literals](#literals)
      - [INTEGER](#integer)
      - [BOOLEAN](#boolean)
      - [NULL](#null)
      - [STRING](#string)
      - [ARRAY](#array)
      - [HASH](#hash)
      - [FUNCTION](#function)
    - [Built-in Functions](#built-in-functions)
      - [`type(<arg1>): STRING`](#typearg1-string)
      - [`puts(<arg1>, <arg2>, ...): NULL`](#putsarg1-arg2--null)
      - [`len(<arg>): INTEGER`](#lenarg-integer)
      - [`first(<arg: STRING>): STRING | NULL`](#firstarg-string-string--null)
      - [`first(<arg: Array>): any`](#firstarg-array-any)
      - [`last(<arg: String>): STRING | NULL`](#lastarg-string-string--null)
      - [`last(<arg: Array>): any`](#lastarg-array-any)
      - [`rest(<arg: STRING>): STRING | NULL`](#restarg-string-string--null)
      - [`rest(<arg: ARRAY>): ARRAY | NULL`](#restarg-array-array--null)
      - [`push(<arg1: ARRAY>, <arg2>): ARRAY`](#pusharg1-array-arg2-array)
      - [`push(<arg1: HASH>, <arg2>, <arg3>): HASH`](#pusharg1-hash-arg2-arg3-hash)
    - [Advanced examples](#advanced-examples)
      - [A custom `map` function](#a-custom-map-function)
      - [A custom `reduce` function](#a-custom-reduce-function)
    - [Macro System](#macro-system)

## Compile MonkeyLang.jl to a standalone executable

Clone the repo, and run `make build` in the root directory.

> Caution: The compilation may take up to ~5 minutes.

## Start the REPL

You can start the REPL in a Julia script or in the Julia REPL:

```julia
import Pkg; Pkg.add("MonkeyLang")

using MonkeyLang

MonkeyLang.start_repl()
MonkeyLang.start_repl(; use_vm = true) # use VM
```

You can press `Ctrl-C` or `Ctrl-D` to exit the REPL.

If you have compiled `MonkeyLang.jl` locally, then you can directly start the REPL by:

```sh
./monkey repl
./monkey repl --vm # use VM
```

## Documentation

I created the document with reference to [Writing An Interpreter In Go][writing-an-interpreter-in-go] and [rs-monkey-lang](https://github.com/wadackel/rs-monkey-lang).  

:warning: **Please note that there may be some mistakes.**

### Summary

- C-like syntax
- variable bindings
- first-class and higher-order functions • closures
- arithmetic expressions
- built-in functions

### Syntax overview

An example of Fibonacci function.

```julia
let fibonacci = fn(x) {
  if (x == 0) {
    0;
  } else {
    if (x == 1) {
      1;
    } else {
      fibonacci(x - 1) + fibonacci(x - 2);
    }
  }
};

fibonacci(10);
```

#### If

It supports the general `if`. `else` exists, but `else if` does not exist.

```julia
if (true) {
  10;
} else {
  5;
}
```

#### While

It also supports `while` loops.

```julia
let x = 5;
while (x > 0) {
  puts(x);
  x = x - 1;
}
```

#### Operators

It supports the general operations.

```julia
1 + 2 + (3 * 4) - (10 / 5);
!true;
!false;
+10;
-5;
"Hello" + " " + "World";
```

#### Return

It returns the value immediately. No further processing will be executed.

```julia
if (true) {
  return;
}
```

```julia
let identity = fn(x) {
  return x;
};

identity("Monkey");
```

### Variable bindings

Variable bindings, such as those supported by many programming languages, are implemented. Variables can be defined using the `let` keyword. Variables cannot be redefined in the same scope, but they can be reassigned.

**Format:**

```julia
let <identifier> = <expression>; # Define

<identifier> = <expression>; # Reassign
```

**Example:**

```julia
let x = 0;
let y = 10;
let foobar = add(5, 5);
let alias = foobar;
let identity = fn(x) { x };

x = x + 1;
y = x - y;
```

### Scopes

In Monkey, there are types of scopes:

#### Global Scope

Variables defined at the top level are visible everywhere, and can be modified from anywhere. 

```julia
let x = 2; # `x` is a global variable

let f = fn() { 
  let g = fn() { 
    x = x + 1; # Modifies the global variable `x`
    return x; 
  } 
  return g; 
}

let g = f();
puts(g()); # 3
puts(g()); # 4

let h = f();
puts(h()); # 5
puts(h()); # 6
```

#### Local Scope

Variables defined within while loops or functions are of this scope. They can be modified from the same scope, or inner while loops' scopes.

```julia
let x = 1;

while (x > 0) {
  x = x - 1;
  let y = 1; # `y` is a local variable
  while (y > 0) {
    y = y - 1; # Modifies the local variable `y`
  }
  puts(y); # 0
}
```

#### Closure Scope

A function captures all non-global variables visible to it as its free variables. These variables can be modified from within the function.

```julia
let f = fn() { 
  let x = 2; 
  let g = fn() { 
    x = x + 1; # `x` is captured as a free variable
    return x; 
  } 
  return g; 
}

let g = f();
puts(g()); # 3
puts(g()); # 4

let h = f();
puts(h()); # 3, since in function `f`, `x` remains unchanged.
puts(h()); # 4
```

#### CurrentClosure Scope

Specially, a named function being defined is of this scope. It cannot be modified from within its body.

```julia
let f = fn(x) {
  f = 3; # ERROR: cannot reassign the current function being defined: f
}
```

But redefinition is OK:

```julia
let f = fn(x) {
  let f = x + x;
  puts(f);
}

f(3); 
```

### Literals

Five types of literals are implemented.

#### INTEGER

`INTEGER` represents an integer value. Floating point numbers can not be handled.

**Format:**

```julia
[-+]?[1-9][0-9]*;
```

**Example:**

```julia
10;
1234;
```

#### BOOLEAN

`BOOLEAN` represents a boolean value.

**Format:**

```julia
true | false;
```

**Example:**

```julia
true;
false;

let truthy = !false;
let falsy = !true;
```

#### NULL

`NULL` represents null. When used as a condition, `NULL` is evaluated as falsy.

**Format:**

```julia
null;
```

**Example:**

```julia
if (null) { 2 } else { 3 }; # 3
```

#### STRING

`STRING` represents a string. Only double quotes can be used.

`STRING`s can be concatenated with `"+"`.

**Format:**

```julia
"<value>";
```

**Example:**

```julia
"Monkey Programming Language"; # "Monkey Programming Language";
"Hello" + " " + "World"; # "Hello World"
```

#### ARRAY

`ARRAY` represents an ordered contiguous element. Each element can contain different data types.

**Format:**

```julia
[<expression>, <expression>, ...];
```

**Example:**

```julia
[1, 2, 3 + 3, fn(x) { x }, add(2, 2), true];
```

```julia
let arr = [1, true, fn(x) { x }];

arr[0];
arr[1];
arr[2](10);
arr[1 + 1](10);
```

#### HASH

`HASH` expresses data associating keys with values.

**Format:**

```julia
{ <expression>: <expression>, <expression>: <expression>, ... };
```

**Example:**

```julia
let hash = {
  "name": "Jimmy",
  "age": 72,
  true: "a boolean",
  99: "an integer"
};

hash["name"];
hash["a" + "ge"];
hash[true];
hash[99];
hash[100 - 1];
```

#### FUNCTION

`FUNCTION` supports functions like those supported by other programming languages.

**Format:**

```julia
fn (<parameter one>, <parameter two>, ...) { <block statement> };
```

**Example:**

```julia
let add = fn(x, y) {
  return x + y;
};

add(10, 20);
```

```julia
let add = fn(x, y) {
  x + y;
};

add(10, 20);
```

If `return` does not exist, it returns the result of the last evaluated expression.

```julia
let addThree = fn(x) { x + 3 };
let callTwoTimes = fn(x, f) { f(f(x)) };

callTwoTimes(3, addThree);
```

Passing around functions, higher-order functions and closures will also work.

> The evaluation order of function parameters is **left to right**.

So a memoized Fibonacci function should be implemented like:

```julia
let d = {}

let fibonacci = fn(x) {
    if (x == 0) {
        0
    } else {
        if (x == 1) {
            1;
        } else {
            if (type(d[x]) == "NULL") {
                # You cannot use `d = push(d, x, fibonacci(x - 1) + fibonacci(x - 2))`
                # since `d` is evaluated first, which means it will not be updated
                # when `fibonacci(x - 1)` and `fibonacci(x - 2)` are called.
                let g = fibonacci(x - 1) + fibonacci(x - 2);
                d = push(d, x, g);
            }

            d[x];
        }
    }
};

fibonacci(35);
```

### Built-in Functions

You can use the following built-in functions :rocket:

#### `type(<arg1>): STRING`

Return the type of `arg1` as a `STRING`.

```julia
type(1); # INTEGER
type("123"); # STRING
type(false); # BOOLEAN
```

#### `puts(<arg1>, <arg2>, ...): NULL`

It outputs the specified value to `stdout`. In the case of Playground, it is output to `console`.

```julia
puts("Hello");
puts("World!");
```

#### `len(<arg>): INTEGER`

For `STRING`, it returns the number of characters. If it's `ARRAY`, it returns the number of elements.

```julia
len("Monkey"); # 6
len([0, 1, 2]); # 3
```

#### `first(<arg: STRING>): STRING | NULL`

Returns the character at the beginning of a `STRING`. If the `STRING` is empty, return `NULL` instead.

```julia
first("123"); # "1"
first(""); # null
```

#### `first(<arg: Array>): any`

Returns the element at the beginning of an `ARRAY`. If the `ARRAY` is empty, return `NULL` instead.

```julia
first([0, 1, 2]); # 0
first([]); # null
```

#### `last(<arg: String>): STRING | NULL`

Returns the element at the last of a `STRING`. If the `STRING` is empty, return `NULL` instead.

```julia
last("123"); # "3"
last(""); # null
```

#### `last(<arg: Array>): any`

Returns the element at the last of an `ARRAY`. If the `ARRAY` is empty, return `NULL` instead.

```julia
last([0, 1, 2]); # 2
last([]) # null
```

#### `rest(<arg: STRING>): STRING | NULL`

Returns a new `STRING` with the first element removed. If the `STRING` is empty, return `Null` instead.

```julia
rest("123"); # "23"
rest(""); # null
```

#### `rest(<arg: ARRAY>): ARRAY | NULL`

Returns a new `ARRAY` with the first element removed. If the `ARRAY` is empty, return `NULL` instead.

```julia
rest([0, 1, 2]); # [1, 2]
rest([]); # null
```

#### `push(<arg1: ARRAY>, <arg2>): ARRAY`

Returns a new `ARRAY` with the element specified at the end added.

```julia
push([0, 1], 2); # [0, 1, 2]
```

#### `push(<arg1: HASH>, <arg2>, <arg3>): HASH`

Returns a new `HASH` with `arg2: arg3` added. If `arg2` already exists, the value will be updated with `arg3`.

```julia
push({0: 1}, 1, 2); # {1:2, 0:1}
push({0: 1}, 0, 3); # {0:3}
```

### Advanced examples

#### A custom `map` function

```julia
let map = fn(arr, f) {
  let iter = fn(arr, accumulated) { 
    if (len(arr) == 0) {  
      accumulated 
    } else { 
      iter(rest(arr), push(accumulated, f(first(arr)))); 
    } 
  };

  iter(arr, []);
};

let a = [1, 2, 3, 4];
let double = fn(x) { x * 2};
map(a, double); # [2, 4, 6, 8]
```

#### A custom `reduce` function

```julia
let reduce = fn(arr, initial, f) {
  let iter = fn(arr, result) {
    if (len(arr) == 0) {
      result
    } else { 
      iter(rest(arr), f(result, first(arr)))
    }
  }

  iter(arr, initial)
}

let sum = fn(arr) { 
  reduce(arr, 0, fn(initial, el) { initial + el })
}

sum([1, 2, 3, 4, 5]); # 15
```

### Macro System

Now that the [Lost Chapter](https://interpreterbook.com/lost/) has been implemented, `MonkeyLang.jl` provides a powerful macro system.

Here is an example:

```julia
let unless = macro(condition, consequence, alternative) {
    quote(if (!(unquote(condition))) {
        unquote(consequence);
    } else {
        unquote(alternative);
    });
};

unless(10 > 5, puts("not greater"), puts("greater")); # greater
```

> In the REPL, you need to enter all the contents in a single line without `\n` characters.

---

Enjoy Monkey :monkey_face: !

---

[writing-an-interpreter-in-go]: https://interpreterbook.com/#the-monkey-programming-language
