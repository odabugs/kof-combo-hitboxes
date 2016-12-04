local ffi = require("ffi")
local ffiutil = {}

-- returns the raw numeric address pointed to by a LuaJIT pointer-type cdata
function ffiutil.intptr(ptr)
	return tonumber(ffi.cast("intptr_t", ptr))
end

function ffiutil.ntypes(t, n, start)
	start = (start or 1)
	local result = {}
	for i = start, (start + n) - 1 do
		result[i] = ffi.new(t)
	end
	return result
end

return ffiutil
