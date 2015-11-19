#ifndef DRAW_H
#define DRAW_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <stdbool.h>
#include "playerstruct.h"
#include "coords.h"
#include "gamedefs.h"
#include "gamestate.h"
#include "colors.h"
#include "hotkeys.h"
#include "util.h"
#include "boxtypes.h"
#include "boxset.h"

extern void drawScene(game_state_t *source);

#endif /* DRAW_H */
