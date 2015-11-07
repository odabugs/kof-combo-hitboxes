#include "util.h"

#define TIMESTAMP_LEN 20
char *timestampFormat = "[%H:%M:%S]";

void timestamp()
{
	char buf[TIMESTAMP_LEN];
	time_t timer;
	time(&timer);
	struct tm *now = localtime(&timer);

	strftime(buf, TIMESTAMP_LEN, timestampFormat, now);
	printf("%s ", buf);
}
