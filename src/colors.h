#ifndef COLORS_H
#define COLORS_H

#include <string.h>
#include <GL/gl.h>
#include "boxtypes.h"

#define BOX_EDGE_ALPHA 0xFF
#define BOX_FILL_ALPHA 0x40
#define PIVOT_ALPHA 0xFF

extern GLubyte boxEdgeColors[boxTypeCount][4];
extern GLubyte boxFillColors[boxTypeCount][4];

extern GLubyte playerPivotColor[4];
extern GLubyte closeNormalRangeColor[4];

extern void initColors();

#endif /* COLORS_H */
