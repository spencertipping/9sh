# Fennel Macro Semantics and Injection

This document details how to manage macro visibility, injection, and namespacing in Fennel, specifically for embedded environments where the host (C++/Lua) needs to provide macros to user scripts.

> [!NOTE]
> All examples assume `fennel` is the loaded Fennel module (e.g., `require("fennel")`).

## 1. Macro Injection Strategies

There are two primary ways to expose host-defined macros to a script: **Scope Injection** (implicit availability) and **Macro Searchers** (explicit import).

### A. Scope Injection (Implicit)

This is the preferred method for "injecting macro definitions into a script" so they are available by default without the user needing to `import-macros`.

You can create a compilation scope, populate it with macros, and pass it to `fennel.compileString` (or `fennel.compile`).

```lua
local fennel = require("fennel")

-- 1. Create a scope
local scope = fennel.scope()

-- 2. Define a macro
-- Macros are functions that accept AST nodes and return AST nodes.
scope.macros["my-macro"] = function(arg_ast)
    -- Must return a valid Fennel AST (use fennel.list, fennel.sym, etc.)
    return fennel.list(fennel.sym("print"), "expanded:", arg_ast)
end

-- 3. Compile with the scope
local code = "(my-macro 123)"
local lua_code = fennel.compileString(code, { scope = scope })
-- Output: print("expanded:", 123)
```

**Namespacing in Scope:**
You can inject namespaced macros using dotted keys or nested tables:

```lua
-- Option 1: Dotted key
scope.macros["my.macro"] = function(...) ... end
-- Usage: (my.macro ...)

-- Option 2: Nested table
scope.macros["pkg"] = {
    func = function(...) ... end
}
-- Usage: (pkg.func ...)
```

### B. Virtual Modules (Explicit Import)

If you want users to explicitly import macros using `(import-macros ... :my-lib)`, you can register a "virtual" macro module using `fennel.macro-searchers`.

```lua
-- A searcher function receives the module name.
-- It returns a LOADER function if it finds the module, or nil.
local function virtual_macro_searcher(module_name)
    if module_name == "my-dsl" then
        return function(mod_name)
            return {
                -- Table of macros
                ["log"] = function(msg)
                    return fennel.list(fennel.sym("print"), "[LOG]", msg)
                end
            }
        end
    end
end

table.insert(fennel["macro-searchers"], virtual_macro_searcher)
```

**Usage in Fennel:**
```fennel
(import-macros {: log} :my-dsl)
(log "hello")
```

## 2. AST Construction

When writing macros in Lua (host side), you must construct proper Fennel AST nodes. Returning simple Lua tables `{ "print", "hi" }` results in a **Sequence** (compiled to a table literal), not a **List** (compiled to a function call).

Use the API provided by `fennel`:

| AST Type | Constructor | Lua Example | Fennel Equivalent |
|----------|-------------|-------------|-------------------|
| **Symbol** | `fennel.sym(name)` | `fennel.sym("print")` | `print` |
| **List** | `fennel.list(...)` | `fennel.list(sym("print"), "hi")` | `(print "hi")` |
| **Sequence** | `fennel.sequence(...)` | `fennel.sequence("a", "b")` | `["a" "b"]` |
| **Varg** | `fennel.varg()` | `fennel.varg()` | `...` |

**Example:**
```lua
local function my_macro(x)
    -- Incorrect: Returns { "print", x } -> ["print" x] (Table/Sequence)
    -- return { fennel.sym("print"), x }

    -- Correct: Returns (print x) -> print(x) (Function Call)
    return fennel.list(fennel.sym("print"), x)
end
```

## 3. Visibility and Shadowing

*   **Scope Injection**: Macros in the passed `scope` are available at the top level of the script.
*   **Shadowing**: `import-macros` inside the script **will shadow** injected macros if names collide.
*   **Sub-scopes**: Injected macros are visible in sub-scopes (e.g., inside `Let` or `Fn`), subject to standard lexical scoping rules.

### Persistence
The `scope` object passed to `compileString` is modified during compilation (it tracks new variables, etc.). Reusing the same `scope` object across multiple `compileString` calls *might* retain state (like `var` declarations) depending on how deep the integration is, but generally `macros` persistence is safe if you just modify `scope.macros`.

## 4. API Reference Summary

*   `fennel.compileString(str, options)`: options can include `{ scope = ... }`.
*   `fennel.scope()`: Creates a new, empty scope structure.
*   `scope.macros`: Table `{[name] = macro_function}`.
*   `fennel["macro-searchers"]`: List of `function(name) -> loader_node | nil`.
*   `fennel.list`, `fennel.sym`: Essential checks for macro AST generation.
