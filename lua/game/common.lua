local luautil = require("luautil")
local window = require("window")
local winprocess = require("winprocess")
local winutil = require("winutil")
local draw = require("game.draw")
local Game_Common = {}
-- Import variables and methods from "draw" into this class.
-- If you see something being used that's not defined here, look in there.
luautil.extend(Game_Common, draw)

local RAM_RANGE_EXCEEDED = "Attempted to step outside the limits of the RAM range."

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

function Game_Common:close()
	window.destroy(self.overlayHwnd)
	window.unregisterClass(self.atom, self.hInstance)
	winprocess.close(self.gameHandle)
end

function Game_Common:setupOverlay(directx)
	self.overlayHwnd, self.atom = window.createOverlayWindow(self.hInstance)
	self.directx = directx
	--self.overlayDC = window.getDC(self.overlayHwnd)
	-- TODO: change directx code on the C side to support multiple instances
	self.directx.setupD3D(self.overlayHwnd)
end

function Game_Common:read(address, buffer)
	address = address + self.RAMbase
	assert(address >= self.RAMbase and address < self.RAMlimit, RAM_RANGE_EXCEEDED)
	self.addressBuf.i = address
	local result = winprocess.read(self.gameHandle, self.addressBuf, buffer)
	return result, address
end

function Game_Common:readPtr(address)
	address = address + self.RAMbase
	assert(address >= self.RAMbase and address < self.RAMlimit, RAM_RANGE_EXCEEDED)
	self.pointerBuf.i = address
	winprocess.read(self.gameHandle, self.pointerBuf, self.pointerBuf)
	return self.pointerBuf.i, address
end

-- to be overridden by derived objects
function Game_Common:captureState()
	return
end

-- to be overridden by derived objects
function Game_Common:renderState()
	return
end

function Game_Common:nextFrame(drawing)
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

return Game_Common
