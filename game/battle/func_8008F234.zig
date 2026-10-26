//! Frees the background layout block and closes its companion state
//! (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8008F234 (src/BATTLE/BATTLE.PRG/146C.c)
/// Clears the flag, and if a background layout is held, closes it, frees it and returns 1; otherwise returns 0.
pub fn func_8008F234() callconv(.c) c_int {
    v.g.D_800F1DC9().* = 0;
    if (v.g.D_800F1DCC().* != null) {
        v.g.D_800F1DC9().* = 0;
        _ = c.func_8007E0A8(
            @as(c_uint, v.g.D_800F1DC8().*),
            @as(c_uint, @as(u32, @bitCast(@as(i32, v.g.D_800F1DBE().*)))),
            5,
        );
        c.vs_main_freeHeapR(v.g.D_800F1DCC().*);
        v.g.D_800F1DCC().* = null;
        return 1;
    }
    return 0;
}
