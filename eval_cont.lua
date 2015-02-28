
do

	local lisp = require "lisp"
	local eval_exp = require "eval"
	local old_error = error
	local old_setmetatable = setmetatable

	_ENV = {}
	_ENV.lisp = lisp
	_ENV.error = old_error
	_ENV.eval_exp = eval_exp
	_ENV.setmetatable = old_setmetatable

end



Object = {}
Object.__index = Object

function Object:new(o)
	local result = o or {}
	result.__index = result
	setmetatable(result, self)
	return result
end





Environment = {}
Environment.__index = Environment


function Environment:new(enclosing, params, args)
	local result = o or {}
	result.enclosing = enclosing
	result.binds = {}

	local function addProp(nameList, valueList)
		if nameList ~= nil and nameList ~= empty_list then
			local value = car(valueList) or nil_val
			result.binds[car(nameList)] = value
			return addProp(cdr(nameList), cdr(valueList))
		end
	end
	addProp(params, args)

	setmetatable(result, self)
	return result
end


function Environment:lookup(name, k)
	if self.binds[name] then
		return k:resume(self.binds[name])
	elseif self.enclosing then
		return self.enclosing:lookup(name, k)
	else
		error("Unknown varaible: " .. name)
	end
end



function Environment:update(name, val, k)
	if self.binds[name] then
		self.binds[name] = val
		return k:resume(val)
	elseif self.enclosing then
		return self.enclosing:update(name, val, k)
	else
		error("Update unknown varaible: " .. name)
	end
end


function Environment.initEnv()
	local e = Environment:new()
	e.binds = LispPrimitive.primitives
	return e
end




LispFunction = {}
LispFunction.__index = LispFunction


function LispFunction:new(params, body, env)
	local result = {}
	result.params = params
	result.body = body
	result.env = env
	setmetatable(result, self)
	return result
end


function LispFunction:invoke(args, env, k)
	local extended_env = Environment:new(self.env, self.params, args)
	return eval_begin(self.body, extended_env, k)
end




LispPrimitive = {}
LispPrimitive.__index = LispPrimitive


function LispPrimitive:new(primitive)
	local result = {}
	result.primitive = primitive
	setmetatable(result, self)
	return result
end


function LispPrimitive:invoke(args, env, k)
	local r = self.primitive(lisp.list_unpack(args))
	return k:resume(r)
end


LispPrimitive.primitives =
{
	["car"] = LispPrimitive:new(lisp.car),
	["cdr"] = LispPrimitive:new(lisp.cdr),
	["+"] = LispPrimitive:new(function(a, b) return a + b end)
}






Continuation = {}
Continuation.__index = Continuation


function Continuation:new(env, k)
	local result = {}
	result.__index = result
	result.env = env
	result.continuation = k
	setmetatable(result, self)
	return result
end




ContinuationBottom = Continuation:new()


function ContinuationBottom:new(func)
	local result = Continuation:new()
	result.func = func
	setmetatable(result, self)
	return result
end


function ContinuationBottom:resume(val)
	self.func(val)
	return val
end






ContinuationIf = Continuation:new()


function ContinuationIf:new(true_exp, false_exp, env, k)
	local result = Continuation:new(env, k)
	result.true_exp = true_exp
	result.false_exp = false_exp
	setmetatable(resume, self)
	return result
end


function ContinuationIf:resume(val)
	local eval_val
	if val then
		eval_val = self.true_exp
	else
		eval_val = self.false_exp
	end

	return eval(eval_val, self.env, self.continuation)
end






ContinuationBegin = Continuation:new()


function ContinuationBegin:new(exp_list, env, k)
	local result = Continuation(env, k)
	result.exp_list = exp_list
	setmetatable(result, self)
	return result;
end


function ContinuationBegin:resume(val)
	return eval(val, self.env, lisp.cdr(self.exp_list), self.continuation)
end






ContinuationSet = Continuation:new()

function ContinuationSet:resume(val)
end




ContinuationEvalFunction = {}
ContinuationEvalFunction.__index = ContinuationEvalFunction
setmetatable(ContinuationEvalFunction, Continuation)


function ContinuationEvalFunction:new(exp_list, env, k)
	local result = {}
	result.exp_list = exp_list
	result.env = env
	result.continuation = k
	setmetatable(result, self)
	return result
end


function ContinuationEvalFunction:resume(func)
	return eval_arguments(self.exp_list, self.env,
						  ContinuationApply:new(func, self.env, self.continuation))
end



ContinuationArguments = {}
ContinuationArguments.__index = ContinuationArguments


function ContinuationArguments:new(exp_list, env, k)
	local result = {}
	result.exp_list = exp_list
	result.env = env
	result.continuation = k
	setmetatable(result, self)
	return result
end


function ContinuationArguments:resume(val)
	return eval_arguments(lisp.cdr(self.exp_list), self.env,
						  ContinuationGather:new(val, self.continuation))
end




ContinuationGather = {}
ContinuationGather.__index = ContinuationGather


function ContinuationGather:new(exp_list, k)
	local result = {}
	result.exp_list = exp_list
	result.continuation = k
	setmetatable(result, self)
	return result
end


function ContinuationGather:resume(val)
	return self.continuation:resume(lisp.cons(self.exp_list, val))
end




ContinuationApply = {}
ContinuationApply.__index = ContinuationApply


function ContinuationApply:new(func, env, k)
	local result = {}
	result.func = func
	result.env = env
	result.continuation = k
	setmetatable(result, self)
	return result
end


function ContinuationApply:resume(val)
	return self.func:invoke(val, self.env, self.continuation)
end




function eval(exp, env, k)
	if eval_exp.is_variable(exp) then
		return eval_variable(exp, env, k)
	elseif eval_exp.is_self_evaluating(exp) then
		return eval_quote(exp, env, k)
	elseif eval_exp.is_quoted(exp) then
		return eval_quote(lisp.cadr(exp), env, k)
	elseif eval_exp.is_if(exp) then
		return eval_if(lisp.cadr(exp),
					   lisp.cadr(lisp.cdr(exp)),
					   lisp.cadr(lisp.cdr(lisp.cdr(exp))),
					   env, k)
	elseif eval_exp.is_begin(exp) then
		return eval_begin(lisp.cdr(exp), env, k)
	elseif eval_exp.is_assignment(exp) then
		return eval_set(exp)
	else
		return eval_application(lisp.car(exp), lisp.cdr(exp), env, k)
	end
end


function eval_quote(val, env, k)
	return k:resume(val)
end


function eval_variable(name, env, k)
	return env:lookup(name, k)
end


function eval_if(cond_exp, true_exp, false_exp, env, k)
	return eval(cond_exp, env,
				ContinuationIf:new(true_exp, false_exp, env, k))
end



function eval_begin(exp_list, env, k)
	if lisp.is_pair(exp_list) then
		if lisp.is_pair(lisp.cdr(exp_list)) then
			return eval(lisp.car(exp_list), env,
						ContinuationBegin:new(exp_list, env, k))
		else
			return eval(lisp.car(exp_list), env, k)
		end
	else
		return k:resume(lisp.empty_list)
	end
end



function eval_lambda(parms, exp_list, env, k)
	return k:resume(LispFunction:new(params, exp_list, env))
end



function eval_set()
end



function eval_arguments(args, env, k)
	if lisp.is_pair(args) then
		return eval(lisp.car(args), env, ContinuationArguments:new(args, env, k))
	else
		return k:resume(lisp.empty_list)
	end
end



function eval_application(func, args, env, k)
	return eval(func, env, ContinuationEvalFunction:new(args, env, k))
end


return _ENV


