

local quote = require "quote"
local eval = require "eval_cont"
local lisp = require "lisp"

lisp.set_cons_metatable = false

local filename = ...
local file = io.open(filename, "r")

if not(file) or io.type(file) ~= "file" then
	print("File not found: " .. filename)
	os.exit()
end

local lisp_src = file:read("a")
local s_exp = quote.quote(lisp_src)

print("Source: ")
print(lisp.list_tostring(s_exp, true) .. "\n")

local env = eval.Environment.initEnv()
local bottom_cont = eval.ContinuationBottom:new(print)
local value = eval.eval_begin(s_exp, env, bottom_cont)

print("> " .. tostring(value))



