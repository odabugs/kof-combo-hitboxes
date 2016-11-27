local window = {}
local ffi = require("ffi")
local winapi = require("winapi")
local winutil = require("winutil")
local luautil = require("luautil")
local winerror = require("winerror")

ffi.cdef[[
typedef struct tagWNDCLASSEX {
	UINT      cbSize;
	UINT      style;
	WNDPROC   lpfnWndProc;
	int       cbClsExtra;
	int       cbWndExtra;
	HINSTANCE hInstance;
	HICON     hIcon;
	HCURSOR   hCursor;
	HBRUSH    hbrBackground;
	LPCTSTR   lpszMenuName;
	LPCTSTR   lpszClassName;
	HICON     hIconSm;
} WNDCLASSEX, *PWNDCLASSEX;

typedef struct _MARGINS {
	int cxLeftWidth;
	int cxRightWidth;
	int cyTopHeight;
	int cyBottomHeight;
} MARGINS, *PMARGINS;

BOOL SetWindowTextW(HWND hWnd, LPCTSTR lpString);
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
BOOL IsWindowVisible(HWND hWnd);
BOOL UpdateWindow(HWND hWnd);
BOOL ShowWindow(HWND hWnd, int nCmdShow);
HDC GetDC(HWND hWnd);
ATOM RegisterClassExW(WNDCLASSEX *lpwCx);
HWND CreateWindowExW(
	DWORD dwExStyle,
	LPCTSTR lpClassName,  // optional
	LPCTSTR lpWindowName, // optional
	DWORD dwStyle,
	int x,
	int y,
	int nWidth,
	int nHeight,
	HWND hWndParent,      // optional
	HMENU hMenu,          // optional
	HINSTANCE hInstance,  // optional
	LPVOID lpParam);

// functions from dwmapi.dll (supported only in Windows Vista and newer)
HRESULT DwmIsCompositionEnabled(BOOL *pfEnabled);
HRESULT DwmExtendFrameIntoClientArea(HWND hwnd, MARGINS *pMarInset);
int GetSystemMetrics(int nIndex);
]]
local C = ffi.C
local dwmapi = ffi.load("dwmapi")

-- possible values for HRESULT returned by functions from dwmapi.dll
window.S_OK = 0
-- mode options for ShowWindow
window.SW_SHOWNORMAL = 1
-- bit masks for window class style options
window.CS_VREDRAW = 0x01
window.CS_HREDRAW = 0x02
-- bit masks for "non-extended" window style options
window.WS_POPUP = 0x80000000
-- bit masks for "extended" window style options
window.WS_EX_TOPMOST = 0x08
window.WS_EX_TRANSPARENT = 0x20
window.WS_EX_LAYERED = 0x00080000
window.WS_EX_COMPOSITED = 0x02000000
-- keys for GetSystemMetrics()
window.SM_CXSCREEN = 0
window.SM_CYSCREEN = 1

window.extendMargins = ffi.new("MARGINS[1]", {
	cxLeftWidth = -1,
	cxRightWidth = -1,
	cyTopHeight = -1,
	cyBottomHeight = -1,
})
function window.getDefaultTitle()
	return ffi.cast("LPCTSTR", winapi.wcs("KOF Combo Hitbox Viewer"))
end
window.defaultWindowTitle = window.getDefaultTitle()
window.defaultWindowClass = {
	cbSize = ffi.sizeof("WNDCLASSEX"),
	style = bit.bor(window.CS_HREDRAW, window.CS_VREDRAW),
	lpfnWndProc = ffi.new("WNDPROC", winutil.WindowProc),
	cbClsExtra = 0,
	cbWndExtra = 0,
	hInstance = NULL,
	hIcon = NULL,
	hCursor = NULL,
	hbrBackground = NULL,
	lpszMenuName = window.defaultWindowTitle,
	lpszClassName = window.defaultWindowTitle,
	hIconSm = NULL,
}
window.createWindowExDefaults = {
	dwExStyle = bit.bor(
		window.WS_EX_TOPMOST, window.WS_EX_TRANSPARENT,
		window.WS_EX_LAYERED, window.WS_EX_COMPOSITED),
	lpClassName = NULL,
	lpWindowName = NULL,
	dwStyle = window.WS_POPUP,
	x = 0,
	y = 0,
	nWidth = 300,
	nHeight = 300,
	hWndParent = NULL,
	hMenu = NULL,
	hInstance = NULL,
	lpParam = NULL,
}
-- use this with luautil.unpackKeys
window.createWindowExParamsOrder = {
	"dwExStyle",
	"lpClassName",
	"lpWindowName",
	"dwStyle",
	"x",
	"y",
	"nWidth",
	"nHeight",
	"hWndParent",
	"hMenu",
	"hInstance",
	"lpParam",
}

function window.console() return C.GetConsoleWindow() end
function window.foreground() return C.GetForegroundWindow() end
function window.desktop() return C.GetDesktopWindow() end
function window.isWindow(hwnd) return C.IsWindow(hwnd) ~= 0LL end
function window.isVisible(hwnd) return C.IsVisibleWindow(hwnd) ~= 0LL end
function window.isForeground(hwnd) return window.foreground() == hwnd end

-- return screen dimensions of the system's primary monitor
function window.getScreenSize()
	return {
		x = C.GetSystemMetrics(window.SM_CXSCREEN), -- width
		y = C.GetSystemMetrics(window.SM_CYSCREEN), -- height
	}
end

function window.update(hwnd)
	local result = C.UpdateWindow(hwnd)
	winerror.checkNotZero(result)
	return result
end

function window.show(hwnd, mode)
	mode = (mode or window.SW_SHOWNORMAL)
	local result = C.ShowWindow(hwnd, mode)
	return result ~= 0
end

function window.getDC(hwnd)
	local result = C.GetDC(hwnd)
	winerror.checkNotEqual(result, NULL)
	return result
end

function window.createOverlayWindow(hInstance, windowClass, windowOptions)
	local hi = { hInstance = hInstance }
	local newWinClass = luautil.extend({},
		window.defaultWindowClass,
		hi,
		windowClass)
	-- Surprise!  When you pass a table to initialize a FFI constructor
	-- like this, it uses rawget() to pull the values from that table
	--for k,v in pairs(newWinClass) do print(k,v) end
	local wndclassEx = ffi.new("WNDCLASSEX", newWinClass)
	local atom = C.RegisterClassExW(wndclassEx)
	winerror.checkNotZero(atom)

	local newWinOptions = luautil.extend({},
		window.createWindowExDefaults,
		hi,
		{ lpClassName = ffi.cast("LPCTSTR", bit.band(atom, 0xFFFF)) },
		windowOptions)
	local overlayHwnd = C.CreateWindowExW(
		luautil.unpackKeys(newWinOptions, window.createWindowExParamsOrder))
	winerror.checkNotEqual(overlayHwnd, NULL)
	-- strange things happen with the window title being set to gibberish
	-- if you don't explicitly use SetWindowTitle() after window creation
	local setResult = C.SetWindowTextW(overlayHwnd, window.getDefaultTitle())
	winerror.checkNotZero(setResult)

	if not window.supportsComposition() then
		error("Window composition support was not detected.\nPlease enable Windows Aero before using this program.")
	end
	window.extendFrame(overlayHwnd, window.extendMargins)
	window.show(overlayHwnd)
	window.update(overlayHwnd)
	return overlayHwnd
end

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
	-- returns 0 and leaves pidBuffer untouched if the call fails
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

-- returns true if Windows Aero is enabled (Vista/7), always true for 8+
function window.supportsComposition()
	local buffer = winutil.boolBufType()
	local result = dwmapi.DwmIsCompositionEnabled(buffer)
	winerror.checkEqual(result, window.S_OK)
	return buffer[0] ~= 0
end

function window.extendFrame(hwnd, margins)
	local result = dwmapi.DwmExtendFrameIntoClientArea(hwnd, margins)
	winerror.checkEqual(result, window.S_OK)
	return result
end

return window
