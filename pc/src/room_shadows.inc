/* Host-only object shadow submission, adapted from retained near-matching
 * .work/ultracode/r11-battle-b/ce15.c. See docs/decomp-blockers.md.
 * Original PS1 build keeps its assembly; runtime scene coverage is incomplete.
 *
 * The shadows of the room's moving platforms (section 12: lifts, floating
 * blocks): a flat square on the floor under each, subtractive (B-F). The
 * packets are built as the PS1 builds them; each square is also drawn
 * natively in world space (effect_native.c pc_platform_shadow_native) at a
 * translucent marker in its bucket, depth-tested against the native room
 * and darkening what is drawn under it. Without that (native drop shadows
 * off, no hardware path) the packets draw. */
extern unsigned* pc_platform_shadow_native(int index, const int centre[3], int shade, unsigned* ot_entry,
    unsigned* packet) __attribute__((weak));
extern void pc_platform_shadows_end(const void* start, const void* end) __attribute__((weak));
