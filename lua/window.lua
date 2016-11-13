local window = {}
local ffi = require("ffi")
local winapi = require("winapi")
local winutil = require("winutil")
local winerror = require("winerror")

ffi.cdef[[
int GetWindowTextW(HWND hWnd, LPTSTR lpString, int nMaxCount);
int GetWindowTextLengthW(HWND hWnd);
DWORD GetWindowThreadProcessId(HWND hWnd, LPDWORD lpdwProcessId);
BOOL QueryFullProcessImageNameW(HANDLE hProcess, DWORD dwFlags, LPTSTR lpExeName, PDWORD lpdwSize);
HWND GetConsoleWindow(void);
HWND GetForegroundWindow(void);
HWND GetDesktopWindow(void);
BOOL GetClientRect(HWND hWnd, LPRECT lpRect);
BOOL ClientToScreen(HWND hWnd, LPPOINT lpPoint);
BOOL IsWindow(HWND hWnd);
]]
local C = ffi.C

function window.console() return C.GetConsoleWindow() end
function window.foreground() return C.GetForegroundWindow() end
function window.desktop() return C.GetDesktopWindow() end
function window.isWindow(hwnd) return C.IsWindow(hwnd) ~= 0LL end
function window.isForeground(hwnd) return window.foreground() == hwnd end

function window.getWindowTitle(hwnd, buffer)
	local titleLen = C.GetWindowTextLengthW(hwnd)
	winerror.checkNotZero(titleLen)
	buffer = (buffer or winutil.makeStringBuffer(titleLen))
	local limit = winutil.stringBufferLength(buffer)
	winerror.checkNotZero(C.GetWindowTextW(
		hwnd, ffi.cast("LPTSTR", buffer), limit))
	return winapi.mbs(buffer)
end

function window.getProcessImageName(hwnd, buffer, nBuffer)
	buffer = (buffer or winutil.makeStringBuffer(1024))
	nBuffer = (nBuffer or winutil.dwordBufType())
	nBuffer[0] = winutil.stringBufferLength(buffer)
	winerror.checkNotZero(C.QueryFullProcessImageNameW(
		hwnd, 0, ffi.cast("LPTSTR", buffer), nBuffer))
	return winapi.mbs(buffer)
end

-- returns both the parent PID (1st result) and parent thread (2nd result)
function window.getParentProcessID(hwnd, pidBuffer)
	pidBuffer = (pidBuffer or winutil.dwordBufType())
	-- according to MSDN comments, GetWindowThreadProcessId
	-- returns 0 and leaves parentPID untouched if the call fails
	local parentThread = C.GetWindowThreadProcessId(hwnd, pidBuffer)
	winerror.checkNotZero(parentThread)
	return (parentThread ~= 0 and pidBuffer[0]), parentThread
end

function window.getClientRect(hwnd, rectBuffer)
	rectBuffer = (rectBuffer or winutil.rectBufType())
	local result = C.GetClientRect(hwnd, rectBuffer)
	winerror.checkNotZero(result)
	return rectBuffer
end

function window.clientToScreen(hwnd, pointBuffer)
	pointBuffer = (pointBuffer or winutil.pointBufType())
	local result = C.ClientToScreen(hwnd, pointBuffer)
	winerror.checkNotZero(result)
	return pointBuffer
end

return window
