local fennel = dofile("/home/spencertipping/r/public/9sh/src/fennel.lua")

print("Fennel version:", fennel["runtime-version"]())

-- Define a test macro function
-- Macros receive AST nodes and return AST nodes.
-- In Fennel AST, a list is a table.
local function my_macro(name)
   print("Expanding my-macro with arg:", tostring(name))
   -- Return (print "expanded")
   return {
      {type = "sym", [1] = "print"},
      "expanded: " .. tostring(name)
   }
end

-- Try method 1: options.macros (if it exists)
local macros_1 = {
   ["my-macro"] = my_macro
}

local code = "(my-macro 123)"
print("\n--- Attempt 1: options.macros ---")
local ok, res = pcall(fennel.compileString, code, { macros = macros_1 })
if ok then
   print("Success:", res)
else
   print("Failed:", res)
end

-- Try method 2: options.scope with pre-filled macros
-- We need to check if fennel.scope or fennel.makeScope exists
print("\n--- Check scope API ---")
if fennel.scope then print("fennel.scope exists") end
if fennel.makeScope then print("fennel.makeScope exists") end

if fennel.scope then -- Assuming it might be a constructor or similar
   local scope = fennel.scope()
   -- This part is speculative, need to see how scope works.
   -- usually scope.macros is a table.
   if type(scope) == 'table' and scope.macros then
      scope.macros["my-macro"] = my_macro
      print("\n--- Attempt 2: options.scope ---")
      local ok, res = pcall(fennel.compileString, code, { scope = scope })
      if ok then
         print("Success:", res)
      else
         print("Failed:", res)
      end
   else
      print("Scope structure unknown: keys=" .. table.concat(vim and vim.tbl_keys(scope) or {}, ","))
   end
end
