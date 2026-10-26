//! Display mask setter in the battle overlay's 146C.c unit.
const c = @import("c_146C");

/// orig: func_80089CE4 (src/BATTLE/BATTLE.PRG/146C.c)
/// Turns the display on by setting the display mask to 1.
pub fn func_80089CE4() callconv(.c) void {
    c.SetDispMask(1);
}
