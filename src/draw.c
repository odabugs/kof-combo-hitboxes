#include "draw.h"

#define LARGE_PIVOT_SIZE 5
#define SMALL_PIVOT_SIZE 2

// TODO: get proper box coloring/alpha before enabling this
bool drawBoxFill = false;

int ensureMinThickness(int goal, int baseline)
{
	return max(goal, baseline) + 1;
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
	translateGameCoords(topLeft, screenDims, NULL, &topLeftScreen, COORD_NORMAL);
	translateGameCoords(bottomRight, screenDims, NULL, &bottomRightScreen, COORD_BOTTOM_RIGHT);
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
	translateGameCoords(topLeft, screenDims, NULL, &outerTopLeft, COORD_NORMAL);
	translateGameCoords(topLeft, screenDims, NULL, &innerTopLeft, COORD_BOTTOM_RIGHT);
	translateGameCoords(bottomRight, screenDims, NULL, &innerBottomRight, COORD_NORMAL);
	translateGameCoords(bottomRight, screenDims, NULL, &outerBottomRight, COORD_BOTTOM_RIGHT);

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
	/* // for testing
	printf("Outer: (%d, %d, %d, %d) - Inner: (%d, %d, %d, %d)\n",
		outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY
	);
	//*/
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

void drawPlayerPivot(player_t *player)
{
	player_coords_t pivot;
	absoluteWorldCoordsFromPlayer(player, &pivot);

	glColor4ubv(playerPivotColor);
	drawPivot(&pivot, LARGE_PIVOT_SIZE);
}

void drawHitbox(player_t *player, hitbox_t *hitbox)
{
	if (hitbox->xRadius == 0 || hitbox->yRadius == 0)
	{
		return;
	}
	player_coords_t pivot, boxCenter, boxTopLeft, boxBottomRight;
	int offsetX = hitbox->xPivot * (player->facing == FACING_RIGHT ? -1 : 1);
	int offsetY = hitbox->yPivot;
	int xRadius = hitbox->xRadius;
	int yRadius = hitbox->yRadius;

	absoluteWorldCoordsFromPlayer(player, &pivot);
	memcpy(&boxCenter, &pivot, sizeof(pivot));
	memcpy(&boxTopLeft, &pivot, sizeof(pivot));
	memcpy(&boxBottomRight, &pivot, sizeof(pivot));
	adjustWorldCoords(&boxCenter, offsetX, offsetY);
	adjustWorldCoords(&boxTopLeft, (offsetX - xRadius), (offsetY - yRadius));
	adjustWorldCoords(&boxBottomRight, (offsetX + xRadius - 1), (offsetY + yRadius - 1));

	if (drawBoxFill)
	{
		drawRectangle(&boxTopLeft, &boxBottomRight);
	}
	drawBox(&boxTopLeft, &boxBottomRight);
	drawPivot(&boxCenter, SMALL_PIVOT_SIZE);
	/*
	printf("%02X %02X %02X %02X %02X\n",
		hitbox->boxID,
		hitbox->xPivot, hitbox->yPivot,
		hitbox->xRadius, hitbox->yRadius);
	//*/
}

void drawPlayer(game_state_t *source, int which)
{
	player_t *player = &(source->players[which]);
	hitbox_t *hitbox;

	for (int i = 0; i < HBLISTSIZE; i++)
	{
		hitbox = &(player->hitboxes[i]);
		if (hitboxIsActive(player, hitbox, hitboxActiveMasks[i]))
		{
			glColor3ubv(colorset[i]);
			drawHitbox(player, hitbox);
		}
	}

	// draw collision box
	hitbox = &(player->collisionBox);
	if (collisionBoxIsActive(player, hitbox)) {
		glColor3ubv(colorset[HBLISTSIZE + 0]);
		drawHitbox(player, hitbox);
	}

	// draw "throwing" box
	hitbox = &(player->throwBox);
	if (throwBoxIsActive(player, hitbox)) {
		glColor3ubv(colorset[HBLISTSIZE + 1]);
		drawHitbox(player, hitbox);
	}

	// draw "throwable" box
	hitbox = &(player->throwableBox);
	if (throwableBoxIsActive(player, hitbox)) {
		glColor3ubv(colorset[HBLISTSIZE + 2]);
		drawHitbox(player, hitbox);
	}

	drawPlayerPivot(player);
}

void drawScene(game_state_t *source)
{
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
	SwapBuffers(source->overlayHdc);
	glFinish();
}
