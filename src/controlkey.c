#include "controlkey.h"

#define KEY_DOWN (1 << 15)
#define KEY_TOGGLED 1
#define KEY_PRESSED (KEY_DOWN | KEY_TOGGLED)
#define pollKey GetAsyncKeyState

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
