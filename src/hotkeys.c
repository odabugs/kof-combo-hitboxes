#include "hotkeys.h"

bool drawBoxFill = true;
bool drawThrowableBoxes = true;
bool drawThrowBoxes = true;
bool drawHitboxPivots = true;
atk_button_t showButtonRanges[PLAYERS] = {
	SHOW_NO_BUTTON_RANGES,
	SHOW_NO_BUTTON_RANGES
};
SHORT showButtonRangeHotkeys[PLAYERS] = {
	VK_F1,
	VK_F2
};
SHORT showBoxFillHotkey = VK_F3;
SHORT showHitboxPivotsHotkey = VK_F4;
SHORT showThrowableBoxesHotkey = VK_F5;
SHORT showThrowBoxesHotkey = VK_F6;

atk_button_t updateRangeMarkerChoice(int which)
{
	atk_button_t showRange = showButtonRanges[which];
	bool updated = false;

	if (keyIsPressed(showButtonRangeHotkeys[which]))
	{
		showRange = ++showRange % (SHOW_NO_BUTTON_RANGES + 1);
		showButtonRanges[which] = showRange;
		updated = true;
	}

	if (updated)
	{
		timestamp();
		if (showRange == SHOW_NO_BUTTON_RANGES)
		{
			printf(
				"Disabled close normal range marker for player %d.\n",
				(which + 1));
		}
		else
		{
			printf(
				"Showing close standing %c activation range for player %d.\n",
				buttonNames[showButtonRanges[which]], (which + 1));
		}
	}

	return showRange;
}

void checkToggleHotkey(SHORT vkCode, bool *target, char *message)
{
	bool oldStatus = *target;
	if (keyIsPressed(vkCode))
	{
		*target = !oldStatus;
		timestamp();
		printf("%s %s.\n", (oldStatus ? "Disabled" : "Enabled"), message);
	}
}

void checkMiscHotkeys()
{
	checkToggleHotkey(
		showBoxFillHotkey, &drawBoxFill,
		"drawing hitbox fills");
	checkToggleHotkey(
		showThrowableBoxesHotkey, &drawThrowableBoxes,
		"drawing throwable boxes");
	checkToggleHotkey(
		showThrowBoxesHotkey, &drawThrowBoxes,
		"drawing throw boxes");
	checkToggleHotkey(
		showHitboxPivotsHotkey, &drawHitboxPivots,
		"drawing hitbox center axes");
}
