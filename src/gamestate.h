#ifndef GAMESTATE_H
#define GAMESTATE_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wingdi.h>
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501 /* this is silly */
#include <uxtheme.h>
#undef _WIN32_WINNT
#include <GL/gl.h>
#include <GL/glu.h>
#include <stdlib.h>
#include <stdbool.h>
#include "playerstruct.h"
#include "coords.h"
#include "gamedefs.h"

typedef HRESULT (WINAPI *dwm_extend_frame_fn)(HWND, PMARGINS);
typedef HRESULT (WINAPI *dwm_comp_enabled_fn)(BOOL *);

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
	HMODULE dwmapi;
	HGLRC hglrc; // OpenGL rendering context
} game_state_t;

extern bool detectGame(game_state_t *target, gamedef_t *gamedefs[]);
extern void establishScreenDimensions(screen_dimensions_t *dims, gamedef_t *source);
extern bool openGame(game_state_t *target, HINSTANCE hInstance, WNDPROC wndProc);
extern void closeGame(game_state_t *target);
extern void readGameState(game_state_t *target);
extern bool shouldDisplayPlayer(game_state_t *target, int which);
extern character_def_t *characterForID(game_state_t *source, int charID);
extern char *characterNameForID(game_state_t *source, int charID);

#endif /* GAMESTATE_H */
