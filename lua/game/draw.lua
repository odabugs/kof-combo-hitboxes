local window = require("window")
local colors = require("render.colors")
-- This class is not intended to be instantiated directly;
-- instead, use luautil.extend() to add its methods to a game class.
-- These methods expect the following to be defined on the calling object:
-- - basicWidth, basicHeight, width, height
-- - xOffset, yOffset, xScissor, yScissor, aspectMode
local draw = {}

-- all draw calls are shifted upward by this amount
draw.absoluteYOffset = 0
draw.useThickLines = false
draw.drawPlayerPivot = true
draw.pivotSize = 20
draw.drawBoxPivot = true
draw.boxPivotSize = 5
draw.pivotColor = colors.WHITE
draw.projectilePivotColor = colors.GREEN
draw.rangeMarkerColor = colors.GREEN

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

function draw:getColor()
	return self.directx.getColor()
end

function draw:setColor(newColor)
	return self.directx.setColor(newColor)
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
	return x, y
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

function draw:box(x1, y1, x2, y2, edgeColor, fillColor, thick)
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

	self.directx.hitbox(
		outerLeftX, outerTopY, outerRightX, outerBottomY,
		innerLeftX, innerTopY, innerRightX, innerBottomY,
		edgeColor, fillColor)
end

function draw:calculateScreenOffset(actual, baseline, scale)
	local scaled = math.floor(baseline * scale)
	if actual <= scaled then return 0
	else return math.floor((actual - scaled) * 0.5)
	end
end

function draw:adjustScaleAndAspect()
	self.xOffset, self.yOffset = 0, 0
	self.xScissor, self.yScissor = self.width, self.height
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

function draw:getGameWindowSize()
	window.getClientRect(self.gameHwnd, self.rectBuf)
	self.width, self.height = self.rectBuf[0].right, self.rectBuf[0].bottom
	self:adjustScaleAndAspect()
	local scissorWidth = self.width - (self.xOffset * 2)
	local scissorHeight = self.height - (self.yOffset * 2)
	self.directx.setScissor(scissorWidth, scissorHeight)
end

function draw:repositionOverlay()
	self:getGameWindowSize()
	window.move(
		self.overlayHwnd, self.gameHwnd,
		self.rectBuf, self.pointBuf,
		self.xOffset, self.yOffset,
		false) -- TODO: don't resize for now
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

return draw
