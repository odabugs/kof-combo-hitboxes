local ffi = require("ffi")
local winapi = require("winapi")
local winerror = require("winerror")
local luautil = require("luautil")
local detectgame = require("detectgame")
local winprocess = require("winprocess")

-- if KOF XI is currently running in PCSX2,
-- open it and print the pivot coordinates of player 1's lead character
local x = detectgame.findSupportedGame()
if x and x.module == "pcsx2.kof_xi" then
	for k,v in pairs(x) do print(k,v) end
	local address = 0x2081EBC4
	local buffer = ffi.new("coordPair")
	local h = x.processHandle
	winprocess.read(h, buffer, ffi.cast("void*", address))
	print(string.format("result at 0x%08X is { x=0x%04X, y=0x%04X }", address, buffer.x, buffer.y))
else
	print(x)
end
