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

// used for unscaled drawing, e.g. for the fill portion of onscreen gauges
void drawScreenRectangle(screen_coords_t *topLeft, screen_coords_t *bottomRight)
{
	GLRectangle(
		min(topLeft->x, bottomRight->x),
		min(topLeft->y, bottomRight->y),
		max(topLeft->x, bottomRight->x),
		max(topLeft->y, bottomRight->y)
	);
}

void drawDot(player_coords_t *location)
{
	drawRectangle(location, location);
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

void fillGauge(gauge_info_t *gauge, double value)
{
	int maxFillSize, actualFillSize;
	screen_coords_t topLeft, bottomRight;
	translateGameCoords(&(gauge->fillTopLeft), &topLeft, COORD_NORMAL);
	translateGameCoords(&(gauge->fillBottomRight), &bottomRight, COORD_BOTTOM_RIGHT);
	if (gauge->isVertical) { maxFillSize = bottomRight.y - topLeft.y; }
	else { maxFillSize = bottomRight.x - topLeft.x; }

	double maxFillSizeDbl = (double)maxFillSize;
	double minValue = gauge->minValueDbl, maxValue = gauge->maxValueDbl;
	// move value range so it starts at 0
	value -= minValue;
	maxValue -= minValue;
	double fillPercent = (value / maxValue);
	actualFillSize = maxFillSize - (int)(fillPercent * maxFillSizeDbl);

	if (gauge->isVertical)
	{
		if (gauge->fillFromBottomUp)
		{
			topLeft.y += actualFillSize;
		}
		else
		{
			bottomRight.y -= actualFillSize;
		}
	}
	else
	{
		if (gauge->fillFromRightToLeft)
		{
			topLeft.x += actualFillSize;
		}
		else
		{
			bottomRight.x -= actualFillSize;
		}
	}
	drawScreenRectangle(&topLeft, &bottomRight);
}

void drawGauge(gauge_info_t *gauge, int value)
{
	// TODO: support vertical gauges
	selectColor(gauge->fillColor);

	// draw gauge empty if value < min value
	if (value >= gauge->minValue)
	{
		// draw gauge full if value >= max value
		if (value >= gauge->maxValue)
		{
			drawRectangle(&(gauge->fillTopLeft), &(gauge->fillBottomRight));
		}
		else
		{
			fillGauge(gauge, (double)value);
		}
	}

	// draw gauge border
	selectColor(gauge->borderColor);
	drawBox(&(gauge->borderTopLeft), &(gauge->borderBottomRight));
}
