#ifndef CONFIG_H
#define CONFIG_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tchar.h>
#include <fcntl.h>
#include <io.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>
#include "gamedefs.h"
#include "boxtypes.h"
#include "colors.h"
#include "hotkeys.h"
#include "util.h"
#include "../lib/inih/ini.h"

extern void readConfigsForGame(gamedef_t *gamedef);

#endif /* CONFIG_H */
