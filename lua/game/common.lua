local window = require("window")
local winprocess = require("winprocess")
local winutil = require("winutil")
local color = require("render.colors")
local Game_Common = {}

-- value added to address parameter in every call to read()/write()
Game_Common.RAMbase = 0

-- pass a result from detectgame.findSupportedGame() as the "source" param
function Game_Common:new(source)
	source = (source or {})
	setmetatable(source, self)
	self.__index = self

	-- resources that MUST always be unique instances are init'd here
	source.addressBuf = winutil.ptrBufType() -- used by read()
	source.pointerBuf = winutil.ptrBufType() -- used by readPtr()
	source.rectBuf = winutil.rectBufType()
	source.pointBuf = winutil.pointBufType()
	-- used by nextFrame()
	source.captureCo = coroutine.create(self.captureState)
	source.renderCo = coroutine.create(self.renderState)

	return source
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
	self:setColor(color.rgba(255,0,0))
end

function Game_Common:read(address, buffer)
	self.addressBuf.i = address + self.RAMbase
	local result = winprocess.read(self.gameHandle, self.addressBuf, buffer)
	return result
end

function Game_Common:readPtr(address)
	self.pointerBuf.i = address + self.RAMbase
	winprocess.read(self.gameHandle, self.pointerBuf, self.pointerBuf)
	return self.pointerBuf.i
end

function Game_Common:repositionOverlay()
	window.move(
		self.overlayHwnd, self.gameHwnd,
		self.rectBuf, self.pointBuf, false) -- TODO: don't resize for now
end

function Game_Common:rect(...)
	self.directx.rect(...)
end

function Game_Common:getColor()
	return self.directx.getColor()
end

function Game_Common:setColor(newColor)
	return self.directx.setColor(newColor)
end

function Game_Common:shouldRenderFrame()
	local fg = window.foreground()
	if fg == self.gameHwnd then
		return true
	elseif fg == self.overlayHwnd and window.isVisible(self.gameHwnd) then
		return true
	end
	return false
end

-- to be overridden by objects that inherit from this prototype
function Game_Common:captureState()
	while true do coroutine.yield() end
end

-- to be overridden by objects that inherit from this prototype
function Game_Common:renderState()
	while true do coroutine.yield() end
end

function Game_Common:nextFrame()
	--[=[
	print("capture", coroutine.resume(self.captureCo, self))
	--]=]
	---[=[
	coroutine.resume(self.captureCo, self)
	--]=]
	if self:shouldRenderFrame() then
		self:repositionOverlay()
		self.directx.beginFrame()
		--[=[
		print("render", coroutine.resume(self.renderCo, self))
		--]=]
		---[=[
		coroutine.resume(self.renderCo, self)
		--]=]
	else
		self.directx.beginFrame()
	end
	self.directx.endFrame()
end

return Game_Common
