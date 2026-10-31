//! Battle unit 146C: a call to func_8009F314 with a null second argument (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_8007C348 (src/BATTLE/BATTLE.PRG/146C.c)
/// Calls func_8009F314 with arg0, a null pointer, and arg1.
pub fn func_8007C348(arg0: c_int, arg1: c_int) callconv(.c) void {
    c.func_8009F314(arg0, null, arg1);
}
