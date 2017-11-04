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
	if not result then
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
	local detectedRevision = nil
	if string.find(title, targetTitle, 1, raw) == nil then
		return nil
	end
	-- does the target game have multiple revisions we have to check for?
	if params.revisions ~= nil then
		for k, v in pairs(params.revisions) do
			--[[
			print(string.format(
				"Checking for \"%s\" in title \"%s\" (v=%s)...",
				k, title, v))
			--]]
			if string.find(title, k, 1, true) ~= nil then
				detectedRevision = v
				break
			end
		end
		if detectedRevision == nil then
			print("A currently unsupported version of this game was detected.")
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
	local targetTitles = params.gameWindowTitles
	local targetPID = game.gamePID
	local pidBuffer = winutil.dwordBufType(0)
	local result = nil
	local function EnumWindowsProc(hwnd, lParam)
		local pid = window.getParentProcessID(hwnd, pidBuffer)
		if pid ~= targetPID then
			return true -- continue EnumWindows loop
		end
		local title = window.getWindowTitle(hwnd)
		for _, targetTitle in ipairs(targetTitles) do
			if string.find(title, targetTitle, 1, true) ~= nil then
				result = hwnd
				return false -- match found; stop EnumWindows loop
			end
		end
		return true -- continue EnumWindows loop
	end

	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	if result ~= nil then
		game.gameHwnd = result
		game.prettyName = params.prettyName
		game.platformType = params.platformType
		return game
	else
		winprocess.close(game.gameHandle)
		return nil
	end
end

local function noPostprocess(params, game)
	game.prettyName = params.prettyName
	game.platformType = params.platformType
	return game
end

local GameTemplate = {
	new = function(self, source)
		setmetatable(source, self)
		self.__index = self
		return source
	end
}
local SteamGame = GameTemplate:new({
	platformType = "Steam",
	detectMethod = checkWindowTitleAndProcessName,
	postprocess = noPostprocess,
	rawTitle = true, -- use false if title is a Lua pattern string
})
local PS2Game = GameTemplate:new({
	platformType = "PS2",
	detectMethod = checkWindowTitleAndProcessName,
	postprocess = findGameWindowByParentPID,
	-- PCSX2's GAME DISPLAY window title will contain this line
	-- (this is the window we really want, not the console window)
	gameWindowTitles = { "GSdx", "ZeroGS" },
	rawTitle = true,
	targetProcessName = "pcsx2.exe",
})

-- games are detected and prioritized in the order listed here;
-- if two games are running, the game that appears first in this list wins
local detectedGames = {
	SteamGame:new({
		module = "steam.kof98um",
		prettyName = "King of Fighters '98 Ultimate Match Final Edition",
		targetWindowTitle = "King of Fighters '98 Ultimate Match Final Edition",
		targetProcessName = "KingOfFighters98UM.exe",
	}),
	SteamGame:new({
		module = "steam.kof2002um",
		prettyName = "King of Fighters 2002 Unlimited Match",
		targetWindowTitle = "King of Fighters 2002 Unlimited Match",
		targetProcessName = "KingOfFighters2002UM.exe",
	}),
	SteamGame:new({
		module = "steam.ggxxacplusr",
		prettyName = "Guilty Gear XX Accent Core +R",
		targetWindowTitle = "GUILTY GEAR XX ..?CORE PLUS R",
		rawTitle = false,
		targetProcessName = "GGXXACPR_Win.exe",
	}),
	SteamGame:new({
		module = "steam.ggxxreload",
		prettyName = "Guilty Gear XX #Reload",
		targetWindowTitle = "GUILTYGEAR X2 #RELOAD",
		targetProcessName = "ggx2.exe",
	}),
	PS2Game:new({
		module = "pcsx2.kof_xi",
		prettyName = "King of Fighters XI",
		-- PCSX2's CONSOLE window title will start with this line
		-- (we search for this window first because it has the game title)
		targetWindowTitle = "King of Fighters XI",
		revisions = {
			-- TODO: SLKA-25167
			["SLPS-25660"] = "NTSC-J",
			["SLPS-25789"] = "NTSC-J", -- TODO: NOT YET TESTED
			["SLUS-21687"] = "NTSC-U",
			["SLES-54437"] = "PAL",
		},
	}),
	PS2Game:new({
		module = "pcsx2.kof_neowave",
		prettyName = "King of Fighters NeoWave",
		targetWindowTitle = "King of Fighters, The.-Neo ?Wave",
		rawTitle = false,
		revisions = {
			["SLPS-25525"] = "NTSC-J",
			["SLPS-25712"] = "NTSC-J", -- TODO: NOT YET TESTED
			["SLES-53999"] = "PAL",
		},
	}),
	PS2Game:new({
		module = "pcsx2.kof98um",
		prettyName = "King of Fighters '98 Ultimate Match",
		targetWindowTitle = "King [Oo]f Fighters .?98.-Ultimate Match",
		rawTitle = false,
		revisions = {
			["SLPS-25783"] = "NTSC-J",
			["SLPS-25935"] = "NTSC-J", -- TODO: NOT YET TESTED
			["SLES-55280"] = "PAL",
			["SLUS-21816"] = "NTSC-U",
		},
	}),
	PS2Game:new({
		module = "pcsx2.kof2002um",
		prettyName = "King of Fighters 2002 Unlimited Match",
		targetWindowTitle = "The King of Fighters 2002.-Unlimited Match",
		rawTitle = false,
		revisions = {
			["SLPS-25915"] = "NTSC-J",
			["SLPS-25983"] = "NTSC-J Tougeki Ver.",
		},
	}),
	PS2Game:new({
		module = "pcsx2.ngbc",
		prettyName = "NeoGeo Battle Coliseum",
		targetWindowTitle = "NeoGeo Battle Coliseum",
		revisions = {
			-- Both NTSC-J revisions report as SLPS-25558 in PCSX2 console
			["SLPS-25558"] = "NTSC-J",
			["SLPS-25737"] = "NTSC-J", -- PCSX2 thinks this is the same?
			["SLUS-21708"] = "NTSC-U",
			["SLES-54395"] = "PAL",
		},
	}),
	PS2Game:new({
		module = "pcsx2.cvs2",
		prettyName = "Capcom vs. SNK 2",
		targetWindowTitle = "Capcom vs. SNK 2 - Mark of the Millennium 2001",
		revisions = {
			["SLPM-65047"] = "NTSC-J",
			["SLUS-20246"] = "NTSC-U",
			["SLES-50541"] = "PAL",
		},
	}),
	PS2Game:new({
		module = "pcsx2.cfj",
		prettyName = "Capcom Fighting Evolution",
		targetWindowTitle = "Capcom Fighting Evolution",
		revisions = {
			["SLPM-65794"] = "NTSC-J",
			["SLUS-20950"] = "NTSC-U",
			["SLES-52852"] = "PAL",
			["SLES-52854"] = "PAL",
		},
	}),
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
				return false -- match found; stop EnumWindows loop
			end
		end
		return true -- continue EnumWindows loop
	end

	local successful = C.EnumWindows(EnumWindowsProc, 0)
	winerror.checkNotZero(successful)
	if detectedGame ~= nil and hInstance ~= nil then
		detectedGame.hInstance = hInstance
		detectedGame.consoleHwnd = window.console()
	end
	return detectedGame
end

function detectgame.moduleForGame(game)
	local target = string.format("game.%s.game", game.module)
	local result = require(target):new(game)
	return result
end

return detectgame
