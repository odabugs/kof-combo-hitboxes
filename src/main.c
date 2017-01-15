// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <winuser.h>
#include <stdlib.h>
#include <stdio.h>
#include <luajit.h>
#include <lualib.h>
#include <lauxlib.h>
#include "directx.h"
#include "coords.h"
#include "draw.h"
#include "gamedefs.h"
#include "gamestate.h"
#include "process.h"

#define TITLE "King of Fighters 2-in-1 Hitbox Viewer"
#define VERSION "0.0.4"
#define HOMEPAGE "https://github.com/odabugs/kof-combo-hitboxes"

#define SLEEP_TIME 10 /* ms */

void mainLoop();
void printHeader();
lua_Integer lRegEntryCount(const luaL_Reg reg[]);
static int traceback(lua_State *L);

int WINAPI WinMain(
    HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpArgv, int nShowCmd)
{
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	lua_pushcfunction(L, traceback);
	//SetCurrentDirectoryW(_T("lua"));
	int status = luaL_loadfile(L, "lua/main.lua");
	if (status != 0) {
		printf("Failed to load Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	// parse Lua scripts
	int result = lua_pcall(L, 0, 0, 1);
	if (result != 0) {
		printf("Error occurred inside Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	// call main() in Lua, with hInstance as first argument
	lua_getglobal(L, "main");
	lua_pushinteger(L, (lua_Integer)hInstance);
	//lua_createtable(L, 0, DIRECTX_LUA_FUNCTIONS_COUNT);
	lua_createtable(L, 0, lRegEntryCount(lib_directX));
	luaL_register(L, NULL, lib_directX);
	//printf("hInstance = 0x%08p\n", hInstance);
	result = lua_pcall(L, 2, LUA_MULTRET, 1);
	if (result != 0) {
		printf("Error occurred inside Lua script: %s\n", lua_tostring(L, -1));
		exit(1);
	}
	lua_close(L);

	printHeader();
	startupProgram(hInstance);

	printf("\n");
	printf("We recommend setting your game to %s resolution in windowed mode.\n",
		gameState.gamedef.recommendResolution);
	if (gameState.gamedef.extraRecommendations != (char*)NULL)
	{
		printf("%s\n", gameState.gamedef.extraRecommendations);
	}
	printHotkeys();

	mainLoop();
	cleanupProgram();
	return 0;
}

static int traceback(lua_State *L)
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

void printHeader()
{
	printf("%s, version %s\n", TITLE, VERSION);
	printf("<%s>\n", HOMEPAGE);
	printf("Note: This tool requires Windows Vista or newer with Windows Aero enabled.\n");
	printf("Additionally, please ensure that the Desktop Window Manager service is enabled.\n");
	printf("\n");
}

lua_Integer lRegEntryCount(const luaL_Reg reg[])
{
	int result = 0;
	if (reg != (luaL_Reg*)NULL)
	{
		while ((reg[result].name != (char*)NULL) && (reg[result].func != (lua_CFunction)NULL))
		{
			result++;
		}
	}

	printf("lRegEntryCount returned %d for 0x%08p\n", result, reg);
	return (lua_Integer)result;
}

void mainLoop()
{
	bool running = true;
	bool printedCoords = false;
	char *quitReason = (char*)NULL;
	screen_dimensions_t *dims = &(gameState.dimensions);
	MSG message;

	while (running)
	{
		while (PeekMessage(&message, NULL, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&message);
			DispatchMessage(&message);
		}

		drawNextFrame();
		if (!printedCoords)
		{
			printedCoords = true;
			printf("Game window is located at (%d, %d) and its size is (%d, %d).\n",
				dims->leftX, dims->topY, dims->width, dims->height);
		}
		running = checkShouldContinueRunning(&quitReason);
		Sleep(SLEEP_TIME);
	}

	if (quitReason != (char*)NULL)
	{
		timestamp();
		printf("%s\n", quitReason);
	}
}
