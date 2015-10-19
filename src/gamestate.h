#ifndef GAMESTATE_H
#define GAMESTATE_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <stdbool.h>
#include "playerstruct.h"
#include "coords.h"
#include "gamedefs.h"

typedef struct game_state
{
	player_t players[PLAYERS];
	player_extra_t playersExtra[PLAYERS];
	player_2nd_extra_t players2ndExtra[PLAYERS];
	camera_t camera;
	screen_dimensions_t dimensions;
	gamedef_t gamedef;
	DWORD processID;
	HWND wHandle;
	HANDLE wProcHandle;
	HDC hdc;
} game_state_t;

extern bool detectGame(game_state_t *target, gamedef_t gamedefs[]);
extern void establishScreenDimensions(
	screen_dimensions_t *dims, gamedef_t *source);
extern bool openGame(game_state_t *target);
extern void closeGame(game_state_t *target);
extern void readGameState(game_state_t *target);
extern bool shouldDisplayPlayer(game_state_t *target, int which);
extern character_def_t *characterForID(game_state_t *source, int charID);
extern char *characterNameForID(game_state_t *source, int charID);

#endif /* GAMESTATE_H */
