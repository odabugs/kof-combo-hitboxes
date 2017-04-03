local KOF02 = require("game.steam.kof2002um.game")
local PCSX2_Common = require("game.pcsx2.common")
local KOF02_PS2 = KOF02:new({ whoami = "KOF02_PS2" })
PCSX2_Common:export(KOF02_PS2)

KOF02_PS2.aspectMode = "stretch"
KOF02_PS2.absoluteYOffset = 16
-- game-specific constants
KOF02_PS2.revisions = {
	["NTSC-J"] = {
		playerPtrs = { 0x005CD0D0, 0x005CD2F0 },
		playerExtraPtrs = { 0x005BA048, 0x005B9D30 },
		cameraPtr = 0x005BCDD8,
		projectilesListInfo = {
			start = 0x005BE710,
			count = 110,
			step  = 0x220,
		},
	},
	["NTSC-J Tougeki Ver."] = {
		playerPtrs = { 0x005C7D80, 0x005C7FA0 },
		playerExtraPtrs = { 0x005B4CF8, 0x005B49E0 },
		cameraPtr = 0x005B7A88,
		projectilesListInfo = {
			start = 0x005B93C0,
			count = 110,
			step  = 0x220,
		},
	},
}
-- use of false instead of nil avoids need for rawget() and associated issues
KOF02_PS2.startupMessage = false

function KOF02_PS2:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
end

-- don't import Steam 2002UM's hotkeys since they conflict with PCSX2's hotkeys
function KOF02_PS2:checkInputs()
	return
end

return KOF02_PS2
