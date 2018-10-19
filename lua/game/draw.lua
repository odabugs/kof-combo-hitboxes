local window = require("window")
local colors = require("render.colors")
-- This class is not intended to be instantiated directly;
-- instead, use luautil.extend() to add its methods to a game class.
-- These methods expect the following to be defined on the calling object:
-- - basicWidth, basicHeight, width, height
-- - xOffset, yOffset, aspectMode
-- - gameHwnd, overlayHwnd
-- - directx (table of C functions)
local draw = {}
local max = math.max

-- all draw calls are shifted upward by this amount
draw.absoluteYOffset = 0
draw.useThickLines = false
draw.drawBoxFills = true
draw.drawPlayerPivot = true
draw.pivotSize = 20
draw.drawBoxPivot = true
draw.boxPivotSize = 5
draw.pivotColor = colors.WHITE
draw.projectilePivotColor = colors.GREEN
draw.rangeMarkerColor = colors.GREEN
draw.activeRangeMarkerColor = colors.RED
draw.gaugeBorderColor = colors.BLACK
draw.gaugeFillAlpha = 0xA0
draw.projectilesEnabled = true
draw.playersEnabled = { true, true }

-- optional flags to pass when calling draw:scaleCoords
draw.COORD_RIGHT_EDGE = 0x01
draw.COORD_BOTTOM_EDGE = 0x02
draw.COORD_BOTTOM_RIGHT = bit.bor(
	draw.COORD_RIGHT_EDGE, draw.COORD_BOTTOM_EDGE)

local function ensureMinThickness(l, r)
	r = (r or l)
	if l < r then return l, r + 1
	else return r, l + 1 end
end

function draw:scaleCoords(x, y, flags)
	flags = (flags or 0)
	local xAdjust, yAdjust = 0, 0
	if bit.band(flags, self.COORD_RIGHT_EDGE) ~= 0 then xAdjust = 1 end
	if bit.band(flags, self.COORD_BOTTOM_EDGE) ~= 0 then yAdjust = 1 end

	x = math.floor((x + xAdjust) * self.xScale) - xAdjust
	y = math.floor(((y + yAdjust) - self.absoluteYOffset) * self.yScale)
	-- Why does this work better when adding 1 extra?  IT IS A MYSTERY
	y = y - yAdjust + 1
	return x + self.xOffset, y + self.yOffset
end

-- to be overridden by derived objects of draw
function draw:worldToScreen(x, y)
	return x, y
end

function draw:rawRect(x1, y1, x2, y2, color)
	self.directx.rect(x1, y1, x2, y2, color)
end

function draw:rect(x1, y1, x2, y2, color)
	x1, y1 = self:scaleCoords(x1, y1)
	x2, y2 = self:scaleCoords(x2, y2)
	x1, x2 = ensureMinThickness(x1, x2)
	y1, y2 = ensureMinThickness(y1, y2)
	self:rawRect(x1, y1, x2, y2, color)
end

function draw:horzLine(x1, x2, y, color, thick)
	thick = (thick or self.useThickLines)
	if thick then self:box(x1, y, x2, y, color, color)
	else self:rect(x1, y, x2, y, color) end
end

function draw:vertLine(y1, y2, x, color, thick)
	thick = (thick or self.useThickLines)
	if thick then self:box(x, y1, x, y2, color, color)
	else self:rect(x, y1, x, y2, color) end
end

function draw:pivot(x, y, size, color, thick)
	local p = (size or self.pivotSize)
	color = (color or self.pivotColor)
	thick = (thick or self.useThickLines)
	self:horzLine(x - p, x + p, y, color, thick)
	self:vertLine(y - p, y + p, x, color, thick)
end

function draw:getBoxCoords(x1, y1, x2, y2, thick)
	if thick == nil then thick = self.useThickLines end
	local corner = (thick and self.COORD_BOTTOM_RIGHT) or 0
	local outerLeftX, outerTopY     = self:scaleCoords(x1, y1)
	local outerRightX, outerBottomY = self:scaleCoords(x2, y2, corner)
	local innerLeftX, innerTopY, innerRightX, innerBottomY
	if thick then
		innerLeftX, innerTopY      = self:scaleCoords(x1, y1, corner)
		innerRightX, innerBottomY  = self:scaleCoords(x2, y2)
		outerLeftX, innerLeftX     = ensureMinThickness(outerLeftX, innerLeftX)
		outerTopY, innerTopY       = ensureMinThickness(outerTopY, innerTopY)
		innerRightX, outerRightX   = ensureMinThickness(innerRightX, outerRightX)
		innerBottomY, outerBottomY = ensureMinThickness(innerBottomY, outerBottomY)
	else
		outerLeftX, innerLeftX     = ensureMinThickness(outerLeftX)
		outerRightX, innerRightX   = ensureMinThickness(outerRightX)
		outerTopY, innerTopY       = ensureMinThickness(outerTopY)
		innerBottomY, outerBottomY = ensureMinThickness(outerBottomY)
	end
	return outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY
end

function draw:box(x1, y1, x2, y2, edgeColor, fillColor, thick)
	fillColor = (fillColor or colors.CLEAR)
	local outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY =
		self:getBoxCoords(x1, y1, x2, y2, thick)
	self.directx.hitbox(
		outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY,
		edgeColor, fillColor)
	return innerLeftX, innerTopY, innerRightX, innerBottomY
end

function draw:calculateScreenOffset(actual, baseline, scale)
	local scaled = math.floor(baseline * scale)
	if actual <= scaled then return 0
	else return math.floor((actual - scaled) * 0.5)
	end
end

function draw:adjustScaleAndAspect()
	self.xOffset, self.yOffset = 0, 0
	self.aspect = self.width / self.height
	local aspectDiff = self.aspect - self.basicAspect
	local mode = self.aspectMode
	if mode == "stretch" then
		self.xScale = self.width / self.basicWidth
		self.yScale = self.height / self.basicHeight
	elseif mode == "letterbox" or (mode == "center" and aspectDiff <= 0) then
		self.xScale = self.width / self.basicWidth
		self.yScale = self.xScale
		self.yOffset = self:calculateScreenOffset(
			self.height, self.basicHeight, self.yScale)
	elseif mode == "pillarbox" or (mode == "center" and aspectDiff > 0) then
		self.yScale = self.height / self.basicHeight
		self.xScale = self.yScale
		self.xOffset = self:calculateScreenOffset(
			self.width, self.basicWidth, self.xScale)
	end
end

function draw:getScissorDimensions()
	local xOff, yOff = self.xOffset, self.yOffset
	local scissorW = self.width - xOff
	local scissorH = self.height - yOff
	--print(xOff, yOff, scissorW, scissorH, self.width, self.height)
	return xOff, yOff, scissorW, scissorH
end

function draw:getGameWindowSize()
	local rb = self.rectBuf
	window.getClientRect(self.gameHwnd, rb)
	self.width, self.height = rb[0].right, rb[0].bottom
	self:adjustScaleAndAspect()
end

function draw:repositionOverlay()
	local oldW, oldH, dx = self.width, self.height, self.directx
	self:getGameWindowSize()
	local result, newX, newY, newW, newH = window.move(
		self.overlayHwnd, self.gameHwnd, self.rectBuf, self.pointBuf,
		0, 0, true)
	if oldW ~= newW or oldH ~= newH then
		dx.setScissor(0, 0, max(oldW, newW), max(oldH, newH))
		dx.clearFrame()
	end
	dx.setScissor(self:getScissorDimensions())
end

function draw:printWindowPosition()
	local gameHwnd = self.gameHwnd
	local wx, wy = window.getTopLeftCorner(gameHwnd, self.pointBuf)
	local width, height = window.getDimensions(gameHwnd, self.rectBuf)
	io.write(
		"Game window is located at (", wx, ", ", wy,
		") and its dimensions are (", width, ", ", height, ").\n")
	return wx, wy, width, height
end

function draw:shouldRenderFrame()
	local fg = window.foreground()
	---[=[
	if window.isVisible(self.gameHwnd) then return true end
	--]=]
	if fg == self.gameHwnd then
		return true
	elseif fg == self.overlayHwnd and window.isVisible(self.gameHwnd) then
		return true
	end
	return false
end

-- "parent" and "borderColor" are set on Gauge objects upon creation
local ProtoGauge = {
	x = 0, y = 0,
	width = 0, height = 0,
	minValue = 0, maxValue = 1,
	direction = "up",
	fillColor = colors.RED,
}
ProtoGauge.__index = ProtoGauge

function ProtoGauge:render(value)
	local r = self.renderer
	-- get "inner" box coords from the box() draw call
	local x, y, w, h = self.x, self.y, self.width, self.height
	local x1, y1, x2, y2 = r:box(x, y, x + w, y + h, self.borderColor)

	local min, max, direction = self.minValue, self.maxValue, self.direction
	-- "move" value range so that it starts at 0
	value, max = value - min, max - min
	local maxFillSize
	if (direction == "up" or direction == "down") then maxFillSize = y2 - y1
	else maxFillSize = x2 - x1 end
	local fillSize = maxFillSize - ((value / max) * maxFillSize)
	-- bail out if actual value < min value
	if fillSize >= maxFillSize then return end
	if fillSize > 0 then -- is actual value < max value?
		-- no "switch/case" construct in Lua :(
		if direction == "up" then y1 = y1 + fillSize
		elseif direction == "down" then y2 = y2 - fillSize
		elseif direction == "left" then x1 = x1 + fillSize
		elseif direction == "right" then x2 = x2 - fillSize end
	end
	r:rawRect(x1, y1, x2, y2, self.fillColor)
end

function draw:Gauge(description)
	description = (description or {})
	description.renderer = self
	if not description.borderColor then
		description.borderColor = self.gaugeBorderColor
	end
	setmetatable(description, ProtoGauge)
	return description
end

return draw
