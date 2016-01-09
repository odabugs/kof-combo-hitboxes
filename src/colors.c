#include "colors.h"

#define BOX_EDGE_ALPHA 0xFF
#define BOX_FILL_ALPHA 0x40
#define PIVOT_ALPHA 0xFF
#define GAUGE_BORDER_ALPHA 0xFF
#define GAUGE_FILL_ALPHA 0xA0

draw_color_t defaultEdgeColors[totalBoxTypes] = {
	[BOX_COLLISION]         = { .value = { 0x00, 0xFF, 0x00, BOX_EDGE_ALPHA } },
	[BOX_VULNERABLE]        = { .value = { 0x77, 0x77, 0xFF, BOX_EDGE_ALPHA } },
	[BOX_GUARD]             = { .value = { 0xCC, 0xCC, 0xFF, BOX_EDGE_ALPHA } },
	[BOX_ATTACK]            = { .value = { 0xFF, 0x00, 0x00, BOX_EDGE_ALPHA } },
	[BOX_PROJECTILE_VULN]   = { .value = { 0x00, 0xFF, 0xFF, BOX_EDGE_ALPHA } },
	[BOX_PROJECTILE_ATTACK] = { .value = { 0xFF, 0x66, 0xFF, BOX_EDGE_ALPHA } },
	[BOX_THROWABLE]         = { .value = { 0xF0, 0xF0, 0xF0, BOX_EDGE_ALPHA } },
	[BOX_THROW]             = { .value = { 0xFF, 0xFF, 0x00, BOX_EDGE_ALPHA } },
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
	playerPivotColor      = { .value = { 0xFF, 0xFF, 0xFF, PIVOT_ALPHA } },
	closeNormalRangeColor = { .value = { 0x00, 0xC0, 0xC0, PIVOT_ALPHA } };
draw_color_t
	gaugeBorderColor      = { .value = { 0x00, 0x00, 0x00, GAUGE_BORDER_ALPHA } },
	stunGaugeFillColor    = { .value = { 0xE0, 0xB0, 0x90, GAUGE_FILL_ALPHA } },
	stunRecoverGaugeFillColor = { .value = { 0xFF, 0x00, 0x00, GAUGE_FILL_ALPHA } },
	guardGaugeFillColor = { .value = { 0xA0, 0xC0, 0xE0, GAUGE_FILL_ALPHA } };

void initColors()
{
	memcpy(defaultFillColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	for (int i = 0; i < validBoxTypes; i++) // don't use totalBoxTypes here
	{
		defaultFillColors[i].a = BOX_FILL_ALPHA;
	}
	defaultFillColors[BOX_THROWABLE].a >>= 1; // make throwable box fill less garish

	memcpy(boxEdgeColors, defaultEdgeColors, sizeof(defaultEdgeColors));
	memcpy(boxFillColors, defaultFillColors, sizeof(defaultFillColors));
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
