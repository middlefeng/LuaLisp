//
//  luaReadline.c
//  luaReadline
//
//  Created by Middleware on 3/20/15.
//  Copyright (c) 2015 fengdong. All rights reserved.
//

#include "luaReadline.h"

#include "lua.h"
#include "lauxlib.h"

#include <string.h>

#include <readline/readline.h>
#include <readline/history.h>


static int lua_readline(lua_State* L);


static const luaL_Reg extension[] =
{
	"readline", lua_readline,
	NULL, NULL,
};



static int lua_readline(lua_State* L)
{
	char* cmd;
	cmd = readline("> ");
	
	if (cmd && strlen(cmd) > 0)
		add_history(cmd);
	
	lua_pushstring(L, cmd);
	return 1;
}



int luaopen_luaReadline(lua_State *L)
{
	luaL_newlib(L, extension);
	return 1;
}