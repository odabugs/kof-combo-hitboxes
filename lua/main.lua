local ffi = require("ffi")
local winapi = require("winapi")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")
local detectgame = require("detectgame")
local window = require("window")
local winprocess = require("winprocess")

ffi.cdef[[
typedef struct { int16_t x; int16_t y; } coordPair;
VOID Sleep(DWORD ms);
]]
local C = ffi.C

-- if KOF XI is currently running in PCSX2,
-- open it and print the pivot coordinates of player 1's lead character
local x = detectgame.findSupportedGame()
if x then
	for k,v in pairs(x) do print(k,v) end

	local rectBuf = winutil.rectBufType()
	local r = rectBuf[0]
	window.getClientRect(x.gameHwnd, rectBuf)
	print(string.format("rectBuf = { %d, %d, %d, %d }",
		r.x, r.y, r.right, r.bottom))
	local pointBuf = winutil.pointBufType()
	local p = pointBuf[0]
	window.clientToScreen(x.gameHwnd, pointBuf)
	print(string.format("pointBuf = { %d, %d }", p.x, p.y))

	if x.module == "pcsx2.kof_xi" then
		local address = 0x2081EBC4
		local buffer = ffi.new("coordPair")
		local h = x.gameHandle
		while true do
			winprocess.read(h, buffer, ffi.cast("void*", address))
			print(string.format("result at 0x%08X is { x=0x%04X, y=0x%04X }",
				address, buffer.x, buffer.y))
			C.Sleep(30)
		end
	end
else
	print(x)
end
