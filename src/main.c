// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <winuser.h>
#include <stdlib.h>
#include <stdio.h>
#include "playerstruct.h"
#include "coords.h"
#include "draw.h"
#include "gamedefs.h"
#include "gamestate.h"
#include "controlkey.h"

#define SLEEP_TIME 10 /* ms */
#define QUIT_KEY 0x51 /* Q key */

HWND myself;
HANDLE myStdin;
game_state_t gameState;

void startupProgram();
void cleanupProgram();
void mainLoop();
void drawNextFrame();
bool checkShouldContinueRunning(char **reason);
LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(
    HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpArgv, int nShowCmd)
{
	startupProgram(hInstance);
	printf("Game detected: %s\n", gameState.gamedef.shortName);
	printf("We recommend setting your game to %s resolution in windowed mode.\n",
		gameState.gamedef.recommendResolution);
	if (gameState.gamedef.extraRecommendations != (char*)NULL)
	{
		printf("%s\n", gameState.gamedef.extraRecommendations);
	}
	printf("Press Q in this console window to exit the hitbox viewer.\n");

	mainLoop();
	cleanupProgram();
	return 0;
}

void mainLoop()
{
	bool running = true;
	char *quitReason = (char*)NULL;
	MSG message;

	while (running)
	{
		//*
		while (PeekMessage(&message, NULL, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&message);
			DispatchMessage(&message);
			//printf("hola\n");
		}

		drawNextFrame();
		//*/
		Sleep(SLEEP_TIME);
		running = checkShouldContinueRunning(&quitReason);
	}

	if (quitReason != (char*)NULL)
	{
		printf("%s\n", quitReason);
	}
}

void startupProgram(HINSTANCE hInstance)
{
	bool bailout = false;
	if (!detectGame(&gameState, gamedefs_list))
	{
		printf("Failed to detect any supported game running.\n");
		bailout = true;
	}
	if (gameState.gameProcessID == (DWORD)NULL)
	{
		printf("Could not find target window.\n");
		bailout = true;
	}
	openGame(&gameState, hInstance, WindowProc);
	if (gameState.gameHandle == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handle to target process.\n");
		bailout = true;
	}
	myself = GetConsoleWindow();
	myStdin = GetStdHandle(STD_INPUT_HANDLE);
	if (myself == (HWND)NULL || myStdin == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handles to this console window.\n");
		bailout = true;
	}

	if (bailout)
	{
		printf("Exiting now.\n");
		exit(EXIT_FAILURE);
	}
}

void cleanupProgram()
{
	closeGame(&gameState);
	printf("Exiting now.\n");
}

void drawNextFrame()
{
	readGameState(&gameState);
	drawScene(&gameState);
}

bool checkShouldContinueRunning(char **reason)
{
	// zeroing out the low bit prevents an issue where pressing the
	// quit key in another window then switching focus to the hitbox
	// viewer's console window still causes the viewer to quit
	if (keyIsPressed(QUIT_KEY) && (GetForegroundWindow() == myself))
	{
		FlushConsoleInputBuffer(myStdin);
		*reason = "User closed the hitbox viewer.";
		return false;
	}
	// IsWindow() can potentially return true if the window handle is
	// recycled, but we're checking it too frequently to worry about that
	if (!IsWindow(gameState.gameHwnd))
	{
		*reason = "User closed the game as it was running.";
		return false;
	}
	return true;
}

LRESULT CALLBACK WindowProc(
	HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
		default:
			return DefWindowProc(hwnd, message, wParam, lParam);
	}

	return 0;
}
