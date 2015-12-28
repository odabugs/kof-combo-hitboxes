#ifndef COLORS_H
#define COLORS_H

#include <string.h>
#include <GL/gl.h>
#include "boxtypes.h"

#define BOX_EDGE_ALPHA 0xFF
#define BOX_FILL_ALPHA 0x40
#define PIVOT_ALPHA 0xFF

typedef union draw_color
{
	struct
	{
		GLubyte r;
		GLubyte g;
		GLubyte b;
		GLubyte a;
	};
	GLubyte value[4];
} draw_color_t;

extern draw_color_t boxEdgeColors[totalBoxTypes];
extern draw_color_t boxFillColors[totalBoxTypes];

extern draw_color_t playerPivotColor;
extern draw_color_t closeNormalRangeColor;

extern void initColors();
extern void selectEdgeColor(boxtype_t boxType);
extern void selectFillColor(boxtype_t boxType);

#endif /* COLORS_H */
