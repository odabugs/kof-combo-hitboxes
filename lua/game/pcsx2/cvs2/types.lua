local commontypes = require("game.commontypes")
local types = commontypes:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- "Absolute" address references are given relative to the start of PCSX2's
-- emulated game RAM area, unless otherwise noted.  Add the value of
-- PCSX2_Common.RAMbase (see game/pcsx2/common.lua) in order to get the
-- "real" absolute address in PCSX2's memory space.  This also applies when
-- dereferencing pointer values within the game's emulated RAM space.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
types.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */
static const int PLAYERS = 2;

typedef struct {
	byte activeState1;        // +000h: "Active" state indicator 1
	byte charID;              // +001h: Current character ID
	uword unknown03;          // +002h: Unknown
	byte activeState2;        // +004h: "Active" state indicator 2
	byte padding01[0x037];    // +005h to +03Ch: Unknown
	fixed xPivot;             // +03Ch: World X position
	fixed yPivot;             // +040h: World Y position
	byte padding08[0x04C];    // +044h to +090h: Unknown
	fixed xSpeed;             // +090h: X velocity (positive = rightward)
	fixed ySpeed;             // +094h: Y velocity (positive = upward)
	byte padding07[0x00C];    // +098h to +0A4h: Unknown
	byte facing;              // +0A4h: Facing (00 = left, 01 = right)
	byte padding03[0x00F];    // +0A5h to +0B4h: Unknown
	uword spriteNum;          // +0B4h: Animation table index
	uword unknown02;          // +0B6h: Unknown
	intptr_t animationPtr;    // +0B8h: Animation table pointer
	byte padding11[0x088];    // +0BCh to +144h: Unknown
	word health;              // +144h: HP
	word redHealth;           // +146h: Red health display
	word healthBarLength;     // +148h: Max length of health bar
	byte padding04[0x016];    // +14Ah to +160h: Unknown
	// These two are of type hitbox*
	intptr_t hitboxPtrs[4];   // +160h to +170h: Hitbox pointers list
	intptr_t attackBoxPtr;    // +170h: Pointer to attack hitbox table
	intptr_t unknownBoxPtr;   // +174h: Pointer to unknown box?
	// These two are of type hitboxOffsets*
	intptr_t boxOffsets;      // +178h: Hitbox offsets for non-throw boxes
	intptr_t throwOffsets;    // +17Ch: Hitbox offsets for throwbox
	byte padding10[0x01E];    // +180h to +19Eh: Unknown
	ubyte dizzy;              // +19Eh: Dizzy meter
	ubyte maxDizzy;           // +19Fh: Dizzy meter limit before stun occurs
	byte padding05[0x008];    // +1A0h to +1A8h: Unknown
	ubyte maxGuardCrush;      // +1A8h: Guard crush meter limit
	ubyte guardCrush;         // +1A9h: Guard crush meter
	byte padding06[0x038];    // +1AAh to +1E2h: Unknown
	uword super;              // +1E2h: Groove meter
	byte padding09[0x018];    // +1E4h to +1FCh: Unknown
	uword dizzyTimer;         // +1FCh: Dizzy state timer
} player;
typedef player projectile;

typedef struct {
	ubyte offsets[0x004];     // +000h to +004h: Hitbox offset indices
} hitboxOffsets;

typedef struct {
	word xCenter;             // +000h: Hitbox center X position
	word yCenter;             // +002h: Hitbox center Y position
	word xRadius;             // +004h: Hitbox width (radius)
	word yRadius;             // +006h: Hitbox height (radius)
} hitbox;

typedef struct {
	hitbox hitboxes[0x100];   // +000h: Hitbox table
} hitboxTable;

typedef struct {
	byte padding01[0x00A];    // +000h to +00Ah: Unknown
	word y;                   // +00Ah: Camera Y position
	byte padding02[0x044];    // +00Ch to +050h: Unknown
	word x;                   // +050h: Camera X position
} camera;

#pragma pack(pop)
]]

return types
