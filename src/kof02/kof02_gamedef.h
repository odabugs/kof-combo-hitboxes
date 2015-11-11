#ifndef NO_KOF_02
#include "../boxtypes.h"
#include "../gamedefs.h"
#include "kof02_roster.h"
#include "kof02_boxtypemap.h"

gamedef_t kof02_gamedef = {
	.windowTitle = "King of Fighters 2002 Unlimited Match",
	.shortName = "King of Fighters 2002UM (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448 or 796x448",
	.extraRecommendations = "Additionally, please set your game to Type B under Options, Graphics Settings.",
	.aspectMode = AM_PILLARBOX,
	.playerAddresses = {
		(void*)0x0167C3A0,
		(void*)0x0167C5C0
	},
	.playerExtraAddresses = {
		(void*)0x0167EA00,
		(void*)0x01683240
	},
	.player2ndExtraAddresses = {
		(void*)0x0166E260,
		(void*)0x0166E480
	},
	.cameraAddress = (void*)0x02208BF8,
	.projectilesListStart = (void*)0x0166DE20,
	.projectilesListSize = 34, // final projectiles list entry starts at 0x01672880(?)
	.projectilesListStep = 0x220,
	.extraStructIndex = 0, // '02 player_extra_t pointer is at player_t +1A4h
	.rosterSize = KOF_02_ROSTER_SIZE,
	.roster = (character_def_t*)&kof02_roster,
	.boxTypeMap = (boxtype_t*)&kof02_boxTypeMap
};
#endif /* NO_KOF_02 */
