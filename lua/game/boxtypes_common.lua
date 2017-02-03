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
Boxtypes_Common.defaultColor = colors.BLACK
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
Boxtypes_Common.colormap = {
	[b_xx] = colors.CLEAR,
	[b_co] = colors.WHITE,
	[b_c]  = colors.CYAN,
	[b_v]  = colors.BLUE,
	[b_vc] = colors.BLUE,
	[b_va] = colors.BLUE,
	[b_vo] = colors.BLUE,
	[b_g]  = colors.CYAN,
	[b_a]  = colors.RED,
	[b_cl] = colors.BLACK,
	[b_pv] = colors.GREEN,
	[b_pa] = colors.YELLOW,
	[b_tv] = colors.WHITE,
	[b_t]  = colors.MAGENTA,
	[b_pr] = colors.WHITE,
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
	return self.colormap[boxtype] or self.defaultColor
end

function Boxtypes_Common:asProjectile(boxtype)
	return self.asProjectileMap[boxtype] or boxtype
end

return Boxtypes_Common
