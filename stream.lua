
do
	local lisp = require "lisp"
	local old_type = _ENV.type
	local old_print = _ENV.print
	
	_ENV = {}
	_ENV.cons = lisp.cons
	_ENV.car = lisp.car
	_ENV.cdr = lisp.cdr
	_ENV.cadr_ex = lisp.cadr_ex
	_ENV.contains_nil = lisp.contains_nil
	_ENV.list = lisp.list
	_ENV.list_unpack = lisp.list_unpack
	
	_ENV.set_cdr = lisp.set_cdr
	
	_ENV.type = old_type
	_ENV.print = old_print
end



function stream_car(stream)
	return car(stream)
end



function stream_cdr(stream)
	if type(cdr(stream)) == "function" then
		set_cdr(stream, (cdr(stream))())
	end
	return cdr(stream)
end



function stream_car_ex(...)
	return cadr_ex(stream_car, ...)
end



function stream_cdr_ex(...)
	return cadr_ex(stream_cdr, ...)
end



function stream_reference(stream, n)
	if n == 0 then
		return stream_car(stream)
	else
		return stream_reference(stream_cdr(stream), n - 1)
	end
end



function stream_filter(pred, stream)
	if stream == nil then
		return nil
	else
		local function delay()
			return stream_filter(pred, stream_cdr(stream))
		end
		if pred(stream_car(stream)) then
			return cons(stream_car(stream), delay)
		else
			return delay()
		end
	end
end



function stream_map(proc, stream)
	if stream == nil then
		return nil
	else
		local function delay()
			return stream_map(proc, stream_cdr(stream))
		end
		return cons(proc(stream_car(stream)), delay)
	end
end



function stream_map_ex(proc, ...)
	if contains_nil(...) then
		return nil
	else
		local delay_list = list(...)
		local function delay()
			return stream_map_ex(proc, stream_cdr_ex(list_unpack(delay_list)))
		end
		return cons(proc(stream_car_ex(...)), delay)
	end
end



function interleave(s1, s2)
	if s1 == nil then
		return s2
	else
		local function delay()
			return interleave(s2, stream_cdr(s1))
		end
		return cons(stream_car(s1), delay)
	end
end



----------------------------------------------------------------------------
------------------------  frequently used streams  -------------------------



function stream_enum_interval(low, high)
	if low > high then
		return nil
	else
		local function delayed()
			return stream_enum_interval(low + 1, high)
		end
		return cons(low, delayed)
	end
end




function ones()
	local function delay()
		return ones()
	end
	return cons(1, delay)
end



function integers()
	local stream_add
	function stream_add(s1, s2)
		local function delay()
			return stream_add(stream_cdr(s1), stream_cdr(s2))
		end
		return cons(stream_car(s1) + stream_car(s2),
					delay)
	end
	
	local function delay()
		return stream_add(ones(), integers())
	end

	return cons(1, delay)
end




------------------------  frequently used streams  -------------------------
----------------------------------------------------------------------------



return _ENV