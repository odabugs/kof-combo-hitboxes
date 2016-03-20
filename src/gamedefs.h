#ifndef GAMEDEFS_H
#define GAMEDEFS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <stdbool.h>
#include "playerstruct.h"
#include "boxtypes.h"
#include "coords.h"
#include "colors.h"

#define PLAYERS 2

typedef struct character_definition
{
	character_id_t charID;
	char *charName;
} character_def_t;

// for info on the range, color and placement of a single gauge onscreen
// TODO: factor this out into its own thing
typedef struct
{
	player_coords_t borderTopLeft;
	player_coords_t borderBottomRight;
	player_coords_t fillTopLeft;
	player_coords_t fillBottomRight;
	draw_color_t borderColor;
	draw_color_t fillColor;
	int maxValue;
	int minValue;
	double maxValueDbl;
	double minValueDbl;
	bool isVertical;
	union
	{
		bool fillFromRightToLeft;
		bool fillFromBottomUp;
	};
} gauge_info_t;

// for info applicable to mirrored pairs of gauges (e.g., stun gauges used by p1/p2)
typedef struct
{
	// max value of gauge (min value is 0)
	int gaugeMax;
	// relative to the the top-center of the screen
	// (p1 is offset to the left, p2 to the right, both offset down)
	player_coords_t gaugeOffset;
	// for the "inside" area of the gauge (border not counted)
	player_coords_t gaugeSize;
} gauge_pair_info_t;

typedef struct game_definition
{
	LPCTSTR windowClassName;
	char *shortName;
	char *configFileName;
	char *configSectionPrefix;
	void *playerAddresses[PLAYERS];
	void *playerExtraAddresses[PLAYERS];
	void *player2ndExtraAddresses[PLAYERS];
	void *cameraAddress;
	void *projectilesListStart;
	int projectilesListSize;
	int projectilesListStep;
	// since '98 and '02 player_extra_t pointers are at different offsets in player_t
	int extraStructIndex;
	// should be the width:height closest to 1:1 scale for onscreen objects
	// (e.g., use 320x224 for kof98/02 even though the smallest resolution
	// offered by the steam versions is 640x448 which amounts to 2:1 scale)
	union
	{
		struct
		{
			int basicWidth;
			int basicHeight;
		};
		screen_coords_t basicSize;
	};
	char *recommendResolution;
	char *extraRecommendations;
	aspect_mode_t aspectMode; // how does the game handle widescreen?
	int rosterSize;
	character_def_t *roster;
	boxtype_t *boxTypeMapSource;
	boxtype_t boxTypeMap[0x100];
	// information used for drawing the stun meters
	bool showStunGauge; // if false, show stun gauge empty except during stun recovery
	bool showGuardGauge; // if false, hide the guard gauge entirely
	gauge_pair_info_t stunGaugeInfo; 
	gauge_pair_info_t stunRecoverGaugeInfo; 
	gauge_pair_info_t guardGaugeInfo; 
	gauge_info_t stunGauges[PLAYERS];
	gauge_info_t stunRecoverGauges[PLAYERS];
	gauge_info_t guardGauges[PLAYERS]; // not used for 02UM (it has in-game guard gauges)
} gamedef_t;

extern gamedef_t *currentGame;
extern gamedef_t *gamedefs_list[];

extern void setupGamedef(gamedef_t *gamedef);
extern void setupBoxTypeMap(gamedef_t *gamedef);
extern character_def_t *characterForID(int charID);
extern char *characterNameForID(int charID);

#endif /* GAMEDEFS_H */
