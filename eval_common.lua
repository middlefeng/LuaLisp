
local quote = require "quote"
local lisp = require "lisp"


do
	local old_select = select
	local old_io = io
	local old_type = type
	local old_table = table

	_ENV = {}

	_ENV.select = old_select
	_ENV.io = old_io
	_ENV.type = old_type
	
	_ENV.table = {}
	_ENV.table.concat = old_table.concat
end



--------------------------------------------------------------------------------------------
------------------------------        Primitive Helper        ------------------------------



function primitive_null(exp)
	return exp == lisp.empty_list
end


function primitive_atom(exp)
	return (not lisp.is_pair(exp)) and (exp ~= lisp.empty_list)
end


function primitive_add(...)
	local result = 0
	for i = 1, select('#', ...) do
		result = result + select(i, ...)
	end
	return result
end



function primitive_sub(...)
	local result = select(1, ...)
	for i = 2, select('#', ...) do
		result = result - select(i, ...)
	end
	return result
end



function primitive_mul(...)
	local result = 1
	for i = 1, select('#', ...) do
		result = result * select(i, ...)
	end
	return result
end



function primitive_div(...)
	local result = select(1, ...)
	for i = 2, select('#', ...) do
		result = result / select(i, ...)
	end
	return result
end



function primitive_algebra(oper)
	if oper == '+' then
		return primitive_add
	elseif oper == '-' then
		return primitive_sub
	elseif oper == '*' then
		return primitive_mul
	elseif oper == "/" then
		return primitive_div
	elseif oper == "==" then
		return function(v1, v2) return v1 == v2 end
	elseif oper == "<" then
		return function(v1, v2) return v1 < v2 end
	elseif oper == ">" then
		return function(v1, v2) return v1 > v2 end
	end
end


--
--	policy:	 		format: indented, wrap
--					option:	level of indention
--
function primitive_tostring(list, policy, option)
	if lisp.is_pair(list) then
		if policy == "indented" then
			return lisp.list_tostring_indented(list, option, true)
		else
			local wrap = (policy == "wrap");
			return lisp.list_tostring(list, wrap)
		end
	end

	return lisp.tostring(list)
end



function primitive_string_append(...)
	local strings = {...}
	return table.concat(strings)
end



function primitive_open(mode)
	return function(filename)
			   return io.open(filename, mode)
		   end
end


function primitive_close(port)
	return io.close(port)
end



function primitive_read_string(inport)
	local content = inport:read("a")
	inport:seek("set", 0)
	return content
end




function primitive_read(instream)
	if type(instream) ~= 'string' then
		instream = primitive_read_string(instream)
	end
	return quote.quote(instream)
end




------------------------------        Primitive Helper        ------------------------------
--------------------------------------------------------------------------------------------



return _ENV
