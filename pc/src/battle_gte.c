/* Native equivalents of hand-written battle assembly that uses the GTE.
 * The original GTE register side effects are reproduced, not just results. */
#include <sys/types.h>
#include <libgte.h>
#include <inline_c.h>

/* 7399C.s: weighted sum a * 6 + 4 * b + c + 2 * d of signed 16-bit b, c, d.
 * The original computes it with MVMVA through the rotation matrix, leaving
 * R11..R33 = (b, c, d, d >> 16, 0, ...), IR = (4, 1, 2) and MAC1..3 set. */
int func_800DC284(int a, int b, int c, int d);


extern unsigned char _trig_table[];
extern psx_long VectorNormal(VECTOR*, VECTOR*);
/* 7B5DC.s trig lookup: interleaved 4-byte table entries, quadrant folding on
 * the (possibly reflected) angle; bits above 0xFFF are ignored, as in the
 * original's unmasked second lookup. */
/* 7B5DC.s: cosine (Q12, clamped to +-0x1000) between the facing `angle` and
 * the XZ direction from `from` to `to`; 0x1000 when `distance` is zero. The
 * direction is normalised by func_80041AF4, the VectorNormal core. */
int func_800E437C(short* from, short* to, int angle, unsigned distance);


/* A 32-bit guest word: the battle menu state block's address. */
extern unsigned D_800EB9B8;
extern MATRIX* func_800C085C(unsigned char*, int);
extern MATRIX* RotMatrixYXZ_gte(SVECTOR*, MATRIX*);
extern MATRIX* func_80041C68(MATRIX*, MATRIX*);
extern void func_800C02A8(void);
extern void func_800C0990(void*, void*, unsigned, int);
/* 58350.s (hand-written): draw a battle menu target shape. Its points (at the
 * shape buffer D_800EB9B8 + 0x48, count 0x32) are transformed by the GTE light
 * matrix (shape scale/rotation composed at scratchpad 0x398) plus the shape
 * origin as background colour, then projected; each point with a nonzero pad
 * draws a segment from the previous point (func_800C0990) with intensity from
 * the pair's depth. Scratchpad 0x398.. holds the current and previous
 * projected point (SXY, depth / 4). */
void func_800C0B50(unsigned char* shape, unsigned color);

