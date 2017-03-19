local luautil = {}

function luautil.collect(iterator, target)
	target = (target or {})
	for i in iterator do table.insert(target, i) end
	return target
end

function luautil.insertPairs(target, source)
	for k, v in pairs(source) do target[k] = v end
	return target
end

function luautil.asBoolean(predicate)
	return (predicate and true) or false
end

function luautil.stringEndsWith(str, key, plain)
	local start = -#key
	local result = string.find(str, key, start, luautil.asBoolean(plain))
	return result ~= nil
end

function luautil.identity(...)
	return ...
end

function luautil.unpackKeys(t, keys, i)
	i = (i or 1)
	local nextKey = keys[i]
	if nextKey ~= nil then
		return t[nextKey], luautil.unpackKeys(t, keys, i + 1)
	end
end

function luautil.extend(t, ...)
	t = (t or {})
	local current
	for i = 1, select("#", ...) do
		current = select(i, ...)
		if current ~= nil then
			for k, v in pairs(current) do t[k] = v end
		end
	end
	return t
end

function luautil.insertn(t, start, ...)
	t = (t or {})
	local n = start
	local current
	for i = 1, select("#", ...) do
		current = select(i, ...)
		t[n] = current
		--io.write("Inserting ", current, " at index ", n, " in ", tostring(t), "\n")
		n = n + 1
	end
	return t
end

function luautil.inserter(t, n)
	n = (n or 1)
	local f = luautil.insertn
	return function(...)
		local count = select("#", ...)
		local result = f(t, n, ...)
		n = n + count
		return t
	end
end

function luautil.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function luautil.contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then return true end
	end
	return false
end

function luautil.asInt(s)
	if (type(s) == "number") or (s:find("^[+-]?%d+$")) then return s + 0
	else return nil end
end

function luautil.selectSection(target, section, create)
	section = section:lower()
	for segment in section:gmatch("([%w_]+)(%.?)") do
		if target[segment] then
			target = target[segment]
		elseif create then
			target[segment] = {}
			target = target[segment]
		else
			return nil
		end
	end
	return target
end

return luautil
