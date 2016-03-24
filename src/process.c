#include "process.h"

// used for detecting which window is currently in focus when users presses hotkey
HWND myself;
HANDLE myStdin;
SHORT quitKey = 0x51; // Q key

LRESULT CALLBACK WindowProc(
	HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
		default:
			return DefWindowProc(hwnd, message, wParam, lParam);
	}

	return 0;
}

void startupProgram(HINSTANCE hInstance)
{
	initColors();
	if (!detectGame(&gameState, gamedefs_list))
	{
		printf("Failed to detect any supported game running.\n");
		goto bailout;
	}
	if (gameState.gameProcessID == (DWORD)NULL)
	{
		printf("Could not find target window.\n");
		goto bailout;
	}
	openGame(&gameState, hInstance, WindowProc);
	if (gameState.gameHandle == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handle to target process.\n");
		goto bailout;
	}
	myself = GetConsoleWindow();
	myStdin = GetStdHandle(STD_INPUT_HANDLE);
	if (myself == (HWND)NULL || myStdin == INVALID_HANDLE_VALUE)
	{
		printf("Failed to obtain handles to this console window.\n");
		goto bailout;
	}

	return;
	bailout:
	printf("Exiting now.\n");
	exit(EXIT_FAILURE);
}

void cleanupProgram()
{
	closeGame(&gameState);
	timestamp();
	printf("Exiting now.\n");
}

// returns true if we found a running game window that we recognize
// (if more than one is out there, this stops at the first successful find)
bool detectGame(game_state_t *target, gamedef_t *gamedefs[])
{
	DWORD newProcID = (DWORD)NULL;
	HWND wHandle = (HWND)NULL;
	gamedef_t *pGamedef;

	for (int i = 0; gamedefs[i] != (gamedef_t*)NULL; i++)
	{
		pGamedef = gamedefs[i];
		wHandle = FindWindow(pGamedef->windowClassName, (LPCTSTR)NULL);
		if (wHandle != (HWND)NULL)
		{
			newProcID = (DWORD)NULL;
			GetWindowThreadProcessId(wHandle, &newProcID);
			if (newProcID != (DWORD)NULL)
			{
				memcpy(&(target->gamedef), pGamedef, sizeof(*pGamedef));
				establishScreenDimensions(&(target->dimensions), pGamedef);
				target->gameProcessID = newProcID;
				target->gameHwnd = wHandle;
				return true;
			}
			else
			{
				// don't hand back any non-null whatevers if we found nothing
				wHandle = (HWND)NULL;
			}
		}
	}

	return false;
}

void setupD3D(game_state_t *target)
{
	gamedef_t *gamedef = &(target->gamedef);
	d3d = Direct3DCreate9(D3D_SDK_VERSION);
	D3DPRESENT_PARAMETERS presentParams;
	memset(&presentParams, 0, sizeof(presentParams));
	presentParams.Windowed = TRUE;
	presentParams.SwapEffect = D3DSWAPEFFECT_FLIP;
	presentParams.hDeviceWindow = target->overlayHwnd;
	screenWidth = (UINT)GetSystemMetrics(SM_CXSCREEN);
	screenHeight = (UINT)GetSystemMetrics(SM_CYSCREEN);
	presentParams.BackBufferWidth = screenWidth;
	presentParams.BackBufferHeight = screenHeight;
	presentParams.BackBufferFormat = D3DFMT_A8R8G8B8;

	IDirect3D9_CreateDevice(
		d3d,
		D3DADAPTER_DEFAULT,
		D3DDEVTYPE_HAL,
		target->overlayHwnd,
		D3DCREATE_HARDWARE_VERTEXPROCESSING,
		&presentParams,
		&d3dDevice);

	for (int i = 0; i < RENDER_STATE_OPTIONS_COUNT; i++)
	{
		IDirect3DDevice9_SetRenderState(
			d3dDevice,
			renderStateOptions[i].option,
			renderStateOptions[i].value);
	}

	IDirect3DDevice9_CreateVertexBuffer(
		d3dDevice,
		BOX_VERTEX_BUFFER_SIZE * sizeof(CUSTOMVERTEX),
		0, // mandatory if CreateDevice used D3DCREATE_HARDWARE_VERTEXPROCESSING
		CUSTOMFVF,
		D3DPOOL_MANAGED,
		&boxBuffer,
		NULL);

	VOID *pVoid;
	IDirect3DVertexBuffer9_Lock(boxBuffer, 0, 0, (void**)&pVoid, 0);
	memcpy(pVoid, templateBoxBuffer, sizeof(templateBoxBuffer));
	IDirect3DVertexBuffer9_Unlock(boxBuffer);
}

// TODO: real handling of failure conditions
bool createOverlayWindow(game_state_t *target)
{
	LPCTSTR title = _T("KOF Combo Hitbox Viewer");
	HWND overlayHwnd;
	ATOM atom;
	WNDCLASSEX windowClass;
	memset(&windowClass, 0, sizeof(WNDCLASSEX));
	windowClass.style = (CS_HREDRAW | CS_VREDRAW);
	windowClass.lpfnWndProc = target->wndProc;
	windowClass.hInstance = target->hInstance;
	windowClass.lpszMenuName = title;
	windowClass.lpszClassName = title;
	windowClass.cbSize = sizeof(WNDCLASSEX);
	windowClass.cbClsExtra = 0;
	windowClass.cbWndExtra = 0;
	windowClass.hIcon = NULL;
	windowClass.hIconSm = NULL;
	windowClass.hCursor = NULL;
	windowClass.hbrBackground = NULL;

	atom = RegisterClassEx(&windowClass);
	if (!atom)
	{
		return false;
	}

	overlayHwnd = CreateWindowEx(
		(WS_EX_TOPMOST | WS_EX_COMPOSITED | WS_EX_TRANSPARENT | WS_EX_LAYERED),
		title,
		title,
		WS_POPUP,
		// overlay window position/size will get updated by the message loop
		0, 0, 1, 1,
		NULL,
		NULL,
		target->hInstance,
		NULL);
	target->overlayHwnd = overlayHwnd;
	if (overlayHwnd == (HWND)NULL)
	{
		return false;
	}

	// ensure that window composition is supported
	target->dwmapi = LoadLibrary(_T("dwmapi.dll"));
	if (target->dwmapi == (HMODULE)NULL)
	{
		return false;
	}
	dwm_extend_frame_fn dwmExtendFrame = (dwm_extend_frame_fn)GetProcAddress(
		target->dwmapi, "DwmExtendFrameIntoClientArea");
	dwm_comp_enabled_fn dwmCompositionEnabled = (dwm_comp_enabled_fn)GetProcAddress(
		target->dwmapi, "DwmIsCompositionEnabled");
	if ((void*)dwmExtendFrame == NULL || (void*)dwmCompositionEnabled == NULL)
	{
		return false;
	}

	BOOL compEnabled;
	dwmCompositionEnabled(&compEnabled);
	if (compEnabled == FALSE)
	{
		return false;
	}

	MARGINS margins = {-1, -1, -1, -1};
	if (dwmExtendFrame(overlayHwnd, &margins) != S_OK)
	{
		return false;
	}

	ShowWindow(overlayHwnd, SW_SHOWNORMAL);
	UpdateWindow(overlayHwnd);
	return true;
}

bool openGame(game_state_t *target, HINSTANCE hInstance, WNDPROC wndProc)
{
	target->hInstance = hInstance;
	target->wndProc = wndProc;
	target->gameHandle = (HANDLE)NULL;
	DWORD procID = target->gameProcessID;

	if (procID != (DWORD)NULL)
	{
		HANDLE wProcHandle = OpenProcess(PROCESS_VM_READ, FALSE, procID);
		if (wProcHandle != INVALID_HANDLE_VALUE && wProcHandle != (HANDLE)NULL)
		{
			target->gameHandle = wProcHandle;
			target->gameHdc = GetDC(target->gameHwnd);
			createOverlayWindow(target);
			target->overlayHdc = GetDC(target->overlayHwnd);
			currentGame = &(target->gamedef);
			setupBoxTypeMap(currentGame);
			boxTypeMap = (boxtype_t*)&(currentGame->boxTypeMap);
			screenDims = &(target->dimensions);
			int projectilesCount = currentGame->projectilesListSize;
			target->projectiles = calloc(projectilesCount, sizeof(projectile_t));
			printf("Game detected: %s\n", currentGame->shortName);
			readConfigsForGame(currentGame);
			setupGamedef(currentGame);
			setupD3D(target);
			return true;
		}
	}

	return false;
}

void closeGame(game_state_t *target)
{
	ReleaseDC(target->gameHwnd, target->gameHdc);
	ReleaseDC(target->overlayHwnd, target->overlayHdc);
	CloseHandle(target->gameHandle);
	free(target->projectiles);
	memset(target, 0, sizeof(*target));
}

bool checkShouldContinueRunning(char **reason)
{
	if (keyIsPressed(quitKey) && (GetForegroundWindow() == myself))
	{
		FlushConsoleInputBuffer(myStdin);
		*reason = "User closed the hitbox viewer.";
		return false;
	}
	// IsWindow() can potentially return true if the window handle is
	// recycled, but we're checking it frequently enough to be a non-issue
	if (!IsWindow(gameState.gameHwnd))
	{
		*reason = "User closed the game as it was running.";
		return false;
	}
	return true;
}

// don't draw boxes if the game or viewer console window aren't in focus
bool checkShouldRenderScene()
{
	HWND currentWindow = GetForegroundWindow();
	if (currentWindow == gameState.gameHwnd) { return true; }
	if (currentWindow == gameState.overlayHwnd) { return true; }
	if (currentWindow == myself) { return true; }
	return false;
}
