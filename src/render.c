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
				return;
		}
		dimensions->groundOffset =
			dblHeight - (int)floor(dimensions->basicGroundOffset * dimensions->yScale);
	}
}

int calculateScreenOffset(double actual, double baseline, double baselineScale)
{
	double scaled = floor(baseline * baselineScale);
	return (actual <= scaled) ? 0 : (int)((actual - scaled) / 2.0);
}

// also applies offsetting from the left/top of the screen
void scaleScreenCoords(screen_dimensions_t dimensions, screen_coords_t *target)
{
	int newX = dimensions.leftOffset + (int)(target->x * dimensions.xScale);
	int newY = dimensions.groundOffset - (int)(target->y * dimensions.yScale);
	newY += dimensions.topOffset;
	target->x = newX;
	target->y = newY;
}

void translateAbsoluteGameCoords(
	player_coords_t source, screen_dimensions_t dimensions,
	screen_coords_t *target)
{
	target->x = source.x;
	target->y = source.y;
	scaleScreenCoords(dimensions, target);
}

void translateRelativeGameCoords(
	player_coords_t source, screen_dimensions_t dimensions,
	camera_t camera, screen_coords_t *target)
{
	player_coords_t adjusted;
	adjusted.x = source.x - (int)(camera.x.whole);
	adjusted.y = source.y - (int)(camera.y.whole);
	translateAbsoluteGameCoords(adjusted, dimensions, target);
}

void translatePlayerCoords(
	player_t player, screen_dimensions_t dimensions,
	camera_t camera, screen_coords_t *target)
{
	player_coords_t source;
	int32_t yOffset = baseY.value - player.yOffset.value;
	source.xComplete.value = player.xPivot.value;
	source.yComplete.value = player.yPivot.value - yOffset;
	translateRelativeGameCoords(source, dimensions, camera, target);
}
