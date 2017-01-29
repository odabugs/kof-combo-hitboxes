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
local BoxSet = require("game.boxset")
local KOF_XI = require("game.pcsx2.kof_xi.game")
-- extraInit() will get stuck and eventually stack overflow
-- if you don't set "parent" on the table parameter beforehand
local NGBC = KOF_XI:new({ parent = KOF_XI, whoami = "NGBC" })

NGBC.basicWidth = 640
NGBC.basicHeight = 448
NGBC.absoluteYOffset = 22
NGBC.groundLevel = NGBC.basicHeight - NGBC.absoluteYOffset
-- game-specific constants
NGBC.projCount = 8
NGBC.playersPerTeam = 2
NGBC.revisions = {
	["NTSC-J"] = {
		teamPtrs = { 0x009DDFF0, 0x009DE1A4 },
		activePlayerPtrs = { 0x009DD8C0, 0x009DD940 },
		cameraPtr = 0x009DDFD0,
	},
	["NTSC-U"] = {
		teamPtrs = { 0x00439A00, 0x00439BB4 },
		--activePlayerPtrs = { 0x018271E0, 0x018271E8 },
		activePlayerPtrs = { 0x00385DB0, 0x00385DF0 },
		cameraPtr = 0x004399E0,
		--zoomPtr = 0x003857A0,
		--zoomPtr = 0x01FFE2B0,
	},
	["PAL"] = {
		teamPtrs = { 0x003CA480, 0x003CA634 },
		activePlayerPtrs = { 0x00318F28, 0x00318F68 },
		cameraPtr = 0x003CA460,
	},
}

function NGBC:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self:importRevisionSpecificOptions(true)
		self.boxtypes = boxtypes
		self.boxset = BoxSet:new(
			self.boxtypes.order, 20, self.boxsetSlotConstructor,
			self.boxtypes)
	end
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
	local team, player = self.teams[which], self.players[which]
	self:read(self.teamPtrs[which], team)
	local activePtr = self.activePlayerPtrs[which]
	activePtr = self:readPtr(activePtr)
	self:read(activePtr, player)
	local facing = self:facingMultiplier(player)
	self:captureEntity(player, facing, false)
	self:capturePlayerProjectiles(which, facing)
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

return NGBC
