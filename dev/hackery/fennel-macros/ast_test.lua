local fennel = dofile("/home/spencertipping/r/public/9sh/src/fennel.lua")

print("Checking AST constructors in fennel module:")
print("fennel.list:", fennel.list)
print("fennel.sym:", fennel.sym)
print("fennel.sequence:", fennel.sequence)
print("fennel.varg:", fennel.varg) -- maybe?

-- Utility to inspect scope
local function inspect_scope(s)
   print("Scope macros keys:", table.concat(vim and vim.tbl_keys(s.macros) or {}, ", "))
end

-- Test Macro Namespacing
local scope = fennel.scope()

-- 1. Dotted name in macros table
scope.macros["my.macro"] = function(x)
   return fennel.list(fennel.sym("print"), "dotted macro called")
end

-- 2. Nested table in macros
scope.macros["nested"] = {
   ["macro"] = function(x)
      return fennel.list(fennel.sym("print"), "nested macro called")
   end
}

local code_dotted = "(my.macro 1)"
local code_nested = "(nested.macro 1)"

print("\n--- Testing Dotted Name ---")
local ok, res = pcall(fennel.compileString, code_dotted, { scope = scope })
if ok then print("Result:", res) else print("Error:", res) end

print("\n--- Testing Nested Table ---")
local ok, res = pcall(fennel.compileString, code_nested, { scope = scope })
if ok then print("Result:", res) else print("Error:", res) end

-- 3. Auto-generated submodule?
-- If I want to support `(import-macros m "my-lib")` where my-lib is virtual.
-- The user asks about "embedded scripts called from native".
-- Maybe we can set `options.plugins`? Or `macro-searchers`?

print("\n--- Checking macro-searchers ---")
print("fennel['macro-searchers']:", fennel['macro-searchers'])
if fennel['macro-searchers'] then
   print("#searchers:", #fennel['macro-searchers'])
end
