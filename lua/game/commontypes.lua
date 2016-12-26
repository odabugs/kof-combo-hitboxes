local commontypes = {}

commontypes.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */
typedef int8_t byte;
typedef uint8_t ubyte;
typedef int16_t word;
typedef uint16_t uword;
typedef int32_t dword;
typedef uint32_t udword;

// 16.16 fixed point coordinate
typedef union {
	struct {
		uword part;           // +000h: Subpixels
		word whole;           // +002h: Whole pixels
	};
	dword value;              // +000h: Complete value
} fixed;
typedef struct { fixed x; fixed y; } fixedPair;
typedef struct { word x; word y; } coordPair;

#pragma pack(pop)
]]

function commontypes:new(source)
	source = (source or {})
	setmetatable(source, self)
	self.__index = self
	source.parent = self
	return source
end

-- pass an object returned by require("ffi") for the parameter here
function commontypes:export(target)
	if self.parent ~= nil then self.parent:export(target) end
	local myTypedefs = rawget(self, "typedefs")
	if myTypedefs ~= nil then target.cdef(myTypedefs) end
	return target
end

return commontypes
