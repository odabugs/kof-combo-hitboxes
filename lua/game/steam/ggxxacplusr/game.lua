local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.steam.ggxxacplusr.types")
local boxtypes = require("game.steam.ggxxacplusr.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local Game_Common = require("game.common")
local GGXX = Game_Common:new({ whoami = "GGXXACPlusR" })
local floor = math.floor

GGXX.configSection = "ggxx"
GGXX.basicWidth = 640
GGXX.basicHeight = 480
GGXX.aspectMode = "pillarbox"
GGXX.absoluteYOffset = 40 -- TODO: find best value
GGXX.pivotSize = 12
GGXX.useThickLines = false
GGXX.boxesPerLayer = 50
-- game-specific constants
GGXX.boxtypes = boxtypes
--GGXX.playerPtrs = { 0x01416778, 0x0141A07C } -- pointers to pointers
GGXX.playerPtrs = { 0x00F96778, 0x00F9A07C } -- pointers to pointers
GGXX.invulPtrs = { 0x00F9A062, 0x00F9A1AA }
GGXX.cameraPtr = 0x00F9B0D4

function GGXX:extraInit(noExport)
	if not noExport then types:export(ffi) end
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.invul = ffiutil.ntypes("invul", 2, 1)
	self.boxBuf = ffi.new("hitbox")
	self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
		self.boxSlotConstructor, self.boxtypes)
	self.zoom = 1.0
	---[=[
	for i = 1, 2 do
		local playerPtr = self:readPtr(self.playerPtrs[i])
		print(string.format("Player %d pointer: 0x%08X (0x%08X)", i, playerPtr, self.playerPtrs[i]))
	end
	--]=]
end

function GGXX:captureState()
	self.boxset:reset()
	local cam = self.camera
	self:read(self.cameraPtr, cam)
	self.zoom = cam.zoom / 100
	for i = 1, 2 do self:capturePlayerState(i) end
end

function GGXX:capturePlayerState(which)
	local player, boxBuf = self.players[which], self.boxBuf
	local playerPtr = self:readPtr(self.playerPtrs[which])
	local boxset, boxAdder = self.boxset, self.addBox
	local bt, boxtype = self.boxtypes, "dummy"
	playerPtr = playerPtr
	if playerPtr ~= NULL then
		self:read(playerPtr, player)
		local px, py = player.xPivot, player.yPivot
		local boxPtr, boxCount = player.boxPtr, player.boxCount
		local facing = self:facingMultiplier(player)
		self:read(self.invulPtrs[which], self.invul[which])
		local invul = self.invul[which].value
		for i = 1, boxCount do
			self:read(boxPtr, boxBuf)
			boxtype = bt:typeForID(boxBuf.boxType)
			if not ((boxtype == "dummy" or (boxtype == "vulnerable" and invul ~= 0))) then
				boxset:add(boxtype, boxAdder, self, player, boxBuf, facing)
			end
			boxPtr = boxPtr + 0x0C
		end
	end
end

function GGXX:facingMultiplier(player)
	return ((player.facing == 0) and 1) or -1
end

function GGXX:deriveBoxPosition(player, hitbox, facing)
	local px, py = player.xPivot, player.yPivot
	local x1, y1 = hitbox.xOffset * 100, hitbox.yOffset * 100
	x1, y1 = px + (x1 * facing), py + y1
	local w, h = hitbox.width * 100, hitbox.height * 100
	local x2, y2 = x1 + (w * facing), y1 + h
	x1, y1 = self:worldToScreen(x1, y1)
	x2, y2 = self:worldToScreen(x2, y2)
	return x1, y1, x2, y2
end

function GGXX:worldToScreen(x, y)
	local cam = self.camera
	local ground, z = self.basicHeight, self.zoom
	x = ((x - cam.leftEdge) * z)
	y = ((y - cam.bottomEdge) * z)
	y = ground + y
	return floor(x), floor(y)
end

function GGXX.boxSlotConstructor(i, slot, boxtypes)
	return {
		left = 0, top = 0, right = 0, bottom = 0,
		colorPair = boxtypes:colorForType(slot),
	}
end

function GGXX.addBox(target, parent, player, hitbox, facing)
	if hitbox.width <= 0 or hitbox.height <= 0 then return false end
	local x1, y1, x2, y2 = parent:deriveBoxPosition(player, hitbox, facing)
	target.left, target.top = x1, y1
	target.right, target.bottom = x2, y2
	return true
end

function GGXX.drawBox(hitbox, parent, pivotSize, drawFill)
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	local edge, fill = colorPair[1], (drawFill and colorPair[2]) or colors.CLEAR
	parent:box(x1, y1, x2, y2, edge, fill)
	return 1
end

function GGXX:renderState()
	self.boxset:render(self.drawBox, self,
		self.boxPivotSize, self.drawBoxFills)
	local ps = self.players
	local p, pos, px, py
	for i = 1, 2 do
		p = ps[i]
		local px, py = self:worldToScreen(p.xPivot, p.yPivot)
		self:pivot(px, py)
	end
end

return GGXX
