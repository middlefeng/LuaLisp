

local quote = require "quote"
local eval = require "eval"
local lisp = require "lisp"

local filename = ...
local file = io.open(filename, "r")

if not(file) or io.type(file) ~= "file" then
	print("File not found: " .. filename)
	os.exit()
end

local lisp_src = file:read("a")
local s_exp = quote.quote(lisp_src)

local env = eval.Enviornment.initEnviornment()
local value = env:evalSequence(s_exp)

print("> " .. tostring(value))

