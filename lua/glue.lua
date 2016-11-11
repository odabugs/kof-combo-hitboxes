
--glue: everyday Lua functions.
--Written by Cosmin Apreutesei. Public domain.

if not ... then require'glue_test'; return end

local glue = {}

local select, pairs, tonumber, tostring, unpack, xpcall, assert =
      select, pairs, tonumber, tostring, unpack, xpcall, assert
local getmetatable, setmetatable, type, pcall =
      getmetatable, setmetatable, type, pcall
local sort, format, byte, char, min, max =
      table.sort, string.format, string.byte, string.char, math.min, math.max

function glue.clamp(x, x0, x1)
	return min(max(x, x0), x1)
end

function glue.pack(...)
	return {n = select('#', ...), ...}
end

function glue.unpack(t, i, j)
	return unpack(t, i or 1, j or t.n or #t)
end

--count the number of keys in table.
function glue.count(t, maxn)
	local n = 0
	if maxn then
		for _ in pairs(t) do
			n = n + 1
			if n >= maxn then break end
		end
	else
		for _ in pairs(t) do
			n = n + 1
		end
	end
	return n
end

--reverse keys with values.
function glue.index(t)
	local dt={}
	for k,v in pairs(t) do dt[v]=k end
	return dt
end

--list of keys, optionally sorted.
function glue.keys(t, cmp)
	local dt={}
	for k in pairs(t) do
		dt[#dt+1]=k
	end
	if cmp == true then
		sort(dt)
	elseif cmp then
		sort(dt, cmp)
	end
	return dt
end

--stateless pairs() that iterate elements in key order.
local keys = glue.keys
function glue.sortedpairs(t, cmp)
	local kt = keys(t, cmp or true)
	local i = 0
	return function()
		i = i + 1
		return kt[i], t[kt[i]]
	end
end

--update a table with the contents of other table(s).
function glue.update(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t ~= nil then
			for k,v in pairs(t) do dt[k]=v end
		end
	end
	return dt
end

--add the contents of other table(s) without overwrite.
function glue.merge(dt,...)
	for i=1,select('#',...) do
		local t=select(i,...)
		if t ~= nil then
			for k,v in pairs(t) do
				if dt[k] == nil then dt[k]=v end
			end
		end
	end
	return dt
end

--scan list for value.
function glue.indexof(v, t)
	for i=1,#t do
		if t[i] == v then
			return i
		end
	end
end

--extend a list with the elements of other lists.
function glue.extend(dt,...)
	for j=1,select('#',...) do
		local t=select(j,...)
		if t ~= nil then
			for i=1,#t do dt[#dt+1]=t[i] end
		end
	end
	return dt
end

--append non-nil arguments to a list.
function glue.append(dt,...)
	for i=1,select('#',...) do
		dt[#dt+1] = select(i,...)
	end
	return dt
end

local tinsert, tremove = table.insert, table.remove

--insert n elements at i, shifting elemens on the right of i (i inclusive)
--to the right.
local function insert(t, i, n)
	if n == 1 then --shift 1
		tinsert(t, i, t[i])
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive)
--to the left.
local function remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		tremove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--shift all the elements to the right of i (i inclusive) to the left
--or further to the right.
function glue.shift(t, i, n)
	if n > 0 then
		insert(t, i, n)
	elseif n < 0 then
		remove(t, i, -n)
	end
	return t
end

--reverse elements of a list in place.
function glue.reverse(t)
	local len = #t+1
	for i = 1, (len-1)/2 do
		t[i], t[len-i] = t[len-i], t[i]
	end
	return t
end

--string submodule. has its own namespace which can be merged with _G.string.
glue.string = {}

--split a string by a separator that can be a pattern or a plain string.
--return a stateless iterator for the pieces.
local function iterate_once(s, s1)
	return s1 == nil and s or nil
end
function glue.string.gsplit(s, sep, start, plain)
	start = start or 1
	plain = plain or false
	if not s:find(sep, start, plain) then
		return iterate_once, s
	end
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true return s end
		return pass(s:find(sep, start, plain))
	end
end

--string trim12 from lua wiki.
function glue.string.trim(s)
	local from = s:match('^%s*()')
	return from > #s and '' or s:match('.*%S', from)
end

--escape a string so that it can be taken literally inside a pattern.
local function format_ci_pat(c)
	return format('[%s%s]', c:lower(), c:upper())
end
function glue.string.escape(s, mode)
	s = s:gsub('%%','%%%%'):gsub('%z','%%z')
		:gsub('([%^%$%(%)%.%[%]%*%+%-%?])', '%%%1')
	if mode == '*i' then s = s:gsub('[%a]', format_ci_pat) end
	return s
end

--string to hex.
function glue.string.tohex(s, upper)
	if type(s) == 'number' then
		return format(upper and '%08.8X' or '%08.8x', s)
	end
	if upper then
		return (s:gsub('.', function(c)
		  return format('%02X', byte(c))
		end))
	else
		return (s:gsub('.', function(c)
		  return format('%02x', byte(c))
		end))
	end
end

--hex to string.
function glue.string.fromhex(s)
	return (s:gsub('..', function(cc)
	  return char(tonumber(cc, 16))
	end))
end

--publish the string submodule in the glue namespace.
glue.update(glue, glue.string)

--run an iterator and collect the n-th return value into a list.
local function select_at(i,...)
	return ...,select(i,...)
end
local function collect_at(i,f,s,v)
	local t = {}
	repeat
		v,t[#t+1] = select_at(i,f(s,v))
	until v == nil
	return t
end
local function collect_first(f,s,v)
	local t = {}
	repeat
		v = f(s,v); t[#t+1] = v
	until v == nil
	return t
end
function glue.collect(n,...)
	if type(n) == 'number' then
		return collect_at(n,...)
	else
		return collect_first(n,...)
	end
end

--no-op filter.
function glue.pass(...) return ... end

--set up dynamic inheritance by creating or updating a table's metatable.
function glue.inherit(t, parent)
	local meta = getmetatable(t)
	if meta then
		meta.__index = parent
	elseif parent ~= nil then
		setmetatable(t, {__index = parent})
	end
	return t
end

--get the value of a table field, and if the field is not present in the
--table, create it as an empty table, and return it.
function glue.attr(t, k, v0)
	local v = t[k]
	if v == nil then
		if v0 == nil then
			v0 = {}
		end
		v = v0
		t[k] = v
	end
	return v
end

--set up a table so that missing keys are created automatically as autotables.
local autotable
local auto_meta = {
	__index = function(t, k)
		t[k] = autotable()
		return t[k]
	end,
}
function autotable(t)
	t = t or {}
	local meta = getmetatable(t)
	if meta then
		assert(not meta.__index or meta.__index == auto_meta.__index,
			'__index already set')
		meta.__index = auto_meta.__index
	else
		setmetatable(t, auto_meta)
	end
	return t
end
glue.autotable = autotable

--check if a file exists and can be opened for reading or writing.
function glue.canopen(name, mode)
	local f = io.open(name, mode or 'rb')
	if f then f:close() end
	return f ~= nil and name or nil
end

glue.fileexists = glue.canopen --for backwards compat.

--read a file into a string (in binary mode by default).
function glue.readfile(name, mode, open)
	open = open or io.open
	local f, err = open(name, mode=='t' and 'r' or 'rb')
	if not f then return nil, err end
	local s, err = f:read'*a'
	if s == nil then return nil, err end
	f:close()
	return s
end

--read the output of a command into a string.
function glue.readpipe(cmd, mode, open)
	return glue.readfile(cmd, mode, open or io.popen)
end

--write a string, number, or table to a file (in binary mode by default).
--if the write fails, the file is removed and an error is raised.
function glue.writefile(filename, s, mode)
	local f, err = io.open(filename, mode=='t' and 'w' or 'wb')
	if not f then
		error(err)
	end
	local function check(ret, err)
		if ret ~= nil then return ret, err end
		f:close()
		local ret, err2 = os.remove(filename)
		if ret == nil then
			err = err .. '\n' .. err2
		end
		error(err, 2)
	end
	if type(s) == 'table' then
		for i = 1, #s do
			check(f:write(s[i]))
		end
	elseif type(s) == 'function' then
		while true do
			local _, s1 = check(xpcall(s, debug.traceback))
			if not s1 then break end
			check(f:write(s1))
		end
	else
		check(f:write(s))
	end
	f:close()
end

--assert() with string formatting (this should be a Lua built-in).
function glue.assert(v, err, ...)
	if v then return v,err,... end
	err = err or 'assertion failed!'
	if select('#',...) > 0 then err = format(err,...) end
	error(err, 2)
end

--pcall with traceback. LuaJIT and Lua 5.2 only.
local function pcall_error(e)
	return tostring(e) .. '\n' .. debug.traceback()
end
function glue.pcall(f, ...)
	return xpcall(f, pcall_error, ...)
end

local function unprotect(ok, result, ...)
	if not ok then return nil, result, ... end
	if result == nil then result = true end --to distinguish from error.
	return result, ...
end

--wrap a function that raises errors on failure into a function that follows
--the Lua convention of returning nil,err on failure.
function glue.protect(func)
	return function(...)
		return unprotect(pcall(func, ...))
	end
end

--pcall with finally and except "clauses":
--		local ret,err = fpcall(function(finally, except)
--			local foo = getfoo()
--			finally(function() foo:free() end)
--			except(function(err) io.stderr:write(err, '\n') end)
--		emd)
--NOTE: a bit bloated at 2 tables and 4 closures. Can we reduce the overhead?
local function fpcall(f,...)
	local fint, errt = {}, {}
	local function finally(f) fint[#fint+1] = f end
	local function onerror(f) errt[#errt+1] = f end
	local function err(e)
		for i=#errt,1,-1 do errt[i](e) end
		for i=#fint,1,-1 do fint[i]() end
		return tostring(e) .. '\n' .. debug.traceback()
	end
	local function pass(ok,...)
		if ok then
			for i=#fint,1,-1 do fint[i]() end
		end
		return ok,...
	end
	return pass(xpcall(f, err, finally, onerror, ...))
end

function glue.fpcall(...)
	return unprotect(fpcall(...))
end

--fcall is like fpcall() but without the protection (i.e. raises errors).
local function assert_fpcall(ok, ...)
	if not ok then error(..., 2) end
	return ...
end
function glue.fcall(...)
	return assert_fpcall(fpcall(...))
end

--memoize for 1 and 2-arg and vararg and 1 retval functions.
--NOTE: cache layouts differ for each type of memoization.
--NOTE: vararg functions require the tuple module.
local function memoize0(func) --for strict no-arg functions
	local v, hasv
	return function()
		if not hasv then
			v, hasv = func(), true
		end
		return v
	end
end
local NIL = {}
local NAN = {}
local function memoize1(func, cache) --for strict single-arg functions
	cache = cache or {}
	return function(k)
		local sk = k ~= k and NAN or k == nil and NIL or k
		local v = cache[sk]
		if v == nil then
			v = func(k)
			cache[sk] = v == nil and NIL or v
		else
			if v == NIL then v = nil end
		end
		return v
	end
end
local function memoize2(func, cache) --for strict two-arg functions
	cache = cache or {}
	return function(k1, k2)
		local sk1 = k1 ~= k1 and NAN or k1 == nil and NIL or k1
		local cache2 = cache[sk1]
		if cache2 == nil then
			cache2 = {}
			cache[sk1] = cache2
		end
		local sk2 = k2 ~= k2 and NAN or k2 == nil and NIL or k2
		local v = cache2[sk2]
		if v == nil then
			v = func(k1, k2)
			cache2[sk2] = v == nil and NIL or v
		else
			if v == NIL then v = nil end
		end
		return v
	end
end
local function memoize_vararg(func, narg, ...) --for vararg functions
	local tuple = require'tuple'.space(true, ...)
	local cache = {}
	return function(...)
		local n = max(narg, select('#', ...))
		local k = tuple.narg(n, ...)
		local v = cache[k]
		if not v then
			v = func(k())
			cache[k] = v
		end
		return v
	end
end
local memoize_narg = {[0] = memoize0, memoize1, memoize2}
function glue.memoize(func, ...)
	local info = debug.getinfo(func)
	local memoize_narg = memoize_narg[info.nparams]
	if info.isvararg or not memoize_narg then
		return memoize_vararg(func, info.nparams, ...)
	else
		return memoize_narg(func, ...)
	end
end

--setup a module to load sub-modules when accessing specific keys.
function glue.autoload(t, k, v)
	local mt = getmetatable(t) or {}
	if not mt.__autoload then
		if mt.__index then
			error('__index already assigned for something else')
		end
		local submodules = {}
		mt.__autoload = submodules
		mt.__index = function(t, k)
			if submodules[k] then
				if type(submodules[k]) == 'string' then
					require(submodules[k]) --module
				else
					submodules[k](k) --custom loader
				end
				submodules[k] = nil --prevent loading twice
			end
			return rawget(t, k)
		end
		setmetatable(t, mt)
	end
	if type(k) == 'table' then
		glue.update(mt.__autoload, k) --multiple key -> module associations.
	else
		mt.__autoload[k] = v --single key -> module association.
	end
	return t
end

--portable way to get script's directory, based on arg[0].
--NOTE: the path is not absolute, but relative to the current directory!
--NOTE: for bundled executables, this returns the executable's directory.
local dir = rawget(_G, 'arg') and arg[0] and arg[0]:gsub('[/\\]?[^/\\]+$', '') or '' --remove file name
glue.bin = dir == '' and '.' or dir

--portable way to add more paths to package.path, at any place in the list.
--negative indices count from the end of the list like string.sub(). index 'after' means 0.
function glue.luapath(path, index, ext)
	ext = ext or 'lua'
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local paths = glue.collect(glue.gsplit(package.path, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. psep .. 'init.' .. ext)
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.path = table.concat(paths, tsep)
end

--portable way to add more paths to package.cpath, at any place in the list.
--negative indices count from the end of the list like string.sub(). index 'after' means 0.
function glue.cpath(path, index)
	index = index or 1
	local psep = package.config:sub(1,1) --'/'
	local tsep = package.config:sub(3,3) --';'
	local wild = package.config:sub(5,5) --'?'
	local ext = package.cpath:match('%.([%a]+)%'..tsep..'?') --dll | so | dylib
	local paths = glue.collect(glue.gsplit(package.cpath, tsep, nil, true))
	path = path:gsub('[/\\]', psep) --normalize slashes
	if index == 'after' then index = 0 end
	if index < 1 then index = #paths + 1 + index end
	table.insert(paths, index,  path .. psep .. wild .. '.' .. ext)
	package.cpath = table.concat(paths, tsep)
end

if jit then

local ffi = require'ffi'

ffi.cdef[[
	void* malloc (size_t size);
	void  free   (void*);
]]

function glue.malloc(ctype, size)
	if type(ctype) == 'number' then
		ctype, size = 'char', ctype
	end
	local ctype = ffi.typeof(ctype or 'char')
	local ctype = size and ffi.typeof('$(&)[$]', ctype, size) or ffi.typeof('$&', ctype)
	local bytes = ffi.sizeof(ctype)
	local data  = ffi.cast(ctype, ffi.C.malloc(bytes))
	assert(data ~= nil, 'out of memory')
	ffi.gc(data, glue.free)
	return data
end

function glue.free(cdata)
	ffi.gc(cdata, nil)
	ffi.C.free(cdata)
end

local intptr_ct = ffi.typeof'intptr_t'
local intptrptr_ct = ffi.typeof'const intptr_t*'
local intptr1_ct = ffi.typeof'intptr_t[1]'
local voidptr_ct = ffi.typeof'void*'

--x86: convert a pointer's address to a Lua number.
local function addr32(p)
	return tonumber(ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p)))
end

--x86: convert a number to a pointer, optionally specifying a ctype.
local function ptr32(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	return ffi.cast(ctype, addr)
end

--x64: convert a pointer's address to a Lua number or possibly string.
local function addr64(p)
	local np = ffi.cast(intptr_ct, ffi.cast(voidptr_ct, p))
   local n = tonumber(np)
	if ffi.cast(intptr_ct, n) ~= np then
		--address too big (ASLR? tagged pointers?): convert to string.
		return ffi.string(intptr1_ct(np), 8)
	end
	return n
end

--x64: convert a number or string to a pointer, optionally specifying a ctype.
local function ptr64(ctype, addr)
	if not addr then
		ctype, addr = voidptr_ct, ctype
	end
	if type(addr) == 'string' then
		return ffi.cast(ctype, ffi.cast(voidptr_ct,
			ffi.cast(intptrptr_ct, addr)[0]))
	else
		return ffi.cast(ctype, addr)
	end
end

glue.addr = ffi.abi'64bit' and addr64 or addr32
glue.ptr = ffi.abi'64bit' and ptr64 or ptr32

end --if jit

return glue

