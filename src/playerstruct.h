#ifndef PLAYERSTRUCT_H
#define PLAYERSTRUCT_H

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "boxtypes.h"

// all structs defined here assume a little-endian CPU
// hex numbers in comments (e.g., for noting offsets) are written like +XXXh
// if you add stuff to structures here without noting the offset, jesus weeps
// "+XXXh to +YYYh" should be intepreted as +XXXh inclusive to +YYYh exclusive

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
typedef uint8_t facing_t;
static const facing_t FACING_LEFT = 0, FACING_RIGHT = 1;

typedef uint8_t costume_t;
static const costume_t
	COSTUME_A  = 0, COSTUME_B  = 1, COSTUME_C  = 2, COSTUME_D  = 3,
	// the following apply only to '98UM
	COSTUME_CD = 4, COSTUME_AB = 5, COSTUME_AD = 6, COSTUME_BC = 7;

typedef uint8_t player_input_t;
// character IDs appear in different byte sizes depending on context
typedef uint8_t char_id_byte_t;
typedef uint16_t char_id_short_t;
typedef uint32_t character_id_t;

// Hitboxes are defined by their center pivot (xPivot and yPivot), their X radius
// (width of the box on BOTH sides of the pivot), and Y radius (same principle there).
// xPivot and yPivot are relative to the player's pivot position.
// Negative values for yPivot place the box above the player's pivot.
// Box positions are NOT auto-adjusted to account for the player facing left vs. right.
typedef struct __attribute__((__packed__)) hitbox
{
	uint8_t boxID;            // +000h: Box ID number (determines box function?)
	int8_t xPivot;            // +001h: Box center X (relative to player pivot X)
	int8_t yPivot;            // +002h: Box center Y (relative to player pivot Y)
	uint8_t xRadius;          // +003h: X radius (extends on both sides of pivot)
	uint8_t yRadius;          // +004h: Y radius (extends on both sides of pivot)
} hitbox_t;
#define HBLISTSIZE 4 /* for the hitbox list starting at player_t +090h */

typedef enum
{
	BTN_A,
	BTN_B,
	BTN_C,
	BTN_D,
	ATTACK_BUTTONS // this must come last
} atk_button_t;
#define SHOW_NO_BUTTON_RANGES ATTACK_BUTTONS

struct player;
typedef struct __attribute__((__packed__)) projectile
{
	uint8_t padding01[0x006]; // +000h to +006h: unknown
	int16_t basicStatus;      // +006h: Basic status (< 0 if projectile is not active)
	uint8_t padding02[0x01C]; // +008h to +024h: unknown
	game_pixel_t screenX;     // +024h: X position onscreen (camera adjusted)
	game_pixel_t screenY;     // +026h: Y position onscreen (camera adjusted)
	uint8_t padding03[0x05C]; // +028h to +084h: unknown
	struct player *owner;     // +084h: Pointer to player who "owns" this projectile
	struct projectile *projListStart; // +088h: Pointer to start of projectiles list
	struct projectile *projListStart_alt; // +08Ch: Duplicate of projListStart?
	hitbox_t hitboxes[HBLISTSIZE]; // +090h to +0A4h: 1st base hitboxes list
} projectile_t;

typedef struct __attribute__((__packed__)) player_extra
{
	player_coord_t walkSpeed; // +000h: Walk speed
	player_coord_t jumpMomentum; // +004h: Jump upward momentum
	player_coord_t jumpGravity;  // +008h: Jump gravity
	union
	{
		uint8_t closeRanges[ATTACK_BUTTONS]; // +00Ch to +010h: Close normal active ranges
		struct
		{
			uint8_t closeARange; // +00Ch: close A activation range (whole pixels)
			uint8_t closeBRange; // +00Dh: close B activation range (whole pixels)
			uint8_t closeCRange; // +00Eh: close C activation range (whole pixels)
			uint8_t closeDRange; // +00Fh: close D activation range (whole pixels)
		};
	};
	uint8_t padding01[0x004]; // +010h to +014h: unknown
	player_coord_t runSpeed;  // +014h: Run speed
	uint8_t padding02[0x008]; // +018h to +020h: unknown
	uint16_t backdashPart1;   // +020h: Backdash component 1 (unknown use)
	uint16_t backdashPart2;   // +022h: Backdash component 2 (unknown use)
	uint8_t padding03[0x004]; // +024h to +028h: unknown
	game_pixel_t backdashUpPush; // +028h: Backdash upward momentum
	player_coord_t backdashGravity; // +02Ah: Backdash gravity
	player_input_t inputBuffer[0x03D]; // +02Eh to 06Bh: Input buffer
	uint8_t padding04[0x001]; // +06Bh to +06Ch: unknown
	uint16_t frameCounter;    // +06Ch: Frame counter
} player_extra_t;

typedef struct __attribute__((__packed__)) player_extra_2
{
	uint8_t padding01[0x008]; // +000h to +008h: unknown
	uint16_t miscFlags1;      // +008h: Broad game state? (purpose still unclear)
	uint8_t padding02[0x008]; // +010h to +018h: unknown
	player_coord_t xPivot;    // +018h: X position in world (pivot axis)
	player_coord_t yOffset;   // +01Ch: Base offset to Y position in world
	player_coord_t yPivot;    // +020h: Y position in world (pivot axis)
	game_pixel_t screenX;     // +024h: X position onscreen (camera adjusted)
	game_pixel_t screenY;     // +026h: Y position onscreen (camera adjusted)
	uint8_t padding03[0x010]; // +028h to +038h: unknown
	uint8_t miscFlags2;       // +038h: Facing (at bit 0) and possible other stuff
	uint8_t padding04[0x001]; // +039h to +03Ah: unknown
	uint8_t miscFlags3;       // +03Ah: Mystery byte (= FEh during gameplay?)
	uint8_t gameplayState;    // +03Bh: More flags!! (bit 0 = "in game"/"not in game")
	uint8_t padding05[0x048]; // +03Ch to +084h: unknown
	struct player *player;    // +084h: Pointer to main player struct
} player_2nd_extra_t;

#define STATUS_FLAGS_LEN 3
#define STATUS_FLAGS_LEN_2ND 4

// "primary" player structure, used for state during gameplay
// some values are duplicated in multiple locations, hence the _altX's in spots
typedef struct __attribute__((__packed__)) player
{
	//uint8_t padding00[0x000]; // +000h to +000h: unknown
	uint32_t statePtr;        // +000h: Code pointer corresponding to current player state
	uint8_t padding01[0x014]; // +004h to +018h: unknown
	player_coord_t xPivot;    // +018h: X position in world (pivot axis)
	player_coord_t yOffset;   // +01Ch: Base offset to Y position in world
	player_coord_t yPivot;    // +020h: Y position in world (pivot axis)
	game_pixel_t screenX;     // +024h: X position onscreen (camera adjusted)
	game_pixel_t screenY;     // +026h: Y position onscreen (camera adjusted)
	uint8_t padding02[0x010]; // +028h to +038h: unknown
	facing_t facing;          // +038h: Facing (0 = left, 1 = right)
	uint8_t padding20[0x003]; // +039h to +03Ch: unknown
	char_id_short_t currentCharID; // +03Ch: Current(?) character ID
	uint8_t padding03[0x012]; // +03Eh to +050h: unknown
	player_coord_t xSpeed;    // +050h: X velocity
	uint8_t padding04[0x004]; // +054h to +058h: unknown
	player_coord_t ySpeed;    // +058h: Y velocity
	uint8_t padding05[0x014]; // +05Ch to +070h: unknown
	char_id_short_t currentCharID_alt1; // +070h: Current(?) character ID (alt 1)
	uint8_t padding06[0x004]; // +072h to +076h: unknown
	char_id_short_t currentCharID_alt2; // +076h: Current(?) character ID (alt 2)
	uint8_t padding07[0x004]; // +078h to +07Ch: unknown
	uint8_t statusFlags[STATUS_FLAGS_LEN]; // +07Ch to +07Fh: Status flags 1
	uint8_t padding22[0x011]; // +07Fh to +090h: unknown
	hitbox_t hitboxes[HBLISTSIZE]; // +090h to +0A4h: 1st base hitboxes list
	hitbox_t collisionBox;    // +0A4h: Collision box
	uint8_t padding19[0x00A]; // +0AAh to +0B4h: unknown
	struct player *opponent;  // +0B4h: Pointer to opponent's main struct
	struct player *opponent_alt1; // +0B8h: Opponent main struct (alt 1)
	game_pixel_t xDistance;   // +0BCh: Absolute distance (whole pixels) between
	                          //        this player's X pivot and the opponent's
	uint8_t padding09[0x016]; // +0BEh to +0D4h: unknown
	int16_t hitstun;          // +0D4h: Hit stun remaining (also used for dizzy state)
	uint8_t padding10[0x007]; // +0D6h to +0DDh: unknown
	costume_t costume;        // +0DDh: Current costume color
	uint8_t padding11[0x002]; // +0DEh to +0E0h: unknown
	uint8_t statusFlags2nd[STATUS_FLAGS_LEN_2ND]; // +0E0h to +0E4h: Status flags 2
	uint8_t padding23[0x004]; // +0E4h to +0E8h: unknown
	uint16_t superPart;       // +0E8h: Fractional super meter
	uint16_t maxGauge;        // +0EAh: Max Mode gauge
	uint8_t padding12[0x04C]; // +0ECh to +138h: unknown
	uint16_t health;          // +138h: HP
	uint8_t padding13[0x004]; // +13Ah to +13Eh: unknown
	uint16_t stunGauge;       // +13Eh: Stun (dizzy) gauge
	uint8_t padding14[0x005]; // +140h to +145h: unknown
	uint8_t stunRecover;      // +145h: Stun recovery timer
	uint16_t guardGauge;      // +146h: Guard crush gauge
	uint8_t padding15[0x010]; // +148h to +158h: unknown
	char_id_short_t currentCharID_alt3; // +158h: Current(?) character ID (alt 3)
	uint8_t padding16[0x02E]; // +15Ah to +188h: unknown
	hitbox_t throwBox;        // +188h: "Throwing" box
	hitbox_t throwableBox;    // +18Dh: "Throwable" box
	uint8_t padding21[0x011]; // +193h to +1A8h: unknown
	union
	{
		player_extra_t *extras[2];       // +1A4h to +1ACh
		struct
		{
			// these two are applicable only to KOF '02 and KOF '98 respectively
			// (not a big deal since player_extra_t's live at fixed addresses anyway)
			player_extra_t *kof02_extra; // +1A4h: Pointer to player's "extra" struct
			player_extra_t *kof98_extra; // +1A8h: Pointer to player's "extra" struct
		};
	};
	uint8_t padding17[0x004]; // +1ACh to +1B0h: unknown
	uint8_t comboCounter;     // +1B0h: Combo counter ("belongs to" opponent, not player)
	uint8_t padding18[0x023]; // +1B1h to +1D4h: unknown
	uint8_t throwableStatus2; // +1D4h: "Throwable" status flag 2 (and possibly more?)
	uint8_t padding24[0x00E]; // +1D5h to +1E3h: unknown
	uint8_t superStocks;      // +1E3h: Whole super meter stocks
} player_t;

extern boxtype_t *boxTypeMap;
extern uint8_t hitboxActiveMasks[HBLISTSIZE];
extern bool letThrowBoxesLinger;
extern int baseThrowBoxLingerTime;
extern char buttonNames[ATTACK_BUTTONS];

extern bool boxTypeCheck(boxtype_t boxType);
extern bool boxSizeCheck(hitbox_t *hitbox);
extern bool shouldShowRangeMarkerFor(player_t *player);
extern boxtype_t hitboxType(hitbox_t *hitbox);
extern boxtype_t projectileTypeEquivalentFor(boxtype_t original);
extern bool hitboxIsActive(
	player_t *player, hitbox_t *hitbox, uint8_t activeMask);
extern bool throwBoxIsActive(player_t *player, hitbox_t *hitbox);
extern bool throwableBoxIsActive(player_t *player, hitbox_t *hitbox);
extern bool collisionBoxIsActive(player_t *player, hitbox_t *hitbox);
extern bool projectileIsActive(projectile_t *projectile);

#endif /* PLAYERSTRUCT_H */
