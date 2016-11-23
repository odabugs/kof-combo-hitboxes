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

return luautil
