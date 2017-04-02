local boxtypes = require("game.steam.kof2002um.boxtypes")
local BoxSet = require("game.boxset")
local KOF98 = require("game.steam.kof98um.game")
local PCSX2_Common = require("game.pcsx2.common")
local KOF_Neowave = KOF98:new({ parent = KOF98, whoami = "KOF_Neowave" })
PCSX2_Common:export(KOF_Neowave)

KOF_Neowave.configSection = "kof_neowave"
-- this game renders at 640x448, but the "world" is effectively 320x224
KOF_Neowave.aspectMode = "stretch"
KOF_Neowave.absoluteYOffset = 18
-- game-specific constants
KOF_Neowave.boxtypes = boxtypes
KOF_Neowave.revisions = {
	-- TODO: NTSC-J
	["PAL"] = {
		playerPtrs = { 0x0051E2E8, 0x0051E500 },
		playerExtraPtrs = { 0x0050E008, 0x0050DDF0 },
		cameraPtr = 0x00510D78,
		projectilesListInfo = { -- TODO: Are there more entries than this?
			start = 0x00512AA8,
			count = 14,
			step  = 0x218,
		},
	},
}
-- use of false instead of nil avoids need for rawget() and associated issues
KOF_Neowave.startupMessage = false

function KOF_Neowave:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
	self.drawGauges = false -- override config option to draw gauge overlays
end

-- don't import Steam 98UMFE's hotkeys since they conflict with PCSX2'S hotkeys
function KOF_Neowave:checkInputs()
	return
end

return KOF_Neowave
