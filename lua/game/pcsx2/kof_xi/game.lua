local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local PCSX2_Common = require("game.pcsx2.common")
local types = require("game.pcsx2.kof_xi.types")
local boxtypes = require("game.pcsx2.kof_xi.boxtypes")
local KOF_XI = PCSX2_Common:new()

KOF_XI.basicWidth = 640
KOF_XI.basicHeight = 448
KOF_XI.absoluteYOffset = 34
-- game-specific constants
KOF_XI.teamPtrs = { 0x008A9690, 0x008A98D8 }
KOF_XI.playerTablePtr = 0x008A26E0
KOF_XI.cameraPtr = 0x008A9660
KOF_XI.projCount = 16 -- per player (team)
KOF_XI.playersPerTeam = 3
KOF_XI.whoami = "KOF_XI"

function KOF_XI:extraInit(noExport)
	if not noExport then types:export(ffi) end
	self.boxtypes = boxtypes
	self.players = {}
	self.projectiles = {}
	self.projectilesActive = { {}, {} }
	self.teams = {}
	for i = 1, 2 do
		self.players[i] = ffi.new("playerMain")
		self.projectiles[i] = ffiutil.ntypes("projectile", self.projCount, 0)
		self.teams[i] = ffi.new("teamMain")
		local target = self.projectilesActive[i]
		for j = 0, self.projCount - 1 do
			target[j] = false
		end
	end

	self.playerTable = ffi.new("playerMainTable") -- shared by both players
	self.camera = ffi.new("camera")
	
	---[=[
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

function KOF_XI:captureWorldState()
	self:read(self.cameraPtr, self.camera)
	self:read(self.playerTablePtr, self.playerTable)
end

function KOF_XI:capturePlayerProjectiles(which)
	local projs = self.projectiles[which]
	local projsActive = self.projectilesActive[which]
	local projPtrs = self.teams[which].projectiles
	for i = 0, self.projCount - 1 do
		local target = projPtrs[i]
		projsActive[i] = false
		if target ~= 0 then
			target = self:readPtr(target + 0x10)
			if target ~= 0 then
				self:read(target, projs[i])
				projsActive[i] = true
			end
		end
	end
end

function KOF_XI:capturePlayerState(which)
	local team = self.teams[which]
	self:read(self.teamPtrs[which], team)
	-- mixed 0- and 1-based indexing cause WE'RE LIVIN' DANGEROUSLY
	self:read(self.playerTable.p[which-1][team.point], self.players[which])
	self:capturePlayerProjectiles(which)
end

function KOF_XI:captureState()
	self:captureWorldState()
	for i = 1, 2 do
		self:capturePlayerState(i)
	end

	---[=[
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
	playerX, playerY = self:worldToScreen(playerX, playerY)
	local centerX, centerY = hitbox.position.x * 2, hitbox.position.y * 2
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY - centerY -- positive offsets move upward
	local w, h = hitbox.width * 2, hitbox.height * 2
	return centerX, centerY, w, h
end

function KOF_XI:renderBox(player, hitbox, color, facing)
	if hitbox.width == 0 or hitbox.height == 0 then return end
	local cx, cy, w, h = self:deriveBoxPosition(player, hitbox, facing)
	self:box(cx - w, cy - h, cx + w, cy + h, color)
	self:pivot(cx, cy, 5, color)
end

local pboxes = {
	[0] = "attack",
	[4] = "grab",
}

function KOF_XI:drawCharacter(target, pivotColor, isProjectile, facing)
	pivotColor = (pivotColor or colors.WHITE)
	local rawX, rawY = target.position.x, target.position.y
	local pivotX, pivotY = self:worldToScreen(rawX, rawY)
	local boxstate = target.hitboxesActive
	local bt, boxtype = self.boxtypes, "dummy"
	if boxstate ~= 0 then
		--[=[
		if isProjectile then
			io.write("Projectile box IDs: { ")
		end
		--]=]
		for i = 0, 5 do
			if bit.band(boxstate, bit.lshift(1, i)) ~= 0 then
				local hitbox = target.hitboxes[i]
				--[=[
				if isProjectile then
					io.write(string.format("%d=0x%02X, ", i,
						bit.band(hitbox.boxID, 0xFF)))
				end
				--]=]
				--[=[
				if pboxes[i] ~= nil then
					print(string.format(
						"Active %s hitbox (ID: 0x%02X)",
						pboxes[i], bit.band(hitbox.boxID, 0xFF)))
				end
				--]=]
				if i == 4 then -- use fixed color for "throw" hitboxes
					boxtype = "throw"
				else
					boxtype = bt:typeForID(hitbox.boxID)
					if isProjectile then
						boxtype = bt:asProjectile(boxtype)
					end
				end

				--[=[
				if boxtype == "dummy" then
					print(string.format(
						"Unrecognized hitbox %d = 0x%02X",
						i, bit.band(hitbox.boxID, 0xFF)))
				end
				--]=]
				local boxcolor = bt:colorForType(boxtype)
				self:renderBox(target, hitbox, boxcolor, facing)
			end
		end
		if isProjectile then
			self:pivot(pivotX, pivotY, 20, pivotColor)
		end
	end
	-- always draw pivot cross for players (but not projectiles),
	-- and don't draw collision box for projectiles
	if not isProjectile then
		if bit.band(target.flags.collisionActive, 0x10) == 0 then
			self:renderBox(target, target.collisionBox, colors.WHITE, facing)
		end
		self:pivot(pivotX, pivotY, 20, pivotColor)
	end
end

function KOF_XI:drawPlayer(which)
	local active = self.players[which]
	local facing = self:facingMultiplier(active)
	--if which == 1 then self:drawCharacter(active) end
	self:drawCharacter(active, colors.WHITE, false, facing)
	-- draw active projectiles
	local projs = self.projectiles[which]
	local projsActive = self.projectilesActive[which]
	for i = 0, self.projCount - 1 do
		if projsActive[i] then
			local proj = projs[i]
			-- Some projectiles (e.g., K' qcf+P) have the facing always set
			-- to the same value, regardless of the player's actual facing.
			-- This can result in projectiles appearing behind the player
			-- when facing to the left, so we use the player's facing.
			self:drawCharacter(proj, colors.GREEN, true, facing)
		end
	end
end

function KOF_XI:renderState()
	for i = 1, 2 do self:drawPlayer(i) end
end

return KOF_XI
