local ffi = require("ffi")
local types = require("game.steam.ggxxreload.types")
local GGXXAC = require("game.steam.ggxxacplusr.game")
local GGXX = GGXXAC:new({ parent = GGXXAC, whoami = "GGXXReload" })

-- game-specific constants
GGXX.playerPtrs = { 0x005D2024, 0x005FF584 } -- pointers to pointers
GGXX.cameraPtr = 0x005CDCA4

function GGXX:extraInit(noExport)
	types:export(ffi)
	self.parent.extraInit(self, true)
end

return GGXX
