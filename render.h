#ifndef RENDER_H
#define RENDER_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include "playerstruct.h"

// game world coords get translated into this,
// for drawing to the game window
typedef struct screen_coords
{
	int x;
	int y;
} screen_coords_t;

typedef struct screen_dimensions
{
	union
	{
		struct
		{
			int width;
			int height;
		};
		screen_coords_t size;
	};
	int xOffset; // rightward from the LEFT edge of the game window
	int yOffset; // upward from the BOTTOM edge of the game window
	double scale; // should be equal to (game window height / 224.0)
	double aspect; // aspect ratio of game window width to height
	bool isWidescreen; // false if 4:3, true if 16:9 (pillarboxed)
} screen_dimensions_t;

extern const player_coord_t baseY;

extern void getGameScreenDimensions(
	HWND handle, screen_dimensions_t *dimensions);
extern void scaleScreenCoords(
	screen_dimensions_t dimensions, screen_coords_t *target);
extern void translateAbsoluteGameCoords(
	player_coords_t source, screen_dimensions_t dimensions,
	screen_coords_t *target);
extern void translateRelativeGameCoords(
	player_coords_t source, screen_dimensions_t dimensions,
	camera_t camera, screen_coords_t *target);
extern void translatePlayerCoords(
	player_t player, screen_dimensions_t dimensions,
	camera_t camera, screen_coords_t *target);

#endif /* RENDER_H */
