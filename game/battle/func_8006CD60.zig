//! Battle helper that forwards to func_800461CC with a random offset (src/BATTLE/BATTLE.PRG/146C.c).
const common = @import("common");
const psx = common.psx;
const c = @import("c_146C");

/// orig: func_8006CD60 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800461CC with id 0x7E, the given pointer and arg1/arg2, and a random count of 8..10.
pub fn func_8006CD60(arg0: [*c]c_uint, arg1: c_int, arg2: c_int) callconv(.c) void {
    const rand: c_int = c.vs_main_getRand(3) +% 8;
    c.func_800461CC(0x7E, arg0, psx.conv(c_uint, rand), arg1, arg2);
}
