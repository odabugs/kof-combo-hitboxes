local colors = require("render.colors")
local Boxtypes_Common = {}

local b_xx = "dummy"
local b_co = "collision"
local b_c  = "counter"
local b_v  = "vulnerable"
local b_vc = "counterVuln"
local b_va = "anywhereVuln"
local b_vo = "otgVuln"
local b_g  = "guard"
local b_a  = "attack"
local b_cl = "clash"
local b_pv = "projVuln"
local b_pa = "projAttack"
local b_tv = "throwable"
local b_t  = "throw"
local b_pr = "proximity"

Boxtypes_Common.idMask = 0xFF
Boxtypes_Common.defaultFillAlpha = 48
Boxtypes_Common.defaultEdgeColor = colors.BLACK
Boxtypes_Common.defaultFillColor = colors.setAlpha(
	Boxtypes_Common.defaultEdgeColor, Boxtypes_Common.defaultFillAlpha)
-- mapping of box type names to {edge color, fill color} tuples; "false" is
-- a placeholder, so that fill colors set manually here won't be overridden
Boxtypes_Common.colormap = {
	[b_xx] = { colors.CLEAR, colors.CLEAR },
	[b_co] = { colors.WHITE, false },
	[b_c]  = { colors.CYAN, false },
	[b_v]  = { colors.BLUE, false },
	[b_vc] = { colors.BLUE, false },
	[b_va] = { colors.BLUE, false },
	[b_vo] = { colors.BLUE, false },
	[b_g]  = { colors.CYAN, false },
	[b_a]  = { colors.RED, false },
	[b_cl] = { colors.BLACK, false },
	[b_pv] = { colors.GREEN, false },
	[b_pa] = { colors.YELLOW, false },
	[b_tv] = { colors.WHITE, false },
	[b_t]  = { colors.MAGENTA, false },
	[b_pr] = { colors.WHITE, false },
}

-- populate the fill color values in colormap above
for _, colorMapping in pairs(Boxtypes_Common.colormap) do
	if type(colorMapping[2]) ~= "number" then
		colorMapping[2] = colors.setAlpha(
			colorMapping[1], Boxtypes_Common.defaultFillAlpha)
	end
end

-- drawing layer order for different box types;
-- box types that appear later in this list will be drawn on top of those
-- that appear earlier in the list
Boxtypes_Common.order = {
	b_xx,
	b_co,
	b_v,
	b_vc,
	b_va,
	b_vo,
	b_c,
	b_g,
	b_a,
	b_cl,
	b_tv,
	b_t,
	b_pv,
	b_pa,
}
Boxtypes_Common.asProjectileMap = {
	[b_a]  = b_pa,
	[b_v]  = b_pv,
}

function Boxtypes_Common:new(source)
	source = (source or {})
	setmetatable(source, self)
	self.__index = self
	return source
end

function Boxtypes_Common:typeForID(id)
	return self[bit.band(id, self.idMask)]
end

function Boxtypes_Common:colorForType(boxtype)
	local result = self.colormap[boxtype]
	if result then
		return result[1], result[2]
	else
		return self.defaultEdgeColor, self.defaultFillColor
	end
end

function Boxtypes_Common:asProjectile(boxtype)
	return self.asProjectileMap[boxtype] or boxtype
end

return Boxtypes_Common
