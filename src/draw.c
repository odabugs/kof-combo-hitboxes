#include "draw.h"

#define PEN_COLORS 2
#define PEN_INTERVAL 20
#define PIVOTSIZE 10
#define PIVOTWIDTH 1

HPEN pens[PEN_COLORS];
HBRUSH brushes[PEN_COLORS];
PAINTSTRUCT ps;
RECT rect;
int nextPen = 0;
int penSwitchTimer = PEN_INTERVAL;

void setupDrawing()
{
	pens[0] = CreatePen(PS_SOLID, 1, RGB(255, 0, 0)); // red
	pens[1] = CreatePen(PS_SOLID, 1, RGB(255, 255, 255)); // white
	brushes[0] = CreateSolidBrush(RGB(255, 0, 0));
	brushes[1] = CreateSolidBrush(RGB(255, 255, 255));
}

void teardownDrawing()
{
	for (int i = 0; i < PEN_COLORS; i++)
	{
		DeleteObject(pens[i]);
		DeleteObject(brushes[i]);
	}
}

int ensureMinThickness(int goal, int baseline)
{
	return max(goal, baseline) + 1;
}

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

void drawPlayer(game_state_t *source, int which)
{
	int penIndex = (nextPen + which) % PEN_COLORS;
	SelectObject(source->hdc, pens[penIndex]);
	SelectObject(source->hdc, brushes[penIndex]);
	drawPivot(source->hdc, &(source->players[which]),
		&(source->dimensions), &(source->camera));
}

void drawScene(game_state_t *source)
{
	BeginPaint(source->wHandle, &ps);

	if (penSwitchTimer-- <= 0)
	{
		nextPen = (nextPen + 1) % PEN_COLORS;
		penSwitchTimer = PEN_INTERVAL;
	}

	for (int i = 0; i < PLAYERS; i++)
	{
		drawPlayer(source, i);
	}

	EndPaint(source->wHandle, &ps);
	InvalidateRect(source->wHandle, &rect, TRUE);
}
