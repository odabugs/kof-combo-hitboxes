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

Game_Common.RAM_RANGE_ERROR = "Target address 0x%08X is outside of the range from 0x%08X (inclusive) to 0x%08X (exclusive)."

-- value added to address parameter in every call to read()
Game_Common.RAMbase = 0
-- upper limit for valid RAM addresses; it is an error if we go above this
Game_Common.RAMlimit = 0xFFFFFFFF
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
	source.xScissor, source.yScissor = 1, 1
	source.aspect = 1

	return source
end

-- to be (optionally) overridden by derived objects
function Game_Common:extraInit()
	return
end

function Game_Common:importRevisionSpecificOptions(overwrite, source)
	if source == nil then
		-- don't bother if the game doesn't have multiple revisions anyway
		if self.revisions == nil then return
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
	self.overlayHwnd, self.atom = window.createOverlayWindow(self.hInstance)
	self.directx = directx
	-- TODO: change directx code on the C side to support multiple instances
	self.directx.setupD3D(self.overlayHwnd)
end

function Game_Common:read(address, buffer)
	address = address + self.RAMbase
	self:pointerRangeCheck(address)
	self.addressBuf.i = address
	local result = winprocess.read(self.gameHandle, self.addressBuf, buffer)
	return result, address
end

function Game_Common:readPtr(address, buffer)
	address = address + self.RAMbase
	self:pointerRangeCheck(address)
	buffer = (buffer or self.pointerBuf)
	buffer.i = address
	winprocess.read(self.gameHandle, buffer, buffer)
	return buffer.i, address
end

function Game_Common:pointerRangeCheck(address)
	local lower, upper = self.RAMbase, self.RAMlimit
	if address < lower or address >= upper then
		local message = string.format(self.RAM_RANGE_ERROR,
			address, lower, upper)
		error(message, 3) -- throw error where read()/readPtr() was called
	end
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

function Game_Common:nextFrame(drawing)
	self:checkInputs()
	self:captureState()
	if drawing and self:shouldRenderFrame() then
		self:repositionOverlay()
		self.directx.beginFrame()
		self:renderState()
	else
		self.directx.beginFrame()
	end
	self.directx.endFrame()
end

function Game_Common:loadConfigs()
	local configSection = self.configSection
	local result = {}
	self:loadConfigFile(result, "default.ini")
	self:loadConfigFile(result, configSection .. ".ini", configSection)
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

return Game_Common
