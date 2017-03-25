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
local KOF_Common = require("game.kof_common")
local KOF_XI = PCSX2_Common:new({ whoami = "KOF_XI" })
luautil.extend(KOF_XI, KOF_Common)

KOF_XI.configSection = "kof_xi"
KOF_XI.basicWidth = 640
KOF_XI.basicHeight = 448
KOF_XI.absoluteYOffset = 35
KOF_XI.boxesPerLayer = 20
-- game-specific constants
KOF_XI.boxtypes = boxtypes
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

function KOF_XI:captureWorldState()
	self:read(self.cameraPtr, self.camera)
	self:read(self.playerTablePtr, self.playerTable)
end

function KOF_XI:captureEntity(target, facing, isProjectile)
	local boxset, boxAdder = self.boxset, self.addBox
	local bt, boxtype = self.boxtypes, "dummy"
	local boxstate, i, boxesDrawn = target.hitboxesActive, 0, 0
	local haveDrawnAttackBox, hitbox = false, nil
	while boxstate ~= 0 and i <= 5 do
		if bit.band(boxstate, 1) ~= 0 then
			hitbox = target.hitboxes[i]
			if i == 4 then -- "throw" hitboxes always occupy this slot
				boxtype = "throw"
			else
				boxtype = bt:typeForID(hitbox.boxID)
				if isProjectile then
					boxtype = bt:asProjectile(boxtype)
				end
			end
			-- special case handler to hide the spurious "throw" hitbox
			-- on the first hit of Robert's close standing D
			if not (boxtype == "throw" and haveDrawnAttackBox) then
				if boxtype == "attack" then
					haveDrawnAttackBox = true
				end
				boxset:add(boxtype, boxAdder, self, self:deriveBoxPosition(
					target, hitbox, facing))
			end
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
		self.pivots:add(self.addPivot, self.pivotColor, self:worldToScreen(
			target.position.x, target.position.y))
	-- only draw pivot cross for projectiles if at least one box was drawn
	elseif boxesDrawn > 0 then
		self.pivots:add(self.addPivot, self.projectilePivotColor,
			self:worldToScreen(target.position.x, target.position.y))
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

function KOF_XI:captureState()
	self.boxset:reset()
	self.pivots:reset()
	self:captureWorldState()
	for i = 1, 2 do
		self:capturePlayerState(i)
	end

	--[=[ -- testing code for determining activation range of close normals
	local p, t = self.players, self.teams
	local distance = math.abs(p[1].position.x - p[2].position.x)
	io.write(string.format("\r%04X", distance), "\t", t[1].point, "\t", t[2].point)
	--]=]
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

function KOF_XI:getPlayerPosition(player)
	return player.position.x, player.position.y
end

-- translate a hitbox's position into coordinates suitable for drawing
function KOF_XI:deriveBoxPosition(player, hitbox, facing)
	local playerX, playerY = self:getPlayerPosition(player)
	local centerX, centerY = hitbox.position.x * 2, hitbox.position.y * 2
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY - centerY -- positive offsets move upward
	local w, h = hitbox.width * 2, hitbox.height * 2
	return centerX, centerY, w, h
end

return KOF_XI
