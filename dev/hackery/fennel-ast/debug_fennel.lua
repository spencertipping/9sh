package.path = "src/?.lua;" .. package.path
print("Loading fennel...")
local fennel = require("fennel")
print("Fennel version: " .. (fennel.version or "unknown"))
print("Fennel module keys:")
for k,v in pairs(fennel) do
  print(k, type(v))
end

-- Try to eval a simple string
print("Eval result:", fennel.eval('(print "Hello from eval")'))
