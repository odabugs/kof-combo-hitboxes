#ifndef COLORS_H
#define COLORS_H

#include <string.h>
#include <GL/gl.h>
#include "boxtypes.h"

#define BOX_EDGE_ALPHA 255
#define BOX_FILL_ALPHA 128
#define PIVOT_ALPHA 255

extern GLubyte boxEdgeColors[boxTypeCount][4];
extern GLubyte boxFillColors[boxTypeCount][4];

extern GLubyte playerPivotColor[4];
extern GLubyte closeNormalRangeColor[4];

extern void initColors();

#endif /* COLORS_H */
