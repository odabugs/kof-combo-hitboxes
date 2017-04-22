local ffi = require("ffi")
local types = require("game.steam.ggxxreload.types")
local GGXXAC = require("game.steam.ggxxacplusr.game")
local GGXX = GGXXAC:new({ parent = GGXXAC, whoami = "GGXXReload" })

-- game-specific constants
GGXX.playerPtrs = { 0x005D0BA4, 0x005FE064 } -- pointers to pointers
-- "start" here is a pointer-to-pointer
GGXX.projectilesListInfo = { start = 0x005D0890, step = 0x104, count = 20 }
GGXX.cameraPtr = 0x005CC714

function GGXX:extraInit(noExport)
	types:export(ffi)
	self.parent.extraInit(self, true)
end

return GGXX
