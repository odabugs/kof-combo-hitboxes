#ifndef LUAUTIL_H
#define LUAUTIL_H
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <luajit.h>
#include <lualib.h>
#include <lauxlib.h>

typedef struct {
	const char *name;
	const luaL_Reg *reg;
} lRegSet;

extern int lTraceback(lua_State *L);
extern int lRegisterAll(lua_State *L, const lRegSet *regs, bool asGlobals);

#endif /* LUAUTIL_H */
