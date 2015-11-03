#include "playerstruct.h"

// stop-gap fix for the fact that the viewer isn't yet hooked into the game;
// throw boxes practically never show up if thread scheduler is left to its own devices
#define DRAW_STALE_THROW_BOXES true

// global, set during game loadup in gamestate.c
boxtype_t *boxTypeMap;
bool letThrowBoxesLinger = true;
// throw boxes are active for very short time periods;
// making them briefly linger onscreen afterward improves visibility
int baseThrowBoxLingerTime = 60; // frames
int throwBoxLingerTimeRemaining = 0;

bool boxSizeCheckImpl(hitbox_t *hitbox)
{
	return (hitbox->xRadius > 0 && hitbox->yRadius > 0);
}
#define boxSizeCheck(x) if (!boxSizeCheckImpl(x)) { return false; }

boxtype_t hitboxType(hitbox_t *hitbox)
{
	boxtype_t result = boxTypeMap[hitbox->boxID];
	//printf("Type for %02X is %d\n", hitbox->boxID, (int)result);
	return result;
}

bool hitboxIsActive(hitbox_t *hitbox)
{
	boxSizeCheck(hitbox);
	return true; // TODO
	//return (hitboxType(hitbox) != BOX_DUMMY);
}

// TODO: make lingering throw boxes work on a per-player basis
void updateThrowBoxLingerTime(bool isActive)
{
	if (isActive)
	{
		throwBoxLingerTimeRemaining = baseThrowBoxLingerTime;
	}
	else
	{
		if (--throwBoxLingerTimeRemaining < 0)
		{
			throwBoxLingerTimeRemaining = 0;
		}
	}
}

bool throwBoxIsActive(hitbox_t *hitbox)
{
	if (DRAW_STALE_THROW_BOXES) { return true; }
	boxSizeCheck(hitbox);
	bool isActive = (hitbox->boxID != 0);
	updateThrowBoxLingerTime(isActive);
	bool isLingering = (throwBoxLingerTimeRemaining > 0);
	bool result = (isActive || (letThrowBoxesLinger && isLingering));
	if (result) {
		printf(
			"Drawing throw box (%d more lingering frames)\n",
			throwBoxLingerTimeRemaining);
	}
	return result;
}

bool throwableBoxIsActive(hitbox_t *hitbox)
{
	bool isActive = true; // TODO
	boxSizeCheck(hitbox);
	return (letThrowBoxesLinger || isActive);
}
