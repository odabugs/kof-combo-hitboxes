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
local boxtypes = require("game.steam.kof_xiii.boxtypes")
local Game_Common = require("game.common")
-- TODO: KOF XIII viewer must be synchronized with the game to work right
--       (this will require replacing the functionality provided by pydbg)
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
	self.boxtypes = boxtypes
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.hitboxListHeads = ffiutil.ntypes("hitboxListHead", 2, 1)
	self.teams = ffiutil.ntypes("team", 2, 1)
	self.pivots = { { x = 0, y = 0 }, { x = 0, y = 0 } }
	self.hitboxSets = { {}, {} }
	self.hitboxListHandlers = self:constructHitboxListHandlers()
	self.hitboxBuffer = ffi.new("hitbox")
end

function KOF13:constructHitboxListHandlers()
	local function always(boxtype)
		return function() return boxtype end
	end
	local bt = self.boxtypes
	local function lookupBoxType(hitbox)
		return bt:typeForID(hitbox.boxID) or "attack"
	end

	local n1, n2 = "nextPtr1", "nextPtr2"
	return {
		{ key = n2, getType = always("collision") },
		{ key = n1, getType = lookupBoxType },
		{ key = n1, getType = always("guard") },
		{ key = n1, getType = always("vulnerable") },
		{ key = n2, getType = always("proximity") },
	}
end

function KOF13:captureState()
	self:read(self.cameraPtr, self.camera)
	for i = 1, 2 do
		self:capturePlayerState(i)
	end
end

function KOF13:capturePlayerState(which)
	local playerPtr = self:readPtr(self.playerPtrs[which])
	local player = self.players[which]
	local pivot = self.pivots[which]
	self:read(playerPtr, player)
	pivot.x, pivot.y = player.position.x, player.position.y

	self:read(self.teamPtrs[which], self.teams[which])
	self:read(self.hitboxListHeadPtrs[which], self.hitboxListHeads[which])
	--self:capturePlayerHitboxes(which)
end

-- TODO: separate "capturing" and "drawing" hitboxes into distinct phases
function KOF13:capturePlayerHitboxes(which)
	local hbListHead = self.hitboxListHeads[which]
	local handlers = self.hitboxListHandlers
	local buffer = self.hitboxBuffer
	local bt = self.boxtypes

	local h, key, getType, currentHead, nextPtr, boxType
	for i = 1, #handlers do
		h = handlers[i]
		key, getType = h.key, h.getType
		currentHead = hbListHead.listPointers[i-1]
		nextPtr = currentHead.head
		nextPtr = self:readPtr(nextPtr)
		---[=[
		if currentHead.count > 0 then
			print(string.format("Reading %d hitboxes from head at 0x%08X",
				currentHead.count, nextPtr))
		end
		--]=]
		for j = 1, currentHead.count do
			self:read(nextPtr, buffer)
			boxType = getType(buffer)
			print("boxtype is " .. boxType)
			self:drawHitbox(buffer, bt:colorForType(boxType))
			nextPtr = buffer[key]
		end
	end
end

function KOF13:worldToScreen(x, y)
	local shake = self.camera.shake
	x = self.centerX + x + shake.x
	y = self.height - y - shake.y
	return x, y
end

function KOF13:drawHitbox(hitbox, color)
	local x1, y1 = hitbox.position.x, hitbox.position.y
	local w, h = hitbox.size.x, hitbox.size.y
	if w <= 0 or h <= 0 then return end
	local x2, y2 = x1 + w - 1, y1 + h - 1
	x1, y1 = self:worldToScreen(x1, y1)
	x2, y2 = self:worldToScreen(x2, y2)
	y1, y2 = y2, y1
	--local color = self.boxtypes:colorForType(boxtype)
	--print(string.format("(%d, %d) to (%d, %d)", x1, y1, x2, y2))
	---[=[
	print(string.format("Origin: (%f, %f), Size: (%.2f, %f)",
		hitbox.position.x, hitbox.position.y, w, h))
	--]=]
	self:box(x1, y1, x2, y2, color)
end

function KOF13:drawPlayer(which)
	local player = self.players[which]
	local pivot = self.pivots[which]
	local pivotX, pivotY = self:worldToScreen(pivot.x, pivot.y)
	self:capturePlayerHitboxes(which)
	self:pivot(pivotX, pivotY, self.pivotSize, colors.WHITE)
end

function KOF13:renderState()
	print("-----")
	for i = 1, 2 do self:drawPlayer(i) end
end

return KOF13
