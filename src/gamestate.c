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

	target->processID = newProcID;
	target->wHandle = wHandle;
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

bool openGame(game_state_t *target)
{
	target->wProcHandle = (HANDLE)NULL;
	DWORD procID = target->processID;

	if (procID != (DWORD)NULL)
	{
		HANDLE wProcHandle = OpenProcess(PROCESS_ALL_ACCESS, FALSE, procID);
		if (wProcHandle != INVALID_HANDLE_VALUE && wProcHandle != (HANDLE)NULL)
		{
			target->wProcHandle = wProcHandle;
			target->hdc = GetDC(target->wHandle);
			SetBkMode(target->hdc, TRANSPARENT);
			return true;
		}
	}

	return false;
}

void closeGame(game_state_t *target)
{
	ReleaseDC(target->wHandle, target->hdc);
	CloseHandle(target->wProcHandle);
	memset(target, 0, sizeof(*target));
}

void readPlayerState(game_state_t *target, int which)
{
	HANDLE handle = target->wProcHandle;
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
	HANDLE handle = target->wProcHandle;
	for (int i = 0; i < PLAYERS; i++)
	{
		readPlayerState(target, i);
	}
	ReadProcessMemory(
		handle, (void*)(target->gamedef.cameraAddress), &(target->camera),
		sizeof(camera_t), NULL);
	getGameScreenDimensions(target->wHandle, &(target->dimensions));
}

bool shouldDisplayPlayer(game_state_t *target, int which)
{
	player_2nd_extra_t *source = &(target->players2ndExtra[which]);
	return (source->gameplayState & 0x01) == 0;
}

// TODO: if player is using an EX character then this yields the non-EX equivalent
character_def_t *characterForID(game_state_t *source, int charID)
{
	if (source == (game_state_t*)NULL || charID >= source->gamedef.rosterSize)
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
