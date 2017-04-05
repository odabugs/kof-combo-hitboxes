local ffi = require("ffi")
local types = require("winapi.types")
local winerror = require("winerror")
local winutil = {}
local checknz = winerror.checkNotZero

ffi.cdef[[
// workaround to avoid excess object creation with ffi.cast()
typedef union { intptr_t i; void *p; } ptrBuffer;

LRESULT WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT DefWindowProcW(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
VOID PostQuitMessage(int nExitCode);
HANDLE GetStdHandle(DWORD nStdHandle);
BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);
int WideCharToMultiByte(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCWSTR  lpWideCharStr,
	int      cchWideChar,
	LPSTR    lpMultiByteStr,
	int      cbMultiByte,
	LPCSTR   lpDefaultChar,
	LPBOOL   lpUsedDefaultChar);
int MultiByteToWideChar(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCSTR   lpMultiByteStr,
	int      cbMultiByte,
	LPWSTR   lpWideCharStr,
	int      cchWideChar);
]]
local C = ffi.C

-- using actual LPDWORD, LPPOINT, LPRECT etc. won't work with most
-- functions in the Win32 API (e.g., GetClientRect)
winutil.dwordBufType = ffi.typeof("DWORD[1]")
winutil.pointType = ffi.typeof("POINT")
winutil.pointBufType = ffi.typeof("POINT[1]")
winutil.rectType = ffi.typeof("RECT")
winutil.rectBufType = ffi.typeof("RECT[1]")
winutil.boolBufType = ffi.typeof("BOOL[1]")
winutil.ptrBufType = ffi.typeof("ptrBuffer")
winutil.wcsCType = ffi.typeof("WCHAR[?]")
winutil.wcsPtrCType = ffi.typeof("WCHAR*")
winutil.mbsCType = ffi.typeof("CHAR[?]")

winutil.charSize = ffi.sizeof("WCHAR")
winutil.defaultWCSBufferSize = 2048

-- window notifications
winutil.WM_DESTROY = 0x02

-- standard in/out/error handles used by Get/SetStdHandle()
winutil.STD_INPUT_HANDLE = ffi.cast("DWORD", -10)
winutil.STD_OUTPUT_HANDLE = ffi.cast("DWORD", -11)
winutil.STD_ERROR_HANDLE = ffi.cast("DWORD", -12)
winutil.INVALID_HANDLE_VALUE = ffi.cast("HANDLE", -1)

-- character encodings used by MB2WC/WC2MB
winutil.CP_UTF8 = 65001
winutil.CP = winutil.CP_UTF8 -- CP_* flags
winutil.MB = 0 -- MB_* flags
winutil.WC = 0 -- WC_* flags

winutil.ERROR_INSUFFICIENT_BUFFER = 122

function winutil.stringBufferLength(buffer)
	return (ffi.sizeof(buffer) / winutil.charSize)
end

function winutil.makeStringBuffer(n)
	local newN = (n > 0 and n or 255)
	local buffer = winutil.makeWCSBuffer(newN)
	return buffer, n
end

-- Accept and convert a WCHAR[?] or WCHAR* buffer to a Lua string.
-- Anything else passes through.
function winutil.mbs(ws)
	local CP, WC = winutil.CP, winutil.WC
	local wcs, wcsPtr = winutil.wcsCType, winutil.wcsPtrCType
	if ffi.istype(wcs, ws) or ffi.istype(wcsPtr, ws) then
		local sz = checknz(C.WideCharToMultiByte(
			CP, WC, ws, -1, nil, 0, nil, nil))
		local buf = winutil.mbsCType(sz)
		checknz(C.WideCharToMultiByte(CP, WC, ws, -1, buf, sz, nil, nil))
		return ffi.string(buf, sz - 1) -- sz includes null terminator
	else
		return ws
	end
end

-- WCS buffer constructor: Allocate a WCHAR[?] buffer and return the buffer
-- and its size in WCHARs, minus the null-terminator.
-- 1. Given a number "n", allocate a WCHAR buffer of size (n + 1).
-- 2. Given a WCHAR[?], return it along with its size in WCHARs minus the null terminator.
-- 3. Given no args, make a default-size buffer.
function winutil.makeWCSBuffer(n)
	local wcs = winutil.wcsCType
	if type(n) == 'number' then
		return wcs(n+1), n
	elseif ffi.istype(wcs, n) then
		return n, ffi.sizeof(n) / 2 - 1
	elseif n == nil then
		local sz = winutil.defaultWCSBufferSize
		return wcs(sz + 1), sz
	end
	--assert(false)
end

-- Accept and convert a UTF-8-encoded Lua string to a WCHAR[?] buffer.
-- Anything not a string passes through untouched.
-- Return the cdata and the size in WCHARs (not bytes) minus the null terminator.
function winutil.toWideChar(s)
	if type(s) ~= 'string' then return s end
	local sz = #s + 1 -- assume 1 byte per character + null terminator
	local wcs = winutil.wcsCType
	local buf = wcs(sz)
	local CP, MB = winutil.CP, winutil.MB
	sz = C.MultiByteToWideChar(CP, MB, s, #s + 1, buf, sz)
	if sz == 0 then
		if C.GetLastError() ~= ERROR_INSUFFICIENT_BUFFER then checknz(0) end
		sz = checknz(C.MultiByteToWideChar(CP, MB, s, #s + 1, nil, 0))
		buf = wcs(sz)
		sz = checknz(C.MultiByteToWideChar(CP, MB, s, #s + 1, buf, sz))
	end
	return buf, sz
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
