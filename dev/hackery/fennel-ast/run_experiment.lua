package.path = "src/?.lua;" .. package.path
local fennel = require("fennel")
local filename = "dev/hackery/fennel-ast/walk_tree.fnl"

print("Running " .. filename .. " ...")
fennel.dofile(filename, {allowedGlobals = {"print", "pairs", "ipairs", "type", "next", "tostring", "require", "getmetatable", "table"}})
