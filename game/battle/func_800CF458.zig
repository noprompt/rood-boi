//! Forwards a call to func_800CF218 (src/BATTLE/BATTLE.PRG/5BF94.c).
const common = @import("common");
const psx = common.psx;
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800CF458 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Returns func_800CF218's result for the same arguments.
pub fn func_800CF458(arg0: ?*v.func_800CF0E8_t, arg1: c_int, arg2: c_int) callconv(.c) c_int {
    const p: [*c]c.func_800CF0E8_t = @ptrCast(arg0);
    return psx.conv(c_int, c.func_800CF218(p, arg1, arg2));
}
