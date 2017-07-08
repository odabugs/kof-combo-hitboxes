local KOF02 = require("game.pcsx2.kof2002um.game")
local KOF_Neowave = KOF02:new({ whoami = "KOF_Neowave" })

KOF_Neowave.configSection = "kof_neowave"
KOF_Neowave.absoluteYOffset = 17
-- game-specific constants
KOF_Neowave.revisions = {
	["NTSC-J"] = {
		playerPtrs = { 0x0064BDA8, 0x0064BFC0 },
		playerExtraPtrs = { 0x0063BAC8, 0x0063B8B0 },
		cameraPtr = 0x0063E838,
		projectilesListInfo = {
			start = 0x00640138,
			count = 90,
			step  = 0x218,
		},
	},
	["PAL"] = {
		playerPtrs = { 0x0051E2E8, 0x0051E500 },
		playerExtraPtrs = { 0x0050E008, 0x0050DDF0 },
		cameraPtr = 0x00510D78,
		projectilesListInfo = {
			start = 0x00512678,
			count = 90,
			step  = 0x218,
		},
	},
}
KOF_Neowave.extraRecommendation = [[
Additionally, please set Screen to Type A in Game Options, Graphic Settings.]]

function KOF_Neowave:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
	self.drawGauges = false -- override config option to draw gauge overlays
end

return KOF_Neowave
