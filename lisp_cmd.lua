

local quote = require "quote"
local eval = require "eval_cont"
local eval_reg = require "eval"
local lisp = require "lisp"

package.cpath = package.cpath .. ";./lib/target/lib?.dylib"
local readline = require "luaReadline"

lisp.set_cons_metatable = true

local cmd_line
local env = eval.Environment.initEnv()

local function func_noop() end



local function is_incomplete(str)
	if str == "" then
		return true
	end

	local str_end = string.byte(str, string.len(str))
	if str_end == string.byte("\\") then
		return true, string.sub(str, 1, string.len(str) - 1)
	else
		return false, str
	end
end




print("Lua Scheme 0.1")
print("Copyright 2015 Dong Feng")


local arg = select(1, ...)
local nocallcc = (arg == "no-callcc")
local wascallcc = (not nocallcc)

if nocallcc then
	print("No first-class continuation mode.")
end


local code = ""

repeat

	if wascallcc ~= (not nocallcc) then
		if nocallcc then
			print("Turn off first-class continuation.")
		else
			print("Turn on first-class continuation.")
		end
		wascallcc = (not nocallcc)
	end

	local prompt = code ~= "" and ">> " or "> "

	if readline then
		cmd_line = readline.readline(prompt)
	else
		io.write("> ")
		cmd_line = io.read("l")
	end

	local incomplete, cmd_line = is_incomplete(cmd_line)
	code = code .. (cmd_line or "")

	if (not incomplete) and code ~= "exit" and code ~= "no-callcc" and code ~= "with-callcc" then

		local bottom_cont = eval.ContinuationBottom:new(func_noop)
		local env_reg = eval_reg.Enviornment.initEnviornment()

		local s_exp
		local r, err = pcall(function ()
								 s_exp = quote.quote(code)
							 end)
		if not r then
			print("Syntax Error: " .. err)
		end

		if not nocallcc then
			r, err = pcall(function ()
							  local value = eval.eval_begin(s_exp, env, bottom_cont)
							  print(value)
						   end)
		else
			r, err = pcall(function ()
							  local value = env_reg:evalSequence(s_exp)
							  print(value)
						   end)
		end

		if not r then
			print("Execution Error: " .. err)
		end

		code = ""
	end

	if code == "no-callcc" or code == "with-callcc" then
		nocallcc = (code == "no-callcc")
		code = ""
	end

until cmd_line == "exit"

