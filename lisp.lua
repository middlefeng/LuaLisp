

local old_table = table
local old_string = string
local old_tostring = tostring
local old_type = type
local old_getmetatable = getmetatable
local old_setmetatable = setmetatable
local old_select = select

local _ENV = {}
_ENV.table = old_table
_ENV.getmetatable = old_getmetatable
_ENV.setmetatable = old_setmetatable
_ENV.string = old_string
_ENV.tostring = old_tostring
_ENV.type = old_type
_ENV.select = old_select


-------------------------------------------------------------------------
--                 -- meta-methods for display --                      --

empty_list = {}

local function empty_list_to_string(empty_list)
	return "()"
end

local empty_list_meta = {
	__tostring = empty_list_to_string
}


setmetatable(empty_list, empty_list_meta)


function list_tostring(list, wrap)

	if type(list) ~= "table" then
		return tostring(list)
	end

	if list == empty_list then
		return tostring(empty_list)
	end

	local result = {}
	result[1] = "("

	local delimitor = wrap and "\n" or " "
	
	local function insert_value(sub_list)
		if sub_list ~= empty_list then
			table.insert(result, list_tostring(car(sub_list), false))
			table.insert(result, delimitor)
			return insert_value(cdr(sub_list))
		else
			table.remove(result)
		end
	end
	insert_value(list)
	
	table.insert(result, ")")
	return table.concat(result)
end


local cons_meta = {
	__tostring = list_tostring,
	__eq = list_eq
}


local function list_eq(a, b)
	if a == nil and b == nil then
		return true
	elseif getmetatable(a) ~= cons_meta and
		   getmetatable(b) ~= cons_meta then
		return a == b
	else
		return a ~= empty_list and b ~= empty_list and
		       car(a) == car(b) and
			   list_eq(cdr(a), cdr(b))
	end
end




--             -- end of meta-methods for display --                   --
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--                    -- basic pair operations --                      --

local function sub_stack(...)
	local function sub_stack_itr(start, ...)
		if start > select("#", ...) then
			return
		else
			return select(start, ...),
				   sub_stack_itr(start + 1, ...)
		end
	end
	return sub_stack_itr(2, ...)
end


function is_pair(p)
	return type(p) == "table" and (p.car ~= nil or p.cdr ~= nil)
end


function cons(a, b)
	local result = { car = a, cdr = b }
	if set_cons_metatable then
		setmetatable(result, cons_meta)
	end
	return result
end


function car(pair)
	return pair.car
end



function cdr(pair)
	return pair.cdr
end


function cadr(list)
	return car(cdr(list))
end


--                    -- basic pair operations --                      --
-------------------------------------------------------------------------




-------------------------------------------------------------------------
--                         -- mutable pair --                          --

function set_car(pair, x)
	pair.car = x
end


function set_cdr(pair, x)
	pair.cdr = x
end


--                         -- mutable pair --                          --
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--                         -- list operations --                       --


function list(...)
	if select("#", ...) == 0 then
		return empty_list
	else
		return cons(select(1, ...),
			   list(sub_stack(...)))
	end
end


function list_unpack(list)
	if cdr(list) == empty_list then
		return car(list)
	else
		return car(list), list_unpack(cdr(list))
	end
end


function list_ref(list, n)
	if n == 1 then
		return car(list)
	else
		return list_ref(cdr(list), n - 1)
	end
end



function length(list)
	if list == empty_list then
		return 0
	else
		return 1 + length(cdr(list))
	end
end


function remove(item, sequence)
	local function retain(x)
		return x ~= item
	end
	return filter(retain, sequence)
end


function append(list1, list2)
	if list1 == empty_list or list1 == nil then
		return list2 or empty_list
	else
		return cons(car(list1),
					append(cdr(list1), list2))
	end
end



function list_contains_nil(list)
	if list == nil or list == empty_list then
		return false
	elseif car(list) == nil then
		return true
	else
		return list_contains_nil(cdr(list))
	end
end



function contains_nil(...)
	return list_contains_nil(list(...))
end



--                         -- list operations --                       --
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--                          -- filter / map --                         --

function map(proc, list)
	if list == nil or list == empty_list then
		return empty_list
	else
		return cons(proc(car(list)),
					map(proc, cdr(list)))
	end
end


function cadr_ex(op, ...)
	if select("#", ...) == 0 then
		return
	else
		return op(select(1, ...)),
			   cadr_ex(op, sub_stack(...))
	end
end


local function car_ex(...)
	return cadr_ex(car, ...)
end


local function cdr_ex(...)
	return cadr_ex(cdr, ...)
end


function map_ex(proc, ...)
	if contains_nil(...) then
		return nil
	else
		return cons(proc(car_ex(...)),
					map_ex(proc, cdr_ex(...)))
	end
end


function filter(predicate, list)
	if list == nil or list == empty_list then
		return empty_list
	elseif predicate(car(list)) then
		return cons(car(list), filter(predicate, cdr(list)))
	else
		return filter(predicate, cdr(list))
	end
end



function accumulate(op, initial, sequence)
	if sequence == nil or sequence == empty_list then
		return initial or empty_list
	else
		return op(car(sequence),
				  accumulate(op, initial, cdr(sequence)))
	end
end



function flat_map(proc, seq)
	return accumulate(append,
					  empty_list,
					  map(proc, seq))
end


--                          -- filter / map --                         --
-------------------------------------------------------------------------





-------------------------------------------------------------------------
--                           -- basic tree --                          --


function count_leaf(tree)
	if tree == nil or tree == empty_list then
		return 0
	elseif not is_pair(tree) then
		return 1
	else
		return count_leaf(car(tree)) +
			   count_leaf(cdr(tree))
	end
end


function map_tree(proc, tree)
	local map_subtree
	function map_subtree(subtree)
		if is_pair(subtree) then
			return map_tree(proc, subtree)
		else
			return proc(subtree)
		end
	end
	return map(map_subtree, tree)
end


function enum_tree(tree)
	if tree == nil or tree == empty_list then
		return empty_list
	elseif not is_pair(tree) then
		return list(tree)
	else
		return append(enum_tree(car(tree)),
					  enum_tree(cdr(tree)))
	end
end



--                           -- basic tree --                          --
-------------------------------------------------------------------------


return _ENV