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
int _kbhit(void);
]]
local C = ffi.C

local openingMessage = [[
KoF Combo Hitbox Viewer, Version 1.0.1
<https://github.com/odabugs/kof-combo-hitboxes/>
LuaJIT Copyright 2005-2017 Mike Pall.
<http://luajit.org/>
]]

function main(hInstance, CLibs)
	print(openingMessage)
	hInstance = ffi.cast("HINSTANCE", hInstance)
	local detected = detectgame.findSupportedGame(hInstance)
	if detected then
		local game = detectgame.moduleForGame(detected)
		print(string.format("Running game detected: %s (%s).",
			detected.prettyName, game.platformType))
		game:loadConfigs()
		print()
		game:printRecommendations()
		game:printWindowPosition()
		print()
		game:extraInit()
		game:setupOverlay(CLibs.directx)
		collectgarbage()
		print("Press Q in this console window to exit the hitbox viewer.")
		return mainLoop(game)
	else
		print("Failed to detect a supported game running.")
		print("Press any key to exit.")
		while C._kbhit() == 0 do C.Sleep(5) end -- Rest In Peace, conio.h
	end
end

function mainLoop(game)
	local running = true
	local drawing = true
	local gameHwnd, overlayHwnd = game.gameHwnd, game.overlayHwnd
	local consoleHwnd = game.consoleHwnd
	local fg, hasFocus

	while running do
		pumpMessages(overlayHwnd)
		fg = window.foreground()
		hasFocus = fg == gameHwnd or fg == overlayHwnd or fg == consoleHwnd
		running = game:nextFrame(drawing, hasFocus)
		if not running then break end
		if hasFocus then
			if fg == game.consoleHwnd then
				if hk.down(hk.VK_Q) then
					winutil.flushConsoleInput()
					io.write("\n")
					running = false
					break
				end
			end
		end
		C.Sleep(5)
	end
	game:close()
	return 0
end

-- LuaJIT's callback mechanism has known limitations with handling
-- infrequently used callbacks when compiled Lua code is involved.
-- Interpreting the offending sections instead avoids such problems.
-- http://www.freelists.org/post/luajit/libvlc-videolan-and-callbacks-crashing,2
do
	local message = ffi.new("MSG[1]")
	local PM_REMOVE = 0x01

	function pumpMessages(hwnd)
		while C.PeekMessageW(message, hwnd, 0, 0, PM_REMOVE) ~= 0 do
			C.TranslateMessage(message)
			C.DispatchMessageW(message)
		end
	end

	jit.off(pumpMessages, true)
end
