local KOF98 = require("game.steam.kof98um.game")
local PCSX2_Common = require("game.pcsx2.common")
local KOF98_PS2 = KOF98:new({ parent = KOF98, whoami = "KOF98_PS2" })
PCSX2_Common:export(KOF98_PS2)

KOF98_PS2.aspectMode = "stretch"
KOF98_PS2.absoluteYOffset = 16
-- game-specific constants
KOF98_PS2.revisions = {
	["NTSC-J"] = {
		playerPtrs = { 0x00680550, 0x00680750 },
		playerExtraPtrs = { 0x00673EE8, 0x00673CD8 },
		cameraPtr = 0x006766A8,
		projectilesListInfo = {
			start = 0x00676550,
			count = 80,
			step  = 0x200,
		},
	},
	["NTSC-U"] = {
		playerPtrs = { 0x0050F210, 0x0050F410 },
		playerExtraPtrs = { 0x00500B88, 0x00500978 },
		cameraPtr = 0x00503348,
		projectilesListInfo = {
			start = 0x00505210,
			count = 80,
			step  = 0x200,
		},
	},
	["PAL"] = {
		playerPtrs = { 0x00512B10, 0x00512D10 },
		playerExtraPtrs = { 0x00504488, 0x00504278 },
		cameraPtr = 0x00506C48,
		projectilesListInfo = {
			start = 0x00508B10,
			count = 80,
			step  = 0x200,
		},
	},
}
-- use of false instead of nil avoids need for rawget() and associated issues
KOF98_PS2.startupMessage = false

function KOF98_PS2:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
end

-- don't import Steam 98UMFE's hotkeys since they conflict with PCSX2'S hotkeys
function KOF98_PS2:checkInputs()
	return
end

return KOF98_PS2
