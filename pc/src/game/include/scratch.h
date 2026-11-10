#pragma once
#include <stddef.h>
#include <libgte.h>
#include "pc/src/psx_types.h"

typedef struct {
    /* 0x00 */ VECTOR position;
    /* 0x10 */ VECTOR lookAt;
    /* 0x20 */ VECTOR angles;
    /* 0x30 */ int farClip;
} vs_camera_t;

/* The scratchpad's first words: the packet cursor and the ordering table (the PS1's vs_scratch, at 0x1F800000). */
typedef struct {
    /* 0x00 */ psx_ptr(void) unk0;
    /* 0x04 */ psx_ptr(void) unk4;
    /* 0x08 */ psx_ptr(void) unk8;
    /* 0x0C */ psx_ptr(void) unkC;
} vs_scratch_t;
PSX_ASSERT_SIZE(vs_scratch_t, 0x10);

/* The scene's view: the camera and the view matrix (the PS1 kept them in the scratchpad after the packet cursor,
 * at 0x1F800010; the offsets inside are the same). Defined in 146C.c. */
typedef struct {
    /* 0x00 */ u_int firstPersonViewFacing;
    /* 0x04 */ MATRIX viewMatrix;
    /* 0x24 */ vs_camera_t camera;
} vs_view_t;
PSX_ASSERT_SIZE(vs_view_t, 0x58);

extern vs_scratch_t vs_scratch;
extern vs_view_t vs_view;
