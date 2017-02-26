local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.pcsx2.kof_xi.types")
local boxtypes = require("game.pcsx2.kof_xi.boxtypes")
local BoxSet = require("game.boxset")
local BoxList = require("game.boxlist")
local PCSX2_Common = require("game.pcsx2.common")
local KOF_XI = PCSX2_Common:new({ whoami = "KOF_XI" })

KOF_XI.basicWidth = 640
KOF_XI.basicHeight = 448
KOF_XI.absoluteYOffset = 35
KOF_XI.pivotSize = 20
KOF_XI.boxPivotSize = 5
KOF_XI.boxesPerLayer = 20
-- game-specific constants
KOF_XI.projCount = 16 -- per player (team)
KOF_XI.playersPerTeam = 3
KOF_XI.revisions = {
	["NTSC-J"] = {
		teamPtrs = { 0x009BDB50, 0x009BDD98 },
		playerTablePtr = 0x009B6BC0,
		cameraPtr = 0x009BDB20,
	},
	["NTSC-U"] = {
		teamPtrs = { 0x008A9690, 0x008A98D8 },
		playerTablePtr = 0x008A26E0,
		cameraPtr = 0x008A9660,
	},
	["PAL"] = {
		teamPtrs = { 0x008EF810, 0x008EFA58 },
		playerTablePtr = 0x008E8860,
		cameraPtr = 0x008EF7E0,
	},
}

function KOF_XI:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self:importRevisionSpecificOptions(true)
		self.boxtypes = boxtypes
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
	end
	self.players = ffiutil.ntypes("player", 2, 1)
	self.teams = ffiutil.ntypes("team", 2, 1)
	self.camera = ffi.new("camera")
	self.projBuffer = ffi.new("projectile")
	self.pivots = BoxList:new( -- dual purposing BoxList to draw pivots
		"pivots", (self.projCount + 1) * 2, self.pivotSlotConstructor)
	
	-- we use the player table for XI, but not for NGBC
	if self.playerTablePtr ~= nil then
		self.playerTable = ffi.new("playerTable") -- shared by both players
		--[=[
		self:read(self.playerTablePtr, self.playerTable)
		print()
		for i = 1, 2 do
			for j = 0, self.playersPerTeam - 1 do
				print(string.format(
					"Player %d, character %d pointer: 0x%08X",
					i, j, self.playerTable.p[i-1][j]))
			end
		end
		print()
		--]=]
	end
end

-- Slot constructor function passed to BoxSet:new();
-- this function MUST return a new table instance with every call
function KOF_XI.boxSlotConstructor(i, slot, boxtypes)
	return {
		centerX = 0, centerY = 0, left = 0, right = 0, top = 0, bottom = 0,
		color = boxtypes:colorForType(slot),
	}
end

function KOF_XI.pivotSlotConstructor()
	return { x = 0, y = 0, color = colors.WHITE }
end

function KOF_XI:captureWorldState()
	self:read(self.cameraPtr, self.camera)
	self:read(self.playerTablePtr, self.playerTable)
end

function KOF_XI:captureEntity(target, facing, isProjectile)
	local boxset, boxAdder = self.boxset, self.addBox
	local bt, boxtype = self.boxtypes, "dummy"
	local boxstate, i, boxesDrawn = target.hitboxesActive, 0, 0
	local hitbox
	while boxstate ~= 0 and i <= 5 do
		if bit.band(boxstate, 1) ~= 0 then
			hitbox = target.hitboxes[i]
			if i == 4 then -- use fixed color for "throw" hitboxes
				boxtype = "throw"
			else
				boxtype = bt:typeForID(hitbox.boxID)
				if isProjectile then
					boxtype = bt:asProjectile(boxtype)
				end
			end
			boxset:add(boxtype, boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
			boxesDrawn = boxesDrawn + 1
		end
		boxstate = bit.rshift(boxstate, 1)
		i = i + 1
	end
	-- always draw pivot cross for players,
	-- and don't draw collision box for projectiles
	if not isProjectile then
		if bit.band(target.flags.collisionActive, 0x10) == 0 then
			hitbox = target.collisionBox
			boxset:add("collision", boxAdder, self, self:deriveBoxPosition(
				target, hitbox, facing))
		end
		self.pivots:add(self.addPivot, colors.WHITE, self:worldToScreen(
			target.position.x, target.position.y))
	-- only draw pivot cross for projectiles if at least one box was drawn
	elseif boxesDrawn > 0 then
		self.pivots:add(self.addPivot, colors.GREEN, self:worldToScreen(
			target.position.x, target.position.y))
	end
end

function KOF_XI:capturePlayerProjectiles(which, facing)
	local projBuffer = self.projBuffer
	local projPtrs = self.teams[which].projectiles
	for i = 0, self.projCount - 1 do
		local target = projPtrs[i]
		if target ~= 0 then
			target = self:readPtr(target + 0x10)
			if target ~= 0 then
				self:read(target, projBuffer)
				self:captureEntity(projBuffer, facing, true)
			end
		end
	end
end

function KOF_XI:capturePlayerState(which)
	local team, player = self.teams[which], self.players[which]
	self:read(self.teamPtrs[which], team)
	-- mixed 0- and 1-based indexing cause WE'RE LIVIN' DANGEROUSLY
	self:read(self.playerTable.p[which-1][team.point], player)
	local facing = self:facingMultiplier(player)
	self:captureEntity(player, facing, false)
	self:capturePlayerProjectiles(which, facing)
end

-- "addFn" passed as parameter to BoxSet:add();
-- this function is responsible for actually writing the new box set entry
function KOF_XI.addBox(target, parent, cx, cy, w, h)
	if w <= 0 or h <= 0 then return false end
	target.centerX, target.centerY = parent:worldToScreen(cx, cy)
	target.left,  target.top    = parent:worldToScreen(cx - w, cy - h)
	target.right, target.bottom = parent:worldToScreen(cx + w - 1, cy + h - 1)
	return true
end

function KOF_XI.addPivot(target, color, x, y)
	target.color, target.x, target.y = color, x, y
	return true
end

function KOF_XI:captureState()
	self.boxset:reset()
	self.pivots:reset()
	self:captureWorldState()
	for i = 1, 2 do
		self:capturePlayerState(i)
	end

	--[=[
	local n = 1
	local activeIndex = self.teams[n].point
	local active = self.players[n]
	io.write(string.format(
		"\rP%d active character's (%d) position is { x=0x%04X, y=0x%04X, pointer=0x%08X }        ",
		n, activeIndex, active.position.x, active.position.y,
		self.playerTable.p[n-1][activeIndex] + self.RAMbase))
	io.flush()
	--]=]
end

-- return -1 if player is facing left, or +1 if player is facing right
function KOF_XI:facingMultiplier(player)
	return ((player.facing == 0) and -1) or 1
end

function KOF_XI:worldToScreen(x, y)
	local cam = self.camera.position
	return x - cam.x, y - cam.y
end

-- translate a hitbox's position into coordinates suitable for drawing
function KOF_XI:deriveBoxPosition(player, hitbox, facing)
	local playerX, playerY = player.position.x, player.position.y
	local centerX, centerY = hitbox.position.x * 2, hitbox.position.y * 2
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY - centerY -- positive offsets move upward
	local w, h = hitbox.width * 2, hitbox.height * 2
	return centerX, centerY, w, h
end

-- "renderFn" passed as parameter to BoxSet:render()
function KOF_XI.drawBox(hitbox, parent)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local color = hitbox.color
	parent:box(x1, y1, x2, y2, color)
	parent:pivot(cx, cy, parent.boxPivotSize, color)
	return 1
end

function KOF_XI.drawPivot(pivot, parent)
	parent:pivot(pivot.x, pivot.y, parent.pivotSize, pivot.color)
	return 1
end

function KOF_XI:renderState()
	self.boxset:render(self.drawBox, self)
	self.pivots:render(self.drawPivot, self)
end

return KOF_XI
