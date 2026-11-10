#pragma once
/* The scene's view as the host units read it (the game's vs_view, scratch.h: the first-person/facing word, the
 * view matrix and the camera, 0x58 bytes). The host units do not include the game's headers. */
extern unsigned char vs_view[0x58];
#define PC_VIEW_FACING (*(const unsigned*)(vs_view + 0x00))
#define PC_VIEW_MATRIX (vs_view + 0x04)
