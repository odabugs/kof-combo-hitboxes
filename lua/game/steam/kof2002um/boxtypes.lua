local luautil = require("luautil")
local colors = require("render.colors")
local Boxtypes_Common = require("game.boxtypes_common")
local boxtypes = Boxtypes_Common:new()

local add = luautil.inserter(boxtypes, 0)
local b_xx = "dummy"
local b_co = "collision"
local b_c  = "counter"
local b_v  = "vulnerable"
local b_vc = "counterVuln"
local b_va = "anywhereVuln"
local b_vo = "otgVuln"
local b_g  = "guard"
local b_a  = "attack"
local b_cl = "clash"
local b_pv = "projVuln"
local b_pa = "projAttack"
local b_tv = "throwable"
local b_t  = "throw"

--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_v , b_v , b_v , b_v ,  b_v , b_v , b_v , b_v ) -- 00h-07h
add(b_v , b_g , b_g , b_g ,  b_a , b_a , b_a , b_a ) -- 08h-0Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_va) -- 10h-17h
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 18h-1Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 20h-27h
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 28h-2Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 30h-37h
add(b_g , b_g , b_pv, b_pv,  b_pv, b_pv, b_pv, b_x ) -- 38h-3Fh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 40h-47h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 48h-4Fh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 50h-57h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 58h-5Fh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 60h-67h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 68h-6Fh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 70h-77h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 78h-7Fh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 80h-87h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 88h-8Fh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 90h-97h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- 98h-9Fh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- A0h-A7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- A8h-AFh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- B0h-B7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- B8h-BFh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- C0h-C7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- C8h-CFh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- D0h-D7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- D8h-DFh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- E0h-E7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- E8h-EFh
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- F0h-F7h
add(b_x , b_x , b_x , b_x ,  b_x , b_x , b_x , b_x ) -- F8h-FFh

boxtypes.order = {
	b_xx,
	b_co,
	b_v,
	b_vc,
	b_va,
	b_vo,
	b_c,
	b_g,
	b_a,
	b_cl,
	b_tv,
	b_t,
	b_pv,
	b_pa,
}
boxtypes.colormap = {
	[b_xx] = colors.CLEAR,
	[b_co] = colors.WHITE,
	[b_c]  = colors.CYAN,
	[b_v]  = colors.BLUE,
	[b_vc] = colors.BLUE,
	[b_va] = colors.BLUE,
	[b_vo] = colors.BLUE,
	[b_g]  = colors.CYAN,
	[b_a]  = colors.RED,
	[b_cl] = colors.BLACK,
	[b_pv] = colors.GREEN,
	[b_pa] = colors.YELLOW,
	[b_tv] = colors.WHITE,
	[b_t]  = colors.MAGENTA,
}
boxtypes.asProjectileMap = {
	[b_a]  = b_pa,
	[b_v]  = b_pv,
}

return boxtypes
