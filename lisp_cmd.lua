

local quote = require "quote"
local eval = require "eval_cont"
local lisp = require "lisp"


local cmd
local env = eval.Environment.initEnv()

local function func_noop() end

repeat
	io.write("> ")
	cmd = io.read("l")

	if cmd ~= "exit" and cmd ~= "" then
		local bottom_cont = eval.ContinuationBottom:new(func_noop)
		local s_exp = quote.quote(cmd)
		local value = eval.eval_begin(s_exp, env, bottom_cont)
		print(value)
	end

until cmd == "exit"

