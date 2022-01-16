# MonkeyLang

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://lucifer1004.github.io/MonkeyLang.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://lucifer1004.github.io/MonkeyLang.jl/dev)
[![Build Status](https://github.com/lucifer1004/MonkeyLang.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/lucifer1004/MonkeyLang.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/lucifer1004/MonkeyLang.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/lucifer1004/MonkeyLang.jl)

> Monkey Programming Language written in Julia.

## Start the REPL

```julia
import Pkg; Pkg.add(url="https://github.com/lucifer1004/MonkeyLang.jl")

using MonkeyLang

MonkeyLang.start_repl()
```

You can enter a blank line to exit the REPL.

## Documentation

I created the document with reference to [Writing An Interpreter In Go][writing-an-interpreter-in-go] and [rs-monkey-lang](https://github.com/wadackel/rs-monkey-lang).  

:warning: **Please note that there may be some mistakes.**

### Table of Contents

- [Summary](#summary)
- [Syntax overview](#syntax-overview)
    - [If](#if)
    - [Operators](#operators)
    - [Return](#return)
- [Variable bindings](#variable-bindings)
- [Literals](#literals)
    - [INTEGER](#integer)
    - [BOOLEAN](#boolean)
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

### Summary

- C-like syntax
- variable bindings
- first-class and higher-order functions • closures
- arithmetic expressions
- built-in functions

### Syntax overview

An example of Fibonacci function.

```
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

It supports the general `if`. `else` exists, but` else if` does not exist.

```
if (true) {
  10;
} else {
  5;
}
```

#### Operators

It supports the general operations.

```
1 + 2 + (3 * 4) - (10 / 5);
!true;
!false;
+10;
-5;
"Hello" + " " + "World";
```

#### Return

It returns the value immediately. No further processing will be executed.

```
if (true) {
  return;
}
```

```
let identity = fn(x) {
  return x;
};

identity("Monkey");
```

### Variable bindings

Variable bindings, such as those supported by many programming languages, are implemented. Variables can be defined using the `let` keyword.

**Format:**

```
let <identifier> = <expression>;
```

**Example:**

```
let x = 0;
let y = 10;
let foobar = add(5, 5);
let alias = foobar;
let identity = fn(x) { x };
```

### Literals

Five types of literals are implemented.

#### INTEGER

`INTEGER` represents an integer value. Floating point numbers can not be handled.

**Format:**

```
[-+]?[1-9][0-9]*;
```

**Example:**

```
10;
1234;
```

#### BOOLEAN

`BOOLEAN` represents a general boolean types.

**Format:**

```
true | false;
```

**Example:**

```julia
true;
false;

let truthy = !false;
let falsy = !true;
```

#### STRING

`STRING` represents a string. Only double quotes can be used.

`STRING`s can be concatenated with `"+"`.

**Format:**

```
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

```
[<expression>, <expression>, ...];
```

**Example:**

```
[1, 2, 3 + 3, fn(x) { x }, add(2, 2), true];
```

```
let arr = [1, true, fn(x) { x }];

arr[0];
arr[1];
arr[2](10);
arr[1 + 1](10);
```

#### HASH

`HASH` expresses data associating keys with values.

**Format:**

```
{ <expression>: <expression>, <expression>: <expression>, ... };
```

**Example:**

```
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

```
fn (<parameter one>, <parameter two>, ...) { <block statement> };
```

**Example:**

```
let add = fn(x, y) {
  return x + y;
};

add(10, 20);
```

```
let add = fn(x, y) {
  x + y;
};

add(10, 20);
```

If `return` does not exist, it returns the result of the last evaluated expression.

```
let addThree = fn(x) { x + 3 };
let callTwoTimes = fn(x, f) { f(f(x)) };

callTwoTimes(3, addThree);
```

Passing around functions, higher-order functions and closures will also work.

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

---

Enjoy Monkey :monkey_face: !

---

[writing-an-interpreter-in-go]: https://interpreterbook.com/#the-monkey-programming-language