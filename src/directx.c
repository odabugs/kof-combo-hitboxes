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

d3dRenderOption_t renderStateOptions[RENDER_STATE_OPTIONS_COUNT] = {
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
	{ D3DRS_BLENDOPALPHA, D3DBLENDOP_MAX }
};

void setupD3D(HWND hwnd)
{
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

void setColor(D3DCOLOR color)
{
	currentColor = color;
}
