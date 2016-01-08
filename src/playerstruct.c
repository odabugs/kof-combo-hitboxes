#include "playerstruct.h"

char buttonNames[ATTACK_BUTTONS] = {
	'A',
	'B',
	'C',
	'D'
};

// global, set during startup in process.c
boxtype_t *boxTypeMap;

uint8_t hitboxActiveMasks[HBLISTSIZE] = {
	1 << 0,
	1 << 1,
	1 << 2,
	1 << 3
};

bool shouldShowRangeMarkerFor(player_t *player)
{
	if ((player->statusFlags2nd[1] & 0x02) != 0) { return false; }
	return true;
}

bool boxTypeCheck(boxtype_t boxType)
{
	return (boxType >= 0 && boxType < validBoxTypes);
}

bool boxSizeCheck(hitbox_t *hitbox)
{
	return (hitbox->xRadius > 0 && hitbox->yRadius > 0);
}

boxtype_t hitboxType(hitbox_t *hitbox)
{
	return boxTypeMap[hitbox->boxID];
}

boxtype_t projectileTypeEquivalentFor(boxtype_t original)
{
	if (original == BOX_ATTACK) { return BOX_PROJECTILE_ATTACK; }
	if (original == BOX_VULNERABLE) { return BOX_PROJECTILE_VULN; }
	return original;
}

bool hitboxIsActive(player_t *player, hitbox_t *hitbox, uint8_t activeMask)
{
	if (!boxTypeCheck(hitboxType(hitbox))) { return false; }
	if (!boxSizeCheck(hitbox)) { return false; }
	uint8_t hitboxFlags = player->statusFlags[0];
	return ((hitboxFlags & activeMask) != 0);
}

bool throwBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	if (!boxSizeCheck(hitbox)) { return false; }
	return (hitbox->boxID != 0);
}

bool throwableBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	if (!boxSizeCheck(hitbox)) { return false; }
	if ((player->statusFlags2nd[3] & 0x20) != 0) { return false; }
	if ((player->statusFlags[2] & 0x03) == 1) { return false; }
	if (player->throwableStatus2 != 0) { return false; }
	if ((hitbox->boxID & 0x80) != 0) { return false; }
	return true;
}

bool collisionBoxIsActive(player_t *player, hitbox_t *hitbox)
{
	if (!boxSizeCheck(hitbox)) { return false; }
	return (hitbox->boxID != 0xFF);
}

bool projectileIsActive(projectile_t *projectile)
{
	return (projectile->basicStatus > 0);
}
