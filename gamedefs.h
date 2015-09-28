#ifndef GAMEDEFS_H
#define GAMEDEFS_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
//#include <tchar.h>
#include <stdlib.h>
#include "playerstruct.h"

#define PLAYERS 2

typedef struct gamedef
{
	char *windowTitle;
	void *playerAddresses[2];
	void *cameraAddress;
} gamedef_t;

extern gamedef_t gamedefs_list[];

#endif /* GAMEDEFS_H */
