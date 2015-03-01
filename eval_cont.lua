
do

	local lisp = require "lisp"
	local old_error = error
	local old_setmetatable = setmetatable

	local old_type = type
	local old_string = string

	_ENV = {}
	_ENV.lisp = lisp
	_ENV.error = old_error
	_ENV.eval_exp = eval_exp
	_ENV.setmetatable = old_setmetatable
	_ENV.type = old_type
	_ENV.string = old_string

end



Object = {}
Object.__index = Object

function Object:new(o)
	local result = o or {}
	result.__index = result
	setmetatable(result, self)
	return result
end





--------------------------------------------------------------------------------------------
------------------------------          Environment           ------------------------------


Environment = {}
Environment.__index = Environment


local nil_val = { __tostring = function(v) return 'Nil' end }
setmetatable(nil_val, nil_val)


function Environment:new(enclosing, params, args)
	local result = o or {}
	result.enclosing = enclosing
	result.binds = {}

	local function addProp(nameList, valueList)
		if nameList ~= nil and nameList ~= lisp.empty_list then
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


function Environment:define(var, val)
	val = val or nil_val
	self.binds[var] = val
end



function Environment.initEnv()
	local e = Environment:new()
	e.binds = LispPrimitive.primitives
	return e
end


------------------------------          Environment           ------------------------------
--------------------------------------------------------------------------------------------






--------------------------------------------------------------------------------------------
------------------------------            Function            ------------------------------



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


------------------------------            Function            ------------------------------
--------------------------------------------------------------------------------------------





--------------------------------------------------------------------------------------------
------------------------------          Continuation          ------------------------------


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
	local result = Continuation:new(env, k)
	result.exp_list = exp_list
	setmetatable(result, self)
	return result;
end


function ContinuationBegin:resume(val)
	return eval_begin(lisp.cdr(self.exp_list),
					  self.env, self.continuation)
end






ContinuationSet = Continuation:new()


function ContinuationSet:new(name, env, k)
	local result = Continuation:new(env, k)
	result.set_name = name
	setmetatable(result, self)
	return result
end


function ContinuationSet:resume(val)
	self.env:update(self.set_name, val, self.env, self.continuation)
end



ContinuationDefine = Continuation:new()


function ContinuationDefine:new(name, env, k)
	local result = Continuation:new(env, k)
	result.define_name = name
	setmetatable(result, self)
	return result
end


function ContinuationDefine:resume(val)
	self.env:define(self.set_name, val, self.env, self.continuation)
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


------------------------------          Continuation          ------------------------------
--------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------
------------------------------           Evaluator            ------------------------------



function eval(exp, env, k)
	if is_variable(exp) then
		return eval_variable(exp, env, k)
	elseif is_self_evaluating(exp) then
		return eval_quote(exp, env, k)
	elseif is_quoted(exp) then
		return eval_quote(lisp.cadr(exp), env, k)
	elseif is_if(exp) then
		return eval_if(lisp.cadr(exp),
					   lisp.cadr(lisp.cdr(exp)),
					   lisp.cadr(lisp.cdr(lisp.cdr(exp))),
					   env, k)
	elseif is_begin(exp) then
		return eval_begin(lisp.cdr(exp), env, k)
	elseif is_assignment(exp) then
		return eval_set(lisp.cadr(exp), lisp.cadr(lisp.cdr(exp)), env, k)
	elseif is_lambda(exp) then
		return eval_lambda(lisp.cadr(exp), lisp.cdr(lisp.cdr(exp)), env, k)
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



function eval_set(name, exp, env, k)
	return eval(exp, ContinuationSet:new(name, env, k))
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


------------------------------           Evaluator            ------------------------------
--------------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------------
------------------------------    expression predicates       ------------------------------


function is_self_evaluating(exp)
	return (type(exp) == 'string' and string.sub(exp, 1, 1) == "'") or
		    type(exp) == 'number' or type(exp) == 'boolean' or
		    false
end



function is_variable(exp)
	return (type(exp) == 'string' and (not is_self_evaluating(exp)))
end


local function is_tagged(exp, tag)
	return lisp.is_pair(exp) and
		   lisp.car(exp) == tag
end


function is_quoted(exp)
	return is_tagged(exp, 'quote')
end



function is_assignment(exp)
	return is_tagged(exp, 'set!')
end



function is_definition(exp)
	return is_tagged(exp, 'define')
end



function is_if(exp)
	return is_tagged(exp, 'if')
end


function is_and(exp)
	return is_tagged(exp, 'and')
end



function is_or(exp)
	return is_tagged(exp, 'or')
end



function is_not(exp)
	return is_tagged(exp, 'not')
end



function is_lambda(exp)
	return is_tagged(exp, 'lambda')
end



function is_begin(exp)
	return is_tagged(exp, 'begin')
end



function is_cond(exp)
	return is_tagged(exp, 'cond')
end


function is_application(exp)
	return is_pair(exp)
end



function is_last_exp(exp)
	return cdr(exp) ==lisp.empty_list
end



function is_delay(exp)
	return is_tagged(exp, 'delay')
end



function is_force(exp)
	return is_tagged(exp, 'force')
end



function is_cons_stream(exp)
	return is_tagged(exp, 'cons-stream')
end


function is_let(exp)
	return is_tagged(exp, 'let')
end


------------------------------    expression predicates       ------------------------------
--------------------------------------------------------------------------------------------



return _ENV


