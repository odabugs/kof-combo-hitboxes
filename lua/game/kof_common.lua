local luautil = require("luautil")
local colors = require("render.colors")
local ReadConfig = require("config")
local KOF_Common = {}

local function readerGenerator(fn, target, targetKey, postprocess)
	print(targetKey)
	postprocess = (postprocess or luautil.identity)
	return function(value, key)
		local result, err = fn(value, key)
		if not err then
			luautil.assign(target, targetKey, postprocess(result))
		end
		return result, err
	end
end

function KOF_Common:getConfigSchema()
	local bt = self.boxtypes
	local function readBoxColor(value, key)
		local newColor, err = ReadConfig.parseColor(value)
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

	local function partialReader(fn, postprocess)
		local defaultTarget = self
		return function(targetKey, target)
			return readerGenerator(
				fn, (target or defaultTarget), targetKey, postprocess)
		end
	end
	local singleColorReader = partialReader(
		ReadConfig.parseColor, function(newColor)
			return newColor.color
		end)
	local booleanReader = partialReader(ReadConfig.parseBoolean)
	local byteReader = partialReader(ReadConfig.parseDecimalByte)

	local result = {
		global = {
			boxEdgeOpacity = byteReader("defaultEdgeAlpha", bt),
			boxFillOpacity = byteReader("defaultFillAlpha", bt),
		},
		-- TODO: drawRangeMarker options for each player
		colors = {
			playerPivot = singleColorReader("pivotColor"),
			projectilePivot = singleColorReader("projectilePivotColor"),
			--rangeMarker = singleColorReader("rangeMarkerColor"), -- TODO
		},
	}
	local booleanKeys = {
		"drawPlayerPivot", "drawBoxPivot", --"drawGauges", -- TODO
	}
	for _, booleanKey in ipairs(booleanKeys) do
		result.global[booleanKey] = booleanReader(booleanKey)
	end
	for colorKey in pairs(bt.colorConfigNames) do
		result.colors[colorKey] = readBoxColor
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
function KOF_Common.drawBox(hitbox, parent, drawBoxPivot, pivotSize)
	local cx, cy = hitbox.centerX, hitbox.centerY
	local x1, y1 = hitbox.left, hitbox.top
	local x2, y2 = hitbox.right, hitbox.bottom
	local colorPair = hitbox.colorPair
	parent:box(x1, y1, x2, y2, colorPair[1], colorPair[2])
	if drawBoxPivot then
		parent:pivot(cx, cy, parent.boxPivotSize, colorPair[1])
	end
	return 1
end

-- "renderFn" passed as parameter to BoxList:render()
function KOF_Common.drawPivot(pivot, parent, pivotSize)
	parent:pivot(pivot.x, pivot.y, pivotSize, pivot.color)
	return 1
end

function KOF_Common:renderState()
	self.boxset:render(self.drawBox, self,
		self.drawBoxPivot, self.boxPivotSize)
	if self.drawPlayerPivot then
		self.pivots:render(self.drawPivot, self, self.pivotSize)
	end
end

return KOF_Common
