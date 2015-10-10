#ifndef NO_KOF_98
#define KOF_98_ROSTER_SIZE 0x40
{
	.windowTitle = "King of Fighters '98 Ultimate Match Final Edition",
	.shortName = "King of Fighters '98UMFE (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448",
	.extraRecommendations = (char*)NULL,
	.aspectMode = AM_PILLARBOX,
	.groundOffset = BASIC_GROUND_OFFSET,
	.playerAddresses = {
		(player_t*)0x0170D000,
		(player_t*)0x0170D200
	},
	.cameraAddress = (camera_t*)0x0180C938,
	.rosterSize = KOF_98_ROSTER_SIZE,
	.roster = (character_def_t*)&kof98_roster
},
#endif /* NO_KOF_98 */
