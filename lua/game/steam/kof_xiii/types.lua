local commontypes = require("game.commontypes")
local types = commontypes:new()

-- Game-specific struct definitions assume a little-endian memory layout.
-- intptr_t is generally used in place of actual pointer types, in order to
-- avoid excess GC overhead induced by frequent use of ffi.cast().
types.typedefs = [[
#pragma pack(push, 1) /* DO NOT REMOVE THIS */
static const int PLAYERS = 2;

typedef struct {
	float x;
	float y;
} floatPair;

typedef struct {
	float x;
	float y;
	float z;
} floatTriple;

// This struct exists at 0x0082F890 in game memory
typedef struct {
	byte padding01[0x13C];    // +000h to +13Ch: Unknown
	floatPair shake;          // +13Ch: X/Y adjust when camera is shaking
	byte padding02[0x038];    // +144h to +17Ch: Unknown
	floatPair position;       // +13Ch: X/Y position
} camera;

// Pointers to this struct exist at 0x008320A0 (P1), 0x008320A4 (P2)
typedef struct {
	byte padding01[0x050];    // +000h to +050h: Unknown
	dword health;             // +050h: HP
	byte padding02[0x018];    // +054h to +06Ch: Unknown
	float guardCrush;         // +06Ch: Guard crush meter
	byte padding03[0x024];    // +070h to +094h: Unknown
	float dizzy;              // +094h: Dizzy meter
	byte padding04[0x014];    // +098h to +0ACh: Unknown
	dword comboCount;         // +0ACh: Combo hit counter
	dword hitTally;           // +0B0h: Running tally of hits landed
	byte padding05[0x014];    // +0B4h to +0C8h: Unknown
	float drive;              // +0C8h: Drive meter
	byte padding06[0x018];    // +0CCh to +0E4h: Unknown
	floatTriple position;     // +0E4h: Location (of pivot axis)
	byte padding07[0x02C];    // +0F0h to +11Ch: Unknown
	float super;              // +11C: Super meter
	byte padding08[0x084];    // +120h to +1A4h: Unknown
	byte facing;              // +1A4h: Left/right facing
} player;

// This struct is embedded inside the "team" struct below
typedef struct {
	udword characterID;       // +000h: Character ID
	udword color;             // +004h: Character color choice
	byte padding01[0x014];    // +008h to +01Ch: Unknown
} teamEntry;

// Struct locations in game memory: 0x00831DF4 (P1), 0x00831EF8 (P2)
typedef struct {
	udword currentCharacter;  // +000h: ID of character currently in play
	byte padding01[0x024];    // +004h to +028h: Unknown
	teamEntry entries[3];     // +028h: Character selections in team
} team;

// Hitbox structs come in two flavors, with slightly different handling.
// Both types are stored as linked lists, with the "head" pointers for
// each list stored in the "hitboxSet" struct below.
typedef struct {
	intptr_t next;            // +000h: Pointer to next linked list entry
	intptr_t next2;           // +004h: Duplicate of "next"?
	byte padding01[0x004];    // +008h to +00Ch: Unknown
	// Hitbox position is given in terms of the box's bottom-left corner.
	floatPair position;       // +00Ch: X/Y position
	// Hitbox width/height "project" rightward and upward from box position.
	floatPair size;           // +014h: Width and height
	byte padding02[0x004];    // +01Ch to +020h: Unknown
	ubyte boxID;              // +020h: Hitbox type ID
} hitbox1;

typedef struct {
	intptr_t next;            // +000h: Pointer to next linked list entry
	// Hitbox position is given in terms of the box's bottom-left corner.
	floatPair position;       // +004h: X/Y position
	// Hitbox width/height "project" rightward and upward from box position.
	floatPair size;           // +00Ch: Width and height
	byte padding01[0x004];    // +014h to +018h: Unknown
	ubyte boxID;              // +018h: Hitbox type ID
} hitbox2;

// Instances of this struct are embedded inside "hitboxSet" below.
// See the comments in "hitboxListHead" below to find out which instances
// point to a "hitbox1" list and which ones point to a "hitbox2" list.
// Note that in both cases, there is a layer of indirection between the
// pointer stored here and the actual list head; i.e., "head" is actually
// a pointer-to-pointer.
typedef struct {
	intptr_t head;            // +000h: Pointer to hitboxes linked list head
	udword count;             // +004h: Number of entries in linked list
	byte padding01[0x004];    // +008h to +00Ch: Unknown
} hitboxList;

// Struct locations in game memory: 0x007EAC08 (P1), 0x007EAC44 (P2)
typedef struct {
	intptr_t collision;       // +000h: Collision boxes (hitbox2)
	// Also includes grab boxes and projectile attack/vulnerable boxes
	intptr_t attack;          // +00Ch: Attack boxes (hitbox1)
	intptr_t armor;           // +018h: Armor boxes (hitbox1)
	intptr_t vulnerable;      // +024h: Vulnerable boxes (hitbox1)
	intptr_t proximity;       // +030h: Proximity boxes (hitbox2)
} hitboxListHead;

#pragma pack(pop)
]]

return types
