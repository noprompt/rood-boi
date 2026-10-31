//! Forwards the D_800F5310 table and the caller's argument to func_800CFE98 (src/BATTLE/BATTLE.PRG/5BF94.c).
const v = @import("views_5BF94");
const c = @import("c_5BF94");

/// orig: func_800D0B08 (src/BATTLE/BATTLE.PRG/5BF94.c)
/// Calls func_800CFE98 with the D_800F5310 table and `arg0`.
pub fn func_800D0B08(arg0: ?*v.func_800CFE98_t) callconv(.c) void {
    c.func_800CFE98(@ptrCast(v.g.D_800F5310()), @ptrCast(arg0));
}
