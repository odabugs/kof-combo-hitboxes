#ifndef COORDS_H
#define COORDS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include "playerstruct.h"
#include "util.h"

#define ABSOLUTE_Y_OFFSET 16

// game world coords get translated into this,
// for drawing to the game window
typedef struct screen_coords
{
	int x;
	int y;
} screen_coords_t;

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
	// location of the overlay window on the desktop
	union
	{
		struct
		{
			int leftX;
			int topY;
		};
		screen_coords_t position;
	};
	// overlay window size; contrast with the game's "native" resolution
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
	double aspect; // (window width / window height)
	union
	{
		struct
		{
			int basicWidth; // closest to 1:1 scale resolution
			int basicHeight; // closest to 1:1 scale resolution
		};
		screen_coords_t basicSize;
	};
	double basicWidthAsDouble;
	double basicHeightAsDouble;
	double basicGroundOffset; // closest to 1:1 scale resolution
	double basicAspect; // closest to 1:1 scale resolution
	aspect_mode_t aspectMode; // how does the game handle different aspect ratios?
} screen_dimensions_t;

// since one "world pixel" can occupy multiple "screen pixels" at large
// resolutions, this lets us request a specific "screen pixel edge"
typedef enum
{
	COORD_NORMAL       = 0x00, // top-left
	COORD_RIGHT_EDGE   = 0x01,
	COORD_BOTTOM_EDGE  = 0x02,
	COORD_BOTTOM_RIGHT = 0x03, // COORD_RIGHT_EDGE & COORD_BOTTOM_EDGE
	COORD_THICK_BORDER = 0x04
} coord_options_t;

typedef enum
{
	HORZ_LEFT_EDGE,
	HORZ_CENTER,
	HORZ_RIGHT_EDGE
} screen_horz_edge_t;

typedef enum
{
	VERT_TOP_EDGE,
	VERT_CENTER,
	VERT_BOTTOM_EDGE
} screen_vert_edge_t;

extern screen_dimensions_t *screenDims;

extern void getGameScreenDimensions(
	HWND game, HWND overlay, screen_dimensions_t *dimensions);
extern void scaleScreenCoords(
	screen_dimensions_t *dimensions, screen_coords_t *target,
	coord_options_t options);
extern void translateRelativeGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options);
extern void translateGameCoords(
	player_coords_t *source, screen_coords_t *target, coord_options_t options);
extern void translatePlayerCoords(
	player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options);
extern void worldCoordsFromPlayer(player_t *player, player_coords_t *target);
extern void adjustWorldCoords(
	player_coords_t *target, game_pixel_t xAdjust, game_pixel_t yAdjust);
extern void ensureCorners(player_coords_t *topLeft, player_coords_t *bottomRight);
extern void getScreenEdgeInWorldCoords(
	player_coords_t *target, screen_horz_edge_t hEdge, screen_vert_edge_t vEdge);
extern void flipXOnAxis(player_coords_t *target, player_coords_t *axis);
extern void swapXComponents(player_coords_t *one, player_coords_t *two);
extern void copyAndAdjust(
	player_coords_t *target, player_coords_t *source, player_coords_t *adjustment);
extern void copyAndAdjustByValues(
	player_coords_t *target, player_coords_t *source, int32_t xAdjust, int32_t yAdjust);

#endif /* COORDS_H */
