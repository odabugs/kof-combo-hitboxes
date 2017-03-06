local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local boxtypes = require("game.steam.kof2002um.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local KOF98 = require("game.steam.kof98um.game")
local PCSX2_Common = require("game.pcsx2.common")
local KOF_Neowave = KOF98:new({ parent = KOF98, whoami = "KOF_Neowave" })
PCSX2_Common:export(KOF_Neowave)

-- this game renders at 640x448, but the "world" is effectively 320x224
KOF_Neowave.aspectMode = "stretch"
KOF_Neowave.absoluteYOffset = 18
-- game-specific constants
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

function KOF_Neowave:extraInit(noExport)
	self:importRevisionSpecificOptions(true)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
	self.boxtypes = boxtypes
	self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
		self.boxSlotConstructor, self.boxtypes)
	self.parent.extraInit(self, true)
end

return KOF_Neowave
