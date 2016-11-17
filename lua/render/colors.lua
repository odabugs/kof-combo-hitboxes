local colors = {}
local bit = require("bit")
local ffi = require("ffi")
local types = require("winapi.types")

ffi.cdef[[
// D3DCOLOR internal format is 32-bit ARGB
typedef DWORD D3DCOLOR;
]]
local C = ffi.C
colors.colorType = ffi.typeof("D3DCOLOR")

-- not using a weak table here because we want to reduce GC frequency
local colorsMemo = {}

local function bandsl(value, mask, shift)
	return bit.lshift(bit.band(value, mask), shift)
end

function colors.raw(value)
	local toReturn = colorsMemo[value]
	if toReturn == nil then
		toReturn = colors.colorType(value)
		colorsMemo[value] = toReturn
	end
	return toReturn
end

function colors.rgba(r, g, b, a)
	a = (a or 0xFF)
	local result = bit.bor(
		bandsl(a, 0xFF, 24), -- alpha (mask 0xFF000000)
		bandsl(r, 0xFF, 16), -- red   (mask 0x00FF0000)
		bandsl(g, 0xFF, 8),  -- green (mask 0x0000FF00)
		bit.band(b, 0xFF))   -- blue  (mask 0x000000FF)
	return colors.raw(result)
end

function colors.setAlpha(color, a)
	a = (a or 0xFF)
	local value = tonumber(color)
	value = bit.bor(bandsl(a, 0xFF, 24), bit.band(value, 0x00FFFFFF))
	return colors.raw(value)
end

return colors
