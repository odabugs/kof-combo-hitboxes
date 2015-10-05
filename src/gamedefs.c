#include "gamedefs.h"

static char
	kof98_title[] = "King of Fighters '98 Ultimate Match Final Edition",
	kof02_title[] = "King of Fighters 2002 Unlimited Match";
#define BASIC_GROUND_OFFSET 22.5

gamedef_t gamedefs_list[] = {
	#ifndef NO_KOF_98
	{
		.windowTitle = kof98_title,
		.shortName = "King of Fighters '98UMFE (Steam)",
		.basicWidth = 320,
		.basicWidescreenWidth = 398,
		.basicHeight = 224,
		.recommendResolution = "640x448",
		.aspectMode = AM_PILLARBOX,
		.groundOffset = BASIC_GROUND_OFFSET,
		.playerAddresses = {
			(player_t*)0x0170D000,
			(player_t*)0x0170D200
		},
		.cameraAddress = (camera_t*)0x0180C938
	},
	#endif
	#ifndef NO_KOF_02
	{
		.windowTitle = kof02_title,
		.shortName = "King of Fighters 2002UM (Steam)",
		.basicWidth = 320,
		.basicWidescreenWidth = 398,
		.basicHeight = 224,
		.recommendResolution = "640x448",
		.aspectMode = AM_PILLARBOX,
		.groundOffset = BASIC_GROUND_OFFSET,
		.playerAddresses = {
			(player_t*)0x0167C3A0,
			(player_t*)0x0167C5C0
		},
		.cameraAddress = (camera_t*)0x02208BF8
	},
	#endif
	// list ender - DO NOT REMOVE THIS
	{
		.windowTitle = NULL
	}
};
