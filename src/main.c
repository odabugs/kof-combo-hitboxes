// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <winuser.h>
#include <stdlib.h>
#include <stdio.h>
#include "playerstruct.h"
#include "render.h"
#include "draw.h"
#include "gamedefs.h"
#include "gamestate.h"

#define SLEEP_TIME 10 /* ms */
#define QUIT_KEY 0x51 /* Q key */

HWND myself;
HANDLE myStdin;
game_state_t gameState;

void startupProgram();
void cleanupProgram();
void mainLoop();
void drawNextFrame();
bool checkShouldContinueRunning();

int main(int argc, char **argv)
{
	startupProgram();
	printf("Game detected: %s\n", gameState.gamedef.shortName);
	printf("We recommend setting your game to %s resolution.\n",
		gameState.gamedef.recommendResolution);
	printf("Press Q in this console window to exit the hitbox viewer.\n");

	mainLoop();
	cleanupProgram();
	return 0;
}

void mainLoop()
{
	bool running = true;
	while (running)
	{
		drawNextFrame();
		Sleep(SLEEP_TIME);
		running = checkShouldContinueRunning();
	}
}

void startupProgram()
{
	if (!detectGame(&gameState, gamedefs_list))
	{
		printf("Failed to detect any supported game running.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}
	if (gameState.processID == (DWORD)NULL)
	{
		printf("Could not find target window.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}
	openGame(&gameState);
	if (gameState.wProcHandle == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handle to target process.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}
	myself = GetConsoleWindow();
	myStdin = GetStdHandle(STD_INPUT_HANDLE);
	if (myself == (HWND)NULL || myStdin == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handles to this console window.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}

	setupDrawing();
}

void cleanupProgram()
{
	closeGame(&gameState);
	teardownDrawing();
	printf("Exiting now.\n");
}

void drawNextFrame()
{
	readGameState(&gameState);
	drawScene(&gameState);
}

bool checkShouldContinueRunning()
{
	// zeroing out the low bit prevents an issue where pressing the
	// quit key in another window then switching focus to the hitbox
	// viewer's console window still causes the viewer to quit
	SHORT quitKeyPressed = (GetAsyncKeyState(QUIT_KEY) & ~1);
	if (quitKeyPressed && (GetForegroundWindow() == myself))
	{
		FlushConsoleInputBuffer(myStdin);
		return false;
	}
	return true;
}
