local BoxList = require("game.boxlist")
local BoxSet = {}

function BoxSet:new(order, countPerLayer, slotConstructor, ...)
	local numLayers = #order
	local result = {
		order = order,
		numLayers = numLayers,
		countPerLayer = countPerLayer,
		totalCount = numLayers * countPerLayer,
	}
	local slotToAdd, key
	for i = 1, numLayers do
		key = order[i]
		slotToAdd = BoxList:new(key, countPerLayer, slotConstructor, ...)
		-- each box list is stored at two table locations;
		-- the hash slot is used by BoxSet:add(),
		-- while the array entry is used when iterating over all slots
		result[key] = slotToAdd
		result[i] = slotToAdd
	end

	setmetatable(result, self)
	self.__index = self
	return result
end

function BoxSet:reset()
	for i = 1, self.numLayers do
		self[i]:reset()
	end
end

function BoxSet:add(slot, addFn, ...)
	self[slot]:add(addFn, ...)
end

function BoxSet:render(renderFn, ...)
	local boxesDrawn = 0
	for i = 1, self.numLayers do
		boxesDrawn = boxesDrawn + self[i]:render(renderFn, ...)
	end
	return boxesDrawn
end

return BoxSet
