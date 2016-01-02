#ifndef COLORS_H
#define COLORS_H

#include <string.h>
#include <GL/gl.h>
#include "boxtypes.h"

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

extern draw_color_t
	playerPivotColor,
	closeNormalRangeColor,
	gaugeBorderColor,
	stunGaugeFillColor;

extern void initColors();
extern void selectColor(draw_color_t color);
extern void selectEdgeColor(boxtype_t boxType);
extern void selectFillColor(boxtype_t boxType);

#endif /* COLORS_H */
