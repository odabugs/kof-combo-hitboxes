local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local types = require("game.pcsx2.samsho6.types")
--local boxtypes = require("game.pcsx2.samsho6.boxtypes")
--local BoxSet = require("game.boxset")
local PCSX2_Common = require("game.pcsx2.common")
local SamSho6 = PCSX2_Common:new({ whoami = "SamSho6" })

SamSho6.basicWidth = 640
SamSho6.basicHeight = 448
SamSho6.absoluteYOffset = 20 -- TODO
-- game-specific constants
SamSho6.revisions = {
	["NTSC-U"] = {
		playerPtrs = { 0x01E55FC0, 0x01E560F8 },
		playerExtraPtrs = { 0x01E54270, 0x01E5519C },
		cameraPtr = 0x01E53CB4,
	},
	-- TODO: NTSC-J, PAL versions
}

function SamSho6:extraInit(noExport)
	if not noExport then
		types:export(ffi)
		self:importRevisionSpecificOptions(true)
		--[=[
		self.boxtypes = boxtypes
		self.boxset = BoxSet:new(self.boxtypes.order, self.boxesPerLayer,
			self.boxSlotConstructor, self.boxtypes)
		--]=]
	end
	self.players = ffiutil.ntypes("player", 2, 1)
	self.playerExtras = ffiutil.ntypes("playerExtra", 2, 1)
	self.camera = ffi.new("camera")
	self.zoom = 1.0 -- camera zoom factor
	self.leftEdge = 0.0 -- left edge of visible screen area
	self.bottomEdge = 0.0 -- bottom edge of visible screen area
end

function SamSho6:captureState()
	local cam = self.camera
	self:read(self.cameraPtr, cam)
	self.zoom = (320.0 / cam.width)
	self.leftEdge = cam.centerX - (cam.width / 2)
	self.bottomEdge = cam.y - 120.0

	for i = 1, 2 do
		self:capturePlayerState(i)
	end
end

function SamSho6:capturePlayerState(which)
	self:read(self.playerPtrs[which], self.players[which])
	self:read(self.playerExtraPtrs[which], self.playerExtras[which])
	--[=[
	if which == 1 then
		local p = self.players[which]
		print(string.format("Player %d position is (%f, %f)",
			which, p.position.x, p.position.y))
	end
	--]=]
end

function SamSho6:worldToScreen(x, y)
	local cam = self.camera
	local z, l, b = self.zoom, self.leftEdge, self.bottomEdge
	x = ((x - l) * 2 * z)
	y = self.basicHeight - ((y - b) * 2 * z)
	--print(string.format("%f, %f", x, y))
	return x, y
end

function SamSho6:renderState()
	local ps, p = self.players
	for i = 1, 2 do
		p = ps[i]
		self:pivot(self:worldToScreen(p.position.x, p.position.y))
	end
end

return SamSho6
