local colors = require("render.colors")
local Game_Common_Extra = {}

-- slot constructor function passed to BoxSet:new()
function Game_Common_Extra.boxSlotConstructor(i, slot, boxtypes)
	return {
		centerX = 0, centerY = 0, width = 0, height = 0,
		colorPair = boxtypes:colorForType(slot),
	}
end

-- slot constructor function passed to BoxList:new()
function Game_Common_Extra.pivotSlotConstructor()
	return { x = 0, y = 0, color = colors.WHITE }
end

-- "addFn" passed as parameter to BoxSet:add();
-- this function is responsible for actually writing the new box set entry
function Game_Common_Extra.addBox(target, parent, cx, cy, w, h)
	if w <= 0 or h <= 0 then return false end
	target.centerX, target.centerY = parent:worldToScreen(cx, cy)
	target.left,  target.top    = parent:worldToScreen(cx - w, cy - h)
	target.right, target.bottom = parent:worldToScreen(cx + w - 1, cy + h - 1)
	return true
end

-- "addFn" passed as parameter to BoxList:add()
function Game_Common_Extra.addPivot(target, color, x, y)
	target.color, target.x, target.y = color, x, y
	return true
end

return Game_Common_Extra
