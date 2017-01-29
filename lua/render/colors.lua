local colors = {}

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

local c = colors.rgb
colors.CLEAR       = c(000, 000, 000, 000)
colors.WHITE       = c(255, 255, 255)
colors.BLACK       = c(000, 000, 000)
colors.RED         = c(255, 000, 000)
colors.GREEN       = c(000, 255, 000)
colors.BLUE        = c(000, 000, 255)
colors.YELLOW      = c(255, 255, 000)
colors.MAGENTA     = c(255, 000, 255)
colors.CYAN        = c(000, 255, 255)

return colors
