local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.pcsx2.cvs2.types")
local boxtypes = require("game.boxtypes_common")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local PCSX2_Common = require("game.pcsx2.common")
local Game_Common_Extra = require("game.common_extra")
local CVS2 = PCSX2_Common:new({ whoami = "CVS2" })
luautil.extend(CVS2, Game_Common_Extra)
local floor, lshift = math.floor, bit.lshift

CVS2.configSection = "cvs2"
CVS2.basicWidth, CVS2.basicHeight = 358, 224
CVS2.absoluteYOffset = 20 -- TODO
CVS2.camXOffset = 371 -- magic number for proper pivot axis alignment
CVS2.pivotSize = 5
CVS2.boxPivotSize = 2
CVS2.boxesPerLayer = 20
CVS2.boxtypes = boxtypes
CVS2.revisions = {
	["NTSC-U"] = {
		playerPtrs = { 0x00481780, 0x00481D50 },
		cameraPtr = 0x0049CFA0,
		projectilesListInfo = {
			start = 0x00482320,
			step = 0x180,
			count = 32,
		},
	},
}

function CVS2:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self:importRevisionSpecificOptions(true)
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
	end
	self.players = ffiutil.ntypes("player", 2)
	self.boxBuf = ffi.new("hitbox")
	self.boxOffsets = ffiutil.ntypes("hitboxOffsets", 3)
	self.byteBuf = ffi.new("byteBuffer")
	self.boxTables = {}
	for i = 1, 3 do
		self.boxTables[i] = ffiutil.ntypes("hitboxTable", 5, 0)
	end
	self.camera = ffi.new("camera")
	local projCount = self.projectilesListInfo.count
	self.projectiles = ffiutil.ntypes("projectile", projCount, 0)
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", (projCount + 2), self.pivotSlotConstructor)
end

function CVS2:captureWorldState()
	self:read(self.cameraPtr, self.camera)
end

function CVS2.isActive(entity)
	return (entity.activeState1 > 0) and (entity.activeState2 == 0x01)
end

function CVS2:captureEntity(target, which, isProjectile)
	if not self.isActive(target) then return end
	local boxBuf, byteBuf = self.boxBuf, self.byteBuf
	local boxset, boxAdder = self.boxset, self.addBox
	local boxOffsets = self.boxOffsets[which]
	local boxTables = self.boxTables[which]
	local facing = self.facingMultiplier(target)
	local boxType, boxesDrawn = "dummy", 0
	self:read(target.boxOffsets, boxOffsets)
	-- vulnerable and collision boxes
	for i = 0, 3 do
		local boxAddr = target.hitboxPtrs[i] + lshift(boxOffsets.offsets[i], 3)
		boxType = ((i == 3) and "collision") or "vulnerable"
		if isProjectile then boxType = boxtypes:asProjectile(boxType) end
		self:read(boxAddr, boxBuf)
		if boxset:add(boxType, boxAdder, self, self:deriveBoxPosition(
			target, boxBuf, facing)) then
			boxesDrawn = boxesDrawn + 1
		end
	end
	-- attack box
	local attackBoxOffset = target.animationPtr + 0x09
	self:read(attackBoxOffset, byteBuf)
	if byteBuf.uvalue ~= 0 then
		local boxAddr = target.attackBoxPtr + (byteBuf.uvalue * 0x20)
		boxType = "attack"
		if isProjectile then boxType = boxtypes:asProjectile(boxType) end
		self:read(boxAddr, boxBuf)
		if boxset:add(boxType, boxAdder, self, self:deriveBoxPosition(
			target, boxBuf, facing)) then
			boxesDrawn = boxesDrawn + 1
		end
	end
	-- pivot axis
	-- only draw pivot cross for projectiles if at least one box was drawn
	if (not isProjectile) or boxesDrawn > 0 then
		local xPos, yPos = target.xPivot.whole, target.yPivot.whole
		local pivotColor = self.pivotColor
		if isProjectile then pivotColor = self.projectilePivotColor end
		self.pivots:add(self.addPivot, pivotColor,
			self:worldToScreen(xPos, yPos))
	end
end

function CVS2:capturePlayerState(which)
	local player = self.players[which]
	self:read(self.playerPtrs[which], player)
	self:captureEntity(player, which, false)
end

function CVS2.facingMultiplier(player)
	return ((player.facing == 0) and 1) or -1
end

function CVS2:deriveBoxPosition(player, hitbox, facing)
	local px, py = player.xPivot.whole, player.yPivot.whole
	local cx, cy = hitbox.xCenter, hitbox.yCenter
	local w,  h  = hitbox.xRadius, hitbox.yRadius
	cx = px + (cx * facing)
	cy = py + cy
	return cx, cy, w, h
end

function CVS2:captureState()
	self.boxset:reset()
	self.pivots:reset()
	self:captureWorldState()
	for i = 1, 2 do self:capturePlayerState(i) end
	local projectiles, projInfo = self.projectiles, self.projectilesListInfo
	local addr, step = projInfo.start, projInfo.step
	for i = 0, projInfo.count - 1 do
		local proj = projectiles[i]
		self:read(addr, proj)
		self:captureEntity(proj, 3, true)
		addr = addr + step
	end
end

function CVS2:worldToScreen(x, y)
	local cam = self.camera
	local camX, camY = cam.x, cam.y
	local ground, xOffset = self.basicHeight, self.camXOffset
	x = x + xOffset - camX
	y = ground - y + (camY / 2)
	return x, floor(y)
end

-- "renderFn" passed as parameter to BoxList:render()
function CVS2.drawPivot(pivot, parent, pivotSize)
	parent:pivot(pivot.x, pivot.y, pivotSize, pivot.color)
	return 1
end

-- "renderFn" passed as parameter to BoxSet:render()
function CVS2.drawBox(hitbox, parent, drawBoxPivot, pivotSize, drawFill)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	local edge, fill = colorPair[1], (drawFill and colorPair[2]) or colors.CLEAR
	parent:box(x1, y1, x2, y2, edge, fill)
	if drawBoxPivot then
		parent:pivot(cx, cy, parent.boxPivotSize, edge)
	end
	return 1
end

function CVS2:renderState()
	self.boxset:render(self.drawBox, self,
		self.drawBoxPivot, self.boxPivotSize, self.drawBoxFills)
	if self.drawPlayerPivot then
		self.pivots:render(self.drawPivot, self, self.pivotSize)
	end
end

return CVS2
