#include "gamestate.h"

// global, set by startupProgram() in main.c
game_state_t gameState;

void establishScreenDimensions(screen_dimensions_t *dims, gamedef_t *source)
{
	memset(dims, 0, sizeof(*dims));
	dims->basicWidth = source->basicWidth;
	dims->basicHeight = source->basicHeight;
	dims->basicWidthAsDouble = (double)source->basicWidth;
	dims->basicHeightAsDouble = (double)source->basicHeight;
	dims->basicAspect = dims->basicWidthAsDouble / dims->basicHeightAsDouble;
	dims->aspectMode = source->aspectMode;
}

void readPlayerState(game_state_t *target, int which)
{
	HANDLE handle = target->gameHandle;
	ReadProcessMemory(
		handle, target->gamedef.playerAddresses[which],
		&(target->players[which]), sizeof(player_t), NULL);
	ReadProcessMemory(
		handle, target->gamedef.playerExtraAddresses[which],
		&(target->playersExtra[which]), sizeof(player_extra_t), NULL);
	ReadProcessMemory(
		handle, target->gamedef.player2ndExtraAddresses[which],
		&(target->players2ndExtra[which]), sizeof(player_2nd_extra_t), NULL);
}

void readProjectiles(game_state_t *target)
{
	HANDLE handle = target->gameHandle;
	void *current = currentGame->projectilesListStart;
	int count = currentGame->projectilesListSize;
	int step = currentGame->projectilesListStep;
	projectile_t *next = target->projectiles;

	for (int i = 0; i < count; i++)
	{
		ReadProcessMemory(handle, current, (next + i), sizeof(projectile_t), NULL);
		current += step;
	}
}

void readGameState(game_state_t *target)
{
	HANDLE handle = target->gameHandle;
	for (int i = 0; i < PLAYERS; i++)
	{
		readPlayerState(target, i);
	}
	readProjectiles(target);
	ReadProcessMemory(
		handle, target->gamedef.cameraAddress, &(target->camera),
		sizeof(camera_t), NULL);
	getGameScreenDimensions(target->gameHwnd, target->overlayHwnd, &(target->dimensions));
}

bool shouldDisplayPlayer(game_state_t *target, int which)
{
	player_2nd_extra_t *source = &(target->players2ndExtra[which]);
	return (source->gameplayState & 0x01) == 0;
}
