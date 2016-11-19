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
	projectile_t *projectiles; // projectiles array malloc'd during openGame()
	camera_t camera;
	screen_dimensions_t dimensions;
	gamedef_t gamedef;
	DWORD gameProcessID;
	HWND gameHwnd;
	HANDLE gameHandle;
	HDC gameHdc; // GDI device context
	HINSTANCE hInstance;
	HWND overlayHwnd;
	HDC overlayHdc;
	WNDPROC wndProc; // window message pump
} game_state_t;

extern game_state_t gameState;

extern void establishScreenDimensions(screen_dimensions_t *dims, gamedef_t *source);
extern void readGameState(game_state_t *target);
extern bool shouldDisplayPlayer(game_state_t *target, int which);

#endif /* GAMESTATE_H */
