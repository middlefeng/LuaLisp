

--[[
int factorCount (long n)
{
    double square = sqrt (n);
    int isquare = (int) square;
    int count = isquare == square ? -1 : 0;
    long candidate;
    for (candidate = 1; candidate <= isquare; candidate ++)
        if (0 == n % candidate) count += 2;
    return count;
}

int main ()
{
    long triangle = 1;
    int index = 1;
    while (factorCount (triangle) < 1001)
    {
        index ++;
        triangle += index;
    }
    printf ("%ld\n", triangle);
}
]]--


package.cpath = package.cpath .. ";./lib?.dylib"
local benchmark = require "benchmark"



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

while factorCount(triangle) < 100 do
	index = index + 1
	triangle = triangle + index
end

local time = benchmark.end_run()

print("Triangle: " .. triangle .. " takes " .. time)





local quote = require "quote"
local eval = require "eval_cont"
local lisp = require "lisp"

local file = io.open("Test/benchmark.lisp", "r")

if not(file) or io.type(file) ~= "file" then
	print("File not found: " .. filename)
	os.exit()
end

local lisp_src = file:read("a")
local s_exp = quote.quote(lisp_src)

print("Source: ")
print(lisp.list_tostring(s_exp, true) .. "\n")

local env = eval.Environment.initEnv()
local bottom_cont = eval.ContinuationBottom:new(print)
--local env = eval.Enviornment.initEnviornment()

benchmark.begin_run()

local value = eval.eval_begin(s_exp, env, bottom_cont)
--local value = env:evalSequence(s_exp)

time = benchmark.end_run()

print("Triangle: " .. value .. " takes " .. time)





