// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
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

HWND wHandle;
DWORD procID;
HANDLE wProcHandle;
HDC hdcArea;
RECT rect;
PAINTSTRUCT ps;
//HGDIOBJ penObj;
HPEN pens[PEN_COLORS];

player_t players[PLAYERS];
player_extra_t player_extras[PLAYERS];
camera_t camera;
screen_dimensions_t dimensions;
game_state_t gameState;

int main(int argc, char **argv)
{
	detectGame(&gameState, gamedefs_list);
	wHandle = gameState.wHandle;
	procID = gameState.processID;
	if (procID == (DWORD)NULL)
	{
		printf("Could not find target window.  Exiting now.\n");
		exit(0);
	}
	openGame(&gameState);
	wProcHandle = gameState.wProcHandle;
	if (wProcHandle == INVALID_HANDLE_VALUE || wProcHandle == NULL)
	{
		printf("Failed to obtain handle to target process.  Exiting now.\n");
		exit(0);
	}
	printf("Press Ctrl+C in this console window to stop the hitbox viewer.\n");

	hdcArea = gameState.hdc;
	pens[0] = CreatePen(PS_SOLID, 1, RGB(255, 0, 0)); // red
	pens[1] = CreatePen(PS_SOLID, 1, RGB(255, 255, 255)); // white

	int nextPen = 0, penSwitchTimer = PEN_INTERVAL;
	while (1)
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
			drawPlayer(&gameState, i);
		}

		EndPaint(wHandle, &ps);
		Sleep(SLEEP_TIME);
		InvalidateRect(wHandle, &rect, TRUE);
		penSwitchTimer--;
	}

	for (int i = 0; i < PEN_COLORS; i++)
	{
		DeleteObject(pens[i]);
	}
	return 0;
}
