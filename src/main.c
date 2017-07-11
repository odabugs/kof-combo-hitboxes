// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#include <conio.h>
#include <stdlib.h>
#include <stdio.h>
#include <luajit.h>
#include <lualib.h>
#include <lauxlib.h>
#include "luautil.h"
#include "directx.h"

static lRegSet luaExports[] = {
	{ "directx", lib_directX },
	{ NULL, NULL } // sentinel
};
static char *LUA_LOAD_ERROR_LINE = "Failed to load Lua script: %s\n";
static char *LUA_RUN_ERROR_LINE = "Error occurred inside Lua script: %s\n";
void showLuaError(lua_State *L, char *errline);

int WINAPI WinMain(
    HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpArgv, int nShowCmd)
{
	int result;
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	lua_pushcfunction(L, lTraceback);
	int status = luaL_loadfile(L, "lua/main.lua");
	if (status != 0) {
		showLuaError(L, LUA_LOAD_ERROR_LINE);
	}
	// parse Lua scripts
	result = lua_pcall(L, 0, 0, 1);
	if (result != 0) {
		showLuaError(L, LUA_RUN_ERROR_LINE);
	}
	// call main() in Lua, with hInstance as first argument
	lua_getglobal(L, "main");
	lua_pushinteger(L, (lua_Integer)hInstance);
	lRegisterAll(L, luaExports, false);
	result = lua_pcall(L, 2, LUA_MULTRET, 1);
	if (result != 0) {
		showLuaError(L, LUA_RUN_ERROR_LINE);
	}
	lua_close(L);
	return 0;
}

void showLuaError(lua_State *L, char *errline)
{
	printf(errline, lua_tostring(L, -1));
	printf("Press any key to exit.\n");
	while (_kbhit() == 0) { Sleep(5); } // wait for keypress
	exit(1);
}
