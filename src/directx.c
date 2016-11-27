#include "directx.h"

LPDIRECT3D9 d3d;
LPDIRECT3DDEVICE9 d3dDevice;
LPDIRECT3DVERTEXBUFFER9 boxBuffer;
UINT screenWidth, screenHeight;
D3DCOLOR currentColor;

CUSTOMVERTEX templateBoxBuffer[BOX_VERTEX_BUFFER_SIZE] = {
	{ 0.0f, 0.0f, 1.0f, 1.0f, D3DCOLOR_RGBA(0, 0, 0, 0) },
	{ 0.0f, 0.0f, 1.0f, 1.0f, D3DCOLOR_RGBA(0, 0, 0, 0) },
	{ 0.0f, 0.0f, 1.0f, 1.0f, D3DCOLOR_RGBA(0, 0, 0, 0) },
	{ 0.0f, 0.0f, 1.0f, 1.0f, D3DCOLOR_RGBA(0, 0, 0, 0) }
};

d3dRenderOption_t renderStateOptions[] = {
	{ D3DRS_ZENABLE, FALSE },
	{ D3DRS_LIGHTING, FALSE },
	{ D3DRS_CULLMODE, D3DCULL_NONE },
	{ D3DRS_SCISSORTESTENABLE, TRUE },
	{ D3DRS_ALPHABLENDENABLE, TRUE },
	{ D3DRS_SRCBLEND, D3DBLEND_SRCALPHA },
	{ D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA },
	{ D3DRS_BLENDOP, D3DBLENDOP_ADD },
	{ D3DRS_SEPARATEALPHABLENDENABLE, TRUE },
	{ D3DRS_SRCBLENDALPHA, D3DBLEND_SRCALPHA },
	{ D3DRS_DESTBLENDALPHA, D3DBLEND_INVSRCALPHA },
	{ D3DRS_BLENDOPALPHA, D3DBLENDOP_MAX },
	{ -1, -1 } // sentinel
};

void setupD3D(HWND hwnd)
{
	printf("hwnd = 0x%08p\n", hwnd);
	d3d = Direct3DCreate9(D3D_SDK_VERSION);
	D3DPRESENT_PARAMETERS presentParams;
	memset(&presentParams, 0, sizeof(presentParams));
	presentParams.Windowed = TRUE;
	presentParams.SwapEffect = D3DSWAPEFFECT_FLIP;
	presentParams.hDeviceWindow = hwnd,
	screenWidth = (UINT)GetSystemMetrics(SM_CXSCREEN);
	screenHeight = (UINT)GetSystemMetrics(SM_CYSCREEN);
	presentParams.BackBufferWidth = screenWidth;
	presentParams.BackBufferHeight = screenHeight;
	presentParams.BackBufferFormat = D3DFMT_A8R8G8B8;

	IDirect3D9_CreateDevice(
		d3d,
		D3DADAPTER_DEFAULT,
		D3DDEVTYPE_HAL,
		hwnd,
		// D3DCREATE_FPU_PRESERVE is necessary to avoid undefined behavior with LuaJIT
		D3DCREATE_HARDWARE_VERTEXPROCESSING | D3DCREATE_FPU_PRESERVE,
		&presentParams,
		&d3dDevice);

	for (int i = 0; renderStateOptions[i].option != -1 && renderStateOptions[i].value != -1; i++)
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

// Takes 1 mandatory argument: HWND for which to set up Direct3D
// Returns 0 values
// TODO: return initialization errors
static int l_setupD3D(lua_State *L)
{
	HWND *hwnd = (HWND*)lua_topointer(L, -1);
	printf("hwnd = 0x%08p, *hwnd = 0x%08p\n", hwnd, *hwnd);
	setupD3D(*hwnd);
	return 0;
}

void DXRectangle(int leftX, int topY, int rightX, int bottomY)
{
	static VOID *pVoid;
	IDirect3DVertexBuffer9_Lock(boxBuffer, 0, 0, (void**)&pVoid, 0);
	CUSTOMVERTEX vertices[] = {
		{ leftX,  topY,    1.0f, 1.0f, currentColor },
		{ rightX, topY,    1.0f, 1.0f, currentColor },
		{ leftX,  bottomY, 1.0f, 1.0f, currentColor },
		{ rightX, bottomY, 1.0f, 1.0f, currentColor }
	};
	memcpy(pVoid, vertices, sizeof(CUSTOMVERTEX) * 4);
	IDirect3DVertexBuffer9_Unlock(boxBuffer);
	IDirect3DDevice9_SetStreamSource(d3dDevice, 0, boxBuffer, 0, sizeof(CUSTOMVERTEX));
	IDirect3DDevice9_DrawPrimitive(d3dDevice, D3DPT_TRIANGLESTRIP, 0, 2);
	//printf("(%d, %d) to (%d, %d)\n", leftX, topY, rightX, bottomY);
}

// Takes 4 mandatory arguments: Left X, top Y, right X, bottom Y (all integers)
// Optional 5th argument: Color to use for this draw call (uses current color otherwise)
// Returns 0 values
static int l_DXRectangle(lua_State *L)
{
	D3DCOLOR newColor = 0, oldColor = currentColor;
	bool haveNewColor = false;
	// if we got a 5th argument for the color, use it then restore old color after
	if (lua_type(L, 5) == LUA_TNUMBER)
	{
		newColor = (D3DCOLOR)luaL_checkint(L, 5);
		setColor(newColor);
		haveNewColor = true;
	}
	int leftX = luaL_checkint(L, 1), topY = luaL_checkint(L, 2);
	int rightX = luaL_checkint(L, 3), bottomY = luaL_checkint(L, 4);
	DXRectangle(leftX, topY, rightX, bottomY);
	if (haveNewColor) { setColor(oldColor); }
	return 0;
}

void setColor(D3DCOLOR color)
{
	currentColor = color;
}

// Takes 1 mandatory argument: New color to set as current color
// Returns 1 value: Old color (the prior current color before this function call)
static int l_setColor(lua_State *L)
{
	D3DCOLOR oldColor = currentColor;
	D3DCOLOR newColor = (D3DCOLOR)luaL_checkint(L, -1);
	currentColor = newColor;
	lua_Integer toPush = ((lua_Integer)oldColor) & MASK_32BITS;
	lua_pushinteger(L, toPush);
	return 1;
}

// Takes 0 arguments
// Returns 1 value: Current color
static int l_getColor(lua_State *L)
{
	lua_Integer toPush = ((lua_Integer)currentColor) & MASK_32BITS;
	lua_pushinteger(L, toPush);
	return 1;
}

void beginFrame()
{
	IDirect3DDevice9_Clear(d3dDevice, 0, NULL, D3DCLEAR_TARGET, D3DCOLOR_RGBA(0, 0, 0, 0), 1.0f, 0);
	IDirect3DDevice9_BeginScene(d3dDevice);
	IDirect3DDevice9_SetFVF(d3dDevice, CUSTOMFVF);
}

void endFrame()
{
	IDirect3DDevice9_EndScene(d3dDevice);
	IDirect3DDevice9_Present(d3dDevice, NULL, NULL, NULL, NULL);
}

// Takes 0 arguments
// Returns 0 values
static int l_beginFrame(lua_State *L)
{
	beginFrame();
	return 0;
}

// Takes 0 arguments
// Returns 0 values
static int l_endFrame(lua_State *L)
{
	endFrame();
	return 0;
}

static const luaL_Reg lib_directX[] = {

	{ "setupD3D", l_setupD3D },
	{ "rect", l_DXRectangle },
	{ "getColor", l_getColor },
	{ "setColor", l_setColor },
	{ "beginFrame", l_beginFrame },
	{ "endFrame", l_endFrame },
	{ NULL, NULL } // sentinel
};

int l_registerDirectX(lua_State *L)
{
	luaL_register(L, NULL, lib_directX);
	return 1;
}
