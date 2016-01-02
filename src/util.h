#ifndef UTIL_H
#define UTIL_H

#include <stdio.h>
#include <time.h>

#undef max
#undef min
// this is silly
#define max(l, r) (((l) > (r)) ? (l) : (r))
#define min(l, r) (((l) < (r)) ? (l) : (r))

extern void timestamp();

#endif /* UTIL_H */
