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
	double widthAsDouble;
	double heightAsDouble;
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
