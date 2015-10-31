#include "coords.h"
#include "playerstruct.h"

const player_coord_t baseY = { .whole = 0x02E8, .part = 0 };

int calculateScreenOffset(double actual, double baseline, double baselineScale)
{
	double scaled = floor(baseline * baselineScale);
	return (actual <= scaled) ? 0 : (int)((actual - scaled) / 2.0);
}

void setScreenOffsetsPillarboxed(
	screen_dimensions_t *dimensions, double dblWidth, double dblHeight)
{
	dimensions->yScale = dblHeight / dimensions->basicHeightAsDouble;
	dimensions->xScale = dimensions->yScale;
	dimensions->leftOffset = calculateScreenOffset(
		dblWidth, dimensions->basicWidthAsDouble, dimensions->xScale);
	dimensions->topOffset = 0;
}

void setScreenOffsetsLetterboxed(
	screen_dimensions_t *dimensions, double dblWidth, double dblHeight)
{
	dimensions->xScale = dblWidth / dimensions->basicWidthAsDouble;
	dimensions->yScale = dimensions->xScale;
	dimensions->leftOffset = 0;
	dimensions->topOffset = calculateScreenOffset(
		dblHeight, dimensions->basicHeightAsDouble, dimensions->yScale);
}

// TODO: account for letterboxing
void setGLWindowDimensions(screen_dimensions_t *dimensions)
{
	int w = dimensions->width, h = dimensions->height;

	glViewport(0, 0, w, h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//gluOrtho2D(0, w, 0, h);
	gluOrtho2D(0, w, h, 0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
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

	// has the game window position and/or size changed since we last checked?
	bool changedPosition, changedSize;
	changedPosition = (dimensions->leftX != newLeftX || dimensions->topY != newTopY);
	changedSize = (dimensions->width != newWidth || dimensions->height != newHeight);

	if (changedPosition || changedSize) {
		MoveWindow(overlay, newLeftX, newTopY, newWidth, newHeight, true);
		dimensions->leftX = newLeftX;
		dimensions->topY = newTopY;
	}

	if (changedSize)
	{
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
					setScreenOffsetsPillarboxed(dimensions, dblWidth, dblHeight);
				break;
			case AM_LETTERBOX:
					setScreenOffsetsLetterboxed(dimensions, dblWidth, dblHeight);
				break;
			case AM_WINDOW_FRAME:
				if (dimensions->aspect < dimensions->basicAspect)
				{
					setScreenOffsetsLetterboxed(dimensions, dblWidth, dblHeight);
				}
				else
				{
					setScreenOffsetsPillarboxed(dimensions, dblWidth, dblHeight);
				}
				break;
			default:
				printf("Encountered invalid aspect mode.");
				exit(EXIT_FAILURE);
		}
		dimensions->groundOffset =
			dblHeight - 1 - (int)(dimensions->basicGroundOffset * dimensions->yScale);

		setGLWindowDimensions(dimensions);
	}
}

// also applies offsetting from the left/top of the screen
void scaleScreenCoords(
	screen_dimensions_t *dimensions, screen_coords_t *target,
	coord_options_t options)
{
	int xAdjust = (options & COORD_RIGHT_EDGE)  ? 1 : 0;
	int yAdjust = (options & COORD_BOTTOM_EDGE) ? 1 : 0;

	int newX = dimensions->leftOffset;
	newX += (int)((target->x + xAdjust) * dimensions->xScale);
	target->x = newX - xAdjust;

	int newY = dimensions->topOffset;
	if (options & COORD_ABSOLUTE_Y)
	{
		newY += (int)((target->y + yAdjust - ABSOLUTE_Y_OFFSET) * dimensions->yScale);
		newY += 1; // god only knows why this is needed but it works
		target->y = newY - yAdjust;
	}
	else
	{
		yAdjust = (yAdjust != 0) ? 0 : 1;
		newY += dimensions->groundOffset;
		newY -= (int)((target->y + yAdjust) * dimensions->yScale);
		target->y = newY + yAdjust;
	}
}

// pass a non-NULL camera pointer to make the results relative to that camera
void translateGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options)
{
	player_coords_t adjusted;
	player_coords_t *newSource = source;
	if (camera != NULL)
	{
		memcpy(&adjusted, source, sizeof(*source));
		relativizeWorldCoords(camera, &adjusted);
		newSource = &adjusted;
	}
	target->x = newSource->x;
	target->y = newSource->y;
	scaleScreenCoords(dimensions, target, options);
}

void translatePlayerCoords(
	player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options)
{
	player_coords_t source;
	worldCoordsFromPlayer(player, &source);
	translateGameCoords(&source, dimensions, camera, target, options);
}

void worldCoordsFromPlayer(player_t *player, player_coords_t *target)
{
	// (player structure +01Ch) is an offset that adjusts the player's Y
	// position both on the screen and in terms of collision detection;
	// decreasing its value causes the player to "walk on air" raised up
	int32_t yOffset = baseY.value - player->yOffset.value;
	target->xComplete.value = player->xPivot.value;
	target->yComplete.value = player->yPivot.value - yOffset;
}

void absoluteWorldCoordsFromPlayer(player_t *player, player_coords_t *target)
{
	memset(target, 0, sizeof(*target));
	target->x = player->screenX;
	target->y = player->screenY;
}

void relativizeWorldCoords(camera_t *camera, player_coords_t *target)
{
	target->x -= (int)(camera->x.whole);
	target->y -= (int)(camera->y.whole);
}

void adjustWorldCoords(player_coords_t *target, int xAdjust, int yAdjust)
{
	target->x += xAdjust;
	target->y += yAdjust;
}

void swapYComponents(player_coords_t *left, player_coords_t *right)
{
	player_coord_t tmpY = left->yComplete;
	left->yComplete = right->yComplete;
	right->yComplete = tmpY;
}
