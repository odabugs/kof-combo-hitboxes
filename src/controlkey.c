#include "controlkey.h"

#define pollKey GetKeyState

bool keyIsDown(int vkCode)
{
	SHORT result = pollKey(vkCode);
	return (result & KEY_DOWN != 0);
}

bool keyIsUp(int vkCode)
{
	SHORT result = pollKey(vkCode);
	return (result & KEY_DOWN == 0);
}

bool keyIsPressed(int vkCode)
{
	SHORT result = pollKey(vkCode);
	return ((result & KEY_DOWN != 0) && (result & KEY_TOGGLED != 0));
}

bool keyIsReleased(int vkCode)
{
	SHORT result = pollKey(vkCode);
	return ((result & KEY_DOWN == 0) && (result & KEY_TOGGLED != 0));
}
