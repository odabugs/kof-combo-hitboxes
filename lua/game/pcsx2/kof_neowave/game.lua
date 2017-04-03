local KOF02 = require("game.pcsx2.kof2002um.game")
local KOF_Neowave = KOF02:new({ whoami = "KOF_Neowave" })

KOF_Neowave.configSection = "kof_neowave"
KOF_Neowave.absoluteYOffset = 17
-- game-specific constants
KOF_Neowave.revisions = {
	-- TODO: NTSC-J
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
function KOF_Neowave:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
	self.drawGauges = false -- override config option to draw gauge overlays
end

return KOF_Neowave
