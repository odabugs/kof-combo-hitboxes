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
local Game_Common = require("game.common")
local KOF98 = Game_Common:new({ whoami = "KOF98" })

KOF98.basicWidth = 320
KOF98.basicHeight = 224
KOF98.aspectMode = "pillarbox"
KOF98.absoluteYOffset = 16
KOF98.pivotSize = 5
KOF98.boxPivotSize = 2
KOF98.drawStaleThrowBoxes = true
-- game-specific constants
KOF98.playerPtrs = { 0x0170D000, 0x0170D200 }
KOF98.playerExtraPtrs = { 0x01715600, 0x0171580C }
KOF98.player2ndExtraPtrs = { 0x01703800, 0x01703A00 }
KOF98.cameraPtr = 0x0180C938
KOF98.projectilesListInfo = { start = 0x01703000, count = 51, step = 0x200 }

function KOF98:extraInit(noExport)
	if not noExport then types:export(ffi) end
	self.boxtypes = boxtypes
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.player2ndExtras = ffiutil.ntypes("playerSecondExtra", 2, 1)
	self.projectiles = ffiutil.ntypes(
		"projectile", self.projectilesListInfo.count, 1)
	self.projectilesActive = {}
	for i = 1, self.projectilesListInfo.count do
		self.projectilesActive[i] = false
	end
end

function KOF98:capturePlayerState(which)
	self:read(self.playerPtrs[which], self.players[which])
	self:read(self.playerExtraPtrs[which], self.playerExtras[which])
	self:read(self.player2ndExtraPtrs[which], self.player2ndExtras[which])
end

function KOF98:captureProjectiles()
	local info = self.projectilesListInfo
	local pointer, step = info.start, info.step
	local target, active = self.projectiles, self.projectilesActive
	local current
	for i = 1, info.count do
		current = target[i]
		self:read(pointer, current)
		active[i] = (current.basicStatus > 0)
		pointer = pointer + step
	end
end

function KOF98:captureState()
	self:read(self.cameraPtr, self.camera)
	for i = 1, 2 do self:capturePlayerState(i) end
	self:captureProjectiles()
end

-- return -1 if player is facing left, or +1 if player is facing right
function KOF98:facingMultiplier(player, inverse)
	if inverse then
		return ((player.facing == 0) and -1) or 1
	else
		return ((player.facing == 0) and 1) or -1
	end
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

function KOF98:renderBox(player, hitbox, color, facing)
	if hitbox.width == 0 or hitbox.height == 0 then return end
	local cx, cy, w, h = self:deriveBoxPosition(player, hitbox, facing)
	self:box(cx - w, cy - h, cx + w, cy + h, color)
	self:pivot(cx, cy, self.boxPivotSize, color)
end

function KOF98:throwableBoxIsActive(player, hitbox)
	if bit.band(player.statusFlags2nd[3], 0x20) ~= 0 then return false
	elseif bit.band(player.statusFlags[2], 0x03) == 1 then return false
	elseif player.throwableStatus ~= 0 then return false
	elseif bit.band(hitbox.boxID, 0x80) ~= 0 then return false
	else return true end
end

local colormap = {
	colors.RED,
	colors.GREEN,
	colors.BLUE,
	colors.YELLOW,
	colors.MAGENTA,
	colors.CYAN,
	colors.WHITE,
}
function KOF98:drawCharacter(target, pivotColor, isProjectile, facing)
	pivotColor = (pivotColor or colors.WHITE)
	facing = (facing or self:facingMultiplier(target))
	local pivotX, pivotY = target.screenX, target.screenY
	local boxstate = target.statusFlags[0]
	local bt, boxtype, boxesDrawn = self.boxtypes, "dummy", 0
	local hitbox, boxColor
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
			boxColor = bt:colorForType(boxtype)
			self:renderBox(target, hitbox, boxColor, facing)
			boxesDrawn = boxesDrawn + 1
			--self:renderBox(target, hitbox, colormap[i+1], facing)
			::continue::
		end
	end
	if not isProjectile then
		-- collision box
		hitbox = target.collisionBox
		if hitbox.boxID ~= 0xFF then
			boxColor = bt:colorForType("collision")
			self:renderBox(target, hitbox, boxColor, facing)
		end
		-- "throw" box
		hitbox = target.throwBox
		if self.drawStaleThrowBoxes or (hitbox.boxID ~= 0) then
			--print(string.format("Active throw box (ID=0x%02X)", hitbox.boxID))
			boxColor = bt:colorForType("throw")
			self:renderBox(target, hitbox, boxColor, facing)
		end
		-- "throwable" box
		hitbox = target.throwableBox
		if self:throwableBoxIsActive(target, hitbox) then
			boxColor = bt:colorForType("throwable")
			self:renderBox(target, hitbox, boxColor, facing)
		end
		self:pivot(pivotX, pivotY, self.pivotSize, pivotColor)
	-- don't draw pivot axis for projectile if it has no active hitboxes
	elseif boxesDrawn > 0 then
		self:pivot(pivotX, pivotY, self.pivotSize, pivotColor)
	end
end

function KOF98:drawPlayer(which)
	local player = self.players[which]
	self:drawCharacter(player)
end

function KOF98:drawProjectiles()
	local projs, active = self.projectiles, self.projectilesActive
	local current
	for i = 1, self.projectilesListInfo.count do
		if active[i] then
			current = projs[i]
			self:drawCharacter(current, colors.GREEN, true)
		end
	end
end

function KOF98:renderState()
	for i = 1, 2 do self:drawPlayer(i) end
	self:drawProjectiles()
end

return KOF98
