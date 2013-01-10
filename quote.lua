

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
	local latest_linebreak = 1
	local line_num = 1
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
				if current == string.byte("\n") then
					line_num = line_num + 1
					latest_linebreak = location
				end
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
		local stop_loc = eschew(location, {" ", ")", "\n"})
		if stop_loc == nil then
			stop_loc = string.len(symbols) + 1
		end
		local symbol = string.sub(symbols, location, stop_loc - 1)
		return list(symbol), eschew(stop_loc)
	end
	
	
	local function forward(expected, location)
		if location == nil or
		   string.byte(symbols, location) ~= string.byte(expected) then
			error("Syntax error. Expect \"(\" at line ".. line_num ..
				  ", location " .. (location - latest_linebreak + 1));
		else
			location = location + 1
			location = eschew(location)
		end
		return location
	end


	--
	--  forward declaration
	--
	local list_item
	local sub_list
	
	--
	--  parse list item
	--
	function list_item(location)
		if string.byte(symbols, location) == string.byte("(") then
			return sub_list(location)
		else
			return list_symbol(location) 
		end
	end

	--
	--	parse sub-list
	--
	function sub_list(location)
		local result_list = list()
		
		location = forward("(", location)
		
		while location and
			  string.byte(symbols, location) ~= string.byte(")") do
		
			local new_item
			new_item, location = list_item(location)
			result_list = append(result_list, new_item)
		
		end
		
		location = forward(")", location)
		if location then
			location = eschew(location)
		end
		
		return list(result_list), location
	end
	
	--
	--  main chunk
	--
	local result_list = list()
	local location = eschew(1)
	while location ~= nil do
		local new_item
		new_item, location = list_item(location)
		result_list = append(result_list, new_item)
	end
	
	return result_list
	
end


return _ENV