//! Forwards a battle request to func_800A1AF8, resolving arg1 through func_800A152C first (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80077F14 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_800A1AF8 with arg1 resolved by func_800A152C (0 when arg1 is -1).
pub fn func_80077F14(arg0: c_int, arg1: c_int, arg2: ?*v.SVECTOR) callconv(.c) void {
    const var_v0: c_int = if (arg1 == -1) 0 else c.func_800A152C(arg0, arg1, 2);
    c.func_800A1AF8(arg0, var_v0, @ptrCast(arg2), 0);
}
