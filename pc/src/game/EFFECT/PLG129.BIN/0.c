#include "common.h"

#define VS_RING_FUNCTION func_800F9800
#define VS_RING_COLORS D_800FD5A8
#define VS_RING_TRANSPOSED
#include "pc/src/game/EFFECT/rings.h"

#define VS_MESH10_FUNCTION func_800FA424
#define VS_MESH10_VERTICES D_800FD5E8
#define VS_MESH10_FACES D_800FD638
#include "pc/src/game/EFFECT/meshes10.h"

#define VS_SURFACE_FUNCTION func_800FAF30
#define VS_SURFACE_VERTICES D_800FD698
#define VS_SURFACE_REPEAT
#include "pc/src/game/EFFECT/surfaces.h"

#define VS_RING_FUNCTION func_800FBAC8
#define VS_RING_COLORS D_800FD918
#include "pc/src/game/EFFECT/rings.h"

#define VS_ROTATING_SURFACE_REPEAT
#define VS_ROTATING_SURFACE_FUNCTION func_800FC6EC
#include "pc/src/game/EFFECT/rotatingSurfaces.h"
