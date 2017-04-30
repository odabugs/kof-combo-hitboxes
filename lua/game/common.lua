local luautil = require("luautil")
local window = require("window")
local winprocess = require("winprocess")
local winutil = require("winutil")
local draw = require("game.draw")
local colors = require("render.colors")
local ReadConfig = require("config")
local Game_Common = {}
-- Import variables and methods from "draw" into this class.
-- If you see something being used that's not defined here, look in there.
luautil.extend(Game_Common, draw)

Game_Common.RAM_RANGE_ERROR = "Target address 0x%08X must be between 0x%08X and 0x%08X (inclusive)."

-- value added to address parameter in every call to read()
Game_Common.RAMbase = 0
-- upper limit for valid RAM addresses; it is an error if we go above this
Game_Common.RAMlimit = 0xFFFFFFFF
-- runtime base address of target game process
Game_Common.processBase = 0
-- "ideal" screen width/height (at or nearest to 1:1 scale in the game)
Game_Common.basicWidth = 1
Game_Common.basicHeight = 1
-- rule for handling aspect ratios that differ from the "ideal" aspect;
-- values: "stretch", "letterbox", "pillarbox", "center"
Game_Common.aspectMode = "stretch"
Game_Common.whoami = "Game_Common"

-- pass a result from detectgame.findSupportedGame() as the "source" param
function Game_Common:new(source)
	source = (source or {})
	setmetatable(source, self)
	self.__index = self
	if source.parent == nil then source.parent = self end
	if source.gameHandle then
		source.processBase = winprocess.getBaseAddress(source.gameHandle)
		--print(string.format("Base address: 0x%08X", source.processBase))
		source:relocate(source.processBase)
	end

	-- values that are set once during init, but may vary based on
	-- other variables set in the calling object
	source.basicAspect = source.basicWidth / source.basicHeight
	-- resources that MUST always be unique instances are init'd here
	source.addressBuf = winutil.ptrBufType() -- used by read()
	source.pointerBuf = winutil.ptrBufType() -- used by readPtr()
	source.rectBuf = winutil.rectBufType()
	source.pointBuf = winutil.pointBufType()
	-- values to be set at runtime
	source.width, source.height = 1, 1
	source.xScale, source.yScale = 1, 1
	source.xOffset, source.yOffset = 0, 0
	source.aspect = 1

	return source
end

-- to be (optionally) overridden by derived objects
function Game_Common:extraInit()
	return
end

-- to be (optionally) overridden by derived objects
function Game_Common:relocate(baseAddress)
	return
end

function Game_Common:importRevisionSpecificOptions(overwrite, source)
	if not source then
		-- don't bother if the game doesn't have multiple revisions anyway
		if not self.revisions then return
		else
			-- expects self.revision to be set beforehand by detectgame.lua
			source = self.revisions[self.revision]
			if source == nil then
				error(string.format(
					"Unrecognized revision (%s) of this game.", self.revision))
			end
		end
	end

	for k, v in pairs(source) do
		if overwrite or (self[k] == nil) then self[k] = v end
	end
end

function Game_Common:close()
	window.destroy(self.overlayHwnd)
	window.unregisterClass(self.atom, self.hInstance)
	winprocess.close(self.gameHandle)
end

function Game_Common:setupOverlay(directx)
	self.overlayHwnd, self.atom = window.createOverlayWindow(
		self.hInstance, self.gameHwnd)
	self.directx = directx
	self.width, self.height = window.getDimensions(self.gameHwnd)
	-- making the D3D surface large allows for smooth window resizing
	self.directx.setupD3D(self.overlayHwnd, window.getScreenSize())
end

function Game_Common:read(address, buffer)
	local newAddress = self:pointerRangeCheck(address)
	local addressBuf = self.addressBuf
	addressBuf.i = newAddress
	local result = winprocess.read(self.gameHandle, addressBuf, buffer)
	return result, address
end

function Game_Common:readPtr(address, buffer)
	local newAddress = self:pointerRangeCheck(address)
	buffer = (buffer or self.pointerBuf)
	buffer.i = newAddress
	winprocess.read(self.gameHandle, buffer, buffer)
	return buffer.i, address
end

function Game_Common:pointerRangeCheck(address)
	local lower, upper = self.RAMbase, self.RAMlimit
	address = address + lower
	if address < lower or address > upper then
		local message = string.format(self.RAM_RANGE_ERROR,
			address, lower, upper)
		error(message, 3) -- throw error where read()/readPtr() was called
	end
	return address
end

-- to be overridden by derived objects
function Game_Common:captureState()
	return
end

-- to be overridden by derived objects
function Game_Common:renderState()
	return
end

-- to be overridden by derived objects
function Game_Common:checkInputs()
	return
end

function Game_Common:nextFrame(drawing, hasFocus)
	if hasFocus then self:checkInputs() end
	if not window.isWindow(self.gameHwnd) then return false end
	if drawing and self:shouldRenderFrame() then
		self:repositionOverlay()
		self.directx.beginFrame()
		self:captureState()
		self:renderState()
	else
		self.directx.beginFrame()
		self:captureState()
	end
	self.directx.endFrame(0, 0, self.width, self.height)
	return true
end

function Game_Common:loadConfigs()
	local result = {}
	self:loadConfigFile(result, "default.ini")
	local configSection = self.configSection
	if configSection then
		self:loadConfigFile(result, configSection .. ".ini", configSection)
	end
	return result
end

function Game_Common:loadConfigFile(target, path, sectionPrefix)
	io.write("Loading config file '", path, "'...\n")
	local file, fileErr = io.open(path, "r")
	if fileErr then
		io.write("Failed to load config file '", path, "': ", fileErr, "\n")
	else
		local schema = self.schema or self:getConfigSchema()
		self.schema = schema
		target = ReadConfig.readFile(file, schema, target, sectionPrefix)
		io.write("Finished loading config file '", path, "'.\n")
		return target
	end
end

-- to be overridden by derived objects
function Game_Common:getConfigSchema()
	return {}
end

-- memoize generated functions since we don't need 10 of the same thing
do
	local readerFns = {}
	function Game_Common:partialReader(fn, postprocess)
		local result = readerFns[fn]
		if not result then
			result = function(targetKey, target)
				return ReadConfig.readerGenerator(
					fn, target, targetKey, postprocess)
			end
			readerFns[fn] = result
		end
		return result
	end
end

function Game_Common:booleanReader(targetKey, target)
	local fn = self:partialReader(ReadConfig.parseBoolean)
	return fn(targetKey, (target or self))
end

function Game_Common:byteReader(targetKey, target)
	local fn = self:partialReader(ReadConfig.parseDecimalByte)
	return fn(targetKey, (target or self))
end

do
	local function getColorValue(newColor) return newColor.color end
	function Game_Common:colorReader(targetKey, target)
		local fn = self:partialReader(ReadConfig.parseColor, getColorValue)
		return fn(targetKey, (target or self))
	end
end

do
	local function handleBoxColor(value, key, target)
		local newColor, err = ReadConfig.parseColor(value)
		local bt = target.boxtypes
		if newColor then
			local boxtypeKey = bt.colorConfigNames[key]
			local target = bt.colormap[boxtypeKey]
			local nc = newColor.color
			-- set edge color
			target[1] = colors.setAlpha(nc, bt.defaultEdgeAlpha)
			-- set fill color
			if not newColor.hasAlpha then
				nc = colors.setAlpha(nc, bt.defaultFillAlpha)
			end
			target[2] = nc
		end
		return newColor, err
	end

	function Game_Common:hitboxColorReader(targetKey, target)
		local fn = self:partialReader(handleBoxColor)
		return fn(targetKey, (target or self))
	end
end

function Game_Common:getConfigSchema()
	local schema = {
		colors = {
			playerPivot = self:colorReader("pivotColor"),
			projectilePivot = self:colorReader("projectilePivotColor"),
		},
	}
	local bt = self.boxtypes
	if bt then
		schema.global = {
			boxEdgeOpacity = self:byteReader("defaultEdgeAlpha", bt),
			boxFillOpacity = self:byteReader("defaultFillAlpha", bt),
		}
		for colorKey in pairs(bt.colorConfigNames) do
			schema.colors[colorKey] = self:hitboxColorReader(colorKey)
		end
	else
		schema.global = {}
	end
	local booleanKeys = {
		"drawPlayerPivot", "drawBoxPivot",
	}
	local g = schema.global
	for _, booleanKey in ipairs(booleanKeys) do
		g[booleanKey] = self:booleanReader(booleanKey)
	end
	g.drawBoxFill = self:booleanReader("drawBoxFills")
	-- duplicating the schema sections and nesting them under the game's
	-- config section name permits INI files to have game-specific sections;
	-- shallow copy allows games to extend existing sections w/o extra work
	if self.configSection then
		schema[self.configSection] = luautil.extend({}, schema)
	end
	return schema
end

return Game_Common
