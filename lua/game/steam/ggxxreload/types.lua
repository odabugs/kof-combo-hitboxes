local commontypes = require("game.commontypes")
local types = commontypes:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
types.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */

// 2F80C
typedef struct {
	dword leftEdge;           // +000h: Left edge of visible area
	byte paddingFF[0x2F7F8];  // +004h to +008h: Unknown
	dword width;              // +000h: Width of visible area
	byte paddingFE[0x004];    // +004h to +008h: Unknown
	float zoom;               // +008h: Zoom factor (1.0 to 0.8)
	byte paddingFD[0x034];    // +00Ch to +040h: Unknown
	dword xCenter;            // +040h: X center of visible area
	dword bottomEdge;         // +044h: Bottom edge of visible area
} camera;

typedef struct {
	word characterID;         // +000h: Current character ID (plus 1)
	byte facing;              // +002h: Current facing (0 = left, 1 = right)
	byte projectedFacing;     // +003h: Projected facing
	byte padding01[0x012];    // +004h to +016h: Unknown
	word health;              // +016h: Current HP
	byte padding02[0x00C];    // +018h to +024h: Unknown
	intptr_t playerExtraPtr;  // +024h: Pointer to "playerExtra" struct
	byte padding05[0x024];    // +028h to +04Ch: Unknown
	intptr_t boxPtr;          // +04Ch: Pointer to current hitbox set
	byte padding03[0x028];    // +050h to +078h: Unknown
	byte boxCount;            // +078h: Box count (plus/minus 1?)
	byte padding04[0x02B];    // +079h to +0A4h: Unknown
	// Y position is equal to 0 when the player is standing on the ground,
	// and decreases as the player moves upward (e.g., while jumping).
	dword xPivot;             // +0A4h: X pivot position
	dword yPivot;             // +0A8h: Y pivot position
} player;

typedef struct {
	word tension;             // +000h: Tension meter
	byte padding01[0x028];    // +002h to +02Ah: Unknown
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
