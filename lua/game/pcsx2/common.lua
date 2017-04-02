local Game_Common = require("game.common")
local PCSX2_Common = Game_Common:new()

PCSX2_Common.whoami = "PCSX2_Common"
-- fixed starting address where PCSX2 stores the game's emulated RAM state
PCSX2_Common.RAMbase = 0x20000000
PCSX2_Common.RAMlimit = 0x21FFFFFF

-- for cases where we want to export some values from this class into others
-- without directly inheriting from this class
function PCSX2_Common:export(target)
	target.RAMbase, target.RAMlimit = self.RAMbase, self.RAMlimit
end

return PCSX2_Common
