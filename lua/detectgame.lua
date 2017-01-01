local ffi = require("ffi")
local types = require("winapi.types")
local window = require("window")
local winprocess = require("winprocess")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")
local detectgame = {}

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
			--gameDC = window.getDC(hwnd),
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
	local detectedRevision = nil
	if string.find(title, targetTitle, 1, raw) == nil then
		return nil
	end
	-- does the target game have multiple revisions we have to check for?
	if params.revisions ~= nil then
		for k, v in pairs(params.revisions) do
			print(string.format(
				"Checking for \"%s\" in title \"%s\" (v=%s)...",
				k, title, v))
			if string.find(title, k, 1, true) ~= nil then
				detectedRevision = v
				break
			end
		end
		if detectedRevision == nil then
			-- TODO: better handling of unsupported revisions of a game
			return nil
		end
	end
	-- also opens handle on successful match
	local result = checkClassName(hwnd, params)
	if detectedRevision ~= nil then result.revision = detectedRevision end
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
		targetWindowTitle = "King of Fighters XI",
		revisions = {
			["SLPS-25660"] = "NTSC-J",
			["SLUS-21687"] = "NTSC-U",
			["SLES-54437"] = "PAL",
		},
		-- PCSX2's GAME DISPLAY window title will contain this line
		-- (this is the window we really want, not the console window)
		gameWindowTitle = "GSdx",
		rawTitle = true,
		targetProcessName = "pcsx2.exe",
	},
	{
		module = "pcsx2.ngbc",
		detectMethod = checkWindowTitleAndProcessName,
		postprocess = findGameWindowByParentPID,
		targetWindowTitle = "NeoGeo Battle Coliseum",
		revisions = {
			-- TODO: japanese version of NGBC
			["SLUS-21708"] = "NTSC-U",
			["SLES-54395"] = "PAL",
		},
		gameWindowTitle = "GSdx",
		rawTitle = true,
		targetProcessName = "pcsx2.exe",
	},
}

function detectgame.findSupportedGame(hInstance, createOverlay)
	local detectedGame = nil
	local function EnumWindowsProc(hwnd, lParam)
		local result
		for i, game in ipairs(detectedGames) do
			result = game.detectMethod(game, hwnd, lParam)
			result = (result and game.postprocess(game, result))
			if result ~= nil then
				detectedGame = result
				return false -- match found; stop EnumWindows loop
			end
		end
		return true -- continue EnumWindows loop
	end

	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	if detectedGame ~= nil and hInstance ~= nil then
		detectedGame.hInstance = hInstance
		--detectedGame.gameDC = window.getDC(detectedGame.gameHwnd)
		detectedGame.consoleHwnd = window.console()
		if createOverlay then
			detectedGame.overlayHwnd = window.createOverlayWindow(hInstance)
			--detectedGame.overlayDC = window.getDC(detectedGame.overlayHwnd)
			directx.setupD3D(detectedGame.overlayHwnd)
		end
	end
	return detectedGame
end

function detectgame.moduleForGame(game)
	local target = string.format("game.%s.game", game.module)
	local result = require(target):new(game)
	return result
end

return detectgame
