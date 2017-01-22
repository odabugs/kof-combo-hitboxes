local ffi = require("ffi")
local ffiutil = {}

-- returns the raw numeric address pointed to by a LuaJIT pointer-type cdata
function ffiutil.intptr(ptr)
	return tonumber(ffi.cast("intptr_t", ptr))
end

-- t may be a string (passed to ffi.new()), or a function that returns an
-- object when called
function ffiutil.ntypes(t, n, start, ...)
	if type(t) == "string" then
		local typename = t
		t = function() return ffi.new(typename) end
	elseif type(t) ~= "function" then
		error("Parameter \"t\" must be a string or a function.")
	end

	start = (start or 1)
	local result = {}
	for i = start, (start + n) - 1 do
		result[i] = t(i, ...)
	end
	return result
end

return ffiutil
