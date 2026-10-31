//! Counts down the battle's text-buffer timer and frees the buffer when it expires (src/BATTLE/BATTLE.PRG/5BF94.c).
const psx = @import("common").psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D278C (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Decrements D_800F5600; on reaching 1 frees the buffer in D_800F55FC, clears it and the counter.
pub fn func_800D278C() callconv(.c) void {
    if (v.g.D_800F5600().* == 1) {
        if (v.g.D_800F55FC().*) |buf| {
            c.vs_main_freeHeapR(buf);
            psx.put(v.g.D_800F55FC(), null);
        }
        v.g.D_800F5600().* = 0;
        return;
    }
    v.g.D_800F5600().* -%= 1;
}
