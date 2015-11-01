#include "draw.h"

#define PEN_COLORS 2
#define PEN_INTERVAL 20
#define PIVOTSIZE 5
#define BOX_EDGE_ALPHA 255
#define BOX_FILL_ALPHA 128
#define PIVOT_ALPHA 255

// glColor3ubv will ignore the "alpha" element, while glColor4ubv will read it
const GLubyte colorset[7][4] = {
	{ 255,   0,   0, BOX_FILL_ALPHA }, // red
	{   0, 255,   0, BOX_FILL_ALPHA }, // green
	{   0,   0, 255, BOX_FILL_ALPHA }, // blue
	{ 255, 255,   0, BOX_FILL_ALPHA }, // yellow
	{ 255,   0, 255, BOX_FILL_ALPHA }, // magenta
	{ 128, 128, 128, BOX_FILL_ALPHA }, // gray
	{ 255, 255, 255, BOX_FILL_ALPHA }  // white
};
const GLubyte pivotColor[4] = { 255, 0, 0, PIVOT_ALPHA };

void setupDrawing()
{
}

void teardownDrawing()
{
}

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

	GLRectangle(leftX, topY, rightX, bottomY);
}

// TODO: fix box drawing with an extra "world pixel" added on the bottom/right
//       (i.e., ask for a 10x10 box in world pixels and you get 11x11 by outer edges)
// TODO: support "thick" and "thin" box borders (currently supports thick borders only)
//       (thick borders should "collapse" inward instead of adding thickness evenly)
// TODO: fill color
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
	GLRectangle(outerLeftX, outerTopY, innerLeftX, outerBottomY);
	GLRectangle(innerRightX, outerTopY, outerRightX, outerBottomY);
	GLRectangle(outerLeftX, outerTopY, outerRightX, innerTopY);
	GLRectangle(outerLeftX, innerBottomY, outerRightX, outerBottomY);
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

void drawHitbox(
	HDC hdcArea, player_t *player, hitbox_t *hitbox,
	screen_dimensions_t *dimensions, camera_t *camera)
{
	if (!hitboxIsActive(hitbox))
	{
		return;
	}
	player_coords_t pivot, boxBottomLeft, boxTopRight;
	int offsetX = hitbox->xPivot;
	int offsetY = hitbox->yPivot;
	int xRadius = hitbox->xRadius;
	int yRadius = hitbox->yRadius;
	if (player->facing == FACING_RIGHT)
	{
		offsetX = -offsetX;
	}

	absoluteWorldCoordsFromPlayer(player, &pivot);
	memcpy(&boxBottomLeft, &pivot, sizeof(pivot));
	memcpy(&boxTopRight, &pivot, sizeof(pivot));
	adjustWorldCoords(&boxBottomLeft, (offsetX - xRadius), (offsetY - yRadius));
	adjustWorldCoords(&boxTopRight, (offsetX + xRadius - 1), (offsetY + yRadius - 1));

	drawBox(hdcArea, &boxBottomLeft, &boxTopRight, dimensions, NULL, COORD_ABSOLUTE_Y);

	//*
	player_coords_t boxCenter;
	memcpy(&boxCenter, &pivot, sizeof(pivot));
	adjustWorldCoords(&boxCenter, offsetX, offsetY);
	drawRectangle(hdcArea, &boxCenter, &boxCenter, dimensions, NULL, COORD_ABSOLUTE_Y);
	//*/
	/*
	printf("%02X %02X %02X %02X %02X\n",
		hitbox->boxID,
		hitbox->xPivot, hitbox->yPivot,
		hitbox->xRadius, hitbox->yRadius);
	//*/
}

void drawPlayer(game_state_t *source, int which)
{
	HDC hdc = source->overlayHdc;
	player_t *player = &(source->players[which]);
	screen_dimensions_t *dims = &(source->dimensions);
	camera_t *camera = &(source->camera);

	for (int i = 0; i < HBLISTSIZE; i++)
	{
		glColor3ubv(colorset[i]);
		drawHitbox(hdc, player, &(player->hitboxes[i]), dims, camera);
	}
	for (int i = 0; i < HBLISTSIZE_2ND; i++)
	{
		glColor3ubv(colorset[i + HBLISTSIZE]);
		drawHitbox(hdc, player, &(player->hitboxes_2nd[i]), dims, camera);
	}
	glColor4ubv(pivotColor);
	drawPivot(hdc, player, dims, camera);
}

void drawScene(game_state_t *source)
{
	HWND hwnd = source->overlayHwnd;
	HDC hdc = source->overlayHdc;
	glClear(GL_COLOR_BUFFER_BIT);
	glBegin(GL_TRIANGLES);

	for (int i = 0; i < PLAYERS; i++)
	{
		if (shouldDisplayPlayer(source, i))
		{
			drawPlayer(source, i);
		}
	}

	glEnd();
	SwapBuffers(hdc);
	glFinish();

	/* // for testing
	player_coords_t bottomLeft, topRight;
	memset(&bottomLeft, 0, sizeof(bottomLeft));
	memset(&topRight, 0, sizeof(topRight));
	adjustWorldCoords(&bottomLeft, 10, 20 + ABSOLUTE_Y_OFFSET);
	adjustWorldCoords(&topRight, 20, 10 + ABSOLUTE_Y_OFFSET);
	drawBox(hdc, &bottomLeft, &topRight, &(source->dimensions), NULL, COORD_ABSOLUTE_Y);
	//*/
}
