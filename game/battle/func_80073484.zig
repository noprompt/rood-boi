//! Battle frame setup: calls the two engine helpers and sets the game time tick speed (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_80073484 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the two setup calls around setting `vs_gametime_tickspeed` to 2.
pub fn func_80073484() callconv(.c) void {
    c.func_8006F5CC();
    v.g.vs_gametime_tickspeed().* = 2;
    c.func_800CB654(0);
    _ = c.func_8008B4C8(1);
}
