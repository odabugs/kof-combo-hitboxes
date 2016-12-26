local ffi = require("ffi")
local types = require("winapi.types")
local winutil = require("winutil")
local detectgame = require("detectgame")
local window = require("window")
local hk = require("hotkey")

ffi.cdef[[
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

---[[
function main(hInstance, dxLib)
	if type(dxLib) == "table" then
		--for k,v in pairs(dxLib) do print(k,v) end
		_G.directx = dxLib
	end
	hInstance = ffi.cast("HINSTANCE", hInstance)
	local detected = detectgame.findSupportedGame(hInstance)
	if detected and detected.module == "pcsx2.kof_xi" then
		local game = detectgame.moduleForGame(detected)
		game:extraInit()
		game:setupOverlay(dxLib)
		return mainLoop(game)
	else
		print(detected)
	end
end
--]]

--[[
function main(hInstance)
	return 0
end
--]]

function mainLoop(game)
	local message = ffi.new("MSG[1]")
	local running = true
	local drawing = true
	local fg
	while running do
		fg = window.foreground()
		while C.PeekMessageW(message, NULL, 0, 0, PM_REMOVE) ~= 0 do
			C.TranslateMessage(message)
			C.DispatchMessageW(message)
		end

		game:nextFrame(drawing)
		if fg == game.consoleHwnd then
			if hk.down(hk.VK_Q) then
				winutil.flushConsoleInput()
				io.write("\n")
				running = false
			end
		end
		if fg == game.consoleHwnd or fg == game.overlayHwnd or fg == game.gameHwnd then
			if hk.pressed(0x20) then drawing = not drawing end
		end
		C.Sleep(5)
	end
	game:close()
	return 0
end
