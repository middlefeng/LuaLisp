

-------------------------------------------------------------------------
--[[

To Do:

--]]
-------------------------------------------------------------------------

do
	local lisp = require "lisp"
	
	local old_setmetatable = _ENV.setmetatable
	local old_getmetatable = _ENV.getmetatable
	local old_error = _ENV.error
	local old_table = _ENV.table
	local old_type = _ENV.type
	local old_string = _ENV.string
	local old_tostring = _ENV.tostring
	
	local old_print = _ENV.print
	local old_pairs = _ENV.pairs
	local old_select = _ENV.select


	_ENV = {}
	_ENV.setmetatable = old_setmetatable
	_ENV.getmetatable = old_getmetatable
	_ENV.error = old_error
	
	_ENV.is_pair = lisp.is_pair
	_ENV.cons = lisp.cons
	_ENV.car = lisp.car
	_ENV.cdr = lisp.cdr
	_ENV.cadr = lisp.cadr
	_ENV.list = lisp.list
	_ENV.map = lisp.map
	_ENV.list_unpack = lisp.list_unpack
	
	_ENV.table = table
	_ENV.type = old_type
	_ENV.string = old_string
	_ENV.tostring = old_tostring
	
	_ENV.print = old_print
	_ENV.pairs = old_pairs
	_ENV.select = old_select
end



-------------------------------------------------------------------------
--                   -- environment structure --                       --



Frame = {}
Frame.__index = Frame



function Frame:new()
	local result = {}
	setmetatable(result, self)
	return result
end


local nil_val = {}


function Frame:newFromList(varNames, varValues)
	local result = {}
	local function addProp(nameList, valueList)
		if nameList ~= nil then
			local value = car(valueList) or nil_val
			result[car(nameList)] = value
			return addProp(cdr(nameList), cdr(valueList))
		end
	end
	addProp(varNames, varValues)
	setmetatable(result, self)
	return result
end



Enviornment = {}
Enviornment.__index = Enviornment



function Enviornment.initEnviornment()
	return Enviornment:new(Procedure.primitiveProcedures)
end



function Enviornment:new(frame, enclosing)
	local result = {}
	result.frame = frame
	result.enclosing = enclosing
	setmetatable(result, self)
	return result
end



function Enviornment:lookup(var)
	if self.frame[var] then
		if self.frame[var] == nil_val then
			return nil
		else
			return self.frame[var]
		end
	elseif self.enclosing then
		return self.enclosing:lookup(var)
	else
		return nil
	end
end



function Enviornment:setVar(var, val)
	if self.frame[var] then
		val = val or nil_val
		self.frame[var] = val
		return val
	elseif self.enclosing then
		return self.enclosing:setVar(var, val)
	else
		return nil
	end
end



function Enviornment:defineVar(var, val)
	val = val or nil_val
	if not self:setVar(var, val) then
		self.frame[var] = val
	end
end



--- evaluation


function Enviornment:eval(exp)
	if is_self_evaluating(exp) then
		return exp
	elseif is_quoted(exp) then
		return text_of_quotation(exp)
	elseif is_variable(exp) then
		return self:lookup(exp)
	elseif is_assignment(exp) then
		return self:evalAssignment(exp)
	elseif is_definition(exp) then
		return self:evalDefinition(exp)
	elseif is_if(exp) then
		return self:evalIf(exp)
	elseif is_and(exp) then
		print(and_to_if(cdr(exp)))
		return self:eval(and_to_if(cdr(exp)))
	elseif is_or(exp) then
		return self:eval(or_to_if(cdr(exp)))
	elseif is_not(exp) then
		return self:eval(not_to_if(cdr(exp)))
	elseif is_lambda(exp) then
		return Procedure:new(
					lambda_param(exp),
					lambda_body(exp),
					self)
	elseif is_let(exp) then
		return self:eval(let_to_lambda_apply(exp))
	elseif is_begin(exp) then
		return self:evalSequence(exp)
	elseif is_cond(exp) then
		return self:eval(cond_to_if(exp))
	elseif is_force(exp) then
		local operator = self:eval(cadr(exp))
		return operator:apply(nil)
	elseif is_delay(exp) then
		return self:evalDelay(exp)
	elseif is_cons_stream(exp) then
		local toCar = cadr(exp)
		local toCdr = make_lambda(nil, cdr(cdr(exp)))
		return self:eval(list('cons', toCar, toCdr))
	elseif is_application(exp) then
		local operator = self:eval(car(exp))
		local operands = self:listOfValues(cdr(exp))
		if operator == nil or getmetatable(operator) ~= Procedure then
			error("Invalid operator in application: " .. tostring(exp))
		end
		return operator:apply(operands)
	else
		return nil
	end
end



function Enviornment:evalAssignment(exp)
	local assign_var = assignment_variable(exp)
	local assign_val = assignment_value(exp)
	self:setVar(assign_var,
			    self:eval(assign_val))
end



function Enviornment:evalDefinition(exp)
	self:defineVar(definition_var(exp),
				   self:eval(definition_val(exp)))
end



function Enviornment:evalIf(exp)
	if self:eval(if_predicate(exp)) then
		return self:eval(if_consequent(exp))
	else
		return self:eval(if_alternative(exp))
	end
end



function Enviornment:evalDelay(exp)
	local body = cdr(exp)
	return self:eval(make_lambda(nil, body))
end



function Enviornment:evalSequence(exp)
	local result = self:eval(first_exp(exp))
	if is_last_exp(exp) then
		return result
	else
		return self:evalSequence(rest_exp(exp))
	end
end



function Enviornment:listOfValues(exps)
	if exps == nil then
		return nil
	else
		return cons(self:eval(car(exps)),
					self:listOfValues(cdr(exps)))
	end
end


--                   -- environment structure --                       --
-------------------------------------------------------------------------




-------------------------------------------------------------------------
--                    -- ---- procedure ---- --                        --



Procedure = {}
Procedure.__index = Procedure


local function primitive_null(exp)
	return exp == nil
end


local function primitive_atom(exp)
	return not is_pair(exp)
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



function Procedure:new(params, body, env, type)
	local result = {
		params = params,
		body = body,
		env = env,
		type = type or 'procedure'
	}
	setmetatable(result, self)
	return result
end


Procedure.primitiveProcedures = {
	["car"] = Procedure:new(nil, car, nil, 'primitive'),
	["cdr"] = Procedure:new(nil, cdr, nil, 'primitive'),
	["cons"] = Procedure:new(nil, cons, nil, 'primitive'),
	["list"] = Procedure:new(nil, list, nil, 'primitive'),
	["null?"] = Procedure:new(nil, primitive_null, nil, 'primitive'),
	["pair?"] = Procedure:new(nil, is_pair, nil, 'primitive'),
	["atom?"] = Procedure:new(nil, primitive_atom, nil, 'primitive'),
	["+"] =  Procedure:new(nil, primitive_algebra('+'), nil, 'primitive'),
	["-"] =  Procedure:new(nil, primitive_algebra('-'), nil, 'primitive'),
	["*"] =  Procedure:new(nil, primitive_algebra('*'), nil, 'primitive'),
	["/"] =  Procedure:new(nil, primitive_algebra('/'), nil, 'primitive'),
	["<"] =  Procedure:new(nil, primitive_algebra('<'), nil, 'primitive'),
	[">"] =  Procedure:new(nil, primitive_algebra('>'), nil, 'primitive'),
	["eq?"] = Procedure:new(nil, primitive_algebra('=='), nil, 'primitive'),
	["="] = Procedure:new(nil, primitive_algebra('=='), nil, 'primitive'),
	["print"] = Procedure:new(nil, print, nil, 'primitive'),
}
setmetatable(Procedure.primitiveProcedures, Frame)



function Procedure:isPrimitive()
	return self.type == 'primitive'
end



function Procedure:isCombound()
	return self.type == 'procedure'
end



function Procedure:apply(arguments)
	if self:isPrimitive() then
		return apply_primitive_procedure(self.body, arguments)
	elseif self:isCombound() then
		local newEnv = Enviornment:new(
							Frame:newFromList(
										self.params,
										arguments),
							self.env)
		return newEnv:evalSequence(self.body)
	end
end




function apply_primitive_procedure(proc, args)
	return proc(list_unpack(args))
end



--                    -- ---- procedure ---- --                        --
-------------------------------------------------------------------------



-------------------------------------------------------------------------
--                   -- expression predicates --                       --




function is_self_evaluating(exp)
	return (type(exp) == 'string' and string.sub(exp, 1, 1) == "'") or
		    type(exp) == 'number' or type(exp) == 'boolean' or
		    false
end



function is_variable(exp)
	return (type(exp) == 'string' and (not is_self_evaluating(exp)))
end


local function is_tagged(exp, tag)
	return is_pair(exp) and
		   car(exp) == tag
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
	return cdr(exp) == nil
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



--                   -- expression predicates --                       --
-------------------------------------------------------------------------




-------------------------------------------------------------------------
--                      -- evaluation rules --                         --


function text_of_quotation(exp)
	return cadr(exp)
end



--- assignment


function assignment_variable(exp)
	return cadr(exp)
end



function assignment_value(exp)
	return cadr(cdr(exp))
end



--- lambda / function


function make_lambda(params, body)
	return cons('lambda', cons(params, body))
end


function definition_var(exp)
	local var = cadr(exp)
	if is_pair(var) then
		return car(var)
	else
		return var
	end
end



function definition_val(exp)
	local var = cadr(exp)
	if is_pair(var) then
		local param = cdr(car(cdr(exp)))
		local body = cdr(cdr(exp))
		return make_lambda(param, body)
	else
		return car(cdr(cdr(exp)))
	end
end



function lambda_param(exp)
	return cadr(exp)
end



function lambda_body(exp)
	return cdr(cdr(exp))
end



--- if / if-else


function if_predicate(exp)
	return cadr(exp)
end



function if_consequent(exp)
	return cadr(cdr(exp))
end



function if_alternative(exp)
	local alt = cadr(cdr(cdr(exp)))
	if alt then
		return alt
	else
		return 'false'
	end
end


local function make_if(predicate, consequent, alternative)
	return list('if', predicate, consequent, alternative)
end


--- cond


function cond_clauses(exp)
	return cdr(exp)
end



function cond_to_if(exp)
	return expaned_clauses(cond_clauses(exp))
end



function cond_predicate(clause)
	return car(clause)
end



function cond_action(clause)
	return cdr(clause)
end


function is_cond_else_clause(clause)
	return cond_predicate(clause) == 'else'
end



function expaned_clauses(clauses)
	if clauses == nil then
		return 'false'
	elseif is_cond_else_clause(car(clauses)) then
		if cdr(clauses) == nil then
			return sequence_to_exp(cond_action(car(clauses)))
		else
			return nil
		end
	else
		return make_if(cond_predicate(car(clauses)),
					   sequence_to_exp(cond_action(car(clauses))),
					   expand_clauses(cdr(clauses)))
	end
end


--- relation


function and_to_if(exp)
	if cdr(exp) == nil then
		return car(exp)
	else
		return make_if(car(exp), and_to_if(cdr(exp)), false)
	end
end


function or_to_if(exp)
	if cdr(exp) == nil then
		return car(exp)
	else
		return make_if(car(exp), true, or_to_if(cdr(exp)))
	end
end


function not_to_if(exp)
	return make_if(car(exp), false, true)
end



--- sequence


function first_exp(sequence)
	return car(sequence)
end



function last_exp(sequence)
	return cdr(sequence) == nil
end



function rest_exp(sequence)
	return cdr(sequence)
end



function begin_actions(exp)
	return cdr(exp)
end


local function make_begin(sequence)
	return cons('begin', sequence)
end


function sequence_to_exp(sequence)
	if sequence == nil then
		return nil
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
	return cons(lambda, arguments)
end



function let_to_lambda(exp)
	local param = let_lambda_parameter(exp)
	local body = let_lambda_body(exp)
	return make_lambda(param, body)
end



function let_lambda_parameter(exp)
	return map(car, cadr(exp))
end


function let_arguments(exp)
	return map(cadr, cadr(exp))
end


function let_lambda_body(exp)
	return cdr(cdr(exp))
end


--                      -- evaluation rules --                         --
-------------------------------------------------------------------------



return _ENV