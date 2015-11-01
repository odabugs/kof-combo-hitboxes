#include "playerstruct.h"

// global, set during game loadup in gamestate.c
boxtype_t *boxTypeMap;

boxtype_t hitboxType(hitbox_t *hitbox)
{
	boxtype_t result = boxTypeMap[hitbox->boxID];
	//printf("Type for %02X is %d\n", hitbox->boxID, (int)result);
	return result;
}

bool hitboxIsActive(hitbox_t *hitbox)
{
	return (hitboxType(hitbox) != BOX_DUMMY);
}
