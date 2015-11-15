#include "colors.h"

// glColor3ubv will ignore the "alpha" element, while glColor4ubv will read it
GLubyte colorset[7][4] = {
	{ 255,   0,   0, BOX_EDGE_ALPHA }, // red
	{   0, 255,   0, BOX_EDGE_ALPHA }, // green
	{   0,   0, 255, BOX_EDGE_ALPHA }, // blue
	{ 255, 255,   0, BOX_EDGE_ALPHA }, // yellow
	{ 255,   0, 255, BOX_EDGE_ALPHA }, // magenta
	{ 128, 128, 128, BOX_EDGE_ALPHA }, // gray
	{ 255, 255, 255, BOX_EDGE_ALPHA }  // white
};

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
}
