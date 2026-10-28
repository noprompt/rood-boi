//! Forwards a call to the battle helper func_800472D0 (src/BATTLE/BATTLE.PRG/146C.c).
const psx = @import("common").psx;
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B3F0 (src/BATTLE/BATTLE.PRG/146C.c)
/// Passes its two arguments on to func_800472D0 unchanged.
pub fn func_8007B3F0(arg0: c_int, arg1: ?*v.D_8005DC6C_t) callconv(.c) void {
    c.func_800472D0(arg0, @ptrCast(arg1));
}
