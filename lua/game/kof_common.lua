local luautil = require("luautil")
local colors = require("render.colors")
local ReadConfig = require("config")
local Game_Common = require("game.common")
local KOF_Common = Game_Common:new({ whoami = "KOF_Common" })

KOF_Common.buttonNames = { "A", "B", "C", "D" }

function KOF_Common:getConfigSchema()
	local bt = self.boxtypes
	local result = {
		global = {
			boxEdgeOpacity = self:byteReader("defaultEdgeAlpha", bt),
			boxFillOpacity = self:byteReader("defaultFillAlpha", bt),
		},
		colors = {
			playerPivot = self:colorReader("pivotColor"),
			projectilePivot = self:colorReader("projectilePivotColor"),
			rangeMarker = self:colorReader("rangeMarkerColor"),
			activeRangeMarker = self:colorReader("activeRangeMarkerColor"),
			gaugeBorder = self:colorReader("gaugeBorderColor"),
			stunGauge = self:colorReader("stunGaugeColor"),
			stunRecoveryGauge = self:colorReader("stunRecoveryGaugeColor"),
			guardGauge = self:colorReader("guardGaugeColor"),
		},
	}
	local booleanKeys = {
		"drawPlayerPivot", "drawBoxPivot", "drawGauges",
	}
	for _, booleanKey in ipairs(booleanKeys) do
		result.global[booleanKey] = self:booleanReader(booleanKey)
	end
	for colorKey in pairs(bt.colorConfigNames) do
		result.colors[colorKey] = self:hitboxColorReader(colorKey)
	end
	-- duplicating the schema sections and nesting them under the game's
	-- config section name permits INI files to have game-specific sections
	result[self.configSection] = luautil.extend({}, result)
	return result
end

-- slot constructor function passed to BoxSet:new()
function KOF_Common.boxSlotConstructor(i, slot, boxtypes)
	return {
		centerX = 0, centerY = 0, width = 0, height = 0,
		colorPair = boxtypes:colorForType(slot),
	}
end

-- slot constructor function passed to BoxList:new()
function KOF_Common.pivotSlotConstructor()
	return { x = 0, y = 0, color = colors.WHITE }
end

-- "addFn" passed as parameter to BoxSet:add();
-- this function is responsible for actually writing the new box set entry
function KOF_Common.addBox(target, parent, cx, cy, w, h)
	if w <= 0 or h <= 0 then return false end
	target.centerX, target.centerY = parent:worldToScreen(cx, cy)
	target.left,  target.top    = parent:worldToScreen(cx - w, cy - h)
	target.right, target.bottom = parent:worldToScreen(cx + w - 1, cy + h - 1)
	return true
end

-- "addFn" passed as parameter to BoxSet:add()
function KOF_Common.addPivot(target, color, x, y)
	target.color, target.x, target.y = color, x, y
	return true
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
