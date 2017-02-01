local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.steam.kof98um.types")
local boxtypes = require("game.steam.kof98um.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local Game_Common = require("game.common")
local KOF98 = Game_Common:new({ whoami = "KOF98" })

KOF98.basicWidth = 320
KOF98.basicHeight = 224
KOF98.aspectMode = "pillarbox"
KOF98.absoluteYOffset = 16
KOF98.pivotSize = 5
KOF98.boxPivotSize = 2
KOF98.drawStaleThrowBoxes = false
KOF98.useThickLines = true
KOF98.boxesPerLayer = 20
-- game-specific constants
KOF98.playerPtrs = { 0x0170D000, 0x0170D200 }
KOF98.playerExtraPtrs = { 0x01715600, 0x0171580C }
KOF98.player2ndExtraPtrs = { 0x01703800, 0x01703A00 }
KOF98.cameraPtr = 0x0180C938
KOF98.projectilesListInfo = { start = 0x01703000, count = 51, step = 0x200 }

function KOF98:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self.boxtypes = boxtypes
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
	end
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.player2ndExtras = ffiutil.ntypes("playerSecondExtra", 2, 1)
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", self.projectilesListInfo.count + 2,
		self.pivotSlotConstructor)
	self.projBuffer = ffi.new("projectile")
end

-- Slot constructor function passed to BoxSet:new();
-- this function MUST return a new table instance with every call
function KOF98.boxSlotConstructor(i, slot, boxtypes)
	return {
		centerX = 0, centerY = 0, width = 0, height = 0,
		color = boxtypes:colorForType(slot),
	}
end

function KOF98.pivotSlotConstructor()
	return { x = 0, y = 0, color = colors.WHITE }
end

-- "addFn" passed as parameter to BoxSet:add();
-- this function is responsible for actually writing the new box set entry
function KOF98.addBox(target, parent, cx, cy, w, h)
	if w <= 0 or h <= 0 then return false end
	target.centerX, target.centerY = parent:worldToScreen(cx, cy)
	target.left,  target.top    = parent:worldToScreen(cx - w, cy - h)
	target.right, target.bottom = parent:worldToScreen(cx + w - 1, cy + h - 1)
	return true
end

function KOF98.addPivot(target, color, x, y)
	target.color, target.x, target.y = color, x, y
	return true
end

function KOF98:capturePlayerState(which)
	local player = self.players[which]
	self:read(self.playerPtrs[which], self.players[which])
	self:read(self.playerExtraPtrs[which], self.playerExtras[which])
	self:read(self.player2ndExtraPtrs[which], self.player2ndExtras[which])
	self:captureEntity(player, false)
end

function KOF98:captureProjectiles()
	local info, current = self.projectilesListInfo, self.projBuffer
	local pointer, step = info.start, info.step
	for i = 1, info.count do
		self:read(pointer, current)
		if current.basicStatus > 0 then
			self:captureEntity(current, true)
		end
		pointer = pointer + step
	end
end

function KOF98:captureState()
	self.boxset:reset()
	self.pivots:reset()
	self:read(self.cameraPtr, self.camera)
	for i = 1, 2 do self:capturePlayerState(i) end
	self:captureProjectiles()
end

-- return -1 if player is facing left, or +1 if player is facing right
function KOF98:facingMultiplier(player)
	return ((player.facing == 0) and 1) or -1
end

-- translate a hitbox's position into coordinates suitable for drawing
function KOF98:deriveBoxPosition(player, hitbox, facing)
	local playerX, playerY = player.screenX, player.screenY
	local centerX, centerY = hitbox.x, hitbox.y
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY + centerY -- positive offsets move downward
	local w, h = hitbox.width, hitbox.height
	return centerX, centerY, w, h
end

function KOF98:throwableBoxIsActive(player, hitbox)
	if bit.band(player.statusFlags2nd[3], 0x20) ~= 0 then return false
	elseif bit.band(player.statusFlags[2], 0x03) == 1 then return false
	elseif player.throwableStatus ~= 0 then return false
	elseif bit.band(hitbox.boxID, 0x80) ~= 0 then return false
	else return true end
end

function KOF98:captureEntity(target, isProjectile, facing)
	pivotColor = (pivotColor or colors.WHITE)
	facing = (facing or self:facingMultiplier(target))
	local pivotX, pivotY = target.screenX, target.screenY
	local boxstate = target.statusFlags[0]
	local bt, boxtype, boxesDrawn = self.boxtypes, "dummy", 0
	local boxset, boxAdder, hitbox = self.boxset, self.addBox
	-- attack/vulnerable boxes
	for i = 0, 3 do
		if bit.band(boxstate, bit.lshift(1, i)) ~= 0 then
			hitbox = target.hitboxes[i]
			boxtype = bt:typeForID(hitbox.boxID)
			if i == 1 and boxtype == "attack" then
				goto continue -- don't draw "ghost boxes" in '02UM
			end
			if isProjectile then
				boxtype = bt:asProjectile(boxtype)
			end
			boxset:add(boxtype, boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
			boxesDrawn = boxesDrawn + 1
			::continue::
		end
	end
	if not isProjectile then
		-- collision box
		hitbox = target.collisionBox
		if hitbox.boxID ~= 0xFF then
			boxset:add("collision", boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
		end
		-- "throw" box
		hitbox = target.throwBox
		if self.drawStaleThrowBoxes or (hitbox.boxID ~= 0) then
			--print(string.format("Active throw box (ID=0x%02X)", hitbox.boxID))
			boxset:add("throw", boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
		end
		-- "throwable" box
		hitbox = target.throwableBox
		if self:throwableBoxIsActive(target, hitbox) then
			boxset:add("throwable", boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
		end
		self.pivots:add(self.addPivot, colors.WHITE, self:worldToScreen(
			target.screenX, target.screenY))
	-- don't draw pivot axis for projectile if it has no active hitboxes
	elseif boxesDrawn > 0 then
		self.pivots:add(self.addPivot, colors.GREEN, self:worldToScreen(
			target.screenX, target.screenY))
	end
end

-- "renderFn" passed as parameter to BoxSet:render()
function KOF98.drawBox(hitbox, parent)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local color = hitbox.color
	parent:box(x1, y1, x2, y2, color)
	parent:pivot(cx, cy, parent.boxPivotSize, color)
	return 1
end

function KOF98.drawPivot(pivot, parent)
	parent:pivot(pivot.x, pivot.y, parent.pivotSize, pivot.color)
	return 1
end

function KOF98:renderState()
	self.boxset:render(self.drawBox, self)
	self.pivots:render(self.drawPivot, self)
end

return KOF98
