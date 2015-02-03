

local lisp = require "lisp"

local a = lisp.list()
local b = lisp.list("a")
local c = lisp.list()

print("a == b: " .. tostring(a == b))
print("a == c: " .. tostring(a == c))
print("a is empty: " .. tostring(a == lisp.empty_list))
print("b is empty: " .. tostring(b == lisp.empty_list))
