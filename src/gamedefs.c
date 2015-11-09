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
