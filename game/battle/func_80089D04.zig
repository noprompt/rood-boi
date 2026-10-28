//! Display-mask stub from the battle overlay (src/BATTLE/BATTLE.PRG/146C.c).
const c = @import("c_146C");

/// orig: func_80089D04 (src/BATTLE/BATTLE.PRG/146C.c)
/// Turns the display off by clearing the display mask.
pub fn func_80089D04() callconv(.c) void {
    c.SetDispMask(0);
}
