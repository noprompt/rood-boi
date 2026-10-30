//! Clears the two camera views and runs the battle camera setup (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF3F8 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Resets the camera state, then runs the setup for `effect` with `arg1`, returning its result.
pub fn func_800CF3F8(arg0: ?*v.func_800CF0E8_t, arg1: c_int) callconv(.c) c_int {
    c.func_800D7890(0);
    c.func_800D1B18(psx.cptr(c.D_800F54D8_t, v.g.D_800F55A8()));
    c.func_800D1B18(psx.cptr(c.D_800F54D8_t, v.g.D_800F54D8()));
    return @as(c_int, c.func_800CF218(@ptrCast(arg0), 0, arg1));
}
