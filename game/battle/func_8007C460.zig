//! Screen transition wipe angle setter (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007C460 (src/BATTLE/BATTLE.PRG/146C.c)
/// Stores the screen transition wipe angle.
pub fn func_8007C460(arg0: c_int) callconv(.c) void {
    v.g.vs_battle_screenTransitionWipeAngle().* = arg0;
}
