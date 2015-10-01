#include "gamedefs.h"

char kof98_title[] = "King of Fighters '98 Ultimate Match Final Edition";
char kof02_title[] = "King of Fighters 2002 Unlimited Match";

gamedef_t gamedefs_list[] = {
	#ifndef NO_KOF_98
	{
		.windowTitle = kof98_title,
		.basicWidth = 320,
		.basicWidescreenWidth = 398,
		.basicHeight = 224,
		.aspectMode = AM_PILLARBOX,
		.groundOffset = 22.5,
		.playerAddresses = { 0x0170D000, 0x0170D200 },
		.cameraAddress = 0x0180C938
	},
	#endif
	#ifndef NO_KOF_02
	{
		.windowTitle = kof02_title,
		.basicWidth = 320,
		.basicWidescreenWidth = 398,
		.basicHeight = 224,
		.aspectMode = AM_PILLARBOX,
		.groundOffset = 22.5,
		.playerAddresses = { 0x0167C3A0, 0x0167C5C0 },
		.cameraAddress = 0x02208BF8
	},
	#endif
	// list ender - DO NOT REMOVE THIS
	{
		.windowTitle = NULL
	}
};
