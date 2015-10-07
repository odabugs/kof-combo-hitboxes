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

// TODO: implement this shit
typedef enum
{
	// game supports only one aspect and enforces it when window is scaled
	AM_FIXED,
	// game stretches to fit any aspect ratio
	AM_STRETCH,
	// game is 4:3 native and supports widescreen with vertical bars
	AM_PILLARBOX,
	// game is widescreen native and supports 4:3 with horizontal bars
	AM_LETTERBOX,
	// game is fixed aspect but centers the screen in a frame as needed
	AM_WINDOW_FRAME
} aspect_mode_t;

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
	double xScale; // scale X coords onscreen by this amount
	double yScale; // scale Y coords onscreen by this amount
	int leftOffset; // pad X coords rightward from LEFT edge by this amount
	int topOffset; // pad Y coords downward from TOP of screen by this amount
	int groundOffset; // Y coordinate on screen where ingame Y = 0 ("ground")
	double aspect; // (window width / window height)
	int basicWidth; // closest to 1:1 scale resolution
	int basicHeight; // closest to 1:1 scale resolution (in either aspect)
	double basicWidthAsDouble;
	double basicHeightAsDouble;
	double basicGroundOffset; // closest to 1:1 scale resolution
	double basicAspect; // closest to 1:1 scale resolution
	aspect_mode_t aspectMode; // how does the game handle widescreen?
} screen_dimensions_t;

// since one "world pixel" can occupy multiple "screen pixels" at large
// resolutions, this lets us request a specific "screen pixel edge"
typedef enum
{
	COORD_NORMAL       = 0x00, // top-left
	COORD_RIGHT_EDGE   = 0x01,
	COORD_BOTTOM_EDGE  = 0x02,
	COORD_BOTTOM_RIGHT = 0x03
} coord_options_t;

extern const player_coord_t baseY;

extern void getGameScreenDimensions(
	HWND handle, screen_dimensions_t *dimensions);
extern void scaleScreenCoords(
	screen_dimensions_t *dimensions, screen_coords_t *target,
	coord_options_t options);
extern void translateAbsoluteGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	screen_coords_t *target, coord_options_t options);
extern void translateRelativeGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options);
extern void translatePlayerCoords(
	player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options);
extern void worldCoordsFromPlayer(
	player_t *player, player_coords_t *target);
extern void relativizeWorldCoords(
	camera_t *camera, player_coords_t *target);
extern void adjustWorldCoords(player_coords_t *target,
	int xAdjust, int yAdjust);
extern void swapYComponents(player_coords_t *left, player_coords_t *right);

#endif /* RENDER_H */
