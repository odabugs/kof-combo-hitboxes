#ifndef CONTROLKEY_H
#define CONTROLKEY_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#include <stdbool.h>

#define KEY_DOWN (1 << 15)
#define KEY_TOGGLED 1
#define KEY_PRESSED (KEY_DOWN | KEY_TOGGLED)

extern bool keyIsDown(int vkCode);
extern bool keyIsUp(int vkCode);
extern bool keyIsPressed(int vkCode);
extern bool keyIsReleased(int vkCode);

#endif /* CONTROLKEY_H */
