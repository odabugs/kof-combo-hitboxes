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
local KOF_Common = require("game.kof_common")
local KOF98 = KOF_Common:new({ whoami = "KOF98" })

KOF98.configSection = "kof98umfe"
KOF98.basicWidth = 320
KOF98.basicHeight = 224
KOF98.aspectMode = "pillarbox"
KOF98.absoluteYOffset = 16
KOF98.pivotSize = 5
KOF98.boxPivotSize = 2
KOF98.drawStaleThrowBoxes = false
KOF98.drawThrowableBoxes = true
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
KOF98.gauges = { {}, {} }
KOF98.drawGauges = true -- "false" here overrides the two values below
KOF98.drawStunGauge = true -- also applies to the stun recovery gauge
KOF98.drawGuardGauge = true
KOF98.stunGaugeColor = colors.rgb(0xFF, 0xB0, 0x90)
KOF98.stunRecoveryGaugeColor = colors.RED
KOF98.guardGaugeColor = colors.rgb(0xA0, 0xC0, 0xE0)

KOF98.toggleHotkeys = {
	{ hotkey.VK_F3, "drawBoxFills", "drawing hitbox fills" },
	{ hotkey.VK_F4, "drawBoxPivot", "drawing hitbox center axes" },
	{ hotkey.VK_F5, "drawThrowableBoxes", "drawing \"throwable\" boxes" },
	{ hotkey.VK_F6, "drawStaleThrowBoxes", "drawing \"stale\" throw boxes" },
	{ hotkey.VK_F7, "drawGauges", "drawing gauge overlays" },
}

KOF98.startupMessage = [[
Hotkeys available for this game:
F1 - Toggle close normal range marker (player 1)
F2 - Toggle close normal range marker (player 2)
F3 - Toggle drawing hitbox fills
F4 - Toggle drawing hitbox center axes
F5 - Toggle drawing "throwable"-type boxes
F6 - Toggle drawing "stale" throw boxes
F7 - Toggle gauge overlays]]

function KOF98:extraInit(noExport)
	if not noExport then
		types:export(ffi)
	end
	self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
		self.boxSlotConstructor, self.boxtypes)
	self.camera = ffi.new("camera")
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", self.projectilesListInfo.count + 2,
		self.pivotSlotConstructor)
	self.projBuffer = ffi.new("projectile")

	if self.startupMessage then print(self.startupMessage) end
	for which = 1, 2 do
		self:printRangeMarkerState(which, true)
	end
	self:setupGauges()
end

function KOF98:setupGauges()
	local g, a = self.gauges, self.gaugeFillAlpha
	g[1].stun = self:Gauge({
		x = 10, y = 51, width = 130, height = 5, direction = "left",
		fillColor = self.stunGaugeColor,
		minValue = 0, maxValue = 0x77,
	})
	-- stun and stun recovery gauges overlap (since we never draw both)
	g[1].stunRecovery = self:Gauge(luautil.extend({}, g[1].stun, {
		fillColor = self.stunRecoveryGaugeColor,
		maxValue = 0xF0,
	}))
	-- guard gauge appears right below the stun/stun recovery gauge
	g[1].guard = self:Gauge(luautil.extend({}, g[1].stun, {
		fillColor = self.guardGaugeColor,
		maxValue = 0x77, y = (g[1].stun.y + g[1].stun.height),
	}))
	-- copy the "mirror image" of player 1's gauges to the player 2 side
	for key, gauge in pairs(g[1]) do
		g[2][key] = self:Gauge(luautil.extend({}, gauge, {
			x = gauge.x + 169, direction = "right",
		}))
	end
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
	local minAddress, maxAddress = pointer
	for i = 1, info.count do
		maxAddress = pointer
		self:read(pointer, current)
		if current.basicStatus > 0 then
			self:captureEntity(current, true)
		end
		pointer = pointer + step
	end
	--print(string.format("Read from range 0x%08X to 0x%08X", minAddress, maxAddress))
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
	if not self.drawThrowableBoxes then return false
	elseif bit.band(player.statusFlags2nd[3], 0x20) ~= 0 then return false
	elseif bit.band(player.statusFlags[2], 0x03) == 1 then return false
	elseif player.throwableStatus ~= 0 then return false
	else return bit.band(hitbox.boxID, 0x80) == 0 end
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
			if boxtype == "dummy" then
				--print(string.format("Dummy box at 0x%02X", hitbox.boxID))
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
	self:printRangeMarkerState(which)
end

function KOF98:printRangeMarkerState(which, suppressIfDisabled)
	local showing = self.drawRangeMarkers[which]
	if showing then
		io.write(
			"Showing close standing ", self.buttonNames[showing + 1],
			" activation range for player ", which, ".\n")
	elseif not suppressIfDisabled then
		io.write(
			"Disabled close normal range marker for player ", which, ".\n")
	end
end

function KOF98:shouldShowStunRecoveryGauge(player)
	local stunMeterFrozen = bit.band(player.statusFlags2nd[0], 0x01) ~= 0
	local dizzyState = bit.band(player.statusFlags2nd[3], 0x10) ~= 0
	if not (dizzyState and stunMeterFrozen) then return false
	else return (player.hitstun > 0 and player.stunRecovery > 0) end
end

function KOF98:renderState()
	KOF_Common.renderState(self)
	local players = self.players
	local xDistance = math.abs(players[1].screenX - players[2].screenX)
	for which = 1, 2 do
		local p, px = players[which], self.playerExtras[which]
		local rangeIndex = self.drawRangeMarkers[which]
		if rangeIndex and (p.yPivot.value == 0) then
			-- subtract 1 since the marker line must actually be "behind"
			-- the opponent's pivot axis to register a close-range attack
			local range = px.closeRanges[rangeIndex] - 1
			self:drawRangeMarker(p, range, range >= xDistance)
		end

		if self.drawGauges then
			local gauges = self.gauges[which]
			if self.drawStunGauge then
				if self:shouldShowStunRecoveryGauge(p) then
					gauges.stunRecovery:render(p.stunRecovery)
				else
					gauges.stun:render(p.stunGauge)
				end
			end
			if self.drawGuardGauge then
				gauges.guard:render(p.guardGauge)
			end
		end
	end
end

function KOF98:toggleState(target, consoleLine)
	local v = not self[target]
	io.write((v and "Enabled ") or "Disabled ", consoleLine, ".\n")
	self[target] = v
end

function KOF98:checkInputs()
	for i = 1, 2 do
		if hotkey.pressed(self.rangeMarkerHotkeys[i]) then
			self:advanceRangeMarker(i)
		end
	end
	for _, toggleKey in ipairs(self.toggleHotkeys) do
		if hotkey.pressed(toggleKey[1]) then
			self:toggleState(toggleKey[2], toggleKey[3])
		end
	end
end

return KOF98
