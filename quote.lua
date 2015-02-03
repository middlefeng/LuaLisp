

do
	local lisp = require "lisp"
	
	local old_string = _ENV.string
	local old_tonumber = _ENV.tonumber
	local old_error = _ENV.error
	local old_type = _ENV.type
	local old_table = _ENV.table
	local old_print = _ENV.print
	
	_ENV = {}
	_ENV.list = lisp.list
	_ENV.append = lisp.append
	
	_ENV.string = old_string
	_ENV.tonumber = old_tonumber
	_ENV.error = old_error
	_ENV.type = old_type
	_ENV.table = old_table
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
				if current == string.byte(";") then
					while location + 1 <= string.len(symbols) do
						current = string.byte(symbols, location + 1)
						location = location + 1
						if current == string.byte("\n") then
							break
						end
					end
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
		if type(symbol) == 'string' then
			if tonumber(symbol) then
				symbol = tonumber(symbol)
			elseif symbol == 'true' then
				symbol = true
			elseif symbol == 'false' then
				symbol = false
			end
		end
		return list(symbol), eschew(stop_loc)
	end
	
	
	local function forward(expected, location)
		if location == nil or
		   string.byte(symbols, location) ~= string.byte(expected) then
		   	
		   	local location_str = "[end]"
		   	if location then
		   		location_str = tostring(location - latest_linebreak + 1)
		   	end

			error("Syntax error. Expect \"" .. expected .. "\" at line ".. line_num ..
				  ", location " .. location_str);
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
	local list_quote
	local read_string
	local sub_list
	
	--
	--  parse list item
	--
	function list_item(location)
		if string.byte(symbols, location) == string.byte("(") then
			return sub_list(location)
		elseif string.byte(symbols, location) == string.byte("'") then
			return list_quote(location)
		elseif string.byte(symbols, location) == string.byte("\"") then
			return read_string(location)
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
	--	parse quote
	--
	function list_quote(location)
		location = forward("'", location)

		local new_item
		new_item, location = list_item(location)
		local result_list = append(list("quote"), new_item)

		return list(result_list), location
	end


	function read_string(location)
		local result = {}

		local last_escape = location + 1
		repeat
			location = location + 1
			local current = string.byte(symbols, location)
			if current == string.byte("\\") then
				if location - 1 > last_escape then
					table.insert(result, string.sub(symbols, last_escape, location - 1))
				end
				last_escape = location + 1
				location = location + 1
			end
		until current == string.byte("\"")

		table.insert(result, string.sub(symbols, last_escape, location - 1))
		result = append(list("quote"), list(table.concat(result)))
		return list(result), eschew(location + 1)
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