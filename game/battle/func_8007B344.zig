//! Battle forwarder: passes its five arguments on to func_800478E0 (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007B344 (src/BATTLE/BATTLE.PRG/146C.c)
/// Forwards its five arguments to func_800478E0, sign-extending the three shorts to int.
pub fn func_8007B344(arg0: c_int, arg1: c_int, arg2: c_short, arg3: c_short, arg4: c_short) callconv(.c) void {
    c.func_800478E0(arg0, arg1, @as(c_int, arg2), @as(c_int, arg3), @as(c_int, arg4));
}
