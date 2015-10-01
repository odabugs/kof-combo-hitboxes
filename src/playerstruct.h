#ifndef PLAYERSTRUCT_H
#define PLAYERSTRUCT_H

#include <stdint.h>

// all structs defined here (obviously) assume a little endian CPU
// "+XXXh to YYYh" should be intepreted as XXX inclusive to YYY exclusive

typedef int16_t game_pixel_t; // whole
typedef uint16_t game_subpixel_t; // partial

// 16.16 fixed point coordinate, used e.g. for player positions
// this struct itself is one-dimensional; use one player_coord_t per dimension
typedef union __attribute__((__packed__)) player_coord
{
	struct
	{
		game_subpixel_t part; // +000h: subpixels component
		game_pixel_t whole;   // +002h: whole pixels component
	};
	int32_t value;
} player_coord_t;

typedef struct __attribute__((__packed__)) player_coords
{
	union
	{
		struct
		{
			game_subpixel_t xPart;
			game_pixel_t x;
		};
		player_coord_t xComplete;
	};
	union
	{
		struct
		{
			game_subpixel_t yPart;
			game_pixel_t y;
		};
		player_coord_t yComplete;
	};
} player_coords_t;

typedef struct __attribute__((__packed__)) camera
{
	player_coord_t x;         // +000h: Camera X position
	uint8_t padding01[0x004]; // +004h to +008h: unknown mystery gap
	player_coord_t y;         // +008h: Camera Y position
} camera_t;

// not using enums for these because we need control over their size in bytes
typedef uint32_t facing_t;
typedef uint8_t costume_t;
typedef uint8_t player_input_t;

// "primary" player structure, used for state during gameplay
// some values are duplicated in multiple locations, hence the _altX's in spots
typedef struct __attribute__((__packed__)) player
{
	//uint8_t padding00[0x000]; // +000h to +000h: unknown
	uint8_t padding01[0x018]; // +000h to +018h: unknown
	player_coord_t xPivot;    // +018h: X position in world (pivot axis)
	player_coord_t yOffset;   // +01Ch: Base offset to Y position in world
	player_coord_t yPivot;    // +020h: Y position in world (pivot axis)
	uint8_t padding02[0x018]; // +024h to +03Ch: unknown
	uint16_t currentCharID;   // +03Ch: Current(?) character ID
	uint8_t padding03[0x012]; // +03Eh to +050h: unknown
	player_coord_t xSpeed;    // +050h: X velocity
	uint8_t padding04[0x004]; // +054h to +058h: unknown
	player_coord_t ySpeed;    // +058h: Y velocity
	uint8_t padding05[0x014]; // +05Ch to +070h: unknown
	uint16_t currentCharID_alt1; // +070h: Current(?) character ID (alt 1)
	uint8_t padding06[0x004]; // +072h to +076h: unknown
	uint16_t currentCharID_alt2; // +076h: Current(?) character ID (alt 2)
	uint8_t padding07[0x002]; // +078h to +080h: unknown
	facing_t facing;          // +080h: Facing (0 = left, 1 = right)
	uint8_t padding08[0x030]; // +084h to +0B4h: unknown
	struct player *opponent;  // +0B4h: Pointer to opponent's main struct
	struct player *opponent_alt1; // +0B4h: Opponent main struct (alt 1)
	game_pixel_t xDistance;   // +0BCh: Absolute distance between this
	                          //        player's X pivot and the opponent's
	uint8_t padding09[0x017]; // +0BEh to +0D5h: unknown
	uint8_t playerMode;       // +0D5h: Player mode (ADV, EX, Ultimate)
	uint8_t padding10[0x007]; // +0D6h to +0DDh: unknown
	costume_t costume;        // +0DDh: Current costume color
	uint8_t padding11[0x00A]; // +0DEh to +0E8h: unknown
	uint16_t superPart;       // +0E8h: Fractional super meter
	uint16_t maxGauge;        // +0EAh: Max Mode gauge
	uint8_t padding12[0x04C]; // +0ECh to +138h: unknown
	uint16_t health;          // +138h: HP
	uint8_t padding13[0x004]; // +13Ah to +13Eh: unknown
	uint16_t stunGauge;       // +13Eh: Stun (dizzy) gauge
	uint8_t padding14[0x005]; // +140h to +145h: unknown
	uint8_t stunRecover;      // +145h: Stun recovery timer
	uint16_t guardGauge;      // +146h: Guard crush gauge
	uint8_t padding15[0x011]; // +147h to +158h: unknown
	uint16_t currentCharID_alt3; // +158h: Current(?) character ID (alt 3)
	uint8_t padding16[0x04E]; // +15Ah to +1A8h: unknown
	struct player_extra *extra; // +1A8h: Pointer to player's "extra" struct
	uint8_t padding17[0x037]; // +1ACh to +1E3h: unknown
	uint8_t superStocks;      // +1E3h: Whole super meter stocks
} player_t;

typedef struct __attribute__((__packed__)) player_extra
{
	player_coord_t walkSpeed; // +000h: Walk speed
	player_coord_t jumpMomentum; // +004h: Jump upward momentum
	player_coord_t jumpGravity;  // +008h: Jump gravity
	uint8_t farARange;        // +00Ch: Far A activation range (whole pixels)
	uint8_t farBRange;        // +00Dh: Far B activation range (whole pixels)
	uint8_t farCRange;        // +00Eh: Far C activation range (whole pixels)
	uint8_t farDRange;        // +00Fh: Far D activation range (whole pixels)
	uint8_t padding01[0x004]; // +010h to +014h: unknown
	player_coord_t runSpeed;  // +014h: Run speed
	uint8_t padding02[0x008]; // +018h to +020h: unknown
	uint16_t backdashPart1;   // +020h: Backdash component 1 (unknown use)
	uint16_t backdashPart2;   // +022h: Backdash component 2 (unknown use)
	uint8_t padding03[0x004]; // +024h to +028h: unknown
	game_pixel_t backdashUpPush; // +028h: Backdash upward momentum
	player_coord_t backdashGravity; // +02Ah: Backdash gravity
	player_input_t inputBuffer[0x03C]; // +023h to 06Bh: Input buffer
	uint8_t padding04[0x001]; // +06Bh to +06Ch: unknown
	uint16_t frameCounter;    // +06Ch: Frame counter
} player_extra_t;

extern const facing_t FACING_LEFT, FACING_RIGHT;
extern const costume_t
	COSTUME_A,  COSTUME_B,  COSTUME_C,  COSTUME_D,
	COSTUME_CD, COSTUME_AB, COSTUME_AD, COSTUME_BC;

extern void *CAMERA_ADDR;
extern void *PLAYER_STRUCT_ADDRS[];

#endif /* PLAYERSTRUCT_H */
