local luautil = require("luautil")
local colors = require("render.colors")
local ReadConfig = require("config")
local Game_Common = require("game.common")
local Game_Common_Extra = require("game.common_extra")
local KOF_Common = Game_Common:new({ whoami = "KOF_Common" })
luautil.extend(KOF_Common, Game_Common_Extra)

KOF_Common.buttonNames = { "A", "B", "C", "D" }

do
	local function handleRangeMarker(value, which, target)
		local oldValue = value -- for printing in error messages
		value = value:upper()
		if value == "NONE" then return false end
		local result, err
		local valueIndex = luautil.find(target.buttonNames, value)
		if valueIndex ~= nil then
			result = valueIndex - 1 -- we want this to start from 0
			target.drawRangeMarkers[which] = result
		else
			err = string.format(
				"Could not interpret '%s' as a range marker value.",
				oldValue)
		end
		return result, err
	end

	function KOF_Common:rangeMarkerReader(which, target)
		return function(value)
			return handleRangeMarker(value, which, self)
		end
	end
end

function KOF_Common:getConfigSchema()
	local function gaugeReader(key)
		return self:colorReader(key, self, "gaugeFillAlpha")
	end
	local schema = Game_Common.getConfigSchema(self)
	luautil.extend(schema.colors, {
		rangeMarker = self:colorReader("rangeMarkerColor"),
		activeRangeMarker = self:colorReader("activeRangeMarkerColor"),
		gaugeBorder = self:colorReader("gaugeBorderColor"),
		stunGauge = gaugeReader("stunGaugeColor"),
		stunRecoveryGauge = gaugeReader("stunRecoveryGaugeColor"),
		guardGauge = gaugeReader("guardGaugeColor"),
	})
	local booleanKeys = { "drawGauges" }
	local g = schema.global
	g.drawGauges = self:booleanReader("drawGauges")
	g.gaugeFillOpacity = self:byteReader("gaugeFillAlpha")
	for i = 1, 2 do
		local playerSchema = {
			drawRangeMarker = self:rangeMarkerReader(i),
		}
		local playerKey = "player" .. i
		schema[playerKey] = playerSchema
		schema[self.configSection][playerKey] = playerSchema
	end
	return schema
end

-- "renderFn" passed as parameter to BoxSet:render()
function KOF_Common.drawBox(hitbox, parent, drawBoxPivot, pivotSize, drawFill)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	local edge, fill = colorPair[1], (drawFill and colorPair[2]) or colors.CLEAR
	parent:box(x1, y1, x2, y2, edge, fill)
	if drawBoxPivot then
		parent:pivot(cx, cy, parent.boxPivotSize, edge)
	end
	return 1
end

-- "renderFn" passed as parameter to BoxList:render()
function KOF_Common.drawPivot(pivot, parent, pivotSize)
	parent:pivot(pivot.x, pivot.y, pivotSize, pivot.color)
	return 1
end

-- to be overridden by derived objects
function KOF_Common:facingMultiplier(player)
	return 1
end

-- in some games, this may disagree with the facing multiplier above,
-- so those games will need to override this function
function KOF_Common:rangeMarkerMultiplier(player)
	return self:facingMultiplier(player)
end

-- to be overridden by derived objects
function KOF_Common:getPlayerPosition(player)
	return 0, 0
end

function KOF_Common:drawRangeMarker(player, range, active)
	local originX, originY = self:getPlayerPosition(player)
	local rangeX = originX + (range * self:rangeMarkerMultiplier(player))
	local color = (active and self.activeRangeMarkerColor) or self.rangeMarkerColor
	originX, originY = self:worldToScreen(originX, originY)
	rangeX = (self:worldToScreen(rangeX, 0))
	self:horzLine(originX, rangeX, originY, color)
	self:vertLine(0, self.height + self.absoluteYOffset, rangeX, color)
end

-- expects "boxset" and "pivots" to be defined on derived objects
function KOF_Common:renderState()
	self.boxset:render(self.drawBox, self,
		self.drawBoxPivot, self.boxPivotSize, self.drawBoxFills)
	if self.drawPlayerPivot then
		self.pivots:render(self.drawPivot, self, self.pivotSize)
	end
end

return KOF_Common
