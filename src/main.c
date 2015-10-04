// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <winuser.h>
#include <stdlib.h>
#include <stdio.h>
//#include <gdiplusflat.h>
//#include <detours.h>
#include "playerstruct.h"
#include "render.h"
#include "draw.h"
#include "gamedefs.h"
#include "gamestate.h"

#define PEN_COLORS 2
#define PEN_INTERVAL 20
#define SLEEP_TIME 10
#define QUIT_KEY 0x51 /* Q key */

HWND wHandle, myself;
DWORD procID;
HANDLE wProcHandle, myStdin;
HDC hdcArea;
RECT rect;
PAINTSTRUCT ps;
//HGDIOBJ penObj;
HPEN pens[PEN_COLORS];
HBRUSH brushes[PEN_COLORS];

player_t players[PLAYERS];
player_extra_t player_extras[PLAYERS];
camera_t camera;
screen_dimensions_t dimensions;
game_state_t gameState;

int main(int argc, char **argv)
{
	if (!detectGame(&gameState, gamedefs_list))
	{
		printf("Failed to detect any supported game running.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}
	wHandle = gameState.wHandle;
	procID = gameState.processID;
	if (procID == (DWORD)NULL)
	{
		printf("Could not find target window.  Exiting now.\n");
		exit(EXIT_FAILURE);
	}
	openGame(&gameState);
	wProcHandle = gameState.wProcHandle;
	if (wProcHandle == INVALID_HANDLE_VALUE || wProcHandle == NULL)
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

	printf("Game detected: %s\n", gameState.gamedef.shortName);
	printf("Press Q in this console window to exit the hitbox viewer.\n");

	hdcArea = gameState.hdc;
	pens[0] = CreatePen(PS_SOLID, 1, RGB(255, 0, 0)); // red
	pens[1] = CreatePen(PS_SOLID, 1, RGB(255, 255, 255)); // white
	brushes[0] = CreateSolidBrush(RGB(255, 0, 0));
	brushes[1] = CreateSolidBrush(RGB(255, 255, 255));

	int nextPen = 0, penSwitchTimer = PEN_INTERVAL;
	bool running = true;
	while (running)
	{
		if (penSwitchTimer <= 0)
		{
			nextPen = (nextPen + 1) % PEN_COLORS;
			penSwitchTimer = PEN_INTERVAL;
		}

		readGameState(&gameState);
		BeginPaint(wHandle, &ps);
		for (int i = 0; i < PLAYERS; i++)
		{
			SelectObject(hdcArea, pens[(nextPen + i) % PEN_COLORS]);
			SelectObject(hdcArea, brushes[(nextPen + i) % PEN_COLORS]);
			drawPlayer(&gameState, i);
		}

		EndPaint(wHandle, &ps);
		Sleep(SLEEP_TIME);
		InvalidateRect(wHandle, &rect, TRUE);
		penSwitchTimer--;

		// zeroing out the low bit prevents an issue where pressing the
		// quit key in another window then switching focus to the hitbox
		// viewer's console window still causes the viewer to quit
		SHORT quitKeyPressed = (GetAsyncKeyState(QUIT_KEY) & ~1);
		if (quitKeyPressed && (GetForegroundWindow() == myself))
		{
			FlushConsoleInputBuffer(myStdin);
			running = false;
		}
	}

	cleanupProgram();
	return 0;
}

void cleanupProgram()
{
	closeGame(&gameState);
	for (int i = 0; i < PEN_COLORS; i++)
	{
		DeleteObject(pens[i]);
		DeleteObject(brushes[i]);
	}
}
