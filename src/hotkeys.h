#ifndef HOTKEYS_H
#define HOTKEYS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winuser.h>
#include <stdbool.h>
#include "playerstruct.h"
#include "gamedefs.h"
#include "controlkey.h"
#include "util.h"

extern bool drawBoxFill;
extern bool drawThrowableBoxes;
extern bool drawThrowBoxes;
extern bool drawHitboxPivots;
extern bool drawPlayerPivots;
extern bool drawGauges;
extern atk_button_t showButtonRanges[PLAYERS];

extern void checkHotkeys();
extern void printHotkeys();

#endif /* HOTKEYS_H */
