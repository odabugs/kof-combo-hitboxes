local colors = require("render.colors")
local Boxtypes_Common = {}

Boxtypes_Common.asProjectileMap = {}
Boxtypes_Common.colormap = {}
Boxtypes_Common.idMask = 0xFF
Boxtypes_Common.defaultColor = colors.BLACK

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
