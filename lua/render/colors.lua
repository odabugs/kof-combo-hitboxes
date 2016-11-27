local colors = {}
local bit = require("bit")

local function bandsl(value, mask, shift)
	return bit.lshift(bit.band(value, mask), shift)
end

function colors.rgba(r, g, b, a)
	a = (a or 0xFF)
	local result = bit.bor(
		bandsl(a, 0xFF, 24), -- alpha (mask 0xFF000000)
		bandsl(r, 0xFF, 16), -- red   (mask 0x00FF0000)
		bandsl(g, 0xFF, 8),  -- green (mask 0x0000FF00)
		bit.band(b, 0xFF))   -- blue  (mask 0x000000FF)
	return result
end
colors.rgb = colors.rgba

function colors.setAlpha(color, a)
	a = (a or 0xFF)
	local result = tonumber(color)
	result = bit.bor(bandsl(a, 0xFF, 24), bit.band(result, 0x00FFFFFF))
	return result
end

return colors
