local ffi = require("ffi")
local types = require("winapi.types")
local hotkey = {}

ffi.cdef[[
SHORT GetKeyState(int vKey);
SHORT GetAsyncKeyState(int vKey);
]]
local C = ffi.C
local KEY_DOWN = bit.lshift(1, 15)
local KEY_TOGGLED = 1
local KEY_PRESSED = bit.bor(KEY_DOWN, KEY_TOGGLED)

function hotkey.down(vk)
	local result = C.GetAsyncKeyState(vk)
	return bit.band(result, KEY_DOWN) ~= 0
end

function hotkey.up(vk)
	local result = C.GetAsyncKeyState(vk)
	return bit.band(result, KEY_DOWN) == 0
end

function hotkey.pressed(vk)
	local result = C.GetAsyncKeyState(vk)
	if bit.band(result, KEY_DOWN) == 0 then return false end
	if bit.band(result, KEY_TOGGLED) == 0 then return false end
	return true
end

function hotkey.released(vk)
	local result = C.GetAsyncKeyState(vk)
	if bit.band(result, KEY_DOWN) ~= 0 then return false end
	if bit.band(result, KEY_TOGGLED) == 0 then return false end
	return true
end

do
	-- add virtual key code constants for the A...Z letter keys
	local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for c in string.gmatch(letters, ".") do
		hotkey["VK_" .. c] = string.byte(c)
	end

	-- add virtual key code constants for the F1...F24 function keys
	local VK_F0 = 0x6F -- NOT a valid virtual key constant
	for i=1,24 do
		hotkey["VK_F" .. i] = VK_F0 + i
	end

	-- add virtual key code constants for the 1-9 digit keys
	-- (both on the row above the letter keys and on the numpad)
	local topRowBase = 0x30
	local numPadBase = 0x60
	for i=0,9 do
		hotkey["VK_" .. i] = topRowBase + i
		hotkey["VK_NUMPAD" .. i] = numPadBase + i
	end
end

return hotkey
