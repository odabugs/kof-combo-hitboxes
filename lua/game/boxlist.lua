local ffiutil = require("ffiutil")
local BoxList = {}

function BoxList:new(slot, count, slotConstructor, ...)
	local result = ffiutil.ntypes(slotConstructor, count, 1, slot, ...)
	result.slot = slot
	result.count = count
	result.valid = 0 -- updated each time we add/remove an entry or reset

	setmetatable(result, self)
	self.__index = self
	return result
end

function BoxList:reset()
	self.valid = 0
end

function BoxList:add(addFn, ...)
	assert(self.valid < self.count, "Can't add more entries to this list!")
	local i = self.valid + 1
	local result = addFn(self[i], ...)
	if result then self.valid = i end
	return result
end

function BoxList:render(renderFn, ...)
	local boxesDrawn = 0
	for i = 1, self.valid do
		boxesDrawn = boxesDrawn + renderFn(self[i], ...)
	end
	return boxesDrawn
end

return BoxList
