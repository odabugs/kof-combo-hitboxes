#ifndef DRAW_H
#define DRAW_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "playerstruct.h"
#include "render.h"
#include "gamestate.h"

extern void drawPivot(
	HDC hdcArea, player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera);
extern void drawPlayer(game_state_t *source, int which);
extern void drawScene(game_state_t *source);

#endif /* DRAW_H */
