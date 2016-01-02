#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#include <string.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include "playerstruct.h"
#include "coords.h"
#include "util.h"

extern void drawRectangle(player_coords_t *topLeft, player_coords_t *bottomRight);
extern void drawScreenRectangle(screen_coords_t *topLeft, screen_coords_t *bottomRight);
extern void drawDot(player_coords_t *location);
extern void drawBox(player_coords_t *topLeft, player_coords_t *bottomRight);
extern void drawPivot(player_coords_t *pivot, int pivotSize);

#endif /* PRIMITIVES_H */
