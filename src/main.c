// to compile with MinGW: mingw32-make
// TODO: support Visual Studio
#define WIN32_LEAN_AND_MEAN
// required for use of GetConsoleWindow() et al.
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <winuser.h>
#include <stdlib.h>
#include <stdio.h>
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

int WINAPI WinMain(
    HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpArgv, int nShowCmd)
{
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

void printHeader()
{
	printf("%s, version %s\n", TITLE, VERSION);
	printf("<%s>\n", HOMEPAGE);
	printf("Note: This tool requires Windows Vista or newer with Windows Aero enabled.\n");
	printf("Additionally, please ensure that the Desktop Window Manager service is enabled.\n");
	printf("\n");
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
