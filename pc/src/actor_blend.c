/* BATTLE/48C7C.s func_800B147C. Keep the GTE's signed 16-bit inputs,
 * fixed-point rounding and conditional stores, including the retained IR3
 * when a rotation's Z delta is zero in the original instruction sequence. */
#include <sys/types.h>
#include <libgte.h>
#include <inline_c.h>
extern void func_800AE980(void*, void*, int);
extern void* vs_main_memcpy(void*, const void*, unsigned);
extern void pc_unimplemented(const char*);
void func_800B147C(void* destination, void* source, int count, int step, int duration);

