local ffi = require("ffi")
local CVS2 = require("game.pcsx2.cvs2.game")
local CFJ = CVS2:new({ parent = CVS2, whoami = "CFJ" })

CFJ.configSection = "cfj"
CFJ.basicWidth, CFJ.basicHeight = 384, 224
CFJ.absoluteYOffset = 20 -- TODO
CFJ.camXOffset = 384
CFJ.revisions = {
	["NTSC-U"] = {
		playerPtrs = { 0x00340C50, 0x00341210 },
		cameraPtr = 0x0035BFD0,
		projectilesListInfo = {
			start = 0x00341800,
			step = 0x180,
			count = 32,
		},
	},
}

return CFJ
