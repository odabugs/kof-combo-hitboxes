#include "coords.h"

// set to false if you want hitboxes to show over the pillarboxes in widescreen mode
#define ALLOW_SCISSOR_TEST true

// global, set during game loadup in gamestate.c
screen_dimensions_t *screenDims;

int calculateScreenOffset(double actual, double baseline, double baselineScale)
{
	double scaled = floor(baseline * baselineScale);
	return (actual <= scaled) ? 0 : (int)((actual - scaled) / 2.0);
}

int setScreenOffsetsPillarboxed(
	screen_dimensions_t *dimensions, double dblWidth, double dblHeight)
{
	dimensions->yScale = dblHeight / dimensions->basicHeightAsDouble;
	dimensions->xScale = dimensions->yScale;
	return calculateScreenOffset(
		dblWidth, dimensions->basicWidthAsDouble, dimensions->xScale);
}

int setScreenOffsetsLetterboxed(
	screen_dimensions_t *dimensions, double dblWidth, double dblHeight)
{
	dimensions->xScale = dblWidth / dimensions->basicWidthAsDouble;
	dimensions->yScale = dimensions->xScale;
	return calculateScreenOffset(
		dblHeight, dimensions->basicHeightAsDouble, dimensions->yScale);
}

void setWindowDimensions(screen_dimensions_t *dimensions, int newXOffset, int newYOffset)
{
	int w = dimensions->width, h = dimensions->height;
	w = w - (newXOffset << 1);
	h = h - (newYOffset << 1);
	RECT scissorRect = { .right = (LONG)w, .bottom = (LONG)h };
	setScissor(w, h);
}

void getGameScreenDimensions(HWND game, HWND overlay, screen_dimensions_t *dimensions)
{
	RECT clientRect;
	POINT clientTopLeft = { .x = 0, .y = 0 };
	GetClientRect(game, &clientRect);
	ClientToScreen(game, &clientTopLeft);
	int newLeftX = (int)clientTopLeft.x;
	int newTopY = (int)clientTopLeft.y;
	int newWidth = (int)clientRect.right;
	int newHeight = (int)clientRect.bottom;
	int newXOffset = 0, newYOffset = 0;

	// has the game window position and/or size changed since we last checked?
	bool changedPosition, changedSize, enlarged;
	changedPosition = (dimensions->leftX != newLeftX || dimensions->topY != newTopY);
	changedSize = (dimensions->width != newWidth || dimensions->height != newHeight);
	enlarged = (changedSize && (newWidth > dimensions->width || newHeight > dimensions->height));

	if (!changedPosition && !changedSize) { return; }
	dimensions->leftX = newLeftX;
	dimensions->topY = newTopY;

	dimensions->width = newWidth;
	dimensions->height = newHeight;
	double dblWidth = (double)newWidth;
	double dblHeight = (double)newHeight;
	dimensions->aspect = dblWidth / dblHeight;

	switch (dimensions->aspectMode)
	{
		case AM_FIXED:
		case AM_STRETCH:
			dimensions->xScale = dblWidth / dimensions->basicWidthAsDouble;
			dimensions->yScale = dblHeight / dimensions->basicHeightAsDouble;
			dimensions->leftOffset = 0;
			dimensions->topOffset = 0;
			break;
		case AM_PILLARBOX:
				newXOffset = setScreenOffsetsPillarboxed(dimensions, dblWidth, dblHeight);
			break;
		case AM_LETTERBOX:
				newYOffset = setScreenOffsetsLetterboxed(dimensions, dblWidth, dblHeight);
			break;
		case AM_WINDOW_FRAME:
			if (dimensions->aspect < dimensions->basicAspect)
			{
				newYOffset = setScreenOffsetsLetterboxed(dimensions, dblWidth, dblHeight);
			}
			else
			{
				newXOffset = setScreenOffsetsPillarboxed(dimensions, dblWidth, dblHeight);
			}
			break;
		default:
			printf("Encountered invalid aspect mode.");
			exit(EXIT_FAILURE);
	}

	if (!enlarged)
	{
		setScissor(screenWidth, screenHeight);
		clearFrame();
	}
	setWindowDimensions(dimensions, newXOffset, newYOffset);
	MoveWindow(overlay,
		newLeftX + newXOffset, newTopY + newYOffset,
		(int)screenWidth, (int)screenHeight,
		true);
}

// also applies offsetting from the left/top of the screen
void scaleScreenCoords(
	screen_dimensions_t *dimensions, screen_coords_t *target, coord_options_t options)
{
	int xAdjust = (options & COORD_RIGHT_EDGE)  ? 1 : 0;
	int yAdjust = (options & COORD_BOTTOM_EDGE) ? 1 : 0;

	int newX = dimensions->leftOffset;
	newX += (int)((target->x + xAdjust) * dimensions->xScale);
	target->x = newX - xAdjust;

	int newY = dimensions->topOffset;
	newY += (int)((target->y + yAdjust - ABSOLUTE_Y_OFFSET) * dimensions->yScale);
	newY += 1; // god only knows why this is needed but it works
	target->y = newY - yAdjust;
}

// pass a non-NULL camera pointer to make the results relative to that camera
void translateRelativeGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options)
{
	player_coords_t adjusted;
	player_coords_t *newSource = source;
	if (camera != NULL)
	{
		memcpy(&adjusted, source, sizeof(*source));
		adjusted.x -= (int)(camera->x.whole);
		adjusted.y -= (int)(camera->y.whole);
		newSource = &adjusted;
	}
	target->x = newSource->x;
	target->y = newSource->y;
	scaleScreenCoords(dimensions, target, options);
}

void translateGameCoords(
	player_coords_t *source, screen_coords_t *target, coord_options_t options)
{
	translateRelativeGameCoords(source, screenDims, NULL, target, options);
}

void worldCoordsFromPlayer(player_t *player, player_coords_t *target)
{
	memset(target, 0, sizeof(*target));
	target->x = player->screenX;
	target->y = player->screenY;
}

void adjustWorldCoords(
	player_coords_t *target, game_pixel_t xAdjust, game_pixel_t yAdjust)
{
	target->x += xAdjust;
	target->y += yAdjust;
}

void ensureCorners(player_coords_t *topLeft, player_coords_t *bottomRight)
{
	int32_t
		leftX   = min(topLeft->xComplete.value, bottomRight->xComplete.value),
		topY    = min(topLeft->yComplete.value, bottomRight->yComplete.value),
		rightX  = max(topLeft->xComplete.value, bottomRight->xComplete.value),
		bottomY = max(topLeft->yComplete.value, bottomRight->yComplete.value);

	topLeft->xComplete.value     = leftX;
	topLeft->yComplete.value     = topY;
	bottomRight->xComplete.value = rightX;
	bottomRight->yComplete.value = bottomY;
}

void getScreenEdgeInWorldCoords(
	player_coords_t *target, screen_horz_edge_t hEdge, screen_vert_edge_t vEdge)
{
	int rightEdge = screenDims->basicWidth, bottomEdge = screenDims->basicHeight;
	game_pixel_t hEdges[3] = {
		0,
		rightEdge >> 1,
		rightEdge - 1
	};
	// TODO: Looks perfect at 1:1 scale but the bottom edge
	//       is positioned slightly off at larger resolutions
	game_pixel_t vEdges[3] = {
		ABSOLUTE_Y_OFFSET,
		ABSOLUTE_Y_OFFSET + (bottomEdge >> 1),
		ABSOLUTE_Y_OFFSET + (bottomEdge - 1),
	};

	memset(target, 0, sizeof(*target));
	target->x = hEdges[hEdge];
	target->y = vEdges[vEdge];
}

void flipXOnAxis(player_coords_t *target, player_coords_t *axis, int postAdjustment)
{
	game_pixel_t xDifference = axis->x - target->x;
	target->x += (xDifference * 2);
	target->x += postAdjustment;
}

void swapXComponents(player_coords_t *one, player_coords_t *two)
{
	if (one != two)
	{
		int32_t temp = one->xComplete.value;
		one->xComplete.value = two->xComplete.value;
		two->xComplete.value = temp;
	}
}

void copyAndAdjust(
	player_coords_t *target, player_coords_t *source, player_coords_t *adjustment)
{
	if (target != source)
	{
		memcpy(target, source, sizeof(*target));
	}
	target->xComplete.value += adjustment->xComplete.value;
	target->yComplete.value += adjustment->yComplete.value;
}

void copyAndAdjustByValues(
	player_coords_t *target, player_coords_t *source, int32_t xAdjust, int32_t yAdjust)
{
	player_coords_t adjustment;
	adjustment.xComplete.value = xAdjust;
	adjustment.yComplete.value = yAdjust;
	copyAndAdjust(target, source, &adjustment);
}
