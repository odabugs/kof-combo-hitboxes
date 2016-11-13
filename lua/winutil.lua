local winutil = {}
local ffi = require("ffi")
local winapi = require("winapi")

-- using actual LPDWORD, LPPOINT, LPRECT etc. won't work with most
-- functions in the Win32 API (e.g., GetClientRect)
winutil.dwordBufType = ffi.typeof("DWORD[1]")
winutil.pointType = ffi.typeof("POINT")
winutil.pointBufType = ffi.typeof("POINT[1]")
winutil.rectType = ffi.typeof("RECT")
winutil.rectBufType = ffi.typeof("RECT[1]")
-- winapi.wcs module uses WCHAR when you ask it for a char buffer via WCS()
winutil.charSize = ffi.sizeof("WCHAR")

function winutil.stringBufferLength(buffer)
	return (ffi.sizeof(buffer) / winutil.charSize)
end

function winutil.makeStringBuffer(n)
	local newN = (n > 0 and n or 255)
	local buffer = winapi.WCS(newN)
	return buffer
end

return winutil
