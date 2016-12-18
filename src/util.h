#ifndef UTIL_H
#define UTIL_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlwapi.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include "boxtypes.h"

#undef max
#undef min
// this is silly
#define max(l, r) (((l) > (r)) ? (l) : (r))
#define min(l, r) (((l) < (r)) ? (l) : (r))

#define DIGIT_CHAR_SET "0123456789"
#define UPPER_ALPHA_CHAR_SET "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define LOWER_ALPHA_CHAR_SET "abcdefghijklmnopqrstuvwxyz"
#define ALPHA_CHAR_SET (UPPER_ALPHA_CHAR_SET LOWER_ALPHA_CHAR_SET "_")
#define HEX_DIGIT_SET (DIGIT_CHAR_SET "abcdef" "ABCDEF")
#define WHITESPACE_CHAR_SET " \t" /* single-line whitespace */

extern void timestamp();
extern int strlenUntilLast(PTSTR str, TCHAR c);
extern char *strchrSet(char *str, char *targetChars);
extern size_t strlenWithinSet(char *str, char *targetChars);
extern size_t strlenUntilSet(char *str, char *targetChars);
extern char *strConcat(
	char *buf, size_t buflen, char *left, char *right, char *separator);

#endif /* UTIL_H */
