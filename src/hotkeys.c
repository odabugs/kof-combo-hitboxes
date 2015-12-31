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

void checkRangeMarkerHotkey(int which)
{
	atk_button_t showRange = showButtonRanges[which];

	if (keyIsPressed(showButtonRangeHotkeys[which]))
	{
		showRange = ++showRange % (SHOW_NO_BUTTON_RANGES + 1);
		showButtonRanges[which] = showRange;

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

void checkHotkeys()
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

	for (int which = 0; which < PLAYERS; which++)
	{
		checkRangeMarkerHotkey(which);
	}
}

void printHotkeys()
{
	printf(
		"\n"
		"Hotkeys:\n"
		"F1 - Toggle close normal range marker (player 1)\n"
		"F2 - Toggle close normal range marker (player 2)\n"
		"F3 - Toggle drawing hitbox fills\n"
		"F4 - Toggle drawing hitbox center axes\n"
		"F5 - Toggle drawing \"throwable\"-type boxes\n"
		"F6 - Toggle drawing \"throw\"-type boxes\n"
		"\n"
		"Press Q in this console window to exit the hitbox viewer.\n"
	);
}
