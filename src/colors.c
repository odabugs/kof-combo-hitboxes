#include "colors.h"

draw_color_channel_t boxEdgeAlpha = 0xFF;
draw_color_channel_t boxFillAlpha = 0x40;
draw_color_channel_t pivotAlpha = 0xFF;
draw_color_channel_t gaugeBorderAlpha = 0xFF;
draw_color_channel_t gaugeFillAlpha = 0xA0;

draw_color_t defaultEdgeColors[totalBoxTypes] = {
	[BOX_COLLISION]         = { .value = { 0x00, 0xFF, 0x00, 0x00 } },
	[BOX_VULNERABLE]        = { .value = { 0x77, 0x77, 0xFF, 0x00 } },
	[BOX_GUARD]             = { .value = { 0xCC, 0xCC, 0xFF, 0x00 } },
	[BOX_ATTACK]            = { .value = { 0xFF, 0x00, 0x00, 0x00 } },
	[BOX_PROJECTILE_VULN]   = { .value = { 0x00, 0xFF, 0xFF, 0x00 } },
	[BOX_PROJECTILE_ATTACK] = { .value = { 0xFF, 0x66, 0xFF, 0x00 } },
	[BOX_THROWABLE]         = { .value = { 0xF0, 0xF0, 0xF0, 0x00 } },
	[BOX_THROW]             = { .value = { 0xFF, 0xFF, 0x00, 0x00 } },
	// invalid box types - don't show boxes of these types onscreen,
	// colors defined for sake of completeness
	[validBoxTypes]         = { .value = { 0x00, 0x00, 0x00, 0x00 } },
	[BOX_DUMMY]             = { .value = { 0x00, 0x00, 0x00, 0x00 } }
};
// initialized during startup
draw_color_t defaultFillColors[totalBoxTypes];
draw_color_t boxEdgeColors[totalBoxTypes];
draw_color_t boxFillColors[totalBoxTypes];

draw_color_t
	playerPivotColor      = { .value = { 0xFF, 0xFF, 0xFF, 0x00 } },
	closeNormalRangeColor = { .value = { 0x00, 0xC0, 0xC0, 0x000 } };
draw_color_t
	gaugeBorderColor      = { .value = { 0x00, 0x00, 0x00, 0x00 } },
	stunGaugeFillColor    = { .value = { 0xE0, 0xB0, 0x90, 0x00 } },
	stunRecoverGaugeFillColor = { .value = { 0xFF, 0x00, 0x00, 0x00 } },
	guardGaugeFillColor   = { .value = { 0xA0, 0xC0, 0xE0, 0x00 } };

void initColors()
{
	memcpy(defaultFillColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	for (int i = 0; i < validBoxTypes; i++) // don't use totalBoxTypes here
	{
		defaultFillColors[i].a = boxFillAlpha;
		defaultEdgeColors[i].a = boxEdgeAlpha;
	}
	//defaultFillColors[BOX_THROWABLE].a >>= 1; // make throwable box fill less garish

	memcpy(boxEdgeColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	memcpy(boxFillColors, defaultFillColors, sizeof(defaultFillColors));

	playerPivotColor.a = pivotAlpha;
	closeNormalRangeColor.a = pivotAlpha;
	gaugeBorderColor.a = gaugeBorderAlpha;
	stunGaugeFillColor.a = gaugeFillAlpha;
	stunRecoverGaugeFillColor.a = gaugeFillAlpha;
	guardGaugeFillColor.a = gaugeFillAlpha;
}

void selectColor(draw_color_t color)
{
	glColor4ubv(color.value);
}

void selectEdgeColor(boxtype_t boxType)
{
	selectColor(boxEdgeColors[boxType]);
}

void selectFillColor(boxtype_t boxType)
{
	selectColor(boxFillColors[boxType]);
}
