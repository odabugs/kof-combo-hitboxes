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

#define DIGIT_CHAR_SET "0123456789"
#define WHITESPACE_CHAR_SET " \t" /* single-line whitespace */

extern void timestamp();
extern int strlenUntilLast(LPSTR str, TCHAR c);
extern char *strchrSet(char *str, char *targetChars);
extern size_t strlenWithinSet(char *str, char *targetChars);
extern size_t strlenUntilSet(char *str, char *targetChars);

#endif /* UTIL_H */
