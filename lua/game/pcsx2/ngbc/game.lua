local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.pcsx2.ngbc.types")
local boxtypes = require("game.pcsx2.kof_xi.boxtypes")
local KOF_XI = require("game.pcsx2.kof_xi.game")
-- extraInit() will get stuck and eventually stack overflow
-- if you don't set "parent" on the calling object beforehand
local NGBC = KOF_XI:new({ parent = KOF_XI, whoami = "NGBC" })

NGBC.basicWidth = 640
NGBC.basicHeight = 448
---[[
NGBC.absoluteYOffset = 22
NGBC.groundLevel = NGBC.basicHeight - NGBC.absoluteYOffset
--]]
-- game-specific constants
NGBC.teamPtrs = { 0x00439A00, 0x00439BB4 }
NGBC.playerTablePtr = 0x004006D0
--NGBC.activePlayerPtrs = { 0x018271E0, 0x018271E8 }
NGBC.activePlayerPtrs = { 0x00385DB0, 0x00385DF0 }
NGBC.cameraPtr = 0x004399E0
--NGBC.zoomPtr = 0x003857A0
NGBC.zoomPtr = 0x01FFE2B0
NGBC.projCount = 8
NGBC.playersPerTeam = 2

function NGBC:extraInit(noExport)
	if not noExport then types:export(ffi) end
	-- init XI, but using our typedefs instead
	self.parent.extraInit(self, true)
	self.zoomBuffer = ffi.new("zoom")
	self.zoom = 1.0 -- camera zoom factor
	self.visibleWidth = self.basicWidth
end

function NGBC:captureWorldState()
	self:read(self.cameraPtr, self.camera)
	--[=[
	local zb = self.zoomBuffer
	self:read(self.zoomPtr, zb)
	--self.zoom = 1.0 / zb.value
	self.zoom = zb.value
	--]=]
	---[=[
	local cam = self.camera
	self.visibleWidth = cam.rightEdge - cam.leftEdge
	local z = self.basicWidth / (cam.rightEdge - cam.leftEdge)
	--z = (z + 1) / 2
	self.zoom = z
	--]=]
	--[=[
	print(string.format("camX=%d, camY=%d",
		cam.leftEdge, cam.y))
	--]=]
end

function NGBC:capturePlayerState(which)
	local team = self.teams[which]
	self:read(self.teamPtrs[which], team)
	local activePtr = self.activePlayerPtrs[which]
	activePtr = self:readPtr(activePtr)
	local playerTable = self.playerTable.p[which-1]
	-- checking whether the retrieved player pointer actually exists
	-- in the player pointers table reduces player hitboxes "flickering"
	for i = 0, self.playersPerTeam - 1 do
		if activePtr == playerTable[i] then
			self:read(activePtr, self.players[which])
			break
		end
	end
	self:capturePlayerProjectiles(which)
end

function NGBC:worldToScreen(x, y)
	local cam = self.camera
	local camX, camY = cam.leftEdge, cam.y
	local z = self.zoom
	---[=[
	x = (x - camX) * z
	y = (y - 0xDA) * z
	y = y - (camY * z)
	y = self.basicHeight + y
	--]=]
	return x, y
end

-- translate a hitbox's position into coordinates suitable for drawing
function NGBC:deriveBoxPosition(player, hitbox, facing)
	local playerX, playerY = player.position.x, player.position.y
	local centerX, centerY = hitbox.position.x * 2, hitbox.position.y * 2
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY - centerY -- positive offsets move upward
	local w, h = hitbox.width * 2, hitbox.height * 2
	return centerX, centerY, w, h
end

function NGBC:renderBox(player, hitbox, color, facing)
	if hitbox.width == 0 or hitbox.height == 0 then return end
	local cx, cy, w, h = self:deriveBoxPosition(player, hitbox, facing)
	---[=[
	local x1, y1 = self:worldToScreen(cx - w, cy - h)
	local x2, y2 = self:worldToScreen(cx + w, cy + h)
	cx, cy = self:worldToScreen(cx, cy)
	--]=]
	--[=[
	cx, cy = self:worldToScreen(cx, cy)
	local z = self.zoom
	local wz, hz = w * z, h * z
	local x1, y1 = cx - wz, cy - hz
	local x2, y2 = cx + wz, cy + hz
	--]=]
	self:box(x1, y1, x2 - 1, y2 - 1, color)
	self:pivot(cx, cy, self.boxPivotSize, color)
end

return NGBC
