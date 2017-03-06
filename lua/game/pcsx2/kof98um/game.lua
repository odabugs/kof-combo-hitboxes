local KOF98 = require("game.steam.kof98um.game")
local PCSX2_Common = require("game.pcsx2.common")
local KOF98_PS2 = KOF98:new({ parent = KOF98, whoami = "KOF98_PS2" })
PCSX2_Common:export(KOF98_PS2)

KOF98_PS2.aspectMode = "stretch"
KOF98_PS2.absoluteYOffset = 16
-- game-specific constants
KOF98_PS2.revisions = {
	-- TODO: NTSC-J, PAL
	["NTSC-U"] = {
		playerPtrs = { 0x0050F210, 0x0050F410 },
		playerExtraPtrs = { 0x0050E008, 0x0050DDF0 },
		cameraPtr = 0x00503348,
		projectilesListInfo = { -- TODO: Are there more entries than this?
			start = 0x00505610,
			count = 29,
			step  = 0x200,
		},
	},
}

function KOF98_PS2:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
end

return KOF98_PS2
