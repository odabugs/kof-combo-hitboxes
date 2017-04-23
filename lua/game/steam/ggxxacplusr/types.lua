local commontypes = require("game.commontypes")
local types = commontypes:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
types.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */

// Struct location in memory: 0x0141B0D4
typedef struct {
	byte padding01[0x010];    // +000h to +010h: Unknown
	dword xCenter;            // +010h: X center of visible area
	dword bottomEdge;         // +014h: Bottom edge of visible area
	byte padding02[0x008];    // +018h to +020h: Unknown
	dword leftEdge;           // +020h: Left edge of visible area
	byte padding03[0x004];    // +024h to +028h: Unknown
	dword width;              // +028h: Width of visible area
	dword height;             // +02Ch: Height of visible area
	byte padding04[0x014];    // +030h to +044h: Unknown
	float zoom;               // +044h: Zoom factor (1.0 to 0.8)
} camera;

typedef struct {
	union {
		word characterID;     // +000h: Current character ID (plus 1)
		uword projStatus;     // +000h: Projectile "active" status
	};
	byte facing;              // +002h: Current facing (0 = left, 1 = right)
	byte projectedFacing;     // +003h: Projected facing
	dword status;             // +004h: Various status flags
	byte padding01[0x016];    // +008h to +01Eh: Unknown
	word health;              // +01Eh: Current HP
	byte padding02[0x00C];    // +020h to +02Ch: Unknown
	intptr_t playerExtraPtr;  // +02Ch: Pointer to "playerExtra" struct
	byte padding03[0x024];    // +030h to +054h: Unknown
	intptr_t boxPtr;          // +054h: Pointer to current hitbox set
	byte padding04[0x02C];    // +058h to +084h: Unknown
	byte boxCount;            // +084h: Box count (plus/minus 1?)
	byte padding05[0x02B];    // +085h to +0B0h: Unknown
	// Y position is equal to 0 when the player is standing on the ground,
	// and decreases as the player moves upward (e.g., while jumping).
	dword xPivot;             // +0B0h: X pivot position
	dword yPivot;             // +0B4h: Y pivot position
	dword xSpeed;             // +0B8h: X velocity
	dword ySpeed;             // +0BCh: Y velocity
} player;
typedef player projectile;

typedef struct {
	word tension;             // +000h: Tension meter
	byte padding01[0x018];    // +002h to +01Ah: Unknown
	word guardGauge;          // +01Ah: Guard gauge
	byte padding02[0x00E];    // +01Ch to +02Ah: Unknown
	byte invul;               // +02Ah: I-frames remaining
} playerExtra;

typedef struct {
	word xOffset;             // +000h: X offset from player pivot
	word yOffset;             // +002h: Y offset from player pivot
	word width;               // +004h: Box width
	word height;              // +006h: Box height
	ubyte boxType;            // +008h: Box type ID
} hitbox;

typedef struct {
	word width;               // +000h: Box width
	word height;              // +002h: Box height
} pushbox;

#pragma pack(pop)
]]

return types
