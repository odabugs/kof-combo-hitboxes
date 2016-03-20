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

// like strchr, but checks for any character in targetChars
char *strchrSet(char *str, char *targetChars)
{
	if (str == NULL || targetChars == NULL) { return (char*)NULL; }

	char *current, *target;
	for (current = str; *current != '\0'; current++)
	{
		for (target = targetChars; *target != '\0'; target++)
		{
			if (*current == *target)
			{
				return current;
			}
		}
	}

	return (char*)NULL;
}

size_t strlenWithinSet(char *str, char *targetChars)
{
	if (str == NULL || targetChars == NULL) { return (size_t)0; }

	size_t result;
	for (result = 0; str[result] != '\0'; result++)
	{
		for (char *target = targetChars; *target != '\0'; target++)
		{
			if (str[result] == *target)
			{
				goto continue_outer_loop;
			}
		}

		return result;
		continue_outer_loop:
			; // no-op; C does not have Java-style "continue [label];" syntax
	}

	return result; // strlen(str) == 0 case
}

size_t strlenUntilSet(char *str, char *targetChars)
{
	if (str == NULL || targetChars == NULL) { return (size_t)0; }

	char *strEnd = strchrSet(str, targetChars);
	if (strEnd == (char*)NULL) { return strlen(str); }
	else { return (size_t)(strEnd - str); }
}

char *strConcat(
	char *buf, size_t buflen, char *left, char *right, char *separator)
{
	if (buf == NULL || buflen == 0) { return (char*)NULL; }
	if (left == NULL) { return right; }
	if (right == NULL) { return left; }

	int remaining = (int)buflen;
	memset(buf, 0, buflen);
	strncat(buf, left, remaining);

	remaining -= strlen(left);
	if (remaining <= 0) { return buf; }
	if (separator != (char*)NULL) {
		strncat(buf, separator, remaining);
		remaining -= strlen(separator);
	}

	if (remaining <= 0) { return buf; }
	if (right != (char*)NULL) {
		strncat(buf, right, remaining);
		remaining -= strlen(right);
	}

	return buf;
}
