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
static const int CHARS_PER_TEAM = 2;
static const int BOXCOUNT = 7;

// this struct exists at 0x00439972 in game RAM
typedef struct {
	byte padding01[0x038];    // +000h to +038h: Unknown
	word playerX[2][2];       // +038h: Character X positions
	word playerY[2][2];       // +040h: Character Y positions
	byte padding02[0x022];    // +048h to +06Ah: Unknown
	word bottomEdge;          // +06Ah: Bottom edge of visible area
	word topEdge;             // +06Ch: Top edge of visible area
	// Use the distance between left and right camera edges to derive
	// the current "zoom factor".  When the camera is fully zoomed in,
	// this distance will be 640, and it will increase as the camera
	// gradually zooms out.
	word leftEdge;            // +06Eh: Left edge of visible area
	word rightEdge;           // +070h: Right edge of visible area
	byte padding03[0x00C];    // +072h to +07Eh: Unknown
	// Does NOT account for camera zoom factor.
	word hCenter;             // +07Eh: Center between left/right edges
	// Y = 0 when players are on solid ground.
	// Y decreases as camera moves upward.
	word y;                   // +080h: Y position
	float unknown01;          // +082h: Always +1.0?
} camera;

// Multiple instances of this struct are embedded in "player" below.
// Things will break if this struct is not 0Ah (decimal 10) bytes wide.
typedef struct {
	byte boxID;               // +000h: Hitbox type (hittable, attack, etc.)
	byte padding01[0x003];    // +001h to +004h: Unknown
	// Hitbox position is expressed in terms of the center of the hitbox.
	// X offset projects forward from player origin, based on the direction
	// the player is facing.  Y offset projects downward from player origin.
	coordPair position;       // +004h: X/Y offset from player origin
	// Width is added to the hitbox on both sides, so that the width given
	// in the struct itself is half of the hitbox's "effective width".
	// The same principle applies for the hitbox's height.
	ubyte width;              // +008h: Hitbox width (in both directions)
	ubyte height;             // +009h: Hitbox height (in both directions)
} hitbox;

// This struct is embedded in "player" struct starting at +260h.
// Exact struct size is currently unknown.
typedef struct {
	byte padding01[0x01B];    // +000h to +01Bh: Unknown
	byte collisionActive;     // +01Bh: Collision box active?
} playerFlags;

// Game allocates 4 of this struct (2 per player, 1 per character in play).
// "playerTable" struct contains pointers to instances of this struct.
typedef struct {
	coordPair position;       // +000h: X/Y world position (4 bytes)
	float unknown01;          // +004h: Unknown float
	byte padding01[0x010];    // +008h to +018h: Unknown
	// Positive X velocity moves forward; negative moves backward.
	// Use the player facing to derive the "absolute" left/right velocity.
	// Positive Y velocity moves upward; negative moves downward.
	fixedPair velocity;       // +018h: X/Y velocity (8 bytes)
	byte padding02[0x06C];    // +020h to +08Ch: Unknown
	byte facing;              // +08Ch: Facing (00h = left, 02h = right)
	byte padding03[0x1D3];    // +08Dh to +260h: Unknown
	playerFlags flags;        // +260h: Various status flags
	byte padding04[0x09C];    // +27Ch to +318h: Unknown
	union {
		struct {
			hitbox attackBox;    // +318h: Attack hitbox
			hitbox vulnBox1;     // +322h: Vulnerable hitbox (also atttack?)
			hitbox vulnBox2;     // +32Ch: Vulnerable hitbox
			hitbox vulnBox3;     // +336h: Vulnerable hitbox
			hitbox grabBox;      // +340h: Grab "attack" hitbox
			hitbox hb6;          // +34Ah: Unused?
			hitbox collisionBox; // +354h: Collision hitbox
		};
		hitbox hitboxes[7]; // +318h: Hitboxes list
	};
	byte padding05[0x034];    // +35Eh to +392h: Unknown
	byte hitboxesActive;      // +392h: Hitbox active state flags
} player;
typedef player projectile;

// this struct exists at 0x004006D0 in game RAM
typedef struct {
	// 2x2 two-dimensional array of pointers to "player" structs.
	// First pair points to player 1's characters, second to player 2's.
	// Each pair is ordered based on the player's first/second picks.
	// See "team" struct to find which char is currently on point.
	intptr_t p[PLAYERS][CHARS_PER_TEAM]; // +000h: Pointers array
} playerTable;

// Instances of this struct are embedded in "team" struct below.
// Struct size is 0x1C (decimal 28) bytes.
typedef struct {
	byte padding01[0x008];    // +000h to +008h: Unknown
	word health;              // +008h: Health
	word redHealth;           // +00Ah: Red (recoverable) health
	word padding02;           // +008h: Unknown
	word guardGauge;          // +00Ah: Guard gauge
	byte padding03[0x010];    // +00Ch to +01Ch: Unknown
} playerExtra;

// struct locations: 0x00439A00 (player 1), 0x00439BB4 (player 2)
typedef struct {
	byte padding01[0x003];    // +000h to +003h: Unknown
	byte point;               // +003h: Current "point" character (0 or 1)
	byte padding02[0x094];    // +004h to +098h: Unknown
	// There's a layer of indirection between the pointer addresses in this
	// list and the actual locations of the projectile structs: Follow this
	// pointer, then follow the pointer at the target address + 0x10.
	// The last entry in this list is always NULL as a loop sentinel value.
	intptr_t projectiles[8];  // +098h: Indirect pointers to projectiles
	byte padding03[0x028];    // +0B8h to +0E0h: Unknown
	playerExtra players[2];   // +0E0h: Extra per-character state info
} team;

// this struct exists at 0x003857A0 in game RAM
typedef struct {
	// Value is equal to +1.0 when camera is zoomed in normally.
	// Value increases as camera zooms outward.
	double value;             // +000h: Zoom factor
} zoom;

#pragma pack(pop)
]]

return types
