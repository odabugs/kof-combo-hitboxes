#include "colors.h"

// glColor3ubv will ignore the "alpha" element, while glColor4ubv will read it
GLubyte colorset[7][4] = {
	{ 255,   0,   0, BOX_FILL_ALPHA }, // red
	{   0, 255,   0, BOX_FILL_ALPHA }, // green
	{   0,   0, 255, BOX_FILL_ALPHA }, // blue
	{ 255, 255,   0, BOX_FILL_ALPHA }, // yellow
	{ 255,   0, 255, BOX_FILL_ALPHA }, // magenta
	{ 128, 128, 128, BOX_FILL_ALPHA }, // gray
	{ 255, 255, 255, BOX_FILL_ALPHA }  // white
};
GLubyte playerPivotColor[4] = { 255, 0, 0, PIVOT_ALPHA };
