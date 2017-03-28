// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#include <windows.h>
#include <winuser.h>
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

int WINAPI WinMain(
    HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpArgv, int nShowCmd)
{
	int result;
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	lua_pushcfunction(L, lTraceback);
	//SetCurrentDirectoryW(_T("lua"));
	int status = luaL_loadfile(L, "lua/main.lua");
	if (status != 0) {
		printf("Failed to load Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	// parse Lua scripts
	result = lua_pcall(L, 0, 0, 1);
	if (result != 0) {
		printf("Error occurred inside Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	// call main() in Lua, with hInstance as first argument
	lua_getglobal(L, "main");
	lua_pushinteger(L, (lua_Integer)hInstance);
	//printf("hInstance = 0x%08p\n", hInstance);
	lRegisterAll(L, luaExports, false);
	result = lua_pcall(L, 2, LUA_MULTRET, 1);
	if (result != 0) {
		printf("Error occurred inside Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	lua_close(L);
	return 0;
}
