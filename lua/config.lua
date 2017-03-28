local colors = require("render.colors")
local luautil = require("luautil")
local ReadConfig = {}

local trim, contains, asInt = luautil.trim, luautil.contains, luautil.asInt
local selectSection = luautil.selectSection

ReadConfig.yesValues = {"yes", "y", "true", "t", "on"}
ReadConfig.noValues = {"no", "n", "false", "f", "off"}

local INTEGER_PARSE_ERR = "Could not interpret '%s' as an integer value."
local BOOLEAN_PARSE_ERR = "Could not interpret '%s' as a yes/no value."
local COLOR_PARSE_ERR = "Could not interpret '%s' as a color value."
local BYTE_RANGE_ERR = "Value %d must be between 0 and 255 (inclusive)."
local INVALID_LINE_ERR = 
	"Line %d is not an option line or a section header, and will be skipped."
local ERRLINE = "Error on line %d: %s"

-- used by ReadConfig.parseColor()
local cp = "%s*%d+%s*"
local rgbPattern = string.format("^%%s*%%(%s,%s,%s%%)%%s*$", cp, cp, cp)
local rgbaPattern = string.format("^%%s*%%(%s,%s,%s,%s%%)%%s*$", cp, cp, cp, cp)

local function stripComment(s)
	local index = (s:find(";", 1, true))
	return (index and s:sub(1, index - 1)) or s
end

local function isSectionMarker(line)
	local l, r = line:find("^%s*%[[%w%._]+%]%s*$")
	return (l and r and line:sub(l + 1, r - 1)) or nil
end

local function isOptionLine(line)
	local l, r = line:find("^%s*[%w_]+%s*=.+$")
	if l and r then
		local eq = line:find("=", l, true)
		return trim(line:sub(1, eq - 1)), trim(line:sub(eq + 1))
	else
		return nil
	end
end

function ReadConfig.parseInteger(s)
	local result = asInt(s)
	if result then return result
	else return nil, string.format(INTEGER_PARSE_ERR, s) end
end

function ReadConfig.parseBoolean(s)
	s = s:lower()
	if contains(ReadConfig.yesValues, s) then return true
	elseif contains(ReadConfig.noValues, s) then return false
	else return nil, string.format(BOOLEAN_PARSE_ERR, s) end
end

function ReadConfig.parseDecimalByte(s)
	local result, err = ReadConfig.parseInteger(s)
	if err then return result, err
	elseif result >= 0 and result <= 255 then return result
	else return nil, string.format(BYTE_RANGE_ERR, result) end
end

function ReadConfig.parseColor(s)
	local hasAlpha
	if s:find(rgbPattern) then hasAlpha = false
	elseif s:find(rgbaPattern) then hasAlpha = true
	else return nil, string.format(COLOR_PARSE_ERR, s) end

	local f = s:gmatch("%d+")
	local r, g, b = f(), f(), f() -- each invocation returns next channel
	local a = (hasAlpha and f()) or 255
	local packed = { r, g, b, a }
	for i, rawValue in ipairs(packed) do
		local value, err = ReadConfig.parseDecimalByte(rawValue)
		if not err then packed[i] = value
		else return nil, err end -- bail out early on parse error
	end

	return { color = colors.rgba(unpack(packed)), hasAlpha = hasAlpha }, nil
end

function ReadConfig.readerGenerator(fn, target, targetKey, postprocess)
	postprocess = (postprocess or luautil.identity)
	return function(value, key)
		local result, err = fn(value, key, target)
		if not err then
			luautil.assign(target, targetKey, postprocess(result))
		end
		return result, err
	end
end

function ReadConfig.readPath(path, schema, target)
	local file, fileErr = io.open(path, "r")
	if file then return ReadConfig.readFile(file, schema, target)
	else return nil, fileErr end
end

-- schema dictates what config file structure to expect,
-- and the appropriate handler for each item in that structure
function ReadConfig.readFile(file, schema, target, sectionPrefix)
	local result = (target or {})
	sectionPrefix = (sectionPrefix and sectionPrefix .. ".") or ""
	local currentSection = "global" -- implicit "default" config section
	if not result[currentSection] then result[currentSection] = {} end
	local target = selectSection(
		result, sectionPrefix .. currentSection, true)
	local handler = selectSection(schema, currentSection, false)
	local i = 1 -- current line number

	for line in file:lines() do
		line = trim(stripComment(line))
		if line:len() > 0 then
			-- is the current line a section header?
			local sectionMarker = isSectionMarker(line)
			if sectionMarker then
				currentSection = sectionMarker
				target = selectSection(
					result, sectionPrefix .. currentSection, true)
				handler = selectSection(schema, currentSection, false)
			else
				local key, value = isOptionLine(line)
				if not key then
					print(string.format(INVALID_LINE_ERR, i))
				elseif handler and handler[key] then
					local result, err = handler[key](value, key)
					if not err then
						target[key] = result
					else
						print(string.format(ERRLINE, i, err))
					end
				end
			end
		end
		i = i + 1
	end

	file:close()
	return result
end

return ReadConfig
