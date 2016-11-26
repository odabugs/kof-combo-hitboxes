#ifndef DRAW_H
#define DRAW_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#define CINTERFACE
#include <d3d9.h>
#include <stdbool.h>
#include "directx.h"
#include "playerstruct.h"
#include "coords.h"
#include "gamedefs.h"
#include "gamestate.h"
#include "process.h"
#include "colors.h"
#include "hotkeys.h"
#include "boxtypes.h"
#include "boxset.h"
#include "primitives.h"

extern void drawNextFrame();

#endif /* DRAW_H */
