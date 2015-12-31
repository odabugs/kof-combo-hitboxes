#include "draw.h"

#define LARGE_PIVOT_SIZE 5
#define SMALL_PIVOT_SIZE 2

void drawPlayerPivot(player_t *player)
{
	player_coords_t pivot;
	worldCoordsFromPlayer(player, &pivot);

	selectColor(playerPivotColor);
	drawPivot(&pivot, LARGE_PIVOT_SIZE);
}

void drawCloseNormalRangeMarker(
	player_t *player, player_extra_t *playerExtra, int which)
{
	atk_button_t showRange = showButtonRanges[which];
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
	worldCoordsFromPlayer(player, &lineOrigin);
	memcpy(&lineExtent, &lineOrigin, sizeof(lineOrigin));
	adjustWorldCoords(&lineExtent, activeRange * facingAdjustment, 0);
	memcpy(&barTop, &lineExtent, sizeof(lineExtent));
	memcpy(&barBottom, &lineExtent, sizeof(lineExtent));
	barTop.yComplete.value = 0;
	barBottom.yPart = 0;
	barBottom.y = (screenDims->basicHeight * 2);

	selectColor(closeNormalRangeColor);
	drawRectangle(&lineOrigin, &lineExtent);
	drawRectangle(&barTop, &barBottom);
}

void drawHitbox(player_t *player, hitbox_t *hitbox, boxtype_t boxType)
{
	if (!boxTypeCheck(boxType) || !boxSizeCheck(hitbox))
	{
		return;
	}
	player_coords_t pivot, boxCenter, boxTopLeft, boxBottomRight;
	int offsetX = hitbox->xPivot * (player->facing == FACING_RIGHT ? -1 : 1);
	int offsetY = hitbox->yPivot;
	int xRadius = hitbox->xRadius;
	int yRadius = hitbox->yRadius;

	worldCoordsFromPlayer(player, &pivot);
	memcpy(&boxCenter, &pivot, sizeof(pivot));
	memcpy(&boxTopLeft, &pivot, sizeof(pivot));
	memcpy(&boxBottomRight, &pivot, sizeof(pivot));
	adjustWorldCoords(&boxCenter, offsetX, offsetY);
	adjustWorldCoords(&boxTopLeft, (offsetX - xRadius), (offsetY - yRadius));
	adjustWorldCoords(&boxBottomRight, (offsetX + xRadius - 1), (offsetY + yRadius - 1));

	if (drawBoxFill)
	{
		selectFillColor(boxType);
		drawRectangle(&boxTopLeft, &boxBottomRight);
	}
	selectEdgeColor(boxType);
	drawBox(&boxTopLeft, &boxBottomRight);
	if (drawHitboxPivots)
	{
		drawPivot(&boxCenter, SMALL_PIVOT_SIZE);
	}
}

void drawProjectiles(game_state_t *source)
{
	int count = currentGame->projectilesListSize;
	projectile_t *projs = source->projectiles;

	for (int i = 0; i < count; i++)
	{
		projectile_t *current = projs + i;
		player_t *asPlayer = (player_t*)current;
		if (!projectileIsActive(current))
		{
			continue;
		}

		int boxesDrawn = 0; // avoid drawing pivots for background decorations
		for (int j = 0; j < HBLISTSIZE; j++)
		{
			hitbox_t *hitbox = &(current->hitboxes[j]);
			boxtype_t boxType = hitboxType(hitbox);

			// detect and skip over "ghost boxes" that occur in '02UM
			if (boxType == BOX_ATTACK && j == 1)
			{
				continue;
			}

			if (hitboxIsActive(asPlayer, hitbox, hitboxActiveMasks[j]))
			{
				boxType = projectileTypeEquivalentFor(boxType);
				drawHitbox(asPlayer, hitbox, boxType);
				boxesDrawn++;
			}
		}
		if (boxesDrawn > 0)
		{
			drawPlayerPivot(asPlayer);
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
			if (boxType == BOX_ATTACK && i == 1)
			{
				continue;
			}

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
	checkHotkeys();
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
