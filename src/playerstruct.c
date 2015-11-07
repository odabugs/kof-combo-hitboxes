#include "playerstruct.h"

// stop-gap fix for the fact that the viewer isn't yet hooked into the game;
// throw boxes practically never show up if thread scheduler is left to its own devices
#define DRAW_STALE_THROW_BOXES true

char buttonNames[ATTACK_BUTTONS] = {
	'A',
	'B',
	'C',
	'D'
};

// global, set during game loadup in gamestate.c
boxtype_t *boxTypeMap;
bool letThrowBoxesLinger = true;
// throw boxes are active for very short time periods;
// making them briefly linger onscreen afterward improves visibility
int baseThrowBoxLingerTime = 60; // frames
int throwBoxLingerTimeRemaining = 0;

uint8_t hitboxActiveMasks[HBLISTSIZE] = {
	1 << 0,
	1 << 1,
	1 << 2,
	1 << 3
};

boxtype_t hitboxType(hitbox_t *hitbox)
{
	boxtype_t result = boxTypeMap[hitbox->boxID];
	//printf("Type for %02X is %d\n", hitbox->boxID, (int)result);
	return result;
}

// TODO: derive a hitbox's type at runtime
bool hitboxIsActive(player_t *player, hitbox_t *hitbox, uint8_t activeMask)
{
	uint8_t hitboxFlags = player->baseStatusFlags[0];
	return (hitboxFlags & activeMask != 0);
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

bool throwBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	if (DRAW_STALE_THROW_BOXES) { return true; }
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

bool throwableBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	if (player->throwableStatus1 & 0x20 != 0) { return false; }
	if (player->throwableStatus2 & 0x80 != 0) { return false; }
	if (player->baseStatusFlags[2] & 0x03 == 1) { return false; }
	if (hitbox->boxID & 0x80 != 0) { return false; }
	return true;
}

bool collisionBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	return (hitbox->boxID != 0xFF);
}
