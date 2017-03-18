local boxtypes = require("game.steam.kof2002um.boxtypes")
local BoxSet = require("game.boxset")
local KOF98 = require("game.steam.kof98um.game")
local KOF02 = KOF98:new({ parent = KOF98, whoami = "KOF02" })

KOF02.configSection = "kof2002um"
-- game-specific constants
KOF02.boxtypes = boxtypes
KOF02.playerPtrs = { 0x0167C3A0, 0x0167C5C0 }
KOF02.playerExtraPtrs = { 0x0167EA00, 0x01683240 }
KOF02.cameraPtr = 0x02208BF8
KOF02.projectilesListInfo = { start = 0x0166DE20, count = 34, step = 0x220 }

function KOF02:extraInit(noExport)
	self.parent.extraInit(self, false) -- inherit typedefs from KOF98
	self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
		self.boxSlotConstructor, self.boxtypes)
end

return KOF02
