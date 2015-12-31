#include "gamedefs.h"
#include "kof98/kof98_gamedef.h"
#include "kof02/kof02_gamedef.h"

gamedef_t *currentGame;

// list ender - DO NOT REMOVE THIS
gamedef_t gamedefSentinel =
{
	.windowTitle = (char*)NULL
};

gamedef_t *gamedefs_list[] = {
	#ifndef NO_KOF_98
	&kof98_gamedef,
	#endif
	#ifndef NO_KOF_02
	&kof02_gamedef,
	#endif
	&gamedefSentinel
};

// TODO: if player is using an EX character then this yields the non-EX equivalent
character_def_t *characterForID(int charID)
{
	if (charID < 0 || charID >= currentGame->rosterSize)
	{
		return (character_def_t*)NULL;
	}
	return &(currentGame->roster[charID]);
}

char *characterNameForID(int charID)
{
	character_def_t *result = characterForID(charID);
	return ((result == (character_def_t*)NULL) ? "INVALID" : result->charName);
}
