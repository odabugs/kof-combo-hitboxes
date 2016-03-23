#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define CINTERFACE
#include <d3d9.h>
#include <d3dx9.h>
#include <stdbool.h>
#include <string.h>
#include "directx.h"
#include "playerstruct.h"
#include "coords.h"
#include "gamedefs.h"
#include "colors.h"
#include "util.h"

extern void drawRectangle(player_coords_t *topLeft, player_coords_t *bottomRight);
extern void drawScreenRectangle(screen_coords_t *topLeft, screen_coords_t *bottomRight);
extern void drawDot(player_coords_t *location);
extern void drawBox(player_coords_t *topLeft, player_coords_t *bottomRight);
extern void drawPivot(player_coords_t *pivot, int pivotSize);
extern void drawGauge(gauge_info_t *gauge, int value);

#endif /* PRIMITIVES_H */
