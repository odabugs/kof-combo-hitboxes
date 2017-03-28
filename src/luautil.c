#include "luautil.h"

int lTraceback(lua_State *L)
{
	if (!lua_isstring(L, 1))  // 'message' not a string?
	{
		return 1;  // keep it intact
	}
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	if (!lua_istable(L, -1))
	{
		lua_pop(L, 1);
		return 1;
	}
	lua_getfield(L, -1, "traceback");
	if (!lua_isfunction(L, -1))
	{
		lua_pop(L, 2);
		return 1;
	}
	lua_pushvalue(L, 1);  // pass error message
	lua_pushinteger(L, 2);  // skip this function and traceback
	lua_call(L, 2, 1);  // call debug.traceback
	return 1;
}

static int lRegEntryCount(const luaL_Reg *reg)
{
	if (reg == (luaL_Reg*)NULL) { return 0; }

	int i = 0;
	const luaL_Reg *current = (const luaL_Reg*)&(reg[i]);
	while ((current->name != (char*)NULL) && (current->func != (lua_CFunction)NULL))
	{
		current = (const luaL_Reg*)&(reg[++i]);
	}

	return i;
}

static int lRegSetEntryCount(const lRegSet *regs)
{
	if (regs == (lRegSet*)NULL) { return 0; }

	int i = 0;
	const lRegSet *current = (const lRegSet*)&(regs[i]);
	while ((current->name != (char*)NULL) && (current->reg != (luaL_Reg*)NULL))
	{
		current = (const lRegSet*)&(regs[++i]);
	}

	return i;
}

// Creates a new table at the top of the Lua stack,
// containing all the tables created by calls to luaL_register()
int lRegisterAll(lua_State *L, const lRegSet *regs, bool asGlobals)
{
	if (L == (lua_State*)NULL || regs == (lRegSet*)NULL) { return 0; }
	// this table will be at the top of the Lua stack when this function returns
	lua_createtable(L, 0, lRegSetEntryCount(regs));

	int i = 0;
	const lRegSet *current = (const lRegSet*)&(regs[i]);
	while ((current->name != (char*)NULL) && (current->reg != (luaL_Reg*)NULL))
	{
		lua_pushstring(L, current->name);
		if (asGlobals)
		{
			luaL_register(L, current->name, current->reg);
		}
		else
		{
			lua_createtable(L, 0, lRegEntryCount(current->reg));
			luaL_register(L, NULL, current->reg);
		}
		lua_settable(L, -3);
		current = (const lRegSet*)&(regs[++i]);
	}

	return i;
}
