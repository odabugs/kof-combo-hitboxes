#include "gamedefs.h"
#include "kof98/kof98_gamedef.h"
#include "kof02/kof02_gamedef.h"

gamedef_t *currentGame;

// list ender - DO NOT REMOVE THIS
gamedef_t gamedefSentinel =
{
	.windowClassName = (LPCTSTR)NULL
};

gamedef_t *gamedefs_list[] = {
	#ifndef NO_KOF_98
	&kof98_gamedef,
	#endif
	#ifndef NO_KOF_02
	&kof02_gamedef,
	#endif
	&gamedefSentinel
};

// kids, don't write code like this
void setupStunGauges(gamedef_t *gamedef)
{
	gauge_info_t *gauge;
	gauge_pair_info_t *stunGaugeInfo = &(gamedef->stunGaugeInfo);
	player_coords_t axis;
	player_coords_t *pAxis = &axis;
	getScreenEdgeInWorldCoords(pAxis, HORZ_CENTER, VERT_TOP_EDGE);

	// setup p2 stun gauge
	gauge = &(gamedef->stunGauges[1]);
	memset(gauge, 0, sizeof(*gauge));
	gauge->borderColor = gaugeBorderColor;
	gauge->fillColor = stunGaugeFillColor;
	gauge->isVertical = false;
	gauge->minValue = 0;
	gauge->maxValue = stunGaugeInfo->gaugeMax;
	gauge->minValueDbl = (double)gauge->minValue;
	gauge->maxValueDbl = (double)gauge->maxValue;
	gauge->fillFromRightToLeft = false;
	copyAndAdjust(&(gauge->fillTopLeft), pAxis, &(stunGaugeInfo->gaugeOffset));
	copyAndAdjust(&(gauge->fillBottomRight),
		&(gauge->fillTopLeft), &(stunGaugeInfo->gaugeSize));
	copyAndAdjustByValues(&(gauge->borderTopLeft), &(gauge->fillTopLeft), -1, -1);
	copyAndAdjustByValues(&(gauge->borderBottomRight), &(gauge->fillBottomRight), 1, 1);

	// setup p1 stun gauge (flipped version of p2 gauge)
	gauge = &(gamedef->stunGauges[0]);
	memcpy(gauge, &(gamedef->stunGauges[1]), sizeof(*gauge));
	gauge->fillFromRightToLeft = true;
	flipXOnAxis(&(gauge->borderTopLeft), pAxis);
	flipXOnAxis(&(gauge->borderBottomRight), pAxis);
	flipXOnAxis(&(gauge->fillTopLeft), pAxis);
	flipXOnAxis(&(gauge->fillBottomRight), pAxis);
	swapXComponents(&(gauge->borderTopLeft), &(gauge->borderBottomRight));
	swapXComponents(&(gauge->fillTopLeft), &(gauge->fillBottomRight));
}

void setupStunRecoverGauges(gamedef_t *gamedef)
{
	gauge_info_t *gauge;
	int maxValue = gamedef->stunRecoverGaugeInfo.gaugeMax;
	for (int i = 0; i < PLAYERS; i++)
	{
		gauge = &(gamedef->stunRecoverGauges[i]);
		memcpy(gauge, &(gamedef->stunGauges[i]), sizeof(*gauge));
		gauge->fillColor = stunRecoverGaugeFillColor;
		gauge->maxValue = maxValue;
		gauge->maxValueDbl = (double)maxValue;
	}
}

void setupGuardGauges(gamedef_t *gamedef)
{
	gauge_info_t *gauge;
	int maxValue = gamedef->guardGaugeInfo.gaugeMax;
	int xOff = 0, yOff = 5;
	for (int i = 0; i < PLAYERS; i++)
	{
		gauge = &(gamedef->guardGauges[i]);
		memcpy(gauge, &(gamedef->stunGauges[i]), sizeof(*gauge));
		gauge->fillColor = guardGaugeFillColor;
		gauge->maxValue = maxValue;
		gauge->maxValueDbl = (double)maxValue;
		adjustWorldCoords(&(gauge->borderTopLeft), xOff, yOff);
		adjustWorldCoords(&(gauge->borderBottomRight), xOff, yOff);
		adjustWorldCoords(&(gauge->fillTopLeft), xOff, yOff);
		adjustWorldCoords(&(gauge->fillBottomRight), xOff, yOff);
	}
}

// performs runtime setup with info provided statically in the gamedef struct
void setupGamedef(gamedef_t *gamedef)
{
	setupStunGauges(gamedef);
	setupStunRecoverGauges(gamedef);
	if (gamedef->showGuardGauge)
	{
		setupGuardGauges(gamedef);
	}
}

void setupBoxTypeMap(gamedef_t *gamedef) {
	memcpy(&(gamedef->boxTypeMap), gamedef->boxTypeMapSource, 0x100);
}

// TODO: if player is using an EX character then this yields the non-EX equivalent
character_def_t *characterForID(int charID)
{
	if (charID < 0 || charID >= currentGame->rosterSize)
	{
		return (character_def_t*)NULL;
	}
	return &(currentGame->roster[charID]);
}

char *characterNameForID(int charID)
{
	character_def_t *result = characterForID(charID);
	return ((result == (character_def_t*)NULL) ? "INVALID" : result->charName);
}
