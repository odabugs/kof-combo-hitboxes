#include "config.h"

// TODO: whine about bad config values
// TODO: use a real regex library for parsing config line values
#define DEFAULT_INI_FILE_NAME "default.ini"

int parseBoolean(const char *value, bool *target)
{
	return 0;
}

#define COLOR_CHANNELS 4
#define ALPHA_CHANNEL (COLOR_CHANNELS - 1)
#define COLOR_CHANNEL_MAX_STR_LEN 3
#define COLOR_CHANNEL_MAX_VALUE 255
int parseColor(
	const char *value, draw_color_t *target, draw_color_channel_t defaultOpacity)
{
	char channelBuf[COLOR_CHANNEL_MAX_STR_LEN + 1];
	char *pos = (char*)value, *nextpos;
	size_t posLen;
	unsigned long channelValue;
	memset(channelBuf, 0, COLOR_CHANNEL_MAX_STR_LEN + 1);
	
	for (int channel = 0; channel < COLOR_CHANNELS; channel++)
	{
		pos = strchrSet(pos, DIGIT_CHAR_SET);
		if (pos == (char*)NULL)
		{
			if (channel == ALPHA_CHANNEL)
			{
				target->a = defaultOpacity;
				return 0;
			}
			else
			{
				return -1;
			}
		}

		posLen = strlenWithinSet(pos, DIGIT_CHAR_SET);
		if (posLen == 0 || posLen > COLOR_CHANNEL_MAX_STR_LEN)
		{
			if (posLen == 0 && channel == ALPHA_CHANNEL)
			{
				target->a = defaultOpacity;
				goto bail_loop;
			}
			else
			{
				return -1;
			}
		}

		strncpy(channelBuf, pos, posLen);
		channelValue = strtoul(channelBuf, &nextpos, 10);
		if (errno == ERANGE || channelValue > COLOR_CHANNEL_MAX_VALUE)
		{
			return -1;
		}
		target->value[channel] = (draw_color_channel_t)(channelValue & 0xFF);
		pos += posLen;
	}

	bail_loop:
	return 0;
}

int handleGlobalSection(gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}

int handleColorsSection(gamedef_t *gamedef, const char *name, const char *value)
{
	int result = 0;

	for (int i = 0; i < validBoxTypes; i++)
	{
		if (strcmp(boxTypeNames[i], name) == 0) {
			result = parseColor(value, &(boxFillColors[i]), boxFillAlpha);
			if (result == 0)
			{
				memcpy(&(boxEdgeColors[i]), &(boxFillColors[i]), sizeof(draw_color_t));
				boxEdgeColors[i].a = boxEdgeAlpha;
			}
			else
			{
				return result;
			}
		}
	}

	return result;
}

int handlePlayerSection(
	int playerNum, gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}

#define MATCH_SECTION(sectionName, handler) \
	if (strcmp(sectionName, section) == 0) \
	{ \
		result = handler(gamedef, name, value); \
		POST_CHECK \
	}
#define MATCH_PLAYER_SECTION(sectionName, playerNum, handler) \
	if (strcmp(sectionName, section) == 0) \
	{ \
		result = handler(playerNum, gamedef, name, value); \
		POST_CHECK \
	}
#define POST_CHECK if (result != 0) { return result; }
int configFileHandler(
	void* user, const char *section, const char *name, const char *value)
{
	gamedef_t *gamedef = (gamedef_t*)user;
	int result = 0;

	// semicolons not strictly needed but good for consistency's sake
	MATCH_SECTION("global", handleGlobalSection);
	MATCH_SECTION("colors", handleColorsSection);
	MATCH_PLAYER_SECTION("player1", 0, handlePlayerSection);
	MATCH_PLAYER_SECTION("player2", 1, handlePlayerSection);

	return result;
}
#undef PREDICATE
#undef POST_CHECK
#undef MATCH_SECTION
#undef MATCH_PLAYER_SECTION

void readConfigFile(const char *fileName, LPCTSTR basePath, gamedef_t *gamedef)
{
	LPCTSTR tFileName = (LPCTSTR)fileName;
	TCHAR pathBuf[MAX_PATH];

	LPTSTR combineResult = PathCombine(pathBuf, basePath, tFileName);
	printf("\"%s\", base=\"%s\", file=\"%s\"\n", pathBuf, basePath, tFileName);
	if (combineResult != (LPTSTR)NULL && PathFileExists(pathBuf))
	{
		int result = ini_parse((const char*)pathBuf, configFileHandler, (void*)gamedef);
		if (result >= 0)
		{
			timestamp();
			printf("Successfully read config file \"%s\".\n", fileName);
		}
		else
		{
			timestamp();
			printf("Could not read config file \"%s\".\n", fileName);
		}
	}
	else
	{
		timestamp();
		printf("Config file \"%s\" was not found, and will be skipped.\n", fileName);
	}
}

void readConfigsForGame(gamedef_t *gamedef)
{
	TCHAR basePath[MAX_PATH];
	int basePathFullLen = GetModuleFileName((HMODULE)NULL, basePath, MAX_PATH);
	int basePathLen = strlenUntilLast(basePath, '\\');
	printf("\"%s\" full=%d len=%d\n", basePath, basePathFullLen, basePathLen);
	if (basePathLen > -1 && basePathLen < MAX_PATH - 1)
	{
		basePath[basePathLen + 1] = '\0'; // don't need executable file name
	}
	printf("\"%s\" full=%d len=%d\n", basePath, basePathFullLen, basePathLen);

	LPCTSTR tBasePath = (LPCTSTR)basePath;
	readConfigFile(DEFAULT_INI_FILE_NAME, tBasePath, gamedef);
	readConfigFile((const char*)(gamedef->configFileName), tBasePath, gamedef);
}
