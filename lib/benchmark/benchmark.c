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


static const luaL_Reg extension[] =
{
	"begin_run", lua_begin,
	"end_run", lua_end,
	"time", lua_time,
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