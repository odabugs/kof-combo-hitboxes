local detectgame = {}
local ffi = require("ffi")
local types = require("winapi.types")
local window = require("window")
local winprocess = require("winprocess")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")

ffi.cdef[[
typedef BOOL (__stdcall *WNDENUMPROC)(HWND hwnd, LPARAM lParam);
BOOL EnumWindows(WNDENUMPROC lpEnumFunc, LPARAM lParam);
]]
local C = ffi.C

local function checkClassName(hwnd, params)
	local parentPID, parentThread = window.getParentProcessID(hwnd)
	local handle = winprocess.open(parentPID)
	local imageName = window.getProcessImageName(handle)
	local target = params.targetProcessName
	local result = luautil.stringEndsWith(imageName, target, true)
	if result == false then
		winprocess.close(handle)
		return nil
	else
		return {
			gameHwnd = hwnd,
			gameHandle = handle,
			gamePID = parentPID,
			module = params.module,
		}
	end
end

local function checkWindowTitleAndProcessName(params, hwnd, lParam)
	local title = window.getWindowTitle(hwnd)
	local targetTitle = params.targetWindowTitle
	local raw = params.rawTitle
	if string.find(title, targetTitle, 1, raw) == nil then
		return nil
	end
	-- also opens handle on successful match
	local result = checkClassName(hwnd, params)
	return result
end

local function findGameWindowByParentPID(params, game)
	-- nested EnumWindows; not the greatest, but functional
	local targetTitle = params.gameWindowTitle
	local targetPID = game.gamePID
	local pidBuffer = winutil.dwordBufType(0)
	local result = nil
	local function EnumWindowsProc(hwnd, lParam)
		local pid = window.getParentProcessID(hwnd, pidBuffer)
		if pid ~= targetPID then
			return true -- continue EnumWindows loop
		end
		local title = window.getWindowTitle(hwnd)
		if string.find(title, targetTitle, 1, true) ~= nil then
			result = hwnd
			return false -- match found; stop EnumWindows loop
		else
			return true -- continue EnumWindows loop
		end
	end

	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	if result ~= nil then
		game.gameHwnd = result
		return game
	else
		winprocess.close(game.gameHandle)
		return nil
	end
end

local function noPostprocess(params, game) return game end

local detectedGames = {
	{
		module = "steam.kof98um",
		detectMethod = checkWindowTitleAndProcessName,
		postprocess = noPostprocess,
		targetWindowTitle = "King of Fighters '98 Ultimate Match Final Edition",
		rawTitle = true, -- use false if title is a Lua pattern string
		targetProcessName = "KingOfFighters98UM.exe",
	},
	{
		module = "steam.kof2002um",
		detectMethod = checkWindowTitleAndProcessName,
		postprocess = noPostprocess,
		targetWindowTitle = "King of Fighters 2002 Unlimited Match",
		rawTitle = true,
		targetProcessName = "KingOfFighters2002UM.exe",
	},
	{
		module = "pcsx2.kof_xi",
		detectMethod = checkWindowTitleAndProcessName,
		postprocess = findGameWindowByParentPID,
		-- PCSX2's CONSOLE window title will start with this line
		-- (we search for this window first because it has the game title)
		targetWindowTitle = "King of Fighters XI, The (NTSC-U)",
		-- PCSX2's GAME DISPLAY window title will contain this line
		-- (this is the window we really want, not the console window)
		gameWindowTitle = "GSdx",
		rawTitle = true,
		targetProcessName = "pcsx2.exe",
	},
}

function detectgame.findSupportedGame(hInstance)
	local detectedGame = nil
	local function EnumWindowsProc(hwnd, lParam)
		local result
		for i, game in ipairs(detectedGames) do
			result = game.detectMethod(game, hwnd, lParam)
			result = (result and game.postprocess(game, result))
			if result ~= nil then
				detectedGame = result
				detectedGame.hInstance = hInstance
				return false -- match found; stop EnumWindows loop
			end
		end
		return true -- continue EnumWindows loop
	end

	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	return detectedGame
end

return detectgame
