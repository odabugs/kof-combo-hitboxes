#ifndef NO_KOF_02
{
	.windowTitle = "King of Fighters 2002 Unlimited Match",
	.shortName = "King of Fighters 2002UM (Steam)",
	.basicWidth = 320,
	.basicHeight = 224,
	.recommendResolution = "640x448",
	.extraRecommendations = "Additionally, please set your game to Type B under Options, Graphics Settings.",
	.aspectMode = AM_PILLARBOX,
	.groundOffset = BASIC_GROUND_OFFSET,
	.playerAddresses = {
		(player_t*)0x0167C3A0,
		(player_t*)0x0167C5C0
	},
	.cameraAddress = (camera_t*)0x02208BF8,
	.rosterSize = KOF_02_ROSTER_SIZE,
	.roster = (character_def_t*)&kof02_roster
},
#endif /* NO_KOF_02 */
