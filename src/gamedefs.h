#ifndef GAMEDEFS_H
#define GAMEDEFS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
//#include <tchar.h>
#include <stdlib.h>
#include "playerstruct.h"
#include "render.h"

#define PLAYERS 2

typedef struct game_definition
{
	char *windowTitle;
	char *shortName;
	void *playerAddresses[PLAYERS];
	void *cameraAddress;
	// should be the width:height closest to 1:1 scale for onscreen objects
	// (e.g., use 320x224 for kof98/02 even though the smallest resolution
	// offered by the steam versions is 640x448 which amounts to 2:1 scale)
	int basicWidth;
	int basicHeight;
	char *recommendResolution;
	char *extraRecommendations;
	double groundOffset; // from BOTTOM edge of game screen (at 1:1 scale)
	aspect_mode_t aspectMode; // how does the game handle widescreen?
} gamedef_t;

extern gamedef_t gamedefs_list[];

#endif /* GAMEDEFS_H */
