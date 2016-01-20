#include "util.h"

#define TIMESTAMP_LEN 20
char *timestampFormat = "[%H:%M:%S] ";

void timestamp()
{
	char buf[TIMESTAMP_LEN];
	time_t timer;
	time(&timer);
	struct tm *now = localtime(&timer);

	strftime(buf, TIMESTAMP_LEN, timestampFormat, now);
	printf(buf);
}

int strlenUntilLast(LPSTR str, TCHAR c)
{
	if (str == NULL) { return -1; }
	LPSTR lastPos = StrRChr(str, (PCTSTR)NULL, c);
	return (lastPos != (LPSTR)NULL ? (int)(lastPos - str) : -1);
}
