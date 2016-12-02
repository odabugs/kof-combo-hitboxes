local ffi = require("ffi")
local ffiutil = {}

-- returns the raw numeric address pointed to by a LuaJIT pointer-type cdata
function ffiutil.intptr(ptr)
	return tonumber(ffi.cast("intptr_t", ptr))
end

return ffiutil
