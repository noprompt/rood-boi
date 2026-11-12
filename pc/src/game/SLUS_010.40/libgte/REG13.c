#include "common.h"
#include <libgte.h>

/* The projection is the game's screen record (pc/src/gte_value.cpp), not a register. */
extern void rood_gte_screen_set(int reg, int value);

void SetGeomScreen(long h) { rood_gte_screen_set(26, (int)h); }
