local ffi = require("ffi")
local winapi = require("winapi")
local winerror = require("winerror")
local winutil = {}

ffi.cdef[[
// workaround to avoid excess object creation with ffi.cast()
typedef union { intptr_t i; void *p; } ptrBuffer;

LRESULT WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT DefWindowProcW(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
VOID PostQuitMessage(int nExitCode);
HANDLE GetStdHandle(DWORD nStdHandle);
BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);
]]
local C = ffi.C
winutil.ptrBufType = ffi.typeof("ptrBuffer")

-- using actual LPDWORD, LPPOINT, LPRECT etc. won't work with most
-- functions in the Win32 API (e.g., GetClientRect)
winutil.dwordBufType = ffi.typeof("DWORD[1]")
winutil.pointType = ffi.typeof("POINT")
winutil.pointBufType = ffi.typeof("POINT[1]")
winutil.rectType = ffi.typeof("RECT")
winutil.rectBufType = ffi.typeof("RECT[1]")
winutil.boolBufType = ffi.typeof("BOOL[1]")
-- winapi.wcs module uses WCHAR when you ask it for a char buffer via WCS()
winutil.charSize = ffi.sizeof("WCHAR")

-- window notifications
winutil.WM_DESTROY = 0x02

-- standard in/out/error handles used by Get/SetStdHandle()
winutil.STD_INPUT_HANDLE = ffi.cast("DWORD", -10)
winutil.STD_OUTPUT_HANDLE = ffi.cast("DWORD", -11)
winutil.STD_ERROR_HANDLE = ffi.cast("DWORD", -12)
winutil.INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1)

function winutil.stringBufferLength(buffer)
	return (ffi.sizeof(buffer) / winutil.charSize)
end

function winutil.makeStringBuffer(n)
	local newN = (n > 0 and n or 255)
	local buffer = winapi.WCS(newN)
	return buffer
end

function winutil.getStdHandle(stdHandle)
	return C.GetStdHandle(stdHandle)
end

function winutil.getStdin()
	return winutil.getStdHandle(winutil.STD_INPUT_HANDLE)
end

function winutil.getStdout()
	return winutil.getStdHandle(winutil.STD_OUTPUT_HANDLE)
end

function winutil.getStderr()
	return winutil.getStdHandle(winutil.STD_ERROR_HANDLE)
end

function winutil.flushConsoleInput(handle)
	handle = (handle or winutil.getStdin())
	local result = C.FlushConsoleInputBuffer(handle)
	winerror.checkNotZero(result)
	return result
end

function winutil.WindowProc(hwnd, message, wParam, lParam)
	if message == winutil.WM_DESTROY then
		C.PostQuitMessage(0)
	else
		return C.DefWindowProcW(hwnd, message, wParam, lParam)
	end
	return 0
end

return winutil
