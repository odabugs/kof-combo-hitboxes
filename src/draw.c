#include "draw.h"

#define PIVOTSIZE 10
#define PIVOTWIDTH 1

void drawPivot(
	HDC hdcArea, player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera)
{
	screen_coords_t coords;
	translatePlayerCoords(player, dimensions, camera, &coords, COORD_NORMAL);
	int topLeftX = coords.x, topLeftY = coords.y;
	translatePlayerCoords(player, dimensions, camera, &coords, COORD_BOTTOM_RIGHT);
	int bottomRightX = coords.x, bottomRightY = coords.y;
	//printf("(%d, %d) to (%d, %d)\n", topLeftX, topLeftY, bottomRightX, bottomRightY);

	Rectangle(hdcArea,
		topLeftX - PIVOTSIZE,
		topLeftY,
		ensureMinThickness(bottomRightX, topLeftX) + PIVOTSIZE,
		ensureMinThickness(bottomRightY, topLeftY));
	Rectangle(hdcArea,
		topLeftX,
		topLeftY - PIVOTSIZE,
		ensureMinThickness(bottomRightX, topLeftX),
		ensureMinThickness(bottomRightY, topLeftY) + PIVOTSIZE);
}

int ensureMinThickness(int goal, int baseline)
{
	return max(goal, baseline) + 1;
}

void drawPlayer(game_state_t *source, int which)
{
	drawPivot(source->hdc, &(source->players[which]), &(source->dimensions),
		&(source->camera));
}
