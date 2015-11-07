#ifndef CONTROLKEY_H
#define CONTROLKEY_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#include <stdbool.h>

extern bool keyIsDown(int vkCode);
extern bool keyIsUp(int vkCode);
extern bool keyIsPressed(int vkCode);
extern bool keyIsReleased(int vkCode);

#endif /* CONTROLKEY_H */
