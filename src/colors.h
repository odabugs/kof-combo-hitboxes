#ifndef COLORS_H
#define COLORS_H

#include <string.h>
#include <GL/gl.h>
#include "boxtypes.h"

typedef GLubyte draw_color_channel_t;

typedef union draw_color
{
	struct
	{
		draw_color_channel_t r;
		draw_color_channel_t g;
		draw_color_channel_t b;
		draw_color_channel_t a;
	};
	draw_color_channel_t value[4];
} draw_color_t;

extern draw_color_channel_t boxEdgeAlpha;
extern draw_color_channel_t boxFillAlpha;
extern draw_color_channel_t pivotAlpha;
extern draw_color_channel_t closeNormalRangeAlpha;
extern draw_color_channel_t gaugeBorderAlpha;
extern draw_color_channel_t gaugeFillAlpha;

extern draw_color_t defaultEdgeColors[totalBoxTypes];
extern draw_color_t defaultFillColors[totalBoxTypes];
extern draw_color_t boxEdgeColors[totalBoxTypes];
extern draw_color_t boxFillColors[totalBoxTypes];

extern draw_color_t playerPivotColor;
extern draw_color_t closeNormalRangeColor;
extern draw_color_t gaugeBorderColor;
extern draw_color_t stunGaugeFillColor;
extern draw_color_t stunRecoverGaugeFillColor;
extern draw_color_t guardGaugeFillColor;

extern void initColors();
extern void selectColor(draw_color_t color);
extern void selectEdgeColor(boxtype_t boxType);
extern void selectFillColor(boxtype_t boxType);

#endif /* COLORS_H */
