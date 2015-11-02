// Note: this does not compile standalone
#ifndef NO_KOF_98
{
	.windowTitle = "King of Fighters '98 Ultimate Match Final Edition",
	.shortName = "King of Fighters '98UMFE (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448 or 796x448",
	.extraRecommendations = (char*)NULL,
	.aspectMode = AM_PILLARBOX,
	.groundOffset = BASIC_GROUND_OFFSET,
	.playerAddresses = {
		(player_t*)0x0170D000,
		(player_t*)0x0170D200
	},
	.playerExtraAddresses = {
		(player_extra_t*)0x01715600,
		(player_extra_t*)0x0171580C
	},
	.player2ndExtraAddresses = {
		(player_2nd_extra_t*)0x01703800,
		(player_2nd_extra_t*)0x01703A00
	},
	.cameraAddress = (camera_t*)0x0180C938,
	.rosterSize = KOF_98_ROSTER_SIZE,
	.roster = (character_def_t*)&kof98_roster,
	.boxTypeMap = (boxtype_t*)&kof98_boxTypeMap
},
#endif /* NO_KOF_98 */
