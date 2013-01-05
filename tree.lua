

do
	local s = require "scheme"
	
	_ENV = {}
	_ENV.car = s.car
	_ENV.cadr = s.cadr
	_ENV.cdr = s.cdr
	_ENV.cons = s.cons
	_ENV.list = s.list
end


function entry(tree)
	return car(tree)
end



function left_branch(tree)
	return cadr(tree)
end



function right_branch(tree)
	return car(cdr(cdr(tree)))
end



function make_tree(entry, left, right)
	return list(entry, left, right)
end


return _ENV