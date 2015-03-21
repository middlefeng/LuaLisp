

local quote = require "quote"
local eval = require "eval_cont"
local lisp = require "lisp"

package.cpath = package.cpath .. ";./lib?.dylib"
local readline = require "luaReadline"

local cmd
local env = eval.Environment.initEnv()

local function func_noop() end

repeat

	if readline then
		cmd = readline.readline()
	else
		io.write("> ")
		cmd = io.read("l")
	end

	if cmd ~= "exit" and cmd ~= "" then
		local bottom_cont = eval.ContinuationBottom:new(func_noop)
		local s_exp = quote.quote(cmd)
		local value = eval.eval_begin(s_exp, env, bottom_cont)
		print(value)
	end

until cmd == "exit"

