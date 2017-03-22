local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
local hotkey = require("hotkey")
local colors = require("render.colors")
local types = require("game.steam.kof98um.types")
local boxtypes = require("game.steam.kof98um.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local Game_Common = require("game.common")
local KOF_Common = require("game.kof_common")
local KOF98 = Game_Common:new({ whoami = "KOF98" })
luautil.extend(KOF98, KOF_Common)

KOF98.configSection = "kof98umfe"
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
KOF98.boxtypes = boxtypes
KOF98.playerPtrs = { 0x0170D000, 0x0170D200 }
KOF98.playerExtraPtrs = { 0x01715600, 0x0171580C }
KOF98.cameraPtr = 0x0180C938
KOF98.projectilesListInfo = { start = 0x01703000, count = 51, step = 0x200 }

KOF98.drawRangeMarkers = { false, false }
KOF98.rangeMarkerHotkeys = { hotkey.VK_F1, hotkey.VK_F2 }

function KOF98:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
	end
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", self.projectilesListInfo.count + 2,
		self.pivotSlotConstructor)
	self.projBuffer = ffi.new("projectile")
end

function KOF98:capturePlayerState(which)
	local player = self.players[which]
	self:read(self.playerPtrs[which], player)
	self:read(self.playerExtraPtrs[which], self.playerExtras[which])
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

function KOF98:rangeMarkerMultiplier(player)
	return self:facingMultiplier(player) * -1
end

function KOF98:getPlayerPosition(player)
	return player.screenX, player.screenY
end

-- translate a hitbox's position into coordinates suitable for drawing
function KOF98:deriveBoxPosition(player, hitbox, facing)
	local playerX, playerY = self:getPlayerPosition(player)
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
	local bt, boxtype, boxesDrawn, i = self.boxtypes, "dummy", 0, 0
	local boxset, boxAdder, hitbox = self.boxset, self.addBox, nil
	-- attack/vulnerable boxes
	while boxstate ~= 0 and i <= 3 do
		if bit.band(boxstate, 1) ~= 0 then
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
		boxstate = bit.rshift(boxstate, 1)
		i = i + 1
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
		self.pivots:add(self.addPivot, self.pivotColor, self:worldToScreen(
			target.screenX, target.screenY))
	-- don't draw pivot axis for projectile if it has no active hitboxes
	elseif boxesDrawn > 0 then
		self.pivots:add(self.addPivot, self.projectilePivotColor,
			self:worldToScreen(target.screenX, target.screenY))
	end
end

function KOF98:advanceRangeMarker(which)
	local r = self.drawRangeMarkers
	if r[which] == false then r[which] = 0
	elseif r[which] >= 3 then r[which] = false
	else r[which] = r[which] + 1 end
	return r[which]
end

function KOF98:renderState()
	KOF_Common.renderState(self)
	local ps = self.players
	for which = 1, 2 do
		local rangeIndex = self.drawRangeMarkers[which]
		local p, px = self.players[which], self.playerExtras[which]
		if rangeIndex and (p.yPivot.value == 0) then
			-- subtract 1 since the marker line must actually be "behind"
			-- the opponent's pivot axis to register a close-range attack
			local range = px.closeRanges[rangeIndex] - 1
			local active = range >= p.xDistance
			self:drawRangeMarker(p, range, active)
		end
	end
end

function KOF98:checkInputs()
	for i = 1, 2 do
		if hotkey.pressed(self.rangeMarkerHotkeys[i]) then
			local newState = self:advanceRangeMarker(i)
			if newState then
				print(string.format(
					"Showing close standing %s activation range for player %d.",
					self.buttonNames[newState + 1], i))
			else
				print(string.format(
					"Disabled close normal range marker for player %d.",
					i))
			end
		end
	end
	if hotkey.pressed(hotkey.VK_F6) then
		self.drawStaleThrowBoxes = not self.drawStaleThrowBoxes
		print("Toggled drawing \"stale\" throw boxes.")
	end
end

return KOF98
