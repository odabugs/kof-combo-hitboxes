#include "gamedefs.h"
#include "kof98/kof98_roster.h"
#include "kof02/kof02_roster.h"

#define BASIC_GROUND_OFFSET 22.5

gamedef_t gamedefs_list[] = {
	#include "kof98/kof98_gamedef.h"
	#include "kof02/kof02_gamedef.h"
	// list ender - DO NOT REMOVE THIS
	{
		.windowTitle = (char*)NULL
	}
};
