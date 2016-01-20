#include "config.h"

#define DEFAULT_INI_FILE_NAME "default.ini"

int parseBoolean(const char *value, bool *target)
{
	return 0;
}

int parseColor(
	const char *value, draw_color_t *target, draw_color_channel_t defaultOpacity)
{
	return 0;
}

int handleGlobalSection(gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}


int handleColorsSection(gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}

int handlePlayerSection(
	int playerNum, gamedef_t *gamedef, const char *name, const char *value)
{
	return 0;
}

int configFileHandler(
	void* user, const char *section, const char *name, const char *value)
{
	gamedef_t *gamedef = (gamedef_t*)user;
	int result = 0;

	#define MATCH_SECTION(sectionName, handler) \
		if (strcmp(sectionName, section) == 0) \
		{ \
			result = handler(gamedef, name, value); \
			if (result != 0) \
			{ \
				return result; \
			} \
		}
	#define MATCH_PLAYER_SECTION(sectionName, playerNum, handler) \
		if (strcmp(sectionName, section) == 0) \
		{ \
			result = handler(playerNum, gamedef, name, value); \
			if (result != 0) \
			{ \
				return result; \
			} \
		}

	// semicolons not strictly needed but good for consistency's sake
	MATCH_SECTION("global", handleGlobalSection);
	MATCH_SECTION("colors", handleColorsSection);
	MATCH_PLAYER_SECTION("player1", 0, handlePlayerSection);
	MATCH_PLAYER_SECTION("player2", 1, handlePlayerSection);

	return result;
	#undef MATCH_SECTION
	#undef MATCH_PLAYER_SECTION
}

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
		printf("Config file \"%s\" not found.\n", fileName);
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
