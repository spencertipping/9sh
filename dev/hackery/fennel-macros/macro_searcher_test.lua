local fennel = dofile("/home/spencertipping/r/public/9sh/src/fennel.lua")

-- Define a custom macro searcher
local function virtual_macro_searcher(module_name)
   print("Macro searcher looking for:", module_name)
   if module_name == "virtual-lib" then
      return function(mod_name)
          return {
             baz = function(x)
                return fennel.list(fennel.sym("print"), "virtual baz called")
             end
          }
      end
   end
end

-- Hook into searchers
table.insert(fennel["macro-searchers"], virtual_macro_searcher)

local code = [[
   (import-macros {: baz} :virtual-lib)
   (baz)
]]

print("\n--- Testing Virtual Macro Import ---")
local ok, res = pcall(fennel.compileString, code)
if ok then
   print("Result:", res)
else
   print("Error:", res)
end

-- Test require-macros (if still supported/relevant, though import-macros is preferred)
local code_require = [[
   (require-macros :virtual-lib)
   (virtual-lib.baz)
]]
-- Wait, require-macros binds to the module name? Or brings them into scope?
-- Actually require-macros usually imports all into current scope?
-- No, (require-macros "lib") usually allows using macros qualified if aliased?
-- Or maybe it just loads them.
-- Let's stick to import-macros as it is the modern way.

-- Double check scope injection + import-macros conflict
-- If I inject 'baz' via scope AND import it.
local scope = fennel.scope()
scope.macros.baz = function() return fennel.list(fennel.sym("print"), "injected baz") end

local code_conflict = [[
   (import-macros {: baz} :virtual-lib)
   (baz)
]]
print("\n--- Testing Shadowing (Import vs Scope) ---")
local ok_c, res_c = pcall(fennel.compileString, code_conflict, { scope = scope })
if ok_c then print("Result:", res_c) else print("Error:", res_c) end
