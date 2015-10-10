#include "draw.h"

#define PEN_COLORS 2
#define PEN_INTERVAL 20
#define PIVOTSIZE 5

static PAINTSTRUCT ps;
static RECT rect;
static HPEN pens[PEN_COLORS];
static HBRUSH brushes[PEN_COLORS];
static int nextPen = 0, penSwitchTimer = PEN_INTERVAL;

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

void drawRectangle(
	HDC hdcArea, player_coords_t *bottomLeft, player_coords_t *topRight,
	screen_dimensions_t *dimensions, camera_t *camera, bool absoluteY)
{
	screen_coords_t bottomLeftScreen, topRightScreen;
	coord_options_t options = absoluteY ? COORD_ABSOLUTE_Y : COORD_NORMAL;
	translateGameCoords(bottomLeft, dimensions, camera,
		&bottomLeftScreen, options | COORD_BOTTOM_EDGE);
	translateGameCoords(topRight, dimensions, camera,
		&topRightScreen, options | COORD_RIGHT_EDGE);
	int leftX = bottomLeftScreen.x;
	int topY = topRightScreen.y;
	int rightX = ensureMinThickness(topRightScreen.x, leftX);
	int bottomY = ensureMinThickness(bottomLeftScreen.y, topY);

	Rectangle(hdcArea, leftX, topY, rightX, bottomY);
}

void drawPivot(
	HDC hdcArea, player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera)
{
	player_coords_t pivotOriginal, pivotBottomLeft, pivotTopRight;

	// draw horizontal line of pivot cross
	absoluteWorldCoordsFromPlayer(player, &pivotOriginal);
	memcpy(&pivotBottomLeft, &pivotOriginal, sizeof(pivotOriginal));
	memcpy(&pivotTopRight, &pivotOriginal, sizeof(pivotOriginal));
	adjustWorldCoords(&pivotBottomLeft, -PIVOTSIZE, 0);
	adjustWorldCoords(&pivotTopRight, PIVOTSIZE, 0);
	drawRectangle(hdcArea, &pivotBottomLeft, &pivotTopRight, dimensions, NULL, true);

	// draw vertical line of pivot cross
	memcpy(&pivotBottomLeft, &pivotOriginal, sizeof(pivotOriginal));
	memcpy(&pivotTopRight, &pivotOriginal, sizeof(pivotOriginal));
	adjustWorldCoords(&pivotBottomLeft, 0, PIVOTSIZE);
	adjustWorldCoords(&pivotTopRight, 0, -PIVOTSIZE);
	drawRectangle(hdcArea, &pivotBottomLeft, &pivotTopRight, dimensions, NULL, true);
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
