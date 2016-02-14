#include "config.h"

// TODO: use a real regex library for parsing config line values
#define DEFAULT_INI_FILE_NAME "default.ini"
#define POST_CHECK if (result != 0) \
	{ \
		whine(); \
		currentName = (const char*)NULL; \
	} \
	return result;
const char *currentSection, *currentName;

char *booleanTrueValues[] = {
	"true", "t",
	"yes", "y",
	"enabled", "e",
	"on",
	(char*)NULL
};
char *booleanFalseValues[] = {
	"false", "f",
	"no", "n",
	"disabled", "d",
	"off",
	(char*)NULL
};

void whine()
{
	if (currentSection == NULL || currentName == NULL) { return; }
	timestamp();
	printf("Could not read value for option \"%s\" under section \"%s\".  "
		"Using default value.\n",
		currentName, currentSection);
}

int testBoolean(char *value, char *targetStrs[], bool *target, bool newValue)
{
	for (int i = 0; targetStrs[i] != (char*)NULL; i++)
	{
		if (stricmp(value, targetStrs[i]) == 0)
		{
			*target = newValue;
			return 0;
		}
	}

	return -1;
}

int parseBoolean(const char *value, bool *target)
{
	char strBuf[10];
	memset(strBuf, 0, 10);
	char *pos = strchrSet((char*)value, ALPHA_CHAR_SET);
	if (pos != (char*)NULL)
	{
		size_t posLen = strlenWithinSet(pos, ALPHA_CHAR_SET);
		strncpy(strBuf, pos, posLen);

		if (testBoolean(strBuf, booleanTrueValues, target, true) == 0) { return 0; }
		if (testBoolean(strBuf, booleanFalseValues, target, false) == 0) { return 0; }
	}

	return -1;
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
	target->a = defaultOpacity;
	
	for (int channel = 0; channel < COLOR_CHANNELS; channel++)
	{
		pos = strchrSet(pos, DIGIT_CHAR_SET);
		if (pos == (char*)NULL && channel != ALPHA_CHANNEL)
		{
			return -1;
		}

		posLen = strlenWithinSet(pos, DIGIT_CHAR_SET);
		if (posLen == 0 || posLen > COLOR_CHANNEL_MAX_STR_LEN)
		{
			if (posLen == 0 && channel == ALPHA_CHANNEL)
			{
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

int parseAlphaChannel(const char *value, draw_color_channel_t *target)
{
	char channelBuf[COLOR_CHANNEL_MAX_STR_LEN + 1];
	char *pos = (char*)value, *nextpos;
	size_t posLen;
	unsigned long channelValue;
	memset(channelBuf, 0, COLOR_CHANNEL_MAX_STR_LEN + 1);

	pos = strchrSet(pos, DIGIT_CHAR_SET);
	if (pos == (char*)NULL)
	{
		return -1;
	}

	posLen = strlenWithinSet(pos, DIGIT_CHAR_SET);
	if (posLen == 0 || posLen > COLOR_CHANNEL_MAX_STR_LEN)
	{
		return -1;
	}

	strncpy(channelBuf, pos, posLen);
	channelValue = strtoul(channelBuf, &nextpos, 10);
	if (errno == ERANGE || channelValue > COLOR_CHANNEL_MAX_VALUE)
	{
		return -1;
	}
	*target = (draw_color_channel_t)(channelValue & 0xFF);
	return 0;
}

#define MATCH_COLOR(colorName, target, defaultOpacity) \
	if (strcmp(colorName, name) == 0) \
	{ \
		currentName = name; \
		result = parseColor(value, &(target), defaultOpacity); \
		POST_CHECK \
	}
int handleColorsSection(gamedef_t *gamedef, const char *name, const char *value)
{
	int result = -1;
	draw_color_t colorBuf;

	for (int i = 0; i < validBoxTypes; i++)
	{
		if (strcmp(boxTypeNames[i], name) == 0) {
			currentName = name;
			result = parseColor(value, &colorBuf, boxFillAlpha);
			if (result == 0)
			{
				memcpy(&(boxFillColors[i]), &colorBuf, sizeof(colorBuf));
				memcpy(&(boxEdgeColors[i]), &colorBuf, sizeof(colorBuf));
				boxEdgeColors[i].a = boxEdgeAlpha;
				return result;
			}
		}
	}

	MATCH_COLOR("playerPivot", playerPivotColor, pivotAlpha);
	MATCH_COLOR("rangeMarker", closeNormalRangeColor, closeNormalRangeAlpha);
	MATCH_COLOR("gaugeBorder", gaugeBorderColor, gaugeBorderAlpha);
	MATCH_COLOR("stunGauge", stunGaugeFillColor, gaugeFillAlpha);
	MATCH_COLOR("stunRecoveryGauge", stunRecoverGaugeFillColor, gaugeFillAlpha);
	MATCH_COLOR("guardGauge", guardGaugeFillColor, gaugeFillAlpha);

	return result;

}
#undef MATCH_COLOR

#define MATCH_BOOLEAN(valueName, target) \
	if (strcmp(valueName, name) == 0) \
	{ \
		currentName = name; \
		result = parseBoolean(value, &(target)); \
		POST_CHECK \
	}
#define MATCH_ALPHA_CHANNEL(propName, target) \
	if (strcmp(propName, name) == 0) \
	{ \
		currentName = name; \
		result = parseAlphaChannel(value, &(target)); \
		POST_CHECK \
	}
int handleGlobalSection(gamedef_t *gamedef, const char *name, const char *value)
{
	int result = -1;

	MATCH_ALPHA_CHANNEL("boxEdgeOpacity", boxEdgeAlpha);
	MATCH_ALPHA_CHANNEL("boxFillOpacity", boxFillAlpha);
	MATCH_ALPHA_CHANNEL("rangeMarkerOpacity", closeNormalRangeAlpha);
	MATCH_ALPHA_CHANNEL("gaugeBorderOpacity", gaugeBorderAlpha);
	MATCH_ALPHA_CHANNEL("gaugeFillOpacity", gaugeFillAlpha);

	MATCH_BOOLEAN("drawBoxFill", drawBoxFill);
	MATCH_BOOLEAN("drawBoxPivot", drawHitboxPivots);
	MATCH_BOOLEAN("drawPlayerPivot", drawPlayerPivots);
	MATCH_BOOLEAN("drawGauges", drawGauges);

	return result;
}

int handlePlayerSection(
	int playerNum, gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}
#undef MATCH_BOOLEAN

#define MATCH_SECTION(sectionName, handler) \
	if (strcmp(sectionName, section) == 0) \
	{ \
		currentSection = section; \
		result = handler(gamedef, name, value); \
		POST_CHECK \
	}
#define MATCH_PLAYER_SECTION(sectionName, playerNum, handler) \
	if (strcmp(sectionName, section) == 0) \
	{ \
		currentSection = section; \
		result = handler(playerNum, gamedef, name, value); \
		POST_CHECK \
	}
int configFileHandler(
	void* user, const char *section, const char *name, const char *value)
{
	gamedef_t *gamedef = (gamedef_t*)user;
	int result = -1;
	currentName = (const char*)NULL;

	// semicolons not strictly needed but good for consistency's sake
	MATCH_SECTION("global", handleGlobalSection);
	MATCH_SECTION("colors", handleColorsSection);
	MATCH_PLAYER_SECTION("player1", 0, handlePlayerSection);
	MATCH_PLAYER_SECTION("player2", 1, handlePlayerSection);

	return result;
}
#undef MATCH_SECTION
#undef MATCH_PLAYER_SECTION

void readConfigFile(const char *fileName, LPCTSTR basePath, gamedef_t *gamedef)
{
	LPCTSTR tFileName = (LPCTSTR)fileName;
	TCHAR pathBuf[MAX_PATH];

	LPTSTR combineResult = PathCombine(pathBuf, basePath, tFileName);
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
	if (basePathLen > -1 && basePathLen < MAX_PATH - 1)
	{
		basePath[basePathLen + 1] = '\0'; // don't need executable file name
	}

	LPCTSTR tBasePath = (LPCTSTR)basePath;
	readConfigFile(DEFAULT_INI_FILE_NAME, tBasePath, gamedef);
	readConfigFile((const char*)(gamedef->configFileName), tBasePath, gamedef);
}
