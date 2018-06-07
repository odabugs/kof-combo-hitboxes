local ffi = require("ffi")
local types = require("winapi.types")
local winerror = require("winerror")
local winutil = require("winutil")
local luautil = require("luautil")
local winprocess = {}

ffi.cdef[[
HANDLE OpenProcess(DWORD access, BOOL inherit, DWORD pid);
BOOL CloseHandle(HANDLE hObject);
BOOL ReadProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);
BOOL WriteProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);

// functions from psapi.dll
typedef union {
	HMODULE hmod;
	intptr_t value;
} hModulePtr;

BOOL EnumProcessModulesEx(
	HANDLE  hProcess,
	hModulePtr *lphModule, // out (cheating a little here with the union type)
	DWORD   cb,
	LPDWORD lpcbNeeded, // out
	DWORD   dwFilterFlag
);

DWORD GetModuleFileNameExW(
	HANDLE  hProcess,
	HMODULE hModule, // optional
	LPTSTR filename, // out
	DWORD nSize
);
]]
local C = ffi.C
local psapi = ffi.load("psapi")

-- bit masks for process access rights used by OpenProcess
winprocess.PROCESS_TERMINATE       = 0x0001
winprocess.PROCESS_CREATE_THREAD   = 0x0002
winprocess.PROCESS_VM_OPERATION    = 0x0008
winprocess.PROCESS_VM_READ         = 0x0010
winprocess.PROCESS_VM_WRITE        = 0x0020
winprocess.PROCESS_DUP_HANDLE      = 0x0040
winprocess.PROCESS_CREATE_PROCESS  = 0x0080
winprocess.PROCESS_SET_QUOTA       = 0x0100
winprocess.PROCESS_SET_INFORMATION = 0x0200
winprocess.PROCESS_QUERY_INFORMATION = 0x0400
winprocess.PROCESS_SUSPEND_RESUME  = 0x0800
winprocess.PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
local defaultRights = bit.bor(
	winprocess.PROCESS_VM_READ,
	--winprocess.PROCESS_VM_WRITE,
	winprocess.PROCESS_QUERY_INFORMATION)

-- nonstandard argument order, to facilitate default arguments
function winprocess.open(pid, access, inherit)
	inherit = luautil.asBoolean(inherit)
	access = access or defaultRights
	local handle = C.OpenProcess(access, inherit, pid)
	winerror.checkNotEqual(handle, NULL)
	return handle
end

function winprocess.close(handle)
	local result = C.CloseHandle(handle)
	winerror.checkNotZero(result)
	return result
end

-- expects a cdata of type "ptrBuffer" (winutil.lua) for address parameter
function winprocess.read(handle, address, buffer, n, bytesReadBuffer)
	local result = C.ReadProcessMemory(
		handle, address.p, buffer, n or ffi.sizeof(buffer),
		bytesReadBuffer or NULL)
	winerror.checkNotZero(result)
	return buffer, result
end

-- expects a cdata of type "ptrBuffer" (winutil.lua) for address parameter
function winprocess.write(handle, address, buffer, n, bytesWrittenBuffer)
	local result = C.WriteProcessMemory(
		handle, address.p, buffer, n or ffi.sizeof(buffer),
		bytesWrittenBuffer or NULL)
	winerror.checkNotZero(result)
	return buffer, result
end

function winprocess.getBaseAddress(handle)
	local hmodule, cb = ffi.new("hModulePtr[1]"), ffi.new("ULONG[1]")
	local result = psapi.EnumProcessModulesEx(
		handle, hmodule[0], ffi.sizeof("HMODULE"), cb, 0x3) -- LIST_HMODULES_ALL
	winerror.checkNotZero(result)
	return hmodule[0].value, cb[0]
end

function winprocess.listLoadedModules(handle, moduleNamesOnly)
	local modulesList = {}
	local maxModules, maxModuleNameLength = 1000, 1024
	local hmodules, cb = ffi.new("hModulePtr[" .. maxModules .. "]")
	local cb = ffi.new("ULONG[1]")
	local result = psapi.EnumProcessModulesEx(
		handle, hmodules, ffi.sizeof("HMODULE") * maxModules, cb, 0x3) -- LIST_HMODULES_ALL
	winerror.checkNotZero(result)
	local moduleCount = cb[0] / ffi.sizeof("HMODULE")
	if moduleCount > 0 then
		moduleCount = math.min(moduleCount, maxModules)
		local buffer = winutil.makeStringBuffer(maxModuleNameLength)
		local limit = winutil.stringBufferLength(buffer)
		for i = 0, moduleCount - 1 do
			result = psapi.GetModuleFileNameExW(
				-- silly, but it's the easiest way to get each HMODULE's value
				handle, ffi.cast("HMODULE", hmodules[i].value),
				ffi.cast("LPTSTR", buffer), limit)
			winerror.checkNotZero(result)
			local moduleName = winutil.mbs(buffer)
			-- module names returned by GetModuleFileNameEx normally
			-- contain the complete file path of the module .dll;
			-- if moduleNamesOnly is true, trim them down to the file name
			if moduleNamesOnly then
				local temp = moduleName
				for substr in string.gmatch(moduleName, "[^\\]+") do
					temp = substr
				end
				moduleName = temp
			end
			modulesList[moduleName] = true
		end
	end
	return modulesList
end

return winprocess
