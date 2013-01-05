

do
	local lisp = require "lisp"
	
	local old_string = _ENV.string
	local old_error = _ENV.error
--	local old_print = _ENV.print
	
	_ENV = {}
	_ENV.list = lisp.list
	_ENV.append = lisp.append
	
	_ENV.string = old_string
	_ENV.error = old_error
	_ENV.print = old_print
end




function quote(symbols)


	--
	--	when *stopper* is nil, eschew all space
	--  when *stopper* is not nil, eschew until hit a stopper
	--
	local function eschew(location, stopper)
		local function is_stopper(sbyte)
			for i = 1, #stopper do
				if sbyte == string.byte(stopper[i]) then
					return true
				end
			end
			return false
		end
		
		local skipped = { " ", "\n", "\t" }
		local function is_skipped(sbyte)
			for i = 1, #skipped do
				if sbyte == string.byte(skipped[i]) then
					return true
				end
			end
			return false
		end
		
		location = location - 1
		repeat
			location = location + 1
			local current
			if location <= string.len(symbols) then
				current = string.byte(symbols, location)
			else
				current = nil
				location = nil
			end
			
		until location == nil or
			  (stopper == nil and (not is_skipped(current))) or
			  (stopper and is_stopper(current))
		
		return location
	end
	
	
	--
	--	parse simple *symbol*s
	--
	local function list_symbol(location)
		local stop_loc = eschew(location, {" ", ")"})
		local symbol = string.sub(symbols, location, stop_loc - 1)
		return list(symbol), eschew(stop_loc)
	end


	--
	--	parse list and sub-list
	--
	local list_items
	function list_items(location)
		local result_list = list()
		
		if string.byte(symbols, location) ~= string.byte("(") then
			error("Syntax error. Expect \"(\" at location ".. location);
		else
			location = location + 1
			location = eschew(location)
		end
		
		while string.byte(symbols, location) ~= string.byte(")") do
		
			if string.byte(symbols, location) == string.byte("(") then
				local new_list
				new_list, location = list_items(location)
				result_list = append(result_list, list(new_list))
			else
				local new_list
				new_list, location = list_symbol(location)
				result_list = append(result_list, new_list)
			end
		
		end
		
		if string.byte(symbols, location) ~= string.byte(")") then
			error("Syntax error. Expect \")\" at location " .. location);
		else
			location = location + 1
			location = eschew(location)
		end
		
		return result_list, location
	end
	
	location = eschew(1)
	return list_items(location)
	
end


return _ENV