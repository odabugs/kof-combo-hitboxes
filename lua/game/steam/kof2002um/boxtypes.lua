local luautil = require("luautil")
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
add(b_v , b_v , b_v , b_vc,  b_vc, b_v , b_v , b_v ) -- 00h-07h
add(b_v , b_g , b_g , b_g ,  b_a , b_a , b_a , b_a ) -- 08h-0Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_va) -- 10h-17h
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 18h-1Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 20h-27h
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 28h-2Fh
add(b_a , b_a , b_a , b_a ,  b_a , b_a , b_a , b_a ) -- 30h-37h
add(b_g , b_g , b_pv, b_pv,  b_pv, b_pv, b_pv, b_xx) -- 38h-3Fh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 40h-47h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 48h-4Fh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 50h-57h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 58h-5Fh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 60h-67h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 68h-6Fh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 70h-77h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 78h-7Fh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 80h-87h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 88h-8Fh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 90h-97h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- 98h-9Fh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- A0h-A7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- A8h-AFh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- B0h-B7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- B8h-BFh
--  +00h  +01h  +02h  +03h   +04h  +05h  +06h  +07h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- C0h-C7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- C8h-CFh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- D0h-D7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- D8h-DFh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- E0h-E7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- E8h-EFh
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- F0h-F7h
add(b_xx, b_xx, b_xx, b_xx,  b_xx, b_xx, b_xx, b_xx) -- F8h-FFh

return boxtypes
