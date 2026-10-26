//! Stores two battle globals through its pointer arguments (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8008EB04 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores D_800F1DCA (unsigned) through arg0 and D_800F1DC4 (signed) through arg1.
pub fn func_8008EB04(arg0: [*c]c_int, arg1: [*c]c_int) callconv(.c) void {
    arg0.* = @as(c_int, v.g.D_800F1DCA().*);
    arg1.* = @as(c_int, v.g.D_800F1DC4().*);
}
