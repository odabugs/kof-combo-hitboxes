local ffi = require("ffi")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
local colors = require("render.colors")
-- This class is not intended to be instantiated directly;
-- instead, use luautil.extend() to add its methods to a game class.
-- These methods expect the following to be defined on the calling object:
-- - basicWidth, basicHeight, width, height
-- - xOffset, yOffset, aspectMode (TODO: NOT YET IMPLEMENTED)
-- - pivotSize (for draw:pivot())
local draw = {}

-- all draw calls are shifted upward by this amount (before scaling)
draw.absoluteYOffset = 0
draw.pivotSize = 20

function draw:getColor()
	return self.directx.getColor()
end

function draw:setColor(newColor)
	return self.directx.setColor(newColor)
end

function draw:ensureMinThickness(l, r)
	if l == r then
		return l, l + 1
	else
		return math.min(l, r), math.max(l, r)
	end
end

-- to be overridden by derived objects of Game_Common
function draw:scaleCoords(x, y)
	local newX = math.floor(x * self.xScale) + self.xOffset
	local newY = math.floor(y * self.yScale) + self.yOffset
	newY = newY - self.absoluteYOffset
	return newX, newY
end

function draw:rawRect(x1, y1, x2, y2, color)
	self.directx.rect(x1, y1, x2, y2, color)
end

function draw:rect(x1, y1, x2, y2, color)
	x1, y1 = self:scaleCoords(x1, y1)
	x2, y2 = self:scaleCoords(x2, y2)
	x1, x2 = self:ensureMinThickness(x1, x2)
	y1, y2 = self:ensureMinThickness(y1, y2)
	self:rawRect(x1, y1, x2, y2, color)
end

function draw:pivot(x, y, color)
	local p = self.pivotSize
	self:rect(x - p, y, x + p + 1, y, color)
	self:rect(x, y - p, x, y + p + 1, color)
end

function draw:box(x1, y1, x2, y2, color)
	local oldColor = self:getColor()
	color = (color or oldColor)
	x1, y1 = self:scaleCoords(x1, y1)
	x2, y2 = self:scaleCoords(x2, y2)
	x1, x2 = self:ensureMinThickness(x1, x2)
	y1, y2 = self:ensureMinThickness(y1, y2)

	self:setColor(colors.setAlpha(color, 255))
	-- draw left edge
	self:rawRect(x1, y1, x1 + 1, y2)
	-- draw right edge
	self:rawRect(x2 - 1, y1, x2, y2)
	-- draw top edge
	self:rawRect(x1 + 1, y1, x2 - 1, y1 + 1)
	-- draw bottom edge
	self:rawRect(x1 + 1, y2 - 1, x2 - 1, y2)
	-- draw fill
	self:setColor(colors.setAlpha(color, 128))
	self:rawRect(x1 + 1, y1 + 1, x2 - 1, y2 - 1)
	self:setColor(oldColor)
end

return draw
