//! Screen transition state for battle (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");

/// orig: func_8007C4AC (src/BATTLE/BATTLE.PRG/146C.c)
/// Starts a screen transition: sets its step to 7 and stores its effect, speed and wipe angle.
pub fn func_8007C4AC(effect: c_int, speed: c_int, wipeAngle: c_int) callconv(.c) void {
    v.g.vs_battle_screenTransitionStep().* = 7;
    v.g.vs_battle_screenTransitionEffect().* = effect;
    v.g.vs_battle_screenTransitionSpeed().* = speed;
    v.g.vs_battle_screenTransitionWipeAngle().* = wipeAngle;
}
