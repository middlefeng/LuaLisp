
do

	local lisp = require "lisp"
	local old_error = error
	local old_setmetatable = setmetatable
	local old_select = select 

	local old_type = type
	local old_string = string
	local print_lua = print

	_ENV = {}
	_ENV.lisp = lisp
	_ENV.error = old_error
	_ENV.eval_exp = eval_exp
	_ENV.setmetatable = old_setmetatable
	_ENV.type = old_type
	_ENV.string = old_string
	_ENV.select = old_select
	_ENV.print_lua = print_lua

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
			local value = lisp.car(valueList) or nil_val
			result.binds[lisp.car(nameList)] = value
			return addProp(lisp.cdr(nameList), lisp.cdr(valueList))
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


function Environment:define(var, val, k)
	if self.binds[name] then
		error("Redefine variable: " .. var)
	else
		val = val or nil_val
		self.binds[var] = val
		return k:resume(val)
	end
end



function Environment.initEnv()
	local e = Environment:new()
	e.binds = LispPrimitive.primitives
	return e
end


------------------------------          Environment           ------------------------------
--------------------------------------------------------------------------------------------






--------------------------------------------------------------------------------------------
------------------------------        Primitive Helper        ------------------------------



local function primitive_null(exp)
	return exp == empty_list
end


local function primitive_atom(exp)
	return (not is_pair(exp)) and (exp ~= empty_list)
end


local function primitive_add(...)
	local result = 0
	for i = 1, select('#', ...) do
		result = result + select(i, ...)
	end
	return result
end



local function primitive_sub(...)
	local result = select(1, ...)
	for i = 2, select('#', ...) do
		result = result - select(i, ...)
	end
	return result
end



local function primitive_mul(...)
	local result = 1
	for i = 1, select('#', ...) do
		result = result * select(i, ...)
	end
	return result
end



local function primitive_div(...)
	local result = select('#', ...)
	for i = 2, select('#', ...) do
		result = result + select(i, ...)
	end
	return result
end



local function primitive_algebra(oper)
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


local function primitive_tostring(list)
	if is_pair(list) then
		return list_tostring(list)
	end

	return tostring(list)
end


------------------------------        Primitive Helper        ------------------------------
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
	["cons"] = LispPrimitive:new(lisp.cons),
	["print"] = LispPrimitive:new(print_lua),
	["list"] = LispPrimitive:new(lisp.list),
	["+"] = LispPrimitive:new(primitive_algebra('+')),
	["-"] = LispPrimitive:new(primitive_algebra('-')),
	["*"] = LispPrimitive:new(primitive_algebra('*')),
	["/"] = LispPrimitive:new(primitive_algebra('/')),
	["eq?"] = LispPrimitive:new(primitive_algebra('==')),
	["<"] = LispPrimitive:new(primitive_algebra('<')),
	[">"] = LispPrimitive:new(primitive_algebra('>'))
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
	return self.env:update(self.set_name, val, self.continuation)
end



ContinuationDefine = Continuation:new()


function ContinuationDefine:new(name, env, k)
	local result = Continuation:new(env, k)
	result.define_name = name
	setmetatable(result, self)
	return result
end


function ContinuationDefine:resume(val)
	return self.env:define(self.define_name, val, self.continuation)
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
------------------------------           Eval Rules           ------------------------------


function text_of_quotation(exp)
	return lisp.cadr(exp)
end



--- assignment


function assignment_variable(exp)
	return cadr(exp)
end



function assignment_value(exp)
	return lisp.cadr(cdr(exp))
end



--- lambda / function


function make_lambda(params, body)
	return lisp.cons('lambda', lisp.cons(params, body))
end


function definition_var(exp)
	local var = lisp.cadr(exp)
	if lisp.is_pair(var) then
		return lisp.car(var)
	else
		return var
	end
end



function definition_val(exp)
	local var = lisp.cadr(exp)
	if lisp.is_pair(var) then
		local param = lisp.cdr(lisp.cadr(exp))
		local body = lisp.cdr(lisp.cdr(exp))
		return make_lambda(param, body)
	else
		return lisp.cadr(lisp.cdr(exp))
	end
end



function lambda_param(exp)
	return lisp.cadr(exp)
end



function lambda_body(exp)
	return lisp.cdr(cdr(exp))
end



--- if / if-else


function if_predicate(exp)
	return lisp.cadr(exp)
end



function if_consequent(exp)
	return lisp.cadr(cdr(exp))
end



function if_alternative(exp)
	local alt = lisp.cadr(lisp.cdr(lisp.cdr(exp)))
	if alt then
		return alt
	else
		return 'false'
	end
end


local function make_if(predicate, consequent, alternative)
	return lisp.list('if', predicate, consequent, alternative)
end


--- cond


function cond_clauses(exp)
	return lisp.cdr(exp)
end



function cond_to_if(exp)
	return expand_clauses(cond_clauses(exp))
end



function cond_predicate(clause)
	return lisp.car(clause)
end



function cond_action(clause)
	return lisp.cdr(clause)
end


function is_cond_else_clause(clause)
	return cond_predicate(clause) == 'else'
end



function expand_clauses(clauses)
	if clauses == empty_list then
		return 'false'
	elseif is_cond_else_clause(lisp.car(clauses)) then
		if lisp.cdr(clauses) == empty_list then
			return sequence_to_exp(cond_action(lisp.car(clauses)))
		else
			return empty_list
		end
	else
		return make_if(cond_predicate(lisp.car(clauses)),
					   sequence_to_exp(cond_action(car(clauses))),
					   expand_clauses(lisp.cdr(clauses)))
	end
end


--- relation


function and_to_if(exp)
	if lisp.cdr(exp) == empty_list then
		return lisp.car(exp)
	else
		return make_if(lisp.car(exp), and_to_if(lisp.cdr(exp)), false)
	end
end


function or_to_if(exp)
	if lisp.cdr(exp) == empty_list then
		return lisp.car(exp)
	else
		return make_if(lisp.car(exp), true, or_to_if(lisp.cdr(exp)))
	end
end


function not_to_if(exp)
	return make_if(lisp.car(exp), false, true)
end



--- sequence


function first_exp(sequence)
	return lisp.car(sequence)
end



function last_exp(sequence)
	return lisp.cdr(sequence) == lisp.empty_list
end



function rest_exp(sequence)
	return lisp.cdr(sequence)
end



function begin_actions(exp)
	return lisp.cdr(exp)
end


local function make_begin(sequence)
	return lisp.cons('begin', sequence)
end


function sequence_to_exp(sequence)
	if sequence == lisp.empty_list then
		return lisp.empty_list
	elseif last_exp(sequence) then
		return first_exp(sequence)
	else
		return make_begin(sequence)
	end
end


--- let


function let_to_lambda_apply(exp)
	local lambda = let_to_lambda(exp)
	local arguments = let_arguments(exp)
	return lisp.cons(lambda, arguments)
end



function let_to_lambda(exp)
	local param = let_lambda_parameter(exp)
	local body = let_lambda_body(exp)
	return make_lambda(param, body)
end



function let_lambda_parameter(exp)
	return lisp.map(lisp.car, lisp.cadr(exp))
end


function let_arguments(exp)
	return lisp.map(lisp.cadr, lisp.cadr(exp))
end


function let_lambda_body(exp)
	return lisp.cdr(lisp.cdr(exp))
end


------------------------------           Eval Rules           ------------------------------
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
	elseif is_definition(exp) then
		return eval_definition(exp, env, k)
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



function eval_lambda(params, exp_list, env, k)
	return k:resume(LispFunction:new(params, exp_list, env))
end



function eval_set(name, exp, env, k)
	return eval(exp, ContinuationSet:new(name, env, k))
end



function eval_definition(exp, env, k)
	local name = definition_var(exp)
	local val_exp = definition_val(exp)
	return eval(val_exp, env, ContinuationDefine:new(name, env, k))
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


