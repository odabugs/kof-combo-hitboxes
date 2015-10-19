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
	screen_dimensions_t *dimensions, camera_t *camera, coord_options_t options)
{
	options = options & COORD_ABSOLUTE_Y;
	screen_coords_t bottomLeftScreen, topRightScreen;
	int leftX, topY, rightX, bottomY;

	translateGameCoords(bottomLeft, dimensions, camera,
		&bottomLeftScreen, options | COORD_BOTTOM_EDGE);
	translateGameCoords(topRight, dimensions, camera,
		&topRightScreen, options | COORD_RIGHT_EDGE);
	leftX   = min(bottomLeftScreen.x, topRightScreen.x);
	topY    = min(bottomLeftScreen.y, topRightScreen.y);
	rightX  = ensureMinThickness(topRightScreen.x, leftX);
	bottomY = ensureMinThickness(bottomLeftScreen.y, topY);

	Rectangle(hdcArea, leftX, topY, rightX, bottomY);
}

// TODO: fix box drawing with an extra "world pixel" added on the bottom/right
//       (i.e., ask for a 10x10 box in world pixels and you get 11x11 by outer edges)
// TODO: support "thick" and "thin" box borders (currently supports thick borders only)
//       (thick borders should "collapse" inward instead of adding thickness evenly)
void drawBox(
	HDC hdcArea, player_coords_t *bottomLeft, player_coords_t *topRight,
	screen_dimensions_t *dimensions, camera_t *camera, coord_options_t options)
{
	options = options & (COORD_ABSOLUTE_Y | COORD_THICK_BORDER);
	screen_coords_t outerBottomLeft, innerBottomLeft;
	screen_coords_t outerTopRight, innerTopRight;
	int innerLeftX, innerTopY, innerRightX, innerBottomY;
	int outerLeftX, outerTopY, outerRightX, outerBottomY;

	translateGameCoords(bottomLeft, dimensions, camera,
		&outerBottomLeft, options | COORD_BOTTOM_EDGE);
	translateGameCoords(topRight, dimensions, camera,
		&outerTopRight, options | COORD_RIGHT_EDGE);
	translateGameCoords(bottomLeft, dimensions, camera,
		&innerBottomLeft, options | COORD_RIGHT_EDGE);
	translateGameCoords(topRight, dimensions, camera,
		&innerTopRight, options | COORD_BOTTOM_EDGE);

	// handle left/top sides of the box
	outerLeftX   = min(outerBottomLeft.x, outerTopRight.x);
	innerRightX  = max(innerBottomLeft.x, innerTopRight.x);
	outerTopY    = min(outerTopRight.y, outerBottomLeft.y);
	innerBottomY = max(innerBottomLeft.y, innerTopRight.y);

	// handle right/bottom sides of the box
	innerLeftX   = ensureMinThickness(
		min(innerBottomLeft.x, innerTopRight.x), outerLeftX);
	outerRightX  = ensureMinThickness(
		max(outerBottomLeft.x, outerTopRight.x), innerRightX);
	innerTopY    = ensureMinThickness(
		min(innerBottomLeft.y, innerTopRight.y), outerTopY);
	outerBottomY = ensureMinThickness(
		max(outerBottomLeft.y, outerTopRight.y), innerBottomY);

	// draw box sides in order: left, right, top, bottom
	/* // for testing
	printf("Outer: (%d, %d, %d, %d) - Inner: (%d, %d, %d, %d)\n",
		outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY
	);
	//*/
	Rectangle(hdcArea, outerLeftX, outerTopY, innerLeftX, outerBottomY);
	Rectangle(hdcArea, innerRightX, outerTopY, outerRightX, outerBottomY);
	Rectangle(hdcArea, outerLeftX, outerTopY, outerRightX, innerTopY);
	Rectangle(hdcArea, outerLeftX, innerBottomY, outerRightX, outerBottomY);
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
	drawRectangle(hdcArea, &pivotBottomLeft, &pivotTopRight, dimensions, NULL, COORD_ABSOLUTE_Y);

	// draw vertical line of pivot cross
	memcpy(&pivotBottomLeft, &pivotOriginal, sizeof(pivotOriginal));
	memcpy(&pivotTopRight, &pivotOriginal, sizeof(pivotOriginal));
	adjustWorldCoords(&pivotBottomLeft, 0, PIVOTSIZE);
	adjustWorldCoords(&pivotTopRight, 0, -PIVOTSIZE);
	drawRectangle(hdcArea, &pivotBottomLeft, &pivotTopRight, dimensions, NULL, COORD_ABSOLUTE_Y);
}

void drawPlayer(game_state_t *source, int which)
{
	int penIndex = (nextPen + which) % PEN_COLORS;
	SelectObject(source->hdc, pens[penIndex]);
	SelectObject(source->hdc, brushes[penIndex]);
	player_t *player = &(source->players[which]);
	screen_dimensions_t *dims = &(source->dimensions);
	camera_t *camera = &(source->camera);

	drawPivot(source->hdc, player, dims, camera);
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
		if (shouldDisplayPlayer(source, i))
		{
			drawPlayer(source, i);
		}
	}

	/* // for testing
	player_coords_t bottomLeft, topRight;
	memset(&bottomLeft, 0, sizeof(bottomLeft));
	memset(&topRight, 0, sizeof(topRight));
	adjustWorldCoords(&bottomLeft, 10, 20 + ABSOLUTE_Y_OFFSET);
	adjustWorldCoords(&topRight, 20, 10 + ABSOLUTE_Y_OFFSET);
	drawBox(source->hdc, &bottomLeft, &topRight, &(source->dimensions), NULL, COORD_ABSOLUTE_Y);
	//*/

	EndPaint(source->wHandle, &ps);
	InvalidateRect(source->wHandle, &rect, TRUE);
}
