//
//  benchmark.c
//  benchmark
//
//  Created by Middleware on 3/24/15.
//  Copyright (c) 2015 fengdong. All rights reserved.
//

#include "benchmark.h"


#include "lua.h"
#include "lauxlib.h"

#include <sys/time.h>
#include <string.h>

#include "benchmark_info.h"


static int lua_begin(lua_State* L);
static int lua_end(lua_State* L);
static int lua_time(lua_State* L);

static int lua_install_hook(lua_State* L);
static int lua_get_call_summary(lua_State* L);
static int lua_clear_call_summary(lua_State* L);


static const char* event_to_string(int event);
static void benchmark_hook(lua_State *L, lua_Debug *ar);




static const luaL_Reg extension[] =
{
	"begin_run", lua_begin,
	"end_run", lua_end,
	"time", lua_time,
	
	"install_hook", lua_install_hook,
	"get_call_summary", lua_get_call_summary,
	"clear_call_summary", lua_clear_call_summary,
	NULL, NULL,
};

struct timeval s_begin, s_end;


static int lua_begin(lua_State* L)
{
	gettimeofday(&s_begin, NULL);
	return 0;
}


static int lua_end(lua_State* L)
{
	gettimeofday(&s_end, NULL);
	
	double diff = (s_end.tv_sec - s_begin.tv_sec) + ((float)(s_end.tv_usec - s_begin.tv_usec)) / 1000000.0;
	lua_pushnumber(L, diff);
	
	return 1;
}



static int lua_time(lua_State* L)
{
	struct timeval timev;
	gettimeofday(&timev, NULL);
	lua_pushnumber(L, timev.tv_sec + ((float)timev.tv_usec) / 1000000.0);
	
	return 1;
}



int luaopen_benchmark(lua_State *L)
{
	luaL_newlib(L, extension);
	return 1;
}






static int lua_install_hook(lua_State* L)
{
	lua_sethook(L, benchmark_hook, LUA_MASKCALL | LUA_MASKRET, 0);
	return 0;
}



int lua_get_call_summary(lua_State* L)
{
	size_t count;
	const char** name;
	double* time;
	function_calls_info(&name, &time, &count);
	
	lua_newtable(L);
	for (size_t i = 0; i < count; ++i) {
		const char* function_name = name[i];
		double this_time = time[i];
		
		lua_pushnumber(L, this_time);
		lua_setfield(L, -2, function_name);
	}
	
	return 1;
}


int lua_clear_call_summary(lua_State* L)
{
	function_calls_info_clear();
	lua_sethook(L, NULL, 0, 0);
	return 0;
}



static void benchmark_hook(lua_State *L, lua_Debug *ar)
{
	lua_getstack(L, 0, ar);
	lua_getinfo(L, "nS", ar);
	
	static char name[128];
	sprintf(name, "%s:%s,%d", event_to_string(ar->event), ar->source, ar->linedefined);
	
	switch (ar->event) {
		case LUA_HOOKCALL:
			function_called(name);
			break;
		case LUA_HOOKTAILCALL:
			function_tailcalled(name);
		case LUA_HOOKRET:
			function_returned();
		default:
			break;
	}
}




static const char* event_to_string(int event)
{
	switch (event) {
		case LUA_HOOKCALL:
			return "Call";
		case LUA_HOOKRET:
			return "Return";
		case LUA_HOOKTAILCALL:
			return "Tail Call";
		case LUA_HOOKLINE:
			return "Line";
		case LUA_HOOKCOUNT:
			return "Count";
		default:
			break;
	}
	return "Unknown";
}






