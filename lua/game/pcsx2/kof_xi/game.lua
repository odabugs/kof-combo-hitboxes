local ffi = require("ffi")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")
local window = require("window")
local winprocess = require("winprocess")
--local hk = require("hotkey")
local color = require("render.colors")
local PCSX2_Common = require("game.pcsx2.common")
local KOF_XI = PCSX2_Common:new()

function KOF_XI:captureState()
	local address = 0x0081EBC4
	local buffer = ffi.new("coordPair")
	--[=[
	io.write("\n")
	--]=]
	while true do
		self:read(address, buffer)
		---[=[
		io.write(string.format("\rresult at 0x%08X is { x=0x%04X, y=0x%04X }        ",
		address + self.RAMbase, buffer.x, buffer.y))
		--]=]
		io.flush()
		coroutine.yield()
	end
end

function KOF_XI:renderState()
	self:setColor(color.rgb(255, 0, 0, 128))
	while true do
		self:rect(100, 120, 300, 250)
		coroutine.yield()
	end
end

return KOF_XI
