#ifndef NO_KOF_98
#include "../boxtypes.h"
#include "../gamedefs.h"
#include "kof98_roster.h"
#include "kof98_boxtypemap.h"

gamedef_t kof98_gamedef = {
	.windowTitle = "King of Fighters '98 Ultimate Match Final Edition",
	.shortName = "King of Fighters '98UMFE (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448 or 796x448",
	.extraRecommendations = (char*)NULL,
	.aspectMode = AM_PILLARBOX,
	.playerAddresses = {
		(void*)0x0170D000,
		(void*)0x0170D200
	},
	.playerExtraAddresses = {
		(void*)0x01715600,
		(void*)0x0171580C
	},
	.player2ndExtraAddresses = {
		(void*)0x01703800,
		(void*)0x01703A00
	},
	.cameraAddress = (void*)0x0180C938,
	.projectilesListStart = (void*)0x1703000,
	.projectilesListSize = 51, // final projectiles list entry starts at 0x01709600
	.projectilesListStep = 0x200,
	.extraStructIndex = 1, // '98 player_extra_t pointer is at player_t +1A8h
	.rosterSize = KOF_98_ROSTER_SIZE,
	.roster = (character_def_t*)&kof98_roster,
	.boxTypeMap = (boxtype_t*)&kof98_boxTypeMap
};
#endif /* NO_KOF_98 */
