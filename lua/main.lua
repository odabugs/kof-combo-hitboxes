local ffi = require("ffi")
local types = require("winapi.types")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")
local ffiutil = require("ffiutil")
local detectgame = require("detectgame")
local window = require("window")
local winprocess = require("winprocess")
local hk = require("hotkey")

ffi.cdef[[
typedef struct { int16_t x; int16_t y; } coordPair;
typedef struct tagMSG {
	HWND   hwnd;
	UINT   message;
	WPARAM wParam;
	LPARAM lParam;
	DWORD  time;
	POINT  pt;
} MSG, *PMSG, *LPMSG;

BOOL PeekMessageW(
	LPMSG lpMsg,         // out
	HWND  hWnd,          // optional
	UINT  wMsgFilterMin,
	UINT  wMsgFilterMax,
	UINT  wRemoveMsg);
BOOL TranslateMessage(MSG *lpMsg);
LRESULT DispatchMessageW(MSG *lpMsg);
VOID Sleep(DWORD ms);
]]
local C = ffi.C

local PM_REMOVE = 0x01 -- used by PeekMessage()

function runLoop()
	local message = ffi.new("MSG[1]")
	while true do
		while C.PeekMessageW(message, NULL, 0, 0, PM_REMOVE) ~= 0 do
			C.TranslateMessage(message)
			C.DispatchMessageW(message)
		end
		coroutine.yield()
	end
end

-- if KOF XI is currently running in PCSX2,
-- open it and print the pivot coordinates of player 1's lead character
---[[
function main(hInstance)
	hInstance = ffi.cast("HINSTANCE", hInstance)
	local detected = detectgame.findSupportedGame(hInstance)
	if detected then
		for k,v in pairs(detected) do print(k,v) end

		local rectBuf = winutil.rectBufType()
		local r = rectBuf[0]
		window.getClientRect(detected.gameHwnd, rectBuf)
		print(string.format("rectBuf = { %d, %d, %d, %d }",
		r.x, r.y, r.right, r.bottom))
		local pointBuf = winutil.pointBufType()
		local p = pointBuf[0]
		window.clientToScreen(detected.gameHwnd, pointBuf)
		print(string.format("pointBuf = { %d, %d }", p.x, p.y))

		local c1 = coroutine.create(runLoop)
		local c2 = coroutine.create(function()
			if detected.module == "pcsx2.kof_xi" then
				local address = 0x2081EBC4
				local buffer = ffi.new("coordPair")
				local h = detected.gameHandle
				io.write("\n")
				while true do
					winprocess.read(h, buffer, ffi.cast("void*", address))
					io.write(string.format("\rresult at 0x%08X is { x=0x%04X, y=0x%04X }        ",
					address, buffer.x, buffer.y))
					io.flush()
					coroutine.yield()
				end
			end
		end)

		local running = true
		while running do
			coroutine.resume(c1)
			coroutine.resume(c2)
			if hk.down(hk.VK_Q) and window.isForeground(window.console()) then
				winutil.flushConsoleInput()
				io.write("\n")
				running = false
			end
			C.Sleep(30)
		end
	else
		print(detected)
	end
end
--]]

--[[
function main(hInstance)
	return nil
end
--]]
