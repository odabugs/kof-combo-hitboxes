#ifndef GAMEDEFS_H
#define GAMEDEFS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include "playerstruct.h"
#include "boxtypes.h"
#include "coords.h"

#define PLAYERS 2

typedef struct character_definition
{
	character_id_t charID;
	char *charName;
} character_def_t;

typedef struct game_definition
{
	LPCTSTR windowClassName;
	char *shortName;
	void *playerAddresses[PLAYERS];
	void *playerExtraAddresses[PLAYERS];
	void *player2ndExtraAddresses[PLAYERS];
	void *cameraAddress;
	void *projectilesListStart;
	int projectilesListSize;
	int projectilesListStep;
	// since '98 and '02 player_extra_t pointers are at different offsets in player_t
	int extraStructIndex;
	// should be the width:height closest to 1:1 scale for onscreen objects
	// (e.g., use 320x224 for kof98/02 even though the smallest resolution
	// offered by the steam versions is 640x448 which amounts to 2:1 scale)
	union
	{
		struct
		{
			int basicWidth;
			int basicHeight;
		};
		screen_coords_t basicSize;
	};
	char *recommendResolution;
	char *extraRecommendations;
	aspect_mode_t aspectMode; // how does the game handle widescreen?
	int rosterSize;
	character_def_t *roster;
	boxtype_t *boxTypeMap;
} gamedef_t;

extern gamedef_t *currentGame;
extern gamedef_t *gamedefs_list[];

extern character_def_t *characterForID(int charID);
extern char *characterNameForID(int charID);

#endif /* GAMEDEFS_H */
