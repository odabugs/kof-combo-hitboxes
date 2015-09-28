#include "render.h"
#include "playerstruct.h"

// used for scaling game coords and adjusting X/Y offsets
// based on the client window size; "natural" window size is 640x448 pixels
// (though this is twice the scale of the original NeoGeo games)
#define BASIC_SCALE 2.0
#define BASIC_HEIGHT 224.0
#define BASIC_ASPECT (640.0 / 448.0)
#define BASIC_WIDE_ASPECT (796.0 / 448.0)
#define BASIC_PADDING ((796.0 - 640.0) / (BASIC_SCALE * 2.0))
#define BASIC_GROUND_Y ((45.0) / BASIC_SCALE)

const player_coord_t baseY = { .whole = 0x02E8, .part = 0 };

bool isWidescreen(double aspect)
{
	// determine which is closer to the screen's actual aspect ratio
	// (don't use exact value comparisons because precision is not perfect)
	double normalDifference = fabs(BASIC_ASPECT - aspect);
	double wideDifference = fabs(BASIC_WIDE_ASPECT - aspect);
	return (normalDifference > wideDifference);
}

void getGameScreenDimensions(HWND handle, screen_dimensions_t *dimensions)
{
	int newWidth, newHeight, newXPadding, newGroundY;
	double newScale, newAspect;
	RECT target;
	GetClientRect(handle, &target);
	newWidth = (int)target.right;
	newHeight = (int)target.bottom;

	// has the game window size changed since we last checked?
	if (dimensions->width != target.right || dimensions->height != target.bottom)
	{
		newScale = (newHeight / BASIC_HEIGHT);
		newGroundY = newHeight - (int)(newScale * BASIC_GROUND_Y);
		newAspect = (double)newWidth / (double)newHeight;
		dimensions->aspect = newAspect;
		if (isWidescreen(newAspect))
		{
			newXPadding = (int)(newScale * BASIC_PADDING);
			dimensions->isWidescreen = true;
		}
		else
		{
			newXPadding = 0;
			dimensions->isWidescreen = false;
		}
		
		dimensions->width = newWidth;
		dimensions->height = newHeight;
		dimensions->xOffset = newXPadding;
		dimensions->yOffset = newGroundY;
		dimensions->scale = newScale;
	}
}

void scaleScreenCoords(screen_dimensions_t dimensions, screen_coords_t *target)
{
	double screenScale = dimensions.scale;
	int newX = dimensions.xOffset + (int)(target->x * screenScale);
	int newY = dimensions.yOffset - (int)(target->y * screenScale);
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
