#include "gamestate.h"
// TODO: Don't compile with _UNICODE defined for now or THE WORLD WILL EXPLODE

// returns true if we found a running game window that we recognize
// (if more than one is out there, this stops at the first successful find)
bool detectGame(game_state_t *target, gamedef_t gamedefs[])
{
	DWORD newProcID = (DWORD)NULL;
	HWND wHandle = (HWND)NULL;
	LPCTSTR title;
	bool success = false;

	for (int i = 0; gamedefs[i].windowTitle != (char*)NULL; i++)
	{
		title = gamedefs[i].windowTitle;
		wHandle = FindWindow(NULL, title);
		if (wHandle != (HWND)NULL)
		{
			newProcID = (DWORD)NULL;
			GetWindowThreadProcessId(wHandle, &newProcID);
			if (newProcID != (DWORD)NULL)
			{
				success = true;
				gamedef_t *pGamedef = &(gamedefs[i]);
				memcpy(&(target->gamedef), pGamedef, sizeof(*pGamedef));
				establishScreenDimensions(&(target->dimensions), pGamedef);
				break;
			}
			else
			{
				// don't hand back any non-null whatevers if we found nothing
				wHandle = (HWND)NULL;
			}
		}
	}

	target->gameProcessID = newProcID;
	target->gameHwnd = wHandle;
	return success;
}

void establishScreenDimensions(
	screen_dimensions_t *dims, gamedef_t *source)
{
	memset(dims, 0, sizeof(*dims));
	dims->basicWidth = source->basicWidth;
	dims->basicHeight = source->basicHeight;
	dims->basicWidthAsDouble = (double)source->basicWidth;
	dims->basicHeightAsDouble = (double)source->basicHeight;
	dims->basicAspect = dims->basicWidthAsDouble / dims->basicHeightAsDouble;
	dims->basicGroundOffset = source->groundOffset;
	dims->aspectMode = source->aspectMode;
}

#define PFD_SUPPORT_COMPOSITION 0x00008000
void setupGL(game_state_t *target)
{
	PIXELFORMATDESCRIPTOR pfd;
	//int iPixelFormat = GetPixelFormat(target->gameHdc);
	int iPixelFormat = 1;
	int iMax = DescribePixelFormat(target->gameHdc, iPixelFormat, sizeof(pfd), &pfd);
	pfd.dwFlags |= (PFD_SUPPORT_COMPOSITION | PFD_SUPPORT_OPENGL);
	SetPixelFormat(target->gameHdc, iPixelFormat, &pfd);
	target->hglrc = wglCreateContext(target->gameHdc);
	wglMakeCurrent(target->gameHdc, target->hglrc);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_ALPHA_TEST);
	glEnable(GL_DEPTH_TEST);
	glClearColor(1.0f, 0.0f, 0.0f, 0.0f); // transparent
}

bool openGame(game_state_t *target)
{
	target->gameHandle = (HANDLE)NULL;
	DWORD procID = target->gameProcessID;

	if (procID != (DWORD)NULL)
	{
		HANDLE wProcHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, procID);
		if (wProcHandle != INVALID_HANDLE_VALUE && wProcHandle != (HANDLE)NULL)
		{
			target->gameHandle = wProcHandle;
			target->gameHdc = GetDC(target->gameHwnd);
			setupGL(target);
			SetBkMode(target->gameHdc, TRANSPARENT);
			return true;
		}
	}

	return false;
}

void closeGame(game_state_t *target)
{
	ReleaseDC(target->gameHwnd, target->gameHdc);
	CloseHandle(target->gameHandle);
	wglMakeCurrent(NULL, NULL);
	wglDeleteContext(target->hglrc);
	memset(target, 0, sizeof(*target));
}

void readPlayerState(game_state_t *target, int which)
{
	HANDLE handle = target->gameHandle;
	ReadProcessMemory(
		handle, (void*)(target->gamedef.playerAddresses[which]),
		&(target->players[which]), sizeof(player_t), NULL);
	ReadProcessMemory(
		handle, (void*)(target->players[which].extra),
		&(target->playersExtra[which]), sizeof(player_extra_t), NULL);
	ReadProcessMemory(
		handle, (void*)(target->gamedef.player2ndExtraAddresses[which]),
		&(target->players2ndExtra[which]), sizeof(player_2nd_extra_t), NULL);
}

void readGameState(game_state_t *target)
{
	HANDLE handle = target->gameHandle;
	for (int i = 0; i < PLAYERS; i++)
	{
		readPlayerState(target, i);
	}
	ReadProcessMemory(
		handle, (void*)(target->gamedef.cameraAddress), &(target->camera),
		sizeof(camera_t), NULL);
	getGameScreenDimensions(target->gameHwnd, &(target->dimensions));
}

bool shouldDisplayPlayer(game_state_t *target, int which)
{
	player_2nd_extra_t *source = &(target->players2ndExtra[which]);
	return (source->gameplayState & 0x01) == 0;
}

// TODO: if player is using an EX character then this yields the non-EX equivalent
character_def_t *characterForID(game_state_t *source, int charID)
{
	if (source == (game_state_t*)NULL || charID < 0 || charID >= source->gamedef.rosterSize)
	{
		return (character_def_t*)NULL;
	}
	return &(source->gamedef.roster[charID]);
}

char *characterNameForID(game_state_t *source, int charID)
{
	character_def_t *result = characterForID(source, charID);
	if (result == (character_def_t*)NULL)
	{
		return "INVALID";
	}
	return result->charName;
}
