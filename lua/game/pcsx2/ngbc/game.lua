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

NGBC.configSection = "ngbc"
NGBC.basicWidth = 640
NGBC.basicHeight = 448
NGBC.absoluteYOffset = 22
--NGBC.absoluteYOffset = 0
NGBC.groundLevel = NGBC.basicHeight - NGBC.absoluteYOffset
-- game-specific constants
NGBC.boxtypes = boxtypes
NGBC.projCount = 8
NGBC.playersPerTeam = 2
NGBC.revisions = {
	["NTSC-J"] = {
		teamPtrs = { 0x009DDFF0, 0x009DE1A4 },
		activePlayerPtrs = { 0x009DD9A0, 0x009DD9A8 },
		extraEntitiesPtr = 0x009DD9B0,
		--cameraPtr = 0x009DDFD0,
		cameraPtr = 0x009DDF62,
		zoomPtr = 0x00347240,
	},
	["NTSC-U"] = {
		teamPtrs = { 0x00439A00, 0x00439BB4 },
		activePlayerPtrs = { 0x018271E0, 0x018271E8 },
		extraEntitiesPtr = 0x018271F0,
		--cameraPtr = 0x004399E0,
		cameraPtr = 0x00439972,
		--zoomPtr = 0x003857A0,
		zoomPtr = 0x01FFE2B0,
		--zoomPtr = 0x0184E940,
	},
	["PAL"] = {
		teamPtrs = { 0x003CA480, 0x003CA634 },
		activePlayerPtrs = { 0x017B7C60, 0x017B7C68 },
		extraEntitiesPtr = 0x017B7C70,
		--cameraPtr = 0x003CA460,
		cameraPtr = 0x003CA3F2,
	},
}

function NGBC:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self:importRevisionSpecificOptions(true)
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
	end
	-- init XI, but using NGBC's typedefs instead
	self.parent.extraInit(self, true)
	self.zoomBuffer = ffi.new("zoom")
	self.zoom, self.xZoom, self.yZoom = 1, 1, 1 -- camera zoom factor
	self.extraEntities = ffi.new("extraEntities")
	self.playerBufs = ffiutil.ntypes("player", 6, 0)
	self.visibleWidth = self.basicWidth
	self.visibleHeight = self.basicHeight
	self.screenCenterX = self.basicWidth / 2
	self.screenCenterY = self.basicHeight / 2
end

function NGBC:worldToScreen(x, y)
	local cam = self.camera
	local camX, camY = cam.leftEdge, cam.centerY
	local w, h = self.visibleWidth, self.visibleHeight
	local bw, bh = self.basicWidth, self.basicHeight
	local z, xz, yz = self.zoom, self.xZoom, self.yZoom
	local scx, wcx = self.screenCenterX, self.worldCenterX
	x = (x - camX) * xz
	--[=[
	local topY = cam.topEdge
	y = (y + camY) * z
	y = bh - 0xDA + y
	--]=]
	---[=[
	y = (y - 0xDA - camY) * yz
	y = bh + y
	--]=]
	return x, y
end

function NGBC:captureWorldState()
	self:read(self.cameraPtr, self.camera)
	local cam = self.camera
	local left, right = cam.leftEdge, cam.rightEdge
	local top, bottom = cam.topEdge, cam.bottomEdge
	self.visibleWidth = right - left
	self.visibleHeight = top - bottom
	local cx = math.floor((left + right) / 2)
	self.worldCenterX = cx
	--[=[
	local zb = self.zoomBuffer
	self:read(self.zoomPtr, zb)
	local z = zb.value
	--]=]
	---[=[
	self.xZoom = self.basicWidth / self.visibleWidth
	self.yZoom = self.basicHeight / self.visibleHeight
	--local z = self.xZoom
	--z = (z + 1) / 2
	--]=]
	-- Zoom value occasionally contains NaN which can cause a viewer crash.
	-- This test relies on the property that NaN is not equal to itself.
	if z == z then self.zoom = z end
	--print(left, right, cx, cam.centerY, z)
	--]=]
	--[=[
	print(string.format("camX=%d, camY=%d",
		cam.leftEdge, cam.centerY))
	--]=]
	local tbl, playerBuf, target = self.extraEntities
	self:read(self.extraEntitiesPtr, tbl)
	-- capture "extra" entities controlled by players w/certain characters
	-- (e.g., Nakoruru's pet eagle, Goodman's "ghost" assistant)
	for i = 0, 3 do
		if bit.band(tbl.values[i].flags, 0x00008000) ~= 0 then
			target = tbl.values[i].target
			if target ~= 0 then
				playerBuf = self.playerBufs[i]
				self:read(target, playerBuf)
				-- TODO: Is the "facing" value ever an issue here?
				self:captureEntity(playerBuf, 0, true)
			end
		end
	end
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
	return activePtr
end

return NGBC
