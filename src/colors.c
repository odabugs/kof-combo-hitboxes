#include "colors.h"

draw_color_channel_t boxEdgeAlpha = 0xFF;
draw_color_channel_t boxFillAlpha = 0x40;
draw_color_channel_t pivotAlpha = 0xFF;
draw_color_channel_t closeNormalRangeAlpha = 0xFF;
draw_color_channel_t gaugeBorderAlpha = 0xFF;
draw_color_channel_t gaugeFillAlpha = 0xA0;

// must be in the same order as the boxtype_t enum (see boxtypes.h)
draw_color_t defaultEdgeColors[totalBoxTypes] = {
	[BOX_COLLISION]         = { .value = { 0x00, 0xFF, 0x00, 0xFF } },
	[BOX_VULNERABLE]        = { .value = { 0x77, 0x77, 0xFF, 0xFF } },
	[BOX_COUNTER_VULN]      = { .value = { 0x77, 0x77, 0xFF, 0xFF } },
	[BOX_ANYWHERE_VULN]     = { .value = { 0x77, 0x77, 0xFF, 0xFF } },
	[BOX_OTG_VULN]          = { .value = { 0x77, 0x77, 0xFF, 0xFF } },
	[BOX_GUARD]             = { .value = { 0xCC, 0xCC, 0xFF, 0xFF } },
	[BOX_ATTACK]            = { .value = { 0xFF, 0x00, 0x00, 0xFF } },
	[BOX_PROJECTILE_VULN]   = { .value = { 0x00, 0xFF, 0xFF, 0xFF } },
	[BOX_PROJECTILE_ATTACK] = { .value = { 0xFF, 0x66, 0xFF, 0xFF } },
	[BOX_THROWABLE]         = { .value = { 0xF0, 0xF0, 0xF0, 0xFF } },
	[BOX_THROW]             = { .value = { 0xFF, 0xFF, 0x00, 0xFF } },
	// invalid box types - don't show boxes of these types onscreen,
	// colors defined for sake of completeness
	[validBoxTypes]         = { .value = { 0x00, 0x00, 0x00, 0xFF } },
	[BOX_DUMMY]             = { .value = { 0x00, 0x00, 0x00, 0xFF } }
};
// initialized during startup and while reading the config file
draw_color_t defaultFillColors[totalBoxTypes];
draw_color_t boxEdgeColors[totalBoxTypes];
draw_color_t boxFillColors[totalBoxTypes];

draw_color_t
	playerPivotColor      = { .value = { 0xFF, 0xFF, 0xFF, 0xFF } },
	closeNormalRangeColor = { .value = { 0x00, 0xC0, 0xC0, 0xFF } };
draw_color_t
	gaugeBorderColor      = { .value = { 0x00, 0x00, 0x00, 0xFF } },
	stunGaugeFillColor    = { .value = { 0xE0, 0xB0, 0x90, 0xA0 } },
	stunRecoverGaugeFillColor = { .value = { 0xFF, 0x00, 0x00, 0xA0 } },
	guardGaugeFillColor   = { .value = { 0xA0, 0xC0, 0xE0, 0xA0 } };

void initColors()
{
	memcpy(defaultFillColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	for (int i = 0; i < validBoxTypes; i++) // don't use totalBoxTypes here
	{
		defaultFillColors[i].a = boxFillAlpha;
		defaultEdgeColors[i].a = boxEdgeAlpha;
	}

	memcpy(boxEdgeColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	memcpy(boxFillColors, defaultFillColors, sizeof(defaultFillColors));

	playerPivotColor.a = pivotAlpha;
	closeNormalRangeColor.a = closeNormalRangeAlpha;
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
