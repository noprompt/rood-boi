//! Battle setup step: resets the CLUT state and the battle display flags (src/BATTLE/BATTLE.PRG/146C.c).
const v = @import("views_146C");
const c = @import("c_146C");

/// orig: func_8007B410 (src/BATTLE/BATTLE.PRG/146C.c)
/// Runs the battle setup calls and sets the battle-ready flag.
pub fn func_8007B410() callconv(.c) void {
    c.func_8007B10C(0xD, 4, -4, -4, 0);
    c.vs_main_setClutState(0);
    c.func_8006C2A0();
    c.func_8008B4BC(1);
    _ = c.func_8008B4C8(0);
    c.func_8008E480(1);
    v.g.D_800F1968().* = 1;
}
