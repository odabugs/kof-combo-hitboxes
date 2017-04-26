local ffi = require("ffi")
local types = require("game.steam.ggxxreload.types")
local GGXXAC = require("game.steam.ggxxacplusr.game")
local GGXX = GGXXAC:new({ parent = GGXXAC, whoami = "GGXXReload" })

-- game-specific constants
GGXX.playerPtrs = { 0x001D0BA4, 0x001FE064 } -- pointers to pointers
-- "start" here is a pointer-to-pointer
GGXX.projectilesListInfo = { start = 0x001D0890, step = 0x104, count = 20 }
GGXX.pushBoxTargetPointers = {
	{ 0x0017BF74, 0x0017BFA4 },
	{ 0x0017BFD4, 0x0017BF44 },
	{ 0x0017BF00, 0x0017BF44 },
}
GGXX.cameraPtr = 0x001CC714

function GGXX:extraInit(noExport)
	types:export(ffi)
	self.parent.extraInit(self, true)
end

return GGXX
