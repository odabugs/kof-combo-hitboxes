#include "primitives.h"

int ensureMinThickness(int goal, int baseline)
{
	return max(goal, baseline) + 1;
}

void GLRectangle(int leftX, int topY, int rightX, int bottomY)
{
	glVertex2i(leftX, topY);
	glVertex2i(rightX, topY);
	glVertex2i(leftX, bottomY);

	glVertex2i(leftX, bottomY);
	glVertex2i(rightX, topY);
	glVertex2i(rightX, bottomY);
	//printf("(%d, %d) to (%d, %d)\n", leftX, topY, rightX, bottomY);
}

void drawRectangle(player_coords_t *topLeft, player_coords_t *bottomRight)
{
	screen_coords_t topLeftScreen, bottomRightScreen;
	int leftX, topY, rightX, bottomY;

	ensureCorners(topLeft, bottomRight);
	translateGameCoords(topLeft, &topLeftScreen, COORD_NORMAL);
	translateGameCoords(bottomRight, &bottomRightScreen, COORD_BOTTOM_RIGHT);
	leftX   = topLeftScreen.x;
	topY    = topLeftScreen.y;
	rightX  = ensureMinThickness(bottomRightScreen.x, leftX);
	bottomY = ensureMinThickness(bottomRightScreen.y, topY);

	GLRectangle(leftX, topY, rightX, bottomY);
}

// TODO: support "thick" and "thin" box borders (currently supports thick borders only)
//       (thick borders should "collapse" inward instead of adding thickness evenly)
void drawBox(player_coords_t *topLeft, player_coords_t *bottomRight)
{
	screen_coords_t outerTopLeft, innerTopLeft;
	screen_coords_t outerBottomRight, innerBottomRight;
	int innerLeftX, innerTopY, innerRightX, innerBottomY;
	int outerLeftX, outerTopY, outerRightX, outerBottomY;

	ensureCorners(topLeft, bottomRight);
	translateGameCoords(topLeft, &outerTopLeft, COORD_NORMAL);
	translateGameCoords(topLeft, &innerTopLeft, COORD_BOTTOM_RIGHT);
	translateGameCoords(bottomRight, &innerBottomRight, COORD_NORMAL);
	translateGameCoords(bottomRight, &outerBottomRight, COORD_BOTTOM_RIGHT);

	// handle left/top sides of the box
	outerLeftX   = outerTopLeft.x;
	innerRightX  = innerBottomRight.x;
	outerTopY    = outerTopLeft.y;
	innerBottomY = innerBottomRight.y;

	// handle right/bottom sides of the box
	innerLeftX   = ensureMinThickness(innerTopLeft.x,     outerLeftX);
	outerRightX  = ensureMinThickness(outerBottomRight.x, innerRightX);
	innerTopY    = ensureMinThickness(innerTopLeft.y,     outerTopY);
	outerBottomY = ensureMinThickness(outerBottomRight.y, innerBottomY);

	// draw box sides in order: left, right, top, bottom
	GLRectangle(outerLeftX, outerTopY, innerLeftX, outerBottomY);
	GLRectangle(innerRightX, outerTopY, outerRightX, outerBottomY);
	GLRectangle(innerLeftX, outerTopY, innerRightX, innerTopY);
	GLRectangle(innerLeftX, innerBottomY, innerRightX, outerBottomY);
}

void drawPivot(player_coords_t *pivot, int pivotSize)
{
	player_coords_t pivotTopLeft, pivotBottomRight;

	// draw horizontal line of pivot cross
	memcpy(&pivotTopLeft, pivot, sizeof(*pivot));
	memcpy(&pivotBottomRight, pivot, sizeof(*pivot));
	adjustWorldCoords(&pivotTopLeft, -pivotSize, 0);
	adjustWorldCoords(&pivotBottomRight, pivotSize, 0);
	drawRectangle(&pivotTopLeft, &pivotBottomRight);

	// draw vertical line of pivot cross
	memcpy(&pivotTopLeft, pivot, sizeof(*pivot));
	memcpy(&pivotBottomRight, pivot, sizeof(*pivot));
	adjustWorldCoords(&pivotTopLeft, 0, -pivotSize);
	adjustWorldCoords(&pivotBottomRight, 0, pivotSize);
	drawRectangle(&pivotTopLeft, &pivotBottomRight);
}
