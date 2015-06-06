

do
	local old_select = select

	_ENV = {}

	_ENV.select = old_select
end



--------------------------------------------------------------------------------------------
------------------------------        Primitive Helper        ------------------------------



function primitive_null(exp)
	return exp == lisp.empty_list
end


function primitive_atom(exp)
	return (not lisp.is_pair(exp)) and (exp ~= lisp.empty_list)
end


function primitive_and(...)
	local result = true
	for i = 1, select('#', ...) do
		result = result and select(i, ...)
	end
	return result
end


function primitive_or(...)
	local result = false
	for i = 1, select('#', ...) do
		result = result or select(i, ...)
	end
	return result
end



function primitive_not(a)
	return (not result)
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


function primitive_tostring(list, wrap)
	if lisp.is_pair(list) then
		return lisp.list_tostring(list, wrap)
	end

	return lisp.tostring(list)
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
