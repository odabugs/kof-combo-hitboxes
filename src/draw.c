#include "draw.h"

#define LARGE_PIVOT_SIZE 5
#define SMALL_PIVOT_SIZE 2

bool drawBoxFill = true;
bool drawThrowableBoxes = true;
bool drawThrowBoxes = true;
bool drawHitboxPivots = true;
atk_button_t showButtonRanges[PLAYERS] = {
	SHOW_NO_BUTTON_RANGES,
	SHOW_NO_BUTTON_RANGES
};
SHORT showButtonRangeHotkeys[PLAYERS] = {
	VK_F1,
	VK_F2
};
SHORT showBoxFillHotkey = VK_F3;
SHORT showHitboxPivotsHotkey = VK_F4;
SHORT showThrowableBoxesHotkey = VK_F5;
SHORT showThrowBoxesHotkey = VK_F6;

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

void checkMiscHotkeys()
{
	bool oldStatus;

	if (keyIsPressed(showBoxFillHotkey))
	{
		oldStatus = drawBoxFill;
		drawBoxFill = !drawBoxFill;
		timestamp();
		printf("%s drawing hitbox fills.\n",
			(oldStatus ? "Disabled" : "Enabled"));
		return;
	}

	if (keyIsPressed(showThrowableBoxesHotkey))
	{
		oldStatus = drawThrowableBoxes;
		drawThrowableBoxes = !drawThrowableBoxes;
		timestamp();
		printf("%s drawing throwable boxes.\n",
			(oldStatus ? "Disabled" : "Enabled"));
		return;
	}

	if (keyIsPressed(showThrowBoxesHotkey))
	{
		oldStatus = drawThrowBoxes;
		drawThrowBoxes = !drawThrowBoxes;
		timestamp();
		printf("%s drawing throw boxes.\n",
			(oldStatus ? "Disabled" : "Enabled"));
		return;
	}

	if (keyIsPressed(showHitboxPivotsHotkey))
	{
		oldStatus = drawHitboxPivots;
		drawHitboxPivots = !drawHitboxPivots;
		timestamp();
		printf("%s drawing hitbox center axes.\n",
			(oldStatus ? "Disabled" : "Enabled"));
		return;
	}
}

atk_button_t updateRangeMarkerChoice(int which)
{
	atk_button_t showRange = showButtonRanges[which];
	bool updated = false;

	if (keyIsPressed(showButtonRangeHotkeys[which]))
	{
		showRange = ++showRange % (SHOW_NO_BUTTON_RANGES + 1);
		showButtonRanges[which] = showRange;
		updated = true;
	}

	if (updated)
	{
		timestamp();
		if (showRange == SHOW_NO_BUTTON_RANGES)
		{
			printf(
				"Disabled close normal range marker for player %d.\n",
				(which + 1));
		}
		else
		{
			printf(
				"Showing close standing %c activation range for player %d.\n",
				buttonNames[showButtonRanges[which]], (which + 1));
		}
	}

	return showRange;
}

void drawCloseNormalRangeMarker(
	player_t *player, player_extra_t *playerExtra, int which)
{
	atk_button_t showRange = updateRangeMarkerChoice(which);
	if (showRange == SHOW_NO_BUTTON_RANGES || !shouldShowRangeMarkerFor(player))
	{
		return;
	}

	int facingAdjustment = (player->facing == FACING_RIGHT ? 1 : -1);
	// subtract 1 because otherwise close normal won't activate unless
	// the activation line is "behind" the center of the opponent's pivot axis
	// (i.e., close normal won't activate if the two overlap exactly)
	int activeRange = playerExtra->closeRanges[showRange] - 1;
	player_coords_t lineOrigin, lineExtent, barTop, barBottom;
	absoluteWorldCoordsFromPlayer(player, &lineOrigin);
	memcpy(&lineExtent, &lineOrigin, sizeof(lineOrigin));
	adjustWorldCoords(&lineExtent, activeRange * facingAdjustment, 0);
	memcpy(&barTop, &lineExtent, sizeof(lineExtent));
	memcpy(&barBottom, &lineExtent, sizeof(lineExtent));
	barTop.yComplete.value = 0;
	barBottom.yPart = 0;
	barBottom.y = (screenDims->basicHeight * 2);

	glColor4ubv(closeNormalRangeColor);
	drawRectangle(&lineOrigin, &lineExtent);
	drawRectangle(&barTop, &barBottom);
}

bool drawHitbox(player_t *player, hitbox_t *hitbox, boxtype_t boxType)
{
	if (!boxTypeCheck(boxType) || !boxSizeCheck(hitbox))
	{
		return false;
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
		glColor4ubv(boxFillColors[boxType]);
		drawRectangle(&boxTopLeft, &boxBottomRight);
	}
	glColor4ubv(boxEdgeColors[boxType]);
	drawBox(&boxTopLeft, &boxBottomRight);
	if (drawHitboxPivots)
	{
		drawPivot(&boxCenter, SMALL_PIVOT_SIZE);
	}
	return true;
	/*
	printf("%02X %02X %02X %02X %02X\n",
		hitbox->boxID,
		hitbox->xPivot, hitbox->yPivot,
		hitbox->xRadius, hitbox->yRadius);
	//*/
}

void drawProjectiles(game_state_t *source)
{
	int count = currentGame->projectilesListSize;
	projectile_t *projs = source->projectiles;
	projectile_t *current;
	hitbox_t *hitbox;
	boxtype_t boxType;

	for (int i = 0; i < count; i++)
	{
		current = projs + i;
		if (!projectileIsActive(current))
		{
			continue;
		}

		int boxesDrawn = 0; // avoid drawing pivots for background decorations
		for (int j = 0; j < HBLISTSIZE; j++)
		{
			hitbox = &(current->hitboxes[j]);
			boxType = hitboxType(hitbox);
			// detect and skip over "ghost boxes" that occur in '02UM
			//*
			if (boxType == BOX_ATTACK && j == 1)
			{
				continue;
			}
			//*/
			boxType = projectileTypeEquivalentFor(boxType);
			if (drawHitbox((player_t*)current, hitbox, boxType)) {
				boxesDrawn++;
			}
		}
		if (boxesDrawn > 0)
		{
			drawPlayerPivot((player_t*)current);
		}
	}
}

void capturePlayerData(game_state_t *source, int which)
{
	player_t *player = &(source->players[which]);
	player_extra_t *playerExtra = &(source->playersExtra[which]);
	hitbox_t *hitbox;
	boxtype_t boxType;

	for (int i = 0; i < HBLISTSIZE; i++)
	{
		hitbox = &(player->hitboxes[i]);
		if (hitboxIsActive(player, hitbox, hitboxActiveMasks[i]))
		{
			boxType = hitboxType(hitbox);
			// detect and skip over "ghost boxes" that occur in '02UM
			//*
			if (boxType == BOX_ATTACK && i == 1)
			{
				continue;
			}
			//*/
			storeBox(which, boxType, hitbox);
		}
	}

	// draw collision box
	hitbox = &(player->collisionBox);
	if (collisionBoxIsActive(player, hitbox)) {
		storeBox(which, BOX_COLLISION, hitbox);
	}

	// draw "throwing" box
	hitbox = &(player->throwBox);
	if (drawThrowBoxes && throwBoxIsActive(player, hitbox)) {
		storeBox(which, BOX_THROW, hitbox);
	}

	// draw "throwable" box
	hitbox = &(player->throwableBox);
	if (drawThrowableBoxes && throwableBoxIsActive(player, hitbox)) {
		storeBox(which, BOX_THROWABLE, hitbox);
	}
}

void drawPlayer(game_state_t *source, int which)
{
	player_t *player = &(source->players[which]);
	player_extra_t *playerExtra = &(source->playersExtra[which]);
	hitbox_t **layerBoxes, *currentBox;
	boxtype_t layerType;
	int layerBoxCount;

	for (int layer = 0; layer < validBoxTypes; layer++)
	{
		layerType = boxTypeForLayer(layer);
		layerBoxes = playerBoxesInLayer(which, layer);
		layerBoxCount = playerBoxCountInLayer(which, layer);

		for (int i = 0; i < layerBoxCount; i++)
		{
			currentBox = *(layerBoxes + i);
			drawHitbox(player, currentBox, layerType);
		}
	}

	drawPlayerPivot(player);
	drawCloseNormalRangeMarker(player, playerExtra, which);
}

void drawScene(game_state_t *source)
{
	checkMiscHotkeys();
	clearStoredBoxes();
	glClear(GL_COLOR_BUFFER_BIT);
	glBegin(GL_TRIANGLES);

	for (int i = 0; i < PLAYERS; i++)
	{
		if (shouldDisplayPlayer(source, i))
		{
			capturePlayerData(source, i);
			drawPlayer(source, i);
		}
	}
	drawProjectiles(source);

	glEnd();
	SwapBuffers(source->overlayHdc);
	glFinish();
}
