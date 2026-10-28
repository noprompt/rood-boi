//! Battle helper that forwards a vector's X and Z to a routine (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007CFF8 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs func_800A0A1C(arg0, 2), then func_800E527C(arg0, vec.vx, vec.vz).
pub fn func_8007CFF8(arg0: c_int, vec: ?*v.SVECTOR) callconv(.c) void {
    c.func_800A0A1C(arg0, 2);
    const p = vec.?;
    c.func_800E527C(arg0, @as(c_int, p.vx), @as(c_int, p.vz));
}
