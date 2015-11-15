#include "colors.h"

GLubyte boxEdgeColors[boxTypeCount][4] = {
	[BOX_COLLISION]         = { 0x00, 0xFF, 0x00, BOX_EDGE_ALPHA },
	[BOX_VULNERABLE]        = { 0x77, 0x77, 0xFF, BOX_EDGE_ALPHA },
	[BOX_GUARD]             = { 0xCC, 0xCC, 0xFF, BOX_EDGE_ALPHA },
	[BOX_ATTACK]            = { 0xFF, 0x00, 0x00, BOX_EDGE_ALPHA },
	[BOX_PROJECTILE_VULN]   = { 0x00, 0xFF, 0xFF, BOX_EDGE_ALPHA },
	[BOX_PROJECTILE_ATTACK] = { 0xFF, 0x66, 0xFF, BOX_EDGE_ALPHA },
	[BOX_THROWABLE]         = { 0xF0, 0xF0, 0xF0, BOX_EDGE_ALPHA },
	[BOX_THROW]             = { 0xFF, 0xFF, 0x00, BOX_EDGE_ALPHA },
};
// initialized during startup
GLubyte boxFillColors[boxTypeCount][4];

GLubyte playerPivotColor[4] = { 255, 0, 0, PIVOT_ALPHA }; // red
GLubyte closeNormalRangeColor[4] = { 0, 128, 128, PIVOT_ALPHA }; // teal

void initColors()
{
	memcpy(boxFillColors, boxEdgeColors, sizeof(boxEdgeColors));
	for (int i = 0; i < boxTypeCount; i++)
	{
		boxFillColors[i][3] = BOX_FILL_ALPHA;
	}
	boxFillColors[BOX_THROWABLE][3] >>= 1; // make throwable box fill less garish
}
