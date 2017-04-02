#include "directx.h"

#define CUSTOMFVF (D3DFVF_XYZRHW | D3DFVF_DIFFUSE)
// slight overkill, but OK
#define BOX_VERTEX_BUFFER_SIZE 100

LPDIRECT3D9 d3d;
LPDIRECT3DDEVICE9 d3dDevice;
LPDIRECT3DVERTEXBUFFER9 boxBuffer;
RECT scissorRect = { .right = (LONG)1, .bottom = (LONG)1 };
D3DPRESENT_PARAMETERS presentParams;

CUSTOMVERTEX templateVertex = { 0.0f, 0.0f, 1.0f, 1.0f, D3DCOLOR_RGBA(0, 0, 0, 0) };

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

void setupD3D(HWND hwnd, UINT w, UINT h)
{
	d3d = Direct3DCreate9(D3D_SDK_VERSION);
	memset(&presentParams, 0, sizeof(presentParams));
	presentParams.Windowed = TRUE;
	presentParams.SwapEffect = D3DSWAPEFFECT_COPY;
	presentParams.hDeviceWindow = hwnd,
	presentParams.BackBufferWidth = w;
	presentParams.BackBufferHeight = h;
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

	for (int i = 0; renderStateOptions[i].option != -1 || renderStateOptions[i].value != -1; i++)
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

	CUSTOMVERTEX *pVoid;
	IDirect3DVertexBuffer9_Lock(boxBuffer, 0, 0, (void**)&pVoid, 0);
	for (int i = 0; i < BOX_VERTEX_BUFFER_SIZE; i++)
	{
		memcpy(&(pVoid[i]), &templateVertex, sizeof(templateVertex));
	}
	IDirect3DVertexBuffer9_Unlock(boxBuffer);
}

// Takes 3 arguments: HWND for which to set up Direct3D, device width/height
// Returns 0 values
// TODO: return initialization errors
static int l_setupD3D(lua_State *L)
{
	HWND *hwnd = (HWND*)lua_topointer(L, 1);
	UINT w = (UINT)luaL_checkint(L, 2);
	UINT h = (UINT)luaL_checkint(L, 3);
	setupD3D(*hwnd, w, h);
	return 0;
}

void DXRectangleF(FLOAT leftX, FLOAT topY, FLOAT rightX, FLOAT bottomY, D3DCOLOR color)
{
	static VOID *pVoid;
	IDirect3DVertexBuffer9_Lock(boxBuffer, 0, 0, (void**)&pVoid, 0);
	CUSTOMVERTEX vertices[] = {
		{ leftX,  topY,    1.0f, 1.0f, color },
		{ rightX, topY,    1.0f, 1.0f, color },
		{ leftX,  bottomY, 1.0f, 1.0f, color },
		{ rightX, bottomY, 1.0f, 1.0f, color }
	};
	memcpy(pVoid, vertices, sizeof(vertices));
	IDirect3DVertexBuffer9_Unlock(boxBuffer);
	IDirect3DDevice9_SetStreamSource(d3dDevice, 0, boxBuffer, 0, sizeof(CUSTOMVERTEX));
	IDirect3DDevice9_DrawPrimitive(d3dDevice, D3DPT_TRIANGLESTRIP, 0, 2);
}

// Takes 5 arguments: Left X, top Y, right X, bottom Y (all integers), fill color
// Returns 0 values
static int l_DXRectangle(lua_State *L)
{
	FLOAT leftX  = luaL_checknumber(L, 1), topY    = luaL_checknumber(L, 2);
	FLOAT rightX = luaL_checknumber(L, 3), bottomY = luaL_checknumber(L, 4);
	D3DCOLOR color = (D3DCOLOR)luaL_checkint(L, 5);
	DXRectangleF(leftX, topY, rightX, bottomY, color);
	return 0;
}

// create vertices that render as a square when using D3DPT_TRIANGLELIST
#define squareTriangleList(left, top, right, bottom, color) \
	{ left,  top,    1.0f, 1.0f, color }, \
	{ right, top,    1.0f, 1.0f, color }, \
	{ left,  bottom, 1.0f, 1.0f, color }, \
	{ right, top,    1.0f, 1.0f, color }, \
	{ right, bottom, 1.0f, 1.0f, color }, \
	{ left,  bottom, 1.0f, 1.0f, color }

static void drawHitbox(
	FLOAT outerLeftX, FLOAT outerTopY, FLOAT outerRightX, FLOAT outerBottomY,
	FLOAT innerLeftX, FLOAT innerTopY, FLOAT innerRightX, FLOAT innerBottomY,
	D3DCOLOR edge, D3DCOLOR fill)
{
	static VOID *pVoid;
	IDirect3DVertexBuffer9_Lock(boxBuffer, 0, 0, (void**)&pVoid, 0);
	CUSTOMVERTEX vertices[] = {
		// inside fill
		squareTriangleList(innerLeftX,  innerTopY,    innerRightX, innerBottomY, fill),
		// left edge
		squareTriangleList(outerLeftX,  outerTopY,    innerLeftX,  outerBottomY, edge),
		// right edge
		squareTriangleList(innerRightX, outerTopY,    outerRightX, outerBottomY, edge),
		// top edge
		squareTriangleList(innerLeftX,  outerTopY,    innerRightX, innerTopY,    edge),
		// bottom edge
		squareTriangleList(innerLeftX,  innerBottomY, innerRightX, outerBottomY, edge)
	};
	memcpy(pVoid, vertices, sizeof(vertices));
	IDirect3DVertexBuffer9_Unlock(boxBuffer);
	IDirect3DDevice9_SetStreamSource(d3dDevice, 0, boxBuffer, 0, sizeof(CUSTOMVERTEX));
	IDirect3DDevice9_DrawPrimitive(d3dDevice, D3DPT_TRIANGLELIST, 0, 10);
}

#undef squareTriangleList

// Takes 10 arguments:
// - X/Y of outer top-left corner
// - X/Y of outer bottom-right corner
// - X/Y of inner top-left corner
// - X/Y of inner bottom-right corner
// - Box edge color
// - Box fill color
// Returns 0 values
static int l_drawHitbox(lua_State *L)
{
	drawHitbox(
		luaL_checknumber(L, 1), luaL_checknumber(L, 2),
		luaL_checknumber(L, 3), luaL_checknumber(L, 4),
		luaL_checknumber(L, 5), luaL_checknumber(L, 6),
		luaL_checknumber(L, 7), luaL_checknumber(L, 8),
		(D3DCOLOR)luaL_checkint(L, 9), (D3DCOLOR)luaL_checkint(L, 10)
	);
	return 0;
}

// Takes 4 arguments: Left/top and right/bottom corners of new scissor clipping area
// Returns 1 value: HRESULT from SetScissorRect() call
static int l_setScissor(lua_State *L)
{
	int left  = luaL_checkint(L, 1), top    = luaL_checkint(L, 2);
	int width = luaL_checkint(L, 3), height = luaL_checkint(L, 4);
	scissorRect.left = (LONG)left;
	scissorRect.top = (LONG)top;
	scissorRect.right = (LONG)width;
	scissorRect.bottom = (LONG)height;
	HRESULT result = IDirect3DDevice9_SetScissorRect(d3dDevice, &scissorRect);
	lua_pushinteger(L, (lua_Integer)result);
	return 1;
}

// Takes 1 optional argument: Clear color (default transparent)
// Returns 1 value: HRESULT from Clear() call
static int l_clearFrame(lua_State *L)
{
	D3DCOLOR clearColor;
	if (!lua_isnoneornil(L, 1)) { clearColor = (D3DCOLOR)luaL_checkint(L, 1); }
	else { clearColor = D3DCOLOR_RGBA(0, 0, 0, 0); }
	HRESULT result = IDirect3DDevice9_Clear(d3dDevice,
		0, NULL, D3DCLEAR_TARGET, clearColor, 1.0f, 0);
	lua_pushinteger(L, (lua_Integer)result);
	return 1;
}

// Takes 1 optional argument: Clear color (default transparent)
// Returns 1 value: HRESULT from last D3D call made (stops at first failed call)
static int l_beginFrame(lua_State *L)
{
	l_clearFrame(L);
	HRESULT result = (HRESULT)lua_tointeger(L, -1);
	if (result != D3D_OK) { goto done; }
	result = IDirect3DDevice9_BeginScene(d3dDevice);
	if (result != D3D_OK) { goto done; }
	result = IDirect3DDevice9_SetFVF(d3dDevice, CUSTOMFVF);
	done:
	lua_pushinteger(L, (lua_Integer)result);
	return 1;
}

// Takes 4 arguments: Top-left and bottom-right coords of source rect
// Returns 1 value: HRESULT from last D3D call made (stops at first failed call)
static int l_endFrame(lua_State *L)
{
	RECT sourceRect;
	sourceRect.left = (LONG)luaL_checkint(L, 1);
	sourceRect.top = (LONG)luaL_checkint(L, 2);
	sourceRect.right = (LONG)luaL_checkint(L, 3);
	sourceRect.bottom = (LONG)luaL_checkint(L, 4);
	HRESULT result = IDirect3DDevice9_EndScene(d3dDevice);
	if (result == D3D_OK)
	{
		result = IDirect3DDevice9_Present(d3dDevice, &sourceRect, NULL, NULL, NULL);
	}
	lua_pushinteger(L, (lua_Integer)result);
	return 1;
}

const luaL_Reg lib_directX[] = {
	{ "setupD3D", l_setupD3D },
	{ "rect", l_DXRectangle },
	{ "hitbox", l_drawHitbox },
	{ "setScissor", l_setScissor },
	{ "clearFrame", l_clearFrame },
	{ "beginFrame", l_beginFrame },
	{ "endFrame", l_endFrame },
	{ NULL, NULL } // sentinel
};
