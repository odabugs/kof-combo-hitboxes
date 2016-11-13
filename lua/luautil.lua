local luautil = {}

function luautil.collect(iterator, target)
	local result = (target or {})
	for i in iterator do table.insert(result, i) end
	return result
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

return luautil
