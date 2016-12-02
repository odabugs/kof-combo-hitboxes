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
local colors = require("render.colors")

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

do
	local message = ffi.new("MSG[1]")
	function messagePump()
		while C.PeekMessageW(message, NULL, 0, 0, PM_REMOVE) ~= 0 do
			C.TranslateMessage(message)
			C.DispatchMessageW(message)
		end
	end
end

-- if KOF XI is currently running in PCSX2,
-- open it and print the pivot coordinates of player 1's lead character
---[[
function main(hInstance, dxLib)
	if type(dxLib) == "table" then
		for k,v in pairs(dxLib) do print(k,v) end
		_G.directx = dxLib
	end
	hInstance = ffi.cast("HINSTANCE", hInstance)
	local detected = detectgame.findSupportedGame(hInstance)
	if detected then
		for k,v in pairs(detected) do print(k,v) end

		local game = detectgame.moduleForGame(detected)
		game:setupOverlay(dxLib)
		
		local running = true
		while running do
			messagePump()
			game:nextFrame()
			if hk.down(hk.VK_Q) and window.isForeground(detected.consoleHwnd) then
				winutil.flushConsoleInput()
				io.write("\n")
				running = false
			end
			C.Sleep(10)
		end
		game:close()
		os.exit(0)
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
