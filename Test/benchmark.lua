




package.cpath = package.cpath .. ";./lib/target/lib?.dylib"
local benchmark = require "benchmark"



------------------------------------------------------------------------
--
--   Regular Lua Version
--
------------------------------------------------------------------------


function factorCount(n)
	local square = math.sqrt(n)
	local isquare = math.floor(square)
	local count = (isquare == square) and -1 or 0

	for candidate = 1, isquare do
		if (0 == math.fmod(n, candidate)) then
			count = count + 2
		end
	end

	return count
end


benchmark.begin_run();

local triangle = 1
local index = 1
local iterate_num = 70

while factorCount(triangle) < iterate_num do
	index = index + 1
	triangle = triangle + index
end

local time = benchmark.end_run()

print("Triangle: " .. triangle .. " takes " .. time)




------------------------------------------------------------------------
--
--   Recursive Lua Version
--
------------------------------------------------------------------------



local function factorCount_recur(n)
    local square = math.sqrt(n)
    local isquare = math.floor(square)
    local count = (isquare == square) and -1 or 0

    local function doCount(candidate, count)
        if candidate == isquare then
            if math.fmod(n, candidate) == 0 then
                return count + 2
            else
                return count
            end
        else
            if math.fmod(n, candidate) == 0 then
                return doCount(candidate + 1, count + 2)
            else
                return doCount(candidate + 1, count)
            end
        end
    end

    return doCount(1, count)
end



benchmark.begin_run();


local function doMain(index, triangle)
    if factorCount_recur(triangle) < iterate_num then
        return doMain(index + 1, index + 1 + triangle)
    else
        return triangle
    end
end

triangle = doMain(1, 1)


time = benchmark.end_run()

print("(Recursive Version) Triangle: " .. triangle .. " takes " .. time)









------------------------------------------------------------------------
--
--   Lisp Version
--
------------------------------------------------------------------------



local quote = require "quote"
local eval = require "eval_cont"
local eval_reg = require "eval"
local lisp = require "lisp"

local file = io.open("Test/benchmark.lisp", "r")
local arg = select(1, ...)
local regular_eval = (arg == 'no-callcc')

if not(file) or io.type(file) ~= "file" then
	print("File not found: " .. filename)
	os.exit()
end

local lisp_src = file:read("a")
local s_exp = quote.quote(lisp_src)

-- print("Source: ")
-- print(lisp.list_tostring(s_exp, true) .. "\n")

local env = eval.Environment.initEnv()
local bottom_cont = eval.ContinuationBottom:new(print)
local env_regular = eval_reg.Enviornment.initEnviornment()

benchmark.begin_run()
benchmark.install_hook()

env:define("iterate_num", iterate_num, bottom_cont)
env_regular:defineVar("iterate_num", iterate_num)

local value
if not regular_eval then
    value = eval.eval_begin(s_exp, env, bottom_cont)
else
    value = env_regular:evalSequence(s_exp)
end

local benchmark_result = benchmark.get_call_summary()
benchmark.clear_call_summary()
time = benchmark.end_run()

print("Triangle: " .. value .. " takes " .. time)



------------------------------------------------------------------------
--
--   Benchmark Report
--
------------------------------------------------------------------------


print("");
print("Benchmark:")
for k, v in pairs(benchmark_result) do
    print(k .. "  ", v)
end





