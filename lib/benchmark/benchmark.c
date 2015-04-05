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


static int lua_begin(lua_State* L);
static int lua_end(lua_State* L);
static int lua_time(lua_State* L);

static int lua_install_hook(lua_State* L);


static const char* event_to_string(int event);
static void benchmark_hook(lua_State *L, lua_Debug *ar);




static const luaL_Reg extension[] =
{
	"begin_run", lua_begin,
	"end_run", lua_end,
	"time", lua_time,
	"install_hook", lua_install_hook,
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



static void benchmark_hook(lua_State *L, lua_Debug *ar)
{
	lua_getstack(L, 0, ar);
	lua_getinfo(L, "n", ar);
	
	printf("Lua info: Name: [%s], %s.\n", ar->name, event_to_string(ar->event));
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






