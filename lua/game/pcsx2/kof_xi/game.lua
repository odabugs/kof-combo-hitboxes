local ffi = require("ffi")
local types = require("types")
local ffiutil = require("ffiutil")
local luautil = require("luautil")
local winerror = require("winerror")
local winutil = require("winutil")
local winprocess = require("winprocess")
local window = require("window")
--local hk = require("hotkey")
local colors = require("render.colors")
local PCSX2_Common = require("game.pcsx2.common")
local KOF_XI = PCSX2_Common:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- "Absolute" address references are given relative to the start of PCSX2's
-- emulated game RAM area, unless otherwise noted.  Add the value of
-- PCSX2_Common.RAMbase (see game/pcsx2/common.lua) in order to get the
-- "real" absolute address in PCSX2's memory space.  This also applies when
-- dereferencing pointer values within the game's emulated RAM space.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
ffi.cdef[[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */
typedef int8_t byte;
typedef uint8_t ubyte;
typedef int16_t word;
typedef uint16_t uword;
typedef int32_t dword;
typedef uint32_t udword;

static const int PLAYERS = 2;
static const int CHARS_PER_TEAM = 3;
static const int BOXCOUNT = 7;

// 16.16 fixed point coordinate
typedef union {
	struct {
		uword part;           // +000h: Subpixels
		word whole;           // +002h: Whole pixels
	};
	dword value;              // +000h: Complete value
} fixed;
typedef struct { fixed x; fixed y; } fixedPair;
typedef struct { word x; word y; } coordPair;

// this struct exists at 0x008A9660 in game RAM
typedef struct {
	// X indicates the position of the left edge of the visible game screen.
	// Y is equal to 00E0h when both players are standing on solid ground.
	// Y decreases as the camera moves upward.
	coordPair position;       // +000h: X/Y world position (4 bytes)
	// Strange things happen with players bumping into invisible walls if
	// this value is less than +1.0, or walking off the edge of the screen
	// if this value is greater than +1.0.  Never seems to change normally.
	float restrictor;         // +004h: Always equal to +1.0?
} camera;

// Multiple instances of this struct are embedded in "playerMain" below.
// Things will break if this struct is not 0Ah (decimal 10) bytes wide.
typedef struct {
	// Hitbox position is expressed in terms of the center of the hitbox.
	// X offset projects forward from player origin, based on the direction
	// the player is facing.  Y offset projects upward from player origin.
	coordPair position;       // +000h: X/Y offset from player origin
	byte padding01[0x003];    // +004h to +007h: Unknown
	// Width is added to the hitbox on both sides, so that the width given
	// in the struct itself is half of the hitbox's "effective width".
	// The same principle applies for the hitbox's height.
	byte width;               // +007h: Hitbox width (in both directions)
	byte height;              // +008h: Hitbox height (in both directions)
	byte padding02[0x001];    // +009h: Unknown (DO NOT REMOVE THIS)
} hitbox;

// This struct is embedded in "playerMain" struct starting at +268h.
// Exact struct size unknown, but known so far to be at least 0x23 bytes.
typedef struct {
	byte padding01[0x01A];    // +000h to +01Ah: Unknown
	// TODO: This is not a reliable test for the attack box's "activeness".
	byte attackBoxActive;     // +01Ah: Attack box active?
	byte collisionActive;     // +01Bh: Collision box active?
	byte padding02[0x007];    // +01Ch to +023h: Unknown
} playerFlags;

// Game allocates 6 of this struct (3 per player, 1 per character in play).
// "playerMainTable" struct contains pointers to instances of this struct.
// Not all essential information about each character is contained in this
// struct; see "teamMain" and "playerExtra" structs below.
typedef struct {
	// Ground level Y = 0x02A0.  Y decreases as player moves upward.
	coordPair position;       // +000h: X/Y world position (4 bytes)
	float unknown01;          // +004h: Unknown float
	byte padding01[0x010];    // +008h to +018h: Unknown
	// Positive X velocity moves forward; negative moves backward.
	// Use the player facing to derive the "absolute" left/right velocity.
	// Positive Y velocity moves upward; negative moves downward.
	fixedPair velocity;       // +018h: X/Y velocity (8 bytes)
	byte padding02[0x06C];    // +020h to +08Ch: Unknown
	byte facing;              // +08Ch: Facing (00h = left, 02h = right)
	byte padding03[0x133];    // +08Dh to +1C0h: Unknown
	uword unknown02;          // +1C0h: Unknown status word
	byte padding04[0x0A6];    // +1C2h to +268h: Unknown
	playerFlags flags;        // +268h: Various status flags
	byte padding05[0x089];    // +28Bh to +314h: Unknown
	union {
		struct {
			hitbox attackBox;    // +314h: Attack hitbox
			hitbox vulnBox1;     // +31Eh: Vulnerable hitbox (also atttack?)
			hitbox vulnBox2;     // +328h: Vulnerable hitbox
			hitbox vulnBox3;     // +332h: Vulnerable hitbox
			hitbox grabBox;      // +33Ch: Grab "attack" hitbox
			hitbox hb6;          // +34Ch: Unused?
			hitbox collisionBox; // +350h: Collision hitbox
		};
		hitbox hitboxes[7]; // +314h: Hitboxes list
	};
	byte padding06[0x044];    // +35Ah to +39Eh: Unknown
	// The collision box is treated separately from the other hitboxes.
	// Use "collisionActive" in the "playerFlags" struct for that one.
	byte hitboxesActive;      // +39Eh: Hitbox active state flags
	byte padding07[0x151];    // +39Fh to +4F0h: Unknown
	ubyte unknown03;          // +4F0h: Unknown status byte
	byte padding08[0x091];    // +4F1h to +582h: Unknown
	word stunTimer;           // +582h: Stun state timer (-1 = not stunned)
} playerMain;
typedef playerMain projectile;

// this struct exists at 0x008A26E0 in game RAM
typedef struct {
	// 2x3 two-dimensional array of pointers to "playerMain" structs.
	// First set of 3 points to player 1's characters, second to player 2's.
	// Each set of 3 is ordered in the order the characters were selected.
	// See "playerExtra" struct to find which char is currently on point.
	intptr_t p[PLAYERS][CHARS_PER_TEAM]; // +000h: Pointers array
} playerMainTable;

// Game allocates 6 of this struct (3 per player, 1 per character in play).
// "teamMain" structs contain embedded instances of this struct.
// Things will break if this struct is not 20h (decimal 32) bytes wide.
typedef struct {
	byte charID;              // +000h: Character ID (see roster.lua)
	byte isSelected;          // +001h: Character selected? -1 = no, 0 = yes
	byte padding01[0x002];    // +002h to +004h: Unknown
	word health;              // +004h: HP (0x70 = full HP, -1 = KO'd)
	word visibleHealth;       // +006h: Visible HP
	word stun;                // +008h: Stun gauge (0x70 = full, 0 = stun)
	word guard;               // +00Ah: Guard gauge (0x70 = full, 0 = GC'd)
	byte teamPosition;        // +00Ch: Current team position (0, 1 or 2)
	byte padding02[0x013];    // +00Dh to +020h: Unknown
} playerExtra;

// struct locations: 0x008A9690 (player 1), 0x008A98D8 (player 2)
typedef struct {
	byte unknown01;           // +000h: Unknown
	byte leader;              // +001h: Selected leader (0, 1 or 2)
	byte unknown02;           // +002h: Unknown
	byte point;               // +003h: Current "point" character (0/1/2)
	byte padding01[0x003];    // +004h to +007h: Unknown
	byte comboCounter;        // +007h: Combo counter
	byte comboCounter2;       // +008h: Combo counter (duplicate?)
	byte padding02[0x011];    // +009h to +01Ah: Unknown
	byte tagCounter;          // +01Ah: Running count of tag-outs performed
	byte padding03[0x00D];    // +01Bh to +028h: Unknown
	byte teamPositions[CHARS_PER_TEAM]; // +028h: Characters' order in team
	byte padding04[0x00D];    // +02Bh to +038h: Unknown
	udword super;             // +038h: Super meter (0x70 = 1 full bar)
	udword skillStock;        // +03Ch: Skill stock (0x70 = 1 full stock)
	byte padding05[0x080];    // +040h to +0C0h: Unknown
	// There's a layer of indirection between the pointer addresses in this
	// list and the actual locations of the projectile structs: Follow this
	// pointer, then follow the pointer at the target address + 0x10.
	// The last entry in this list is always NULL as a loop sentinel value.
	intptr_t projectiles[16]; // +0C0h: Indirect pointers to projectiles
	byte padding05[0x050];    // +100h to +150h: Unknown
	playerExtra p[CHARS_PER_TEAM]; // +150h: "playerExtra" struct instances
	byte padding07[0x090];    // +1B0h to +240h: Unknown
	word currentX;            // +240h: Current point character's X position
} teamMain;

#pragma pack(pop)
]]

KOF_XI.basicWidth = 640
KOF_XI.basicHeight = 448
KOF_XI.absoluteYOffset = 34
-- game-specific variables
KOF_XI.teamPtrs = { 0x008A9690, 0x008A98D8 }
KOF_XI.playerTablePtr = 0x008A26E0
KOF_XI.cameraPtr = 0x008A9660
KOF_XI.projCount = 16 -- per player (team)

function KOF_XI:extraInit()
	self.players = {}
	self.projectiles = {}
	self.projectilesActive = { {}, {} }
	self.teams = {}
	for i = 1, 2 do
		self.players[i] = ffiutil.ntypes("playerMain", 3, 0)
		self.projectiles[i] = ffiutil.ntypes("projectile", self.projCount, 0)
		self.teams[i] = ffi.new("teamMain")
		self:clearActiveProjectiles(i) -- init self.projectilesActive
	end

	self.playerTable = ffi.new("playerMainTable") -- shared by both players
	self.camera = ffi.new("camera")
	
	---[=[
	self:read(self.playerTablePtr, self.playerTable)
	print()
	for i = 1, 2 do
		for j = 0, 2 do
			print(string.format(
				"Player %d, character %d pointer: 0x%08X",
				i, j, self.playerTable.p[i-1][j]))
		end
	end
	print()
	--]=]
end

function KOF_XI:activeCharacter(which)
	local activeIndex = self.teams[which].point
	return self.players[which][activeIndex], activeIndex
end

function KOF_XI:clearActiveProjectiles(which)
	local target = self.projectilesActive[which]
	for i = 0, self.projCount - 1 do
		target[i] = false
	end
end

function KOF_XI:capturePlayerState(which)
	local team = self.teams[which]
	self:read(self.teamPtrs[which], team)
	-- mixed 0- and 1-based indexing cause WE'RE LIVIN' DANGEROUSLY
	for i = 0, 2 do
		self:read(self.playerTable.p[which-1][i], self.players[which][i])
	end

	-- capture active projectiles
	self:clearActiveProjectiles(which)
	local projs = self.projectiles[which]
	local projsActive = self.projectilesActive[which]
	local projPtrs = team.projectiles
	for i = 0, self.projCount - 1 do
		local target = projPtrs[i]
		--print("Read ", target)
		if target ~= 0 then
			target = self:readPtr(target + 0x10)
			--print("- Read ", target)
			if target ~= 0 then
				self:read(target, projs[i])
				projsActive[i] = true
			end
		end
	end
end

function KOF_XI:captureState()
	self:read(self.cameraPtr, self.camera)
	self:read(self.playerTablePtr, self.playerTable)
	for i = 1, 2 do
		self:capturePlayerState(i)
	end

	---[=[
	local n = 1
	local active, activeIndex = self:activeCharacter(n)
	io.write(string.format("\rP1 active character's (%d) position is { x=0x%04X, y=0x%04X, pointer=0x%08X }        ",
	activeIndex, active.position.x, active.position.y, self.playerTable.p[n-1][activeIndex] + self.RAMbase))
	io.flush()
	--]=]
end

-- return -1 if player is facing left, or +1 if player is facing right
function KOF_XI:facingMultiplier(player)
	return ((player.facing == 0) and -1) or 1
end

-- translate a hitbox's position into coordinates suitable for drawing
function KOF_XI:deriveBoxPosition(player, hitbox, camera)
	local facing = self:facingMultiplier(player)
	local playerX, playerY = player.position.x, player.position.y
	playerX = playerX - camera.position.x
	playerY = playerY - camera.position.y
	local centerX, centerY = hitbox.position.x * 2, hitbox.position.y * 2
	centerX = playerX + (centerX * facing) -- positive offsets move forward
	centerY = playerY - centerY -- positive offsets move upward
	local w, h = hitbox.width * 2, hitbox.height * 2
	return centerX, centerY, w, h
end

function KOF_XI:renderBox(player, hitbox, color)
	if hitbox.width == 0 or hitbox.height == 0 then return end
	local cx, cy, w, h = self:deriveBoxPosition(
		player, hitbox, self.camera)
	self:box(cx - w, cy - h, cx + w, cy + h, color)
	---[=[
	self:pivot(cx, cy, 5, color)
	--]=]
end

-- TODO: Boxes are currently colored according to their location in memory.
-- "Proper" box type and active/inactive state checks are forthcoming.
-- For now, inactive boxes will simply linger onscreen after they're done.
local colormap = {
	colors.RED,
	colors.GREEN,
	colors.BLUE,
	colors.YELLOW,
	colors.MAGENTA,
	colors.CYAN,
	colors.WHITE,
}

function KOF_XI:drawCharacter(target, pivotColor, isProjectile)
	pivotColor = (pivotColor or colors.WHITE)
	local cam = self.camera.position
	local pivotX = target.position.x - cam.x
	local pivotY = target.position.y - cam.y
	local boxstate = target.hitboxesActive
	if boxstate ~= 0 then
		for i = 0, 5 do
			if bit.band(boxstate, bit.lshift(1, i)) ~= 0 then
				local hitbox = target.hitboxes[i]
				self:renderBox(target, hitbox, colormap[i+1])
			end
		end
		if isProjectile then
			self:pivot(pivotX, pivotY, 20, pivotColor)
		end
	end
	-- always draw pivot cross for players (but not projectiles),
	-- and don't draw collision box for projectiles
	if not isProjectile then
		if bit.band(target.flags.collisionActive, 0x10) == 0 then
			self:renderBox(target, target.collisionBox, colors.WHITE)
		end
		self:pivot(pivotX, pivotY, 20, pivotColor)
	end
end

function KOF_XI:drawPlayer(which)
	local active = self:activeCharacter(which)
	self:drawCharacter(active)
	-- draw active projectiles
	local projs = self.projectiles[which]
	local projsActive = self.projectilesActive[which]
	for i = 0, self.projCount - 1 do
		if projsActive[i] then
			local proj = projs[i]
			self:drawCharacter(proj, colors.GREEN, true)
		end
	end
end

function KOF_XI:renderState()
	self:setColor(colors.BLACK)
	for i = 1, 2 do self:drawPlayer(i) end
end

return KOF_XI
