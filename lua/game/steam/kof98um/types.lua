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
static const int HBLISTSIZE = 4;
static const int BUTTONCOUNT = 4;

typedef struct {
	fixed x;                  // +000h: Camera X position
	byte padding01[0x004];    // +004h to +008h: Unknown
	fixed y;                  // +008h: Camera Y position
} camera;

// Hitboxes are defined by their center pivot (xPivot and yPivot), their X radius
// (width of the box on BOTH sides of the pivot), and Y radius (same principle there).
// xPivot and yPivot are relative to the player's pivot position.
// Negative values for yPivot place the box above the player's pivot.
// Box positions are NOT auto-adjusted to account for the player facing left vs. right.
typedef struct {
	ubyte boxID;              // +000h: Box ID
	// Hitbox position is expressed in terms of the center of the hitbox.
	// X offset projects forward from player origin, based on the direction
	// the player is facing.  Y offset projects downward from player origin.
	byte x;                   // +001h: X offset
	byte y;                   // +001h: Y offset
	// Width is added to the hitbox on both sides, so that the width given
	// in the struct itself is half of the hitbox's "effective width".
	// The same principle applies for the hitbox's height.
	ubyte width;              // +003h: Box width
	ubyte height;             // +004h: Box height
} hitbox;

//*
typedef struct {
	byte padding01[0x006];    // +000h to +006h: unknown
	word basicStatus;         // +006h: Basic status (< 0 if projectile is not active)
	uint8_t padding02[0x01C]; // +008h to +024h: unknown
	// screenX/screenY are pre-adjusted relative to the camera position
	word screenX;             // +024h: X position onscreen
	word screenY;             // +026h: Y position onscreen
	byte padding03[0x010];    // +028h to +038h: unknown
	ubyte facing;             // +038h: Facing (0 = left, 1 = right)
	byte padding04[0x043];    // +039h to +07Ch: unknown
	ubyte statusFlags[3];     // +07Ch to +07Fh: Status flags 1
	byte padding05[0x005];    // +07Fh to +084h: unknown
	// This points to "struct player"
	intptr_t owner;           // +084h: Pointer to projectile's "owner"
	// These two point to "struct projectile"
	intptr_t projListStart;   // +088h: Projectiles list start ptr
	intptr_t projListStart_alt; // +08Ch: Duplicate of +088h
	hitbox hitboxes[HBLISTSIZE]; // +090h to +0A4h: Hitboxes list
} projectile;
//*/

typedef struct {
	word screenY;             // +024h: Y position onscreen
	fixed walkSpeed;          // +000h: Walk speed
	fixed jumpMomentum;       // +004h: Jump upward momentum
	fixed jumpGravity;        // +008h: Jump gravity
	// These go in order: A, B, C, D
	ubyte closeRanges[BUTTONCOUNT]; // +00Ch to +010h: Close normal active ranges
	byte padding01[0x004];    // +010h to +014h: unknown
	fixed runSpeed;           // +014h: Run speed
	byte padding02[0x008];    // +018h to +020h: unknown
	uword backdashPart1;      // +020h: Backdash component 1 (unknown use)
	uword backdashPart2;      // +022h: Backdash component 2 (unknown use)
	byte padding03[0x004];    // +024h to +028h: unknown
	word backdashUpPush;      // +028h: Backdash upward momentum
	fixed backdashGravity;    // +02Ah: Backdash gravity
	byte inputBuffer[0x03D];  // +02Eh to 06Bh: Input buffer
	byte padding04[0x001];    // +06Bh to +06Ch: unknown
	uword frameCounter;       // +06Ch: Frame counter
} playerExtra;

typedef struct {
	uword frameCounter;       // +06Ch: Frame counter
	byte padding01[0x008];    // +000h to +008h: unknown
	uword miscFlags1;         // +008h: Game state? (purpose still unclear)
	byte padding02[0x008];    // +010h to +018h: unknown
	fixed xPivot;             // +018h: World X position
	fixed yOffset;            // +01Ch: Base offset to world Y
	fixed yPivot;             // +020h: World Y position
	// screenX/screenY are pre-adjusted relative to the camera position
	word screenX;             // +024h: X position onscreen
	word screenY;             // +026h: Y position onscreen
	byte padding03[0x010];    // +028h to +038h: unknown
	ubyte miscFlags2;         // +038h: Facing (bit 0), other stuff too?
	byte padding04[0x001];    // +039h to +03Ah: unknown
	ubyte miscFlags3;         // +03Ah: Mystery byte (0xFE during gameplay?)
	ubyte gameplayState;      // +03Bh: Flags (bit 0 = "in game?")
	byte padding05[0x048];    // +03Ch to +084h: unknown
	// This points to "struct player"
	intptr_t player;          // +084h: Pointer to main player struct
} playerSecondExtra;

typedef struct {
	intptr_t statePtr;        // +000h: Player state code pointer
	byte padding01[0x014];    // +004h to +018h: unknown
	fixed xPivot;             // +018h: World X position
	fixed yOffset;            // +01Ch: Base offset to world Y
	fixed yPivot;             // +020h: World Y position
	// screenX/screenY are pre-adjusted relative to the camera position
	word screenX;             // +024h: X position onscreen
	word screenY;             // +026h: Y position onscreen
	byte padding02[0x010];    // +028h to +038h: unknown
	ubyte facing;             // +038h: Facing (0 = left, 1 = right)
	byte padding20[0x003];    // +039h to +03Ch: unknown
	uword currentCharID;      // +03Ch: Current(?) character ID
	byte padding03[0x012];    // +03Eh to +050h: unknown
	fixed xSpeed;             // +050h: X velocity
	byte padding04[0x004];    // +054h to +058h: unknown
	fixed ySpeed;             // +058h: Y velocity
	byte padding05[0x014];    // +05Ch to +070h: unknown
	uword currentCharID_alt1; // +070h: Current(?) character ID (alt 1)
	byte padding06[0x004];    // +072h to +076h: unknown
	uword currentCharID_alt2; // +076h: Current(?) character ID (alt 2)
	byte padding07[0x004];    // +078h to +07Ch: unknown
	ubyte statusFlags[3];     // +07Ch to +07Fh: Status flags 1
	byte padding22[0x011];    // +07Fh to +090h: unknown
	hitbox hitboxes[HBLISTSIZE]; // +090h to +0A4h: 1st base hitboxes list
	hitbox collisionBox;      // +0A4h: Collision box
	byte padding19[0x00B];    // +0A9h to +0B4h: unknown
	// These two point to "struct player"
	intptr_t opponent;        // +0B4h: Pointer to opponent's main struct
	intptr_t opponent_alt1;   // +0B8h: Opponent main struct (alt 1)
	uword xDistance;       // +0BCh: X distance between player and opponent
	byte padding09[0x016];    // +0BEh to +0D4h: unknown
	word hitstun;             // +0D4h: Hit stun (also used for dizzy state)
	byte padding10[0x007];    // +0D6h to +0DDh: unknown
	ubyte costume;            // +0DDh: Current costume color
	byte padding11[0x002];    // +0DEh to +0E0h: unknown
	ubyte statusFlags2nd[4];  // +0E0h to +0E4h: Status flags 2
	byte padding23[0x004];    // +0E4h to +0E8h: unknown
	uword superPart;          // +0E8h: Fractional super meter
	uword maxGauge;           // +0EAh: Max Mode gauge
	byte padding12[0x04C];    // +0ECh to +138h: unknown
	uword health;             // +138h: HP
	byte padding13[0x004];    // +13Ah to +13Eh: unknown
	uword stunGauge;          // +13Eh: Stun (dizzy) gauge
	byte padding14[0x005];    // +140h to +145h: unknown
	ubyte stunRecover;        // +145h: Stun recovery timer
	uword guardGauge;         // +146h: Guard crush gauge
	byte padding15[0x010];    // +148h to +158h: unknown
	uword currentCharID_alt3; // +158h: Current(?) character ID (alt 3)
	byte padding16[0x02E];    // +15Ah to +188h: unknown
	hitbox throwBox;          // +188h: "Throwing" box
	hitbox throwableBox;      // +18Dh: "Throwable" box
	byte padding21[0x012];    // +192h to +1A8h: unknown
	// These two point to "struct playerExtra".
	// This pointer is in different positions depending on the game.
	intptr_t kof02_extra;     // +1A4h: Pointer to player's "extra" struct
	intptr_t kof98_extra;     // +1A8h: Pointer to player's "extra" struct
	byte padding17[0x004];    // +1ACh to +1B0h: unknown
	ubyte comboCounter;     // +1B0h: Combo counter ("belongs to" opponent)
	byte padding18[0x023];    // +1B1h to +1D4h: unknown
	ubyte throwableStatus;    // +1D4h: "Throwable" status flag
	byte padding24[0x00E];    // +1D5h to +1E3h: unknown
	ubyte superStocks;        // +1E3h: Whole super meter stocks
} player;
//typedef player projectile;

#pragma pack(pop)
]]

return types
