#ifndef DIRECTX_H
#define DIRECTX_H

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#define CINTERFACE
#include <d3d9.h>
#include <stdbool.h>
#include <luajit.h>
#include <lauxlib.h>

#define CUSTOMFVF (D3DFVF_XYZRHW | D3DFVF_DIFFUSE)
// slight overkill, but OK
#define BOX_VERTEX_BUFFER_SIZE 100
#define MASK_32BITS 0xFFFFFFFF

typedef struct customVertexFormat {
	FLOAT x, y, z, rhw;
	D3DCOLOR color;
} CUSTOMVERTEX;

typedef struct d3dRenderOption {
	D3DRENDERSTATETYPE option;
	DWORD value;
} d3dRenderOption_t;

extern LPDIRECT3D9 d3d;
extern LPDIRECT3DDEVICE9 d3dDevice;
// vertex buffer used for drawing square shapes (box fills, thick box edge lines)
extern LPDIRECT3DVERTEXBUFFER9 boxBuffer;
extern CUSTOMVERTEX templateBoxBuffer[BOX_VERTEX_BUFFER_SIZE];
extern UINT screenWidth, screenHeight;
extern D3DCOLOR currentColor;
extern d3dRenderOption_t renderStateOptions[];
extern const luaL_Reg lib_directX[];

extern void setupD3D(HWND hwnd);
extern void DXRectangle(int leftX, int topY, int rightX, int botomY);
extern void setColor(D3DCOLOR color);
extern void setScissor(int width, int height);
extern void clearFrame();
extern void beginFrame();
extern void endFrame();

#endif /* DIRECTX_H */
