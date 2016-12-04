local Game_Common = require("game.common")
local PCSX2_Common = Game_Common:new()

-- fixed starting address where PCSX2 stores the game's emulated RAM state
PCSX2_Common.RAMbase = 0x20000000
PCSX2_Common.RAMlimit = 0x22000000

return PCSX2_Common
