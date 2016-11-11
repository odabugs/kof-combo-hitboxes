local detectgame = {}
local ffi = require("ffi")
local winapi = require("winapi")
local winerror = require("winerror")
local luautil = require("luautil")
local winprocess = require("winprocess")

ffi.cdef[[
typedef BOOL (__stdcall *WNDENUMPROC)(HWND hwnd, LPARAM lParam);
BOOL EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
int GetWindowTextW(HWND hWnd, LPTSTR lpString, int nMaxCount);
int GetWindowTextLengthW(HWND hWnd);
DWORD GetWindowThreadProcessId(HWND hWnd, LPDWORD lpdwProcessId);
BOOL QueryFullProcessImageNameW(HANDLE hProcess, DWORD dwFlags, LPTSTR lpExeName, PDWORD lpdwSize);
typedef struct { int16_t x; int16_t y; } coordPair;
]]
local C = ffi.C
-- winapi.wcs module uses WCHAR when you ask it for a char buffer via WCS()
local charSize = ffi.sizeof("WCHAR")

-- set by EnumWindowsProc, returned by detectgame.findSupportedGame
local detectedGame

local function makeStringBuffer(n)
	local newN = (n > 0 and n or 255)
	local buffer = winapi.WCS(newN)
	local bufSize = ffi.sizeof(buffer) / charSize
	return buffer, bufSize
end

local function getWindowTitle(hwnd)
	local titleLen = C.GetWindowTextLengthW(hwnd)
	winerror.checkNotZero(titleLen)
	local buffer, limit = makeStringBuffer(titleLen)
	winerror.checkNotZero(C.GetWindowTextW(
		hwnd, ffi.cast("LPTSTR", buffer), limit))
	return winapi.mbs(buffer)
end

local function getClassName(hwnd)
	local buffer, n = makeStringBuffer(1024)
	local nBuf = ffi.new("DWORD[1]", n)
	winerror.checkNotZero(C.QueryFullProcessImageNameW(
		hwnd, 0, ffi.cast("LPTSTR", buffer), nBuf))
	return winapi.mbs(buffer)
end

local function checkClassName(hwnd, params)
	local parentPid = ffi.new("DWORD[1]")
	local parentThread = C.GetWindowThreadProcessId(hwnd, parentPid)
	winerror.checkNotZero(parentThread)
	local handle = winprocess.open(parentPid[0])

	local className = getClassName(handle)
	local target = params.targetProcessName
	--[[
	local splitClass = luautil.collect(string.gmatch(className, "[^\\]+"))
	local programName = splitClass[#splitClass]
	print(parentPid[0], parentThread, className, programName)
	local result = string.find(programName, target) == 1
	--]]
	local result = luautil.stringEndsWith(className, target)
	print(parentPid[0], parentThread, className, result)
	return result, (result and handle or NULL)
end

local function checkWindowTitleAndProcessName(params, hwnd, lParam)
	local title = getWindowTitle(hwnd)
	if string.find(title, params.targetWindowTitle, 1, true) == nil then
		return false, NULL
	end
	-- also opens handle on successful match
	local result, handle = checkClassName(hwnd, params)
	return result, handle
end

local detectedGames = {
	{
		module = "steam.kof98um",
		detectMethod = checkWindowTitleAndProcessName,
		targetWindowTitle = "King of Fighters '98 Ultimate Match Final Edition",
		targetProcessName = "KingOfFighters98UM.exe",
	},
	{
		module = "steam.kof2002um",
		detectMethod = checkWindowTitleAndProcessName,
		targetWindowTitle = "King of Fighters 2002 Unlimited Match",
		targetProcessName = "KingOfFighters2002UM.exe",
	},
	{
		module = "pcsx2.kof_xi",
		detectMethod = checkWindowTitleAndProcessName,
		-- the PCSX2 console's window title will start with this line
		targetWindowTitle = "King of Fighters XI, The (NTSC-U)",
		targetProcessName = "pcsx2.exe",
	},
}

local function EnumWindowsProc(hwnd, lParam)
	local detected, handle
	for i, game in ipairs(detectedGames) do
		detected, handle = game.detectMethod(game, hwnd, lParam)
		if detected then
			detectedGame = {
				module = game.module,
				processHandle = handle,
			}
			return false -- stop EnumWindows loop
		end
	end
	return true -- continue EnumWindows loop
end

function detectgame.findSupportedGame()
	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	return detectedGame
end

return detectgame
