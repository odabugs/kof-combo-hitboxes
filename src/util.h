#ifndef UTIL_H
#define UTIL_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>

#undef max
#undef min
// this is silly
#define max(l, r) (((l) > (r)) ? (l) : (r))
#define min(l, r) (((l) < (r)) ? (l) : (r))

extern void timestamp();
extern int strlenUntilLast(LPSTR str, TCHAR c);

#endif /* UTIL_H */
