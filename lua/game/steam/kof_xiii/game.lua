local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.steam.kof_xiii.types")
--local boxtypes = require("game.steam.kof_xiii.boxtypes")
local Game_Common = require("game.common")
local KOF13 = Game_Common:new({ whoami = "KOF XIII" })

-- 854x480 resolution displays player sprites at approximately 1:1 scale
KOF13.basicWidth = 854
KOF13.basicHeight = 480
KOF13.centerX = KOF13.basicWidth / 2
KOF13.absoluteYOffset = 49
KOF13.aspectMode = "stretch"
KOF13.pivotSize = 20
KOF13.boxPivotSize = 8
KOF13.useThickLines = false
-- game-specific constants
-- locations of pointers to "player" structs
KOF13.playerPtrs = { 0x008320A0, 0x008320A4 }
KOF13.teamPtrs = { 0x00831DF4, 0x00831EF8 } -- locations of "team" structs
-- locations of "hitboxListHead" structs in memory
KOF13.hitboxListHeadPtrs = { 0x007EAC08, 0x007EAC44 }
KOF13.cameraPtr = 0x0082F890 -- location of "camera" struct in memory

function KOF13:extraInit(noExport)
	if not noExport then types:export(ffi) end
	--self.boxtypes = boxtypes
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.hitboxListHeads = ffiutil.ntypes("hitboxListHead", 2, 1)
	self.teams = ffiutil.ntypes("team", 2, 1)
	self.boxes = { {}, {} }
end

function KOF13:captureState()
	self:read(self.cameraPtr, self.camera)
	for i = 1, 2 do
		self:capturePlayerState(i)
	end
end

function KOF13:capturePlayerState(which)
	local playerPtr = self:readPtr(self.playerPtrs[which])
	self:read(playerPtr, self.players[which])
	self:read(self.teamPtrs[which], self.teams[which])
end

function KOF13:worldToScreen(x, y)
	local shake = self.camera.shake
	x = self.centerX + x + shake.x
	y = self.height - y - shake.y
	return x, y
end

function KOF13:drawPlayer(which)
	local player = self.players[which]
	local pivotX, pivotY = player.position.x, player.position.y
	pivotX, pivotY = self:worldToScreen(pivotX, pivotY)
	self:pivot(pivotX, pivotY, self.pivotSize, colors.WHITE)
end

function KOF13:renderState()
	for i = 1, 2 do self:drawPlayer(i) end
end

return KOF13
