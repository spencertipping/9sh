# Fennel AST API Reference

This document provides a comprehensive reference for manipulating Fennel's Abstract Syntax Tree (AST), which is essential for writing advanced macros and compiler plugins.

> [!NOTE]
> This API is exposed via the `fennel` module. In macros, it is available as the global `fennel`.

## Core Concepts

Fennel AST nodes are generally **Standard Lua Tables** equipped with metatables that identify their type (List, Symbol, Sequence, etc.).
Source metadata (filename, line number, etc.) is stored directly as fields on these tables.

### Types and Constructors

| Type | Constructor | Predicate | Description |
|------|-------------|-----------|-------------|
| **Symbol** | `fennel.sym(name, [meta])` | `fennel.sym?(x)` | A symbol (e.g., `+`, `print`). The table contains the name as the first element. |
| **List** | `fennel.list(...)` | `fennel.list?(x)` | A list (parentheses). Used for function calls and forms. |
| **Sequence** | `fennel.sequence(...)` | `fennel.sequence?(x)` | A sequence (square brackets) or key-value table (curly braces). |
| **Comment** | `fennel.comment(content)` | `fennel.comment?(x)` | A comment. |
| **Vararg** | `fennel.varg([meta])` | `fennel.varg?(x)` | The `...` form. |

**Important:** Keywords (e.g., `:foo`) are represented as simple **Lua strings** (`"foo"`) in the AST, not as special objects.
> [!WARNING]
> Since keywords become simple strings, **macros cannot differentiate** between a user typing `:foo` and `"foo"`. They both arrive as the string `"foo"`. If you need to distinguish them, you would need to use a custom parser hook or a different syntax.

### Usage Examples

```fennel
;; Creating a symbol
(local s (fennel.sym "+"))

;; Creating a list: (+ 1 2)
(local l (fennel.list s 1 2))

;; Creating a sequence: [1 2 3]
(local seq (fennel.sequence 1 2 3))

;; Creating a key-value table: {:foo 1 :bar 2}
;; Just use a standard Lua table: Fennel treats plain tables as KV tables.
(local t {:foo 1 :bar 2})
```

> [!TIP]
> **Key-Value Tables:** There is no special constructor for `{}` tables because they are just standard Lua tables. If you need to attach metadata to one (like source location), you can manually `setmetatable` on it, but generally you just pass the table as-is. `fennel.sequence` is specifically for `[]` (ordered lists that are not function calls).

## Parsing

The parsing API allows you to convert Fennel source code strings into AST nodes.

### `fennel.parser(str, [filename], [options])`

Returns an iterator function that yields parsed values one by one.

**Returns:**
- Iterator function: Returns `(ok, val)` where `ok` is a boolean.
    - If `ok` is `true`, `val` is the AST node.
    - If `ok` is `false`, `val` is likely nil/done (the iterator handles errors internally or via pcall if not using `dosafely`).

```fennel
(let [parser (fennel.parser "(+ 1 2) :keyword")]
  (var (ok ast) (parser))
  ;; NOTE: We use (ok ast) because the parser returns Multiple Values.
  ;; If we used [ok ast], it would try to index the first value as a table!
  (while ok
    (print (fennel.view ast))
    (set (ok ast) (parser))))

> [!TIP]
> **Destructuring Syntax:**
> Since `fennel.parser` returns an iterator yielding multiple values, use `(ok val)`.

### Common Iterator Patterns

Since the parser returns an iterator, you will often use these patterns:

```fennel
;; 1. Using a loop (most common)
(let [parser (fennel.parser "(+ 1 2)")]
  (var (ok ast) (parser))
  (while ok
    (print (fennel.view ast))
    (set (ok ast) (parser))))

;; 2. Destructuring with 'let' (if you just want the first value)
(let [parser (fennel.parser "(one) (two)")
      (ok ast) (parser)]
   (print "First form:" ast))

;; 3. Manual stepping
(let [p (fennel.parser "1 2")]
  (match [(p)]
    [true val] (print "Got:" val)
    _          (print "Done")))
```

### Implementing Custom Iterators

You can create your own iterators to use with `(each)` or standard destructuring. The convention is a factory function that returns a closure.

```fennel
(fn range-iter [start end step]
  (var current (- start step))
  (fn []
    (set current (+ current step))
    (if (<= current end)
        (values current (* current current)) ;; Return multiple values
        nil)))

;; Usage with (each)
(each [val sq (range-iter 1 5 1)]
  (print "Value:" val "Square:" sq))

;; Usage with manual destructuring
(let [iter (range-iter 1 5 1)]
  (var (val sq) (iter))
  (while val
    (print val sq)
    (set (val sq) (iter))))
```

## Metadata & Source Tracking

Metadata is stored directly on the AST node tables.

- `filename`: The file where the node was defined.
- `line`: The line number (1-based).
- `col`: The column number (0-based byte offset from start of line?).
- `bytestart`, `byteend`: Byte offsets in the source file.

### `fennel.ast-source(node)`

Returns the table capable of holding metadata for the given node. For Symbols and Lists, this is the node itself. For primitives (like numbers or strings), it returns an empty table (or the object itself if it's a table-like) but since primitives can't hold fields, this is mostly useful for normalized access.

```fennel
(local s (fennel.sym "foo" {:filename "test.fnl" :line 42}))
(print s.filename) ;; "test.fnl"
(print s.line)     ;; 42
```

## Traversing and Introspection

### `fennel.view(x)`

Returns a string representation of the AST, formatted like Fennel code.

### `fennel.utils.walk-tree(root, f, [custom-iterator])`

> [!IMPORTANT]
> This function must be accessed via `(require :fennel.utils)`.

Walks the AST `root` recursively.
- `f(idx, node, parent)`: Function called for each node.
    - **Return true** to descend into the node's children.
    - **Return nil/false** to stop descending.
    - **CRITICAL:** You must check that `node` is a table before returning `true`, otherwise it will crash when trying to iterate a primitive!

```fennel
(local utils (require :fennel.utils))

(utils.walk-tree ast (fn [idx node parent]
  ;; Do something with node...
  (print idx node)

  ;; Return true ONLY if we want to descend AND it is a table
  (and (= (type node) "table")
       (not (should-skip? node)))))
```

> [!NOTE]
> By default, `walk-tree` uses `pairs`, so it will visit **all fields**, including metadata fields like `line`, `filename`, etc. If you only want to visit AST children, you should provide `ipairs` as the third argument (though this might miss key-value table keys).


- `fennel.eval(str, [options], ...)`: Evaluates a string of Fennel code.
- `fennel.dofile(filename, [options], ...)`: Runs a Fennel file.
- `fennel.version`: String containing the Fennel version.
- `fennel.metadata`: Table handling docstrings and other metadata for functions.

## Internal Metatables

While you generally use constructors, knowing the internal keys can be useful for deep debugging:
- **Lists** and **Symbols** have `__fennelview`.
- **Sequences** have a metatable with a `sequence` field set to a marker value.

```lua
-- From fennel.lua (approximate)
local list_mt = { "LIST", ... }
local symbol_mt = { "SYMBOL", ... }
```
