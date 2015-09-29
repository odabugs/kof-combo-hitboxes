#include "gamedefs.h"

char kof98_title[] = "King of Fighters '98 Ultimate Match Final Edition";
char kof02_title[] = "King of Fighters 2002 Unlimited Match";

gamedef_t gamedefs_list[] = {
	{
		.windowTitle = kof98_title,
		.playerAddresses = { 0x0170D000, 0x0170D200 },
		.cameraAddress = 0x0180C938
	},
	{
		.windowTitle = kof02_title,
		.playerAddresses = { 0x0167C3A0, 0x0167C5C0 },
		.cameraAddress = 0x02208BF8
	},
	{
		.windowTitle = NULL
	}
};
