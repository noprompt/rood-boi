//! Fills three words of the caller's block from the global at D_800F1A30 (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007DE88 (src/BATTLE/BATTLE.PRG/146C.c)
/// Writes the value of D_800F1A30 to the first two words of arg0 and zero to the third.
pub fn func_8007DE88(arg0: [*c]c_int) callconv(.c) void {
    // The global is read again after the first store: arg0 may alias it, as in the object.
    arg0[0] = v.g.D_800F1A30()[0];
    arg0[1] = v.g.D_800F1A30()[0];
    arg0[2] = 0;
}
