#include "render.h"
#include "playerstruct.h"

const player_coord_t baseY = { .whole = 0x02E8, .part = 0 };

void getGameScreenDimensions(HWND handle, screen_dimensions_t *dimensions)
{
	int newWidth, newHeight;
	double dblWidth, dblHeight;
	RECT target;
	GetClientRect(handle, &target);
	newWidth = (int)target.right;
	newHeight = (int)target.bottom;

	// has the game window size changed since we last checked?
	if (dimensions->width != target.right || dimensions->height != target.bottom)
	{
		dimensions->width = newWidth;
		dimensions->height = newHeight;
		dblWidth = (double)newWidth;
		dblHeight = (double)newHeight;
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
				dimensions->yScale = dblHeight / dimensions->basicHeightAsDouble;
				dimensions->xScale = dimensions->yScale;
				dimensions->leftOffset = calculateScreenOffset(
					dblWidth, dimensions->basicWidthAsDouble, dimensions->xScale);
				dimensions->topOffset = 0;
				break;
			case AM_LETTERBOX:
				dimensions->xScale = dblWidth / dimensions->basicWidthAsDouble;
				dimensions->yScale = dimensions->xScale;
				dimensions->leftOffset = 0;
				dimensions->topOffset = calculateScreenOffset(
					dblHeight, dimensions->basicHeightAsDouble, dimensions->yScale);
				break;
			case AM_WINDOW_FRAME:
				// TODO
				break;
			default:
				printf("Encountered invalid aspect mode.");
				exit(EXIT_FAILURE);
		}
		dimensions->groundOffset =
			dblHeight - 1 - (int)(dimensions->basicGroundOffset * dimensions->yScale);
	}
}

int calculateScreenOffset(double actual, double baseline, double baselineScale)
{
	double scaled = floor(baseline * baselineScale);
	return (actual <= scaled) ? 0 : (int)((actual - scaled) / 2.0);
}

// also applies offsetting from the left/top of the screen
void scaleScreenCoords(
	screen_dimensions_t *dimensions, screen_coords_t *target,
	coord_options_t options)
{
	int xAdjust = (options & COORD_RIGHT_EDGE)  ? 1 : 0;
	int yAdjust = (options & COORD_BOTTOM_EDGE) ? 0 : 1;
	int newX = dimensions->leftOffset;
	int newY = dimensions->groundOffset + dimensions->topOffset;
	newX = newX + (int)((target->x + xAdjust) * dimensions->xScale);
	newY = newY - (int)((target->y + yAdjust) * dimensions->yScale);
	target->x = newX - xAdjust;
	target->y = newY + yAdjust;
}

void translateAbsoluteGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	screen_coords_t *target, coord_options_t options)
{
	target->x = source->x;
	target->y = source->y;
	scaleScreenCoords(dimensions, target, options);
}

void translateRelativeGameCoords(
	player_coords_t *source, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options)
{
	player_coords_t adjusted;
	adjusted.x = source->x - (int)(camera->x.whole);
	adjusted.y = source->y - (int)(camera->y.whole);
	translateAbsoluteGameCoords(&adjusted, dimensions, target, options);
}

void translatePlayerCoords(
	player_t *player, screen_dimensions_t *dimensions,
	camera_t *camera, screen_coords_t *target, coord_options_t options)
{
	player_coords_t source;
	worldCoordsFromPlayer(player, &source);
	translateRelativeGameCoords(&source, dimensions, camera, target, options);
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
