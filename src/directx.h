#ifndef DIRECTX_H
#define DIRECTX_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define CINTERFACE
#include <d3d9.h>
#include <stdbool.h>
#include <luajit.h>
#include <lauxlib.h>

typedef struct customVertexFormat {
	FLOAT x, y, z, rhw;
	D3DCOLOR color;
} CUSTOMVERTEX;

typedef struct d3dRenderOption {
	D3DRENDERSTATETYPE option;
	DWORD value;
} d3dRenderOption_t;

extern UINT screenWidth, screenHeight;
extern const luaL_Reg lib_directX[];

extern void setupD3D(HWND hwnd);
extern void DXRectangle(int leftX, int topY, int rightX, int botomY);
extern void setColor(D3DCOLOR color);
extern void setScissor(int width, int height);
extern void clearFrame();
extern void beginFrame();
extern void endFrame();

#endif /* DIRECTX_H */
