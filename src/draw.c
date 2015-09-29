#include "draw.h"

#define PIVOTSIZE 10
#define PIVOTWIDTH 1

void drawPivot(
	HDC hdcArea, player_t player, screen_dimensions_t dimensions,
	camera_t camera)
{
	screen_coords_t coords;
	translatePlayerCoords(player, dimensions, camera, &coords);
	int x = coords.x, y = coords.y;
	//printf("Drawing to %d, %d\n", x, y);

	SelectObject(hdcArea, GetStockObject(WHITE_BRUSH));
	Rectangle(hdcArea,
		x - PIVOTSIZE - PIVOTWIDTH, y - PIVOTWIDTH,
		x + PIVOTSIZE + PIVOTWIDTH, y + PIVOTWIDTH);
	Rectangle(hdcArea,
		x - PIVOTWIDTH, y - PIVOTSIZE - PIVOTWIDTH,
		x + PIVOTWIDTH, y + PIVOTSIZE + PIVOTWIDTH);
}

extern void drawPlayer(game_state_t *source, int which)
{
	drawPivot(source->hdc, source->players[which], source->dimensions,
		source->camera);
}
