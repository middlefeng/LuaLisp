

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

local list_tostring
function list_tostring(list)

	local result = {}
	result[1] = "("
	
	local function quote(s)
		if type(s) == "string" then
			return s
		else
			return tostring(s)
		end
	end
	
	local insert_value
	function insert_value(sub_list)
		if sub_list ~= nil then
			table.insert(result, quote(car(sub_list)))
			table.insert(result, " ")
			return insert_value(cdr(sub_list))
		else
			table.remove(result)
		end
	end
	insert_value(list)
	
	table.insert(result, ")")
	return table.concat(result)
end


local list_eq
function list_eq(a, b)
	if a == nil and b == nil then
		return true
	else
		return a ~= nil and b ~= nil and
		       car(a) == car(b) and
			   list_eq(cdr(a), cdr(b))
	end
end



local cons_meta = {
	__tostring = list_tostring,
	__eq = list_eq
}

--             -- end of meta-methods for display --                   --
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--                    -- basic pair operations --                      --

local function sub_stack(...)
	local sub_stack_itr
	function sub_stack_itr(start, ...)
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
	return getmetatable(p) == cons_meta
end


function cons(a, b)
	local result = { car = a, cdr = b }
	setmetatable(result, cons_meta)
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
		return nil
	else
		return cons(select(1, ...),
			   list(sub_stack(...)))
	end
end


function list_unpack(list)
	if cdr(list) == nil then
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
	if list == nil then
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
	if list1 == nil then
		return list2
	else
		return cons(car(list1),
					append(cdr(list1), list2))
	end
end



function list_contains_nil(list)
	if list == nil then
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
	if list == nil then
		return nil
	else
		return cons(proc(car(list)),
					map(proc, cdr(list)))
	end
end


local cadr_ex
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
	if list == nil then
		return nil
	elseif predicate(car(list)) then
		return cons(car(list), filter(predicate, cdr(list)))
	else
		return filter(predicate, cdr(list))
	end
end



function accumulate(op, initial, sequence)
	if sequence == nil then
		return initial
	else
		return op(car(sequence),
				  accumulate(op, initial, cdr(sequence)))
	end
end



function flat_map(proc, seq)
	return accumulate(append,
					  nil,
					  map(proc, seq))
end


--                          -- filter / map --                         --
-------------------------------------------------------------------------





-------------------------------------------------------------------------
--                           -- basic tree --                          --


function count_leaf(tree)
	if tree == nil then
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
	if tree == nil then
		return nil
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